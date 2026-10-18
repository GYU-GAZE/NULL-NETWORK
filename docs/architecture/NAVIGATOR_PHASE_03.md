# Navigator — consolidação da Fase 03

Base verificada: PR #42 aberta, `refactor/browser-authoring-pipeline`, commit `b0241504ad34c6e6f6cba1f2b9e9b6493cbb7c5c`. A nova branch é `refactor/navigator-exploration-pipeline`, dependente dessa base. Não há merge nesta entrega.

## Auditoria e responsabilidades

| Fronteira | Autoridade reutilizada / implementação |
| --- | --- |
| Conteúdo e referências | `ContentRegistry`, catálogo concreto `GameContentCatalog`, `NavigatorWorldData`, `MapLocation` e `LocalAreaData`. O mapa referencia o mesmo Resource global por ID; não há registro alternativo. |
| Conhecimento e acesso | `LocationDiscoveryService`, `GameState`, `CampaignState`, Conditions compartilhadas e `NavigatorLocationStateResolver`. Descoberta não satisfaz restrições explícitas. |
| Apresentação | `NavigatorApp` conserva os modos existentes e coordena as transições; WorldMapView e LocalAreaView continuam sendo consumidores. |
| População | `LocalAreaPopulationController`, `LegacyAwarePopulationController`, `SpawnTable`, CampaignState e LeadIncidentManager existentes. Reconciliação por identidade substitui reconstrução total. |
| NPCs | `NPCData.get_active_routine()` permanece autoridade de horário/presença. O novo ator físico só projeta identidade, diálogo e estado existentes. |
| Tempo | ActivityManager/TimeManager existentes. Reserva persistente e liquidação idempotente permitem viagem confirmada e fuga gratuita sem retroceder o relógio. |
| Combate e diálogo | DialogueManager, CombatManager e CombatResolutionService existentes. A resolução ESCAPED elimina recompensas permanentes; não cria outro runtime. |
| Persistência | SaveManager e seus provedores existentes. Nova seção de transações restaura antes das apresentações dependentes. |

Classes novas têm interfaces delimitadas: `NavigatorContentValidator` valida estrutura/catálogos sem iniciar exploração; `LocationAuthoring` grava e registra conteúdo; seu EditorPlugin traduz campos de UI para essa interface. `ConditionChangeSubscription` coleta dependências e emite uma atualização coalescida; é um Node local, não autoload. `NavigatorMapGeometry` concentra cálculos puros de clamp e conversão pan/scroll. `NavigatorAreaHistory` mantém apenas posição/entrada e estado local por região; população mundial continua em CampaignState. `LocalAreaNPCActor` apresenta NPCData. Nenhum autoload foi adicionado.

## Regressões de Fórum e foco

A normalização remove a barra final do prefixo de thread. O extrator anterior devolvia `/id`; agora usa BrowserRoute, verifica limite de segmento e remove exatamente um separador. Abertura por título, ícone, alerta e histórico é testada no Browser real.

Havia também um bypass de ações locais: o RichText procurava o Browser context e ignorava a intenção de Lead do Fórum. `use_local_navigation_handler` permite ao post emitir a intenção ao seu consumidor existente, que resolve a Lead e então publica navegação. O Browser não ganhou regras de Lead.

WindowBase distingue botão de ativação e roda do mouse. Pedidos redundantes de foco não repintam a janela. WindowManager mantém pulso em mudança real de foco e solicitações explícitas do dock; clique interno já focado e wheel não geram flash. O contrato existente conserva drag, maximize/restore, teclado e oito bordas/cantos de resize.

## Acesso reativo e localização física

Initially discovered define visibilidade inicial, sem criar um evento narrativo de descoberta. A descoberta por Lead preserva os badges/viewed/announcement existentes. Permissão combina Conditions explícitas com a compatibilidade de flags; disponibilidade combina Conditions temporais e períodos legados. Uma área estruturalmente inválida ou não registrada de forma canônica não pode ser acessada.

Marcadores sobrevivem a atualizações e mudanças irrelevantes de flags não disparam sua reavaliação. Marcadores bloqueados visíveis permitem inspeção e mostram o motivo da recusa. A ida ao World Map conserva `CampaignState.current_location_id`; revisita da região atual reapresenta sua área sem viagem paga. Área/posição são confirmadas somente após carregamento válido.

## População e fronteiras futuras

A seleção de slots comuns é persistente na geração e usa seed estável. Elegibilidade reativa não implica renovação. PERIOD permanece padrão; políticas DAY/ACTION_BLOCK/CAMPAIGN podem ser autoradas. Tombstones de atores resolvidos impedem reaparição na mesma geração. Em uma geração nova, um ator comum reutilizado recebe o novo estado, inclusive quando o avanço temporal ocorreu antes da limpeza da resolução anterior.

NPCs usam rotinas com blocos absolutos 0–23, localização e presença física. Atores existentes elegíveis mantêm instância/ponto; atores ausentes são retirados. Incidentes e Legacy Sites conservam seus hooks existentes. APKs ambientais podem ser projetados sem encounter fixo; nesta fase sua interação é observação. Combat Call, formação dinâmica e ecologia completa não foram implementados. Encounters autorados continuam funcionais.

## Tempo e migração

A solicitação atual substitui a antiga cobrança de combate voluntário na confirmação. DVS-039 registra a mudança e referencia DVS-004. Custo 2 permanece no Resource; confirmação reserva e conclusão paga. Fuga bem-sucedida custa 0 e não concede EXP, itens, Modules, passivas, tame, Encyclopedia ou efeitos permanentes de recompensa do plano. Dano já sofrido no combate continua parte do snapshot. Atividades de Incidente ainda cobram uma vez na confirmação; o combate incluído reutiliza a transação.

`commit_time_on_completion` é opt-in e falso por padrão. Somente as atividades de viagem e combate voluntário de produção foram migradas. Akihabara recebe `initially_discovered=true` para preservar o acesso inicialmente conhecido; locais ocultos/narrativos não foram convertidos em áreas. Recursos puros e validadores estruturais necessários à ferramenta receberam `@tool`; managers e nós de gameplay não executam no editor.

Sessão Navigator versão 6 aceita 1–5 e armazena histórico/retorno de diálogo. População versão 2 aceita descritores antigos da versão 1. `activity_transactions` versão 1 é seção opcional do save; sua ausência não cobra novamente transações antigas. O Navigator recusa save em transição e solicita checkpoint ao atingir estado estável. O teste real de disco cobre save/load com reserva de combate, fuga, retorno e ausência de transação órfã.

## Evidência e limites

Base: 58 cenas, 42 PASS e 16 FAIL. Fase 03: 64 cenas, 49 PASS e 15 FAIL. Os seis testes novos passaram e todas as 42 cenas verdes da base permaneceram verdes. `activity_manager_test` passou após atualizar as expectativas para a reserva e esperar a fronteira assíncrona estável. O inventário de resultados identifica separadamente cada falha herdada; não se declara a suíte global verde.

No Godot 4.6 nativo com OpenGL/NVIDIA, foram executados e capturados o fluxo Browser/Fórum → Lead → mapa → viagem → interação física → diálogo → combate contido real → retorno → save/load → fechar/reabrir; o contrato de foco; o contrato de janela/resize; NPC/diálogo e a área gerada. O fluxo também foi renderizado em 1280×720 e verificou escala 2x/posição preservada. O EditorPlugin nativo criou e registrou uma cena, vinculou uma segunda localização a essa cena e recusou ID duplicado sem alterar os catálogos. Uma regressão visual do tamanho do diálogo de erro foi corrigida e ganhou assertiva.

Há warnings de ObjectDB/resources no encerramento de algumas cenas, inclusive na base; PASS não significa ausência desses warnings. O scan global do editor também tem o erro de tipo preexistente em `tests/onboarding/compatibility_assessment_test.gd:26`. O teste desse runtime passa. Falhas antigas de layout/combate e de outras funcionalidades continuam fora do escopo desta fase. Os assets substitutos usados pelo CI validam contratos, não a fidelidade gráfica dos assets de produção.
