# Fase 05 — WorldState, ecologia e fronteiras de resolução

Base: e81ec647cc8d8db1d1e38b307fb9b11133c899a9, PR #44. Branch dependente feat/ecology-canonical-qa-time. Nenhuma alteração em main ou merge automático.

EcologyService é um autoload porque atende combate, tempo, Navigator, Encyclopedia, Social, Profile e narrativa mesmo sem o Navigator instanciado. Ele não possui uma cópia privada da população. A única representação mutável fica em CampaignState.world_state.ecology_zones e ecology_route; ContentRegistry contém definições imutáveis.

## Estado e lifecycle

Cada zona persiste ID, capacidade, espécies, status, colapso, last_update, último Micro-Update, revisão, época de projeção, ledger de efeitos e histórico limitado. Cada espécie persiste base/capacidade/corrente, Resonance, estado e atualização. O ledger da zona conserva IDs de operações e proveniência por espécie/alvo; não há um contador mundial único.

O provedor ecology_lifecycle registra somente versão e readiness. SaveManager.campaign_loaded retoma o serviço após a importação completa dos demais provedores. Zonas ausentes de saves antigos são inicializadas uma vez. Recibos pendentes são consumidos antes de continuar o calendário. O estado já comprometido não é rerrolado.

## Transação ecológica

1. CombatManager verifica a fronteira terminal, resultado e consentimento de colapso.
2. CombatResolutionService planeja e aplica recompensas pelo runtime existente.
3. O mesmo serviço registra o envelope formal e solicita a mutação ecológica.
4. EcologyService grava população/Resonance e receipt no mesmo trecho síncrono protegido contra save.
5. O envelope recebe APPLIED; sua ausência não permite repetir um ledger já aplicado.
6. combat_resolution_applied reconcilia tombstones físicos antes do checkpoint automático.
7. Navigator retorna e liquida a reserva exatamente uma vez.

Não existe await no commit ecológico. A readiness do combate também bloqueia save durante a resolução de campanha. Fuga/cancelamento não criam efeitos ecológicos formais. A proteção de última assinatura compara todos os alvos PURGE do encontro e exige consentimento para a revisão/conjunto exatos. Cancelamento da extração mantém a batalha existente, sem colapso.

## Tempo

O serviço escuta time_advanced. Micro-Updates e atividades abstratas de NPC são ordenados por índice canônico de ação, prioridade e ID estável. Contextos de condições usam a fronteira correspondente; o serviço não altera o relógio nem executa uma simulação por frame. Cada zona/ciclo possui receipt. Migração conserva unidades e não produz colapso automático.

QA em desenvolvimento processa 1 ou 24 horas intermediárias. O prólogo seguro é permitido; narrativa viva, diálogo, combate, atividades e save/load continuam protegidos. UI observa sinais dos proprietários. Nenhum reset global de ActivityManager é usado como mecanismo de desbloqueio. Cancelamento/conclusão remove requests e transações no proprietário; sessões de combate ainda vivas conservam legitimamente sua reserva até o retorno.

## Projeções e identidade

SpawnTable recebe pesos/limites, incluindo garantias. LocalAreaPopulationController conserva descritores, tombstones e corpos sobreviventes e observa mudanças somente da zona relevante. FieldCombatCallCoordinator continua selecionando atores físicos. O total visual é separado das assinaturas finitas. FieldEcologyProjection apresenta feedback/ambientação e projeta a entidade persistente usando LocalAreaExeActor e FieldEXEMotor.

O Predador possui uma identidade de campanha, perfil original, origem, contagem de colapsos, Modules assimilados, status ACTIVE/RECOMPILING e posições por localização. Ele usa CombatEncounter/CATALOG_APK/APKCombatLoadoutFactory e perfil de recompensa zero. Não existe lógica de personagem específica em NavigatorApp, segunda engine de combate ou fórmula de Node TBD.

## Conteúdo e consumidores

Akiba possui uma zona real na área existente. Fixtures de duas zonas reutilizam geometria em testes e não adicionam destinos exploráveis ao produto. Pool de Nodes, pressão, recuperação, migração, NPCs, thresholds e textos ficam em Resources. Publicações GameState são espelhos narrativos; o estado ecológico permanece autoritativo.

Encyclopedia e Profile estendem projeções existentes. Forum recebe ThreadButtonData condicionado; Social recebe uma mensagem no ChatConversationData existente; StoryEventManager recebe um StoryEvent normal. EcologyOperationEffectData reutiliza GameEffectData para conteúdo narrativo, sem conceder autorização de colapso final a NPCs/eventos abstratos.

## Limites de evidência

A comparação de cenas e de diagnósticos está em docs/validation/ecology-phase05-results.json. Falhas herdadas e warnings de encerramento não são mascarados. As imagens nativas são de cenários de aceitação com fixtures controladas; o teste QA percorre a UI normal de criação de campanha, sem trocar PROLOGUE para desbloqueá-la. Não foi produzido um executável exportado de release; o bloqueio de release é o guard OS.is_debug_build da API/UI. Assets e balanceamento de demonstração do predador são provisórios; regras OPEN/TBD não são declaradas implementadas.
