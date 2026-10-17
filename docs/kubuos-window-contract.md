# KubuOS: contrato definitivo de janelas em 2×

## Base e diagnóstico

Implementação iniciada no HEAD `c388f2b17659f75131db1e3cf1bb831f9bf8416e`
da PR #40 (`refactor/modularity-pass-1`), ainda aberta e draft em 17/10/2026.
A branch de implementação é `refactor/kubuos-fixed-2x`; sua PR depende da #40
e tem `refactor/modularity-pass-1` como destino. Não fazer merge automático.

O contrato anterior tinha três espaços diferentes:

| Subsistema | Unidades anteriores | Problema encontrado |
| --- | --- | --- |
| `KubuDisplaySetting` | Tamanho físico da janela nativa; viewport lógico = físico / 2 | O desktop já era fixo em 2× |
| `KubuOSMetrics` | Unidades lógicas do desktop | Também calculava escala interna por densidade solicitada |
| `WindowBase` / manager | Retângulo externo em coordenadas locais do manager | Resize e clamp do manager corrigiam o mesmo retângulo separadamente |
| `AdaptiveScaleWindowBase` | VisualRoot local escalado em 1 ou 0,5 | A redução interna produzia 1× físico; mínimo do Resource era um breakpoint |
| `AppResource` | Default lógico relativo a workspace de referência; mínimo usado como breakpoint | A janela acabava usando mínimo separado de 96×12 |
| Workspace e desktop | Coordenadas lógicas do viewport; chrome em unidades lógicas | Manager repetia o cálculo das reservas |
| Motion player | Posição/tamanho locais do Control e escala visual transitória | Um último tick podia sobrescrever geometria após o sinal de conclusão |

A inspeção incluiu as cenas do manager, janela e desktop, `core/main.tscn`,
metrics/display, Resources de apps, workspace, dock, taskbar, motion, Browser,
Navigator e referências indiretas no projeto. `core/main.tscn` já separava
workspace, janelas e chrome nas camadas 5/10/20; essa composição foi preservada.

## Coordenadas e autoridade

Um pixel lógico do KubuOS corresponde permanentemente a **dois pixels físicos**.
O fator 2 é aplicado uma vez pela janela nativa. `WindowBase`, VisualRoot,
conteúdo e hitbox permanecem em escala local `(1, 1)`, independentemente do tamanho.

`WindowGeometry` é um cálculo puro, sem autoload nem estado de desktop.
`resolve()` ajusta tamanho e posição solicitados ao mínimo e à área útil;
`resize()` restringe somente as bordas móveis e preserva as bordas opostas.
Todos os resultados são inteiros lógicos. Mínimos são arredondados para cima.
Retângulos persistidos não finitos recebem posição da área útil e tamanho mínimo.

`WindowManager.resolve_window_geometry()` fornece a área útil e as regras
globais. A janela recebe esse resolver como Callable; o mouse produz uma
operação e aplica o resultado uma vez por `apply_resolved_geometry()`.
Os sinais `window_moved`/`window_resized` salvam estado; não fazem outro clamp.
Fixtures isoladas usam o mesmo cálculo puro com a área fornecida pelo host.

Mouse de GUI é convertido do Control de origem para o espaço local do manager.
Movimento capturado usa coordenadas do viewport e a inversa do transform com
canvas do pai. Não se multiplica novamente pelo fator físico 2.

O manager usa `KubuOSMetrics.get_work_area_rect()` também utilizado pelo workspace.
A taskbar superior e reservas laterais são respeitadas. O dock flutuante não
ganha uma nova faixa inferior reservada. Resize do display e alteração de métricas
cancelam gestos/transições, normalizam o retângulo de restauração e aplicam uma
única geometria atualizada.

O workspace de referência e o dimensionamento proporcional foram removidos.
`default_window_size` agora é utilizado diretamente, limitado apenas pela área útil.

## Superfície, inicialização e captura

`WindowBase` é a única classe de janela. A classe adaptativa, sua UID, histerese,
densidades mutáveis, signal de mudança de densidade e APIs de breakpoint foram
removidos. O Navigator perdeu somente a solicitação de breakpoint ao manager;
nenhuma regra de combate/RPG foi alterada. Breakpoints de layout responsivo do
Forum continuam válidos, pois não mudam a densidade.

VisualRoot e ResizeBorder derivam do retângulo externo tanto em notificações de
resize quanto na aplicação síncrona de geometria. O detector de perímetro foi
preservado; o overlay exclui os botões Close/Maximize para não engolir cliques.
Captura cobre movimentos fora do perímetro e termina com release, perda de foco
da janela nativa, maximização, fechamento ou saída da árvore.

O host de conteúdo passou a ser um `ScrollContainer` sem margens de tema.
Ele absorve overflow por mínimo intrínseco sem ampliar o retângulo externo nem
reduzir escala. Apps que já têm scroll mantêm seus próprios layouts. No tamanho
mínimo configurado, os seis apps de catálogo foram verificados sem overflow
externo; displays menores podem usar o scroll de segurança do host.

Ordem de abertura: instanciar shell → configurar resolver e Resource → aplicar
estado salvo/default/maximizado → sincronizar containers da shell → configurar
tamanho do app fora da árvore → adicionar app → restaurar sessão → emitir abertura
e foco. `mount_app()` garante que `_ready()` já receba o viewport final.

Os Containers do Godot normalmente ordenam filhos em um passo diferido.
A shell executa sua ordenação síncrona antes de montar o app; não há espera de
frames para corrigir inicialização. Reabertura de saves continua diferida até
as demais seções terem sido importadas, conforme o ciclo existente do SaveManager.

Janelas abrem/fecham por fade mantendo escala e posição estáveis. Maximização e
restauração animam retângulos com posições/tamanhos inteiros. O motion player usa
revisões monotônicas e encerra o tween antes de anunciar conclusão, impedindo que
um tick antigo sobrescreva um novo gesto. Flash de foco não restaura dimensões
antigas de containers. Fontes continuam sem antialias/subpixel, texturas em
nearest e o projeto habilita snapping de transforms 2D.

## Resource e Editor

No Inspector de um `AppResource`:

1. Defina `app_id` estável, `app_name` e a cena de conteúdo com raiz Control.
2. Para janela, use `PresentationMode.WINDOW`.
3. Configure `default_window_size` com o retângulo **externo** desejado em unidades
   lógicas, incluindo barra de título e margens. Exemplo: 600×400 ocupa 1200×800
   pixels físicos quando o display permite.
4. Configure `min_window_size` com o menor retângulo externo utilizável e mantenha
   o default igual ou maior. Ele não é um breakpoint.
5. Habilite `can_resize` se a janela permitir resize/maximização pelo usuário.
6. Faça o conteúdo adaptar layout ou usar scroll para regiões extensas. Não
   altere a escala da raiz nem implemente correções de geometria no app.
7. Para WORKSPACE, o WorkspaceManager fornece a área útil antes de `_ready()`;
   os campos de janela não governam sua geometria.

Resources revisados e validados no tema real:

| App | Default lógico | Mínimo externo lógico |
| --- | --- | --- |
| Browser | 600×400 | 400×300 |
| Social | 600×400 | 520×320 |
| Profile | 600×420 | 460×320 |
| Calendar | 640×420 | 560×340 |
| Encyclopedia | 640×420 | 560×340 |
| Settings | 480×340 | 380×310 |

Browser ganhou altura mínima para manter seu viewport em 2×; Settings ganhou
altura para os controles. Os defaults antigos de apps grandes deixaram de ser
proporções de um canvas de referência. Os mínimos mantidos nos outros quatro apps
foram confrontados com seus mínimos intrínsecos e superfícies reais.

Se o display for menor que o mínimo, o mínimo efetivo é limitado **por eixo** à
área útil. O mínimo declarado no Resource permanece intacto. Ao recuperar espaço,
a janela volta a respeitar o mínimo original. Nenhuma escala muda. Para áreas
degeneradas o cálculo usa pelo menos uma unidade lógica, evitando tamanho negativo.

## Foco e persistência

Clique, abertura, dock e alternância de teclado passam por `focus_window()`.
Alternar janela atualiza `focused_app_id`, z-order e `GlobalSignals.app_focused`.
Fechar a focada seleciona a próxima janela válida; sem janelas o workspace pode
recuperar foco pelo fluxo existente. Ativar workspace limpa o foco lógico da
janela sem criar outro estado paralelo. Apps WORKSPACE enviados ao manager são
encaminhados ao WorkspaceManager e não viram uma janela duplicada.

O save de janelas passa à versão 2 e aceita a versão 1. Os campos persistidos
continuam sendo retângulo externo lógico, área útil, escala física e maximização.
Saves adaptativos já guardavam a geometria externa: não se duplica seu tamanho.
Uma escala física histórica diferente de 2 usa o retângulo de trabalho salvo para
remapeamento proporcional uma vez; depois aplica o resolver atual. Saves menores
que o mínimo ou fora da tela recebem a mesma normalização de qualquer janela.
Sessões dos apps e seções dedicadas continuam usando suas APIs existentes.
Preparar save encerra transições; IDs de janelas fechadas/pendentes de queue_free
não entram na lista de apps a reabrir.

## Verificação e limites observados

`docs/validation/kubuos-fixed-2x-results.json` registra a comparação antes/depois
e o estado dos 11 checks do HEAD da PR #40. Baseline local: 39/55 cenas passaram.
Após a mudança: 40/56 passaram, incluindo o novo contrato; as mesmas 16 falhas
preexistentes permaneceram, sem nova cena falhando na comparação.

O teste novo cobre oito direções, limites extremos, 1000 retângulos determinísticos,
bordas opostas, hitboxes, release/cancelamento, coordenadas de pai transformado,
transições interrompidas, maximize/restore, importação v1, reabertura, `_ready()`,
foco/teclado, alterações de chrome/display e convivência com Navigator WORKSPACE.
Integra Browser, Forum, Social, Profile, Calendar, Encyclopedia e Settings reais.

Execução local com Godot 4.6 stable, Windows. O mesmo teste passou também com
renderização OpenGL real em GPU NVIDIA; capturas dos sete apps foram inspecionadas.
O workflow Desktop Shell passa a executar esse teste com Godot 4.6.3.

As 16 falhas restantes incluem dados/progressão, Encyclopedia (Rattildus e
milestones), bootstrap/save e o parse error preexistente de `kubuchan_thread_test`.
Passar a integração geométrica de Encyclopedia não significa que sua suíte de
dados tenha passado. Logs também registram avisos de anchors do mapa do Navigator
e recursos/RIDs ainda vivos ao encerrar. O código de domínio responsável por essas
falhas não foi modificado. Os resultados não são uma declaração de CI global verde.

Reprodução do contrato:

```sh
godot --headless --editor --path . --import
godot --headless --path . tests/window_manager/window_contract_test.tscn
godot --headless --path . tests/browser/browser_responsive_site_layout_test.tscn
godot --headless --path . tests/browser/browser_page_scroll_origin_test.tscn
```

Captura opcional com renderização real:

```sh
godot --path . --rendering-method gl_compatibility \
  tests/window_manager/window_contract_test.tscn -- \
  --capture-directory=/absolute/path/to/captures
```
