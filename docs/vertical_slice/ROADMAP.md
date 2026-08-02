# NULL NETWORK — ROADMAP OFICIAL DO PRIMEIRO VERTICAL SLICE FUNCIONAL

**Versão do roadmap:** 1.0
**Base de auditoria:** GDD(5), instruções atuais do projeto e branch `main` do repositório.
**Objetivo:** transformar o estado atual do projeto em uma campanha contínua, jogável, persistente e capaz de executar o Prólogo, o primeiro dia e a primeira semana até o Incidente do Aquário.

Este roadmap substitui o roadmap arquitetural anterior. O documento antigo continua útil como histórico, mas Browser, Window System, Navigator e Combat avançaram desde sua escrita; o gargalo atual passou a ser a ausência da camada de campanha que conecta esses sistemas. 

Toda implementação descrita aqui deve ser construída como arquitetura definitiva, orientada a dados e reutilizável. O vertical slice limita **conteúdo**, não a qualidade estrutural dos sistemas. Não serão criados protótipos descartáveis ou sistemas paralelos específicos para o Aquário.  

---

# 1. Definição do vertical slice

O primeiro vertical slice será considerado concluído quando o jogo suportar este fluxo:

```text
Abrir o executável
→ criar uma campanha ou carregar uma campanha existente
→ escolher SAFE MODE ou COMMIT MODE
→ iniciar o boot diegético do KubuOS
→ abrir o Browser
→ acessar o denpa-channel
→ encontrar o link para NULL NETWORK
→ navegar pelo site oficial
→ criar o Operator
→ desbloquear o NULL CHANNEL
→ ler WELCOME, NEW PLAYERS
→ instalar NULL NETWORK
→ escolher o APK inicial
→ desbloquear o Navigator
→ viajar até a primeira área
→ explorar o Overworld Local
→ iniciar o primeiro combate
→ usar Modules e Player Actions
→ vencer, fugir ou perder
→ receber consequências persistentes
→ iniciar oficialmente o Dia 1
→ jogar a primeira semana
→ investigar os rumores do Aquário
→ concluir o Incidente do Aquário
→ fechar o jogo
→ reabrir no estado correto
```

O Prólogo seguirá o fluxo descrito no GDD: denpa-channel, site oficial, criação da conta, fórum, instalação, starter, Navigator e primeiro EXE. Após o tutorial, a campanha oficial começa no dia seguinte. 

A semana deverá demonstrar o ciclo central:

```text
Ler a comunidade
→ encontrar um Lead
→ viajar
→ explorar
→ gastar tempo em uma ação significativa
→ enfrentar uma consequência
→ ver Fórum, Social, APK e mundo reagirem
```

O objetivo não é apenas produzir uma sequência narrativa. O vertical slice precisa provar que esse ciclo pode ser repetido durante o restante do jogo sem código específico para cada evento.

---

# 2. Regras canônicas congeladas

## 2.1 Tempo

```text
DAY: 12 blocos
NIGHT: 12 blocos
Total diário: 24 blocos
```

O `TimeManager` atual já utiliza corretamente `12 + 12`.

Toda condição temporal deverá usar:

```text
days_passed
current_period
current_action_block
```

Não deverão existir novos sistemas baseados em:

```text
morning
noon
afternoon
evening
madrugada
```

Esses conceitos podem aparecer apenas como texto de apresentação.

## 2.2 Custos de atividade

```text
Atividade livre: 0 blocos
Ação simples: normalmente 1 bloco
Ação complexa: normalmente 2 blocos ou mais
Combate voluntário: 2 blocos
Viagem entre distritos: normalmente 1 bloco
```

Combates já incluídos em uma etapa paga de Lead, Incidente, Data Center ou evento não cobram novamente.

Uma mesma unidade narrativa nunca pode cobrar tempo duas vezes.

Toda atividade paga deverá mostrar antes da confirmação:

```text
custo;
período final;
bloco final;
se atravessará DAY/NIGHT;
se há tempo suficiente;
se algum evento pode expirar.
```

Ações podem atravessar de DAY para NIGHT, mas não podem ultrapassar o fim absoluto do dia sem autorização explícita do conteúdo. Essas regras estão detalhadas na seção de tempo do GDD atualizado. 

## 2.3 Player Actions

As Player Actions finais são:

```text
SCAN
PURGE
PURIFY
TAME
```

Cada slot da Timeline dedicado a uma Player Action adiciona 25% de progresso ao alvo. Elas substituem Modules naquela posição do ciclo e não são uma tela pós-combate separada. 

```text
SCAN
→ LOGIC
→ Module ativo específico escolhido

PURGE
→ SELF
→ Module ativo aleatório + EXP aumentada

PURIFY
→ SYNC
→ Module passivo relacionado

TAME
→ contextual
→ substituição permanente do parceiro

Derrota normal do EXE
→ EXP e drops comuns
```

VALOUR ainda não possui uma Player Action própria. O GDD marca isso como uma lacuna de design aberta; o sistema não deve inventar uma quinta ação neste roadmap. 

## 2.4 Persistência e Commitment

Antes da criação definitiva do Operator, o jogador escolhe:

```text
SAFE MODE
COMMIT MODE
```

Safe Mode permite retornar a saves anteriores. Commit Mode mantém um registro vivo e salva imediatamente eventos irreversíveis. 

Partner Loss, TURD, Operator Loss, mudança de infestação, TAME, evolução, avanço de dias e decisões irreversíveis deverão estar representados no schema de save desde o início, mesmo que nem todos sejam acionados obrigatoriamente pelo conteúdo principal da primeira semana. 

---

# 3. Estado atual confirmado do projeto

## 3.1 Sistemas com fundação funcional

```text
Desktop e chrome do KubuOS
WindowManager e WindowBase
Dock
Browser com abas
SimulatedDNS
WebsitePage e páginas customizadas
NULL CHANNEL
ForumThread e ForumPost
busca e filtros do fórum
threads lidas e observadas
notificações
TimeManager DAY/NIGHT
Navigator World Map
Navigator Local Area
movimento e interação top-down
transição Navigator → Combat → Navigator
CombatManager modular
grid 1x4
Timeline
reposicionamento
Modules
CombatEffectData
Status Effects
Unstability
slots de posição e ação mutáveis
Run Away
apresentação e animações de combate
estado temporário dos apps
```

O projeto já registra `TimeManager`, `CombatManager`, `GameState`, bancos do fórum, notificações e `AppSessionStore` como autoloads. Ainda não existem `SaveManager`, `CampaignState`, `StoryEventManager` ou sistemas equivalentes registrados.

## 3.2 Sistemas parcialmente implementados

### GameState

Atualmente armazena:

```text
flags;
variáveis numéricas;
threads lidas;
threads observadas;
histórico do Browser;
sites fixados.
```

Ele não possui exportação, importação ou reset completo para arquivos de save.

### AppSessionStore

Já possui:

```gdscript
export_save_data()
import_save_data()
```

Porém apenas armazena dados em memória. Nenhum arquivo é escrito em `user://`.

### Navigator

Já possui os modos:

```text
WORLD_MAP
LOCAL_AREA
ENCOUNTER
DIALOGUE
```

Também salva localização, posição e estado persistente dos objetos locais em seu session state. Entretanto, `DIALOGUE` ainda não possui player de diálogo, e o Navigator chama `TimeManager.advance_action()` diretamente para viagem, examine e resolução de combate.

### MapLocation

Já contém:

```text
ID;
nome;
posição no mapa;
requisitos de período;
requisitos de flags;
LocalAreaData;
custo de viagem;
SpawnTable.
```

O Resource está bem posicionado para continuar sendo a definição principal de um distrito.

### Combate

O `CombatManager` já controla encontros, times 1x4, Timeline, fuga, slots dinâmicos, movimentação e execução modular de efeitos.

A resolução atual, porém, contém somente:

```text
VITÓRIA ou DERROTA CRÍTICA
→ CONTINUE
→ CombatResult
```

Ainda não aplica XP, Modules, Player Actions, tendências, Enciclopédia, TAME ou Partner Loss.

O loadout do jogador também ainda é buscado diretamente no slot aliado `0` do `CombatEncounter`, portanto o parceiro não é uma entidade persistente de campanha.

### ConditionData

O sistema usa corretamente DAY/NIGHT, mas o Inspector ainda restringe os blocos a `0–5`:

```gdscript
@export_range(0, 5)
```

Isso impede condições nos blocos 6–11.

## 3.3 Sistemas ainda ausentes

A auditoria do repositório não encontrou implementações atuais para:

```text
ActivityManager
SaveManager
SaveMigrator
CampaignState
ContentRegistry geral
seleção de campanha
SAFE/COMMIT runtime
criação de Operator
OccupationData
agenda de ocupação
TendencyState
APKData
PartnerState
personalidades do APK
inventário persistente
progressão de nível persistente
AppCatalog
instalação/desbloqueio dinâmico de apps
StoryEvent
StoryEventManager
DialogueData
DialoguePlayer
NPCData
rotinas de NPC
Social App
Profile App
Calendar App
Encyclopedia App
LeadData
IncidentData
population/spawn controller
Combat Tendency Log
Player Actions
CombatResolutionService
EvolutionManager
Partner Loss
TURD runtime
Operator Loss
Legacy Site
infestação de áreas
```

O `main.tscn` atualmente coloca somente Browser e Navigator no dock.

---

# 4. Arquitetura-alvo

A campanha final deverá ser dividida em quatro camadas.

```text
CONTEÚDO IMUTÁVEL
Resources .tres
├── APKData
├── ModuleData
├── ItemData
├── NPCData
├── DialogueData
├── StoryEventData
├── LeadData
├── MapLocation
└── CombatEncounter

ESTADO MUTÁVEL
Dados serializáveis
├── CampaignState
├── OperatorState
├── PartnerState
├── InventoryState
├── SocialState
├── EncyclopediaState
├── WorldState
└── AppSessionStore

REGRAS
Managers e Services
├── ActivityManager
├── SaveManager
├── StoryEventManager
├── CombatManager
├── CombatResolutionService
├── EvolutionManager
└── PopulationController

APRESENTAÇÃO
Scenes e Apps
├── Browser
├── Navigator
├── Combat
├── Dialogue
├── Social
├── Profile
├── Encyclopedia
└── Calendar
```

## Regra fundamental de persistência

Resources definem **o que uma coisa é**.

O save registra **o que aconteceu com ela**.

Exemplo:

```text
APKData.tres
→ espécie, forma, stats de nível 100, sprites, branches

PartnerState salvo
→ apk_id, nível, EXP, HP atual, Modules e personalidade
```

Nunca salvar diretamente:

```text
Node
Texture2D
PackedScene
Callable
Signal
Resource completo
referência de objeto runtime
```

Salvar IDs estáveis:

```text
apk_id
module_id
item_id
npc_id
event_id
location_id
thread_id
dialogue_id
```

---

# 5. Ordem obrigatória de desenvolvimento

```text
FASE 0  — Documentação de continuidade
FASE 1  — Tempo e transações de atividade
FASE 2  — CampaignState e registros de conteúdo
FASE 3  — SaveManager, boot e modos de save
FASE 4  — Conditions, Effects e textos globais
FASE 5  — Catálogo e desbloqueio de aplicativos
FASE 6  — StoryEventManager
FASE 7  — Sistema de diálogos
FASE 8  — Criação do Operator e ocupações
FASE 9  — APK, parceiro, inventário e progressão
FASE 10 — Fechamento do combate
FASE 11 — Leads, Incidentes e população das áreas
FASE 12 — NPCs, Social e party mínima
FASE 13 — Profile, Encyclopedia e Calendar
FASE 14 — Commitment, Partner Loss e Operator Loss
FASE 15 — Construção do Prólogo
FASE 16 — Construção da primeira semana
FASE 17 — Hardening e validação final
```

Uma fase só começa depois que o gate de conclusão da anterior estiver passando.

---

# 6. FASE 0 — Continuidade do projeto

## Objetivo

Eliminar o problema de retomar o projeto sem saber onde ele parou.

## Criar

```text
docs/vertical_slice/ROADMAP.md
docs/vertical_slice/CURRENT_STATE.md
docs/vertical_slice/DECISIONS.md
docs/vertical_slice/TEST_MATRIX.md
docs/vertical_slice/CONTENT_MANIFEST.md
```

## Responsabilidade dos arquivos

### CURRENT_STATE.md

```text
Último sistema concluído
Sistema atual
Próxima tarefa exata
Arquivos sendo modificados
Bugs conhecidos
Testes que passam
Testes que falham
Último commit estável
```

### DECISIONS.md

Registrar decisões congeladas:

```text
12 + 12 ações
combate voluntário custa 2
Player Actions usam slots
Resources não são save
Prologue é CampaignPhase separada
Navigator contém World Map, Local Area, Dialogue e Combat
```

### TEST_MATRIX.md

Cada linha representa um fluxo testável:

```text
ID
pré-condição
ações
resultado esperado
estado
commit que validou
```

### CONTENT_MANIFEST.md

Listar todo conteúdo necessário para:

```text
Prólogo
Day One
Semana 1
Aquário
```

## Gate

Ao abrir o projeto depois de semanas, deve ser possível descobrir em menos de cinco minutos:

```text
onde o desenvolvimento parou;
qual arquivo abrir;
qual comportamento testar;
qual é a próxima fase.
```

---

# 7. FASE 1 — Tempo e transações de atividade

## Objetivo

Impedir cobranças duplicadas e retirar dos apps a responsabilidade de manipular diretamente o relógio.

## Corrigir imediatamente

### Modificar

```text
data/templates/condition_data.gd
```

Substituir os limites `0–5` por `0–11`.

## Criar

```text
data/templates/activity/activity_definition_data.gd
data/templates/activity/activity_preview_data.gd
core/autoloads/activity_manager.gd

systems/ui/activity_confirmation_dialog.tscn
systems/ui/activity_confirmation_dialog.gd
```

## ActivityDefinitionData

Campos finais:

```text
activity_id
display_name
description
action_cost
allow_cross_period
allow_cross_day
requires_confirmation
insufficient_time_message
confirmation_message
```

## ActivityManager

Responsabilidades:

```text
prever o horário final;
verificar disponibilidade;
considerar bloqueios de ocupação;
abrir confirmação;
iniciar uma transação;
cobrar o custo uma única vez;
registrar atividade incluída em outra;
emitir sinais de início e conclusão;
chamar TimeManager apenas depois da confirmação.
```

Fluxo:

```text
UI solicita atividade
→ ActivityManager cria preview
→ UI apresenta custo
→ jogador confirma
→ ActivityManager cria transaction_id
→ custo é aplicado
→ atividade inicia
→ sistemas filhos recebem o mesmo transaction_id
→ nenhuma atividade filha cobra novamente
```

## Modificar

```text
apps/navigator/app_navigator.gd
data/templates/navigator/map_location.gd
apps/navigator/local_area/interactions/local_area_interaction_data.gd
apps/navigator/local_area/actors/local_area_exe_actor.gd
core/autoloads/global_signals.gd
project.godot
```

Remover chamadas diretas de:

```gdscript
TimeManager.advance_action(...)
```

do Navigator e encaminhar tudo pelo `ActivityManager`.

## Gate

* Viajar custa exatamente uma vez.
* Combate voluntário custa dois blocos na confirmação.
* Combate interno de Incidente custa zero adicional.
* Ação de dois blocos pode atravessar DAY para NIGHT.
* Ação não ultrapassa o fim do dia.
* Cancelar confirmação não gasta tempo.
* Fechar uma UI durante confirmação não gasta tempo.

---

# 8. FASE 2 — CampaignState e registros de conteúdo

## Objetivo

Criar uma fonte única de verdade para a campanha e IDs resolvíveis para o save.

## Criar

```text
core/autoloads/campaign_state.gd
core/autoloads/content_registry.gd

data/templates/content/game_content_catalog.gd
data/content/game_content_catalog.tres

data/templates/campaign/operator_state_data.gd
data/templates/campaign/tendency_state_data.gd
data/templates/campaign/world_state_data.gd
data/templates/campaign/inventory_state_data.gd
```

## CampaignState

Responsável por:

```text
campaign_id
campaign_phase
save_mode
Operator atual
parceiro atual
tendências
dinheiro
inventários
Modules conhecidos
apps instalados
locais descobertos
Leads
Social
Enciclopédia
estado mundial
infestação
histórico de Operators
```

Não mover para `CampaignState`:

```text
cálculo de dano;
renderização;
navegação do Browser;
execução de diálogos;
lógica de Timeline.
```

## CampaignPhase

```text
NO_CAMPAIGN
PROLOGUE
MAIN_CAMPAIGN
OPERATOR_CREATION
OPERATOR_LOSS
CAMPAIGN_COMPLETE
```

## ContentRegistry

Deve indexar por ID as categorias que ainda não possuem banco próprio:

```text
APKs
Modules
Items
Occupations
Apps
Locations
Dialogues
StoryEvents
Leads
Incidents
```

Não duplicar:

```text
NetworkUserDatabase
ForumThreadDatabase
```

Esses bancos já existem e continuam especializados.

## Gate

* Criar uma campanha vazia.
* Inserir Operator, tendências, inventário e estado mundial.
* Resolver um `apk_id` ou `module_id` pelo ContentRegistry.
* Rejeitar IDs duplicados.
* Resetar toda a campanha sem reiniciar o executável.

---

# 9. FASE 3 — SaveManager, boot e modos de save

## Objetivo

Persistir a campanha em disco e restaurá-la depois que o processo do jogo for encerrado.

## Criar

```text
core/autoloads/save_manager.gd
core/save/save_migrator.gd
core/save/save_constants.gd
core/save/save_section_registry.gd

core/bootstrap/bootstrap.tscn
core/bootstrap/bootstrap.gd

systems/save/campaign_select.tscn
systems/save/campaign_select.gd
systems/save/new_campaign_panel.tscn
systems/save/new_campaign_panel.gd
```

## Modificar

```text
project.godot
core/main.tscn
core/autoloads/game_state.gd
core/autoloads/time_manager.gd
core/autoloads/app_session_store.gd
systems/window_manager/window_manager.gd
apps/navigator/app_navigator.gd
```

## Contrato de persistência

Cada sistema salvável implementará:

```gdscript
func get_save_section_id() -> String
func export_save_data() -> Dictionary
func import_save_data(data: Dictionary) -> void
func reset_save_data() -> void
```

## Schema principal

```text
save_version
metadata
├── campaign_id
├── save_mode
├── created_at
├── updated_at
└── last_checkpoint

time
game_state
campaign_state
app_sessions
window_states
navigator_state
world_state
combat_session
```

## Escrita atômica

```text
serializar
→ salvar em arquivo temporário
→ validar
→ mover save anterior para backup técnico
→ substituir save oficial
```

## Safe Mode

```text
vários checkpoints;
manual save;
autosave;
carregamento de checkpoints anteriores;
consequências continuam reais até o jogador carregar.
```

## Commit Mode

```text
um registro vivo;
sem seleção de checkpoints anteriores;
autosave em eventos irreversíveis;
backup técnico não aparece como opção de rollback.
```

## Checkpoints

```text
criação da campanha;
criação do Operator;
escolha do starter;
instalação de app;
viagem;
início de atividade complexa;
início de combate;
fim de cada ciclo;
fim de combate;
Player Action concluída;
evolução;
TAME;
Partner Loss;
Operator Loss;
troca de período;
avanço de dia;
escolha narrativa irreversível.
```

O save nunca ocorre durante tween ou animação. Em combate, salva após o estado lógico do ciclo ser concluído.

## CombatSession

Para restaurar entre ciclos, salvar:

```text
encounter_id
activity_transaction_id
cycle_index
times
actors
HP e Stability
status effects
slots
Modules equipados
Player Action progress
Combat Tendency Log
alvos resolvidos
```

Na carga:

```text
carregar CombatEncounter pelo ID
→ reconstruir participantes
→ reaplicar runtime state
→ reconstruir Timeline
→ abrir Navigator em ENCOUNTER
```

## Gate

Teste obrigatório:

```text
abrir Browser;
abrir duas abas;
entrar numa thread;
mover janela;
viajar;
andar na área;
iniciar combate;
executar um ciclo;
fechar o executável;
abrir novamente.
```

Todos os estados devem ser restaurados.

---

# 10. FASE 4 — Conditions, Effects e textos globais

## Objetivo

Permitir que qualquer conteúdo seja condicionado e produza efeitos sem código específico.

## Criar

```text
data/templates/conditions/condition_set_data.gd
data/templates/conditions/condition_rule_data.gd
data/templates/conditions/flag_condition_data.gd
data/templates/conditions/time_condition_data.gd
data/templates/conditions/location_condition_data.gd
data/templates/conditions/tendency_condition_data.gd
data/templates/conditions/affinity_condition_data.gd
data/templates/conditions/partner_condition_data.gd
data/templates/conditions/occupation_condition_data.gd

data/templates/effects/game_effect_data.gd
data/templates/effects/set_flag_effect_data.gd
data/templates/effects/modify_number_effect_data.gd
data/templates/effects/modify_tendency_effect_data.gd
data/templates/effects/unlock_app_effect_data.gd
data/templates/effects/discover_location_effect_data.gd
data/templates/effects/grant_item_effect_data.gd
data/templates/effects/grant_module_effect_data.gd
data/templates/effects/add_lead_effect_data.gd
data/templates/effects/modify_affinity_effect_data.gd

data/templates/text/global_text_catalog.gd
data/content/text/global_text_catalog.tres
```

## Migração

O `ConditionData` e o `EffectData` atuais deverão ser migrados para a arquitetura composta. Os `.tres` existentes serão atualizados na mesma fase; depois da migração, remover campos legados que duplicarem a nova lógica.

## ConditionSetData

```text
ALL
ANY
NONE
```

Cada conteúdo poderá combinar regras sem modificar o manager.

## GameEffectData

Cada efeito deve receber um contexto:

```text
source_id
target_id
location_id
activity_transaction_id
event_id
```

## GlobalTextCatalog

Concentrar textos de interface:

```text
botões;
labels;
erros;
confirmações;
menus;
mensagens genéricas;
nomes de tabs.
```

Conteúdo narrativo permanece nos Resources narrativos correspondentes.

## Gate

Um `.tres` deve conseguir:

```text
verificar dia, período, bloco, flag e tendência;
desbloquear localização;
instalar app;
adicionar Lead;
alterar tendência;
dar Module;
alterar affinity;
```

sem alterar o código da UI.

---

# 11. FASE 5 — Catálogo e desbloqueio de apps

## Objetivo

Remover a lista fixa de apps do `main.tscn`.

## Criar

```text
data/templates/apps/app_catalog.gd
data/content/apps/kubu_os_app_catalog.tres
```

## Modificar

```text
data/templates/app_resource.gd
systems/desktop/dock/kubu_bottom_dock.gd
core/main.tscn
```

## Campos novos de AppResource

```text
installed_by_default
unlock_conditions
sort_order
installation_effects
notification_data
```

## Estado instalado

A instalação pertence ao `CampaignState`, não ao `AppResource`.

```text
Browser
→ instalado por padrão

Navigator
→ instalado após escolha do starter

Profile
→ instalado junto do parceiro

Encyclopedia
→ instalado após primeiro registro válido

Social
→ instalado ao adicionar primeiro contato

Calendar
→ instalado ao começar a campanha oficial
```

## Gate

* Dock é reconstruído a partir do catálogo.
* Apps bloqueados não aparecem.
* Instalar app cria ícone sem reiniciar a cena.
* Save e load preservam apps instalados.
* Apenas uma instância de cada app é aberta.

---

# 12. FASE 6 — StoryEventManager

## Objetivo

Criar a camada que conecta tempo, flags, Browser, Social, Navigator, diálogo e combate sem acoplamento entre apps.

## Criar

```text
core/autoloads/story_event_manager.gd

data/templates/events/story_event_data.gd
data/templates/events/story_event_step_data.gd
data/templates/events/story_event_trigger_data.gd
data/templates/events/story_event_catalog.gd

data/content/events/story_event_catalog.tres
```

## StoryEventData

```text
event_id
priority
conditions
trigger
repeat_policy
steps
completion_effects
interruption_policy
```

## Steps iniciais

```text
SHOW_ALERT
SHOW_NOTIFICATION
OPEN_APP
NAVIGATE_BROWSER
START_DIALOGUE
START_ENCOUNTER
DISCOVER_LOCATION
INSTALL_APP
ADD_LEAD
APPLY_EFFECTS
START_ACTIVITY
ADVANCE_EVENT
```

## Fluxo

```text
tempo, flag ou localização muda
→ StoryEventManager recebe sinal
→ avalia eventos elegíveis
→ coloca eventos em fila
→ executa um por vez
→ salva o índice do step atual
→ aplica efeitos
→ marca evento concluído
```

O manager não acessa Nodes por caminho absoluto. Ele emite sinais e os apps respondem.

## Gate

Um `StoryEventData.tres` deve conseguir:

```text
abrir Browser;
navegar para uma página;
mostrar alerta;
desbloquear Navigator;
iniciar diálogo;
aplicar flag;
salvar.
```

---

# 13. FASE 7 — Sistema de diálogos

## Objetivo

Executar Visual Novels no container já reservado pelo Navigator.

## Criar

```text
apps/navigator/dialogue/dialogue_player.tscn
apps/navigator/dialogue/dialogue_player.gd

data/templates/dialogue/dialogue_data.gd
data/templates/dialogue/dialogue_node_data.gd
data/templates/dialogue/dialogue_choice_data.gd
data/templates/dialogue/dialogue_portrait_state.gd
data/templates/dialogue/dialogue_speaker_data.gd
```

## Cena

```text
DialoguePlayer (Control)
├── Dimmer (ColorRect)
├── PortraitLayer (Control)
│   ├── LeftSlots (HBoxContainer)
│   │   ├── Left1 (TextureRect)
│   │   ├── Left2 (TextureRect)
│   │   └── Left3 (TextureRect)
│   └── RightSlots (HBoxContainer)
│       ├── Right1 (TextureRect)
│       ├── Right2 (TextureRect)
│       └── Right3 (TextureRect)
└── DialoguePanel (PanelContainer)
    └── Content (VBoxContainer)
        ├── SpeakerLabel (Label)
        ├── DialogueText (RichTextLabel)
        ├── ChoiceContainer (VBoxContainer)
        └── AdvanceButton (Button)
```

## DialogueNodeData

```text
node_id
speaker_id
text
portrait_states
conditions
effects_on_enter
choices
next_node_id
```

## DialogueChoiceData

```text
choice_id
text
conditions
effects
tendency_changes
next_node_id
activity_definition
```

Até seis escolhas.

## Persistência

```text
dialogue_id
current_node_id
executed_node_effects
selected_choices
```

Efeitos não podem ser reaplicados ao recarregar.

## Modificar

```text
apps/navigator/app_navigator.gd
apps/navigator/local_area/interactions/local_area_interaction_data.gd
```

Implementar o handler `DIALOGUE`.

## Gate

* Diálogo linear.
* Seis retratos.
* Escolhas condicionais.
* Alteração de tendências.
* Alteração de flags.
* Ação paga.
* Save e load no meio da cena.

---

# 14. FASE 8 — Criação do Operator e ocupações

## Objetivo

Criar o personagem persistente antes do início oficial da campanha.

## Criar

```text
data/templates/operator/operator_profile_data.gd
data/templates/operator/appearance_data.gd
data/templates/operator/occupation_data.gd
data/templates/operator/occupation_schedule_data.gd

apps/browser/sites/null_network/register/operator_creation.tscn
apps/browser/sites/null_network/register/operator_creation.gd
```

## Campos do Operator

```text
first_name
last_name
nickname
username
server_id
occupation_id
gender
pronoun_set_id
avatar_id
appearance_part_ids
```

## Tendências iniciais

```text
15 pontos distribuídos entre:
VALOUR
LOGIC
SYNC
SELF
```

A soma precisa ser exatamente 15.

## OccupationData

```text
occupation_id
display_name
initial_money
recurring_income
schedule
starting_location_id
routine_event_ids
```

## Schedule

A ocupação não remove blocos do dia. Ela define quais blocos estão ocupados e quais eventos de rotina acontecem neles.

```text
NEET
→ maior disponibilidade
→ sem renda fixa

HIGH_SCHOOL_STUDENT
→ blocos escolares
→ mesada
→ conteúdo escolar

SALARYPERSON
→ blocos de trabalho
→ maior renda
→ conteúdo adulto/noturno
```

O ActivityManager consulta essa agenda antes de permitir uma atividade.

## Gate

* Criar cada uma das três ocupações.
* Distribuir 15 pontos.
* Salvar.
* Reiniciar.
* Restaurar perfil, aparência e agenda.
* Impedir atividade em bloco ocupado.

---

# 15. FASE 9 — APK, parceiro, inventário e progressão

## Objetivo

Separar a definição da criatura do estado persistente do parceiro.

## Criar

```text
data/templates/apk/apk_data.gd
data/templates/apk/partner_state_data.gd
data/templates/apk/apk_personality_data.gd
data/templates/apk/address_term_data.gd
data/templates/apk/apk_growth_profile_data.gd
data/templates/apk/apk_level_reward_data.gd

data/templates/items/item_data.gd
data/templates/items/inventory_entry_data.gd

systems/progression/apk_progression_service.gd
systems/progression/apk_stat_calculator.gd
```

## APKData

```text
apk_id
species_line_id
form_id
form_type
sprites
portraits
level_100_stats
stability_recovery
available_personalities
default_active_modules
signature_passive
learnable_modules
evolution_branches
```

## PartnerState

```text
apk_id
nickname
level
current_exp
current_hp
current_stability
affinity
personality_id
address_term_id
active_module_ids
known_active_module_ids
secondary_passive_module_id
allocation_points
allocated_stats
growth_lineage
integrity_state
```

## CharacterLoadout

Passa a ser:

```text
snapshot de entrada em combate
```

Não será mais a fonte permanente do jogador.

## CombatSlotData

Adicionar uma fonte de participante:

```text
FIXED_LOADOUT
PLAYER_PARTNER
PARTY_MEMBER
```

O slot aliado `0` do encontro usa `PLAYER_PARTNER`.

## Progressão

Implementar as fórmulas canônicas do GDD:

```text
nível 1–100;
barreira prática após 80;
HP, ATK, DEF, MATK e MDEF escalados;
Stability máxima fixa em 100;
Stability Recovery separada;
1 Allocation Point por level;
stats recalculados, não acumulados por arredondamento.
```

O GDD também determina que evolução mantém nível e EXP, recalculando imediatamente o corpo estatístico.  

## Gate

* Escolher starter.
* Gerar personalidade controlada.
* Definir tratamento do jogador.
* Entrar em combate usando o PartnerState.
* Ganhar EXP.
* Subir de nível.
* Distribuir ponto.
* Salvar e restaurar tudo.

---

# 16. FASE 10 — Fechamento do combate

## Objetivo

Transformar o combate atual em uma atividade completa de campanha.

## Criar

```text
data/templates/combat/player_action_data.gd
data/templates/combat/player_action_progress_data.gd
data/templates/combat/combat_reward_data.gd
data/templates/combat/combat_resolution_data.gd
data/templates/combat/combat_tendency_gain_data.gd
data/templates/combat/combat_tendency_log.gd
data/templates/combat/combat_style_rule_data.gd

systems/combat/combat_resolution_service.gd
systems/combat/player_action_service.gd

apps/combat/player_actions/player_action_selector.tscn
apps/combat/player_actions/player_action_selector.gd
apps/combat/resolution/combat_resolution_panel.tscn
apps/combat/resolution/combat_resolution_panel.gd
```

## Modificar

```text
apps/combat/combat_manager.gd
apps/combat/app_combat.gd
data/templates/module_data.gd
data/templates/combat_encounter.gd
data/templates/combat_slot_data.gd
```

## Player Actions na Timeline

Cada ação possui:

```text
MODULE
PLAYER_ACTION
EMPTY
```

Player Action precisa de:

```text
action_id
target_uid
progress_amount
```

## Combat Tendency Log

Registrar:

```text
combat_valour
combat_logic
combat_sync
combat_self
damage
critical_hits
scan_uses
support_uses
offensive_uses
corrupted_uses
allies_saved
enemies_defeated
stability_breaks
run_attempts
```

O log é temporário e não altera as tendências globais até a resolução. A Projected Tendency soma tendência global e tendência temporária para permitir evolução durante a luta. 

## CombatResolutionService

Responsável por:

```text
EXP;
level ups;
drops;
Modules;
Player Actions concluídas;
Combat Style;
tendências finais;
Enciclopédia;
estado do parceiro;
estado dos inimigos;
flags;
efeitos de evento;
resultado enviado ao Navigator;
save.
```

A UI não concede recompensa diretamente.

## Evolução

Criar:

```text
core/autoloads/evolution_manager.gd

data/templates/evolution/evolution_branch_data.gd
data/templates/evolution/core_requirement_data.gd
data/templates/evolution/evolution_catalyst_data.gd
data/templates/evolution/evolution_window_data.gd

apps/navigator/evolution/evolution_overlay.tscn
apps/navigator/evolution/evolution_overlay.gd
```

Checar principalmente:

```text
fim do ciclo
→ atualiza Combat Tendency Log
→ calcula Projected Tendencies
→ EvolutionManager verifica branches
→ pausa o combate
→ executa evolução
→ recalcula PartnerState
→ reconstrói Timeline
```

## Gate

Um combate deve suportar:

```text
matar normalmente;
SCAN 100%;
PURGE 100%;
PURIFY 100%;
TAME contextual;
ganhar EXP;
ganhar Module;
alterar tendência;
registrar Enciclopédia;
subir de nível;
evoluir;
fugir;
perder;
salvar entre ciclos.
```

---

# 17. FASE 11 — Leads, Incidentes e população das áreas

## Objetivo

Conectar Fórum e Social ao gameplay top-down.

## Criar

```text
data/templates/leads/lead_data.gd
data/templates/leads/lead_stage_data.gd
data/templates/leads/lead_catalog.gd

data/templates/incidents/incident_data.gd
data/templates/incidents/incident_stage_data.gd

apps/navigator/local_area/spawning/local_area_spawn_point.gd
apps/navigator/local_area/spawning/local_area_population_controller.gd
```

## LeadData

```text
lead_id
lead_type
title
source_type
source_id
location_id
conditions
stages
expiration_conditions
navigator_badge
```

## IncidentData

```text
incident_id
conditions
activity_definition
dialogue
encounter
effects
resolution_branches
```

## SpawnTable

Conectar a `SpawnTable` já presente no `MapLocation`.

Ao entrar:

```text
PopulationController
→ consulta MapLocation
→ filtra entradas por condições
→ escolhe encontros
→ instancia atores nos SpawnPoints
→ restaura atores já resolvidos
```

Encontros narrativos continuam explícitos na área. Encontros comuns usam a tabela.

## Gate

```text
abrir thread;
clicar em link;
receber Lead;
ver badge no Navigator;
viajar;
encontrar Incidente;
pagar atividade;
dialogar;
combater;
resolver;
ver fórum reagir.
```

---

# 18. FASE 12 — NPCs, Social e party mínima

## Objetivo

Implementar a primeira conexão humana persistente da campanha.

## Criar

```text
data/templates/npcs/npc_data.gd
data/templates/npcs/npc_routine_entry_data.gd
data/templates/npcs/npc_catalog.gd
data/templates/npcs/npc_personality_data.gd

data/templates/social/chat_profile_data.gd
data/templates/social/chat_conversation_data.gd
data/templates/social/chat_message_data.gd
data/templates/social/chat_choice_data.gd
data/templates/social/social_interaction_data.gd

apps/social/social_app.tscn
apps/social/social_app.gd
apps/social/contact_row.tscn
apps/social/chat_message_bubble.tscn

data/content/apps/app_social.tres
```

## NPCData

Referenciar `NetworkUserData` existente em vez de duplicar identidade de fórum.

```text
npc_id
network_user
real_name
npc_type
routine_entries
chat_profile
partner_apk_id
combat_loadout
personality_id
```

## SocialState

```text
known_contacts
affinity_by_npc
chat_history
unread_messages
last_interaction
planned_hangouts
party_state
```

## Escopo do vertical slice

```text
1 NPC principal
1 NPC secundário
1 contato desbloqueável
1 conversa significativa
1 interação flavor
1 DM que cria Lead
1 convite de party
1 mudança de affinity
```

## Party mínima

Implementar a arquitetura final, mas somente conteúdo de:

```text
party por objetivo;
um NPC aliado;
saída após objetivo.
```

## Gate

* NPC alterna online/offline pela rotina.
* Mensagem entra no histórico.
* Contato sobe para o topo.
* Interação significativa custa tempo.
* Affinity persiste.
* NPC entra no combate como `PARTY_MEMBER`.
* NPC sai ao concluir o objetivo.

---

# 19. FASE 13 — Profile, Encyclopedia e Calendar

## 19.1 Profile

### Criar

```text
apps/profile/profile_app.tscn
apps/profile/profile_app.gd
data/content/apps/app_profile.tres
```

### Exibir

```text
Operator;
ocupação;
ranking;
tendências;
parceiro;
nível;
EXP;
stats;
Modules equipados;
Modules conhecidos;
inventário;
affinity do parceiro.
```

O ambiente isométrico do parceiro deverá possuir a cena final extensível, mesmo que o vertical slice use arte greybox.

## 19.2 Encyclopedia

### Criar

```text
apps/encyclopedia/encyclopedia_app.tscn
apps/encyclopedia/encyclopedia_app.gd

data/templates/encyclopedia/encyclopedia_entry_data.gd
data/templates/encyclopedia/encyclopedia_state_data.gd

data/content/apps/app_encyclopedia.tres
```

### Registrar separadamente

```text
seen
scanned
defeated
purged
purified
tamed
lost
known_modules
known_locations
known_evolutions
```

A Enciclopédia contém informação confirmada. O fórum contém informação comunitária e especulativa. 

## 19.3 Calendar

### Criar

```text
apps/calendar/calendar_app.tscn
apps/calendar/calendar_app.gd

data/templates/calendar/calendar_event_data.gd
data/templates/calendar/calendar_catalog.gd

data/content/apps/app_calendar.tres
```

### Exibir

```text
data;
dia da semana;
DAY/NIGHT;
bloco atual;
blocos disponíveis;
dias até Update 1.0;
eventos conhecidos;
hangouts;
micro-update;
incidente de fim de semana.
```

## Gate

Após um combate:

```text
Profile mostra EXP e tendências;
Encyclopedia mostra o EXE;
Calendar mostra o próximo evento;
todos persistem após restart.
```

---

# 20. FASE 14 — Commitment, Partner Loss e Operator Loss

## Objetivo

Garantir que derrota tenha um estado final coerente, mesmo que o conteúdo principal do vertical slice não force essas consequências.

## Criar

```text
systems/commitment/commitment_service.gd
systems/commitment/partner_loss_service.gd
systems/commitment/operator_loss_service.gd

data/templates/world/area_infestation_state_data.gd
data/templates/world/operator_legacy_data.gd

apps/navigator/local_area/actors/legacy_site_actor.gd
```

## Partner Loss

```text
parceiro chega a 0 HP em combate definitivo
→ parceiro marcado como LOST
→ TURD atribuído
→ área ganha infestação
→ reações são enfileiradas
→ save imediato em Commit Mode
```

## TURD

TURD é um estado de contenção, não um starter alternativo.

```text
permite explorar;
permite lutar;
permite TAME;
permite reconstruir a campanha;
```

## Operator Loss

```text
TURD chega a 0 HP em situação definitiva
→ Operator arquivado
→ mundo e calendário permanecem
→ Legacy Site é criado
→ fluxo de novo Operator começa
```

O novo Operator perde relações, reputação, tendências, ranking e parceiro, mas entra no mesmo mundo e no mesmo dia. 

## Gate

Criar encontro de teste não-canônico que permita validar:

```text
Partner Loss;
TURD;
TAME de recuperação;
Operator Loss;
novo Operator;
continuidade do dia;
Legacy Site.
```

---

# 21. FASE 15 — Construção do Prólogo

Somente depois das fases sistêmicas anteriores começa a produção do conteúdo jogável.

## Decisão arquitetural

O Prólogo será:

```text
CampaignPhase.PROLOGUE
```

Não será representado como `days_passed = 0`.

Ao terminar:

```text
CampaignPhase = MAIN_CAMPAIGN
days_passed = 1
current_period = DAY
current_action_block = 0
```

Isso evita compensações de “Dia 0” em todas as condições futuras.

## Conteúdo necessário

### Sites

```text
denpa-channel
null.net
null.net/introduction
null.net/get-started
null.net/rankings
null.net/register
null.net/forums
null.net/download
```

### Eventos

```text
prologue.boot
prologue.denpa_opened
prologue.null_link_clicked
prologue.registration_started
prologue.registration_completed
prologue.forum_unlocked
prologue.welcome_available
prologue.welcome_read
prologue.download_available
prologue.app_installed
prologue.starter_selected
prologue.navigator_installed
prologue.first_area_entered
prologue.first_encounter_started
prologue.first_encounter_completed
prologue.completed
```

### Flags

```text
campaign.created
operator.registered
forum.account_created
forum.welcome_read
app.null_network.installed
partner.selected
app.navigator.installed
tutorial.navigator.completed
tutorial.combat.completed
prologue.completed
```

### Recursos mínimos

```text
3 OccupationData
5 starters em greybox funcional
1 área inicial
1 EXE
1 CombatEncounter tutorial
1 DialogueData do parceiro
1 thread WELCOME, NEW PLAYERS
1 página de registro
1 página de download
```

## Gate do Prólogo

Um jogador novo deve conseguir completar tudo sem usar ferramentas de debug.

Depois de fechar e reabrir:

```text
Operator;
starter;
apps;
threads lidas;
local;
inventário;
tendências;
tutorial;
```

devem permanecer corretos.

---

# 22. FASE 16 — Construção da primeira semana

## Segunda-feira — Micro-Update

Criar:

```text
1 changelog
1 alerta de boot
1 nota críptica
3–5 threads
1 Lead inicial
1 mudança de área ou spawn
```

Sistemas provados:

```text
StoryEvent;
Calendar;
Forum timing;
notificações;
Leads;
save.
```

## Terça-feira — Primeiro contexto

Criar:

```text
1 thread Rumours sobre o Aquário;
1 DM;
1 NPC disponível;
1 investigação simples;
1 escolha de tendência.
```

## Quarta-feira — Escalada

Criar:

```text
1 thread Help;
1 EXE diferente;
1 oportunidade de SCAN;
1 novo dado de Enciclopédia;
1 reação do parceiro.
```

## Quinta-feira — Preparação

Criar:

```text
1 Guide;
1 avanço de Lead;
1 escolha entre preparação e recompensa imediata;
1 oportunidade de party.
```

## Sexta-feira — Pre-Patch

Criar:

```text
alteração do contador;
glitches leves;
posts novos em threads antigas;
mudança de spawn;
moderação suspeita;
evento obrigatório curto.
```

## Sábado/Domingo — Incidente do Aquário

Criar:

```text
Aquário desbloqueado;
LocalArea própria;
2–3 subáreas;
2 EXEs comuns;
1 encontro anômalo;
1 NPC envolvido;
1 sequência de diálogos;
1 boss;
1 mecânica de hardware/UI;
1 escolha de resolução;
1 oportunidade de evolução;
reação do fórum;
encerramento do slice.
```

## Conteúdo do fórum

As pistas precisam existir antes do boss. O GDD exemplifica uma progressão em que rumores, screenshot apagada, pedido de ajuda e Guide surgem em dias diferentes, para que ganhem novo significado depois do encontro. 

## Gate da semana

O jogador pode ignorar parte dos Leads, mas o mundo continua avançando.

O Aquário deve poder terminar com diferenças observáveis em:

```text
tendências;
Modules;
EXP;
Encyclopedia;
affinity;
fórum;
parceiro;
estado da área;
flags narrativas.
```

---

# 23. FASE 17 — Hardening

## Testes automáticos e utilitários

Criar validadores para:

```text
IDs duplicados;
Resources sem ID;
referências quebradas;
CombatEncounter inválido;
APK sem Modules;
Dialogue sem node inicial;
next_node inexistente;
StoryEvent sem step;
Lead sem localização;
App sem scene;
save incompatível;
condição impossível;
efeito sem target.
```

## Testes de regressão

```text
novo jogo;
Safe Mode;
Commit Mode;
load no Desktop;
load no Browser;
load no Navigator;
load em Dialogue;
load em Combat;
load após resolução;
troca DAY/NIGHT;
troca de dia;
Operator Loss;
save corrompido;
backup;
migração de versão.
```

## UX

```text
custos sempre visíveis;
feedback de autosave;
feedback de app instalado;
badges de notificação;
botões desabilitados explicam o motivo;
nenhuma atividade consome tempo sem confirmação;
nenhuma recompensa aparece sem origem legível;
nenhum load coloca jogador em estado inválido.
```

## Performance

```text
nenhum vazamento ao fechar apps;
nenhum CombatApp duplicado;
LocalAreas descarregam corretamente;
Resources não são duplicados sem necessidade;
listas longas usam containers adequados;
save não serializa assets.
```

---

# 24. Sistemas fora do caminho crítico

Estes sistemas não bloqueiam o primeiro vertical slice:

```text
PVP completo;
party 4v4 avançada;
Data Centers completos;
geração total de NPCs Fodder;
todos os 60 NPCs;
todas as linhas de APK;
todas as evoluções;
Devil Mode;
CANON;
D-Day final;
ranking dinâmico completo;
economia completa;
lojas finais;
todos os tipos de infestação;
Legacy Recovery completo;
todos os hangouts;
todos os Variant Nodes;
arte final de todos os apps.
```

A arquitetura criada deve permitir esses sistemas depois, mas eles não entram no conteúdo da primeira semana.

---

# 25. Definition of Done do vertical slice

O vertical slice só estará finalizado quando todos os itens abaixo forem verdadeiros.

## Campanha

```text
[ ] Novo jogo funciona
[ ] Safe Mode funciona
[ ] Commit Mode funciona
[ ] Operator é persistente
[ ] Ocupação altera disponibilidade
[ ] Prólogo termina
[ ] Dia 1 começa corretamente
[ ] Primeira semana avança
[ ] Aquário pode ser concluído
```

## Save

```text
[ ] Save é escrito em disco
[ ] Save possui versão
[ ] Save possui backup
[ ] GameState é restaurado
[ ] TimeManager é restaurado
[ ] Apps são restaurados
[ ] Janelas são restauradas
[ ] Browser é restaurado
[ ] Navigator é restaurado
[ ] Dialogue é restaurado
[ ] Combat é restaurado entre ciclos
[ ] PartnerState é restaurado
[ ] Social é restaurado
[ ] Enciclopédia é restaurada
[ ] Leads são restaurados
```

## Tempo

```text
[ ] DAY possui 12 blocos
[ ] NIGHT possui 12 blocos
[ ] Ações atravessam período
[ ] Ações não ultrapassam o dia
[ ] Combate voluntário custa 2
[ ] Combate incluído não cobra de novo
[ ] Ocupação bloqueia horários
[ ] Custos aparecem antes da ação
```

## Combate

```text
[ ] Parceiro persistente entra no combate
[ ] Modules funcionam
[ ] Player Actions funcionam
[ ] SCAN concede escolha
[ ] PURGE concede recompensa
[ ] PURIFY concede passivo
[ ] TAME troca parceiro
[ ] Derrota normal concede EXP
[ ] Combat Style altera tendências
[ ] Enciclopédia é atualizada
[ ] Level up funciona
[ ] Evolução funciona
[ ] Fuga funciona
[ ] Derrota funciona
```

## Narrativa e mundo

```text
[ ] StoryEvents são data-driven
[ ] Dialogue é data-driven
[ ] Escolhas alteram estado
[ ] Fórum libera threads por condições
[ ] Leads conectam fórum ao mapa
[ ] Incidentes consomem atividades
[ ] NPCs seguem rotina
[ ] Social mantém histórico
[ ] Apps são instaláveis
[ ] Mundo reage às resoluções
```

## Arquitetura

```text
[ ] Nenhum app chama outro diretamente
[ ] Nenhum conteúdo depende de caminho absoluto de Node
[ ] UI não concede recompensa
[ ] CombatManager não altera CampaignState diretamente
[ ] Resources imutáveis não são usados como estado runtime
[ ] Save utiliza IDs
[ ] Sistemas globais são autoloads apenas quando necessário
[ ] Novo conteúdo pode ser criado principalmente por .tres
```

---

# 26. Ordem imediata de execução

A próxima sequência prática do projeto é:

```text
1. Criar os documentos de continuidade.
2. Corrigir ConditionData para 0–11.
3. Implementar ActivityManager.
4. Remover advance_action direto do Navigator.
5. Criar CampaignState.
6. Criar ContentRegistry.
7. Implementar SaveManager.
8. Criar Bootstrap e seleção Safe/Commit.
9. Tornar GameState, TimeManager, WindowManager e Navigator salváveis.
10. Validar save e load antes de criar qualquer novo app.
```

Até esses dez passos terminarem, não deve haver nova expansão de animações, novos tipos de Module, arte final de app ou produção extensa de conteúdo. O combate já possui uma fundação técnica avançada; o projeto precisa agora adquirir campanha, causalidade e persistência.

