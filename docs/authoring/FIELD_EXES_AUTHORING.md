# Field EXEs e Combat Call — autoria da Fase 04

## Contrato e autoridades

Esta fase implementa as decisões fechadas do pedido canônico da Fase 04. O GDD v5 completo não está presente no checkout; nenhum detalhe ausente de Danger, Variant Node ou ecologia global foi preenchido com uma autoridade paralela.

`APKData` continua sendo a espécie/forma. Cada projeção ambiental é uma unidade individual do estado de população existente em `CampaignState.world_state.population_states`. O ID inclui local, entrada, índice e geração; nunca é substituído pelo ID da espécie durante o combate. `ContentRegistry`, Conditions, rotinas, ActivityManager, TimeManager, DialogueManager, CombatManager e SaveManager mantêm suas responsabilidades.

## Configurar uma espécie/forma

No Inspector de `APKData`, atribua:

| Resource | Campos e responsabilidade |
| --- | --- |
| `field_presentation: FieldPresentationData` | `idle_frames`, `step_frames`, `sprite_origin` em pixels da imagem, `visual_scale`, `frames_per_second`, `faces_right`, `tint` e `digital_effect`. Independente de ator runtime e reutilizável futuramente pelo Profile. |
| `field_behavior: FieldBehaviorProfileData` | Identidade comportamental padrão da espécie/forma, parâmetros de movimento, percepção e resposta. |
| `field_encounter: FieldEncounterProfileData` | Atividades voluntária/imposta, perfil de resolução/recompensa, raio e duração da chamada e política de aggro. |

Os arrays antigos `sprites`/`portraits` não são interpretados como Field Idle/Step. Sem frames específicos, o renderer usa um sprite SVG provisório e uma animação de passo mínima. A apresentação temporária é substituível no Resource e não é arte definitiva de Rattildus. O portrait provisório de GANBAREkun também está identificado como placeholder. Nenhuma espécie precisa conservar o antigo polígono de encontro.

## Comportamento

`FieldBehaviorProfileData.behavior` aceita PASSIVE, AGGRESSIVE, TERRITORIAL, CAUTIOUS, COWARDLY, CURIOUS, PACK, SOLITARY, PROTECTIVE, OPPORTUNIST, SWARM e DORMANT.

- PASSIVE patrulha ou percorre destinos de roaming sem iniciar aggro.
- AGGRESSIVE percebe, persegue e solicita contato físico.
- TERRITORIAL limita a perseguição ao território e retorna à origem.
- CAUTIOUS/COWARDLY recuam quando percebem o jogador.
- CURIOUS investiga e acompanha sem iniciar ataque por esse motivo.
- PACK considera companheiros da mesma espécie; PROTECTIVE reage à aproximação do jogador aos companheiros.
- SOLITARY afasta-se de unidades próximas; OPPORTUNIST usa o limiar autorado de HP do parceiro para decidir atacar.
- SWARM pode perseguir e responder em grupo. DORMANT permanece inativo até um modificador autoral mudar seu comportamento.

Defina `speed`, `acceleration`, `perception_radius`, `roaming_radius`, `territory_radius`, `maximum_pursuit`, `following_distance`, `minimum_pause`, `maximum_pause`, `patrol_offsets` relativos ao ponto de origem e `perception_interval`. Sem destinos de patrulha, o ator sorteia destinos de roaming pelo RNG individual persistido. `opportunist_hp_threshold` e `response_probability` são parâmetros do perfil, não regras por espécie no script.

`active_conditions` controla atividade; `aggro_conditions` controla intenção agressiva. `FieldBehaviorModifierData` combina uma Condition compartilhada com `behavior_override` e `speed_multiplier`. O perfil de patrulha de Akiba possui um modificador NIGHT que passa a CAUTIOUS. As dependências globais são assinadas e coalescidas; Conditions não são varridas a cada frame físico.

O motor possui estados Idle, Roaming, Patrol, Investigating, Following, Chasing, Fleeing, Returning, CombatCall e Disabled. Preserva RNG, posição, origem, destino, pausas, índice de patrulha, graça de fuga e necessidade de separação. O estado de RNG de 64 bits é salvo como texto decimal para evitar perda de precisão pelo JSON.

## Física, mapa e pontos de spawn

O ator conserva a raiz `LocalAreaInteractable`/Area2D e o contrato do sensor existente na layer 2. O movimento pertence a um `CharacterBody2D` composto com `top_level`, layer/mask 1; a raiz de interação acompanha o corpo. Não se desloca um StaticBody2D. A apresentação arredonda sua própria posição, mantendo subpixels no corpo físico.

Cada área mantém uma grade `AStarGrid2D` compartilhada de 24 pixels. Ela amostra obstáculos físicos com folga para o corpo e impede cortes diagonais por cantos bloqueados. O motor recalcula caminhos em intervalos, enquanto `move_and_slide()` continua sendo a autoridade final de colisão. O mapa usa `area_bounds` e as colisões existentes, incluindo NPCs estáticos. Pontos inválidos/ocupados são corrigidos para posições livres próximas; se não há espaço válido, a unidade não é apresentada. Ajuste colisões e spawn points no editor para evitar depender dessa recuperação.

O Player e os motores ambientais são pausados pela apresentação local quando Navigator fica inativo, entra em diálogo/combate ou há confirmação. O avanço temporal de QA também pausa os motores durante a operação. Proximidade visual não inicia batalha: o motor exige contato físico/sensor compatível antes de emitir a intenção automática. A interação deliberada usa o sensor existente do Player e verifica distância/linha livre.

## População ambiental

Use `SpawnEntry.environmental_apk` e deixe `encounter` vazio para fauna comum. O Resource herda os três perfis da espécie. Use `behavior_override` ou `encounter_override` apenas quando a ocorrência precisar de uma variação. `field_level` define o nível do indivíduo; `variant_node_id` é um identificador autoral opcional transmitido no contexto. Não coloque IDs de espécie no controlador ou no coordenador.

Em `SpawnTable.field_population`, configure `FieldPopulationData`: mínimo/máximo visível (referência comum 2–5), `conditions`, `guaranteed_spawn_ids`, `spawn_separation` e `danger_number_key` opcional. `rolls_per_population` informa a quantidade desejada e os pesos completam a composição dentro do orçamento. As entradas garantidas permitem demonstrar diversidade comportamental sem depender de um sorteio favorável. A disponibilidade real de pontos compatíveis e espaço físico limita a projeção.

Akiba usa quatro entradas individuais de `rattildus_init`: patrulha, agressiva, cautelosa e de grupo. Seus quatro pontos são separados do kiosk, NPC e incidente. Os encounters fechados 1v1/3v1 continuam registrados para conteúdo autoral; não são sorteados como fauna comum.

`retired_entries` é somente lookup de compatibilidade, nunca pool de sorteio. Uma entrada aposentada só permanece apresentada enquanto um combate antigo salvo com ela estiver ativo. Depois da resolução, o tombstone é preservado; sem luta antiga ativa, a população migra para unidades ambientais. Não use essa coleção para novo conteúdo.

## Respostas à Combat Call

O principal sempre ocupa o slot inimigo 0. O coordenador consulta atores ambientais realmente presentes, disponíveis, com linha livre e dentro de `call_radius`. Avalia cada resposta separadamente e inclui até três respondedores. INTERCEPT tem prioridade; demais empates usam distância/ID estáveis. Quem não entra continua na área.

As respostas são JOIN, IGNORE, HESITATE, FLEE, INTERCEPT e OBSERVE. As identidades do perfil fornecem padrões; `response_rules` ordenadas permitem condições específicas. `FieldCallResponseRule` define resposta, distância mínima/máxima, mesma espécie, variantes aceitas, limites opcionais de Danger/Infestation, probabilidade, tempo de hesitação e `join_after_hesitation`. HESITATE pode responder depois do atraso; FLEE inicia o retorno/recuo protegido após a chamada. O resultado usa seed de chamada/unidade, não sorteio independente de inimigos.

Infestation vem de `CampaignState.world_state.get_infestation(location_id)`. Danger só entra no contexto quando o conteúdo aponta uma chave numérica existente de GameState. Variant Node é metadado autoral da projeção. Regras que exigem uma dimensão ausente não recebem um valor universal inventado. Sistemas futuros podem preencher esses mesmos contextos pelas autoridades existentes.

O coordenador mostra sinal/chamada e respostas, espera a duração autorada, constrói um novo `CombatEncounter` com `CombatSlotData.CATALOG_APK` e entrega ao CombatApp existente. `APKCombatLoadoutFactory` mantém stats, Modules e integridade. Recompensas são as do perfil de cada participante; SCAN, PURGE e TAME usam o runtime existente. Nenhum `.tres` de encounter é alterado em disco.

## Aggro, custo e fuga

Combate voluntário independente custa EXATAMENTE 1 action block, tanto 1v1 quanto 1v4. `voluntary_activity` deve possuir `action_cost=1` e `commit_time_on_completion=true`. A validação recusa um perfil voluntário de custo 2.

Escolha explicitamente `aggro_policy`:

| Política | Contato automático |
| --- | --- |
| FORCED_FREE | Usa `forced_activity` autorada com custo 0 e sem confirmação. Funciona mesmo quando a ocupação bloqueia horas voluntárias. |
| OFFER_VOLUNTARY | Oferece a atividade voluntária normal. Confirmação/cancelamento e indisponibilidade de horas são respeitados; a recusa libera a chamada e aplica graça. |
| DISABLED | Não emite intenção de combate automático. Interação deliberada continua disponível. |

Incidentes e atividades proprietárias continuam usando a transação existente; combate incluído não paga novamente. A reserva só é liquidada em resolução paga. Run Away bem-sucedido libera a reserva com custo 0 e sem recompensas persistentes. Dano/estado já ocorrido e unidades efetivamente neutralizadas são reconciliados pelos resultados individuais, sem recriar a formação inteira.

`escape_grace_seconds` e `reengage_distance` evitam loops no retorno: perseguidores recebem graça e precisam permitir separação antes de aggro automático. A chamada possui ownership por área; contatos repetidos não abrem novas atividades. Cancelar/recusar libera os atores. O jogador pode provocar deliberadamente outra luta durante a graça.

## NPCs e Visual Novel

Para conversa presencial, registre `DialogueData` no catálogo global e atribua `NPCData.default_dialogue_id`. Configure speakers, `DialoguePortraitState`, nós e choices nos Resources existentes. O ator usa DIALOGUE por padrão quando esse vínculo existe e volta à área ao encerrar. EXAMINE continua para objetos e mensagens simples.

GANBAREkun agora aponta para `npc.ganbarekun.field_meeting`, com portrait e três escolhas. Sua rotina permanece DAY 0–11; ele deixa a área em NIGHT. O DialoguePlayer preserva as escolhas visíveis quando mudanças de população/save atualizam suas Conditions depois do término do texto.

## QA temporal e saves

System Settings possui a seção DEVELOPMENT / QA TIME. Mostra data, período, horário e bloco e oferece +1 hora ou o mesmo horário do próximo dia. `TimeManager.advance_development_hours()` processa cada hora em ordem e interrompe em fronteira de evento/atividade incompatível. Combate, diálogo, confirmação, transação ativa, save/load e fases fora da campanha principal bloqueiam a operação. Não há bônus direto de EXP/itens; serviços temporais canônicos continuam processando suas agendas. A função é de desenvolvimento e não substitui sono/rotina do jogo.

Save fica bloqueado durante o avanço e durante a apresentação da chamada; ao estabilizar, é solicitado checkpoint. Combat session v3 persiste a receita dinâmica antes dos snapshots mutáveis. Navigator v7 aceita v1–6; população v3 aceita v1/v2. A reserva antiga não cobrada é reconciliada com sua definição atual; custos já comprometidos e transações proprietárias não são reembolsados/reprecificados. Há fixture não modificada de um save real de teste da PR #43 com reserva de 2, restaurada e liquidada como 1 pelo teste de migração.

## Validação

Execute as seis cenas `tests/field/*test.tscn`: movimento, formação/respostas, Player Actions/aggro, NPC/tempo, fluxo completo e migração de save. O fluxo completo usa botões reais do CombatApp, SaveManager em disco, fuga e vitórias 1v1/1v4. A suite do Navigator e os encounters/Incidentes autorais continuam necessários. O workflow Field EXEs Validation executa os novos contratos e integrações existentes; Navigator Validation continua independente.

As capturas nativas demonstram movimento, perseguição, fuga, chamada, formação, resolução, VN e controles temporais com os assets provisórios. PASS headless valida contratos; a inspeção nativa é uma evidência separada.

Referências de implementação do Godot 4.6: [AStarGrid2D](https://docs.godotengine.org/en/4.6/classes/class_astargrid2d.html) e [PhysicsDirectSpaceState2D](https://docs.godotengine.org/en/4.6/classes/class_physicsdirectspacestate2d.html).
