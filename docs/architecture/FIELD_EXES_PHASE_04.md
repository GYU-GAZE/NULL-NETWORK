# Field EXEs — arquitetura e verificação da Fase 04

Base atualizada: PR #43 aberta, `refactor/navigator-exploration-pipeline`, `c0d139f26a14a782eed92ac5c3a7ba4073f97f93`. O commit adicional em relação a `bb22b8e` adiciona apenas o GDD v5; código e Resources do baseline são idênticos. Implementação em branch dependente `feat/field-exes-combat-call`, sem merge automático.

## Fronteiras de responsabilidade

| Responsabilidade | Implementação |
| --- | --- |
| Identidade/conteúdo | APKData permanece espécie/forma; SpawnEntry referencia a espécie e herda perfis, com overrides autorais opcionais. Não há scripts por espécie. |
| Estado individual | Descritores existentes persistem IDs de campo, resolução, HP/stability e movimento em CampaignState. Não são o contador finito de Population Units ecológicas. |
| Apresentação | FieldPresentationData define Field Idle/Step, origem, escala, orientação e efeito digital. FieldEXEPresentation consome os dados com fallback substituível. |
| Física | FieldEXEMotor é um CharacterBody2D composto com a Area2D de interação. O sensor existente continua funcionando; o corpo físico não é um StaticBody2D deslocado. |
| Navegação | FieldNavigationGrid mantém uma grade amostrada por área; caminhos usam AStarGrid2D e a física continua impedindo atravessamento. Geometria inválida é tratada antes de apresentar unidades. |
| Decisão/percepção | O motor atualiza deslocamento em physics ticks e percepção em intervalos. Condições globais são assinadas/coalescidas pelo mecanismo compartilhado. |
| Participação na chamada | FieldResponseEvaluator é avaliação pura/seeded. FieldCombatCallCoordinator pertence à área e seleciona os atores físicos reais, separados da decisão de perseguir. |
| Batalha | FieldCombatEncounterFactory deriva um CombatEncounter e slots CATALOG_APK. O autoload CombatManager continua sendo CombatCampaignManager, que usa APKCombatLoadoutFactory, Social e os serviços de resolução existentes. |
| Tempo/persistência | ActivityManager conserva reservas e liquidação. TimeManager implementa o avanço explícito de QA. SaveManager e seus provedores mantêm a ordem autoritativa de restauração. |

Nenhum autoload, registro de espécies, calendário, gerenciador de combate ou estado ecológico global paralelo foi adicionado. A ecologia representada nesta fase é o orçamento/projeção de unidades no estado mundial já existente; evolução ecológica global/offscreen continua fora deste contrato.

## Contrato de campo e Combat Call

Akiba projeta quatro indivíduos de Rattildus, com patrulha, agressividade, cautela e comportamento de grupo. Seus pontos são separados de obstáculos e dos pontos de NPC/incidente. O Player pode observar movimento, evitar aproximação e interagir deliberadamente. Uma criatura agressiva só emite intenção automática após contato válido. O coordenador impede duplicatas e a confirmação/recusa possui cleanup.

O principal fica sempre no slot 0; até três respondedores entram. Regras individuais consideram distância/linha livre, identidade da espécie, comportamento, Variant Node autoral, Infestation real e Danger opcional de uma chave existente de GameState. Não é sorteada uma formação independente da fauna visível. JOIN, IGNORE, HESITATE, FLEE, INTERCEPT e OBSERVE possuem respostas distintas; HESITATE aproxima-se parcialmente e desiste sem integrar a formação. JOIN e INTERCEPT aproximam-se fisicamente durante a chamada.

As formações fechadas autorais continuam registradas. O novo encontro não modifica seu Resource fonte. Slots dinâmicos usam APKCombatLoadoutFactory e carregam `field_unit_id`, HP/stability individuais e o perfil de recompensas. A resolução comum e a subclasse de campanha compartilham a extração dos resultados por unidade; assim, Partner/Operator Loss, SCAN, PURGE, TAME e Social não são contornados.

Resultado é aplicado somente aos IDs participantes. Projeções neutralizadas/tamadas são reconciliadas individualmente; sobreviventes mantêm seu estado. Não participantes permanecem no mapa. Run Away não concede recompensas permanentes, descarta resoluções inimigas/alterações ecológicas pendentes, libera a reserva e aplica graça/separação aos sobreviventes próximos. O código não converte um único derrotado em remoção de toda a fauna.

## Custo e compatibilidade

DVS-041 estabelece custo voluntário independente 1 para qualquer formação de 1–4 inimigos, reservado até resolução paga. DVS-043 define políticas autorais FORCED_FREE, OFFER_VOLUNTARY e DISABLED. Contato imposto gratuito é aceito pela autoridade de ocupação mesmo quando não existem horas voluntárias; política opcional respeita a recusa e libera a chamada. Incidentes mantêm sua atividade proprietária e custo adicional zero.

Combat session v3 inclui a receita da formação, restaurada antes dos snapshots de batalha; aceita v1/v2. Navigator v7 aceita v1–6; população v3 aceita v1/v2. O RNG individual de 64 bits é persistido como texto decimal para sobreviver ao JSON sem arredondamento.

Uma reserva antiga ainda não cobrada é reconciliada com o Resource atual apenas quando seu root_activity_id coincide com a definição restaurada. Custos já cobrados e atividades proprietárias não são reembolsados nem alterados por esse hook. `SpawnTable.retired_entries` fornece lookup exclusivo de migração para conservar um participante de combate antigo em andamento; essas entradas nunca entram no pool ambiental. Sem combate antigo ativo, a projeção migra para os indivíduos novos. Tombstones de unidades resolvidas continuam preservados até a renovação autorada.

A fixture de teste é um checkpoint manual não modificado, produzido no baseline #43 em APPDATA isolado: reserva 2, população v2, sessão Navigator v6 e combate v2. O teste restaura esse arquivo pelo SaveManager real, preserva o encontro autoral/ID antigo, ajusta a reserva e executa sua resolução no CombatApp. A provenance está em `tests/field/fixtures/README.md`.

## VN e desenvolvimento temporal

GANBAREkun possui DialogueData de produção registrado no catálogo, portrait provisório e três escolhas. O vínculo vem de NPCData.default_dialogue_id; não existe outro runtime de fala. A integração revelou uma falha anterior: refresh de Conditions por eventos de população/save escondia choices após o texto. DialoguePlayer agora preserva sua apresentação e respeita uma escolha ainda pendente.

System Settings contém uma seção explicitamente DEVELOPMENT / QA. Os comandos +1 hora e mesmo horário do próximo dia usam TimeManager e processam horas intermediárias em ordem. Diálogo, combate, atividade pendente/ativa, save/load e fases fora da campanha principal bloqueiam o comando. Uma nova fronteira de evento pode interromper um avanço de 24 horas. Saves são bloqueados durante a operação e um checkpoint é solicitado ao estabilizar. Não há concessão direta de EXP/itens pelo controle; serviços temporais canônicos continuam recebendo os eventos.

## Evidência

O baseline local foi reproduzido antes das alterações: 64 cenas, 49 PASS e 15 FAIL. As seis cenas novas cobrem física, chamadas/respostas, Player Actions/aggro, VN/tempo, fluxo completo e migração. A comparação final de cada cena está em `docs/validation/field-phase04-results.json`; falhas herdadas são distinguidas das novas e não são mascaradas.

As verificações nativas usam Godot 4.6 stable Windows, OpenGL/NVIDIA RTX 3050. Capturas mostram múltiplos indivíduos, perseguição, fuga cautelosa, chamada/respondedores, formação dinâmica, retorno/resolução, VN com portrait/choices e controles temporais. O fluxo completo também verifica 1280×720/escala 2x, posições e save/load. Assets SVG de fallback/portrait são provisórios e não constituem arte final aprovada.

O workflow Field EXEs Validation executa os seis testes novos e integrações existentes de combate, Navigator, Leads, Social, save e janela. Navigator Validation permanece independente, incluindo a ferramenta de autoria real. CI usa Godot 4.6.3 Linux com o preparo de assets substitutos já usado pelo projeto; renderização nativa é evidência separada.

Persistem warnings de ObjectDB/resources no encerramento e falhas antigas em outras áreas, incluindo o scan de teste de onboarding e jobs já vermelhos da base. A entrega não declara o projeto inteiro verde. O GDD v5 completo foi incorporado pela base atualizada e os contratos de campo foram auditados contra seus capítulos relevantes. O pedido preserva os contratos de Player Actions já implementados; a ecologia global finita e novas Interaction Sequences do GDD permanecem autoridades futuras, sem implementação paralela nesta fase.

### Fronteira da ecologia finita

Projeções visíveis não equivalem às Population Units finitas do capítulo 9. Normal defeat, SCAN e TAME não debitam um contador ecológico fictício. Na resolução formal, cada alvo PURGE derrotado produz um pedido de delta -1 por espécie/zona, com receipt idempotente em `world_state.persistent_objects` e sinal `ecology_effects_requested`. Uma autoridade ecológica futura pode consumir esse pedido; esta fase não inventa populações-base semanais. Run Away não emite nem persiste esse pedido. Atores físicos podem sair da apresentação atual sem significar extinção ecológica. Os contratos de recompensas/Player Actions existentes foram preservados conforme o pedido; o balanceamento e novas Interaction Sequences do GDD são fronteiras distintas.
