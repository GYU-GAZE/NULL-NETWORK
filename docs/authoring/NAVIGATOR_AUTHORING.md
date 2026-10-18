# Autoria de locais e exploração no Navigator

## Criar um distrito pelo editor

Com Godot 4.6, habilite **Navigator Location Authoring** em Project → Project Settings → Plugins. O projeto já inclui essa configuração. Use Project → Tools → Create Navigator Location. O formulário chama o serviço de produção `LocationAuthoring.create_location`, valida o conteúdo, grava os arquivos, registra o mesmo `MapLocation` nos dois catálogos e abre a cena resultante.

| Campo do formulário | Conteúdo / efeito |
| --- | --- |
| Stable ID | Identificador estável válido, por exemplo `nakano_arcade`. Não reutilizar um ID existente. |
| Location name / Description | Nome e descrição apresentados no Navigator. |
| Map position | `X,Y` normalizados entre 0 e 1. A posição não é em pixels. |
| Destination folder | Pasta `res://`, sem `..`. Novos arquivos não sobrescrevem destinos existentes. |
| Existing scene | Opcional. Vazio cria uma cena a partir do template. Preenchido vincula um `PackedScene` existente sem duplicá-lo. |
| Travel ActivityDefinitionData | Caminho obrigatório para a atividade de viagem. O custo e a confirmação pertencem ao Resource. |
| SpawnTable | Opcional. Tabela de população comum da área. |
| Unlock ConditionRuleData | Opcional. Permissão de acesso, independente da descoberta. |
| Availability ConditionRuleData | Opcional. Disponibilidade momentânea, por exemplo horário e estado de campanha. |
| Marker texture | Textura opcional. O ícone e a cor também podem ser editados depois no Inspector. |
| GameContentCatalog | Por padrão `res://data/content/game_content_catalog.tres`. A ferramenta preserva o script concreto e todas as demais propriedades do catálogo. |
| NavigatorWorldData | Por padrão `res://data/content/navigator/world_map.tres`. Recebe referência ao mesmo Resource de localização registrado globalmente. |
| Category | Enum `MapLocation.LocationCategory`: STORY, SHOP, HANGOUT, DATA, SERVICE, TRANSIT, BOSS, OTHER. |
| Initially discovered | O marcador começa conhecido. Não concede permissão nem satisfaz Conditions. |
| Unlocked by default | Dispensa o desbloqueio legado por flags. Uma Condition explícita ainda precisa ser satisfeita. |

Ao criar `nakano_arcade`, a ferramenta gera `nakano_arcade.tscn`, `nakano_arcade_area.tres` e `nakano_arcade.tres`. Ao vincular uma cena existente, gera somente os dois Resources. O `LocalAreaData.area_id` é `nakano_arcade.local`; `default_entry_id` começa em `default`.

Os novos arquivos são gravados antes da substituição dos catálogos. Ambos os catálogos são serializados para arquivos `.pending` antes da primeira substituição. Se uma gravação/substituição falhar, o serviço restaura os catálogos já substituídos e remove os arquivos que criou. Há teste com falha real de gravação no segundo catálogo. Essa recuperação cobre erros retornados pelas operações; não equivale a uma transação de sistema de arquivos resistente a queda de energia ou a escritores concorrentes. Um `.pending` preexistente bloqueia a operação.

## Compor a cena local

O template usa `NavigatorLocalAreaScene` e inclui `Environment/Ground`, `WorldCollision`, `%EntryPoints/DefaultEntry`, `%Player`, `Interactables`, `%PopulationController/SpawnPoints` e `PopulationActors`. O chão é uma apresentação mínima editável. `WorldCollision` é um recipiente vazio: coloque nele os `StaticBody2D` e suas colisões conforme a geometria real da área.

O Player já é a cena compartilhada `player_controller_2d.tscn`. A entrada `default` está em `(160, 180)` e o Player aparece nessa posição no editor. Não crie outro controlador de movimento. Para entradas adicionais, use `LocalAreaEntryPoint` com `entry_id` único e mantenha `LocalAreaData.default_entry_id` apontando para uma entrada existente. `%Player` e `%EntryPoints` precisam ser nomes únicos na cena.

O controlador do template herda de `LegacyAwarePopulationController`; preserva a integração de Legacy Sites. Os pontos de spawn têm `spawn_point_id` único e `spawn_kind`: `COMMON_ENCOUNTER`, `LEAD_INCIDENT`, `NPC` ou `LEGACY_SITE`. O template oferece um de cada. Edite posições e adicione pontos de acordo com o espaço disponível. A quantidade de atores apresentados é limitada pelos pontos compatíveis disponíveis. `PopulationController.spawn_points_path` e `population_actors_path` devem resolver para a árvore de pontos e para um `Node2D` de atores.

Para uma cena existente, mantenha esses contratos. Não basta atribuir qualquer `PackedScene`: a validação recusa raiz errada, Player ausente, entrada padrão inexistente, IDs de entrada/spawn duplicados e caminhos de população inválidos. Uma localização com SpawnTable também precisa de controlador e ponto comum compatível.

## Descoberta, permissão e disponibilidade

`initially_discovered` e `LocationDiscoveryService` determinam conhecimento. `unlock_conditions` determina permissão. `availability_conditions` determina disponibilidade momentânea. As Conditions são os mesmos Resources usados pelo restante do jogo, inclusive conjuntos, flags, números, tempo, parceiro e afinidade; não existe uma linguagem paralela de regras de mapa.

Os campos legados continuam aceitos: `required_flags`, `unlocked_by_default` e `required_time_periods` (`DAY` / `NIGHT`). Descoberta só preserva o antigo desbloqueio implícito quando não existe restrição explícita de flags ou Condition. Um Lead que revela uma área não ignora uma restrição explícita dessa área.

Edite `locked_message`, `unavailable_message` e `no_area_message` para explicar a recusa. `show_when_locked` permite mostrar marcadores antes da descoberta; `reveal_identity_when_locked` controla o nome. Marcadores visíveis podem ser selecionados para inspeção enquanto o botão de entrada permanece desabilitado. As Conditions e chaves relevantes assinam mudanças de estado; o mapa reconcilia seus marcadores sem reconstruir todos a cada evento.

Locais narrativos ou de referência podem existir apenas como `MapLocation` no catálogo, sem `LocalAreaData`. Mantenha `travel_activity` e `spawn_table` vazios nesses casos. Não transforme Safehouse ou outras referências ocultas em distritos exploráveis apenas para satisfazer a ferramenta. O formulário cria locais exploráveis; referências narrativas são Resources editados no Inspector.

## NPCs físicos

Cadastre `NPCData` no catálogo global existente. Use seu `default_dialogue_id` para apontar a um `DialogueData` já registrado. `LocalAreaNPCActor` é uma projeção dessa identidade e usa TALK e o diálogo existente. Sem diálogo configurado, apresenta nome/status por EXAMINE; não inventa uma árvore de conversa.

Edite as rotinas existentes `NPCRoutineEntryData`: `routine_id`, `priority`, `weekday_indices` (domingo 0 até sábado 6), `day_blocks` (DAY 0–11, NIGHT 12–23), `location_id`, `physically_present`, `presence_state`, `status_text` e Conditions. A seleção usa `NPCData.get_active_routine()`. Estar ONLINE não implica presença física. A rotina ativa precisa marcar `physically_present` e corresponder ao local. Sem rotinas, aplica-se `default_location_id`; havendo rotinas e nenhuma ativa, o NPC fica ausente. As Conditions de descoberta do NPC também são respeitadas.

Adicione pontos NPC compatíveis na cena. O controlador descobre candidatos pelo catálogo e reage ao tempo/Conditions. Não coloque IDs de NPC em `NavigatorApp` nem duplique afinidade, contatos ou progresso de conversa em atores físicos.

## População comum e EXEs

`SpawnTable` continua usando `table_id`, `rolls_per_population`, `entries` e pesos. Cada `SpawnEntry` possui ID estável, nome, Conditions e um dos conteúdos: `encounter` autorado com `activity`, ou `environmental_apk` com descrição opcional. O segundo permite apresentar um APK ambiental sem exigir uma formação fixa. Sua interação atual é OBSERVE/EXAMINE, gratuita. A formação de Combat Call e a ecologia completa continuam como fronteiras futuras; a ferramenta não as simula.

`refresh_policy` controla a geração: PERIOD (padrão legado), DAY, ACTION_BLOCK ou CAMPAIGN. O seed considera campanha, local e chave da geração. Elegibilidade e renovação são diferentes: Conditions podem ocultar/reapresentar atores elegíveis na mesma geração sem rerrolar todos os slots. Atores resolvidos permanecem gastos até a política autorizar nova geração. Atores e pontos ainda válidos conservam instância e identidade; ao mudar de geração, um slot comum pode receber novo estado mesmo quando seu ID é reutilizado. O save persiste descritores/resoluções em `world_population`.

Incidentes continuam vindo de `LeadIncidentManager` e usam os pontos de incidente existentes. Os testes cobrem ativação pelo Fórum, aparição física, diálogo, combate incluído e conclusão da Lead. Não substitua essa autoridade por SpawnEntries de missão.

## Interações e tempo

Coloque uma instância de `LocalAreaInteractable` ou de seus atores especializados em `Interactables`, com colisão/sensor compatíveis. Seu `LocalAreaInteractionData` define ID, nome, verbo, tipo, texto, atividade opcional e `DialogueData`. Os consumidores existentes tratam EXAMINE, DIALOGUE e ENCOUNTER; `TRANSITION` e `CUSTOM` permanecem pontos de extensão e não devem ser usados esperando uma viagem automática implementada por esta fase.

EXAMINE e conversas sem atividade são gratuitas. Para ação paga, vincule `ActivityDefinitionData` e deixe o ActivityManager mostrar a confirmação. A viagem de produção custa 1 bloco e confirma o carregamento da área antes de liquidar o custo. Voltar ao mapa não apaga a posição física da campanha; retornar à região atual é gratuito e restaura a área. Viagem entre regiões é cobrada pela atividade do destino.

Combate voluntário mantém custo 2. `commit_time_on_completion=true` reserva esse custo: vitória/derrota paga ao finalizar, Run Away bem-sucedido libera a reserva com custo 0 e sem recompensas permanentes. Incidente pago mantém sua transação proprietária e cobra uma vez na confirmação; combate contido custa zero adicional. Não chame `TimeManager.advance_action()` em UI para implementar essas regras.

## Validar e persistir

`MapLocation.validate_data()`, `LocalAreaData.validate_data()` e `NavigatorWorldData.validate_data(catalog)` verificam estrutura e referências. No editor, a ferramenta não executa validadores de gameplay não relacionados que dependem de autoloads ativos. O teste de autoria em runtime também verifica `GameContentCatalog.validate_data()` no catálogo concreto.

O Navigator salva sessão versão 6 com posição, modo anterior ao diálogo e histórico local. Versões 1–5 continuam aceitas. População versão 1 é migrada para 2 preservando atores/resoluções. A seção opcional `activity_transactions` restaura antes de Dialogue/Combat/Navigator. Saves antigos sem essa seção não recebem cobrança retroativa. Transições em andamento bloqueiam o save até uma fronteira estável, quando é solicitado checkpoint.

Execute `tests/navigator/*test.tscn` para contratos de Fórum/foco, autoria, mapa, população, atividades e fluxo integrado. O EditorPlugin tem teste real via `tests/browser/run_editor_smoke.py --smoke-plugin res://tests/navigator/editor_smoke/plugin.cfg --marker 'LOCATION_AUTHORING_EDITOR_SMOKE: PASS'`, com `--godot`, `--workspace` e `--output`. Sem `--headless`, ele abre o editor nativo; `--capture` registra a renderização. O workflow `Navigator Validation` executa esses contratos e integrações existentes.
