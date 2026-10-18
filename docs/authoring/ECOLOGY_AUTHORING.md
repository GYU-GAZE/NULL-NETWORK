# Ecologia finita e QA Time — autoria da Fase 05

Autoridade: [GDD canônico v5, capítulo 9](../gdd/NULL_NETWORK_GDD_CANONICO_v5.md). Base da entrega: PR #44, `feat/field-exes-combat-call`, `e81ec647cc8d8db1d1e38b307fb9b11133c899a9`. Não há merge automático.

## Zona, espécie e subárea

`EcologyZoneData` é conteúdo imutável registrado em `GameContentCatalog.ecology_zones`. Cada `MapLocation.ecology_zone` referencia a zona governante. Várias subáreas podem compartilhar uma zona; um distrito também pode possuir várias zonas independentes. Os IDs de localização e de zona não são intercambiáveis. Não crie uma área explorável para cadastrar uma ecologia abstrata.

| Resource | Campos principais |
| --- | --- |
| EcologyZoneData | ecology_zone_id, display_name, location_ids, population_capacity, conditions, species, danger_number_key, micro_update_weekday, recompile_on_micro_update, migrations, npc_activities, resonance_presence_bonus, presentation, predator, counts_towards_extinction_route |
| EcologySpeciesData | species_line_id, population_base, population_capacity, frequency, weekly_recovery, weekly_resonance_decay, conditions, variants, pressure_rules |
| EcologyVariantData | node_id, species_line_ids, zone_ids, minimum_resonance, weight, resonance_weight_bonus, conditions, field_tint |
| EcologyPressureRuleData | periods, minimum_infestation, minimum_danger, conditions, population_base_bonus, weekly_recovery_bonus, frequency_multiplier, variant_additions |
| EcologyMigrationData | migration_id, source_zone_id, species_line_id, maximum_units, leave_in_source, conditions |
| EcologyNPCActivityData | activity_id, npc_id, species_line_id, operation, interval_blocks, conditions, infestation_delta, danger_delta |
| EcologyPresentationData | limiares autorais, textos de estados/avisos/feedback e collapsed_tint |
| EcologyPredatorData / StageData | identidade, APK de catálogo, nível de demonstração, perfis de campo/encontro, estágios por quantidade de colapsos, Modules autorais e assimilação compatível |

Akiba usa `data/content/ecology/akiba_electric_town.tres`. É a ecologia real da área existente: Rattildus tem base/capacidade 5; capacidade total da zona 8; a subárea projeta normalmente quatro atores. Os valores de capacidade, frequência, velocidade, limiares e balanceamento do predador são decisões de CONTEÚDO da demonstração, não números universais declarados canônicos pelo GDD.

Os exemplos executáveis estão nos arquivos `akiba_rattildus.tres`, `akiba_electric_town.tres`, `akiba_npc_stewardship.tres` e `null_predator.tres`. Para outra espécie, crie um EcologySpeciesData com uma species_line_id já presente nos APKData do catálogo; atribua base, capacidade, recuperação e pools compatíveis. Adicione-o ao array species da zona e adicione SpawnEntry ambientais compatíveis à SpawnTable de cada subárea. Registre a zona no catálogo e vincule a MapLocation. A soma das bases não pode exceder a capacidade total. Os validadores verificam referências de zonas, espécies, NPCs e APK do predador.

Exemplo mínimo, seguindo os Resources reais:

```ini
[gd_resource type="Resource" script_class="EcologySpeciesData" format=3]
[ext_resource type="Script" path="res://data/templates/ecology/ecology_species_data.gd" id="species"]
[resource]
script = ExtResource("species")
species_line_id = "rattildus"
population_base = 5
population_capacity = 5
weekly_recovery = 2
weekly_resonance_decay = 1
```

## Population Units e projeção

Population Units pertencem a espécie + zona. `FieldPopulationData.minimum_units/maximum_units` controla apenas densidade visual. Cinco assinaturas podem apresentar dois atores. O orçamento visual jamais cria assinaturas ecológicas.

O contexto entregue à SpawnTable contém limites e pesos ecológicos. Frequência combina população corrente/base, frequência autoral, bônus autoral de Resonance e regras de pressão. O limite simultâneo é arredondado a partir dessa frequência e limitado à população corrente e ao orçamento visual. Em Akiba, cair de 5 para 2 reduz a projeção de quatro para dois; em zero nenhuma entrada garantida contorna a ausência. O limite mínimo visual não força spawns quando a ecologia não permite.

A seleção continua usando o RNG determinístico da geração. Alterações de uma zona notificam apenas as áreas que a referenciam. Descritores conservam IDs, posições e tombstones; atores sobreviventes não são reconstruídos por uma alteração não relacionada. Novas projeções não substituem imediatamente os indivíduos gastos no mesmo ponto. Período/renovação autorada e Micro-Update permitem recompilação coerente.

Combat Call seleciona atores físicos presentes. O principal permanece obrigatório; há até quatro inimigos e cada espécie respeita suas Population Units disponíveis. A formação é conferida novamente ao terminar a apresentação. Encontros fechados de Incidentes e eventos permanecem no runtime existente; não use formações abstratas como substituto da fauna comum.

## Variant Nodes, Resonance e pressão

Resonance varia entre 0 e 3. Pools só aceitam os oito identificadores de Variant já autorados no projeto. Cada variante declara espécies e zonas compatíveis, mínimo de Resonance, condições e pesos. Pressure rules podem acrescentar outras variantes compatíveis. Em Akiba, DEFENSIVE, CONDUCTIVE e CRYOSIVE tornam-se elegíveis nos níveis autorais 1, 2 e 3.

A variante escolhida é persistida no descritor e transmitida à formação/slot. Sua apresentação usa tint e identificação de campo. O pipeline não inventa atributos de batalha para Nodes cujo comportamento continua TBD. A alteração de elegibilidade não rerrola a identidade de todos os atores existentes; novos representantes da geração/atualização usam a pool vigente e variantes indisponíveis deixam de ser projetadas.

Infestation vem de WorldStateData.get_infestation. Danger só é consultado quando existe uma chave autoral configurada; a entrega não cria uma escala global fictícia. O perfil de patrulha de Akiba possui um modificador de agressividade para Infestation >= 3; a espécie possui uma regra de recuperação/frequência para essa pressão. Os números são conteúdo configurável. PURGE não reduz Infestation automaticamente.

## Operações e recompensas

| Ação | Efeito comprometido na resolução formal |
| --- | --- |
| PURGE concluído + alvo derrotado | -1 assinatura da espécie/zona; exatamente 3× EXP após penalidade de nível; nenhum Module/passivo/item proveniente de PURGE |
| PURIFY concluído | +1 Resonance, máximo 3; população preservada; passivo válido ainda não conhecido ou EXP alternativa existente |
| SCAN | Extração selecionada e Encyclopedia existentes; ecologia neutra; SCAN anterior a PURGE continua válido |
| TAME | Adoção pelo serviço existente; população e Resonance preservadas |
| Derrota comum | Dispersa a projeção física; não debita população permanente |
| Run Away / cancelamento | Descarta recompensas e efeitos ecológicos pendentes; não cobra a reserva voluntária |

A política de recompensas fica em CombatResolutionService para todos os fluxos. Recompensas legítimas de outros alvos e SCAN anterior continuam válidas em um encontro misto. A penalidade de inimigo fraco é autorada em CombatRewardData: em Rattildus, diferença >= 10 usa razão 0,2; somente depois ocorre o multiplicador canônico 3. O GDD não fixa esses limiares. Um exemplo com 500 EXP e penalidade 0,2 produz 100 × 3 = 300. O antigo campo serializado purge_experience_multiplier não altera a regra fechada de 3× na autoridade.

O custo da Fase 04 permanece: voluntário independente 1 reservado; Run Away 0; combate incluído reutiliza o proprietário; contato FORCED_FREE não inventa horas pagas.

## Recibos e falhas intermediárias

A resolução produz envelopes `world_state.persistent_objects["field_resolution." + battle_id]`. Cada pedido identifica operação, batalha, alvo físico/UID, zona, espécie, resultado formal, deltas solicitados, proveniência e estado de aplicação. Novos envelopes usam versão 2; os envelopes persistidos da Fase 04 continuam recuperáveis.

A população e o ledger `applied_effect_receipts` são atualizados sincronicamente na mesma autoridade. Save fica bloqueado durante a mutação. A confirmação APPLIED no envelope ocorre depois do ledger. Se um checkpoint contiver ledger aplicado e confirmação ausente, o reprocessamento apenas confirma o pedido. Se contiver pedido ainda não aplicado, ele é consumido após a restauração completa dos provedores. Não há dependência exclusiva do sinal efêmero. Recibos de fuga/cancelamento não são consumidos.

Tombstones físicos são reconciliados no sinal formal de resolução antes de refresh/checkpoint; o retorno ao mapa continua idempotente. Assim, salvar entre a tela de resultado e CONTINUE não faz reaparecer um alvo purgado. A assinatura expurgada fica registrada pelo ID; uma recompilação futura usa uma identidade de geração diferente.

## Micro-Update, migração e NPCs

O serviço escuta o TimeManager existente. Segunda-feira é o Micro-Update de produção; a data inicial do projeto faz a primeira segunda-feira ocorrer no dia de jogo 5. Cada zona/ciclo recebe um recibo persistente. Não há relógio nem scheduler concorrente.

Recuperação é parcial, limitada pelas capacidades. O exemplo autorado permite 1/5 +2 => 3/5 e Resonance 3 => 2. Migração transfere unidades entre zonas permitidas, não cria unidades por acidente. O limite leave_in_source é conteúdo; mesmo quando zero é permitido para uma espécie, a migração automática preserva pelo menos uma assinatura total na origem. Zonas colapsadas não recuperam nem recebem migração convencional.

NPCs usam eventos abstratos com cadência em blocos canônicos, ID de ciclo e NPC real. Há suporte para PURGE, PURIFY, contenção de Swarm e pressão de mundo. Eles podem eliminar localmente uma espécie quando outras sobrevivem, mas nunca a última assinatura da zona. `akiba_npc_stewardship.tres` demonstra uma rotina opt-in do GANBAREkun, habilitada pela flag autoral ecology.akiba.community_stewardship. Ela não altera silenciosamente a campanha antes de ser habilitada.

StoryEvents podem usar EcologyOperationEffectData pelo contrato GameEffectData existente. A proveniência narrativa/ciclo torna o efeito idempotente. Esse efeito não autoriza colapso final: a confirmação deliberada do protagonista pertence ao combate. Alterações de Infestation/Danger são dados explícitos da operação, não consequências universais de PURGE.

## Última assinatura, colapso e Predador NULL

O Overworld exibe LAST ACTIVE EXE SIGNATURE quando resta uma assinatura total. Antes de comprometer um resultado que destruiria a última, CombatManager exige uma confirmação específica, separada da confirmação de custo. O aviso explicita permanência, bloqueio de recuperação e impossibilidade de reversão pelo Micro-Update comum. Isso inclui PURGEs simultâneos contra vários alvos.

As marcas de PURGE continuam pendentes até essa decisão. CONFIRM PURGE autoriza o conjunto exato de alvos na revisão ecológica atual. CANCEL PURGE descarta as marcas destrutivas pendentes e permite resolver a batalha sem esse débito. Um save anterior à confirmação exige o aviso novamente; autorizações obsoletas não valem para outra revisão/conjunto.

O colapso zera população e Resonance, bloqueia fauna comum/recuperação, escurece a ambientação, publica flags e registra a rota. Estado de mundo e rota sobrevivem ao Operator Loss. O indicador de conclusão global refere-se às zonas relevantes AUTORADAS no catálogo, sem inventar distritos inexistentes.

O primeiro colapso registra um único Predador NULL por campanha. A área o projeta com o mesmo ator físico reutilizável, comportamento de perseguição e política forçada gratuita. Ele pode ser evitado pelo cenário. Fuga preserva sua atividade; vitória preserva o colapso e coloca o mesmo predador em recompilação. Outro colapso reativa/evolui essa identidade. A definição original permanece a política global da entidade.

A demonstração usa APK/arte provisórios e nível/perfis autorais. No segundo colapso, o estágio autorado equipa heavy_attack e permite assimilar Modules ativos compatíveis das faunas destruídas. Isso usa os loadouts existentes. Fórmulas especiais de Nodes, passivos/fases adicionais e curvas exatas ainda não fechadas permanecem nas notas unresolved_design_notes; não foram substituídas por mecânicas inventadas. O perfil de recompensa é zero e não oferece farming convencional de EXP, Modules ou itens.

## Consumidores e informação

Navigator mostra estado diegético e feedback; após SCAN formal pode revelar contagens. Encyclopedia acrescenta presença/ausência para sujeitos conhecidos, com precisão ampliada por SCAN. Profile consulta o estado da localização atual. Forum usa Conditions em threads de ausência/colapso; Social entrega uma mensagem condicional na conversa existente do GANBAREkun; StoryEventManager processa o aviso autorado.

As flags ecology.<zona>.collapsed, ecology.<zona>.last_signature, ecology.<zona>.<espécie>.absent e ecology.extinction_route são projeções para Conditions/narrativa. O número de Resonance e o total de zonas colapsadas também são publicados por GameState. Não escreva nesses espelhos para modificar população: use EcologyService e os protocolos formais.

## QA Time e compatibilidade

Controles e API só ficam disponíveis em builds de desenvolvimento. PROLOGUE e MAIN_CAMPAIGN seguros são permitidos; outras fases são protegidas. StoryEvent ativo/enfileirado, diálogo, combate, request/transação viva, save/load e outra operação QA bloqueiam a mutação. O motivo e a fase ficam visíveis permanentemente no TimeStatusLabel; tooltips são preservados e os serviços notificam mudanças sem polling de 250 ms.

O fluxo normal New User → SAFE MODE → START mantém PROLOGUE verdadeiro. QA não altera a fase para desbloquear os botões. +24 processa cada hora via TimeManager e interrompe em uma fronteira incompatível. Só a animação cinematográfica intermediária é omitida durante stepping de desenvolvimento; temas e eventos temporais continuam atualizados. Sono e ocupação normais mantêm seus contratos. Não existe bônus direto de EXP/itens/afinidade.

Campanha mantém seu schema compatível e WorldState adiciona ecology_zones/ecology_route opcionais; zonas usam versão 1. População v3 e combate v3 continuam aceitando os saves anteriores. Saves sem ecologia inicializam as definições vigentes no ponto de migração e consomem recibos persistidos, sem simular retroativamente uma semana que não estava registrada. Formação antiga sem escopo ecológico permanece um encontro legado, sem atribuição retroativa de efeitos novos. Custos/recompensas já pagos não são recalculados.

## Validação

As oito cenas tests/ecology/*test.tscn cobrem onboarding real, estados de bloqueio, autoridade/recibos, recompensas, projeção, ciclo completo, colapso/predador, atualização semanal/NPCs e reações nos consumidores. As suítes verdes anteriores continuam necessárias. O JSON de validação distingue baseline, novas cenas, falhas herdadas e novos erros de runtime. A renderização nativa usa Godot 4.6 Windows; CI usa a versão Linux e a preparação de assets já existente no projeto.
