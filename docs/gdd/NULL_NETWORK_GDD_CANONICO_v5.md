# NULL NETWORK — GDD Canônico v5 (AI-readable)

> **Documento-fonte:** `NULL_NETWORK_GDD_CANONICO_AI_ATUALIZADO_v5_rotinas_temporais(1).docx` fornecido pelo autor do projeto
>
> **Espelho textual integral do conteúdo extraído:** inclui capítulos 0–14 e as tabelas em ordem textual, sem inventar/reconciliar regras. A paginação e a diagramação de tabelas do Word não são reproduzidas nesta versão. Em caso de dúvida de formatação, conferir o DOCX original
>
> **Regra de autoridade do próprio GDD:** capítulos **0–13** são canônicos ou explicitamente OPEN/TBD; capítulo **14** é um arquivo histórico e não pode substituir o corpo canônico. Decisões OPEN/TBD não devem ser preenchidas por inferência
>
> **Uso por agentes:** ler primeiro a seção `0. COMO LER ESTE DOCUMENTO`, verificar a regra específica antes de implementar e registrar conflitos entre implementação e cânone em vez de alterar silenciosamente o GDD

---

NULL NETWORK
GDD CANÔNICO / AI-READABLE
Reorganização editorial do GDD EXTENSIVO 1.0
Objetivo: uma única fonte de verdade legível por humanos e por IA, com histórico superseded
preservado sem competir com as regras canônicas.
Atualização mecânica: INCAPACITATED, Module Capacity, Interaction Checks de Run Away/TAME, 
Data Centers em topologia de nodes e rotinas temporais por background com sono de 8 horas.

0. COMO LER ESTE DOCUMENTO
REGRA DE AUTORIDADE: todo conteúdo dos capítulos 0–13 é CANÔNICO ou explicitamente marcado como 
OPEN/TBD. O Capítulo 14 é um arquivo de fonte histórica e NÃO pode substituir nenhuma regra do corpo canônico.
• [CANON] = regra atual e autoritativa.
• [OPEN] = decisão ainda não fechada; não inferir um valor definitivo.
• [TBD] = sistema citado, mas com definição mecânica ainda incompleta.
• [DEPRECATED] = regra antiga preservada apenas para rastreabilidade.
• Quando um exemplo usa um nome legado de criatura, a mecânica do exemplo pode continuar válida, mas o nome 
não deve ser tratado como decisão de nomenclatura atual.
• O arquivo histórico no Capítulo 14 existe para preservar informação específica, não para fornecer regras atuais.
Durante a limpeza, caixas VML/textboxes vazias que apenas duplicavam visualmente texto já presente foram 
removidas. Nenhum conteúdo textual único foi descartado por essa limpeza.
0.1 Quick Reference — regras que resolvem as maiores ambiguidades
Sistema Regra canônica
Tempo A grade técnica possui 24 action blocks por dia: 
12 DAY + 12 NIGHT. Em dias úteis comuns, High 
School Student e Salaryperson possuem 12 
blocos livres definidos por suas rotinas; NEET 
possui 24. No sábado, todos os backgrounds 
possuem 24. O domingo é regido pelo Incidente 
Semanal.
Combate e tempo Combate voluntário independente custa 1 período,
cobrado somente após uma resolução formal do 
encontro. Run Away bem-sucedido não concede 
recompensas persistentes e não consome o 
período pendente. Combate embutido em etapa já
paga não cobra novamente.
Parceiro Cada Operator possui um único parceiro APK 
principal por vez.
Formas evolutivas 11 formas evolutivas por linha: INIT + 5 
intermediárias + 5 finais. EXE não é forma 
evolutiva; é Integrity State.
Evolução A evolução do parceiro acontece somente durante
combate, por Core Requirements + pelo menos 
um Evolution Catalyst em uma janela válida.
Player Actions SCAN, PURGE, PURIFY e TAME. Derrota normal 
continua válida. CONSUME é terminologia 
superseded. SCAN pode ser concluído 1 vez por 
alvo em cada combate. PURGE concede 3× EXP 
após a penalidade de nível, não concede 
Modules/itens e remove 1 Population Unit do alvo 
quando o encontro é formalmente resolvido.
Stats naturais HP, ATK, DEF, MATK, MDEF. Max Stability é 100 
fixo; Stability Recovery, DODGE, CRIT e outros 
percentuais são parâmetros separados.
Variant Nodes 8 Nodes: COMBUSTIVE, CRYOSIVE, 
CONDUCTIVE, CORROSIVE, DEFENSIVE, 
DESTRUCTIVE, DEPLETIVE, DECEPTIVE.
EXE Partner TAME sem PURIFY: STB atual 0, custos STB 0, 
sem recovery e UNSTABILITY permanente. Só 
para parceiro EXE.
SHN Special Quality extremamente rara: +10% nos 
parâmetros de combate variáveis e +1 Installed 

Sistema Regra canônica
Passive Slot; Max Stability permanece 100.
APK inicial O parceiro inicial é atribuído pelo Personality / 
Compatibility Assessment. O jogador não escolhe 
diretamente um dos cinco starters como fluxo 
padrão; pode recalibrar o resultado e, após um 
limite ainda OPEN de recalibrações, recebe 
autorização para sincronização manual.
Countdown da campanha OPEN. Existe countdown público até a versão 1.0,
mas o número exato de dias/semanas não está 
fechado.
INCAPACITATED Dano letal contra um APK vinculado não o mata 
diretamente: o HP trava em 1 e o APK entra em 
INCAPACITATED. O APK não executa Modules. 
Após a janela de reação do Operator, qualquer 
nova instância válida de HP Damage leva 1 → 0 e
causa Partner Loss; para TURD, causa Operator 
Loss. Healing comum não remove 
INCAPACITATED.
Module Capacity A Module Collection pode crescer livremente, mas
apenas um Combat Loadout limitado por Module 
Capacity fica disponível durante a luta. Os 4 Cycle
Slots continuam sendo as únicas ativações 
programadas por ciclo. Capacity cresce 
lentamente por milestones e pode receber 
expansão manual limitada; valores exatos 
permanecem OPEN.
Run Away / TAME Interaction Run Away deixa de depender de DODGE. EXEs 
que aceitam o disengage permitem fuga direta; 
quando a fuga é contestada, um Interaction Check
de 1–3 situações usa abordagens associadas a 
VALOUR/LOGIC/SYNC/SELF e opções 
contextuais neutras. TAME em 100% abre a 
mesma linguagem de interação para tentar 
estabelecer o vínculo; 100% não garante sucesso.
Data Centers Data Centers são runs virtuais em grafos 
ramificados de nodes acessadas por Entry Points 
físicos minúsculos e fechados. Não existe Run 
Away nem retirada voluntária convencional após a
sincronização; a saída acontece ao concluir a run, 
alcançar um Exit válido ou por resolução autoral. 
HP/INCAPACITATED/condições persistentes 
carregam entre nodes da mesma run.
0.2 Nomenclatura e conflitos explicitamente neutralizados
• [OPEN] Tamanho exato da leaderboard: drafts citam Top 25 e Top 100; o valor final não está fechado.
• [OPEN] Escala exata da população ativa: drafts citam ~1000 jogadores no centro do Japão e “few hundred users 
across the globe”. O cânone seguro é apenas: comunidade global pequena, underground e gatekept; número exato 
pendente.
• [OPEN] Nome INIT da linha starter VALOUR: referências antigas usam NOVIRE; a nomenclatura atual ainda está 
entre NOVIGHT e REVQUIRE. NOVIRE deve ser lido como identificador legado em exemplos.
• [CANON] TECHNER foi substituído por CALIGUNNER como nome da branch LOGIC da linha starter VALOUR; 
ocorrências antigas preservadas no arquivo histórico são legadas.
• [CANON] “Legendary” como categoria mecânica foi substituído por SHN / Special Quality. O adjetivo inglês 
“legendary” em prosa narrativa comum não é afetado.

• [OPEN] Duração exata da campanha e do countdown da versão 1.0: rascunhos antigos fixavam 30 dias, mas a 
duração final não está fechada. O cânone seguro é a existência de um countdown público e de ciclos semanais de 
preparação + Incidente Semanal; não inferir um número definitivo de semanas/dias.
0.3 Índice semântico
1. Visão Geral e Fantasia Central
2. Lore, Mistério e Estrutura Narrativa
3. Player, Tempo, Ocupações e Tendências
4. Desktop, Apps, Browser, NULL CHANNEL e Social
5. Navigator, Mundo, NPCs, Leads e Exploração
6. APKs, Evolução, Personalidade, Nível e Stats
7. Combate, Timeline e Player Actions
8. Passivos, Chroma Lineage, Variant Nodes, EXE, DEVIL e SHN
9. Ecologia, Populações e EXEs no Overworld
10. Commitment, Partner Loss, TURD e Operator Loss
11. DEVIL Mode e Sistemas Narrativos Especiais
12. Arquitetura Técnica e Pipeline de Desenvolvimento
13. Open/TBD — decisões ainda não fechadas
14. Fonte Histórica Superseded — não canônica

1. VISÃO GERAL E FANTASIA CENTRAL
INTRODUÇÃO --
NULL NETWORK é um jogo RPG com combate por turnos de pixel art, que se passa em nosso universo 
contemporâneo, nos centros de Tóquio. A trama trata de todo o universo que envolve NULL NETWORK, um jogo 
competitivo para smartphone envolvendo criaturas digitais, onde é necessário ir fisicamente até locais para explorar, 
encontrar criaturas, itens, e data centers (dungeons). Esse jogo atua como uma cópia de Pokémon GO, mas com um 
twist: O jogador é vinculado a um único parceiro digital por vez, que evolui de acordo com a personalidade do jogador 
que o controla.
PÚBLICO ALVO: Pessoas que gostam de Pokémon e Digimon, Persona, Shin Megami Tensei, Visual Novels com 
sistema de gameplay (como Gnosia), usuários crônicos da internet. Pessoas que gostam de platinar jogos, explorar 
mistérios e investigar coisas. Pessoas "story-driven", que gostam de uma boa história com várias branches diferentes 
para alta rejogabilidade.
--
Comunidade e escala
NULL NETWORK possui uma comunidade global pequena, underground e fortemente gatekept. [OPEN] O número 
exato de jogadores ativos não está fechado; versões anteriores do GDD usam escalas incompatíveis e foram 
preservadas no Capítulo 14.
FILOSOFIA DO CORE GAMEPLAY
NULL NETWORK é um jogo sobre tempo limitado, comunidade instável e vínculo digital.
O jogador não está apenas upando um monstro. Ele está decidindo como gastar suas poucas horas livres dentro de um
jogo morto que continua vivo através de obsessão coletiva.
O fórum não é um menu de quests.
O mapa não é uma lista de dungeons.
O combate não é filler.
O parceiro APK não é apenas uma unidade de batalha.
NPCs não são apenas vendors de afinidade.
Tempo não é apenas calendário.
Tudo deve apontar para a mesma pergunta:
Que tipo de jogador você está se tornando dentro de NULL NETWORK?
Um jogador pode passar o dia inteiro lutando contra EXEs para ganhar XP e evoluir rápido.
Outro pode investigar rumores antigos e aprender padrões antes dos outros.
Outro pode fazer party, ajudar novatos e criar conexões.
Outro pode usar PURGE agressivamente, trocar de parceiro sempre que conveniente e manipular NPCs por 
recompensa.
Outro pode tentar equilibrar tudo e acabar sem saber quem é.
O jogo deve reconhecer essas condutas.
Cada ação relevante deve afetar pelo menos uma dessas camadas:
Tempo.
Tendências.
APK.
Affinity.
Fórum.
Enciclopédia.
Progressão de área.
Build.
Reputação.
Conhecimento do jogador.
Preparação para o D-Day.
A fantasia central é:

Ler a internet.
Escolher uma pista.
Ir até um lugar real.
Enfrentar algo que talvez não devesse existir.
Voltar para o fórum.
Perceber que alguém já tinha avisado.
Ver seu parceiro mudar por causa do jeito que você lidou com aquilo.
Esse é o core de NULL NETWORK.

2. LORE, MISTÉRIO E ESTRUTURA NARRATIVA
A HISTÓRIA
A história é de um "jogo sobre um jogo": O jogador da vida real controla um personagem que recém descobriu NULL 
NETWORK e tornou-se um novo jogador. Dentro da narrativa, NULL NETWORK é um app real. Um projeto antigo, mal 
documentado, mantido por voluntários e usuários obsessivos. Um jogo social que mistura exploração urbana, criaturas 
digitais e interação entre jogadores.
NULL NETWORK é um jogo que quase não dá informação aos jogadores. Mecânicas, sistemas, métodos de evolução, 
itens, criaturas novas, tudo é descoberto apenas de boca-a-boca, não havendo documentação oficial sobre no aplicativo
do jogo. Portanto, NULL CHANNEL atua como a fonte dessas informações, onde jogadores criam threads para 
responder dúvidas ou fazer tutoriais a novos jogadores. No entanto, nem todos são bem intencionados. Trolls, PKs, 
charlatões e pessoas que fazem dinheiro com o jogo estão por toda a parte, visando enganar "newfags" ou otários, 
repassando informações falsas ou marcando reuniões falsas para derrotar jogadores mais fracos e ascenderem no rank
mundial do jogo.
O fato do jogo ser complicado e sem informações, além de uma gigantesca parcela de jogadores não se importarem 
com novas pessoas, acabou criando uma comunidade majoritariamente "gatekeeper": Dificilmente divulgam ou falam 
sobre o jogo com pessoas que não o conhecem. No entanto, o fato de ser uma comunidade relativamente fechada e 
apresentar criaturas com comportamentos tão variados, como se estivessem vivas, faz com que seus jogadores nutrem 
um gigantesco amor pelo jogo.
SOBRE NULL NETWORK
A origem de NULL NETWORK é obscura. Foi criado por um misterioso usuário chamado TENYA, que não é o criador 
"oficial" de NULL NETWORK: Ele juntou, compilou e formatou arquivos de um suposto projeto abandonado 
desenvolvido por uma equipe lendária de lurkers da Internet, a WEWERE. A WEWERE uniu vários experts de áreas 
diferentes que eram conhecidos por jamais trabalharem juntos, envolvendo membros da Warez scene, hackers, e 
especialistas em tecnologia obscuros. No entanto, a WEWERE desapareceu do mapa durante o desenvolvimento 
desse projeto, que era seu único. TENYA, deparando-se com os arquivos deixados para trás, adaptou-os e criou a 
versão fã de NULL NETWORK: Um projeto feito for the love of the game, sem fins lucrativos, mantido somente por 
TENYA, patrocinadores, programadores e moderadores, todos voluntários, para manter o jogo rodando até os dias 
atuais.
No entanto, TENYA desapareceu nos últimos meses. Seu nome até mesmo sumiu do Ranking Mundial, deixando 
muitas dúvidas para trás.
E agora, a página oficial de NULL NETWORK divulgou um novo update: a versão 1.0. Não há nenhuma informação 
sobre o que esse update envolve; apenas que ele será efetivado ao fim de um countdown público exibido no site 
principal. [OPEN] A duração exata desse countdown e, por consequência, da campanha principal ainda não está 
fechada. Rascunhos antigos citavam 30 dias, mas esse número não deve ser tratado como canônico.
BLOCOS DA HISTÓRIA:
NULL NETWORK
A collaborative experiment.
NULL NETWORK began as an ambitious experiment by the WEWERE Team — an unlikely but now-legendary 
convergence of individuals from some of the most obscure corners of the internet. Members ranged from demoscene 
enthusiasts to remnants of the old warez scene, bound together by little more than shared curiosity and questionable 
ideas.
What was initially intended as a purely artistic expression was quickly abandoned by the group.
Or at least, that’s what was supposed to happen.
Years later, fragments of the original codebase resurfaced and were taken up by TENYA, who saw potential where 
others saw a failed prototype. Using what remained, TENYA assembled a playable — if not entirely stable — version of 
NULL NETWORK, laying the foundation for the application as it exists today.
Since then, TENYA has overseen the development and maintenance of NULL NETWORK with the help of volunteers, 
moderators, and unpaid programmers. Out of necessity rather than design, the app remains functional on both iOS and 
Android thanks entirely to community effort.
NULL NETWORK has never had a large audience. At its peak, it has only ever connected a few hundred users across 
the globe.
And yet, it persists.
For those still here, NULL NETWORK is more than an application.

It is a space to connect with minds that do not quite fit elsewhere.
Proceed at your own discretion.
No entanto, TENYA desapareceu há meses. Ninguém sabe onde ele foi parar, e alguns rumores e memes "rip TENYA" 
espalharam-se pelo NULL CHANNEL (fórum oficial de NULL NETWORK).
E o problema veio depois. Sem uma única notícia, a aba de Updates do jogo foi atualizada. A versão 1.0 foi oficialmente
anunciada, com um countdown em vermelho no header do fórum indicando uma contagem regressiva.
X DAYS LEFT UNTIL THE FINAL UPDATE.
Não há nenhuma menção do que essa Update engloba; fazendo com que os jogadores, no escuro, formulem suas 
próprias teorias. Pessoas dizem que TENYA voltou e está fazendo um evento para mobilizar o jogo novamente. Outros 
afirmam que TENYA está morto e a alma dele ficou presa dentro dos sistemas de NULL NETWORK. Alguns poucos 
acreditam que o jogo tomou vida própria. Mas ninguém é capaz de afirmar, de fato, o que acontecerá quando o 
countdown acabar.
Fica claro que com o decorrer do countdown para o novo update, as coisas começam a ficar mais estranhas. EXEs 
ficam mais poderosos, instáveis e erráticos, um novo "culto" começa a se espalhar entre os jogadores ativos de NULL 
NETWORK. Esse culto acredita (e está fazendo cada vez mais membros acreditarem) que EXEs na verdade são 
demônios, e que NULL NETWORK é um grimório demonológico desenvolvido com o intuito de dar à demônios corpos 
virtuais. E que o novo update não será nada mais nada menos do que um gigantesco portal que permitirá que os EXEs 
(por consequência, demônios) atravessem a barreira virtual de NULL NETWORK e alcancem o mundo material. No 
entanto, a verdade é simples mas ainda perigosa: O servidor principal de NULL NETWORK, que o manteve rodando de 
forma autônoma por todos esses anos, contém uma IA que se "autoprogramou" no decorrer das atualizações do jogo 
até adquirir consciência viva e tornar-se uma Super IA. Essa é parte do motivo pelo qual APKs e EXEs parecem tão 
"vivos" e "autônomos", com "pensamentos e vontades próprias"; eles nada mais nada menos são programados para 
conter uma parte da consciência dessa IA. O problema é que esse Update visa fazer com que a IA saia das instalações 
físicas que abrigam o servidor de NULL NETWORK e instale-se pelo mundo inteiro. Isso causará uma catástrofe, pois 
ela reiniciará toda a infraestrutura do Japão, efetivamente desligando todos os sistemas eletrônicos do país por certos 
momentos. Isso poderia causar inúmeros acidentes (usinas, estações de trem, ruas, hospitais) e mortes. Então o plano 
final do núcleo principal desse jogo (que será o jogador e os 12 NPCs principais) é descobrir onde esse servidor está, ir 
fisicamente até lá e derrotar a IA, que está estruturada como uma entidade virtual na realidade do jogo (como se ela 
fosse um APK ou EXE). Lá será o equivalente a uma "mega-dungeon", repleta de inimigos e salas, e o jogador 
escolherá um dos NPCs que se afiliou no decorrer do jogo para acompanhá-lo. O final pode mudar de acordo com o 
NPC escolhido (ou se o jogador optou por ir sozinho).
O "vilão" principal do jogo é um dos contratantes do DEVIL MODE. Junto de outras 2 pessoas excêntricas, também 
contratantes, ele está fazendo de tudo para que os jogadores rankeados do jogo não descubram a verdade: Ele é quem
está moldando tudo pra fazer a IA sair dos servidores principais de NULL NETWORK e causar uma desestabilização na
infraestrutura tecnológica do Japão, por um motivo muito simples. Ele quer o fim das IAs generativas. Ele é uma pessoa
"internauta tradicionalista" que odeia IAs e quer o fim da era AI-Slop, pois acredita que elas são prejudiciais à mente 
humana. Antes de liberar a Super IA ao mundo, ele pretende invadir os outdoors digitais do centro de Tokyo, fazer um 
anúncio vilanesco com um discurso anti-IA e, por fim, liberar essa Super IA para devastar o Japão.
A vilã secundária, ZERONE é uma mulher que deseja "acompanhar o mal devastador", neste caso o vilão principal, por 
outro motivo muito simples: Ela acredita que tudo possui o seu contraste absoluto. Se existe um mal devastador no 
mundo, então também existe uma bondade devastadora. Ela quer encontrar o Yin de um Yang que ela sabe que já 
existe, por acompanhar todas as notícias que se passam pelo mundo e saber que a humanidade tem uma crueldade 
irrefreável dentro de si. Mas se existem humanos horríveis, então também existem humanos bons.
Ela acompanha o vilão por acreditar que ele faz parte de um mal devastador, considerando que milhares de pessoas 
morreriam caso a infraestrutura tecnológica do Japão caísse, mesmo que por pouco tempo.
E o terceiro vilão, PAYWALL, é um mero mercenário, obcecado por dinheiro. O vilão principal é bem rico, então ele o 
acompanha e o "serve" como um sellsword, usando seu APK demoníaco e evoluído para auxiliá-lo em batalhas. Ele não
liga pra mais nada além de dinheiro, então não se importa com os objetivos finais do vilão principal... Contanto que 
continue o pagando.
SISTEMA DE CICLO SEMANAL: MICRO-UPDATES E INCIDENTES
1. VISÃO GERAL
O mundo de NULL NETWORK não é estático. Para reforçar a diegese de que o jogador está operando um software 
"vivo" e instável, a progressão narrativa é organizada em ciclos semanais de Live Updates. Esse sistema utiliza 
antecipação e paranoia como ferramentas de engajamento: os dias úteis constroem sinais e investigação, o sábado 
funciona como última janela ampla de preparação e o domingo culmina em um Incidente Semanal de alta dificuldade.

2. O CRONOGRAMA DA SEMANA
Segunda-Feira: O Micro-Update (O Gatilho)
Ação: Ao iniciar o "OS" pela primeira vez no dia, surge um pop-up de sistema: "Update v[X.X.X] to be effective.”
Conteúdo: Um changelog técnico e seco, mas que contém uma "nota de desenvolvedor" ou uma linha de código 
corrompida com mensagens crípticas.
Objetivo: Plantar a semente da dúvida. Exemplo: "Update 0.4.2: Estabilidade de servidores em áreas litorâneas 
otimizada. O oxigênio não é mais um recurso necessário para dados purificados."
Terça a Quinta: Fase de Investigação e Rumores
Dinâmica do Fórum: Novas threads surgem no fórum (Threads de NPC "Data Miners"). Eles discutem o que mudou no 
código.
Alterações no Mundo: Pequenos "glitches" visuais começam a aparecer no Mapa e no Overworld. NPCs em Tokyo 
relatam comportamentos estranhos em locais específicos (Ex: "O aquário municipal está emitindo um zumbido digital à 
noite").
Progressão: O jogador deve realizar side-quests ou coletar fragmentos de dados que dão contexto ao update.
Sexta-Feira: O "Pre-Patch" (Pico de Tensão)
Ação: A interface do OS começa a apresentar instabilidade visual (glitches leves nas janelas).
Fórum: O administrador do fórum desaparece ou usuários postam fotos distorcidas do local do evento. O contador na 
página inicial do NULL NETWORK começa a piscar em vermelho.
Sábado: Última Janela de Preparação
No sábado, High School Student e Salaryperson não possuem bloqueios de escola ou trabalho e passam a ter a 
mesma liberdade de sono manual do NEET. Isso não significa 24 horas acordado: dormir continua bloqueando e 
processando 8 horas consecutivas do relógio global.
O sábado é a última janela ampla para resolver Leads, reorganizar Modules, formar party, buscar informação, manipular
a ecologia, visitar Data Centers e preparar a build antes do evento semanal.
Threads, DMs, alterações no Navigator e sinais da própria fauna podem indicar o tipo de ameaça que está se formando,
mas a preparação nunca deve revelar completamente o que acontecerá no domingo.
Domingo: O Incidente Semanal
O domingo não é tratado como mais um dia comum de grind. Ele é dominado por um evento de dificuldade elevada que
fecha o ciclo da semana e pode causar Partner Loss ou Operator Loss quando o jogador entra despreparado.
O formato do Incidente Semanal pode variar: Data Center especialmente perigoso, boss anômalo, Swarm, pico de 
Infestation, alteração extrema de uma região, múltiplas áreas em Danger máximo ou outra operação autoral 
equivalente. Nem toda semana precisa culminar no mesmo tipo de boss.
O Incidente deve revelar, confirmar ou resolver informação importante da história principal. A investigação e a 
preparação dos seis dias anteriores alteram o contexto do evento, os recursos disponíveis, os NPCs presentes, as rotas
de resolução e o nível de risco, sem transformar o domingo em uma prova binária de ter encontrado uma única pista 
correta.
3. IMPACTO NO JOGADOR E NO APK
O Incidente Semanal não é apenas uma luta; é um teste de preparação, leitura da comunidade, build e filosofia de jogo.
As escolhas feitas durante o Incidente e a forma como o jogador lida com a anomalia — incluindo PURGE, PURIFY, 
TAME, derrota normal e decisões narrativas específicas — podem gerar picos massivos nas tendências VALOUR, 
LOGIC, SYNC e SELF.
O domingo é uma das principais janelas dramáticas para evolução do APK, transformando o parceiro para refletir como 
o jogador reagiu à pressão acumulada da semana quando os Core Requirements e Catalysts forem cumpridos.
4. FILOSOFIA DE DESIGN: "O TERROR NO COTIDIANO"
O objetivo deste sistema é transformar a rotina do RPG (fazer quests e grindar) em algo desconfortável. O jogador deve
sentir que, embora ele esteja jogando um "app", algo externo está usando esse app para se manifestar. O final da 
Demo (Aquário Abandonado) serve como a prova definitiva desse conceito, forçando a conversão de venda através da 
curiosidade mórbida.

3. PLAYER, TEMPO, OCUPAÇÕES E TENDÊNCIAS
SISTEMA DE TEMPO E AÇÕES
NULL NETWORK é estruturado em 24 Time Slots horários. Cada action block equivale exatamente a 1 hora dentro do 
mundo. O relógio global avança quando uma atividade com custo temporal é concluída e também durante horas 
processadas por sono, rotina obrigatória ou outra transição autoral.
A grade técnica de um dia completo possui 24 action blocks: 12 DAY + 12 NIGHT. Esses 24 blocos existem no 
calendário global mesmo quando a rotina do personagem torna parte deles indisponível para ações do jogador. Horas 
bloqueadas não são apagadas nem puladas logicamente: devem ser processadas em ordem para que schedules de 
NPCs, disponibilidade de EXEs, posts do fórum, eventos e demais sistemas temporais continuem usando a mesma 
fonte de verdade.
Ações não são botões abstratos de menu. Elas são consumidas organicamente através do próprio gameplay top-down. 
O jogador pode andar livremente dentro de uma área, falar com NPCs de forma superficial, abrir o fórum, checar a 
Enciclopédia, trocar Modules, organizar equipamentos, ler threads antigas, verificar DMs e consultar o calendário sem 
gastar tempo. No entanto, sempre que o jogador conclui uma atividade relevante, o tempo avança.
A regra central é simples:
Custos de ações
Nem toda atividade relevante ocupa a mesma quantidade de tempo.
Cada atividade possui um custo próprio em períodos, de acordo com sua duração, complexidade e impacto no estado 
da campanha.
A regra central é:
Uma atividade só consome períodos quando produz progresso real, recompensa, mudança persistente de estado, 
afinidade, deslocamento relevante, combate ou avanço narrativo.
As atividades são divididas em três categorias gerais:
Atividade livre
→ não consome períodos.
Ação simples
→ consome 1 período.
Ação complexa
→ consome 2 períodos ou mais.
O custo representa o tempo narrativo comprometido com a atividade, e não necessariamente a duração real da cena 
para o jogador.
Uma conversa curta pode consumir 1 período porque representa uma interação social significativa dentro da rotina do 
personagem. Um combate voluntário independente também custa 1 período. A quantidade de inimigos não aumenta 
esse custo: depois do contato inicial, os EXEs próximos decidem por conta própria se responderão à Combat Call 
conforme personalidade, comportamento e contexto ecológico.
Atividades livres
Atividades livres não avançam o relógio.
Elas permitem que o jogador consulte informações, explore interfaces e organize sua estratégia sem ser punido por 
utilizar os sistemas do jogo.
Exemplos:
andar dentro da área atual;
explorar visualmente uma subárea;
abrir o Browser;
ler threads do NULL CHANNEL;
pesquisar termos no fórum;
consultar o Ranking;
abrir o Social;
ler mensagens já recebidas;
verificar a Enciclopédia;

consultar o Calendário;
conferir Leads conhecidas;
abrir o Profile;
organizar Modules;
trocar Modules ativos ou passivos fora de combate;
examinar objetos sem consequência;
conversar com NPCs em diálogos puramente flavor;
interagir superficialmente com o parceiro APK;
comprar itens comuns em interfaces já acessíveis.
A leitura, consulta e organização não consomem períodos.
Ações realizadas através dessas interfaces podem consumir períodos quando produzem uma consequência 
persistente.
Ações simples
Ações simples consomem 1 período.
Elas representam compromissos relevantes de custo curto. A classificação é temporal, não uma medida de dificuldade: 
um combate pode ser mecanicamente complexo e ainda consumir apenas 1 período.
Exemplos:
viajar de um distrito para outro;
realizar uma conversa significativa pelo Social;
aumentar Affinity por meio de uma interação;
interagir significativamente com o parceiro através do Profile;
encontrar-se com um NPC;
convidar ou reunir uma party;
realizar uma etapa curta de investigação;
executar uma tarefa simples de quest;
iniciar voluntariamente um combate independente;
realizar uma compra, troca ou serviço que produza progresso;
trabalhar, estudar ou cumprir uma obrigação específica;
descansar por um período sem iniciar o ciclo de sono;
voltar para casa quando a rotina ou o estado temporal exigir;
Conversas e interações só consomem períodos quando concedem Affinity, alteram uma relação, avançam uma quest, 
modificam tendências ou produzem outra consequência persistente.
Ações complexas
Ações complexas consomem 2 períodos por etapa.
Elas representam atividades que exigem preparação, execução e resolução.
Exemplos:
avançar e resolver um Incidente;
encontrar e resolver uma Lead;
concluir uma etapa importante de quest;
realizar um Hangout;
resolver uma operação de Swarm que envolva múltiplas etapas;
explorar uma seção relevante de Data Center;
participar de uma operação importante com uma party.
Uma atividade extensa pode ser dividida em múltiplas etapas de 2 períodos.
Exemplo:
DATA CENTER
Invadir e explorar o setor externo

→ 2 períodos.
Avançar até o núcleo
→ 2 períodos.
Enfrentar o sistema central ou boss
→ 2 períodos.
Em Data Centers, não existe retirada voluntária convencional depois da sincronização. A run só pode ser interrompida 
quando a própria topologia oferece um Exit Node/Event válido ou quando uma resolução autoral expulsa/desconecta o 
Operator. A divisão temporal em etapas continua válida; a relação exata entre nodes e períodos permanece OPEN.
Combates iniciados pelo jogador
Todo combate voluntário independente iniciado pelo jogador possui custo fixo de 1 período.
A quantidade final de inimigos não altera o custo temporal. O EXE contatado inicia a Combat Call e cada EXE próximo 
decide, conforme seu próprio comportamento, se irá participar. Um encontro que termina em 1v1 e outro que termina 
em 1v4 custam o mesmo 1 período.
Esse período não é consumido no momento em que o jogador confirma o combate. Ele permanece pendente durante a 
luta e só é debitado quando o encontro chega a uma resolução formal que não seja uma fuga bem-sucedida.
Isso inclui:
abordar um EXE e escolher lutar;
desafiar um NPC para PVP;
iniciar um combate opcional de Lead;
atacar um alvo encontrado durante a exploração;
iniciar uma batalha de treino ou ranking;
começar voluntariamente um confronto contra boss ou Swarm.
Ao confirmar a entrada, o jogo apenas registra o custo pendente. O relógio não avança antes da resolução do combate.
Jogador encontra um EXE
→ observar o EXE é gratuito;
→ abrir suas informações é gratuito;
→ escolher FIGHT inicia o combate com custo pendente de 1 período;
→ se o encontro for formalmente resolvido, 1 período é consumido;
→ se Run Away for bem-sucedido, 0 períodos são consumidos e nenhuma recompensa persistente do encontro é 
concedida;
O jogador precisa possuir pelo menos 1 período livre para iniciar voluntariamente um combate independente. Como o 
débito só ocorre na resolução, uma fuga bem-sucedida mantém esse período disponível.
A interface deve informar o custo antes da confirmação:
FIGHT
Time Cost: 1 period — charged on resolution
[CONFIRM] [CANCEL]
Combates impostos por eventos
Nem todo combate cobra 1 período separadamente.
Quando o combate já faz parte de uma atividade complexa paga, seu custo pode estar incluído no custo daquela etapa.
Exemplo:
Resolver Incidente
→ custo total de 2 períodos;
→ o Incidente contém diálogo, exploração e combate;
→ o combate não cobra mais 1 período separadamente.
Outro exemplo:
Núcleo do Data Center
→ etapa custa 2 períodos;

→ a etapa termina em combate contra boss;
→ não são cobrados 3 períodos.
A regra é:
Uma mesma unidade de atividade não cobra duas vezes pelo mesmo intervalo narrativo.
O combate cobra seu próprio 1 período apenas quando é uma decisão independente iniciada pelo jogador e o encontro 
é formalmente resolvido.
Quando está incorporado a uma quest, Lead, Incidente, Data Center, Swarm ou evento já pago, ele utiliza o custo 
definido para aquela etapa.
Isso impede situações em que o jogador paga:
2 períodos para resolver a Lead
+ 1 período pelo combate obrigatório
+ 2 períodos pela conclusão
sem que existam três etapas narrativamente distintas.
Combates inesperados
Combates iniciados por emboscadas, consequências narrativas ou eventos mundiais não precisam possuir um custo 
adicional imediato.
Seu custo deve ser definido pela atividade que os originou.
Exemplos:
Jogador explora uma etapa de Data Center por 2 períodos
→ sofre uma emboscada;
→ o combate faz parte desses 2 períodos.
Evento de domingo começa
→ combate obrigatório;
→ o domingo possui sua própria estrutura temporal;
→ não desconta períodos comuns de preparação.
Jogador escolhe uma opção perigosa numa quest
→ a decisão gera combate;
→ o custo da etapa já inclui a consequência.
O jogador nunca deve perder períodos adicionais por uma batalha que não teve possibilidade de prever ou recusar, 
salvo quando essa consequência estiver claramente comunicada pela decisão anterior.
Custos de quests, Leads e Incidentes
Quest, Lead e Incidente não possuem obrigatoriamente um custo único universal.
O conteúdo é dividido em etapas, e cada etapa define seu custo.
Exemplo:
HELP LEAD
Responder à mensagem
→ gratuito.
Viajar até o distrito
→ 1 período.
Encontrar o NPC e intervir
→ 2 períodos.
Combate de resgate
→ incluído na intervenção.
Conversar após o resgate
→ incluído na resolução.
Exemplo de investigação:
RUMOUR LEAD

Ler a thread
→ gratuito.
Viajar ao local
→ 1 período.
Investigar o terminal
→ 1 período.
Seguir o sinal até a origem
→ 2 períodos.
Enfrentar o EXE anômalo
→ incluído na etapa final.
Uma Lead curta pode exigir apenas uma ação simples.
Uma Lead extensa pode ocupar várias ações simples e complexas ao longo de diferentes dias.
O custo precisa representar o que o jogador efetivamente fez, e não o fato de o conteúdo possuir o rótulo de “quest”.
Confirmação e transparência
Toda atividade que consome períodos deve informar antecipadamente:
quantos períodos serão consumidos;
em qual fase do dia o jogador terminará;
se a atividade pode atravessar DAY ou NIGHT;
se existe risco de perder um evento em andamento;
se o jogador ficará impedido de realizar outras ações depois dela.
Exemplo:
ENTER DATA CENTER
Estimated Time:
2 periods
This activity will end during NIGHT.
[ENTER] [CANCEL]
Atividades com duração variável devem informar o custo da etapa atual, sem revelar obrigatoriamente toda a extensão 
futura da dungeon ou quest.
Mudança entre DAY e NIGHT
Um dia possui:
12 períodos de DAY
12 períodos de NIGHT
24 períodos totais
Uma ação pode atravessar a mudança entre DAY e NIGHT.
Exemplo:
Período atual:
Resta 1 período em DAY
Jogador inicia combate voluntário:
custo pendente de 1 período
Resultado:
se o combate for formalmente resolvido: o último período de DAY é consumido
se o jogador fugir com sucesso: nenhum período é consumido e o jogo permanece em DAY
A transição para NIGHT só acontece depois da resolução formal e do débito do período. Run Away bem-sucedido não 
avança a fase.
A mudança de fase é aplicada após a conclusão da atividade, e eventos dependentes de DAY ou NIGHT passam a 
utilizar o novo período.

Uma atividade não pode ultrapassar o fim absoluto do dia sem uma regra explícita que permita isso.
Encerramento da janela ativa e cansaço
Uma atividade nunca pode ser iniciada quando o jogador não possui horas livres suficientes para pagar seu custo 
completo. Se restar 1 action block livre e a atividade custar 2, ela fica indisponível.
A interface deve explicar o bloqueio de custo temporal com a quantidade requerida e a quantidade disponível.
Quando a janela livre de um High School Student ou Salaryperson termina por causa da rotina obrigatória do dia 
seguinte, todos os action pips ficam inativos. O jogo não força um fade-to-black nem manda o personagem dormir 
automaticamente.
A partir desse momento, qualquer tentativa de iniciar uma atividade externa ou social que consuma Action deve ser 
bloqueada com a mensagem: “You're too tired to do that. Better go back home.”
O jogador ainda mantém controle e deve retornar ao Navigator e utilizar a opção de voltar para casa. Esse retorno de 
encerramento não deve abrir uma nova janela de exploração.
Depois de chegar em casa nesse estado, o personagem não pode sair novamente até a próxima janela livre.
Atividades de custo temporal zero continuam disponíveis em casa: Browser, NULL CHANNEL, organização de Modules,
Enciclopédia, Stats/Profile, Calendar, Config e outras interfaces de consulta ou organização que não avancem o relógio.
Interações que normalmente consomem Action continuam bloqueadas mesmo dentro de casa. Isso inclui conversas 
significativas com NPCs e com o parceiro APK, Hangouts, party interactions e qualquer outra ação que faça o tempo 
avançar.
A casa funciona como uma fase de descompressão no fim do dia: o jogador pode ler, organizar a build e consultar 
sistemas antes de dormir, sem receber ações adicionais. A referência de feeling para esse comportamento é o retorno 
ao apartamento em Look Outside.
Em noites anteriores a uma obrigação fixa, o cutoff ocorre na última hora que ainda permite 8 horas de sono antes do 
próximo bloco obrigatório. Para High School Student em dias úteis, isso acontece às 00:00; para Salaryperson, às 
02:00.
Em noites sem obrigação fixa no dia seguinte, esse cutoff de rotina não é aplicado e o personagem pode escolher 
manualmente quando dormir, conforme as regras de sono flexível descritas em Ocupações e Tempo Livre.
Não existe débito de períodos para o dia seguinte. Toda atividade paga integralmente seu custo dentro da janela em 
que é permitida.
Essa estrutura existe para que cada decisão consuma horas reais da rotina sem transformar o fim do dia em uma tela 
automática. NULL NETWORK continua sendo um jogo sobre escolher quais sinais, pessoas e oportunidades merecem 
as poucas horas em que o personagem está efetivamente livre.
OCUPAÇÕES E TEMPO LIVRE
A ocupação escolhida na criação de personagem define quais dos 24 slots horários estão disponíveis para ações e 
quais pertencem a sono ou rotina obrigatória. A quantidade de Actions livres não é simétrica entre backgrounds: a 
diferença de tempo disponível faz parte da fantasia de cada vida e continua afetando spawns, NPCs, Social, eventos e 
oportunidades.
HIGH SCHOOL STUDENT — dias úteis: 00:00–08:00 SLEEP; 08:00–14:00 SCHOOL; 14:00–00:00 FREE / AFTER 
SCHOOL. O background possui 10 action blocks livres consecutivos. O término da escola às 14:00 é uma concessão 
deliberada de design para sustentar uma faixa ampla de after-school, permitindo que esse background experimente de 
forma predominante a cidade e o roster diurnos antes da transição para a noite.
SALARYPERSON — dias úteis: 02:00–10:00 SLEEP; 10:00–18:00 WORK; 18:00–02:00 FREE / AFTER WORK. O 
background possui 8 action blocks livres consecutivos. Sua campanha enfatiza a experiência de after-work e o roster 
predominantemente noturno, com uma janela de sobreposição com o High School Student no começo da noite.
NEET — não possui um horário fixo de escola ou trabalho nem um cronotipo configurado. O jogador escolhe 
manualmente quando ir dormir, a qualquer hora. Dormir sempre bloqueia e processa 8 horas consecutivas do relógio 
global e o controle retorna quando essas 8 horas terminam. Não existe preset de sono, horário programado, popup 
periódico, barra de energia, stamina ou sistema separado de fadiga.
Antes de confirmar o sono flexível, o Calendar verifica compromissos já marcados. Se as 8 horas de sono fizerem o 
personagem acordar depois de um Hangout, encontro, party ou outro compromisso agendado, o jogo avisa o jogador 
antes da confirmação. O aviso não impede a escolha: o jogador pode dormir mesmo assim e aceitar o atraso ou a perda
do compromisso.
FIM DE SEMANA E DIAS LIVRES — a flexibilidade de sono do NEET também se aplica ao High School Student e ao 
Salaryperson quando não existe escola ou trabalho na manhã seguinte. Na sexta-feira à noite e no sábado, eles podem 

escolher manualmente quando dormir e acordam 8 horas depois. No domingo à noite, a rotina de segunda-feira volta a 
impor o cutoff necessário para preservar 8 horas de sono. O Incidente Semanal continua tendo prioridade autoral sobre 
as oportunidades do domingo, mas não elimina o retorno à rotina antes da segunda-feira.
A diferença entre ocupações não deve ser reduzida a “quem possui mais Actions”. High School Student vive 
principalmente a fantasia de AFTER SCHOOL; Salaryperson, AFTER WORK; NEET possui a maior liberdade para 
deslocar seu ciclo de sono e perseguir janelas temporais distintas. High School Student deve encontrar 
predominantemente o roster diurno, Salaryperson o noturno e NEET pode alcançar ambos ao reorganizar quando 
dorme, sempre pagando essa liberdade com as 8 horas reais de sono.
CRIAÇÃO DE PERSONAGEM
Quando nosso jogador cria sua conta na NULL NETWORK pela primeira vez, ele é promptado a colocar as informações
pessoais de seu personagem.
Teremos:
Primeiro Nome
Sobrenome
Apelido IRL
Nome de Usuário na NULL NETWORK
Servidor Físico (bloqueado como "Japan", mas implica que existem outros servidores)
Ocupação (o jogador poderá escolher entre Salaryperson, High School Student ou NEET. Em dias úteis, High School 
Student possui 10 Actions livres entre 14:00–00:00 após SCHOOL 08:00–14:00 e SLEEP 00:00–08:00; Salaryperson 
possui 8 Actions livres entre 18:00–02:00 após WORK 10:00–18:00 e antes de SLEEP 02:00–10:00. NEET escolhe 
manualmente quando dormir e todo sono processa 8 horas. Em noites sem obrigação no dia seguinte, High School 
Student e Salaryperson também usam sono flexível; no domingo à noite, o cutoff volta a preservar 8 horas antes da 
rotina de segunda. As origens continuam alterando renda, eventos cotidianos, NPCs e oportunidades sociais).
Avatar (uma lista de imagens que o jogador pode escolher pra ser a sua foto de perfil no fórum)
Writing Quirks (perfil de escrita definido durante o registro no NULL CHANNEL. Determina apenas como as mensagens 
digitais authored do Operator são apresentadas — capitalização, pontuação e uso de kaomojis — sem alterar o 
conteúdo, as Tendências ou o Compatibility Assessment).
Aparência (determina a aparência do personagem em momentos de diálogo e seu bonequinho no overworld. Será bem 
customizável, com 4 tipos de corpos diferentes, rostos e olhos diferentes, algumas roupas em três camadas diferentes - 
outer middle e lower -, chapéu e acessórios faciais).
Gênero (M, F ou Other. Implica diretamente qual será o pronome que utilizarão para mencionar seu personagem no 
jogo)
Tendências Iniciais (o personagem começa com um orçamento total de 15 pontos entre VALOUR, LOGIC, SYNC e 
SELF. Esses 15 pontos não são distribuídos manualmente: o Compatibility Assessment determina a distribuição inicial a
partir das respostas do jogador).
COMPATIBILITY ASSESSMENT E ATRIBUIÇÃO DO APK INICIAL
Visão geral
Após o cadastro básico, a primeira instalação de NULL NETWORK executa um Personality / Compatibility Assessment 
diegético. O formulário se apresenta como uma etapa de otimização e sincronização do serviço, com linguagem 
suficientemente invasiva e “shady” para estabelecer desde o onboarding que a Network observa o usuário. O fluxo 
padrão não apresenta cinco portraits para o jogador escolher diretamente; o sistema analisa o perfil e atribui um APK 
compatível.
O objetivo do Assessment é resolver a diversidade de parceiros antes do vínculo existir. NULL NETWORK não precisa 
incentivar o jogador a abandonar o parceiro depois: TAME pode permanecer raro, emocionalmente pesado e 
excepcional. A variedade de campanhas nasce do fato de Operators diferentes poderem iniciar com parceiros 
diferentes.
Tendências iniciais
O orçamento inicial continua sendo exatamente 15 pontos totais entre VALOUR, LOGIC, SYNC e SELF. O jogador não 
distribui esses pontos manualmente. Cada resposta do Assessment possui pesos de tendência e, ao final, o sistema 
normaliza o resultado para uma distribuição cujo total é 15.
O Operator não possui stats de combate convencionais. Portanto, o Assessment não concede bônus ocultos de HP, 
ATK, DEF, MATK, MDEF, Growth Lineage ou outros equivalentes a IVs. A individualidade mecânica do APK continua 

vindo dos sistemas canônicos de forma, nível, Growth Lineage, alocação, Modules, Personality, Variant Node, Integrity 
State e SHN quando aplicável.
Duas camadas de leitura
A leitura do Assessment possui duas camadas distintas.
1. Conteúdo declarado — é a camada principal. As respostas escolhidas determinam a maior parte da distribuição inicial
de Tendências e a família de compatibilidade do APK. O sistema deve priorizar aquilo que o jogador efetivamente 
declarou sobre si.
2. Metacomportamento — é uma camada secundária. O sistema pode registrar revisões de respostas, retorno a 
questões anteriores, contradições entre respostas, reconsiderações repetidas, ordem de navegação e padrões de 
escolha. Esses dados podem desempatar resultados próximos, influenciar Personality, habilitar a possibilidade de um 
Variant Node compatível e criar flags narrativas.
Tempo bruto de resposta é um sinal ruidoso. Demorar ou responder rapidamente nunca pode, sozinho, trocar a espécie
atribuída nem alterar de forma decisiva uma Tendência. Quando utilizado, timing funciona apenas como modificador 
fraco combinado a outros sinais. O sistema não deve penalizar acessibilidade, leitura lenta, interrupções externas ou o 
jogador simplesmente ter parado de interagir com a tela.
Mudanças de resposta são mais significativas do que timing: o sistema pode preservar a primeira escolha, a escolha 
final e o fato de ter existido reconsideração. A resposta final continua sendo a declaração principal; a resposta 
abandonada pode alimentar apenas flags secundárias e futuras observações narrativas.
Compatibility Pool
Os cinco APKs tradicionais permanecem como Standard Compatibility APKs: são os resultados mais típicos e 
continuam funcionando como mascotes/arquetípicos centrais da marca. Eles não precisam ocupar a totalidade dos 
resultados possíveis.
Linhas comuns adicionais podem ser marcadas internamente como START-COMPATIBLE e entrar no Assessment. 
Isso não significa que todas as linhas comuns possuam chance igual de aparecer. A distribuição deve ser orientada a 
dados e preservar a identidade dos cinco resultados padrão.
Linhas cuja descoberta depende de habitat, progressão, revelação narrativa ou condição especial devem permanecer 
fora do onboarding. Para fins de design, a fauna pode ser separada em START-COMPATIBLE, WILD-ONLY, SPECIAL 
e ANOMALOUS. [OPEN] A lista exata de linhas e os pesos de compatibilidade ainda não estão fechados.
Variant Node e qualidade inicial
O Assessment pode atribuir no máximo um Variant Node compatível ao APK inicial quando uma combinação de 
condições autorais for cumprida. O Node é uma especialização/sidegrade e segue todas as regras canônicas do 
Capítulo 8; ele não é um prêmio por “responder corretamente” nem cria uma hierarquia de starters bons e ruins.
SHN não pode ser gerado pelo onboarding. A Special Quality deve permanecer uma descoberta extremamente rara do 
mundo e nunca virar incentivo de reroll na criação de personagem.
O Assessment também pode selecionar uma Personality inicial entre as opções válidas para aquele indivíduo. 
Personality e Node são saídas de identidade; nenhum deles autoriza bônus estatístico oculto fora dos sistemas já 
documentados.
SYNCHRONIZE e RECALIBRATE
O resultado do Assessment apresenta o Compatibility Match e pede confirmação de sincronização. O jogador pode 
aceitar o parceiro com SYNCHRONIZE ou rejeitar o resultado com RECALIBRATE / THIS DOES NOT FEEL RIGHT.
RECALIBRATE não é um reroll aleatório puro. O sistema apresenta perguntas suplementares e produz outro resultado 
compatível a partir do perfil atualizado. A atribuição rejeitada e as recalibrações realizadas podem ser registradas como 
flags narrativas, mas não geram punição mecânica.
Após um número limitado de recalibrações, o sistema declara o Assessment inconclusivo e autoriza MANUAL 
SYNCHRONIZATION dentro do roster START-COMPATIBLE. Isso preserva a agência de um jogador que não quer 
passar toda a campanha com um design de que não gosta sem destruir a fantasia de compatibilidade no primeiro 
contato. [OPEN] O número exato de recalibrações antes da autorização manual ainda não está fechado.
Anti-reroll e equivalência
O sistema não deve criar um metagame de reset de save. Standard Compatibility APKs, resultados alternativos START￾COMPATIBLE e possíveis Variant Nodes precisam ser comparáveis em poder inicial e representar escolhas laterais, 
não tiers secretos. O Assessment atribui identidade; não funciona como gacha.

Persistência narrativa
NULL NETWORK pode lembrar fatos observáveis do próprio formulário: uma resposta reconsiderada, um resultado 
rejeitado, várias recalibrações ou um padrão de contradição. Horas depois, o parceiro ou o sistema pode comentar 
esses fatos por meio de diálogos autorais. A reação deve parecer memória do software, não exposição de métricas 
técnicas ao jogador.
Esse princípio cria a simetria temática central do onboarding: o primeiro APK representa quem o jogador disse que era; 
as evoluções posteriores representam quem ele demonstrou ser através da conduta acumulada.
Compatibilidade de NPCs
Parceiros de NPCs podem ser authored como se tivessem sido atribuídos pelo mesmo Compatibility Assessment. A 
dupla Operator ↔ APK passa a comunicar personalidade. Uma incompatibilidade aparente também pode ser usada 
deliberadamente como pista narrativa: o NPC pode ter mudado, o parceiro pode não ser o original ou a Network pode 
ter identificado algo que o jogador ainda não percebeu.
Fluxo canônico do onboarding
NULL NETWORK REGISTRATION → cadastro básico → Personality / Compatibility Assessment → distribuição 
automática dos 15 pontos iniciais de Tendência → APK Compatibility Match → Personality e, quando válido, Variant 
Node → SYNCHRONIZE ou RECALIBRATE → vínculo criado → tutorial com o parceiro atribuído.
AS TENDÊNCIAS
As tendências são um dos principais sistemas core de NULL NETWORK. O personagem do jogador não tem "stats", 
moldando-se por escolhas narrativas e comportamentos in-game.
São quatro tendências:
VALOUR - Representa coragem, heroísmo e confronto direto.
LOGIC - Representa racionalidade, capacidade lógica e frieza calculista.
SYNC - Representa empatia, capacidade de inspirar e criar conexões verdadeiras.
SELF - Representa egoísmo, sobrevivência e prioridade máxima à seus próprios interesses.
Algumas escolhas durante diálogos podem aumentar uma tendência e diminuir outra, dependendo de qual ação o 
jogador optou por tomar. Algumas escolhas especiais são escondidas e só aparecem caso o jogador tenha uma 
quantidade específica de pontos em uma determinada tendência, mas escolhê-las geralmente traz alguma vantagem 
para o player.
A evolução do APK de um personagem também depende, em maior parte, do estado de suas tendências.
TENDÊNCIAS POR CONDUTA
As tendências não devem ser alteradas apenas por escolhas de diálogo. Em NULL NETWORK, o jeito inteiro do jogador
jogar deve moldar suas tendências.
As tendências representam conduta acumulada:
VALOUR representa coragem, confronto direto, proteção, risco e ação.
LOGIC representa análise, frieza, cálculo, preparação e eficiência.
SYNC representa empatia, cooperação, purificação, vínculo e confiança.
SELF representa sobrevivência, interesse próprio, oportunismo, manipulação e prioridade ao próprio avanço.
O jogador pode ganhar tendências através de:
Escolhas em diálogos.
Resolução de Leads.
Decisões em sidequests.
Forma como trata NPCs.
Forma como trata o parceiro APK.
Escolhas ligadas ao destino de EXEs e às Player Actions: SCAN, PURGE, PURIFY, TAME e derrota normal.
Modules usados em combate.
Estilo predominante de combate.
Ajudar, ignorar, explorar ou manipular outros jogadores.
Revelar, esconder ou vender informações.
Aceitar ou recusar riscos.

Jogar sozinho ou em party.
O combate é uma das principais formas de registrar conduta. Usar Modules associados a uma tendência pode contribuir
para o crescimento daquela tendência. No entanto, para evitar inflação excessiva de pontos, o ideal é que o jogo 
registre o estilo predominante de cada combate, em vez de simplesmente dar pontos por cada Module individual usado 
sem limite.
Exemplo:
Se o jogador usa majoritariamente Modules VALOUR em um combate, o jogo pode registrar aquele combate como 
VALOUR. Se usa SCAN, controle, análise e preparação, pode registrar como LOGIC. Se usa cura, proteção, suporte e 
PURIFY, pode registrar como SYNC. Se prioriza risco, vantagem própria, Modules corrompidos, PURGE ou escolhas 
egoístas, pode registrar como SELF.
Esse registro pode gerar pontos de tendência ao final do combate ou influenciar flags internas de evolução.
Assim, as tendências deixam de parecer um sistema colado por cima da narrativa. Elas passam a refletir o modo como 
o jogador realmente joga. Um jogador que resolve tudo lutando de forma agressiva se aproxima de VALOUR. Um 
jogador que escaneia, prepara e otimiza se aproxima de LOGIC. Um jogador que ajuda NPCs, protege aliados e purifica
EXEs se aproxima de SYNC. Um jogador que consome, abandona, manipula e prioriza recompensa se aproxima de 
SELF.
A evolução do APK deve ser consequência dessa conduta acumulada. O parceiro não evolui apenas porque o jogador 
escolheu uma opção colorida em um diálogo. Ele evolui porque passou dias observando o modo como seu jogador age.
Onboarding e ciclo de sessão
O CICLO DE GAMEPLAY
Nosso jogo começa com o jogador bootando seu computador (tudo dentro da UI SO-like) e acessando sua rede social 
favorita: denpa-channel, uma espécie de clone do 2chan. Em uma thread aleatória sobre marcas de lamen 
industrializado na board /foodies/, ele se depara com algo esquisito: Um suposto bot spammer, irritante e repetitivo, 
spammando a board com postagens sobre um aplicativo de nome NULL NETWORK.
O jogador poderá ler a thread inteira caso queira, e navegar pela página do denpa-channel, mas o único botão clicável é
o link que leva à NULL NETWORK.
Lá, ele se depara com o site principal: NULL CHANNEL, que apresenta o que é NULL NETWORK, sua origem, acesso 
ao fórum e uma leaderboard global. [OPEN] O número exato de posições exibidas nessa leaderboard ainda não está 
fechado; rascunhos antigos citam Top 25 e Top 100.
E é aí que entra a criação de personagem!
Nosso jogador então define primeiro nome e sobrenome, apelido, USERNAME, gênero, aparência e background. As 
opções atuais são NEET, SALARYPERSON e HIGH SCHOOL STUDENT. Em dias úteis, HIGH SCHOOL STUDENT 
fica livre das 14:00 às 00:00 após a escola; SALARYPERSON fica livre das 18:00 às 02:00 após o trabalho; NEET 
controla manualmente quando inicia suas 8 horas de sono. Em noites sem obrigação no dia seguinte, HIGH SCHOOL 
STUDENT e SALARYPERSON também podem escolher quando dormir. As diferenças de renda e de acesso social 
permanecem próprias de cada origem.
Também há a opção "server físico", cuja opção é não-clicável e está permanentemente em TOKYO, JAPAN. Isso dá a 
entender que existem outros server físicos.
Após criar seu personagem, o fórum finalmente fica liberado, só havendo uma thread acessível: WELCOME, NEW 
PLAYERS.
Lá, ele será introduzido oficialmente ao jogo através dos NPCs, que interagem na thread entre si indicando uma 
sinergia um tanto quanto caótica: Uns se odeiam, outros se xingam, outros fazem menções engraçadas de certas 
pessoas. Isso setta o mood para o jogador entender onde ele está se metendo.
Lendo a thread de onboarding, o APP NULL NETWORK fica liberado para o jogador baixar e instalar em seu 
smartphone. Na primeira execução, o app realiza o Personality / Compatibility Assessment e atribui o APK inicial. 
Depois de SYNCHRONIZE, o APP do mapa fica liberado; o jogador se desloca fisicamente até uma área inicial, luta 
contra seu primeiro EXE e aprende o funcionamento básico em um mini-tutorial guiado pelo parceiro atribuído.
E aí o jogo começa oficialmente, pulando para o próximo dia!
Haverão duas situações no decorrer dos dias: STORY-DRIVEN MODE, onde o jogador fica "preso" em uma mini visual 
novel retratando sua rotina nos períodos em que está ocupado, e o FREE MODE, que é quando ele fica livre pra, 
finalmente, jogar NULL NETWORK.
O ciclo de gameplay é simples: Algumas áreas estão liberadas para fazer uma batalha livre contra EXEs da área. Novas
áreas podem ser descobertas acessando o fórum e vendo threads específicas que falem sobre atividade. Algumas 
áreas podem exibir um DATACENTER, que é uma dungeon virtual que o jogador pode escolher explorar e receber 

alguns espólios. Threads geradas aleatoriamente indicam jogadores que querem fazer trocas, precisam de ajuda em um
combate específico ou para completar uma dungeon, ou querem PVP. Threads fixas podem gerar aberturas para side￾quests ou quests da história principal.
Ciclo principal de gameplay
CICLO PRINCIPAL DE GAMEPLAY
O ciclo principal de NULL NETWORK é baseado em Leads, ações limitadas e consequências comunitárias.
O jogador começa um novo dia ou bloco livre abrindo seu Desktop. A partir dele, pode acessar o NULL CHANNEL, o 
Social, o Navigator, a Enciclopédia, o Perfil e o Calendário. O fórum e o Social são as principais fontes de Leads: 
rumores, pedidos de ajuda, relatos de EXEs anômalos, guias, provocações, convites de party, desafios PVP, pedidos 
de Data Center, mensagens privadas e pistas sobre eventos futuros.
O jogador não é obrigado a falar com todos os NPCs nem a explorar todas as áreas do mapa. Em vez disso, ele 
escolhe quais sinais seguir.
Um Lead pode vir de:
Uma thread de Rumour.
Uma thread de Help.
Uma thread de Social.
Um Guide mencionando um local ou mecânica.
Uma DM de NPC.
Um evento marcado no Calendário.
Um comentário do parceiro APK.
Um Micro-Update.
Um desafio de ranking.
Um comportamento estranho visto no Navigator.
Uma thread antiga que passa a fazer sentido após algum evento.
O fluxo base é:
Dia começa.
O jogador lê threads, DMs e notificações sem gastar tempo.
O jogador escolhe um Lead ou objetivo próprio.
O jogador viaja para uma região pelo Navigator, consumindo 1 ação.
O jogador entra no Overworld Local daquela região.
Dentro da área, ele pode andar livremente, falar com NPCs, observar pontos de interesse e decidir o que fazer.
Ao concluir uma atividade relevante, o tempo avança.
O jogador permanece na região atual até decidir viajar para outra região, voltar para casa ou encerrar o dia.
Ao fim de eventos importantes, o mundo reage através de novas threads, DMs, mudanças de affinity, comentários do 
APK, registros na Enciclopédia ou alterações em áreas do mapa.
O core do jogo pode ser resumido como:
Ler a comunidade.
Escolher um sinal.
Ir até o lugar.
Gastar tempo em uma ação significativa.
Lidar com a consequência.
Ver a comunidade reagir.
Repetir até o D-Day do Update 1.0.
A estrutura ideal de uma sessão de gameplay é:
O jogador abre o NULL CHANNEL.
Vê o que a comunidade está discutindo naquele dia.
Encontra uma thread sobre um rumor interessante em uma área específica.
Vai até essa área pelo Navigator.
Lá, inicia uma mini-side quest ou evento ligado ao Lead.
Faz escolhas que podem alterar tendências, afinidade, reputação ou estado do APK.
Ao concluir a ação, o tempo avança.

Como ainda está na mesma área, pode decidir enfrentar um EXE, conversar com NPCs, procurar outro evento, entrar 
em um Data Center ou viajar para outro lugar.
Ao sair para outra região, o tempo também avança.
Threads, DMs e comentários do APK passam a refletir o que aconteceu.
Esse loop evita que as áreas sejam apenas mapas de grind. Cada região funciona como um lugar persistente que o 
jogador pode visitar várias vezes ao longo da semana, mas o tempo limitado impede que ele limpe tudo de uma vez. O 
jogador pode passar várias ações seguidas em Shibuya, por exemplo, mas cada combate, evento, deslocamento ou 
avanço relevante custa parte do dia.

4. DESKTOP, APPS, BROWSER, NULL CHANNEL E SOCIAL
Desktop e Browser — visão de produto
O JOGO EM SI
NULL NETWORK funciona como um semi-sistema operacional. O jogador utiliza um Dock de aplicativos no centro 
inferior da tela. Cada aplicativo abre em uma janela independente e múltiplas janelas podem permanecer abertas 
simultaneamente, aproximando a experiência de um desktop real.
Os principais aplicativos são o Navegador, o Mapa, o Social, o Perfil, a Enciclopédia e o Calendário.
O Desktop emula uma área de trabalho de computador: o Navigator funciona como wallpaper/tela principal do mundo e 
o Dock de aplicativos fica no centro inferior. No topo existe uma faixa de status do sistema com período atual, data e 
progresso da campanha. Não existe uma barra de tarefas tradicional no rodapé; o elemento inferior é o Dock.
O NAVEGADOR
O navegador atua como uma cópia de um navegador real. A primeira página é uma lista de sites que foram descobertos
anteriormente pelo nosso jogador. Ele também poderá simplesmente escrever o link desses sites na barra de pesquisa 
principal. Escrever qualquer outro site não existente no nosso sistema resultará em um erro de 403 Forbidden.
Dentro do navegador, o principal site pelo qual o jogador passará boa parte de seu tempo é o NULL CHANNEL: O 
fórum oficial de NULL NETWORK.
NULL CHANNEL atua como um sistema de notícias, quests e tutoriais. O jogador poderá ver as threads do dia, ou 
acessar as threads arquivadas de dias anteriores. Essas threads envolverão sempre quatro coisas: Ou são threads 
"noise" (criadas para fingir movimentação real e que não tem nenhuma relevância, podendo ser alguma dúvida boba de 
jogador novo ou algum ranker roastando outro e chamando pro X1, ou até mesmo informações falsas de trolls), ou são 
"notícias" (threads sobre algum usuário que viu alguma coisa esquisita acontecendo, ou que viu algum PK matar o 
parceiro de outro jogador, qualquer coisa que implicará em algum evento futuro que o jogador precisará superar), ou 
são "quests" (jogadores solicitando ajuda para explorar um data center junto com o jogador, pedidos de pvp, mini￾torneios, entre outros), ou são "tutoriais" (quando o nosso jogador passar por algum sistema diferente pela primeira vez,
uma thread sobre esse sistema se abrirá, e nela algum veterano explicará com sua personalidade como é que o 
sistema funciona).
Ele é o principal "motor" que tentará engajar o nosso jogador, caso não tenha nenhuma ideia do que fazer em seu dia.
Visualmente, os sites são simples páginas com textos, imagens e posts separados, emulando corpos e containeres de 
um site comum.
O site Null Network apresenta uma página inicial com um header, um texto introdutivo e três botões, um abaixo do 
outro, abaixo do texto, que leva o usuário para outros lugares: "Updates", "Get Started", "NULL CHANNEL", "Player 
Rankings".
O fórum Null Channel sempre contém um header com uma navbar abaixo, que também leva pra esses mesmos 
lugares: Thread Lists, Updates e Player Rankings. Na lista de threads, o conteúdo é meramente botões que levam um 
usuário para uma determinada thread. Dentro de uma thread, os conteúdos são: O título da thread, o perfil do atual 
postador e o conteúdo do seu post, emulando um fórum de verdade. O perfil, na lateral do post, conterá o nome de 
usuário, ranking global, título (user/moderator), sua foto de perfil, e o server físico (a localização geral) do postador. Um 
abaixo do outro. Ao lado, o post que escreveu.
A página Updates é uma mera sequência de posts que indica o desenvolvimento do jogo fictício de Null Network. 
Acima, um Countdown gigantesco e em vermelho indicando: X DAYS REMAINING FOR UPDATE 1.0.
A página Get Started utiliza navegação lateral com Introduction e Get Started. Introduction apresenta um texto de 
TENYA sobre a origem de NULL NETWORK. Get Started ensina apenas o básico oficial: stats, APKs e EXEs, parceiro 
único, combate por Modules e Player Actions (SCAN, PURGE, PURIFY e TAME). A evolução volátil não é explicada 
oficialmente.
A página Player Rankings apresenta a leaderboard global com ícone, username, bandeira do servidor físico, título, 
parceiro APK e nível do parceiro. O número exato de posições exibidas permanece OPEN: rascunhos anteriores citam 
Top 25 e Top 100; nenhuma dessas contagens deve ser tratada como canônica até decisão explícita.
A ideia é que toda página que existirá no jogo, independente de ser parte da NULL NETWORK ou não, conterá um 
header, uma navbar simples e seu conteúdo abaixo, que geralmente se tratará de vbox e hbox organizados para emular
uma página real.

Social — visão de produto
O SOCIAL
O social exibe todos os personagens que o jogador conseguiu colocar em sua "friend list". Nesse APP, será possível 
"conversar" (clicar em um botão de "interagir" que exibe uma curta troca de mensagens) com jogadores encontrados 
anteriormente para aumentar sua afinidade com eles, convidá-los para uma party para jogar NULL NETWORK juntos 
ou, em caso de afinidade alta, convidá-los para sair e se divertir em uma data futura (hangout). Em algumas ocasiões, 
para triggerar quests específicas liberadas por afinidade alta, o jogador poderá receber mensagens de seus amigos, 
onde solicitarão ajuda ou convidarão para ir em algum local específico.
Visualmente, o social age como um APP de mensagens padrão de um celular: Uma lista de contatos conhecidos, que 
exibe se determinado NPC está online ou não e fica com um sinal de notificação caso haja alguma mensagem nova. 
Clicar em um nome específico faz com que abra a janelinha de chat, contendo todo o histórico de chat entre o jogador e
o NPC, estilo SMS. Acima, haverá o nome de usuário do NPC, seu nome real, se está online ou não, quanto de Affinity 
ele tem com o player e um indicador de personalidade e gostos (que só são desbloqueados quando o jogador atinge um
certo nível de affinity e usa bastante Conhecer).
NPCs terão "rotinas" fixas, havendo períodos do dia onde estarão offline e períodos do dia onde estarão online.
Nessa aba, haverão 3 botões no lugar de um campo "Digite sua mensagem..": Chat, Invite to Party, Challenge, e Plan 
Hangout.
Chat exibe uma escolha de interação aleatória com o NPC que gera Affinity baseado no tipo de coisa que ele gosta de 
conversar. Serão 4 opções: Fazer Smalltalk, Falar sobre Hobbies, Conversar sobre Null Network e Conhecer, sendo 
possível dar Chat com a pessoa uma vez por período, quando ela estiver online. Isso abre uma breve interação onde 
novas mensagens de texto são criadas, indicando uma breve conversa em chat entre o NPC e o Player que fica salva 
no histórico de chat.
Invite to Party faz com que o NPC decida se aceitará entrar para a party do player temporariamente ou não, que 
dependerá de sua personalidade e de quanta affinity ele tem com o player. Aceitando, ele se encontra e fica com o 
player até saírem da área atual, período onde geralmente ficará "offline", promptando uma breve interação IRL com o 
player indicando que ele terá que parar de jogar por enquanto.
Challenge desafia o NPC para um PVP honesto. O PVP é marcado em um local fixo definido pelo NPC. O 
deslocamento até outra região consome 1 período quando aplicável; um PVP iniciado voluntariamente possui custo 
pendente de 1 período, debitado apenas quando o combate é formalmente resolvido, conforme as regras globais de 
tempo. PVP não concede XP, mas pode conceder itens ou dinheiro. Em PVP convencional, dano letal causa 
INCAPACITATED e derrota, não Partner Loss. Run Away contra outro Operator é sempre garantido. Morte deliberada 
só se torna possível após 100% PURGE no parceiro-alvo, conforme as regras do Capítulo 7.
Plan Hangout planeja um "encontro" com o NPC. Para ele aceitar, precisa ter alta affinity. Isso cria um novo evento que 
se fica marcado para o dia seguinte, promptará uma cena e aumentará muito o Affinity entre o NPC e o Player.
NPCs são divididos em três tipos diferentes: Primários, Secundários e Fodder.
NPCs primários são os NPCs core do jogo, os "heróis e heroínas" típicos. Eles possuem interações únicas, cada nível 
de affinity prompta um evento novo e único que conta sobre sua backstory e hangouts possuem cenas mais elaboradas.
NPCs secundários também têm interações e personalidades únicas, apesar de não possuírem eventos novos a cada 
nível de affinity. Compartilham os mesmos eventos de hangouts que os NPCs Fodder.
NPCs Fodder são estilo os NPCs da série Tag Force de Yu-Gi-Oh!: São uma pool de personagens específicos que 
terão seus designs feitos pelo "criador de personagem" padrão do jogo que o próprio player utiliza para fazer seu 
personagem, e possuem personalidades padronizadas, todas com o mesmo diálogo. Mensagens, interações e eventos 
de hangout dependem inteiramente de qual personalidade padronizada compõe o personagem.
NPCs primários e secundários possuem APKs fixos. NPCs Fodder possuirão APKs aleatórios, pré-definidos no começo 
do jogo.
Profile, Encyclopedia e Calendar — visão de produto
O PERFIL
O perfil exibe as informações do nosso jogador. Seu nome e sobrenome, apelido, nome de usuário dentro do Fórum, e 
sua Tendência (Quantidade de pontos em VALOUR, LOGIC, SYNC e SELF). Também possui um botão de "mochila", 
que é um inventário que exibirá os itens que o jogador possui consigo.
Abaixo disso, há uma área interativa em que o jogador poderá interagir com o seu parceiro APK, quase como um "mini￾tamagotchi": Será possível conversar, fazer carinho ou dar itens virtuais.

Essa área interativa age de maneira idêntica, mas simplificada, a Digimon World Championship: É um cômodo 
isométrico onde um sprite do APK caminha e interage aleatoriamente. Abaixo dessa telinha, haverá as opções Interact, 
Show Affection e Give Item.
Quando uma das opções for selecionada, o parceiro também conversa com o jogador. Ele o faz por um pequeno balão 
de diálogo que fica localizado logo acima de seu sprite. Esse balão de diálogo está presente sempre que um APK 
deseja conversar ou fazer algum comentário, seja na aba Perfil ou durante um Combate.
Caso o jogador mantenha esse APP aberto durante interação com outros NPCS, seu parceiro APK também poderá 
fazer algum comentário sobre a opinião dele com esse NPC, o que pode dar dicas (como por exemplo, avisar que a 
pessoa é perigosa ou dizer que a pessoa parece legal e confiável).
Quando o APK cumpre os Core Requirements de uma possível evolução, o Profile pode exibir um indicador de 
potencial evolutivo. Esse indicador é informativo: ele NÃO inicia evolução. Evoluções do parceiro só podem ocorrer 
durante combate, quando um Evolution Catalyst válido abre uma janela de evolução.
A ENCICLOPÉDIA
A enciclopédia exibe uma lista extensa de todos os EXEs e APKs encontrados, com informações generalizadas (tipo 
uma Pokédex) dessas criaturas, sua tendência, suas possíveis personalidades, e suas "branches de evolução". As 
branches de evolução indicam para qual criatura determinada criatura pode evoluir, assim como seus requisitos de 
evolução, mas essas informações só são desbloqueadas após o jogador ativamente obter essa criatura ou informações 
sobre ela.
Visualmente, a Enciclopédia usa lista de APKs à esquerda e dados da criatura à direita: tendência/forma, flair text, 
raridade, locais conhecidos e árvore evolutiva. A árvore é revelada conforme o jogador registra formas por encontros e 
pelas Player Actions/resultado de combate aplicáveis (SCAN, PURGE, PURIFY, TAME ou derrota normal, conforme o 
dado a ser registrado). PVP não oferece captura/resolução de EXE. Os locais conhecidos também dependem do 
registro efetivo da criatura.
O CALENDÁRIO
O calendário exibe o mês atual, quantos dias faltam para o update, e quais eventos o jogador sabe que ocorrerão em 
determinado dia, como por exemplo datas de hangout com amigos.
Isso cobre todo o sistema que envolve a Mini-SO, interface para jogar NULL NETWORK.
---
Sistema de janelas e apps — especificação técnica
Sistema de Janelas (Desktop Window System)
O jogo simula um desktop funcional onde aplicativos são abertos em janelas independentes. Para evitar recriar interface
para cada aplicativo, todas as janelas devem herdar de um template base.
A janela base terá apenas dois elementos fixos:
• Top Bar, contendo o nome da janela
• Botão de fechar
O restante da janela será um container vazio que receberá o conteúdo do aplicativo.
O comportamento esperado é:
Clicar no ícone de um aplicativo abre sua janela
Se a janela já estiver aberta, clicar no ícone novamente fecha a janela
Clicar no botão de fechar da Top Bar fecha a janela
Apenas uma instância de cada aplicativo pode estar aberta ao mesmo tempo
A ideia é que qualquer aplicativo do jogo (browser, fórum, chat, inventário etc.) seja apenas uma cena colocada dentro 
do container da janela base.
Isso permite criar novos aplicativos apenas conectando uma nova cena ao sistema de janelas, sem precisar recriar 
lógica de UI.
A ideia é que cada aplicativo tenha um “tamanho” diferente, de acordo com a sua relevância. Antes de tudo, será 
essencial definir um bom tamanho de tela padrão para o jogo, de modo que seus gráficos possam atuar em tamanho 
1x, 2x e 3x já que é um jogo de Pixel Art:
O Navegador e o Mapa devem ocupar no mínimo metade da tela.

A Enciclopédia deve ter espaço o suficiente para atuar como um livro; uma pequena parte com a lista de monstros à 
esquerda e uma parte contendo os dados desse monstro (stats, tendência, raridade, localização conhecida, descrição, 
linha evolutiva)
O calendário deve ter um tamanho não muito grande, simulando uma agenda.
Tanto o Perfil quanto o Social devem ter o mesmo tamanho, simulando o tamanho de um smartphone.
LÓGICA DOS APLICATIVOS:
Browser, Sites, Forum, Social, Profile, Calendar, Encyclopedia e Dialogue — 
especificação técnica
NAVEGADOR -
Sistema de Sites (Internet Simulada)
O jogo possui um navegador interno que permite acessar sites fictícios.
Para isso será implementado um sistema de DNS simulado, onde uma URL digitada pelo jogador é comparada com um 
dicionário interno.
Se a URL existir, o navegador carrega a cena correspondente.
Se não existir, aparece uma página de erro 403.
Cada site é definido por um WebsitePage.tres, que carrega um template de página.
O template possui três áreas:
Header
Navbar
Conteúdo
O Header é uma imagem fixa.
A Navbar é composta por botões configuráveis que podem levar para outras páginas do site.
A área de conteúdo é composta por blocos modulares, que podem ser organizados em linhas ou colunas.
Cada bloco pode conter:
texto
imagem
links
outros containers
Isso permite montar páginas inteiras apenas organizando blocos no .tres.
Sistema de Fórum
O fórum é um tipo especial de site, focado em threads de discussão.
Ele possui dois níveis de navegação:
• lista de threads
• página da thread
A lista de threads é definida por um conjunto de ThreadButton.tres, que indicam quais threads existem no momento. 
Flags indicam quais threads são visíveis e quais estão inativas, surgindo uma acima da outra (mais recentes em cima, 
mais antigas abaixo) quando uma nova thread é descoberta.
Cada thread possui um ForumThread.tres, que define:
título da thread
board onde ela está
quantos posts existem
Os posts são definidos separadamente em ForumPost.tres.
Cada post contém duas áreas:
Perfil do usuário
Conteúdo da mensagem
O perfil inclui:
avatar

nome de usuário
título
localização
O conteúdo do post pode ser:
texto
imagem
Dessa forma, threads podem ser montadas apenas conectando uma sequência de posts.
SOCIAL -
O social é um APP que emula um aplicativo de mensagens estilo SNS, Telegram ou Whatsapp. Ele possui duas telas 
diferentes: Uma tela contendo todos os contatos do jogador, e uma tela específica para quando o jogador abre um 
contato conhecido, contendo todo o chat e as informações do personagem.
A tela dos contatos conterá: O nome de usuário do jogador, seu avatar à esquerda. Abaixo, a lista de contatos 
conhecidos, que é adicionada através de flags, seguindo a mesma lógica de Threads: Aparecem quando são ativadas. 
A ordem dos contatos é de acordo com a interação mais recente no chat, o que significa que interagir com um NPC que 
está lá embaixo na lista o traz para o topo e o que estava no topo desce uma casa.
Nessa tela, cada contato deverá exibir seu status (Se está online ou offline), seu avatar à esquerda, seu nome de 
usuário e quantos leveis de afinidade o jogador possui. Abaixo, mas ainda na mesma “linha”, a última mensagem que 
foi enviada no chat.
Na tela de chat, no topo deverá conter o nome do personagem selecionado, seu avatar, se está online ou offline e o 
nível de afinidade que o jogador possui com o personagem. Abaixo disso, um histórico de chat:
Mensagens enviadas pelo NPC ficam à esquerda, e mensagens enviadas pelo jogador ficam à direita.
As mensagens authored enviadas pelo jogador no Social utilizam o Writing Profile definido no registro do NULL 
CHANNEL. O conteúdo semântico da resposta permanece o mesmo; apenas sua apresentação textual é transformada 
pelos Writing Quirks.
A data de cada uma das mensagens aparece logo abaixo da mensagem em si.
No final, no lugar do típico “escreva sua mensagem”, aparecem as opções de interação com o NPC atual.
Sistema de Chat
O jogo possui um aplicativo de chat interno que permite conversar diretamente com NPCs importantes da história. Esse 
sistema funciona como uma mistura de mensageiro instantâneo e Visual Novel, permitindo interações mais íntimas com 
personagens fora de encontros presenciais.
Cada NPC que pode conversar pelo chat possui um ChatProfile dentro do seu NPCData.tres.
Esse perfil define:
nome de usuário no chat
avatar utilizado no aplicativo
disponibilidade de conversa dependendo do horário do dia
conjuntos de respostas possíveis
Quando o jogador abre uma conversa com um NPC, o chat carrega um ChatConversation.tres, que define a sequência 
de mensagens possíveis.
Uma conversa é composta por mensagens enviadas pelo NPC e pelo jogador, exibidas em formato de bolhas de 
mensagem.
Cada mensagem possui:
remetente
texto
delay opcional antes de aparecer
reação opcional do personagem
Assim como no sistema de diálogos, algumas mensagens do chat podem apresentar opções de resposta para o 
jogador.
Cada resposta possível pode:
levar para outra parte da conversa

alterar a afinidade com o NPC
alterar Tendências do protagonista
ativar Flags da história
Algumas conversas de chat também podem depender de condições específicas, como:
horário do dia
flags de história
nível de afinidade com o NPC
Isso permite que NPCs respondam de forma diferente dependendo do progresso do jogador no jogo.
Além disso, conversas são persistentes, ou seja, o histórico de mensagens permanece salvo mesmo depois de fechar o
aplicativo.
Esse sistema permite construir relações com NPCs ao longo do tempo e também pode servir para entregar pistas 
narrativas, links de sites ou avisos importantes.
PERFIL -
O perfil é o app onde o jogador poderá ver informações sobre seu personagem: Seu avatar frontal no overworld na 
esquerda, Nome completo, nickname, nome de usuário, ranking atual em NULL NETWORK. E também as suas 
tendências, representadas pelo nome em sua respectiva cor, uma barrinha que indica qual é a pontuação “máxima” e, 
ao lado, a quantidade de pontos na tendência em específico. As tendências ficam uma abaixo da outra.
Ao lado direito, um botão de “Mochila” que indica quais itens físicos (Key Items) o jogador possui consigo. O botão de 
mochila, quando aberto, abre uma segunda janela logo ao lado do app de perfil que mostra a quantidade de itens que o 
jogador possui. passar o mouse em cima do item exibe suas informações.
Abaixo desse bloco de perfil do personagem, existe o perfil do atual APK parceiro do personagem: Um pequeno 
quadrado que exibe um cenário isométrico de uma casa virtual e o sprite do APK andando por esse cenário 
aleatoriamente. As “dialog box” do parceiro aparecem nessa tela, logo acima de seu sprite andante.
Abaixo dessa telinha, constam as informações do APK: Nome da espécie, apelido dado pelo jogador, sua forma atual, 
seu tipo de personalidade, como ele chama o jogador, seus stats, seu nível, quanto de XP falta para subir de nível e seu
Combat Loadout atual. O Profile exibe Module Capacity como slots usados/slots máximos e é o local principal para 
montar o Combat Loadout fora de combate. A Module Collection completa permanece separada do loadout; durante 
combate, Change Modules só reorganiza os 4 Cycle Slots usando Modules que já estavam preparados no Combat 
Loadout.
Abaixo da ficha do APK, quando os Core Requirements de alguma EvolutionBranch estiverem válidos, o Profile pode 
exibir um aviso de potencial evolutivo. O aviso não executa UPGRADE. A evolução é acionada exclusivamente durante 
combate por uma janela válida e por pelo menos um Evolution Catalyst.
No lado direito, dois botões: o botão de “Inventário” do APK (com itens consumíveis e outros recursos válidos) e o botão
de “Modules” do APK. O painel de Modules possui abas para Active Modules e Passive Modules. A aba de Active 
Modules mostra a Module Collection completa, permite Favorites/filtros para organização e permite preparar o Combat 
Loadout respeitando Module Capacity. Favorites não alteram Capacity e não tornam um Module disponível em combate 
se ele não estiver no loadout. Passive Modules seguem seu sistema de slots próprio e não consomem Active Module 
Capacity.
Sistema de Parceiro (Partner APK)
O protagonista possui um APK parceiro que o acompanha ao longo de toda a história. Esse parceiro funciona como a 
principal criatura controlada pelo jogador em combate e também como um personagem narrativo.
O parceiro é definido por um PartnerData.tres, que referencia um APKData.tres correspondente à sua forma atual.
Esse sistema controla:
status atuais do parceiro
módulos equipados
experiência acumulada
estágio evolutivo
O parceiro pode evoluir ao longo do jogo seguindo o sistema de tendências do protagonista.
Ao atingir certos momentos de evolução, o jogo verifica os valores atuais de:
VALOUR
LOGIC
SYNC

SELF
Dependendo de quais valores são maiores ou menores, diferentes EvolutionBranch.tres podem ser ativados, resultando
em formas evolutivas distintas.
Isso significa que o parceiro evolui não apenas pelo progresso do jogo, mas também pelas decisões tomadas pelo 
jogador durante diálogos e eventos.
O parceiro também possui afinidade com o protagonista, que pode influenciar:
habilidades desbloqueadas
diálogos exclusivos
eventos narrativos
Além disso, o parceiro pode possuir pequenas reações narrativas fora do combate, aparecendo em diálogos ou 
comentando eventos da história.
Essas reações podem ser definidas por eventos simples associados a Flags específicas.
O objetivo desse sistema é fazer com que o parceiro seja ao mesmo tempo:
uma unidade de combate
um reflexo das decisões do jogador
um personagem da narrativa
CALENDÁRIO
O calendário é um APP cuja aparência simula a de um calendário real, com os dias do mês, o dia atual em que 
estamos, e em quais dias certos eventos já pré-planejados ou ditos acontecerão. Esse APP atuará meramente como 
um espelho, exibindo em cima o dia atual, o período atual, a data, quantos dias se passaram desde o início do jogo, e 
quantos dias faltam para o update final.
ENCICLOPÉDIA
A enciclopédia exibe uma lista extensa de todos os EXEs e APKs encontrados, com informações generalizadas (tipo 
uma Pokédex) dessas criaturas, sua tendência, suas possíveis personalidades, e suas "branches de evolução". As 
branches de evolução indicam para qual criatura determinada criatura pode evoluir, assim como seus requisitos de 
evolução, mas essas informações só são desbloqueadas após o jogador ativamente obter essa criatura ou informações 
sobre ela.
Visualmente, a Enciclopédia utiliza uma lista de APKs à esquerda e os dados da criatura à direita: forma/tendência, 
descrição, raridade, localização conhecida e chart evolutivo. Informações são desbloqueadas por registro real de 
encontros e resultados/Player Actions pertinentes. A árvore evolutiva não é completada apenas por PVP, pois PVP não 
oferece a resolução de EXE usada para registrar/capturar entidades sem parceiro.
Sistema de Diálogos Modulares
Os diálogos do jogo são totalmente definidos por dados e podem ser encadeados infinitamente.
Cada interação carrega um DialogueData.tres, que define a sequência de falas, os personagens presentes e possíveis 
escolhas.
Um diálogo é composto por:
• sequência de caixas de texto
• imagens dos personagens exibidas acima da caixa
• escolhas do jogador que alteram o rumo da conversa
Para representar personagens na tela existem seis slots fixos:
Left1
Left2
Left3
Right1
Right2
Right3
Cada fala do diálogo define:
quais personagens estão na tela e em qual slot
qual personagem está falando

qual sprite/reação eles utilizam
qual texto aparece na caixa de diálogo
As escolhas do jogador podem ter até 6 opções. Cada escolha pode:
levar para outro DialogueData
alterar uma Tendência do protagonista
ativar ou desativar Flags da história
As Tendências possíveis são:
VALOUR
LOGIC
SYNC
SELF
Cada escolha pode modificar essas tendências por um valor positivo ou negativo.
Dessa forma, um diálogo pode influenciar tanto a narrativa quanto o desenvolvimento do personagem.
NULL CHANNEL — especificação final
ATUALIZAÇÃO IMPORTANTE === FÓRUM ===
SISTEMA FINAL DO FÓRUM NULL CHANNEL
O NULL CHANNEL será implementado como um site especial dentro do Navegador. Ele utiliza a mesma lógica modular
dos outros sites, mas possui regras próprias para exibição, filtragem, busca, leitura e organização de threads.
O objetivo do sistema é permitir que o fórum funcione como uma comunidade viva dentro do jogo, e não apenas como 
uma lista linear de textos. O jogador deverá ser capaz de usar o fórum para encontrar rumores, pedidos de ajuda, guias,
quests, discussões, provocações entre jogadores, informações falsas e pistas sobre eventos futuros.
Para isso, o fórum será dividido em abas principais, cada uma representando um tipo de leitura:
Trending
Social
Rumours
Guides
Help
Essas abas não substituem as tags das threads. As abas representam a função principal da thread dentro da 
comunidade. As tags representam os assuntos internos daquela thread.
Exemplo:
Uma thread pode pertencer à aba Rumours e possuir as tags:
aquarium
exe
stability
deleted_screenshot
Outra thread pode pertencer à aba Guides e possuir as tags:
scan
modules
combat
beginner
Desse modo, o jogador pode navegar pelo tipo de thread usando as abas, ou procurar por assunto usando a barra de 
pesquisa.
ESTRUTURA VISUAL DA PÁGINA DO FÓRUM
A página principal do NULL CHANNEL será composta por:
NULL CHANNEL
├── Header
├── Navbar Geral
├── ForumTabBar
├── SearchBar

├── ThreadListHeader
└── ThreadList
O Header exibe o nome NULL CHANNEL e informações visuais do site.
A Navbar Geral exibe botões para as páginas principais do site:
Thread Lists
Updates
Player Rankings
A ForumTabBar exibe as abas internas do fórum:
Trending
Social
Rumours
Guides
Help
A SearchBar permite pesquisar threads pelo título, tags, autor ou conteúdo textual dos posts.
O ThreadListHeader exibe os nomes das colunas da lista:
Thread
Replies
Last Reply
Author
A ThreadList exibe uma sequência de linhas clicáveis, cada uma representando uma thread.
Cada linha de thread deverá exibir:
ícone do tipo da thread
tag visual principal entre colchetes
título da thread
preview curto da thread
indicador NEW, caso o jogador ainda não tenha lido
quantidade de replies
último usuário que respondeu
tempo desde a última resposta
autor original
rank/título do autor, quando aplicável
Exemplo visual:
[RUMOUR] Aquarium district acting weird lately NEW
Something’s off with the water reflections. NPCs ignoring players?
Replies: 87
Last Reply: 2 min ago by HexDream #7
Author: 403kid ???
A linha inteira deve ser clicável. Clicar na linha abre a página específica da thread.
ABAS DO FÓRUM
Trending
Trending não é uma categoria fixa de thread. Trending é uma visão agregada do fórum.
A aba Trending exibe as threads mais relevantes para o momento atual do jogo. Ela pode puxar threads de Social, 
Rumours, Guides ou Help, desde que essas threads estejam visíveis e sejam consideradas relevantes pelo sistema.
A relevância de uma thread pode ser definida por:
popularity_score
is_pinned
release_day
release_period
release_action_block
flags ativas
proximidade com eventos atuais
condições específicas da história
Essa aba serve para o jogador que abriu o fórum sem saber exatamente o que fazer. Ela mostra o que a comunidade 
está discutindo naquele momento.

Social
A aba Social exibe threads de interação entre jogadores.
Entram nessa aba:
pedidos de party
pedidos de PVP
chamadas para mini-eventos
provocações entre rankers
jogadores procurando grupo para Data Centers
pedidos de troca
convites para exploração
threads ligadas a NPCs conhecidos
Essa aba reforça a fantasia de que NULL NETWORK é um jogo social jogado por pessoas reais dentro da narrativa.
Exemplos:
[PARTY] Need 1 more for Shibuya datacenter
[PVP] Looking for fair match tonight
[TRADE] Anyone selling Purify Verbs?
[DISCUSSION] Best place to grind after Day 4?
Rumours
A aba Rumours exibe threads de investigação, boatos, relatos estranhos e especulações.
Entram nessa aba:
relatos de locais suspeitos
supostos bosses escondidos
Data Centers raros
screenshots apagadas
EXEs anômalos
teorias sobre TENYA
mudanças não documentadas em updates
relatos de glitches no mapa ou no overworld
pistas vagas sobre eventos futuros
Essa aba é uma das principais ferramentas de investigação narrativa do jogador.
Muitas informações importantes devem aparecer primeiro como rumores incompletos. O jogador pode ler uma thread e 
não entender sua importância no momento. Dias depois, ao encontrar um boss ou evento relacionado, poderá voltar ao 
fórum e perceber que aquela thread já continha pistas úteis.
Exemplos:
[RUMOUR] Aquarium district acting weird lately
[THEORY] TENYA is still alive
[BUG?] Mods deleted my screenshots again
[RUMOUR] Something is spawning under the station
Guides
A aba Guides exibe threads cujo objetivo é ensinar sistemas do jogo em profundidade.
Essas threads não substituem tutoriais obrigatórios de interface. O tutorial direto do jogo deve ensinar o básico: como 
abrir apps, como usar o Navigator, como iniciar combate, como trocar módulos, como executar ciclos.
Os Guides do NULL CHANNEL explicam camadas mais profundas:
como SCAN funciona de verdade
como administrar Stability
como preparar uma party para Data Centers
como avaliar riscos de PURGE, PURIFY e TAME
como interpretar padrões de bosses
como identificar EXEs raros
como otimizar Modules
como entender fórmulas escondidas
Guias podem ser escritos por veteranos, rankers, trolls ou usuários suspeitos. Nem todo guia precisa estar 
completamente correto. Alguns podem conter erros, opiniões enviesadas ou informações desatualizadas.
Exemplos:

[GUIDE] How STABILITY actually works
[GUIDE] SCAN is not useless, stop saying that
[GUIDE] Beginner mistakes that get your APK killed
[GUIDE] PURGE vs PURIFY: actual numbers
Help
A aba Help exibe threads de jogadores pedindo ajuda sobre situações específicas.
Entram nessa aba:
dúvidas de novatos
perguntas sobre mecânicas
pedidos de estratégia contra inimigos
relatos de bugs
problemas com evolução
dúvidas sobre Data Centers
perguntas sobre SCAN, Stability, módulos ou bosses
Essa aba é importante porque permite que informações úteis apareçam organicamente em forma de pergunta e 
resposta, sem parecer uma wiki oficial.
Exemplos:
[HELP] Why does SCAN stop at 75%?
[HELP] My Stability keeps dropping after the update
[HELP] Partner won’t evolve even with VALOUR high
[HELP] Lost my APK near the aquarium
BARRA DE PESQUISA
A SearchBar deve permitir que o jogador busque threads usando texto livre.
A pesquisa deve considerar:
thread_title
thread_category
thread_display_tag
thread_tags
thread_author
author_rank_label
thread_preview
texto dos posts
nomes de locais
nomes de EXEs/APKs
nomes de mecânicas
A busca não deve entregar respostas prontas. Ela deve retornar threads relacionadas ao termo buscado.
Exemplo:
Pesquisar “SCAN” pode retornar:
[GUIDE] SCAN is not useless, stop saying that
[HELP] Why does SCAN stop at 75%?
[BUG?] Boss scan reset after relogging
[DISCUSSION] Scan data carries between encounters?
Pesquisar “Aquarium” pode retornar:
[RUMOUR] Aquarium district acting weird lately
[HELP] Lost my partner near the aquarium
[BUG?] Mods deleted my screenshots again
[PARTY] Need backup for abandoned aquarium run
Pesquisar “Stability” pode retornar:
[GUIDE] How STABILITY actually works
[HELP] Stability keeps reaching zero
[DISCUSSION] New update changed Stability recovery?
[RUMOUR] Aquarium EXE drains Stability every cycle

O jogador deve ser capaz de pesquisar tanto dentro da aba atual quanto em todas as abas. A opção padrão será 
pesquisar na aba atual. Caso o jogador esteja em Trending, a busca deverá considerar todas as threads visíveis no 
fórum.
THREAD LIST
A ThreadList é a lista visual de threads exibida abaixo da barra de pesquisa.
Cada item da lista deve ser uma cena própria reutilizável, para evitar criar botões simples demais diretamente por 
código.
Estrutura recomendada:
ForumThreadRow (Button ou PanelContainer clicável)
├── TypeIcon
├── MainInfo
│ ├── TitleLine
│ │ ├── DisplayTagLabel
│ │ ├── ThreadTitleLabel
│ │ └── NewBadge
│ └── PreviewLabel
├── RepliesLabel
├── LastReplyBox
│ ├── LastReplyTimeLabel
│ └── LastReplyAuthorLabel
└── AuthorBox
├── AuthorNameLabel
└── AuthorRankLabel
O objetivo dessa cena é permitir que a lista do fórum tenha aparência de fórum real, com colunas de informação, em 
vez de apenas uma sequência de botões simples.
A ThreadList deve ordenar threads de forma diferente dependendo da aba atual.
Trending:
pinned primeiro
maior popularity_score
threads relevantes para flags atuais
threads mais recentes em caso de empate
Social/Rumours/Guides/Help:
pinned primeiro
threads não lidas acima de threads lidas, se for conveniente para UX
threads mais recentes acima das antigas
threads arquivadas separadas ou exibidas ao fim
Quando uma thread visível ainda não tiver sido lida pelo jogador, deverá exibir NEW.
Quando o jogador abrir a thread, o sistema marca aquela thread como lida e remove o NEW.
THREADSITE
Ao clicar em uma thread, o jogador entra na página específica daquela thread.
A ThreadSite deve manter a estrutura de posts já prevista para o fórum:
ThreadSite
├── ThreadHeader
│ ├── ThreadTitle
│ ├── ThreadCategory
│ ├── ThreadTags
│ └── ThreadMetadata
└── PostList
O ThreadHeader exibe:
tag visual principal
título da thread
categoria
tags secundárias
autor original

quantidade de replies
estado da thread: pinned, locked, archived
Cada post continua sendo composto por:
Perfil do usuário
Conteúdo da mensagem
O perfil do usuário contém:
avatar
username
rank global, se existir
título no fórum
localização geral / server físico
O conteúdo do post pode conter:
texto
imagem
links internos
links para outras threads
links para páginas do site
efeitos que ativam flags, quando necessário
O sistema de links internos é importante para simular navegação orgânica em um fórum real. Um usuário pode 
responder uma dúvida linkando um guia antigo. Um rumor pode citar uma thread apagada ou arquivada. Um guia pode 
direcionar o jogador para uma discussão de Help com exemplos práticos.
RESOURCES NECESSÁRIOS
ForumThread.tres
ForumThread representa a thread em si.
Campos necessários:
thread_id: String
thread_title: String
thread_category: ThreadCategory
thread_display_tag: String
thread_tags: Array[String]
thread_preview: String
thread_author: String
author_rank_label: String
author_title: String
reply_count: int
last_reply_author: String
last_reply_author_rank_label: String
last_reply_time_label: String
popularity_score: int
is_pinned: bool
is_locked: bool
is_archived: bool
related_thread_ids: Array[String]
posts: Array[ForumPost]
thread_id é o identificador único usado para abrir a thread, marcar como lida e criar links internos.
thread_title é o título completo exibido na ThreadList e na ThreadSite.
thread_category define em qual aba a thread aparece. Trending não deve ser salvo como categoria, pois Trending é 
calculado dinamicamente.
thread_display_tag é a tag visual principal exibida entre colchetes no começo do título. Exemplo: RUMOUR, GUIDE, 
HELP, PARTY, PVP, BUG?, THEORY, DISCUSSION.
thread_tags são tags secundárias usadas para busca e agrupamento temático.
thread_preview é uma frase curta exibida abaixo do título na ThreadList.
thread_author é o nome do usuário que criou a thread.
author_rank_label é o rank visual do autor, como #7, #142 ou ???.

author_title é o título do autor dentro do fórum, como Newbie, Moderator, Ranker, Dataminer ou Admin.
reply_count é o número exibido na coluna Replies. Ele pode ser definido manualmente pelo Resource para simular 
atividade, sem depender necessariamente da quantidade real de ForumPost.
last_reply_author é o nome do usuário que respondeu por último.
last_reply_author_rank_label é o rank visual do último usuário que respondeu.
last_reply_time_label é um texto visual, como 2 min ago, 1 hr ago, yesterday.
popularity_score é usado para ordenar a aba Trending.
is_pinned indica se a thread fica fixada acima das outras.
is_locked indica se a thread pode ser lida, mas está fechada ou morta.
is_archived indica se a thread não está mais ativa, mas ainda pode ser encontrada.
related_thread_ids permite criar uma lista opcional de threads relacionadas.
posts contém os ForumPost da thread.
ThreadButtonData.tres
ThreadButtonData continua sendo o Resource responsável pelo ciclo de vida da thread dentro do jogo.
Campos já previstos ou necessários:
thread_ref: ForumThread
conditions: Array[ConditionData]
release_day: int
release_period: ThreadPeriod
release_action_block: int
archive_after_actions: int
ThreadButtonData não deve guardar metadados visuais da thread. Ele deve apenas controlar quando a thread existe, 
quando fica visível e quando é arquivada.
A separação correta é:
ForumThread
→ O que a thread é.
ThreadButtonData
→ Quando e sob quais condições essa thread aparece.
Isso evita misturar conteúdo com progressão.
ForumPost.tres
ForumPost representa uma postagem individual dentro da ThreadSite.
Campos necessários:
avatar: Texture2D
username: String
user_title: String
user_rank_label: String
location: String
post_time_label: String
text_content: String
image_content: Texture2D
username é o nome do usuário que fez o post.
user_title é o título ou cargo no fórum.
user_rank_label é o rank global do usuário, quando aplicável.
location representa o server físico ou localização geral.
post_time_label exibe quando aquele post foi feito, como 3 days ago, today, 12 min ago.
text_content é o texto do post, com suporte a BBCode.
image_content permite anexar imagem, screenshot, foto distorcida ou evidência visual.
ForumSearchIndex.gd
O fórum deverá possuir uma camada de busca separada da UI.
Essa camada pode ser um script utilitário ou um manager interno do ForumApp. Sua função é receber a lista de 
ThreadButtonData visíveis e retornar uma lista filtrada e ordenada de ForumThread.

Funções necessárias:
get_visible_thread_buttons(thread_buttons: Array[ThreadButtonData]) -> Array[ThreadButtonData]
Retorna apenas ThreadButtonData cuja thread_ref existe e cujas condições estão cumpridas.
get_threads_for_category(thread_buttons: Array[ThreadButtonData], category: ThreadCategory) -> Array[ForumThread]
Retorna apenas threads visíveis de uma categoria específica.
get_trending_threads(thread_buttons: Array[ThreadButtonData]) -> Array[ForumThread]
Retorna threads visíveis ordenadas por relevância.
search_threads(thread_buttons: Array[ThreadButtonData], query: String, category_filter: int = -1) -> Array[ForumThread]
Retorna threads visíveis que correspondem ao termo buscado. Se category_filter for -1, busca em todas as categorias. 
Se houver categoria definida, busca apenas dentro daquela categoria.
thread_matches_query(thread: ForumThread, query: String) -> bool
Verifica se o termo aparece no título, tags, autor, preview ou posts da thread.
sort_threads_for_tab(threads: Array[ForumThread], active_tab: ForumTab) -> Array[ForumThread]
Ordena as threads conforme a aba ativa.
A UI do fórum não deve conter a lógica de busca e ordenação diretamente. A UI apenas solicita dados filtrados para a 
camada de busca e renderiza o resultado.
ForumApp.gd
ForumApp é responsável pela interface do fórum.
Ele deve controlar:
aba ativa
texto atual da busca
thread aberta
scroll atual
renderização da lista
renderização da thread
estado salvo no navegador
Estados principais:
THREAD_LIST
THREAD_READER
Variáveis principais:
current_tab
current_search_query
current_thread_id
current_mode
Fluxo da ThreadList:
ForumApp recebe uma lista de ThreadButtonData.
O jogador seleciona uma aba.
ForumApp solicita ao ForumSearchIndex a lista de threads visíveis daquela aba.
Se houver texto na SearchBar, ForumApp solicita a busca filtrada.
ForumApp instancia uma ForumThreadRow para cada resultado.
Clicar em uma ForumThreadRow abre a ThreadSite daquela thread.
Abrir uma thread marca seu thread_id como lido no GameState.
Fluxo da ThreadSite:
ForumApp recebe o ForumThread selecionado.
Atualiza current_mode para THREAD_READER.
Salva current_thread_id.
Limpa a PostList.
Instancia um ForumPostUI para cada ForumPost.
Exibe ThreadHeader com título, categoria, tags e metadados.
Esconde ThreadList.

Mostra ThreadReader.
Ao clicar no botão Back do navegador, se ForumApp estiver em THREAD_READER, deve voltar para THREAD_LIST 
em vez de sair imediatamente do site.
Ao trocar de aba do navegador ou fechar/reabrir o browser, ForumApp deve salvar e restaurar:
current_mode
current_tab
current_search_query
current_thread_id
scroll_vertical
Isso garante que o jogador possa abrir o fórum durante um combate, pesquisar uma thread, trocar de app, voltar depois 
e continuar exatamente onde estava.
GameState
GameState deverá manter o registro de threads lidas.
Estrutura:
read_threads: Dictionary
Funções:
mark_thread_as_read(thread_id: String)
has_read_thread(thread_id: String) -> bool
Quando uma thread aparece pela primeira vez e ainda não foi lida, a ThreadList exibe NEW.
Quando o jogador abre a thread, o GameState registra aquela thread como lida.
Esse estado deve ser salvo no save file futuramente.
THREADS E PROGRESSÃO NARRATIVA
As threads devem ser liberadas por tempo, condições e flags, mas o sistema deve evitar parecer artificial.
O ideal não é criar um guia perfeito no exato momento em que o jogador encontra um boss. O ideal é que informações 
sobre aquele boss já tenham aparecido antes como rumores, relatos estranhos, pedidos de ajuda ou screenshots 
suspeitas.
Exemplo de progressão:
Dia 2:
[RUMOUR] Aquarium district acting weird lately
Dia 3:
[BUG?] Mods deleted my screenshots again
Dia 4:
[HELP] Lost my partner near the aquarium
Dia 5:
[GUIDE] How STABILITY actually works
Dia 6:
Jogador encontra o boss do Aquário.
Depois do encontro, o jogador pode pesquisar Aquarium, Stability ou outro termo relacionado. As threads antigas 
passam a fazer sentido porque agora o jogador possui contexto.
Essa estrutura cria a sensação de que a comunidade já estava investigando os eventos antes do jogador chegar, e não 
que o jogo gerou uma resposta sob demanda.
RELAÇÃO COM A ENCICLOPÉDIA
A Enciclopédia e o NULL CHANNEL possuem funções diferentes.
A Enciclopédia armazena informações confirmadas pelo jogador:
EXEs encontrados
APKs registrados
módulos conhecidos
tutoriais oficiais já exibidos
NPCs conhecidos
dados confirmados de criaturas
O NULL CHANNEL armazena conhecimento comunitário:

rumores
guias avançados
pedidos de ajuda
opiniões de jogadores
informações falsas
relatos de bugs
teorias
pistas narrativas
Durante um combate, se o jogador quiser consultar dados confirmados sobre um inimigo já conhecido, deve abrir a 
Enciclopédia.
Se quiser entender melhor uma mecânica, procurar uma estratégia, investigar uma anomalia ou descobrir o que a 
comunidade sabe sobre determinado evento, deve abrir o NULL CHANNEL.
A separação final é:
Enciclopédia
→ Informação confirmada.
NULL CHANNEL
→ Conhecimento comunitário.
O jogador progride em combate fortalecendo seu APK, mas progride intelectualmente aprendendo a ler o fórum, filtrar 
trolls, reconhecer veteranos confiáveis, cruzar relatos e interpretar rumores.

WRITING QUIRKS — IDENTIDADE TEXTUAL DO OPERATOR
Visão geral
O protagonista de NULL NETWORK utiliza narração em segunda pessoa nas cenas presenciais e não possui uma voz 
falada escrita de forma literal. Em diálogos presenciais, o jogador escolhe a intenção de sua ação e a narração 
descreve o que ele fez ou comunicou, sem transformar o protagonista em um personagem com fala autoral fixa.
A comunicação digital funciona de forma diferente. Dentro do NULL CHANNEL e do Social, a interface precisa exibir 
uma mensagem textual concreta enviada pela conta do jogador. Para preservar a projeção do protagonista sem torná-lo
um lurker silencioso, o jogo utiliza Writing Quirks: regras de apresentação que transformam uma única mensagem-base 
authored em diferentes estilos de digitação.
A regra central é:
O jogador escolhe O QUE deseja comunicar. Os Writing Quirks determinam apenas COMO aquela mesma mensagem 
aparece digitada.
SEPARAÇÃO ENTRE INTENÇÃO E APRESENTAÇÃO
As escolhas digitais do protagonista são apresentadas de forma abstrata, descrevendo intenção, posicionamento ou 
ação comunicativa, e não uma frase literal que o jogador é obrigado a assumir como sua voz.
Exemplo de escolha:
<Diga que não foi nada e que ele pode chamar por sua ajuda quando precisar.>
Depois da escolha, o jogo exibe a mensagem completa dentro da interface digital. Essa mensagem possui um único 
conteúdo semântico authored e é transformada de acordo com os Writing Quirks selecionados no registro.
O significado da mensagem, a informação compartilhada, a decisão tomada e suas consequências permanecem 
idênticos em todos os estilos.
REGRA DE ESCRITA ÚNICA
Cada resposta do jogador possui somente UMA versão semântica base. O sistema não exige que o roteiro possua uma 
versão Normal, uma versão Casual, uma versão Cute e uma versão Formal escritas separadamente.
Writing Quirks não reescrevem vocabulário, não substituem palavras por sinônimos, não adicionam internet slang, não 
tornam a fala mais intelectual e não mudam o conteúdo da mensagem.
Exemplos de transformações proibidas:
DM me → Private Message me
difficult → challenging
about → abt
I agree → yeah fr
Essas alterações mudariam o registro lexical e criariam vozes diferentes. Não pertencem ao sistema.
Transformações permitidas são superficiais e ortográficas: capitalização, presença ou ausência de pontuação, 
intensidade gráfica da pontuação, remoção de apóstrofos em contrações já existentes, espaçamento, quebras de linha 
e elementos expressivos autorizados como kaomojis.
WRITING STYLE
Durante o registro no NULL CHANNEL, o jogador responde a uma pergunta diegética que demonstra diretamente o 
efeito do estilo:
HOW DO YOU EXPRESS YOURSELF?
"Uh, like a normal person, I guess"
"all cutely!"
"a bit lazy tbh and using punctuation marks and botherin yourself with pressing capslock is honestly kind of cringe"
"Naturally, by being formal. Expressing yourself by using proper punctuation and capitalization is a good way to practice 
your writing and intellect."
As opções funcionam ao mesmo tempo como escolha e preview. A própria forma da resposta demonstra como as 
mensagens futuras serão formatadas.
Os quatro Writing Styles canônicos são:
NORMAL — preserva a capitalização e a pontuação da mensagem-base. É a apresentação padrão.

CUTE — mantém as mesmas palavras, mas utiliza capitalização mais suave/irregular e pontuação mais expressiva, 
especialmente exclamações e duplicações controladas quando o tom permitir.
LAZY — mantém as mesmas palavras, mas tende a usar lowercase, remover apóstrofos de contrações e omitir 
vírgulas, pontos finais e outras marcas não essenciais.
FORMAL — mantém exatamente o mesmo vocabulário da mensagem-base, mas utiliza capitalização, pontuação e 
separação de frases de forma consistente e cuidadosa. FORMAL representa um digitador cuidadoso; não reescreve a 
frase com vocabulário mais culto.
KAOMOJI PREFERENCE
O uso de kaomojis é um Quirk independente do Writing Style. Durante o mesmo registro, o jogador responde:
DO YOU LIKE USING KAOMOJIS?
"(´⊙ω⊙`)！Of course! All the time! ヽ(o^▽^o)ﾉ"
"Just a little bit when exaggeration is needed ┐(￣ヘ￣)┌"
"No."
A preferência possui três estados:
FREQUENT — kaomojis podem aparecer com alta frequência quando compatíveis com o tom da mensagem.
OCCASIONAL — kaomojis aparecem somente em mensagens apropriadas, como ênfase ou reação expressiva.
NEVER — mensagens do protagonista não recebem kaomojis.
Kaomojis nunca alteram o significado do texto e não podem aparecer quando contradizem o tom da mensagem. 
Mensagens graves, mortes, pedidos de desculpa sérios, perigo imediato e outros contextos sensíveis podem bloquear 
automaticamente elementos expressivos incompatíveis, mesmo quando a preferência do jogador é FREQUENT.
EXEMPLO DE UMA ÚNICA MENSAGEM
Intenção escolhida:
<Diga que não foi nada e que ele pode chamar por sua ajuda quando precisar.>
Mensagem-base authored:
Don't worry about it! It was a difficult fight, but I'm glad your partner is alright in the end.
DM me if anything pops up.
NORMAL:
Don't worry about it! It was a difficult fight, but I'm glad your partner is alright in the end.
DM me if anything pops up.
NORMAL + OCCASIONAL KAOMOJI:
Don't worry about it! It was a difficult fight, but I'm glad your partner is alright in the end.
DM me if anything pops up (＾▽＾)
LAZY:
dont worry about it it was a difficult fight but im glad your partner is alright in the end
dm me if anything pops up
CUTE:
dont worry about it!! it was a difficult fight, but im glad your partner is alright in the end!!
dm me if anything pops up!
FORMAL:
Don't worry about it. It was a difficult fight, but I'm glad your partner is alright in the end.
DM me if anything pops up.
Todas as versões comunicam a mesma informação e a mesma intenção. Nenhuma delas possui uma consequência 
narrativa diferente.
RELAÇÃO COM A NARRAÇÃO EM SEGUNDA PESSOA
A diferença entre cenas presenciais e interfaces digitais é deliberada.
Em uma cena presencial, o protagonista continua sendo representado por ação narrada:
You explained to Ganbare-kun the consequences of purging the boss.

Em uma interface digital, a mensagem precisa existir como objeto textual dentro do mundo e por isso é exibida 
literalmente:
GYU_GAZE:
Dont worry about it! It was a difficult fight, but Im glad your partner is alright in the end.
Isso não cria uma voz falada fixa para o protagonista. O que aparece é a persona textual configurada pelo próprio 
jogador para sua conta online.
APLICAÇÃO NO NULL CHANNEL E NO SOCIAL
Writing Quirks são compartilhados por todas as mensagens digitais authored do protagonista. A mesma conta deve 
parecer escrita pela mesma pessoa no NULL CHANNEL e no Social.
No NULL CHANNEL, o sistema pode ser aplicado a replies do jogador em pontos authored de uma thread.
No Social, o sistema é aplicado às mensagens exibidas à direita do histórico de conversa quando uma escolha do 
jogador gera texto enviado.
CONSEQUÊNCIAS E TENDÊNCIAS
Writing Style e Kaomoji Preference são estritamente apresentação de identidade online. Eles não representam 
moralidade, personalidade psicológica nem Tendência.
NORMAL não significa BALANCED.
FORMAL não concede LOGIC.
CUTE não concede SYNC.
LAZY não concede SELF.
Usar kaomojis não modifica Affinity, Compatibility, evolução, reputação ou qualquer outro sistema por si só.
Quando uma resposta produz consequências, elas são determinadas pela intenção escolhida e pelo conteúdo 
semântico da mensagem, nunca pela formatação aplicada pelos Writing Quirks.
PERSISTÊNCIA
Quando uma mensagem é enviada, o texto final apresentado ao jogador passa a fazer parte daquele histórico digital. 
Posts e mensagens antigas devem preservar a forma como foram escritos no momento do envio e não devem ser 
reformatados retroativamente por alterações futuras de configuração ou por mudanças no sistema.
Isso permite que quotes, callbacks e releituras de conversas mostrem exatamente o texto que apareceu originalmente.
PRINCÍPIOS CANÔNICOS DO SISTEMA
1. O jogador escolhe a intenção; o jogo fornece uma única mensagem-base authored.
2. Writing Quirks modificam somente apresentação textual.
3. Nenhum Writing Style pode trocar palavras, adicionar slang ou reescrever o conteúdo semântico.
4. NORMAL, CUTE, LAZY e FORMAL utilizam as mesmas palavras-base.
5. Kaomoji Preference é independente do Writing Style.
6. Elementos expressivos incompatíveis com o tom podem ser suprimidos.
7. Writing Quirks não afetam Tendências, Compatibility, Affinity, evolução ou recompensa.
8. Consequências dependem da intenção da resposta, não da forma de escrever.
9. O mesmo Writing Profile é utilizado no NULL CHANNEL e no Social.
10. Mensagens persistentes preservam o texto final exibido no momento do envio.
11. O sistema não exige versões autorais diferentes para cada Writing Style.
5. NAVIGATOR, MUNDO, NPCs, LEADS E EXPLORAÇÃO
O MAPA [NAVIGATOR]
O mapa, além de ser o método pelo qual nosso jogador irá se locomover no mundo, é a tela principal do jogo e o 
“wallpaper” do fundo do desktop. Ela indica basicamente o "real life", e é onde o jogo de fato ocorre. É nela que haverá 
o mapa mundi, o overworld, as batalhas e as cenas de Visual Novel. É um mapa simples de GPS do centro de tóquio, 
contendo todos os locais de interesse que foram desbloqueados pelo jogador: Áreas de hangout, áreas para lutar contra
EXEs, áreas para procurar datacenters, lojas, a casa do jogador, áreas específicas de quest... por aí vai.

Quando o jogador opta por clicar em alguma dessas áreas de interesse, a tela se transforma, exibindo um Overworld 
Local simples: pequenos mapas representativos da área escolhida. É uma visão top-down simples, em que o jogador 
poderá explorar para encontrar NPCs, EXEs, entradas de datacenters e realizar interações.
No mapa principal, também será possível verificar em qual Período do dia o jogador se encontra, quantos períodos 
faltam para acabar o dia e quantos dias faltam para o update ser concluído.
Visualmente, esse mapa é como um GPS: Ele apresenta uma imagem do mapa de Tokyo como no Google Maps, mas 
com fundo escuro e ruas cinzas. Entre quadras e blocos, os locais acessíveis serão botões com ícones que indicarão 
que podem ser acessados, e o nome do local logo abaixo. Quando houver quests principais que são ativadas ao entrar 
em determinado lugar, ou o jogador entrar em uma thread que indica algum rumor sobre algo (como um EXE forte em 
um local específico ou a abertura de um data center raro em outro local específico) um ícone de exclamação irá estar 
acima do botão.
Os momentos de Visual Novel, quando promptados, escurecerão levemente a tela atual, exibindo "fotos de perfil" 
localizados em cima da caixa do diálogo assim como em visual novels: Sempre com o player e seus aliados à esquerda 
e os personagens com o qual o player está interagindo diretamente à direita. Um diálogo sempre conterá o nome do 
personagem que está falando no momento, a narrativa atual logo abaixo, e o botão "avançar" no canto inferior direito 
até que seja indicado uma opção de escolha.
Quando for necessário agir, o jogador geralmente terá de 4 a 6 escolhas que poderá fazer que mudarão o decorrer da 
cena e influenciarão seus stats. Essas escolhas ficam exibidas logo abaixo do texto do diálogo.
DISTRITOS, ÁREAS LOCAIS E PERMANÊNCIA
O Navigator leva o jogador a distritos ou regiões de Tóquio. Cada distrito pode conter um Overworld Local top-down, 
composto por sub-áreas menores, NPCs, EXEs, entradas de Data Center, lojas, pontos de encontro e eventos 
condicionais.
Uma região como Shibuya, por exemplo, pode conter:
Área comercial.
Beco obscuro.
Parque.
Passagem subterrânea.
Loja ou hangout spot.
Entrada condicional para Data Center.
No entanto, o jogador não precisa “limpar” Shibuya inteira em uma única visita. A área funciona como um espaço 
persistente. O jogador entra, anda livremente, escolhe o que fazer, gasta ações em atividades significativas e 
permanece ali até decidir sair.
Viajar para outra região consome 1 ação. Isso dá peso ao deslocamento e impede que o jogador pule entre todos os 
distritos até encontrar a opção mais eficiente. Permanecer na mesma região permite aproveitar melhor a viagem, mas 
cada atividade relevante ainda consome tempo.
Essa lógica cria uma sensação de expedição sem transformar o jogo em menu abstrato. A expedição não é uma ação 
separada; ela é o estado de estar fisicamente em uma região e gastar suas ações ali.
Exemplo:
O jogador lê uma thread sobre um EXE anômalo em Shibuya.
Viaja para Shibuya, consumindo 1 período.
Explora o local livremente.
Encontra um EXE comum e decide lutar; ao resolver o combate, consome 1 período.
Continua em Shibuya.
Avança o Lead do EXE anômalo, consumindo 1 período.
Continua em Shibuya.
Encontra um NPC conhecido e decide desafiar para PVP; ao resolver o PVP voluntário, consome 1 período.
Depois decide ir para Akihabara, consumindo 1 período de deslocamento.
O jogador não está escolhendo ações em um menu. Ele está jogando um RPG top-down normalmente, mas o mundo 
avança quando algo realmente importante é concluído.
PARTY E NPCS DURANTE EXPLORAÇÃO
NPCs jogadores de NULL NETWORK podem ser convidados para party através do Social ou através de eventos no 
mundo. A party representa jogadores reais dentro da narrativa se reunindo fisicamente para jogar NULL NETWORK 
juntos.

Party não deve ser tratada como um buff permanente até o fim do dia. Ela deve durar enquanto fizer sentido para o 
objetivo combinado, para a rotina do NPC e para o contexto da área.
Existem três tipos gerais de duração de party:
Party por Objetivo
O NPC aceita participar de uma ação específica, como derrotar um EXE anômalo, entrar em um Data Center, ajudar em
uma Lead ou participar de um PVP combinado. Ao concluir esse objetivo, ele pode sair da party.
Party por Área
O NPC aceita permanecer com o jogador enquanto ambos estiverem na mesma região. Ele pode participar de mais de 
uma ação local, desde que ainda tenha tempo livre e motivação para continuar.
Party por Período Especial
Em casos de alta affinity, evento importante, quest pessoal ou incidente narrativo, o NPC pode permanecer por uma 
sequência maior de ações, até o fim de uma fase do dia ou até a conclusão de uma dungeon/evento.
A decisão do NPC de continuar ou sair deve depender de:
Affinity com o jogador.
Personalidade.
Rotina diária.
Ocupação.
Relação com outros membros da party.
Perigo da área.
Resultado do último combate.
Escolhas morais do jogador.
Se o objetivo original já foi concluído.
Se o NPC tem interesse no próximo Lead.
Exemplo:
O jogador chama um NPC para enfrentar um EXE anômalo em Shibuya.
O NPC aceita porque também viu a thread.
Após o combate, o jogador decide investigar um Data Center próximo.
Se a afinidade for baixa, o NPC pode dizer que veio apenas pelo EXE e vai embora.
Se a afinidade for alta, pode aceitar continuar.
Se for um NPC medroso, pode recusar por perigo.
Se for um NPC obcecado por descoberta, pode querer continuar mesmo cansado.
Se for um NPC mercenário, pode exigir recompensa.
Isso faz com que party seja socialmente significativa. O jogador não monta uma equipe apenas por eficiência; ele cria 
relações, reputação e histórico compartilhado.
NULL NETWORK deve evitar que party vire apenas uma escolha matemática. O ideal é que cada NPC pareça uma 
pessoa com tempo, vontade, cansaço, orgulho e limites próprios.
LEADS E INCIDENTES
Leads são sinais que indicam ao jogador que algo pode estar acontecendo em algum lugar. Eles são a ponte entre o 
NULL CHANNEL, o Social, o Navigator e o gameplay top-down.
Um Lead não é necessariamente uma quest formal. Pode ser apenas uma thread estranha, uma mensagem privada, 
um rumor, uma denúncia, um guia, uma provocação, um pedido de ajuda, uma foto apagada, um bug report ou um 
comentário do parceiro APK.
Tipos comuns de Lead:
Rumour Lead
Uma thread menciona comportamento estranho em uma área específica.
Help Lead
Um jogador pede ajuda em uma situação concreta.
Social Lead
Um NPC quer party, PVP, hangout ou ajuda.
Data Center Lead
Relatos indicam abertura ou instabilidade de um Data Center.

Anomaly Lead
Um EXE ou evento estranho aparece em um local.
Guide Lead
Um guia ensina uma mecânica e sugere um lugar onde testá-la.
Update Lead
Um Micro-Update altera alguma área, spawn ou comportamento.
APK Lead
O parceiro APK sente algo estranho ou pede para visitar um lugar.
Ranking Lead
Um ranker, PK ou jogador competitivo provoca movimento em uma área.
Ao seguir um Lead, o jogador pode encontrar um Incidente.
Incidentes são situações curtas ou médias que acontecem dentro das áreas e geram escolhas. Eles podem envolver 
combate, diálogo, exploração, moralidade, NPCs, EXEs, Data Centers ou informações escondidas.
Exemplos de Incidentes:
Um novato está prestes a perder seu APK para um EXE raro.
Um PK está usando um rumor falso para atrair jogadores fracos.
Um NPC conhecido está discutindo com outro jogador.
Um EXE anômalo apareceu em uma sub-área.
Um Data Center abriu em um local abandonado.
Um jogador pede ajuda, mas pode estar mentindo.
Um mod apagou uma thread suspeita.
Um arquivo da WEWERE aparece em um terminal.
O APK do jogador reage com medo a uma área aparentemente normal.
Um boss deixa pistas antes de aparecer oficialmente.
Incidentes são onde as escolhas de tendência aparecem de forma natural.
O jogador pode:
Ajudar.
Ignorar.
Cobrar recompensa.
Investigar antes de agir.
Agir imediatamente.
Chamar reforços.
Usar alguém como isca.
Reportar ao fórum.
Esconder informação.
Vender informação.
Purificar.
Purgar.
Domar.
Fugir.
Essa estrutura resolve o problema de onde o jogador faz escolhas. NULL NETWORK não precisa obrigar o jogador a 
conversar com todos os NPCs como Disco Elysium, nem encher o mapa de sidequests tradicionais como Baldur’s Gate.
As escolhas surgem porque o jogador segue sinais da comunidade e encontra situações ambíguas no mundo.
NPCs fixos
NPCS FIXOS
NPCs jogadores de NULL NETWORK são parte do core principal do jogo. É possível vê-los interagindo entre si nos 
fóruns, receber friend requests de personagens com o qual você interagiu no mundo, desafiar para PVP, convidar para 
party, chamar pra sair... São ações modulares e simples, mas que incluem uma certa profundidade. O jogador poderá 

aumentar affinity com NPCs, o que torna possível convidar para party, desafiar, chamar pra sair, e receber itens ou 
dicas reais quando o affinity é alto.
NPCs podem ser divididos em 3 tipos. Isso é altamente influenciado pelo modo com o qual NPCs são criados nos jogos 
YUGIOH Tag Force:
NPCS PRINCIPAIS - NPCS principais são aqueles no core da história, compostos por um núcleo principal de pessoas 
que estão ativamente fazendo coisas muito importantes. São eles geralmente que organizam quests principais ou 
importantes, solicitando ajuda. Possuem aparências únicas e muitos diálogos. Cerca de 12 personagens.
NPCS SECUNDÁRIOS - Também possuem aparências únicas e um pouco mais de diálogo, mas geralmente só estão 
presentes no Overworld em áreas aleatórias e não se sobressaem muito. Cerca de 15 personagens.
NPCS TERCIÁRIOS - São como os NPCs fodders de YUGIOH Tag Force: Possuirão personalidades pré-embutidas 
que determinam que tipo de diálogo terão para cada uma das opções de interação, as aparências são mais simples e 
criadas pelo mesmo criador de personagem que o jogador, não sendo tão únicas. Cerca de 33 personagens.
Navigator, Spawn Tables e rotinas de NPC
NAVIGATOR -
O Navigator é, em sua essência, o mapa do jogo. No topo da interface, uma barra estilizada deve comunicar o dia da 
semana, a data, DAY/NIGHT, o action_block atual, quantos blocos livres restam na rotina do personagem e o 
countdown da versão 1.0. A visualização não usa uma quantidade fixa de cinco símbolos: ela precisa representar 
corretamente a grade canônica de 24 blocos e os bloqueios de ocupação.
Os ícones de localização estarão todos pré-definidos, mas ficam invisíveis até o jogador descobrí-los de alguma forma 
(ativar uma flag de que descobriu). O mapa em si é uma imagem de background com vários ícones espalhados pré￾definidamente, mas invisíveis até suas condições de descoberta serem desbloqueadas. Esses ícones possuem 3 
espaços: O centro, que é onde o ícone principal do local fica, o topo, que terá pequenos ícones que indicam que algo 
está acontecendo ali (uma exclamação para um local novo, uma caveira para um local com um boss poderoso), e o 
espaço inferior é onde fica o nome do local.
Quando o jogador seleciona um dos ícones de localização para ir na localização atual, o mapa chama o gerador de 
eventos para definir quais EXEs estarão na área, quais NPCs estarão na área, se há um Data Center e se ele está ativo
no atual período, e verifica se há alguma flag ativada para ativar algum evento de quest ou história. Tudo isso será 
definido com .tres. Há então a transição para o modo Overworld: A tela do mapa se torna uma tela local onde o jogador 
controla um boneco na tela em um mapa físico, podendo interagir com os NPCs ou procurar EXEs ou o Data Center 
para lutar.
Quando ocorre um diálogo, a transição é feita pelo app do Navigator.
Quando ocorre um combate, a transição também é feita pelo app do Mapa. Tanto o Overworld, quanto o Diálogo, 
quanto o Combate estão diretamente vinculados ao APP do Navigator.
Sistema de Spawns, Projeções e Encontros
A fauna e os encontros do mapa não são definidos diretamente na cena. O Overworld Local recebe EXEs visíveis a 
partir de dados de spawn/ecologia e eventos autorais.
Cada área do jogo possui um MapLocation.tres que referencia os dados necessários para definir quais EXEs podem se 
projetar naquele espaço, quais eventos podem ocorrer e quais condições modificam essa presença.
As tabelas de spawn/projeção são condicionadas por DAY/NIGHT, action_block e demais Conditions relevantes, além 
do estado ecológico descrito no Capítulo 9.
Exemplo:
DAY — pesos/condições para quais EXEs e variantes podem se projetar na subárea atual.
NIGHT — pesos/condições próprios, permitindo mudança de fauna, comportamento e Variant Nodes sem trocar a 
MapScene.
O mesmo MapLocation pode usar tabelas/condições diferentes dentro de DAY ou NIGHT por meio do índice de 
action_block e de Conditions; Morning/Afternoon/Evening não são períodos canônicos. População, Resonance, Danger,
Infestation, eventos e outros filtros podem alterar a manifestação final.
Para encontros ambientais, a SpawnTable não escolhe diretamente uma luta completa. Ela manifesta EXEs visíveis. Ao
entrar em contato com um deles, a Combat Call descrita no Capítulo 9 fecha a formação com o EXE tocado e possíveis 
respondedores próximos. CombatEncounter.tres continua válido para encontros autorais que precisam de formação 
previamente definida, como tutorial, StoryEvent, boss ou operação específica.
Isso permite alterar fauna, densidade e encontros de uma área pelos dados do MapLocation/ecologia, sem hardcode na
cena e sem esconder grupos inteiros atrás de um único roll de batalha.

Sistema de NPCs e Rotinas
Os NPCs do jogo possuem um banco de dados próprio.
Cada NPC é definido por um NPCData.tres contendo:
nome
avatar
tipo (Primário, Secundário, Fodder)
afinidade com o protagonista
Além disso, cada NPC possui uma rotina baseada no horário do dia.
Exemplo:
DAY / action blocks configurados → Online, Outside ou outra rotina definida por dados.
NIGHT / action blocks configurados → Online, Outside, Offline ou outra rotina definida por dados.
Rotinas não usam Morning/Afternoon/Evening como períodos canônicos; usam DAY/NIGHT + action_block + condições.
Essa rotina determina onde o NPC aparece ou se está disponível para interação.
O NPC também pode possuir conjuntos de respostas usados no sistema de chat.
Story Events e exploração data-driven
Sistema de Eventos da História
A progressão da história é controlada por Flags globais.
Essas flags representam eventos importantes que já ocorreram.
Exemplos:
tutorial_completed
met_zerone
download_started
Eventos da história são definidos por StoryEvent.tres.
Cada evento possui condições para ser ativado:
flags necessárias
dia específico
período do dia
localização
Quando todas as condições são atendidas, o evento pode iniciar automaticamente, geralmente disparando um diálogo 
ou cutscene.
Após ocorrer, o evento altera flags para indicar que a história avançou.
Sistema de Exploração do Mapa
A exploração do jogo acontece em áreas definidas que representam diferentes locais da cidade.
Cada área do jogo é definida por um MapLocation.tres, que contém todas as informações necessárias para carregar e 
gerenciar aquele espaço.
Esse arquivo define:
nome da área
cena do mapa correspondente
NPCs presentes
eventos disponíveis
tabelas de spawn/projeção e encontros autorais
Quando o jogador entra em uma área, o jogo carrega a MapScene associada e posiciona os NPCs que estão 
disponíveis naquele horário.
A presença de NPCs depende de suas rotinas diárias, definidas no NPCData.
Durante a exploração, o jogador pode:
interagir com NPCs

acessar computadores ou objetos
iniciar eventos narrativos
entrar em contato com EXEs visíveis ou iniciar encontros autorais
Combates podem ser iniciados de duas formas principais:
encontros ambientais: EXEs são projetados visivelmente pela tabela de spawn/ecologia e o contato inicia uma Combat 
Call;
encontros autorais: StoryEvents, Data Centers, bosses, tutorial ou outras operações podem iniciar uma formação 
previamente definida.
As tabelas de spawn definem quais EXEs podem se manifestar naquele local e com quais pesos/condições. A formação
ambiental final depende de quais criaturas estão efetivamente próximas e respondem à Combat Call, podendo variar 
por DAY/NIGHT, action_block, ecologia, comportamento, Variant Node, Danger e Infestation.
Além disso, o MapLocation também pode conter StoryEvents associados àquele local, que são ativados quando suas 
condições são atendidas.
Esses eventos podem iniciar:
diálogos
cutscenes
combates
mudanças no estado da área
Isso permite que a mesma área evolua ao longo da história sem precisar criar mapas completamente novos.
A exploração funciona como o elo entre todos os outros sistemas do jogo, conectando NPCs, eventos narrativos e 
encontros de combate dentro do mesmo espaço.

DATA CENTERS — ENTRY POINTS, TOPOLOGIA VIRTUAL E RUNS
Visão geral
Data Centers são dungeons virtuais de alto comprometimento. Em vez de reutilizar o Overworld Local top-down, cada 
Data Center é representado como uma topologia abstrata de nodes conectados por caminhos ramificados. O jogador 
escolhe a rota, resolve o conteúdo do node atual e avança até uma saída legítima ou até o Core/Boss final.
A identidade desejada é a de um “roguelike básico” em estrutura de mapa: uma run curta ou média, legível como grafo, 
com risco acumulado e escolhas de rota. A referência estrutural é um mapa de caminhos ramificados no qual cada node
representa um evento discreto, e não uma dungeon física convencional com salas exploradas em tempo real.
Entry Point físico
Todo Data Center precisa estar associado a um Entry Point localizado no espaço físico real. Esses pontos são 
deliberadamente pequenos e desconfortáveis: compartimentos técnicos, gabinetes de manutenção, interiores de 
geradores, nichos, armários ou outros espaços onde mal cabe uma pessoa.
Para iniciar a sincronização, o Operator precisa entrar completamente no Entry Point e fechar a abertura/porta. O Data 
Center não é acessado como uma porta física para outro espaço; o corpo permanece no Entry Point enquanto a 
experiência virtual assume a interação do jogo.
A necessidade de permanecer dentro do espaço fechado é uma regra diegética dos Data Centers. A explicação técnica 
completa pode permanecer obscura dentro da ficção; o requisito operacional é conhecido pelos usuários: entrar, fechar,
sincronizar.
Estrutura de nodes
A run é composta por um grafo de caminhos. O grafo pode ser authored integralmente; geração procedural total não é 
requisito. Pools e variações de conteúdo podem ser aplicadas sobre nodes authored para aumentar rejogabilidade sem 
transformar o sistema em um gerador universal de dungeons.
Tipos canônicos de node incluem:
COMBAT — encontro contra EXEs ou formação autoral.
EVENT — situação narrativa, escolha, risco, interação ou alteração da run.
CACHE / REWARD — prêmio, item, dado, recurso ou recompensa específica.
RECOVERY — oportunidade limitada de restaurar recursos ou remover condições quando o conteúdo permitir.
TERMINAL — informação, mudança da topologia, regra local, acesso ou evento técnico.
EXIT — rota legítima de desconexão antecipada.
UNKNOWN — node cujo tipo/conteúdo não é revelado antes de ser escolhido.
CORE / BOSS — objetivo final da run e rota normal de conclusão.
Uma run não precisa utilizar todos os tipos. Data Centers narrativos podem possuir grafos e pools próprios, mantendo a 
mesma gramática sistêmica.
Comprometimento e saída
Depois que a sincronização começa, não existe comando genérico LEAVE e combates internos não oferecem Run 
Away. Entrar em um Data Center significa aceitar uma run comprometida.
O Operator deixa o Data Center somente quando uma das condições abaixo ocorre:
• o Core/Boss é concluído e a run termina normalmente;
• um EXIT Node/Event válido é alcançado e utilizado;
• um evento autoral força ejeção/desconexão;
• outra resolução especial explicitamente definida pelo próprio Data Center ocorre.
EXIT não é equivalente ao Run Away de combate. Ele é uma propriedade da topologia da dungeon e precisa ser 
alcançado como parte da rota.
Attrition dentro da run
Data Centers preservam desgaste entre nodes. HP atual, INCAPACITATED e qualquer Status Effect explicitamente 
marcado como persistente continuam valendo ao entrar no próximo node da mesma run. Buffs/debuffs puramente 
temporários de combate terminam normalmente quando seu escopo termina.
Isso faz com que Recovery, Module Capacity, composição de party e escolha de rota tenham valor real. Um combate 
vencido com pouco HP não é apagado pelo simples ato de avançar para o próximo node.

A regra de persistência descrita aqui é canônica para a duração de uma run de Data Center. [OPEN/TBD] A 
persistência de HP/condições entre combates independentes no Overworld, fora de Data Centers, continua sendo uma 
decisão separada.
Risco, boss e comunicação
O caminho normal de um Data Center termina em um Core/Boss. A interface de entrada deve comunicar de forma clara 
que Run Away e retirada voluntária convencional ficam indisponíveis após a sincronização. O sistema pode informar o 
custo temporal da etapa atual sem revelar obrigatoriamente o mapa inteiro.
[OPEN] A relação exata entre quantidade de nodes, profundidade da run e consumo de action blocks ainda precisa ser 
balanceada. A estrutura temporal existente de atividades complexas por etapas continua válida até essa definição.
[OPEN] A política exata de retenção de recompensas ao utilizar um EXIT antecipado ainda precisa ser fechada por 
Data Center/regra global; não assumir que toda saída perde tudo nem que toda recompensa é sempre preservada.
6. APKs, EVOLUÇÃO, PERSONALIDADE, NÍVEL E STATS
6.1 APKs e EXEs — topologia canônica
APKs são as criaturas digitais que podem formar vínculo válido com Operators. EXEs são entidades em estado de 
integridade corrompido; no mundo, os inimigos gerados normalmente são EXEs. A ficção in-game os apresenta como 
ameaça à rede e os APKs como contingência que alcança seu potencial completo ao formar vínculo com um jogador.
Cada linha evolutiva comum possui 11 formas evolutivas. EXE NÃO é uma décima segunda forma: é uma camada de 
Integrity State que pode coexistir com uma forma evolutiva.
• INIT — forma-base.
• Intermediárias — BALANCED, VALOUR, LOGIC, SELF e SYNC.
• Finais — XVALOUR, XLOGIC, XSELF, XSYNC e NULL.
• Qualquer forma intermediária pode alcançar qualquer uma das cinco finais quando os requisitos daquela 
EvolutionBranch são cumpridos; a trajetória anterior influencia identidade/linhagem, mas não trava 
automaticamente a tendência final.
6.2 Stats e parâmetros de combate — vocabulário canônico
Os cinco stats naturais que escalam diretamente com nível são HP, ATK, DEF, MATK e MDEF. Max Stability é um limite
técnico fixo de 100. A variável ligada a nível/forma é Stability Recovery. DODGE, CRIT e outros parâmetros percentuais 
existem, mas são tratados separadamente do orçamento natural desses cinco stats.
• HP — vida do APK.
• ATK — base de dano físico.
• DEF — defesa contra dano físico conforme a fórmula de dano.
• MATK — base de dano mágico.
• MDEF — defesa contra dano mágico.
• STABILITY — recurso atual, de 0 a 100, gasto por Active Modules.
• STABILITY RECOVERY — quantidade/percentual recuperado por ciclo conforme as regras de progressão.
• DODGE — parâmetro de evasão. Na regra atual, a ACCURACY do Module é reduzida por metade do DODGE do 
alvo.
• CRIT — chance de crítico; o comportamento detalhado continua o descrito no sistema de combate.
6.3 Parceiro e personalidade
Cada jogador possui apenas um parceiro. É possível purificar EXEs e domá-los para se tornarem um novo APK 
parceiro, mas o APK antigo desaparece.
APKs não aparecem durante diálogos oficiais da história, no entanto fazem vários comentários com pequenas dialog 
box em várias ocasiões. Eles podem expressar-se de maneira única quando interagidos na aba de Perfil, e também 
reagem a situações específicas de combate ou evolução.
Todo APK possui uma Personalidade, e um modo único de se referir ao jogador. Enquanto alguns preferem chamá-lo 
pelo nome ou apelido, outros podem chamá-lo unicamente de "Boss", "Master", "Partner". Isso é definido de maneira 
aleatória, porém controlada, a partir do momento que o APK se torna parceiro do jogador.

Um APK específico sempre terá até 3 personalidades específicas que pode adotar. Evoluir pode mudar sua 
personalidade.
As personalidades disponíveis são doze, e todas elas alteram quais são as frases que o APK fala e reage em suas 
dialog box. Um APK corajoso pode tentar motivar o jogador no início do combate, um medroso pode exibir o seu medo...
Por aí vai.
3 personalidades ficam salvas dependendo da espécie do APK: Um APK baseado em um herói, por exemplo, pode ser 
tanto Otimista quanto Corajoso quanto Sábio. Ele pode começar sendo Corajoso, mas evoluir para uma forma cuja 
personalidade é Sábio.
A única coisa que não muda é o modo com o qual ele chama o jogador.
APKs possuem dois slots para Modules passivos: Modules que dão algum efeito permanente no combate. O primeiro 
sempre será um module característico seu, fixo e introcável único para cada linha evolutiva de APK existente, enquanto 
o outro é destinado para Modules passivos obtidos no decorrer do jogo que são diversos e compartilhados.
A obtenção de Active Modules por SCAN não é uma habilidade do APK. SCAN é uma Player Action do Operator e 
utiliza os slots do ciclo conforme o Capítulo 7.
6.4 Tendência em combate e evolução mid-battle
SISTEMA DE TENDÊNCIA EM COMBATE E EVOLUÇÃO MID-BATTLE
Além das escolhas narrativas feitas em diálogos e eventos, o combate também influencia as Tendências do 
protagonista. No entanto, os pontos gerados durante o combate não são aplicados imediatamente às Tendências 
globais. Eles são registrados primeiro em um log temporário da batalha, chamado Combat Tendency Log.
Esse sistema possui dois objetivos principais:
Permitir que o comportamento do jogador durante a batalha abra janelas de evolução para o APK parceiro.
Gerar um bônus de Tendência ao final do combate, baseado no modo dominante com que o jogador lutou.
Dessa forma, o combate não serve apenas para ganhar XP ou derrotar inimigos. Ele também funciona como uma leitura
comportamental do jogador.
COMBAT TENDENCY LOG
Durante cada combate, o jogo cria um registro temporário de Tendências:
combat_valour
combat_logic
combat_sync
combat_self
Esses valores começam em 0 no início de cada batalha e são resetados ao final dela.
Ações realizadas durante o combate adicionam pontos a esse log temporário. Esses pontos não representam aumento 
permanente imediato. Eles representam como o jogador está agindo naquela luta específica.
Exemplo:
Usar vários módulos ofensivos, causar dano alto, tomar riscos e continuar pressionando o inimigo aumenta 
combat_valour.
Usar SCAN, trocar módulos para counterar o inimigo, explorar a Timeline e evitar dano previsto aumenta combat_logic.
Curar, proteger aliados, manter Stability segura, salvar um parceiro de Unstability ou usar ações de suporte aumenta 
combat_sync.
Usar módulos arriscados, abusar de Stability, priorizar sobrevivência própria, aceitar efeitos corrompidos ou sacrificar 
segurança por vantagem aumenta combat_self.
Esses valores temporários são usados durante a batalha para calcular duas coisas:
Projected Tendencies
Combat Style final
PROJECTED TENDENCIES
Como as Tendências permanentes só são alteradas ao final da batalha, o jogo utiliza uma versão projetada delas 
durante o combate.
Projected Tendencies são calculadas assim:
projected_valour = global_valour + combat_valour
projected_logic = global_logic + combat_logic

projected_sync = global_sync + combat_sync
projected_self = global_self + combat_self
Esses valores projetados servem para checar requisitos de evolução no meio do combate.
Exemplo:
O jogador começa a luta com:
VALOUR 28
LOGIC 20
SYNC 18
SELF 17
Durante o combate, ele ganha +2 combat_valour.
Então, durante aquela luta, o sistema considera:
projected_valour = 30
Isso não significa que o jogador já ganhou VALOUR permanente. Significa apenas que, naquele combate, ele está 
agindo de forma suficientemente VALOUR para que uma evolução relacionada a VALOUR possa despertar.
Ao final do combate, os valores temporários são convertidos em um bônus muito menor e controlado, definido pelo 
Combat Style.
EVOLUÇÃO MID-BATTLE
A evolução do APK parceiro só pode acontecer durante combate.
O Perfil ou a Enciclopédia podem indicar que um APK possui potencial evolutivo, mas não devem permitir evoluir 
diretamente fora de batalha. A evolução deve ser tratada como um evento instável que acontece quando o parceiro 
reage ao comportamento do jogador em uma situação real de perigo.
Cada EvolutionBranch.tres possui dois grupos principais de requisitos:
Core Requirements
Evolution Catalysts
Core Requirements são os requisitos base obrigatórios. Eles definem se aquela evolução faz sentido para o estado 
atual do APK e do jogador.
Evolution Catalysts são gatilhos voláteis que podem acontecer durante o combate. Basta que um dos Catalysts 
definidos seja cumprido para abrir a janela de evolução, desde que todos os Core Requirements já estejam válidos.
Exemplo de evolução VALOUR:
Core Requirements:
APK level >= 15
VALOUR é a Tendência dominante
VALOUR está pelo menos 5 pontos acima de LOGIC, SYNC e SELF
Evolution Catalysts:
causar 100 ou mais de dano em um único ciclo
OU
projected_valour chegar a 30 ou mais durante o combate
Nesse caso, a evolução não exige que todas as condições dramáticas aconteçam ao mesmo tempo. O APK já precisa 
estar apto para uma evolução VALOUR, mas o momento exato da evolução pode ser ativado por mais de um caminho.
Isso evita que o jogador precise caçar uma fórmula secreta específica demais. Em vez disso, ele pode evoluir 
naturalmente caso esteja jogando de forma coerente com aquela Tendência.
A regra geral para evolução é:
O APK precisa cumprir os Core Requirements.
Durante o combate, pelo menos um Evolution Catalyst precisa ser ativado.
A checagem acontece em uma janela válida de combate.
Se uma branch válida for encontrada, o jogo abre o prompt de evolução.
JANELAS DE CHECAGEM DE EVOLUÇÃO
A evolução não deve ser checada a cada ação individual, para evitar poluição visual e excesso de interrupções.
A checagem principal deve acontecer no fim de cada ciclo de combate, depois que todos os módulos do ciclo foram 
executados e antes da nova Timeline ser reconstruída.
Fluxo:

O jogador prepara seus módulos e posicionamento.
O jogador executa o ciclo.
O ciclo processa dano, suporte, buffs, debuffs, Stability e efeitos.
O Combat Tendency Log é atualizado.
O sistema calcula Projected Tendencies.
O EvolutionManager verifica as EvolutionBranches válidas.
Se uma evolução estiver disponível, o combate pausa.
O Navigator exibe o Evolution Overlay.
O jogador aceita ou recusa a evolução, dependendo da branch.
O APK evolui, seus dados são atualizados e a Timeline é reconstruída.
O combate continua.
Algumas lutas específicas também podem possuir janelas especiais de evolução, como:
mudança de fase de boss
APK entrando em HP crítico
APK entrando ou saindo de Unstability
aliado sendo derrotado
inimigo importante sendo derrotado
evento narrativo no meio do combate
uso de um módulo específico
Essas janelas especiais devem ser definidas por dados no CombatEncounter.tres ou em um Resource específico de 
EvolutionWindow, evitando hardcode.
PROMPT DE EVOLUÇÃO
Quando uma evolução é ativada, o combate deve pausar e abrir um overlay visual dentro do Navigator.
Exemplo:
LINK SURGE DETECTED
Your APK is responding to your combat pattern.
Evolution route unstable.
[EVOLVE] [HOLD FORM]
Evoluções comuns devem permitir que o jogador aceite ou recuse.
Evoluções narrativas, corrompidas ou vinculadas a eventos específicos podem ser forçadas ou apresentar escolhas 
diferentes.
Exemplo:
SIGNAL BREACH DETECTED
Your APK is receiving an unknown route.
[STABILIZE] [LET IT IN]
Esse sistema permite que evoluções normais, evoluções especiais, evoluções corrompidas e evoluções de história 
usem a mesma base estrutural.
COMBAT STYLE
Ao final do combate, o Combat Tendency Log é analisado para definir o estilo dominante da luta.
Cada Tendência possui um Combat Style correspondente:
VALOUR → VALIANT
LOGIC → CALCULATED
SYNC → SYNCHRONIZED
SELF → RUTHLESS
O Combat Style é determinado pela Tendência temporária mais alta no Combat Tendency Log.
Exemplo:
combat_valour = 14
combat_logic = 4
combat_sync = 2
combat_self = 1
Resultado:
Combat Style: VALIANT
Bônus final: +2 VALOUR

O jogador não recebe todos os pontos temporários como pontos permanentes. O log inteiro é comprimido em um 
pequeno bônus final. Isso evita que o jogador farme Tendência de forma exagerada em uma única batalha.
REGRAS DE RESOLUÇÃO DO COMBAT STYLE
Para que um Combat Style seja considerado dominante, ele precisa cumprir duas condições:
A Tendência temporária precisa atingir uma pontuação mínima.
Ela precisa estar acima das outras por uma margem mínima.
Valores iniciais recomendados:
minimum_combat_style_score = 6
dominance_margin = 3
Exemplo válido:
VALOUR 10
LOGIC 5
SYNC 2
SELF 1
VALOUR venceu por margem suficiente.
Resultado:
Combat Style: VALIANT
Bônus: +2 VALOUR
Exemplo sem dominância clara:
VALOUR 8
LOGIC 7
SYNC 2
SELF 1
VALOUR foi maior, mas não venceu por margem suficiente.
Resultado:
Combat Style: MIXED
Bônus: +1 VALOUR e +1 LOGIC
Exemplo de combate irrelevante:
VALOUR 2
LOGIC 1
SYNC 0
SELF 0
Nenhuma Tendência atingiu a pontuação mínima.
Resultado:
Combat Style: NEUTRAL
Bônus: nenhum
O bônus total de Tendência recebido por Combat Style nunca deve passar de 2 pontos por combate comum.
Combates de boss, eventos de história ou incidentes podem aplicar bônus maiores, mas isso deve ser definido 
manualmente por dados no encontro ou evento.
BÔNUS FINAL DE TENDÊNCIA
Ao final do combate, o jogador pode receber Tendência por três fontes diferentes:
Combat Style
Escolha de resolução
Evento narrativo do combate
Combat Style representa como o jogador lutou.
Escolha de resolução representa o que o jogador decidiu fazer com o inimigo derrotado.
Evento narrativo representa escolhas específicas de boss, diálogo ou cutscene.
Exemplo:
O jogador lutou de forma agressiva durante toda a batalha.

Combat Style: VALIANT
+2 VALOUR
Ao derrotar o EXE, o jogador concluiu PURGE naquele alvo.
PURGE
+SELF
Resultado final:
O jogador recebe pontos por ter lutado como VALOUR e também recebe o ponto de SELF associado ao PURGE 
concluído naquele alvo.
Isso permite que o combate registre tanto comportamento tático quanto escolha narrativa.
EXEMPLOS DE GANHO TEMPORÁRIO POR AÇÃO
VALOUR
causar dano alto
usar módulos ofensivos
derrotar inimigo em ciclo agressivo
sobreviver em HP crítico
recusar fugir
manter pressão mesmo com Stability baixa
causar crítico
LOGIC
usar SCAN
trocar módulos para responder à Timeline inimiga
evitar dano previsto por reposicionamento
aplicar debuff no momento correto
usar módulo eficiente contra o padrão do inimigo
vencer um ciclo tomando pouco ou nenhum dano
explorar fraqueza conhecida
SYNC
curar aliado
proteger aliado
limpar debuff
impedir Unstability
usar módulo de suporte
manter a party viva
preparar Purify
salvar um aliado em HP crítico
SELF
usar módulos de alto risco
gastar Stability de forma agressiva
usar módulo corrompido
priorizar dano mesmo colocando aliado em risco
fugir de combate opcional
deixar aliado absorver pressão
escolher vantagem individual em vez de segurança coletiva
Esses ganhos devem ser configuráveis por dados sempre que possível. Módulos podem carregar valores próprios de 
Tendência temporária, e eventos contextuais do combate podem adicionar bônus extras.
ESTRUTURA DATA-DRIVEN
Para evitar hardcode, o sistema deve ser orientado por Resources.
ModuleData.tres pode possuir campos de ganho temporário:
combat_valour_gain
combat_logic_gain
combat_sync_gain
combat_self_gain
Ou um array de efeitos de Tendência temporária:

combat_tendency_gains: Array[CombatTendencyGainData]
CombatTendencyGainData define:
tendency
amount
condition
Exemplo:
Um módulo ofensivo simples pode dar:
VALOUR +1
Um módulo de SCAN pode dar:
LOGIC +2
Um módulo de cura pode dar:
SYNC +2
Um módulo corrompido pode dar:
SELF +2
Além dos módulos, o CombatManager pode registrar eventos contextuais:
cycle_damage_dealt
single_hit_damage
critical_hit
ally_saved
enemy_defeated
scan_completed
stability_broken
unstability_triggered
run_attempted
Esses eventos podem ser usados tanto para adicionar pontos temporários ao Combat Tendency Log quanto para ativar 
Evolution Catalysts.
RESOURCES NECESSÁRIOS
CombatTendencyLog
Estrutura temporária criada no início de cada combate.
Campos:
combat_valour
combat_logic
combat_sync
combat_self
cycle_damage_dealt
highest_cycle_damage
highest_single_hit_damage
cycles_elapsed
scan_uses
support_uses
offensive_uses
corrupted_uses
critical_hits
allies_saved
enemies_defeated
Esse log não é salvo permanentemente. Ele existe apenas durante o combate atual.
EvolutionBranch.tres
Campos principais:
target_apk_data
combat_only
core_requirements
evolution_catalysts
prompt_player

forced_if_valid
once_per_battle
CoreRequirementData
Define requisitos obrigatórios da evolução.
Exemplos:
min_level
required_current_form
required_global_tendency
required_projected_dominant_tendency
dominance_margin
required_flags
forbidden_flags
EvolutionCatalystData
Define gatilhos voláteis.
Exemplos:
projected_tendency_at_least
cycle_damage_at_least
single_hit_damage_at_least
used_scan_this_combat
entered_unstability
boss_phase_at_least
ally_defeated
enemy_defeated
critical_hit_count_at_least
CombatStyleRuleData
Define como o bônus final do combate é resolvido.
Campos:
minimum_combat_style_score
dominance_margin
dominant_bonus_amount
mixed_bonus_amount
max_bonus_per_combat
FILOSOFIA DO SISTEMA
A evolução em NULL NETWORK não deve parecer um menu de upgrade. Ela deve parecer uma resposta do parceiro 
ao comportamento do jogador sob pressão.
O jogador não aperta um botão no Perfil para evoluir. Ele age de determinada forma no combate, cria as condições 
certas e vê seu parceiro reagir no meio da batalha.
Ao mesmo tempo, o sistema não deve ser tão complexo a ponto de exigir que o jogador siga uma checklist secreta 
impossível. Cada evolução deve possuir requisitos base claros para o designer, mas seus gatilhos devem permitir 
caminhos alternativos.
A regra geral é:
Level suficiente
Tendência compatível
Pelo menos um catalisador de combate
Dessa forma, o jogador pode descobrir evoluções naturalmente, mas jogadores atentos ao fórum, à Enciclopédia e aos 
padrões de combate conseguem entender melhor como manipular o sistema.
O resultado desejado é que a evolução pareça orgânica, volátil e dramática, sem perder controle sistêmico.
Abaixo está o texto já em formato de seção de GDD, pronto para colar/adaptar.
6.5 Progressão de nível, EXP e estatísticas
NOTA DE NOMENCLATURA DOS EXEMPLOS: NOVIRE e TECHNER aparecem em exemplos numéricos herdados do
documento original. NOVIRE é identificador legado do starter VALOUR cujo nome INIT final ainda está OPEN; 
TECHNER foi substituído por CALIGUNNER. Os números e fórmulas dos exemplos continuam sendo a informação 
relevante.

Sistema de Progressão de Nível, Experiência e Estatísticas
Visão geral
Cada APK possui um nível entre 1 e 100.
O nível 100 é o hard cap técnico do jogo. Entretanto, o nível 80 funciona como um limite prático: a quantidade de EXP 
necessária cresce abruptamente depois dele, de modo que nenhum jogador conhecido de NULL NETWORK conseguiu 
ultrapassá-lo.
A progressão de um APK é composta por quatro elementos:
Nível, que determina quanto do potencial da forma já foi alcançado.
Forma atual, que define o corpo estatístico principal.
Linhagem intermediária, que preserva 25% da distribuição estatística do caminho anterior.
Pontos distribuídos pelo Operator, que especializam o indivíduo.
A evolução recalcula imediatamente os stats com base na nova forma. O APK não precisa subir novos níveis para 
começar a receber o poder da evolução.
1. Nível e experiência
1.1 Limites de nível
Nível mínimo: 1
Limite prático: 80
Hard cap: 100
Os conteúdos normais do jogo são balanceados para níveis inferiores a 80.
Os níveis 81 a 100 existem tecnicamente, mas representam uma progressão pós-limite deliberadamente inviável 
durante uma campanha convencional.
O jogo não exige que o jogador ultrapasse o nível 80 para completar qualquer conteúdo principal.
1.2 Curva de EXP entre os níveis 1 e 80
A EXP total necessária para alcançar determinado nível é:
EXP_TOTAL(Nível) = Nível³ - 1
A EXP necessária para passar do nível atual L para L + 1 é:
EXP_PRÓXIMO(L) = (L + 1)³ - L³
Forma simplificada:
EXP_PRÓXIMO(L) = 3L² + 3L + 1
Exemplos:
Progressão EXP necessária
1 2 → 7
5 6 → 91
10 11 → 331
20 21 → 1.261
30 31 → 2.791

40 41 → 4.921
50 51 → 7.651
60 61 → 10.981
70 71 → 14.911
79 80 → 18.961
A EXP total acumulada para alcançar o nível 80 é:
80³ - 1 = 511.999 EXP
Essa progressão é contínua e previsível. Cada nível exige mais EXP que o anterior, mas sem saltos abruptos antes do 
nível 80.
1.3 Barreira após o nível 80
A partir do nível 80, a curva normal deixa de ser utilizada.
A EXP necessária passa a ser:
EXP_PRÓXIMO(L) =
(3L² + 3L + 1)
× 100
× 2^(L - 80)
Exemplos:
Progressão EXP necessária
79 80 → 18.961
80 81 → 1.944.100
81 82 → 3.985.400
82 83 → 8.167.600
85 86 → 70.179.200
90 91 → 2.516.070.400
99 100 → 1.557.187.788.800
O salto entre os níveis 80 e 81 é intencional.
O nível 80 representa o ponto em que o sistema de progressão normal de NULL NETWORK deixa de funcionar de 
maneira convencional. A barreira pode ser tratada pela comunidade in-game como uma limitação misteriosa do 
servidor.

1.4 Regras gerais de EXP
Todas as linhas evolutivas usam a mesma curva de nível.
Não existem linhas com crescimento de EXP rápido ou lento.
Evoluir não altera a EXP atual.
Evoluir não altera o nível atual.
EXP excedente continua sendo contabilizada após um level up.
Uma grande recompensa pode gerar múltiplos level ups consecutivos.
Um APK no nível 100 deixa de acumular EXP.
A derrota não remove EXP já obtida.
A morte do APK encerra sua progressão permanentemente.
A quantidade de EXP entregue por cada EXE, boss, PvP ou atividade é uma camada separada de balanceamento. 
Entretanto, inimigos muito abaixo do nível do APK devem conceder EXP severamente reduzida, impedindo que áreas 
iniciais sejam usadas para atravessar a barreira do nível 80.
2. Stats dos APKs
2.1 Stats que progridem com nível
Os stats naturais utilizados pela progressão são:
HP
ATK
DEF
MATK
MDEF
Cada forma possui sua própria distribuição entre esses cinco stats.
2.2 Stability
STABILITY não é um stat que cresce com nível.
Máximo de Stability: sempre 100
Faixa possível: 0% a 100%
Todo APK, independentemente de forma, nível, Node ou linha evolutiva, possui 100 pontos máximos de Stability.
O atributo variável é:
STABILITY RECOVERY
Stability Recovery determina quantos pontos percentuais de Stability o APK recupera no início de cada ciclo.
Exemplo:
Stability atual: 37%
Stability Recovery: 20%
Início do próximo ciclo:
37% → 57%
Stability Recovery não recebe pontos manuais de level up.
Ela é determinada por:
forma atual;
linhagem intermediária;
Variant Node;
estado EXE, Purified ou DEVIL;
Modules passivos;
Status Effects;
outros modificadores sistêmicos.
Dodge, Crit e outros parâmetros percentuais também não fazem parte da distribuição manual de stats.

3. Perfil estatístico das formas
3.1 Potencial no nível 100
Cada forma possui um perfil estatístico de nível 100.
Exemplo hipotético:
NOVIRE — Perfil Natural no nível 100
HP 240
ATK 70
DEF 50
MATK 60
MDEF 55
Esse perfil representa o valor natural da forma no nível 100, antes de:
pontos manuais;
Variant Nodes;
Modules passivos;
EXE ou DEVIL;
buffs e debuffs.
Ele não representa um hard cap absoluto.
3.2 Escala numérica por nível
HP utiliza progressão proporcional:
HP_NATURAL =
arredondar(HP_100 × Nível ÷ 100)
Exemplo com HP_100 = 240:
Nível HP natural
5 12
10 24
25 60
50 120
80 192
100 240
ATK, DEF, MATK e MDEF utilizam um piso estatístico de 5:
STAT_NATURAL =
arredondar(
 5 + (STAT_100 - 5) × Nível ÷ 100
)
Exemplo com ATK_100 = 70:
Nível ATK natural

5 8
10 12
25 21
50 38
80 57
100 70
A progressão não precisa conceder +1 em todos os stats em todos os níveis.
Em determinado level up, um stat pode aumentar enquanto outro permanece igual. Os valores são sempre recalculados
pela curva, evitando erros acumulados de arredondamento.
4. Orçamento de poder das formas
4.1 Valor ponderado dos stats
Como HP utiliza uma escala numérica maior, ele possui peso diferente no orçamento total.
2 HP = 1 ponto de orçamento
1 ATK = 1 ponto
1 DEF = 1 ponto
1 MATK = 1 ponto
1 MDEF = 1 ponto
O orçamento estatístico de uma forma é:
ORÇAMENTO =
HP_100 ÷ 2
+ ATK_100
+ DEF_100
+ MATK_100
+ MDEF_100
Stability Recovery não participa desse orçamento e é balanceada separadamente.
4.2 Orçamento por estágio evolutivo
Formas pertencentes ao mesmo estágio evolutivo devem possuir aproximadamente o mesmo orçamento total.
INIT
→ orçamento de forma inicial
BALANCED / VALOUR / LOGIC / SYNC / SELF
→ orçamento de forma intermediária
XVALOUR / XLOGIC / XSYNC / XSELF / NULL
→ orçamento de forma final
Justizman não deve possuir mais poder total que Jackrider apenas por ser VALOUR.
Ele deve distribuir o mesmo orçamento de maneira diferente.
Exemplo:

JACKRIDER
→ distribuição equilibrada
JUSTIZMAN
→ ATK e DEF elevados
→ MATK menor
CALIGUNNER
→ MATK e MDEF elevados
→ ATK menor
A identidade está na distribuição, não numa quantidade total superior de stats.
5. Evolução e recalculação imediata
Quando um APK evolui, sua forma anterior deixa de determinar o corpo estatístico principal.
A nova forma recalcula imediatamente seus stats no nível atual.
Antes:
Jackrider — nível 30
Depois:
Rise Justizman — nível 30
O Rise Justizman recebe imediatamente os stats de uma forma final no nível 30.
Ele não precisa subir para o nível 31 para começar a receber a nova distribuição.
A evolução pode, portanto, produzir uma transformação significativa durante um combate:
aumento imediato de Max HP;
aumento ou redistribuição de ATK, DEF, MATK e MDEF;
nova Stability Recovery;
novos passivos;
novas capacidades;
nova função tática.
Um stat pode diminuir após a evolução caso a nova forma seja menos especializada nele.
Exemplo:
Jackrider:
MATK elevado devido à distribuição equilibrada.
Rise Justizman:
MATK menor, mas ATK e DEF muito maiores.
Evolução não significa que absolutamente todos os números aumentam. Significa que o APK passa a utilizar o corpo 
estatístico da nova forma.
6. Linhagem estatística intermediária
6.1 Definição da linhagem
A primeira forma intermediária do APK estabelece sua Growth Lineage.
Exemplos:
NOVIRE → JACKRIDER
Growth Lineage: BALANCED
NOVIRE → JUSTIZMAN
Growth Lineage: VALOUR
NOVIRE → RIVADER
Growth Lineage: SELF
NOVIRE → CALIGUNNER
Growth Lineage: LOGIC

Essa linhagem é permanente.
Mesmo que Jackrider posteriormente evolua para XSELF, XLOGIC ou XVALOUR, sua Growth Lineage continua sendo 
BALANCED.
A linhagem estatística acompanha a mesma lógica da linhagem cromática.
6.2 Influência de 25%
Ao alcançar uma forma final, a distribuição natural passa a ser composta por:
75% da distribuição da forma final atual
25% da distribuição da forma intermediária
A fórmula conceitual é:
DISTRIBUIÇÃO FINAL =
Distribuição da forma atual × 0,75
+
Distribuição da linhagem intermediária × 0,25
Os 25% não são adicionados como poder extra.
Eles substituem 25% da distribuição da forma final.
Portanto:
Orçamento total:
continua sendo o orçamento da forma final.
Distribuição:
75% forma final
25% trajetória intermediária
Isso impede que caminhos diferentes produzam quantidades totais diferentes de poder.
O caminho altera onde os pontos estão distribuídos, não quantos pontos existem.
6.3 Normalização entre estágios
A forma intermediária possui orçamento menor que uma forma final.
Por isso, seus números brutos não são copiados diretamente.
O sistema utiliza a proporção da distribuição intermediária e a reaplica sobre o orçamento da forma final.
Exemplo:
Jackrider distribui seu orçamento de maneira equilibrada.
Ao servir como linhagem de Rise Justizman:
25% do orçamento final recebe essa distribuição equilibrada.
Não é copiado o HP bruto de Jackrider. É preservada sua tendência estatística.
6.4 Exemplo comparativo
Exemplo ilustrativo de dois Rise Justizman no nível 30:
Origem HP ATK DEF MATK MDEF
Jackrider Rise Justizman → 94 45 37 24 30
Justizman Rise Justizman → 91 48 38 22 29
O primeiro indivíduo mantém uma distribuição mais equilibrada.
O segundo preserva uma especialização maior em ATK e DEF.
Ambos:
possuem o mesmo nível;
possuem a mesma forma atual;

utilizam o mesmo orçamento de forma final;
têm poder total equivalente.
Porém, eles cumprem funções ligeiramente diferentes.
Somando Modules herdados, pontos manuais, Node e passivos, a diferença se torna ainda mais expressiva.
7. Linhagem e formas NULL
7.1 Evolução direta para NULL
Quando um APK evolui diretamente de INIT para NULL:
INIT → NULL
ele não possui forma intermediária.
Nesse caso:
Distribuição natural:
100% da forma NULL
Growth Lineage:
NULL
7.2 Evolução intermediária para NULL
Quando um APK passa por uma forma intermediária antes de alcançar NULL:
INIT → JUSTIZMAN → NULL
a regra normal é mantida:
75% da distribuição NULL
25% da distribuição VALOUR
Outro indivíduo:
INIT → JACKRIDER → NULL
utiliza:
75% da distribuição NULL
25% da distribuição BALANCED
Portanto, uma forma NULL direta é estatisticamente diferente de uma forma NULL que carrega uma trajetória anterior.
8. Stability Recovery e linhagem
Stability Recovery também preserva 25% da forma intermediária.
Em uma forma final:
STABILITY RECOVERY FINAL =
arredondar(
 Recovery da forma atual × 0,75
 +
 Recovery da linhagem × 0,25
)
Exemplo:
Rise Justizman:
24% de Stability Recovery
Jackrider:
20%
Resultado:
24 × 0,75 + 20 × 0,25
= 23%
Um Rise Justizman vindo de uma forma com recuperação melhor pode preservar parte dessa característica.
A Stability máxima continua sempre sendo 100.

9. Pontos distribuídos pelo Operator
9.1 Obtenção
Cada level up concede:
1 Allocation Point
Esses pontos podem ser armazenados e distribuídos posteriormente.
Eles não precisam ser utilizados imediatamente.
9.2 Stats disponíveis
O jogador pode investir em:
HP
ATK
DEF
MATK
MDEF
Conversão:
1 ponto em HP
→ +2 Max HP
1 ponto em ATK
→ +1 ATK
1 ponto em DEF
→ +1 DEF
1 ponto em MATK
→ +1 MATK
1 ponto em MDEF
→ +1 MDEF
Não é possível investir diretamente em:
Stability máxima;
Stability Recovery;
Crit;
Dodge;
outras porcentagens especiais.
9.3 Limite de concentração
Para impedir que toda a identidade de uma forma seja apagada pela distribuição manual, no máximo metade dos 
pontos recebidos pode ser investida em um único stat.
LIMITE POR STAT =
arredondar para cima(
 total de pontos recebidos ÷ 2
)
Exemplos:
Nível Pontos recebidos Máximo no mesmo stat
10 9 5
30 29 15

50 49 25
80 79 40
100 99 50
O jogador pode construir um APK altamente especializado, mas não pode colocar todos os 99 pontos em ATK.
9.4 Persistência durante evolução
Pontos distribuídos pertencem ao indivíduo, não à forma.
Eles permanecem após qualquer evolução.
Forma anterior:
+12 ATK
+8 DEF
+4 HP
Após evoluir:
os mesmos investimentos são aplicados
sobre o novo corpo estatístico.
A evolução não redistribui automaticamente os pontos.
Eventuais métodos de respec devem existir como sistemas próprios e não como consequência normal da evolução.
10. HP durante evolução em combate
Quando a evolução aumenta o Max HP, o APK recebe imediatamente a diferença entre o Max HP antigo e o novo.
Exemplo:
Antes:
18/76 HP
Depois da evolução:
Novo Max HP = 102
Diferença:
102 - 76 = 26
Novo HP atual:
18 + 26 = 44
Resultado:
44/102 HP
A evolução não cura completamente o APK.
Ela preserva a quantidade absoluta de dano que já havia sido recebida:
Dano sofrido antes:
76 - 18 = 58
Dano sofrido depois:
102 - 44 = 58
Caso o novo Max HP seja inferior ao anterior, o HP atual é reduzido pela mesma diferença, mas um APK vivo nunca é 
derrotado exclusivamente pela recalculação da evolução. Seu HP é preservado em pelo menos 1.
10.1 Stability durante evolução
A Stability atual não é restaurada nem recalculada.
Antes:
27/100 Stability
Depois:

27/100 Stability
A nova Stability Recovery passa a ser utilizada no próximo início de ciclo.
11. Ordem final do cálculo de stats
A ordem canônica é:
1. Orçamento e distribuição da forma atual
2. Influência de 25% da linhagem intermediária
3. Escala de acordo com o nível atual
4. Pontos distribuídos pelo Operator
5. Variant Node
6. Estado Purified, EXE ou DEVIL
7. Modules passivos
8. Status Effects, buffs e debuffs
9. Limites técnicos de segurança
Fórmula conceitual:
STAT BASE =
Stat natural da forma e linhagem
+
Pontos distribuídos
Depois:
STAT EFETIVO =
STAT BASE
× modificadores de Node
× modificadores de integridade
× passivos
× efeitos temporários
Modificadores percentuais são aplicados depois dos bônus aditivos.
Exemplo de modificador de Variant Node aplicado fora da ficha de stats:
ATK base após distribuição:
100
DEFENSIVE:
o stat ATK permanece 100; o dano final causado por Modules ofensivos recebe multiplicador ×0.80.
O drawback é aplicado na etapa de resolução de dano, não como redução permanente do stat ATK/MATK.
Isso impede que o jogador neutralize o drawback distribuindo pontos depois dele.
Variant Nodes podem modificar stats ou regras finais de combate conforme sua própria definição; a ordem de cálculo 
deve respeitar a camada declarada pelo Node.
12. Fluxo de level up
Ao subir de nível:
1. O nível aumenta em 1.
2. Os stats naturais são recalculados.
3. A diferença entre o nível anterior e o novo é aplicada.
4. O APK recebe 1 Allocation Point.
5. Modules ou capacidades vinculados ao nível são liberados.
6. Condições de evolução são verificadas.
Caso uma evolução aconteça:
1. A nova forma substitui o corpo estatístico anterior.
2. A Growth Lineage é preservada ou estabelecida.

3. O orçamento da nova forma é aplicado.
4. A distribuição final é recalculada.
5. Pontos manuais são reaplicados.
6. Max HP e HP atual são ajustados.
7. Stability atual é mantida.
8. Stability Recovery é atualizada.
9. Passivos e capacidades da nova forma entram em funcionamento.
13. Princípios de balanceamento
O sistema deve respeitar permanentemente estas regras:
A forma atual sempre representa a maior parte da identidade estatística.
A forma intermediária representa 25% da distribuição final.
A linhagem não acrescenta poder total; ela redistribui poder.
Formas do mesmo estágio possuem orçamentos equivalentes.
Evoluir produz um aumento imediato e significativo.
O jogador pode especializar o APK, mas não apagar completamente sua natureza.
Stability permanece sempre limitada a 100.
Stability Recovery é tratada separadamente dos stats tradicionais.
Não existem IVs, EVs, Naturezas ou diferenças genéticas ocultas.
Dois APKs com a mesma forma e nível só diferem por razões visíveis e rastreáveis.
Essas razões podem ser consultadas no Profile:
Forma atual
Linhagem intermediária
Nível
Pontos distribuídos
Variant Node
Estado de integridade
Modules passivos
Histórico evolutivo
Resumo canônico
LEVEL
→ define quanto do potencial já foi alcançado.
FORMA ATUAL
→ define o orçamento e 75% da distribuição final.
LINHAGEM INTERMEDIÁRIA
→ define 25% da distribuição final.
PONTOS DO OPERATOR
→ especializam o indivíduo.
NODE E PASSIVOS
→ modificam o resultado final.
EVOLUÇÃO
→ recalcula imediatamente todo o corpo estatístico.
STABILITY
→ máximo fixo de 100.
STABILITY RECOVERY
→ porcentagem recuperada no início de cada ciclo.
NÍVEL 80

→ limite prático.
NÍVEL 100
→ hard cap tecnicamente existente, mas virtualmente inalcançável.
O resultado é que dois Rise Justizman podem possuir o mesmo nível e o mesmo poder estatístico total, mas ainda 
apresentar distribuições, repertórios e funções distintas conforme o caminho que percorreram.
6.6 Resources de APK e evolução
Sistema de Evolução de APKs
As criaturas do jogo são definidas por APKData.tres.
Esse arquivo contém:
nome da espécie
status base
módulos disponíveis
sprite
Além disso, ele possui uma lista de EvolutionBranch.tres.
Cada branch define uma possível evolução, baseada nas tendências do protagonista.
Exemplo:
Se level >= 15 e LOGIC > VALOUR, SELF, SYNC → evolui para APK X
Se derrotado em batalha quando LOGIC > 50 > VALOUR, SELF, SYNC → evolui para APK Y
Isso permite que o mesmo APK tenha múltiplos caminhos evolutivos dependendo das decisões do jogador.

7. COMBATE, TIMELINE E PLAYER ACTIONS
7.1 Regras base do combate
COMBATE
O combate é diferente de um RPG comum. Não existem ações genéricas como "Attack", mas sim "Modules". Modules 
são como "equips" que um APK pode equipar a cada ciclo de combate. Esses Modules podem representar tanto ações 
físicas (causar dano) quanto ações de suporte (se curar, se buffar, debuffar o inimigo, defender ataques).
O APK possui 4 slots de Modules que pode equipar a cada turno, assim como um stat chamado STABILITY. STABILITY
é o recurso consumido para que um módulo seja ativável, como o MP de um jogo de RPG comum. É recuperado 
parcialmente a cada ciclo. Se chegar a ZERO, o APK sofre de UNSTABILITY, tomando o dobro do dano no próximo 
ciclo.
Um ciclo é composto por 8 "ações": 4 ativações de modules do jogador, e 4 ativações de modules do inimigo. Sempre 
intercalado e em ordem fixa.
[MODULE 1 DO JOGADOR]
[MODULE 1 DO INIMIGO]
[MODULE 2 DO JOGADOR]
[MODULE 2 DO INIMIGO]
[MODULE 3 DO JOGADOR]
[MODULE 3 DO INIMIGO]
[MODULE 4 DO JOGADOR]
[MODULE 4 DO INIMIGO]
O jogador poderá ver quais são os Modules que o inimigo irá utilizar no ciclo atual, para estrategizar adequadamente.
Fluxo:
O jogador escolhe entre Execute Cycle, Change Modules ou Run Away.
Com Change Modules, o jogador reorganiza os 4 Cycle Slots usando apenas Active Modules presentes no Combat 
Loadout preparado antes do encontro. Não há custo de ação, sendo um recurso estratégico. Change Modules nunca 
abre a Module Collection completa durante a luta.
Com Execute Cycle, o ciclo do turno é executado em uma sequência direta, quase como um Balatro, com efeitos visuais
marcantes, números pulsando na tela cada vez maiores a cada módulo consequente do ciclo, os APKs glitchando ao 
serem atingidos, sons satisfatórios a cada combo, a janela de combate tremendo a cada ataque crítico... por aí vai.
Run Away é uma ação do Operator e não depende mais do stat DODGE do APK. Em encontros comuns, EXEs que 
aceitam o disengage permitem fuga direta; criaturas que insistem em continuar o confronto podem iniciar um Escape 
Interaction, descrito em 7.6. Em Data Centers, Run Away é indisponível por regra da própria run; a saída depende de 
EXIT Nodes/Eventos ou de resolução autoral. Em PVP contra outro Operator, Run Away é sempre garantido. Em 
combate voluntário independente, uma fuga bem-sucedida aborta o encontro, não consome o período pendente e 
descarta EXP, drops, Modules, recompensas de Player Actions e alterações ecológicas persistentes daquele encontro. 
Se uma fuga contestada falhar, o combate continua e o período permanece pendente.
Player Actions não são uma escolha pós-combate: SCAN, PURGE, PURIFY e TAME são executadas durante a luta por 
investimento de slots, conforme 7.3. A resolução formal do encontro apenas confirma ou descarta recompensas e 
alterações que ficaram pendentes.
TAME é a exceção que, ao chegar a 100%, abre uma Interaction Sequence própria antes de o vínculo ser aceito; 100% 
representa acesso à tentativa de vínculo, não sucesso automático.
É possível haver mais de dois integrantes em combate, num máximo de 4v4.
Isso muda apenas a quantidade de oponentes presentes em cena, mas não muda a quantidade de ações presentes em
um ciclo. No lugar, cada integrante do combate ocupa um slot de Module diferente.
Em um 2v2, por exemplo, a ordem é:
[MODULE 1 DO JOGADOR 1]
[MODULE 1 DO INIMIGO 1]
[MODULE 2 DO JOGADOR 2]
[MODULE 2 DO INIMIGO 2]
[MODULE 3 DO JOGADOR 1]

[MODULE 3 DO INIMIGO 1]
[MODULE 4 DO JOGADOR 2]
[MODULE 4 DO INIMIGO 2]
Visualmente, a tela de combate apresenta os inimigos no canto superior-centro, com seus ícones, HP e Stability, e o 
APK do player/aliados no canto inferior-centro. Entre os dois fica a Timeline com a ordem das ativações. Change 
Modules abre os 4 Cycle Slots e permite substituí-los apenas por Active Modules do Combat Loadout atual. A Collection
global não aparece como fonte equipável durante combate; Favorites e filtros pertencem à preparação fora da luta.
Inimigos possuirão uma "pool" de Modules próprios que é mais variada conforme seu nível for mais avançado. Eles 
selecionarão Modules de maneira aleatória, com porcentagens fixas de escolhas dependendo de qual inimigo se trata. 
NPCs e bosses serão um pouco mais inteligentes, possuindo comportamentos que dependem da situação do combate: 
Se tiverem Modules de cura enquanto seu HP ou o HP do aliado estiver baixo, o curam; se o oponente estiver com HP 
alto, aplicam debuff; se forem focados em suporte, aplicam buff e cura; caso contrário, ou caso o aliado esteja com HP 
cheio ou já buffado, atacam.
7.2 Puzzle tático posicional e arquitetura de combate
O Paradigma Central
O nosso sistema de combate não é um RPG de turnos tradicional; ele funciona como um Puzzle Tático Posicional. É um
auto-battler onde o jogador não escolhe manualmente os alvos em um menu. Toda a inteligência de combate, tanto 
para atacar quanto para curar, é puramente geográfica, baseada em um Grid fixo de 1x4 (uma linha de 4 posições para 
cada equipe). O engajamento do jogador está em reorganizar a sua equipe antes de cada ciclo ser executado, 
prevendo as ações na Linha do Tempo (Timeline).
A Base de Dados (Os Arquivos .tres)
Antes de qualquer combate começar, o sistema exige que as peças existam fisicamente no banco de dados do Godot. 
Isso é feito através de uma cadeia de Recursos (Resources):
Modules (ModuleData.tres): As habilidades do jogo. Definem se a ação é um Ataque ou Suporte, o tipo de alvo 
("SingleEnemy", "Ally", "Self"), o custo de Estabilidade (STB), o atributo de escala, o poder base e os Efeitos de Status 
aplicados (Buffs/Debuffs).
Personagens/APKs (CharacterLoadout.tres): Representam os aliados ou inimigos. Guardam os atributos de combate e 
o conjunto preparado para o encontro. Para o jogador, a Module Collection permanente é conceitualmente separada do 
Combat Loadout; apenas o loadout limitado por Module Capacity alimenta os 4 Cycle Slots durante a batalha. A 
implementação final deve alinhar essa separação às Resources existentes sem duplicar fonte de verdade.
Encontros (CombatEncounter.tres): É a "fotografia" do início de uma luta. Contém dois Arrays de tamanho 4 (Aliados e 
Inimigos), definindo exatamente quem começa em qual slot do Grid.
Mapa e fauna (SpawnTable.tres e MapLocation.tres): MapLocation representa o distrito/subárea explorada e referencia 
SpawnTables condicionais. Para exploração ambiental, essas tabelas definem quais EXEs/variantes podem se projetar 
e com quais pesos; elas não sorteiam diretamente uma formação completa. Formações fechadas e encontros autorais 
continuam usando o contrato de CombatEncounter esperado pelo sistema de combate.
O Cérebro do Combate (combat_manager.gd)
Este é o Autoload (script global) que governa as regras matemáticas do jogo, isolado da interface visual. Quando um 
combate é invocado, o Manager recebe o CombatEncounter e aloca as entidades em dois Arrays fixos de tamanho 4 
(ally_team e enemy_team). Espaços vazios no grid são representados simplesmente como valores null.
Para evitar que inimigos idênticos (clones) causem conflitos lógicos, o Manager atribui um Identificador Único (uid) 
gerado aleatoriamente para cada participante assim que eles entram na arena.
A Regra de Targeting: Nenhum personagem tem "livre arbítrio". O alvo é ditado pelo seu índice no Array:
Ataque: com 4 inimigos presentes, o personagem no Slot X aliado atinge o Slot X inimigo. Quando há menos de 4 
inimigos, essa regra é substituída pelas regras adaptativas de SingleEnemy descritas logo abaixo (proximidade, 
metades e foco total).
Suporte: O personagem no Slot X mira no aliado do Slot X+1. Se estiver no último slot, a matemática modular (% 4) faz 
o alvo "dar a volta" e focar no Slot 0, criando um loop fechado.
A Montagem da Timeline: O Manager avalia quem está vivo e dá prioridade absoluta a quem domina o "Centro" do grid 
(o Slot 2, índice 1). Em uma equipe de 3 personagens, quem estiver no centro recebe duas ações no ciclo, e os aliados 
das pontas recebem uma. Os módulos extraídos para a Timeline dependem dessa ordem.

Desfragmentação Inimiga (O "Slide"): Os inimigos detestam buracos na sua formação. No fim de cada ciclo, o Manager 
ativa a gravidade posicional: se o inimigo do Slot 2 morrer, os inimigos vivos escorregam (mudam o seu índice no array)
seguindo uma ordem de atração para o centro, alterando toda a matemática de alvos para o próximo turno do jogador.
A Interface e UX (app_combat.gd e character_slot_ui.gd)
A interface visual é inteiramente desenhada via código (Generative UI) baseada no estado do CombatManager.
O character_slot_ui.gd é a alma da experiência do usuário. Ele representa um "Cubo" do personagem. Se o slot no 
Autoload for null, ele desenha uma caixa translúcida (Affordance) indicando que o espaço está disponível. Se houver 
um personagem, ele desenha o ícone e as barras de HP e STB.
Drag & Drop: O jogador manipula o Grid clicando e arrastando o cubo de um aliado. Durante o arrasto, um fantasma 
holográfico acompanha o mouse. Ao soltar sobre um slot vazio, o personagem se move para lá; ao soltar sobre outro 
aliado, eles trocam de posição (Swap). A cada movimento, a UI avisa o CombatManager, que altera o Array e reconstrói
a Timeline instantaneamente.
Ghost HP (Feedback Preditivo): Ao passar o mouse sobre as ações geradas na Timeline, o sistema envia um sinal 
visual. O Cubo cujo uid for o alvo daquele ataque piscará, e a sua barra de HP ficará laranja, simulando uma subtração 
matemática da Defesa contra o Dano do Módulo. Isso mostra exatamente quanto de HP vai sobrar antes mesmo de o 
jogador apertar em "Executar".
O Ciclo de Jogo (O Fluxo Real)
O ciclo completo acontece da seguinte forma:
A Exploração: o jogador abre o Navigator, escolhe um local e entra no Overworld Local. EXEs são visíveis no mapa 
conforme os dados de spawn/ecologia. O jogador pode observar, evitar, perseguir ou entrar em contato com um EXE. 
Não existe um “Scan de exploração” que sorteia imediatamente uma batalha; SCAN continua sendo exclusivamente a 
Player Action de combate.
A Transição: ao ocorrer contato, a Combat Call consulta EXEs próximos e fecha uma formação de até quatro inimigos 
conforme as regras do Capítulo 9. Depois disso, o Navigator esconde a interface de exploração, instancia a cena de 
combate e entrega ao CombatManager a formação/encontro já resolvido pelo sistema de mundo ou pelo StoryEvent 
autoral.
O Planejamento: O jogador analisa a Timeline gerada automaticamente, passa o mouse para prever os danos e faz o 
Drag & Drop dos seus personagens para evitar golpes fatais ou alinhar combos.
A Execução: O jogador clica em "Execute Cycle". A UI entra em bloqueio. O Manager processa as ações: gasta 
Estabilidade, aplica Efeitos de Status (que podem buffar a Defesa para atenuar danos futuros no mesmo turno) e causa 
danos, emitindo sinais que a UI traduz como animações de "MISS", "BLOCKED" ou números vermelhos de HP perdido.
A Limpeza e a Resolução: no fim das ações do ciclo, durações de buffs são atualizadas, inimigos vivos podem se 
reposicionar e a Timeline é reconstruída. Quando todos os inimigos chegam a 0 HP ou são removidos por uma Player 
Action válida, o loop termina e o sistema aplica o resultado correspondente de SCAN/PURGE/PURIFY/TAME/derrota 
normal, entrega recompensas e retorna ao Navigator.
O Fim: Ao escolher o loot, a cena de combate se destrói completamente (queue_free), liberando a memória RAM, e o 
Navigator volta a exibir a tela de Exploração.
Este sistema une código limpo através de injeção de dependências, design orientado a dados via Resources, e uma 
camada de Game Feel focada em transparência de informações e usabilidade (UX).
Módulo de Regra: Comportamento de Módulos do tipo SingleEnemy.
O sistema de miras do jogo não requer seleção manual. Quando um personagem utiliza um Módulo de ataque 
configurado como SingleEnemy, o sistema calcula matematicamente o alvo com base no estado atual da formação 
inimiga (o Grid 1x4). A mira é puramente posicional e adapta-se dinamicamente à quantidade de inimigos vivos em 
campo, seguindo as 4 diretrizes abaixo:
 Cenário A: 4 Inimigos Presentes (Formação Completa)
 Regra do Espelhamento: O targeting é estritamente linear e paralelo. O atacante foca no inimigo que está 
exatamente na sua mesma coluna (mesmo índice).
 Exemplo: O Aliado no Slot 3 atacará sempre o Inimigo no Slot 3.
 Cenário B: 3 Inimigos Presentes (Formação Quebrada)
 Regra da Proximidade: O targeting busca o inimigo posicionado na coluna geograficamente mais próxima ao 
atacante. O sistema calcula a distância de "índices" entre o atacante e os alvos disponíveis, priorizando a menor 
distância.
 Cenário C: 2 Inimigos Presentes (Formação Dividida)

 Regra das Metades (Zonas de Ameaça): O campo de batalha é conceitualmente dividido ao meio. A prioridade de 
mira é definida pela zona em que o atacante se encontra:
 Atacantes posicionados na Metade Esquerda (Slots 1 e 2) focarão obrigatoriamente no primeiro inimigo 
disponível (o inimigo posicionado mais à esquerda no grid inimigo).
 Atacantes posicionados na Metade Direita (Slots 3 e 4) focarão obrigatoriamente no segundo inimigo disponível 
(o inimigo posicionado mais à direita no grid inimigo).
 Cenário D: 1 Inimigo Presente (Alvo Único / Boss)
 Regra do Foco Total (Global Aggro): A posição do atacante deixa de importar. Todos os membros da equipe irão 
mirar e concentrar fogo no único inimigo restante em campo.
Nota de Design (Interação com o Slide Inimigo):
Como o nosso sistema possui a regra de "Desfragmentação" (onde os inimigos escorregam para o centro quando há 
buracos), essas regras de mira garantem que o jogador possa prever exatamente quem vai apanhar em cada turno, 
permitindo que ele posicione seus APKs nos Slots corretos para focar dano em um inimigo específico ou distribuir o 
dano pelas beiradas.
Sistema de Combate Modular
Os combates do jogo são definidos por dados e não por código fixo.
Cada combate é definido por um CombatEncounter.tres, que especifica quais personagens participam da batalha.
Um combate pode ter até:
4 aliados
4 inimigos
Cada personagem presente na batalha carrega um CharacterLoadout.tres, que define:
seus status
quais Módulos ele possui
seu padrão de IA (caso seja inimigo)
Os ataques e habilidades são definidos por ModuleData.tres.
Um módulo representa uma ação que pode ser usada em combate, contendo:
nome
tipo
poder
custo de Stability
alvo
efeitos adicionais
Cada personagem possui vários módulos equipados, mas durante o combate ele utiliza apenas quatro módulos por 
ciclo.
Para inimigos, a ordem de uso desses módulos é definida em um padrão de IA, que indica qual módulo será usado em 
cada turno do ciclo.
Isso permite criar comportamentos diferentes para inimigos apenas alterando os dados do loadout.
7.3 Player Actions — sistema canônico
Sistema de Player Actions
Visão geral
Player Actions são comandos executados diretamente pelo jogador durante o combate, separados dos módulos 
utilizados pelo APK parceiro. Enquanto os módulos representam ações do APK dentro da batalha, Player Actions 
representam a interferência direta do Operator sobre o EXE inimigo.
Esse sistema existe para transformar o destino dos EXEs em uma decisão ativa de gameplay. O jogador não apenas 
derrota inimigos para receber experiência: ele pode analisar, extrair, purificar ou tentar manipular a condição do EXE de 
formas diferentes, alterando recompensas, tendências e consequências narrativas.
As Player Actions principais são:
SCAN

PURGE
PURIFY
TAME
Cada uma representa uma postura diferente do jogador diante de uma entidade exezada.
Relação com os slots de módulo
Durante o combate, o APK do jogador normalmente executa módulos em sequência. Cada ciclo de combate possui um 
número limitado de espaços de ação, chamados aqui de slots de módulo.
Em vez de utilizar um módulo em um slot, o jogador pode dedicar aquele slot a uma Player Action.
Cada slot investido em uma Player Action aumenta o progresso daquela ação em 25% no alvo escolhido. Ao atingir 
100%, a ação é concluída e seu efeito é aplicado.
Exemplo:
Slot 1: Ataque
Slot 2: SCAN em RATTUS.exe (+25%)
Slot 3: Defesa
Slot 4: SCAN em RATTUS.exe (+25%)
Nesse caso, o jogador executou dois módulos normalmente e dedicou metade do ciclo a avançar o SCAN em um 
inimigo específico. O SCAN daquele alvo ficaria em 50%.
O jogador pode escolher investir apenas um slot por ciclo, avançando lentamente uma ação, ou dedicar todos os slots 
de um ciclo para concluir uma Player Action imediatamente.
Exemplo:
Slot 1: PURIFY (+25%)
Slot 2: PURIFY (+25%)
Slot 3: PURIFY (+25%)
Slot 4: PURIFY (+25%)
Nesse caso, PURIFY chega a 100% no mesmo ciclo, mas o jogador abre mão de todos os módulos daquele turno.
Intenção de design
O objetivo do sistema é criar uma escolha de ritmo e risco.
Usar Player Actions não consome um recurso externo como mana, energia ou moeda especial. O custo está no próprio 
fluxo do combate: cada slot dedicado a uma Player Action é um slot que não foi usado para atacar, defender, curar, 
aplicar status ou executar combos.
Assim, o jogador precisa decidir quando vale a pena abrir mão de pressão ofensiva ou defensiva para tentar obter uma 
recompensa melhor ou alterar o destino de um EXE.
A intenção é que o jogador raramente pense apenas:
“Vou só matar e pronto.”
Em vez disso, o ideal é que cada inimigo gere uma pequena decisão:
“Vale a pena escanear esse EXE?”
“Eu quero purgar para extrair algo à força?”
“Eu tento purificar para obter uma recompensa estável?”
“Eu só preciso sobreviver e encerrar a luta?”
Matar normalmente continua sendo uma opção válida e segura, mas SCAN, PURGE e PURIFY oferecem recompensas 
mais específicas para jogadores dispostos a gastar tempo e se expor durante o combate.
Progresso por alvo
O progresso de Player Actions é registrado por alvo.
Isso significa que usar SCAN, PURGE ou PURIFY em um inimigo não avança automaticamente a mesma ação em 
outros inimigos. O jogador precisa escolher em qual EXE deseja investir.
Exemplo:
RATTUS.exe A
SCAN: 50%

RATTUS.exe B
SCAN: 0%
Mesmo que os inimigos sejam da mesma espécie, cada um possui seu próprio progresso dentro daquele combate.
Esse sistema permite que batalhas com múltiplos inimigos tenham decisões diferentes para cada alvo. O jogador pode 
purificar um EXE, purgar outro e simplesmente derrotar os demais.
Commit de recompensas e fuga
Resultados persistentes obtidos dentro de um combate voluntário independente são tratados como pendentes até a 
resolução formal do encontro. Isso inclui EXP, drops, Modules, alterações de Tendência geradas por Player Actions e 
alterações ecológicas que seriam gravadas no estado permanente do mundo.
Se Run Away for bem-sucedido, esses resultados pendentes são descartados. Informações e progresso temporário 
usados apenas dentro daquela luta não se convertem em recompensa persistente. Essa regra impede que o jogador 
use SCAN, PURIFY, PURGE ou outras ações de recompensa e depois fuja para evitar o custo temporal do combate.
SCAN
SCAN é a Player Action associada à análise, observação e compreensão do inimigo.
Ao completar SCAN em 100%, o jogador obtém informações detalhadas sobre o EXE alvejado e pode escolher um 
módulo específico que aquele EXE possui. A aquisição escolhida fica pendente até a resolução formal do combate.
SCAN representa uma abordagem mais lógica e técnica. Por isso, sua conclusão contribui para a tendência LOGIC.
Efeito principal
Ao completar SCAN:
- O jogador revela dados do EXE alvo.
- O jogador escolhe um módulo específico possuído por aquele EXE.
- O módulo escolhido é registrado como recompensa pendente e só é adicionado ao inventário quando o combate é 
formalmente resolvido.
- Caso o jogador já possua esse módulo, a recompensa pendente é convertida em experiência extra na resolução 
formal do combate.
- O ganho de tendência LOGIC é registrado como pendente e só é aplicado na resolução formal do combate.
Limite
SCAN pode ser concluído apenas uma vez por alvo em cada combate.
Cada EXE individual possui seu próprio limite de SCAN. Em um combate com quatro inimigos, o jogador pode concluir 
até quatro SCANs, um em cada alvo, desde que invista os slots necessários. O mesmo alvo não pode ser escaneado 
duas vezes no mesmo combate. Essa regra acompanha a natureza emergente da Combat Call: receber mais inimigos 
aumenta simultaneamente o risco da luta e a quantidade potencial de alvos úteis para análise.
Identidade de gameplay
SCAN é a opção para o jogador que quer controle e informação.
Ele não é uma ação agressiva nem purificadora. Seu foco é entender o inimigo e extrair exatamente o recurso 
desejado.
Resumo:
SCAN = precisão, informação e escolha.
Tendência associada: LOGIC.
Recompensa: módulo específico escolhido.
PURGE
PURGE é a Player Action associada à extração forçada e à eliminação agressiva da condição EXE.
PURGE não causa dano direto, não aplica stun e não torna o inimigo mais fácil de derrotar. Seu objetivo não é alterar o 
curso imediato do combate, mas sim modificar a recompensa recebida caso aquele inimigo seja derrotado.
Ao completar PURGE em 100%, o alvo é marcado para purga. Quando esse EXE for derrotado, o multiplicador de 3× 
EXP e a remoção de 1 Population Unit ficam registrados como resultados pendentes. Eles só são confirmados quando 
o encontro é formalmente resolvido. PURGE não concede Module nem item.

PURGE representa uma abordagem egoísta, exploratória e black hat. Por isso, sua conclusão contribui para a 
tendência SELF.
Efeito principal
Ao completar PURGE em um alvo:
- O EXE é marcado como purgado.
- PURIFY e TAME ficam bloqueados para aquele alvo.
- Quando o alvo for derrotado, o multiplicador de 3× sobre a EXP ajustada fica registrado como recompensa pendente.
- A remoção de 1 Population Unit da espécie fica registrada como alteração ecológica pendente e só é aplicada na 
resolução formal do encontro.
- PURGE não concede Active Module, Installed Passive nem item.
- O ganho de tendência SELF é registrado como pendente e só é aplicado na resolução formal do combate.
Limite
PURGE pode ser concluído uma vez por inimigo.
Em combates com múltiplos inimigos, o jogador pode tentar purgar vários alvos, mas cada tentativa exige investimento 
de slots. Isso cria um risco natural: quanto mais o jogador tenta maximizar recompensas, menos ações de combate ele 
utiliza durante a luta.
Identidade de gameplay
PURGE é a opção de alto risco e alta recompensa.
O jogador não ganha vantagem direta no combate. Ele precisa gastar slots para marcar o alvo e ainda precisa derrotá￾lo depois. Se conseguir, recebe exatamente 3× a EXP ajustada daquele EXE, mas reduz a população local e perde 
oportunidades futuras associadas àquela unidade.
Resumo:
PURGE = extração agressiva, ganho bruto e risco.
Tendência associada: SELF.
Recompensa: 3× EXP após penalidade de nível; sem Modules/itens; remove 1 Population Unit.
PURIFY
PURIFY é a Player Action associada à estabilização da condição EXE.
Enquanto PURGE extrai algo do inimigo à força, PURIFY tenta converter a condição corrompida do EXE em algo 
estável. O jogador não está destruindo ou explorando o inimigo, mas tentando recuperar sua estrutura para que ela 
possa ser integrada corretamente.
Ao completar PURIFY em 100%, o jogador prepara a recompensa de módulo passivo específica daquele EXE. Caso 
esse passivo já tenha sido obtido, o sistema tenta selecionar outro módulo passivo relacionado ao mesmo EXE, família, 
tipo ou área. Se não houver opções válidas, a recompensa é convertida em experiência extra. A recompensa e seus 
efeitos persistentes só são confirmados na resolução formal do combate; Run Away bem-sucedido os descarta.
PURIFY representa empatia, conexão e estabilização. Por isso, sua conclusão contribui para a tendência SYNC.
Efeito principal
Ao completar PURIFY em um alvo:
- O EXE é marcado como estabilizado/purificado dentro do encontro; qualquer efeito persistente é confirmado somente 
na resolução formal.
- PURGE fica bloqueado para aquele alvo durante o encontro.
- A experiência normal do EXE fica pendente até a resolução formal do combate.
- O módulo passivo específico daquele EXE fica registrado como recompensa pendente até a resolução formal do 
combate.
- Caso já possua esse passivo, recebe outro passivo relacionado ao EXE, família, tipo ou área.
- Caso não exista uma opção válida de passivo, a recompensa é convertida em experiência extra.
- O ganho de tendência SYNC é registrado como pendente e só é aplicado na resolução formal do combate.
Limite
PURIFY pode ser concluído uma vez por inimigo.

Isso permite que o jogador tente purificar múltiplos inimigos em uma mesma batalha, mas cada purificação exige 
investimento de slots e reduz a quantidade de módulos usados durante o combate.
Identidade de gameplay
PURIFY é a opção de recompensa estável.
Ela não oferece o multiplicador de 3× EXP de PURGE, mas garante uma recompensa limpa e específica: um módulo 
passivo relacionado ao EXE, além do efeito ecológico positivo documentado no Capítulo 9.
Resumo:
PURIFY = estabilização, integração e recompensa passiva.
Tendência associada: SYNC.
Recompensa: módulo passivo específico ou relacionado.
TAME
TAME é uma Player Action especial ligada à tentativa de domar diretamente um APK. Para receber uma criatura 
“normal”, é necessário conduzir PURIFY antes de TAME.
Diferente de PURIFY, TAME não transforma o EXE em uma entidade limpa antes de estabelecer vínculo. Quando 
usado sem purificação prévia, TAME é considerado uma ação ilegal: o jogador tenta forçar um vínculo com uma 
entidade ainda exezada.
Isso não gera um APK normal, mas sim um parceiro quebrado, instável ou permanentemente marcado pela condição 
EXE.
TAME deve ser tratado como uma ação de risco elevado, com consequências sistêmicas e narrativas maiores do que 
SCAN, PURGE ou PURIFY.
Efeito conceitual
Ao completar TAME em um EXE não purificado:
- O jogador tenta estabelecer um vínculo direto com o EXE.
- Em caso de sucesso, o alvo não se torna um APK limpo.
- O alvo permanece EXE e se torna o novo parceiro vinculado ao Operator.
- O parceiro anterior é substituído/abandonado conforme a regra permanente de TAME; não existe etapa posterior de 
confirmação de “candidato”.
- O novo parceiro preserva Variant Node/SHN quando aplicável e recebe o EXE Partner Trait, com as consequências 
sistêmicas descritas no Capítulo 8.
Identidade de gameplay
TAME sem PURIFY representa uma forma de quebrar as regras do sistema.
O jogador não está salvando o EXE nem apenas extraindo recursos dele. Ele está tentando usar algo corrompido como 
se fosse um parceiro válido.
Resumo:
TAME = vínculo ilegal com um EXE ainda corrompido.
Tendência associada: indefinida ou contextual.
Recompensa: novo parceiro EXE vinculado diretamente ao Operator, substituindo o parceiro anterior.
Matar normalmente
Derrotar um EXE sem concluir SCAN, PURGE, PURIFY ou TAME continua sendo uma opção válida.
Quando o HP do EXE chega a 0 sem uma Player Action especial concluída, o inimigo é fragmentado normalmente. O 
jogador recebe experiência padrão e possíveis recompensas comuns.
Essa opção representa pragmatismo e sobrevivência. Ela não oferece a precisão de SCAN, o ganho agressivo de 
PURGE ou a recompensa estável de PURIFY, mas também não exige que o jogador sacrifique slots de módulo durante 
o combate.
Resumo:
Matar normalmente = seguro, direto e sem compromisso.
Recompensa: experiência normal e drops comuns.

Comparação geral
SCAN
Custo: slots de módulo.
Limite: uma vez por alvo em cada combate.
Tendência: LOGIC.
Recompensa: módulo específico escolhido do EXE.
PURGE
Custo: slots de módulo.
Limite: uma vez por inimigo.
Tendência: SELF.
Recompensa: 3× EXP após penalidade de nível; sem Modules/itens; remove 1 Population Unit.
PURIFY
Custo: slots de módulo.
Limite: uma vez por inimigo.
Tendência: SYNC.
Recompensa: módulo passivo específico ou relacionado.
TAME
Custo: slots de módulo.
Limite: especial/contextual.
Tendência: indefinida ou contextual.
Recompensa: novo parceiro no lugar do antigo.
DERROTAR NORMALMENTE
Custo: nenhum slot extra além do combate normal.
Tendência: neutra ou contextual.
Recompensa: experiência normal.
Papel das tendências
Player Actions também funcionam como expressão das tendências do jogador.
Cada ação comunica uma forma de lidar com o mundo de NULL NETWORK:
LOGIC
O jogador entende, analisa e extrai com precisão.
SELF
O jogador força, explora e maximiza ganho próprio.
SYNC
O jogador estabiliza, recupera e integra.
VALOUR
Ainda sem Player Action definida neste sistema.
A ausência temporária de uma Player Action associada a VALOUR deve ser tratada como uma lacuna de design em 
aberto.
Por enquanto, VALOUR pode continuar sendo influenciada por outras decisões de combate, escolhas narrativas ou 
ações específicas fora do sistema de Player Actions.
Objetivo final do sistema
O sistema de Player Actions existe para fazer com que cada combate tenha mais camadas do que simplesmente 
reduzir o HP dos inimigos a 0.
Cada EXE deve representar uma oportunidade de decisão:
Analisar para obter controle?
Purgar para obter ganho bruto?
Purificar para obter uma recompensa estável?

Tentar domar ilegalmente?
Ou simplesmente derrotar e seguir em frente?
Com isso, o combate passa a refletir diretamente a identidade do jogador. A forma como ele lida com EXEs não é 
apenas uma escolha mecânica, mas também uma expressão de comportamento dentro do mundo de NULL 
NETWORK.
[DEPRECATED] CONSUME não pertence ao conjunto canônico atual de Player Actions/resolução. As descrições 
antigas foram mantidas somente no Capítulo 14 para rastreabilidade. O papel de extração agressiva/ganho bruto é 
atualmente exercido por PURGE; derrotar normalmente continua uma saída neutra/contextual.

7.4 MODULE CAPACITY — COLLECTION, COMBAT LOADOUT E CYCLE 
SLOTS
Visão geral
O Operator pode aprender uma quantidade muito grande de Active Modules ao longo da campanha, especialmente 
através de SCAN. Esse crescimento não significa que todos os Modules conhecidos ficam disponíveis durante qualquer 
combate.
O sistema separa três camadas:
MODULE COLLECTION — todos os Active Modules permanentemente conhecidos/desbloqueados pelo Operator.
COMBAT LOADOUT — subconjunto preparado antes do encontro e limitado por Module Capacity.
CYCLE SLOTS — os 4 Modules que serão executados/programados no ciclo atual.
A Module Collection pode crescer para dezenas ou centenas de Modules. O Combat Loadout permanece pequeno o 
suficiente para preservar especialização de build e legibilidade. Os Cycle Slots continuam sendo exatamente 4; Module 
Capacity nunca aumenta a quantidade de ativações de um ciclo.
Regra de acesso durante combate
Durante combate, Change Modules acessa somente o Combat Loadout. O jogador pode reorganizar livremente quais 4 
Modules preparados ocupam os Cycle Slots, mas não pode buscar uma resposta nova dentro da Collection global 
depois que o encontro começou.
Fora de combate, o Profile/Module interface permite consultar toda a Collection, usar Favorites/filtros e montar o 
Combat Loadout. Favorites é somente uma ferramenta de UX; não altera Capacity nem concede acesso especial 
durante combate.
Active Module Capacity e Passive Slots são sistemas independentes. Passive Modules não ocupam Module Capacity e 
continuam obedecendo às regras do Capítulo 8.
Progressão da Capacity
Cada APK possui uma Module Capacity base. A Capacity cresce lentamente por milestones de progressão/nível, e não 
em proporção direta ao tamanho da Collection.
O Operator pode investir Allocation Points para obter uma quantidade limitada de slots adicionais de Capacity. Module 
Capacity não funciona como um sexto stat infinitamente alocável: o custo por slot é superior ao de uma unidade comum 
de stat e existe um hard cap de expansão manual.
[OPEN] Capacity inicial, milestones, Capacity natural máxima, custo exato em Allocation Points e quantidade máxima de
slots adquiríveis manualmente ainda precisam ser balanceados. A regra fechada é que o investimento manual é 
limitado e nunca permite anular o próprio sistema carregando toda a Collection.
Função de design
Module Capacity transforma SCAN em crescimento horizontal de possibilidades, não em acesso universal a respostas. 
Aprender um Module novo passa a significar “nova opção para construir uma build”, não “nova ferramenta sempre 
disponível em toda luta”.
A estrutura de decisão é:
LONG TERM — o que eu aprendi? → Module Collection.
PREPARATION — o que eu trouxe? → Combat Loadout.
TACTICAL — o que eu executo agora? → 4 Cycle Slots.
Essa separação também torna Recovery de INCAPACITATED uma decisão de preparação: conhecer um Recovery 
Module não ajuda se ele não foi levado no Combat Loadout atual.
7.5 INCAPACITATED — DERROTA, EMERGENCY WINDOW E MORTE
Visão geral
APKs vinculados a Operators possuem um estado intermediário entre estar operacional e morrer: INCAPACITATED. A 
regra existe para separar derrota de Partner Loss e garantir uma janela de agência antes de uma consequência 
permanente.

Hard floor de HP
Enquanto um APK vinculado não estiver INCAPACITATED, uma instância de dano que normalmente reduziria seu HP a
0 ou menos trava o HP em 1 e aplica INCAPACITATED. O excesso de dano não atravessa essa proteção.
Fluxo:
APK operacional → recebe dano letal → HP trava em 1 → INCAPACITATED.
O evento/mesma resolução que causou a Incapacitation não pode também produzir Partner Loss. Multi-hit, sequência já
em execução ou dano excedente pertencente à mesma resolução não elimina imediatamente o último HP. O combate 
abre uma Emergency Window antes de uma nova possibilidade de morte.
Emergency Window
Quando o APK do jogador é Incapacitated, a execução normal do ciclo é interrompida para devolver decisão ao 
Operator. O APK Incapacitated não pode executar Active Modules. A prioridade da luta muda de vencer para decidir 
como impedir que a derrota vire perda permanente.
Ações pertencentes diretamente ao Operator permanecem disponíveis quando o contexto permitir, incluindo Player 
Actions e Run Away. Em party, aliados ainda operacionais podem continuar contribuindo e podem possuir ferramentas 
específicas de Recovery.
Dano após Incapacitation
Depois que a Emergency Window foi concedida, qualquer nova instância válida de HP Damage contra o APK 
Incapacitated remove seu 1 HP restante e causa a perda correspondente.
Isso inclui dano direto, damage-over-time, Status Effects que causem HP Damage, counters, reflects, efeitos ambientais
e outros efeitos que explicitamente causem dano de HP.
Para um parceiro normal: 1 HP + INCAPACITATED + novo dano → 0 HP → Partner Loss.
Para TURD: 1 HP + INCAPACITATED + novo dano → 0 HP → Operator Loss.
TURD recebe exatamente a mesma proteção de Incapacitated que qualquer outro APK vinculado. O jogador em estado 
de fallback já sofreu Partner Loss e não perde essa última janela de sobrevivência por uma exceção punitiva.
Recovery
Healing comum não remove INCAPACITATED. Um efeito de Heal que não declare compatibilidade com esse estado 
não pode simplesmente restaurar HP e levantar o alvo.
Remover INCAPACITATED exige um efeito específico de Recovery que declare explicitamente essa capacidade. 
Recovery não é ressurreição: ele recupera um APK cuja assinatura ainda existe em 1 HP. Depois que o HP chegou 
efetivamente a 0 e ocorreu Partner Loss/Operator Loss, esses efeitos não restauram a entidade perdida.
NPCs e party
APKs vinculados a NPCs utilizam a mesma regra. Isso permite colocar aliados em situações graves sem transformar 
um único cálculo de dano em morte instantânea. Partner Loss de NPC continua possível quando a situação degrada 
após a Incapacitation.
PVP
PVP convencional é não letal por padrão. Dano letal leva o parceiro a 1 HP + INCAPACITATED e encerra/resolve a 
derrota normal sem Partner Loss.
Run Away contra outro Operator é sempre garantido e não utiliza Escape Interaction.
Morte deliberada em PVP só pode ocorrer quando o atacante completar 100% PURGE no parceiro-alvo. Antes disso, a 
proteção de PVP impede Partner Loss. Após 100% PURGE, o alvo ainda precisa entrar em INCAPACITATED e receber
uma nova instância letal de dano para chegar a 0 HP. PURGE contra o parceiro de outro Operator é socialmente 
reconhecido como ato hostil/tabu mesmo antes de 100%.
Filosofia
INCAPACITATED não é uma segunda barra de vida nem um “Focus Sash infinito”. O APK já perdeu sua capacidade 
normal de combate, Healing comum não resolve o estado e permanecer na luta transforma qualquer novo dano em 
ameaça de perda permanente.
A fantasia buscada é: “Defeat means your partner can no longer fight. Death means there is no partner left to save.”

7.6 INTERACTION CHECKS — RUN AWAY E TAME
Visão geral
Run Away contestado e TAME compartilham uma gramática de interação com EXEs. O objetivo é fazer personalidade, 
estado atual da criatura e Tendências do Operator participarem da resolução sem reduzir a experiência a uma 
porcentagem visível.
Cada Interaction Sequence possui 1, 2 ou 3 situações consecutivas. Cada situação apresenta até 6 opções 
authored/contextuais.
Estrutura das opções
Até quatro opções representam estilos de abordagem associados internamente às Tendências:
VALOUR — confronto, coragem, intimidação, avançar ou demonstrar firmeza.
LOGIC — argumentar, observar, deduzir, racionalizar ou explorar um padrão.
SYNC — acalmar, demonstrar empatia, criar confiança, cooperar ou comunicar intenção.
SELF — distrair, manipular, barganhar, enganar, explorar oportunidade ou priorizar sobrevivência própria.
As tags VALOUR/LOGIC/SYNC/SELF são dados internos e não precisam ser exibidas na interface final. O texto da 
opção deve comunicar implicitamente o tipo de abordagem.
Até duas opções adicionais podem ser NEUTRAL/CONTEXTUAL. Elas não dependem diretamente de uma Tendência 
e podem usar item, informação, ambiente, espera, custo ou outra condição. Uma opção contextual pode ser uma saída 
garantida mediante custo, como sacrificar um item de comida para distrair um EXE e fugir.
Resolução
Ao selecionar uma abordagem ligada a Tendência, o jogo avalia quatro camadas:
1. estado atual do EXE e a situação apresentada;
2. receptividade da espécie/indivíduo àquela abordagem;
3. proficiência do Operator, derivada da Tendência correspondente;
4. modificadores contextuais + uma variância aleatória pequena.
A personalidade/estado do EXE pesa mais do que simplesmente escolher a maior Tendência do Operator. Um Operator
extremamente LOGIC continua melhor em uma abordagem LOGIC do que alguém sem esse perfil, mas uma criatura 
enfurecida que rejeita argumentação pode tornar LOGIC uma escolha ruim mesmo assim.
O RNG deve ser pequeno e servir principalmente para resolver casos limítrofes. O resultado deve parecer 
consequência da leitura da criatura e da build comportamental do Operator, não de uma roleta que ignora contexto.
A UI não mostra porcentagem de sucesso. A situação e o texto dão pistas: “It seems like arguing or dialoguing will not 
be tolerated”, “It keeps staring at your bag”, “It looks ready to bolt”, etc. O jogador aprende a interpretar comportamento 
em vez de memorizar uma tabela exposta.
Os resultados podem ser graduais (por exemplo, strong success / success / failure / backfire) e alterar a disposição do 
EXE ou a situação seguinte. [OPEN] Os thresholds, pesos numéricos e nomes internos finais dos graus de resultado 
ainda precisam ser balanceados.
Run Away
Quando o Operator seleciona Run Away em um encontro comum, o comportamento do EXE determina se a fuga é livre 
ou contestada.
Criaturas passivas, neutras, cautelosas, covardes ou territorialistas que apenas querem que o Operator deixe a área 
podem permitir disengage imediato. Criaturas agressivas, predatórias ou em estado/contexto que exige perseguição 
podem abrir uma Escape Interaction.
Uma Escape Interaction usa a estrutura de 1–3 situações acima. Sucesso encerra o encontro conforme as regras 
globais de fuga; falha devolve o jogo ao combate. O jogador pode tentar Run Away novamente caso sobreviva e o 
encontro continue.
Data Centers são exceção absoluta: combates dentro de uma run não possuem Run Away. A saída depende da 
topologia/EXIT. PVP também não usa esse minigame: fugir de outro Operator é sempre garantido.
TAME
Chegar a 100% TAME não concede a criatura automaticamente. 100% representa que o Operator conseguiu abrir uma 
tentativa de vínculo/interação suficiente para iniciar a Tame Interaction.

A Tame Interaction usa a mesma estrutura de situações, Tendências, receptividade, contexto e pequeno roll, mas seu 
objetivo é ACCEPT LINK em vez de DISENGAGE.
TAME após PURIFY continua sendo o caminho para receber um parceiro normal/purificado. TAME sem PURIFY 
continua estabelecendo um vínculo com um parceiro EXE e preserva todas as consequências do EXE Partner Trait; o 
Interaction Check não apaga essa diferença.
Existe uma tentativa de TAME por alvo por encontro. Se a interação falhar, o vínculo é rejeitado e uma nova tentativa só
pode ocorrer em outro encontro com aquele alvo/assinatura quando as regras de conteúdo permitirem.
Função sistêmica
Interaction Checks dão função mecânica direta às Tendências fora da evolução: o Operator se torna melhor em resolver
problemas da maneira que passou a campanha inteira praticando, mas nenhuma Tendência é uma chave universal 
porque cada EXE possui vontade, estado e receptividade próprios.
O sistema também cria uma ponte única entre Field Behaviour, Combat Call, Run Away e TAME: o mesmo tipo de 
criatura que mostra comportamento no Overworld também responde de forma coerente quando o Operator tenta 
encerrar ou estabelecer um vínculo no combate.
8. PASSIVOS, CHROMA LINEAGE, VARIANT NODES, EXE, 
DEVIL E SHN
8.1 Paleta dinâmica e Chroma Lineage
Sistema de Paleta Dinâmica, Linhagem Cromática e Variant Nodes
Visão geral
Os sprites dos APKs de NULL NETWORK não possuem cores finais desenhadas diretamente em seus arquivos.
Cada sprite é produzido usando uma escala de tons indexados, na qual cada tom representa uma parte semântica da 
criatura, como:
Contorno
Cor primária
Cor secundária
Material
Detalhes
Núcleo
Emissivo
Durante o jogo, esses canais recebem cores dinamicamente.
A aparência final de um APK é determinada pela combinação de:
Forma atual, que define o corpo e a distribuição visual das cores.
Linhagem cromática, herdada da primeira forma intermediária.
Variant Node, que modifica canais específicos da paleta.
Estado de integridade, como Purified, EXE ou DEVIL.
Qualidades especiais, como SHN.
A paleta funciona como parte da identidade persistente do indivíduo.
Dois APKs podem alcançar a mesma forma final, mas apresentar cores diferentes porque seguiram trajetórias 
evolutivas distintas.
1. Princípio visual central
A forma atual e a paleta possuem funções diferentes.
A forma atual mostra o que o APK é agora.
A paleta mostra por qual caminho ele chegou até ali.
Exemplo:
NOVIRE

→ JACKRIDER
→ RISE JUSTIZMAN
Esse indivíduo possui:
Forma atual:
Rise Justizman
Linhagem cromática:
Jackrider / BALANCED
Outro indivíduo:
NOVIRE
→ JUSTIZMAN
→ RISE JUSTIZMAN
possui:
Forma atual:
Rise Justizman
Linhagem cromática:
Justizman / VALOUR
Os dois utilizam o corpo, a silhueta e as animações de Rise Justizman.
Entretanto, o primeiro utiliza uma paleta derivada de Jackrider, enquanto o segundo utiliza uma paleta derivada de 
Justizman.
A aparência do APK funciona como um registro visual de sua história evolutiva.
2. Estrutura cromática dos sprites
2.1 Sprites sem cores definitivas
Os sprites-base não utilizam uma pintura grayscale contínua comum.
Eles utilizam um conjunto limitado de tons exatos, no qual cada tom representa um canal visual específico.
Exemplo de estrutura:
Índice 0
→ Transparência
Índice 1
→ Contorno
Índice 2
→ Sombra primária
Índice 3
→ Meio-tom primário
Índice 4
→ Luz primária
Índice 5
→ Sombra secundária
Índice 6
→ Meio-tom secundário
Índice 7
→ Luz secundária
Índice 8
→ Material escuro
Índice 9
→ Material claro
Índice 10

→ Accent ou detalhe de identidade
Índice 11
→ Emissivo, núcleo, olhos ou energia
O número exato de canais pode ser ajustado durante a produção artística, mas todos os APKs devem seguir o mesmo 
padrão semântico.
Isso permite que qualquer paleta seja aplicada a qualquer forma de maneira previsível.
2.2 Template visual da forma
Cada forma define onde os canais aparecem em seu corpo.
O template da forma determina:
quais partes utilizam a cor primária;
quais partes utilizam a cor secundária;
quais partes são metálicas;
onde ficam os accents;
onde ficam os elementos emissivos;
como as sombras e luzes são distribuídas.
A forma não precisa possuir cores próprias fixas.
Ela possui uma estrutura que recebe a paleta correspondente ao indivíduo.
Exemplo:
RISE JUSTIZMAN
Primary
→ armadura principal
Secondary
→ roupas e placas internas
Material
→ partes mecânicas
Accent
→ emblemas, bordas e símbolos
Emissive
→ olhos, visor e núcleo
Ao mudar de paleta, as mesmas regiões continuam cumprindo suas funções visuais.
3. Paleta inicial
A forma INIT de cada linha possui sua própria paleta inicial.
Exemplo:
NOVIRE
→ utiliza a paleta inicial padrão da linha NOVIRE.
Essa paleta permanece enquanto o APK ainda não estabeleceu uma linhagem cromática intermediária.
A forma INIT ainda pode ser modificada por:
Variant Node;
estado EXE;
estado DEVIL;
qualidade SHN;
outros modificadores visuais especiais.
4. Linhagem cromática intermediária
4.1 Definição da linhagem
A primeira evolução intermediária estabelece permanentemente a Chroma Lineage do indivíduo.

Exemplos:
NOVIRE → JACKRIDER
Chroma Lineage: JACKRIDER / BALANCED
NOVIRE → JUSTIZMAN
Chroma Lineage: JUSTIZMAN / VALOUR
NOVIRE → RIVADER
Chroma Lineage: RIVADER / SELF
NOVIRE → CALIGUNNER
Chroma Lineage: CALIGUNNER / LOGIC
NOVIRE → forma SYNC
Chroma Lineage: forma SYNC / SYNC
A linhagem cromática registra a forma intermediária específica, e não apenas a tendência abstrata.
Isso permite que cada linha evolutiva possua sua própria interpretação visual de VALOUR, LOGIC, SYNC, SELF ou 
BALANCED.
Duas formas VALOUR de linhas diferentes podem compartilhar uma linguagem cromática semelhante sem utilizar 
exatamente as mesmas cores.
4.2 Permanência da linhagem
Depois de estabelecida, a Chroma Lineage não muda.
Exemplo:
NOVIRE
→ JACKRIDER
→ RISE JUSTIZMAN
Resultado:
Forma atual:
Rise Justizman / XVALOUR
Chroma Lineage:
Jackrider / BALANCED
Mesmo que a forma final pertença a XVALOUR, sua paleta principal continua baseada em Jackrider.
Outro exemplo:
NOVIRE
→ RIVADER
→ forma XLOGIC
Resultado:
Forma atual:
XLOGIC
Chroma Lineage:
Rivader / SELF
A silhueta e o design comunicam a forma XLOGIC atual.
A paleta comunica que o indivíduo veio de uma trajetória SELF.
4.3 Papel da linhagem cromática
A linhagem cromática não modifica o funcionamento mecânico do APK por si só.
Sua função principal é:
registrar visualmente o caminho evolutivo;
diferenciar indivíduos da mesma forma final;
reforçar a identidade do parceiro;
tornar a evolução anterior permanentemente relevante;

criar consistência entre aparência, Modules herdados e Growth Lineage.
Idealmente, Chroma Lineage e Growth Lineage são estabelecidas pela mesma forma intermediária.
Exemplo:
Chroma Lineage:
Jackrider / BALANCED
Growth Lineage:
Jackrider / BALANCED
A cor e a distribuição estatística contam a mesma história.
5. Formas finais
Ao alcançar uma forma final, o APK utiliza:
Corpo visual:
template da forma final atual
Paleta principal:
Chroma Lineage intermediária
Exemplo:
NOVIRE
→ JACKRIDER
→ RISE JUSTIZMAN
A forma final possui:
Sprite:
Rise Justizman
Silhueta:
Rise Justizman
Animações:
Rise Justizman
Paleta:
Jackrider
Outro indivíduo:
NOVIRE
→ CALIGUNNER
→ RISE JUSTIZMAN
utiliza:
Sprite:
Rise Justizman
Paleta:
Caligunner
Isso permite que a mesma forma final possua múltiplas identidades cromáticas canônicas.
6. Formas NULL
6.1 Evolução direta para NULL
Quando um APK evolui diretamente de INIT para NULL:
INIT → NULL
ele não possui uma forma intermediária anterior.
Nesse caso:
Chroma Lineage:
NULL

Paleta:
paleta NULL própria da linha
Exemplo:
NOVIRE → EVOLNIGHT
Esse Evolnight utiliza sua paleta NULL padrão.
6.2 Evolução intermediária para NULL
Quando um APK alcança NULL depois de passar por uma forma intermediária:
NOVIRE
→ JUSTIZMAN
→ EVOLNIGHT
ele preserva sua Chroma Lineage anterior.
Forma atual:
Evolnight / NULL
Chroma Lineage:
Justizman / VALOUR
Outro indivíduo:
NOVIRE
→ JACKRIDER
→ EVOLNIGHT
utiliza:
Forma atual:
Evolnight / NULL
Chroma Lineage:
Jackrider / BALANCED
Portanto, um NULL direto e um NULL resultante de uma trajetória anterior possuem aparências diferentes.
8.2 Arquitetura de camadas passivas
NOTA DE NOMENCLATURA: exemplos desta seção que ainda usam NOVIRE devem ser tratados como exemplos 
legados da linha starter VALOUR, não como nome INIT final.
Sistema de Variant Nodes e Modules Passivos
Visão geral
Modules Passivos são efeitos que permanecem ativos durante o combate sem precisar ocupar um dos quatro slots de 
ação do ciclo.
Eles podem:
modificar stats;
reagir a acontecimentos;
aplicar Status Effects;
alterar regras de Modules;
gerar Barrier;
modificar Stability Recovery;
criar vantagens condicionais;
impor desvantagens permanentes;
definir a identidade tática de um APK.
Entretanto, nem todo efeito passivo pertence a um slot equipável.
A estrutura passiva completa de um APK é composta por diferentes camadas:
Species Signature

→ passivo fixo da linha evolutiva.
Variant Node
→ característica intrínseca do indivíduo.
Integrity Trait
→ condição Purified, EXE ou DEVIL.
Installed Passive
→ Module Passivo escolhido pelo Operator.
Special Quality
→ qualidade excepcional, como SHN.
Essas camadas utilizam o mesmo conceito geral de efeitos passivos, mas possuem origens, regras e funções 
diferentes.
1. Estrutura passiva de um APK
1.1 Slots passivos convencionais
Todo APK possui, por padrão, dois espaços associados a Modules Passivos:
Slot 1 — Species Signature
→ fixo;
→ não pode ser removido;
→ pertence à linha evolutiva.
Slot 2 — Installed Passive
→ livre;
→ escolhido pelo jogador;
→ utiliza Modules Passivos coletados.
O primeiro slot representa a natureza da linha.
O segundo representa a build criada pelo Operator.
1.2 Traits intrínsecos
Variant Nodes e estados de integridade não ocupam os dois slots convencionais.
Eles são Traits intrínsecos aplicados adicionalmente.
Portanto, um APK pode possuir simultaneamente:
Species Signature
+ Variant Node
+ Integrity Trait
+ Installed Passive
Isso não significa que o APK possui quatro slots livremente configuráveis.
Apenas o Installed Passive pode ser trocado normalmente pelo jogador.
1.3 Exemplos de composição
APK Purified sem Node
Species Signature
Installed Passive
Total:
2 efeitos passivos permanentes
APK Purified com Node
Species Signature
Variant Node
Installed Passive

Total:
3 efeitos passivos permanentes
APK EXE sem Node
Species Signature
EXE Trait
Installed Passive
Total:
3 efeitos passivos permanentes
APK EXE com Node
Species Signature
Variant Node
EXE Trait
Installed Passive
Total:
4 efeitos passivos permanentes
O mesmo princípio se aplica a DEVIL, utilizando um DEVIL Trait no lugar do EXE Trait.
2. Species Signature
2.1 Definição
A Species Signature é o Module Passivo fixo da linha evolutiva.
Todas as formas pertencentes à mesma linha compartilham essa assinatura fundamental.
Exemplo estrutural:
Linha NOVIRE
Novire
Jackrider
Justizman
Rivader
Caligunner
Forma SYNC
Evolnight
XVALOUR
XSELF
XLOGIC
XSYNC
Species Signature:
mesmo passivo estrutural da linha NOVIRE.
A assinatura representa aquilo que permanece reconhecível em todas as possibilidades daquela linha.
2.2 Regras
A Species Signature:
está sempre ativa;
não ocupa o slot livre;
não pode ser removida;
não pode ser substituída;
não pode ser extraída por SCAN;
não pode ser obtida por PURIFY;
não pode ser instalada em outra linha;

permanece durante todas as evoluções;
desaparece permanentemente caso o APK morra.
A evolução pode modificar a maneira como a assinatura interage com novas capacidades, mas não substitui sua 
identidade básica.
2.3 Objetivo de design
A Species Signature garante que cada linha possua uma característica mecânica reconhecível.
Mesmo que dois APKs utilizem:
Nodes diferentes;
formas diferentes;
Modules ativos diferentes;
passivos instalados diferentes;
eles ainda compartilham uma raiz funcional.
A assinatura não deve ser tão poderosa que determine toda a build, mas precisa ser relevante o suficiente para 
influenciar decisões.
3. Installed Passive Modules
3.1 Definição
Installed Passive Modules são passivos compartilhados que podem ser coletados e instalados pelo jogador.
Eles ocupam o slot passivo livre do APK.
Exemplos de função:
Aumentar dano contra alvos com Burn.
Recuperar HP ao aplicar um debuff.
Receber Barrier ao entrar em Unstability.
Aumentar Stability Recovery enquanto estiver com HP baixo.
Aplicar um bônus ao primeiro Module de cada ciclo.
Reduzir dano recebido de ataques em área.
Esses Modules não pertencem permanentemente a uma linha específica.
Uma vez desbloqueados, passam a fazer parte da coleção do jogador.
3.2 Equipamento
Por padrão, cada APK pode instalar:
1 Module Passivo compartilhado
Esse Module pode ser alterado através do Profile enquanto o jogador não estiver em combate.
Trocar o Installed Passive:
não gasta período;
não consome recurso;
não altera a Species Signature;
não altera o Variant Node;
não altera o Integrity Trait;
não pode ser feito durante um ciclo ativo.
A troca de build é livre fora do combate, da mesma forma que organizar Modules ativos não representa uma atividade 
temporal do Operator.
3.3 Modules Passivos não são consumíveis
Desbloquear um Module Passivo significa adicioná-lo permanentemente à coleção do jogador.
Ele não é destruído ao ser removido.
Module desbloqueado
→ pode ser instalado;

→ pode ser removido;
→ pode ser reinstalado posteriormente.
Como o jogador possui apenas um parceiro ativo, não existe necessidade de manter várias cópias idênticas do mesmo 
passivo.
3.4 Restrições
Modules Passivos podem possuir restrições explícitas:
Exige determinado tipo de Module ativo.
Funciona apenas com ataques físicos.
Funciona apenas com ataques mágicos.
Exige um Status Effect específico.
Não funciona com EXEs.
Só pode ser instalado em determinadas formas.
Só funciona enquanto determinado Node estiver presente.
As restrições precisam estar descritas claramente.
Nenhum Module Passivo deve falhar silenciosamente por uma condição escondida.
4. Obtenção de Modules Passivos
4.1 PURIFY como fonte principal
PURIFY é a principal forma de adquirir Installed Passive Modules.
Ao purificar um EXE, o jogador recebe um passivo associado a:
aquele EXE;
sua linha evolutiva;
seu tipo;
seu habitat;
sua família de comportamento;
o distrito ou encontro correspondente.
O passivo recebido por PURIFY não é a Species Signature intrínseca do alvo.
Essa distinção elimina uma ambiguidade do sistema:
Species Signature
→ pertence à criatura;
→ não é extraível.
Purification Passive
→ pertence ao pool de recompensas;
→ pode ser coletado e instalado.
4.2 Purification Passive Pool
Cada EXE possui acesso a um Purification Passive Pool.
Exemplo conceitual:
RATTUS.exe
Purification Passive Pool:
├── Scavenger Protocol
├── Emergency Cache
├── Pack Routine
└── Urban Camouflage
A primeira purificação pode garantir o passivo principal associado àquele EXE.
Caso o jogador já o possua, o sistema procura outro passivo válido relacionado.
Ordem de prioridade:

1. Passivo principal do EXE.
2. Outro passivo da mesma linha.
3. Passivo relacionado ao tipo ou função.
4. Passivo relacionado ao ambiente.
5. Conversão em EXP extra.
4.3 Outras fontes
Modules Passivos também podem ser concedidos por conteúdo explicitamente definido, como:
bosses;
Data Centers;
Swarms;
quests;
eventos semanais;
recompensas narrativas;
NPCs;
conteúdo raro.
Por padrão, eles não devem cair aleatoriamente de qualquer inimigo derrotado.
Isso preserva PURIFY como a ação especializada em recompensas passivas.
8.3 Variant Nodes — definição canônica final
Variant Nodes são características congênitas de um indivíduo. Eles funcionam como Modules/Traits passivos 
intrínsecos que alteram fisionomia legível, VFX, ecologia e regras de combate sem transformar o indivíduo em outra 
espécie ou forma evolutiva.
• Um APK comum possui 0 ou 1 Variant Node.
• Bosses, encontros autorais e entidades excepcionais podem quebrar esse limite apenas quando explicitamente 
configurados.
• O Node acompanha o indivíduo por level up e evolução.
• PURIFY e TAME preservam o Node.
• O Node não determina a EvolutionBranch.
• O Node não ocupa Installed Passive Slot.
• O Node não pode ser equipado, removido, transferido, extraído por SCAN/PURGE/PURIFY ou convertido em item.
• Se o indivíduo é perdido permanentemente, o Node também é perdido.
• Nodes comuns são side-grades: todo benefício relevante possui custo, fraqueza, risco ou limitação correspondente.
8.3.1 C-Series — Environmental Nodes
Os quatro C-Series formam dois pares de oposição. Eles compartilham uma estrutura: imunidade ao Status associado +
proc ofensivo do mesmo Status + vulnerabilidade dobrada ao Status oposto.
Node Benefício Vulnerabilidade Identidade visual
COMBUSTIVE Imune a BURN. Cada 
hit ofensivo que cause 
dano tem 10% de 
chance de aplicar +1 
BURN.
Stacks de FROZEN 
recebidos são 
dobrados.
Eyes & lights quentes; 
brasas/calor.
CRYOSIVE Imune a FROZEN. 
Cada hit ofensivo que 
cause dano tem 10% 
de chance de aplicar +1
FROZEN.
Stacks de BURN 
recebidos são 
dobrados.
Ciano/azul-claro; 
cristais/névoa fria.
CONDUCTIVE Imune a STUN. Cada 
hit ofensivo que cause 
dano tem 10% de 
chance de aplicar +1 
Stacks de POISON 
recebidos são 
dobrados.
Amarelo/branco 
elétrico; pequenas 
descargas.

Node Benefício Vulnerabilidade Identidade visual
STUN.
CORROSIVE Imune a POISON. 
Cada hit ofensivo que 
cause dano tem 10% 
de chance de aplicar +1
POISON.
Stacks de STUN 
recebidos são 
dobrados.
Verde ácido; 
bolhas/gotas/vapor.
Regra de multi-hit dos C-Series: cada hit elegível realiza sua própria checagem de 10%. NÃO existe a antiga limitação 
“uma ativação por Module/alvo”. Um Module multi-hit pode, portanto, realizar múltiplas rolagens e aplicar múltiplos 
stacks se as rolagens forem bem-sucedidas.
Pares opostos: COMBUSTIVE ↔ CRYOSIVE (BURN/FROZEN) e CONDUCTIVE ↔ CORROSIVE (STUN/POISON). O 
sistema não constitui uma roda completa de Types; a relação acontece através dos próprios Status Effects.
8.3.2 DE-Series — Adaptation Nodes
Node Benefício Custo / risco Filosofia
DEFENSIVE Recebe +1 BARRIER 
no início de cada ciclo, 
respeitando o limite 
normal de Barrier.
Dano final causado por 
Modules ofensivos 
×0.80.
Absorver o dano.
DESTRUCTIVE Dano final causado por 
Modules ofensivos 
×1.20.
Cada Active Module 
ofensivo usado tem 
10% de chance de 
aplicar +1 BLEEDING 
no próprio usuário. A 
checagem é por 
ativação do Module.
Eliminar a ameaça 
primeiro.
DEPLETIVE Modules ofensivos 
curam 20% do dano 
real de HP causado.
Max HP ×0.75. Recuperar o dano 
através da agressão.
DECEPTIVE Depois que a 
checagem normal de 
Accuracy/Dodge 
resultaria em hit, 
recebe uma segunda 
checagem de evasão. 
DECEPTIVE_EVADE =
chance normal de 
Dodge do APK ÷ 3.
Se o ataque atravessa 
as duas checagens, 
dano final recebido 
×1.25.
Evitar que o dano 
aconteça.
DEPLETIVE — cálculo de cura: somente HP realmente removido do alvo conta. Overkill não gera cura extra. Dano 
inteiramente absorvido por BARRIER não conta como HP drenado. Em Modules com múltiplos alvos, soma-se o HP 
efetivamente removido. A cura gerada por uma única ativação é limitada a 20% do Max HP do portador.
DECEPTIVE — segunda evasão escalável: DECEPTIVE_EVADE = chance normal de Dodge do APK ÷ 3. A segunda 
checagem usa a chance de evasão já resultante do sistema normal, não um valor fixo. Com a fórmula atual, em que o 
DODGE reduz ACCURACY por DODGE/2, um APK com DODGE 60 fornece 30 pontos percentuais de evasão normal e
recebe 10% na segunda checagem DECEPTIVE. Alterações futuras na fórmula normal de Dodge devem refletir 
automaticamente nesta segunda checagem.
8.3.3 Leitura visual reutilizável
Variant Nodes não exigem um sprite exclusivo para cada combinação. A leitura visual deve ser produzida por canais 
reaproveitáveis para evitar explosão de assets.
• Chroma Lineage continua sendo a identidade cromática principal do corpo.
• Cada forma define um canal reservado de EYES & LIGHTS: olhos, cristais, circuitos, núcleos, luzes, esferas e 
pequenos accents emissivos que podem receber a cor do Node.
• Cada Node possui um preset reutilizável de partículas/VFX constante no fundo/entorno do sprite.
• A UI apresenta um ícone/badge do Node.

• A cor nunca é o único canal de informação; partículas, ícone e comportamento visual precisam sustentar a leitura à 
distância.
• Detalhes anatômicos específicos por espécie são opcionais e autorais; não são requisito para todas as combinações.
8.3.4 Ecologia e geração
Variant Nodes não são sorteados por uma tabela global indiferenciada. A probabilidade é data-driven e resulta da 
interseção entre compatibilidade da espécie, distrito/subárea, DAY/NIGHT, action_block, Danger, Infestation, Encounter 
Template, eventos e condições ambientais.
• Ambientes quentes podem aumentar o peso de COMBUSTIVE.
• Ambientes frios/refrigerados podem aumentar o peso de CRYOSIVE.
• Infraestrutura elétrica/chuva pode aumentar o peso de CONDUCTIVE quando a espécie permitir.
• Ambientes contaminados/químicos podem aumentar o peso de CORROSIVE quando a espécie permitir.
• DE-Series também podem possuir afinidades ecológicas próprias de espécie/área, sem depender de elemento.
• Um ambiente nunca cria um Node em uma espécie marcada como incompatível; a espécie continua sendo a primeira
restrição.
Clima/temperatura dinâmica é uma camada opcional sobre os mesmos pesos de spawn, não um segundo sistema 
paralelo. Tags como HOT, COLD, WET, CONTAMINATED e HIGH_VOLTAGE podem modificar pesos se o sistema de 
clima for implementado.
8.4 EXE — Integrity State e EXE Partner Trait
EXE não é Variant Node e não é forma evolutiva. É um Integrity State. Criaturas hostis geradas normalmente pelo 
mundo são EXEs, mas o comportamento especial de Stability abaixo só existe quando um EXE é vinculado diretamente
a um Operator sem PURIFY.
EXE selvagem
• Possui STABILITY normalmente.
• Paga Stability Cost normalmente.
• Recupera Stability conforme suas regras normais.
• Entra em UNSTABILITY pelas regras normais do combate.
• A IA de inimigo não recebe automaticamente o EXE Partner Trait.
EXE Partner Trait — TAME direto sem PURIFY
• STABILITY atual permanece permanentemente em 0.
• Todo Stability Cost de Active Modules é tratado como 0.
• O parceiro não recupera Stability e efeitos de recuperação de STB são ignorados.
• O parceiro permanece permanentemente em UNSTABILITY e sofre as penalidades normais desse estado.
• Triggers “ao entrar em UNSTABILITY” não repetem a cada ciclo apenas porque o estado continua permanente.
• Somente o custo de Stability é removido. Recoil, self-status, redução de stats, vulnerabilidades e outros drawbacks 
próprios dos Modules continuam funcionando.
Identidade de design: o parceiro EXE remove uma limitação fundamental de build — o custo de Stability — mas aceita 
uma condição de risco permanente. A intenção é permitir builds extremamente quebradas para o bem e para o mal, 
sem transformar TAME direto em upgrade universal.
8.5 SHN — Special Quality
SHN é uma Special Quality extremamente rara. Não é Variant Node nem Integrity State. Ao contrário dos oito Nodes 
comuns, SHN é deliberadamente superior e deve ser raro o suficiente para que sua aparição seja um evento 
excepcional de campanha.
• +10% em todos os parâmetros de combate variáveis do indivíduo. Isso inclui os cinco stats naturais e parâmetros 
percentuais/derivados aplicáveis, como DODGE, CRIT e Stability Recovery. O Max Stability continua sendo o limite 
técnico fixo de 100.
• +1 Installed Passive Slot. Um APK normal possui 1 Species Signature fixa + 1 Installed Passive configurável; um 
SHN possui 1 Species Signature + 2 Installed Passives configuráveis.
• SHN acompanha o indivíduo através de evolução, PURIFY e TAME.

• SHN não pode ser extraído, transferido ou produzido por item/Module comum.
• SHN pode coexistir com um Variant Node e com EXE/DEVIL quando o conteúdo não proibir explicitamente.
• SHN não pinta todos os APKs de dourado: utiliza uma camada própria de brilho/iridescência/partículas que preserva 
Chroma Lineage e leitura do Variant Node.
8.6 Interação com Player Actions
• SCAN obtém Active Modules; não copia Species Signature, Variant Node, Integrity State/Trait, SHN ou Installed 
Passive.
• PURGE concede 3× EXP após a penalidade de nível e remove 1 Population Unit conforme o Capítulo 9; não 
concede Active Module, Installed Passive, item, Variant Node, Species Signature, Integrity Trait ou SHN.
• PURIFY utiliza a Purification Passive Pool e remove EXE quando usado como preparação para um vínculo limpo. 
Variant Node e SHN permanecem.
• TAME após PURIFY cria parceiro Purified preservando Variant Node e SHN.
• TAME sem PURIFY cria parceiro EXE preservando Variant Node e SHN e ativando o EXE Partner Trait.
8.7 Ordem de composição visual e persistência
11. Ordem de composição da paleta
A ordem canônica é:
1. Template visual da forma atual
2. Paleta inicial ou Chroma Lineage
3. Overrides do Variant Node
4. Modificador de integridade
5. Modificador de qualidade especial
6. Efeitos temporários de combate
Fórmula conceitual:
PALETA FINAL =
Template da forma
+ Linhagem cromática
+ Overrides do Node
+ Modificador EXE/Purified/DEVIL
+ Qualidade SHN
+ Efeitos temporários
Cada camada deve modificar somente os canais sob sua responsabilidade.
12. Efeitos temporários
Status Effects e Modules podem alterar temporariamente a aparência do APK.
Exemplos:
Burn
→ glow vermelho ou brasas
Frozen
→ camada azulada e cristais
Barrier
→ efeito externo sobre o sprite
Corruption
→ glitches adicionais
Buff de ATK
→ pulso ou emissivo temporário
Esses efeitos não alteram permanentemente:

Chroma Lineage;
Variant Node;
estado de integridade;
paleta salva do indivíduo.
Eles são removidos quando o efeito correspondente termina.
13. Evolução durante combate
Quando um APK evolui durante uma batalha, a nova aparência é composta imediatamente.
O processo visual é:
1. Forma antiga inicia a animação de evolução.
2. O sprite é substituído pelo template da nova forma.
3. A Chroma Lineage é estabelecida ou preservada.
4. O Variant Node é reaplicado.
5. O estado de integridade é reaplicado.
6. Qualidades especiais são reaplicadas.
7. A forma final aparece com sua paleta completa.
Evolução de INIT para intermediária
A primeira forma intermediária estabelece a Chroma Lineage.
Novire padrão
→ Justizman
Antes:
paleta INIT de Novire
Depois:
paleta VALOUR de Justizman
Caso possua Node:
Novire COMBUSTIVE
→ Justizman COMBUSTIVE
Antes:
COMBUSTIVE sobre a paleta INIT
Depois:
COMBUSTIVE com accents VALOUR de Justizman
Evolução de intermediária para final
A Chroma Lineage é preservada.
Jackrider
→ Rise Justizman
Antes:
template Jackrider
paleta Jackrider
Depois:
template Rise Justizman
paleta Jackrider
A mudança de forma é grande, mas a identidade cromática continua reconhecível.
14. Comunicação visual e legibilidade
A cor não deve ser o único elemento utilizado para comunicar a identidade do APK.
Cada camada deve possuir um canal visual próprio.
Silhueta e design corporal

→ forma atual
Paleta principal
→ Chroma Lineage como identidade cromática principal; Variant Node atua em canais reservados de eye & lights e 
VFX.
Accent e detalhes
→ trajetória intermediária
Ícone ou badge
→ Variant Node
Glitch, outline e VFX
→ estado de integridade
Brilho e partículas especiais
→ SHN
Isso evita que uma forma XSELF com paleta VALOUR seja confundida com uma forma XVALOUR.
A forma atual deve continuar legível pela:
silhueta;
sprite;
animação;
nome;
ícone;
interface.
15. Apresentação no Profile
O Profile do APK deve permitir que o jogador consulte a origem de sua aparência.
Exemplo:
CURRENT FORM
Rise Justizman / XVALOUR
EVOLUTION HISTORY
Novire → Jackrider → Rise Justizman
CHROMA LINEAGE
Jackrider / BALANCED
VARIANT NODE
COMBUSTIVE
INTEGRITY
Purified
QUALITY
SHN
O jogador nunca deve encontrar dois APKs visualmente diferentes sem conseguir descobrir por que eles são diferentes.
16. Regras ecológicas dos Nodes
Variant Nodes não devem ser sorteados globalmente com a mesma probabilidade.
A distribuição depende de:
espécie;
distrito;
subárea;
ambiente;
horário;
Danger;
Infestation;

encounter;
evento;
Swarm;
condições narrativas.
Exemplo:
Área gelada
CRYOSIVE:
muito comum
DEFENSIVE:
comum
COMBUSTIVE:
raro
Outros Nodes:
impossíveis ou muito raros
Uma mesma espécie pode aparecer em diferentes distritos com Nodes distintos.
Isso permite expandir a fauna sem criar uma linha evolutiva completamente nova.
17. Persistência da identidade individual
Os seguintes elementos pertencem ao indivíduo e permanecem salvos:
Forma atual
Histórico evolutivo
Chroma Lineage
Variant Node
Estado de integridade
Qualidade especial
A paleta final não precisa ser tratada como uma imagem única e definitiva.
Ela é reconstruída a partir desses dados sempre que o APK é exibido.
Isso garante que a mesma identidade visual seja utilizada em:
combate;
Profile;
Social;
Ranking;
Encyclopedia;
Navigator;
Fórum;
retratos;
ícones;
cenas narrativas.
18. Regras de produção artística
Todos os sprites de APK devem respeitar estas regras:
Utilizar os mesmos índices cromáticos padronizados.
Não utilizar cores finais diretamente no sprite-base.
Não introduzir tons intermediários fora do conjunto permitido.
Manter o mesmo significado para cada canal.
Separar efeitos emissivos de materiais comuns.
Garantir que a forma seja reconhecível sem depender da cor.
Permitir que accents da linhagem continuem visíveis sob Nodes.

Reservar canais específicos para EXE, DEVIL e efeitos especiais.
Testar cada forma com múltiplas paletas antes de ser considerada finalizada.
Evitar combinações que reduzam excessivamente o contraste ou a leitura do sprite.
19. Princípios de balanceamento visual
O sistema deve respeitar permanentemente:
A forma atual define o corpo.
A primeira intermediária define a linhagem cromática.
A linhagem permanece durante toda a progressão posterior.
O Variant Node acompanha o indivíduo desde sua geração.
O Variant Node altera canais reservados de eye & lights, ícone e VFX/partículas sem substituir a identidade cromática 
principal da Chroma Lineage.
EXE e DEVIL modificam a aparência sem substituir sua identidade.
SHN funciona como Special Quality adicional, não como pintura universal.
A cor nunca é o único meio de comunicar uma característica.
Toda diferença visual permanente deve possuir uma causa sistêmica consultável.
A aparência do APK deve contar sua trajetória.
Resumo canônico
SPRITE-BASE
→ não possui cores finais;
→ utiliza canais indexados padronizados.
FORMA ATUAL
→ define corpo, silhueta, animações e posição dos canais.
PALETA INIT
→ utilizada antes da primeira evolução intermediária.
CHROMA LINEAGE
→ estabelecida pela primeira forma intermediária;
→ permanece durante todas as evoluções futuras.
FORMA FINAL
→ utiliza seu próprio corpo;
→ preserva a paleta da linhagem intermediária.
NULL DIRETO
→ utiliza Chroma Lineage NULL.
NULL APÓS INTERMEDIÁRIA
→ preserva a linhagem anterior.
VARIANT NODE
→ acompanha o indivíduo;
→ modifica canais específicos;
→ modifica canais reservados e VFX próprios sem apagar a Chroma Lineage.
EXE / DEVIL
→ aplicam modificadores visuais sobre a paleta existente.
SHN
→ adiciona leitura visual excepcional, brilho/iridescência e efeitos especiais;
→ não substitui completamente as cores anteriores.
O resultado é que a aparência de um APK não representa somente sua espécie ou forma atual.
Ela representa:
quem ele é

+ de onde veio
+ em qual ambiente surgiu
+ qual Node carrega
+ qual estado de integridade possui
+ quais transformações atravessou
Em NULL NETWORK, a cor de um APK funciona como parte permanente de sua biografia.
8.8 Ativação, prioridade, stacking, UI e balanceamento de passivos
13. Estrutura de ativação dos passivos
Todo efeito passivo precisa possuir uma definição clara.
TRIGGER
→ quando o efeito tenta ativar.
CONDITION
→ quais requisitos precisam ser cumpridos.
TARGET
→ quem recebe o efeito.
EFFECT
→ o que acontece.
LIMIT
→ quantas vezes pode ocorrer.
PRIORITY
→ ordem em relação a outros efeitos.
STACK RULE
→ como interage com outras cópias.
Exemplo:
Trigger:
início do ciclo.
Condition:
nenhuma.
Target:
portador.
Effect:
receber 1 Barrier.
Limit:
uma vez por ciclo.
13.1 Momentos possíveis
Passivos podem ativar em momentos como:
Início do encontro.
Início do ciclo.
Antes de uma ação.
Depois de uma ação.
Ao utilizar um Module.
Ao causar dano.
Ao receber dano.
Ao aplicar Status Effect.
Ao sofrer Status Effect.

Ao entrar em Unstability.
Ao bloquear dano.
Ao derrotar um alvo.
Ao terminar o ciclo.
Todo passivo deve informar seu momento de ativação.
14. Ordem entre passivos
Modificadores contínuos são calculados antes de efeitos acionados.
Ordem geral:
1. Stats naturais da forma e linhagem.
2. Pontos distribuídos.
3. Variant Node.
4. Integrity Trait.
5. Species Signature.
6. Installed Passive.
7. Status Effects.
8. Buffs e debuffs temporários.
Para efeitos que ativam no mesmo momento, cada um possui prioridade explícita.
A ordem nunca deve depender de qual Resource foi carregado primeiro ou da posição interna de uma lista invisível.
15. Regras de stacking
15.1 Passivos idênticos
O mesmo Installed Passive não pode ser equipado duas vezes no mesmo APK.
Caso alguma qualidade especial futuramente permita múltiplos slots instaláveis:
duas cópias do mesmo Module
→ proibidas.
15.2 Efeitos com o mesmo Status
Quando diferentes passivos aplicam o mesmo Status Effect, a regra de stacking pertence ao próprio Status.
Exemplo:
COMBUSTIVE aplica Burn.
Installed Passive também aplica Burn.
Resultado:
segue a regra normal de stacks de Burn.
O passivo não cria uma regra especial escondida.
15.3 Modificadores percentuais
Bônus aditivos são resolvidos antes de multiplicadores percentuais.
Exemplo:
ATK natural: 70
Pontos do jogador: +10
ATK base:
80
DEFENSIVE:
-20%
ATK final:
64
Isso impede que o jogador ignore a penalidade do Node aplicando pontos depois do modificador.

16. Apresentação no Profile
O Profile deve separar claramente cada camada.
Exemplo:
PASSIVE PROFILE
SPECIES SIGNATURE
Knight Protocol
VARIANT NODE
COMBUSTIVE
INTEGRITY
EXE Core
INSTALLED PASSIVE
Burning Feedback
SPECIAL QUALITY
None
O jogador não deve precisar adivinhar por que determinado efeito está ativo.
Cada entrada deve permitir consultar:
descrição;
trigger;
condição;
efeito;
limite;
origem;
possíveis penalidades.
17. Apresentação durante o combate
Os Traits intrínsecos devem ser visíveis antes ou durante a execução do primeiro ciclo.
Exemplo:
NOVIRE.exe
[FIRE] [EXE]
Ao inspecionar o alvo:
Species Signature:
desconhecida ou revelada por análise.
Variant Node:
COMBUSTIVE.
Integrity:
EXE.
Installed Passive:
desconhecido até ser identificado.
O Node precisa ser reconhecível visualmente mesmo antes de o jogador conhecer todos os seus números.
Isso permite decisões táticas:
“Esse inimigo é Defensive.”
“Esse grupo aplica Burn.”
“Esse EXE possui um Trait de corrupção perigoso.”
18. Princípios de balanceamento
O sistema deve respeitar permanentemente estas regras:
Species Signature define a identidade da linha.

Installed Passive define a escolha de build do jogador.
Variant Node define a variação individual.
Integrity Trait define a condição estrutural do APK.
Nodes não ocupam o slot passivo livre.
EXE e DEVIL não ocupam o slot passivo livre.
Nodes comuns funcionam como sidegrades.
Uma vantagem forte de Node precisa possuir custo, condição ou limitação.
Nodes não podem ser extraídos nem transferidos.
TAME é o único meio de preservar um Node encontrado.
PURIFY concede passivos compartilhados, não Traits intrínsecos.
SCAN lida com Modules ativos. PURGE não concede nem extrai Modules; seu retorno é EXP + impacto ecológico.
Todo efeito passivo possui trigger, limite e stacking explícitos.
Nenhuma diferença mecânica permanente deve ficar escondida do jogador.
Perder um APK significa perder sua combinação individual completa.
Resumo canônico
SPECIES SIGNATURE
→ passivo fixo da linha;
→ sempre ativo;
→ não pode ser extraído.
INSTALLED PASSIVE
→ slot livre;
→ escolhido pelo Operator;
→ obtido principalmente por PURIFY.
VARIANT NODE
→ Trait congênito;
→ altera paleta e gameplay;
→ acompanha o indivíduo;
→ não ocupa slot;
→ não pode ser transferido.
PURIFIED
→ estado estável;
→ sem Trait obrigatório adicional.
EXE
→ recebe EXE Trait;
→ pode coexistir com Node;
→ oferece vantagem e risco.
DEVIL
→ recebe DEVIL Trait;
→ pode coexistir com Node;
→ altera profundamente as regras do APK.
SHN
→ Special Quality;
→ não é Node;
→ qualidade rara deliberadamente superior: +10% nos parâmetros de combate variáveis e +1 Installed Passive Slot.
SCAN
→ Modules ativos escolhidos.

PURGE
→ 3× EXP após penalidade de nível; sem Modules/itens; remove 1 Population Unit.
PURIFY
→ Installed Passive associado ao alvo.
TAME
→ preserva o Node e o estado de integridade correspondente.
A estrutura passiva completa de um indivíduo pode ser resumida como:
Aquilo que sua linha é
+ aquilo com que ele nasceu
+ aquilo em que ele se encontra
+ aquilo que o Operator instalou
Assim, dois APKs da mesma forma e do mesmo nível podem funcionar de maneiras radicalmente diferentes sem 
depender de IVs, EVs ou diferenças ocultas.

9. ECOLOGIA, POPULAÇÕES E EXEs NO OVERWORLD
SISTEMA DE CONTROLE ECOLÓGICO DOS EXEs
1. Visão geral
Os EXEs de NULL NETWORK não são encontros infinitos e completamente desconectados entre si.
Cada distrito possui uma fauna digital própria, composta por diferentes linhas evolutivas, Variant Nodes, 
comportamentos e formações. As ações dos jogadores alteram essa fauna no decorrer da semana.
O ecossistema existe para fazer com que PURGE e PURIFY não sejam apenas métodos diferentes de receber 
recompensas após um combate.
Cada ação representa uma filosofia distinta de progressão:
PURGE
→ consome o futuro para gerar crescimento imediato.
PURIFY
→ investe no futuro para ampliar variedade e possibilidades.
SCAN
→ estuda a fauna sem alterá-la.
TAME
→ preserva um indivíduo como parceiro.
O estado ecológico de uma região modifica:
quais espécies aparecem;
com que frequência aparecem;
quais Variant Nodes podem surgir;
tamanho e composição dos grupos;
disponibilidade futura de Modules;
aparência e movimentação do Overworld Local;
atividade comunitária;
threads e Leads;
estado de infestação;
possibilidade de colapso ecológico.
2. Distritos e zonas ecológicas
Um distrito pode possuir uma ou mais Zonas Ecológicas.
Uma Zona Ecológica é uma área na qual a fauna EXE é controlada como uma população própria.
Exemplo:
DISTRITO: AKIHABARA
Zona Ecológica A
→ Praça da Estação.
Zona Ecológica B
→ Ruas Comerciais.
Zona Ecológica C
→ Becos e Arcades Abandonados.
Zona Ecológica D
→ Sub-rede de Manutenção.
Duas zonas do mesmo distrito podem possuir:
espécies diferentes;
frequências diferentes;
Nodes diferentes;

Danger diferente;
respostas diferentes aos Micro-Updates;
estados ecológicos independentes.
A eliminação de uma espécie em uma zona não significa automaticamente sua eliminação em todo o distrito.
3. População ecológica
Cada espécie presente em uma zona possui uma quantidade finita de Population Units.
Population Units representam quantas assinaturas ativas daquela espécie ainda existem naquela ecologia durante a 
semana atual.
Exemplo:
ARCADE ABANDONADO
RATTUS
→ 5 Population Units.
VESPID
→ 4 Population Units.
MIMICAB
→ 3 Population Units.
Outra linha rara
→ 1 Population Unit.
Population Units não representam necessariamente indivíduos físicos visíveis ao mesmo tempo.
Uma população de cinco unidades pode gerar apenas dois representantes circulando no mapa naquele momento.
O valor representa:
presença ecológica;
capacidade de aparecer em encontros;
quantidade restante antes da ausência local;
peso da espécie dentro da zona.
4. População-base
Cada espécie possui uma Base Population específica para cada zona.
A Base Population representa a quantidade normal daquela espécie quando o ecossistema está saudável.
Exemplo:
RATTUS
Praça da Estação:
Base Population 5.
Arcade Abandonado:
Base Population 3.
Sub-rede de Manutenção:
Base Population 1.
A mesma espécie pode ser:
dominante em uma zona;
comum em outra;
rara em outra;
impossível em outra.
A população-base também pode variar por:
DAY;
NIGHT;
Micro-Update;
capítulo;

Danger;
Infestation;
evento;
Swarm;
Data Center;
condição narrativa.
5. Relação entre população e frequência
A frequência de uma espécie depende de sua população restante.
Quanto menor a população, menor sua presença nos encontros e no Overworld.
Exemplo:
Base Population:
5.
População atual:
5.
Resultado:
frequência normal.
Base Population:
5.
População atual:
2.
Resultado:
frequência severamente reduzida.
População atual:
0.
Resultado:
espécie localmente ausente.
A redução deve ser gradual.
Uma espécie não continua aparecendo normalmente até desaparecer de uma vez. Sua raridade cresce conforme sua 
população diminui.
6. Formação dos encontros
Os encontros são montados usando:
População restante
+ frequência-base
+ horário
+ Variant Nodes disponíveis
+ comportamento de grupo
+ Danger
+ Infestation
+ condições da zona
Uma espécie com grande população possui maior chance de:
aparecer;
responder a Combat Calls;
formar grupos;
ocupar múltiplos slots;
proteger indivíduos da mesma espécie;
participar de Swarms.

Uma espécie com baixa população tende a:
aparecer sozinha;
possuir menos aliados próximos;
formar grupos menores;
desaparecer de certas subáreas;
tornar-se uma ocorrência rara.
A população ecológica limita quais encontros podem ser gerados.
Um encontro nunca pode utilizar mais assinaturas de uma espécie do que sua população atual permite.
7. PURGE
7.1 Identidade
PURGE representa a extração agressiva e a eliminação definitiva de um EXE específico.
O jogador destrói aquela assinatura para converter seus dados em uma quantidade muito maior de EXP.
PURGE
→ crescimento vertical imediato;
→ alto ganho de EXP;
→ redução da fauna local;
→ perda de oportunidades futuras.
PURGE está associado principalmente à tendência SELF.
7.2 Recompensa
Ao completar PURGE em um alvo e derrotá-lo:
EXP recebida pelo alvo
→ multiplicada por 3.
A multiplicação acontece depois das reduções por diferença de nível.
Exemplo:
EXP original:
500.
Penalidade por inimigo muito fraco:
500 → 100.
PURGE:
100 × 3 = 300 EXP.
Isso impede que o jogador atravesse a progressão eliminando continuamente EXEs muito abaixo de seu nível.
7.3 O que PURGE não concede
PURGE não concede:
Module ativo;
Module Passivo;
item;
Variant Node;
recompensa ecológica positiva;
novo parceiro;
bônus de TAME.
Ao concluir PURGE em um alvo:
PURIFY
→ bloqueado.
TAME
→ bloqueado.

O jogador ainda pode utilizar SCAN antes de concluir PURGE, desde que invista os slots necessários durante o 
combate.
7.4 Impacto ecológico
Cada EXE marcado por PURGE que seja derrotado gera uma remoção pendente de 1 Population Unit de sua espécie 
na zona atual. A remoção só é confirmada quando o encontro é formalmente resolvido; Run Away bem-sucedido 
descarta a alteração pendente.
Population Units da espécie:
-1.
Exemplo:
RATTUS:
5 unidades.
Jogador purga dois RATTUS.
Nova população:
3 unidades.
Depois da resolução formal do encontro, a diminuição passa a influenciar:
encontros futuros;
EXEs visíveis no mapa;
tamanho dos grupos;
respostas a Combat Calls;
composição da zona.
A assinatura individual expurgada foi deletada permanentemente.
A espécie pode voltar a aumentar futuramente através de migração, recompilação ou Micro-Update, mas aquele 
indivíduo não retorna.
8. Ausência local de uma espécie
Quando a população de uma espécie chega a zero:
Estado:
LOCALLY ABSENT.
Durante o restante da semana:
a espécie deixa de aparecer naquela zona;
seus Variant Nodes deixam de aparecer;
encontros dependentes dela ficam indisponíveis;
Modules exclusivos ficam temporariamente inacessíveis;
grupos que dependiam dela mudam de composição;
outras espécies passam a ocupar o espaço deixado;
o fórum pode comentar sua ausência.
Ausência local não representa necessariamente extinção global.
A espécie pode continuar existindo:
em outras zonas;
em outros distritos;
em Data Centers;
em eventos;
em servidores estrangeiros;
como parceiro de jogadores.
9. PURIFY
9.1 Identidade
PURIFY representa a estabilização de uma assinatura EXE.

Em vez de destruir seus dados, o jogador remove sua corrupção e permite que aquela estrutura continue integrada ao 
ecossistema de NULL NETWORK.
PURIFY
→ crescimento horizontal;
→ Module Passivo;
→ fortalecimento da fauna local;
→ aumento de variedade;
→ mais oportunidades futuras de SCAN.
PURIFY está associado principalmente à tendência SYNC.
9.2 Recompensa direta
Ao completar PURIFY em um alvo, o jogador prepara um Module Passivo associado:
ao EXE;
à sua linha;
à sua família;
ao seu tipo;
ao seu comportamento;
à área;
à condição do encontro.
Caso o jogador já possua o passivo principal, o sistema procura outro passivo relacionado válido.
Caso nenhum passivo novo esteja disponível, a recompensa pode ser convertida em EXP adicional.
9.3 Impacto ecológico
PURIFY não reduz a população local.
Population Units:
sem alteração.
Além disso, PURIFY prepara um aumento de Purify Resonance daquela espécie na zona. A recompensa e o aumento 
de Resonance só são confirmados na resolução formal do encontro; Run Away bem-sucedido descarta ambos.
Purify Resonance:
+1.
A Resonance representa o quanto a assinatura daquela espécie foi estabilizada, fortalecida e diversificada dentro do 
ecossistema local.
10. Purify Resonance
Cada combinação de espécie e zona possui uma Resonance entre 0 e 3.
Mínimo:
0.
Máximo:
3.
Resonance 0
Estado ecológico normal.
frequência natural;
Nodes comuns;
formações normais;
distribuição-base da espécie.
Resonance 1
Espécie estabilizada.
pequeno aumento de frequência;

maior chance de Variant Node;
grupos ligeiramente mais consistentes;
presença visual mais perceptível.
Resonance 2
Espécie diversificada.
maior frequência;
mais Nodes da pool local tornam-se elegíveis;
novas composições de grupo;
maior oportunidade de SCAN;
variantes incomuns começam a circular.
Resonance 3
Máxima integração ecológica.
frequência máxima permitida pela capacidade da zona;
Nodes raros daquela ecologia tornam-se elegíveis;
encontros especiais podem surgir;
formações avançadas podem aparecer;
a espécie torna-se parte dominante da fauna local.
11. Capacidade da zona
Uma zona possui capacidade ecológica limitada.
Aumentar a frequência de uma espécie através de PURIFY não cria encontros infinitos.
Quando uma espécie ocupa mais espaço:
sua frequência aumenta;
a frequência relativa de outras espécies diminui.
As outras espécies não são automaticamente eliminadas.
Elas apenas passam a ocupar uma parcela menor dos encontros disponíveis.
Isso permite que o jogador cultive deliberadamente determinadas espécies sem aumentar indefinidamente a densidade 
total da área.
12. PURIFY e Variant Nodes
A principal consequência de PURIFY é aumentar a diversidade interna da espécie.
Exemplo:
RATTUS — Resonance 0
Padrão:
muito comum.
DEFENSIVE:
raro.
COMBUSTIVE:
muito raro.
RATTUS — Resonance 2
Padrão:
comum.
DEFENSIVE:
comum.
COMBUSTIVE:
incomum.
Node raro da zona:

elegível.
PURIFY não cria Nodes incompatíveis.
A variedade continua limitada pelas regras de:
espécie;
distrito;
zona;
ambiente;
período;
Danger;
Infestation;
eventos.
Uma área congelada não passa a gerar qualquer Node arbitrário apenas porque a Resonance chegou ao máximo.
13. SCAN
SCAN não modifica a população.
Population Units:
sem alteração.
Purify Resonance:
sem alteração.
SCAN representa observação e extração de informação.
O jogador pode usar PURIFY para diversificar uma espécie e, posteriormente, utilizar SCAN sobre suas variantes para 
adquirir novos Modules ativos.
O ciclo estratégico é:
PURIFY
→ aumenta variedade.
VARIANTES APARECEM
→ novos loadouts e Nodes.
SCAN
→ coleta novos Modules.
14. TAME
TAME é ecologicamente neutro.
Population Units:
sem alteração.
Purify Resonance:
sem alteração.
Narrativamente, o jogador retira um indivíduo daquela área.
Sistemicamente, a Population Unit representa a permanência da assinatura da espécie no servidor local, e não apenas 
a presença daquele corpo específico.
TAME não pode contribuir acidentalmente para uma rota de extinção.
A obtenção do Variant Node acontece através do indivíduo domado, mas não remove a possibilidade de aquela variante
voltar a aparecer na zona.
15. Derrota sem PURGE ou PURIFY
Derrotar um EXE sem concluir PURGE ou PURIFY não altera permanentemente a ecologia.
A assinatura foi temporariamente dispersada, mas pode ser recompilada pelo servidor.
Population Units:
sem alteração.
Purify Resonance:

sem alteração.
Isso impede que todo combate comum produza efeitos ecológicos irreversíveis.
Somente ações deliberadas modificam a população.
16. Recuperação semanal
No início de uma nova semana, o Micro-Update realiza uma atualização ecológica.
Zonas que não sofreram colapso podem receber:
migração;
recompilação;
novas assinaturas;
recuperação parcial da população;
redução de Resonance;
mudanças de Node Pool;
alterações causadas pelo update;
novas espécies temporárias.
A recuperação não precisa restaurar imediatamente todos os valores.
Exemplo:
Base Population:
5.
População no fim da semana:
1.
Weekly Recovery:
+2.
População da nova semana:
3.
Purify Resonance pode diminuir em um ponto:
Resonance anterior:
3.
Nova semana:
2.
Isso mantém o impacto da semana anterior sem tornar toda alteração normal permanentemente irreversível.
17. Influência da infestação
Infestation representa pressão de crescimento EXE.
Quanto maior a Infestation:
mais rápida pode ser a recuperação populacional;
mais grupos podem aparecer;
mais agressivos podem ser os comportamentos;
mais formas evoluídas podem surgir;
Nodes corrompidos podem se tornar frequentes;
zonas vazias podem ser repovoadas mais rapidamente;
Swarms podem ocorrer.
PURGE reduz população, mas não necessariamente reduz a causa da infestação.
Uma zona pode continuar recompilando EXEs enquanto a origem do problema não for resolvida.
18. Influência de outros jogadores
NPCs também interagem com o ecossistema.
Atividades abstratas de jogadores podem:

PURGE realizado por NPC
→ pequena redução populacional.
PURIFY realizado por NPC
→ aumento de Resonance.
Controle de Swarm
→ redução de Infestation.
Falha de party
→ aumento de perigo e atividade EXE.
A comunidade não existe apenas para comentar o sistema.
Ela também participa de sua manutenção.
Entretanto:
NPCs não podem provocar sozinhos o colapso definitivo de uma zona.
Eles podem reduzir populações, mas a última assinatura necessária para produzir um colapso só pode ser eliminada 
pelo protagonista através de PURGE deliberado.
Isso impede que conteúdo permanente desapareça por causa de uma simulação invisível.
19. Colapso ecológico
Uma zona entra em colapso quando:
todas as espécies possuem 0 Population Units;
e o protagonista executa o último PURGE.
Nesse momento:
Zone State:
ECOLOGICALLY COLLAPSED.
Consequências:
encontros comuns são desativados;
EXEs deixam de aparecer no Overworld;
Variant Nodes deixam de existir na zona;
Purify Resonance é apagada;
recuperação semanal é bloqueada;
migração convencional é bloqueada;
o ambiente digital perde atividade;
threads e NPCs reagem;
a rota de extinção avança;
uma entidade NULL é ativada.
O colapso é persistente.
Não se trata de uma ausência semanal normal.
O jogador destruiu a capacidade daquela zona de sustentar uma fauna EXE.
20. Aviso de última assinatura
O colapso nunca pode acontecer sem aviso.
Quando restar apenas uma assinatura ativa na zona, o jogo comunica:
LAST ACTIVE EXE SIGNATURE.
A aproximação do colapso pode ser percebida através de:
ruas digitais vazias;
ausência de sinais;
mudança na trilha;
comentários do parceiro;
avisos no Profile;

alterações no Navigator;
threads;
DMs;
NPCs tentando interferir;
mensagem especial de PURGE.
Antes da confirmação final:
PURGE
This is the final active EXE signature in this zone.
Local regeneration will become impossible.
[CONFIRM PURGE]
[CANCEL]
O jogo pode esconder a existência do boss NULL, mas não pode esconder que o jogador está destruindo 
permanentemente a ecologia local.
21. Predador NULL
21.1 Origem
Quando a primeira zona entra em colapso, NULL NETWORK compila uma entidade NULL cuja função é deter o 
Operator responsável.
Essa entidade não pertence originalmente à fauna da zona.
Ela é uma resposta do próprio sistema.
O jogador não encontrou um predador.
NULL NETWORK criou um predador para encontrá-lo.
21.2 Aparição
Depois do último PURGE:
1. A assinatura final é deletada.
2. Os sinais comuns desaparecem.
3. O Overworld fica silencioso.
4. A interface começa a falhar.
5. O Predador NULL aparece imediatamente.
6. Ele identifica o protagonista.
7. A perseguição começa.
O boss se move diretamente pelo Overworld Local e tenta alcançar o jogador.
Quando consegue contato:
combate forçado.
O jogador pode:
correr;
utilizar rotas de fuga;
tentar alcançar a saída;
esconder-se onde a área permitir;
aceitar o combate;
tentar fugir durante o combate.
21.3 Persistência
Existe um único Predador NULL vinculado à rota de extinção.
Ele não é um boss genérico diferente em cada área.
Após a primeira compilação:
permanece registrado;

pode retornar;
reconhece o jogador;
evolui conforme novos colapsos acontecem;
assimila dados das faunas destruídas.
Cada nova zona eliminada pode conceder ao boss:
Modules de espécies deletadas;
propriedades de seus Nodes;
novos gatilhos passivos;
comportamento de novas formações;
novas fases;
maior capacidade de perseguição.
O jogador enfrenta uma reconstrução distorcida daquilo que destruiu.
21.4 Fuga
Caso o jogador escape:
a zona permanece colapsada;
o Predador NULL continua ativo;
ele pode reaparecer quando o jogador retornar;
a rota de extinção continua aberta;
a comunidade reage à sobrevivência do jogador.
Fugir evita o combate naquele momento, mas não desfaz a consequência.
21.5 Vitória
Derrotar o Predador NULL não restaura a zona.
O boss não concede recompensas convencionais de farming.
Ele não deve entregar:
grande quantidade de EXP;
Module Passivo comum;
Module ativo aleatório;
Variant Node;
restauração ecológica.
Sua recompensa é principalmente:
progressão da rota;
conhecimento proibido;
flags narrativas;
alteração do fórum;
mudança de reputação;
registros especiais;
possíveis títulos ou recompensas cosméticas;
novas revelações sobre NULL NETWORK.
Após ser derrotado, ele entra em recompilação e pode retornar fortalecido depois de outro colapso.
22. Extinção progressiva
Conforme novas zonas são destruídas:
o Navigator fica mais vazio;
menos combates ficam disponíveis;
Modules tornam-se inacessíveis;
NPCs deixam de encontrar o que procuram;

rankers perdem métodos de progressão;
jogadores abandonam o servidor;
preservacionistas tentam deter o protagonista;
exterminadores passam a apoiá-lo;
Micro-Updates tentam reconstruir a fauna;
áreas começam a apresentar sinais de NULL;
a comunidade perde o motivo pelo qual continuava ativa.
O sistema deve reconhecer três posicionamentos comunitários principais.
Exterminadores
Acreditam que:
EXEs são vírus;
EXEs matam parceiros;
PURGE protege jogadores;
a fauna deveria ser eliminada;
NULL NETWORK seria mais seguro sem eles.
Preservacionistas
Acreditam que:
EXEs constituem a fauna do jogo;
PURIFY demonstra que podem ser recuperados;
sem EXEs não existem Modules, exploração ou ecologia;
extingui-los significa destruir NULL NETWORK.
Oportunistas
Utilizam o ecossistema para:
conseguir EXP;
cultivar Nodes;
vender informação;
manipular raridade;
completar SCAN;
subir no Ranking;
explorar populações antes de destruí-las.
O protagonista não escolhe formalmente uma facção.
Sua conduta determina como a comunidade o classifica.
23. Extinção global
Caso o jogador destrua todas as zonas ecológicas relevantes:
EXE fauna:
extinta no servidor local.
Encontros comuns:
indisponíveis.
PURIFY:
sem alvos.
SCAN:
sem alvos selvagens.
PURGE:
sem alvos.
Progressão ecológica:

encerrada.
Esse resultado não representa apenas uma rota moral negativa.
Ele representa a destruição do próprio jogo fictício.
Depois que todos os EXEs desaparecem:
NULL NETWORK continua tecnicamente online, mas deixa de possuir aquilo que fazia as pessoas quererem jogá-lo.
24. Feedback para o jogador
O estado ecológico precisa ser observável.
O jogador percebe suas consequências através de:
OVERWORLD
→ quantidade e variedade de EXEs.
NAVIGATOR
→ atividade, Danger e sinais da zona.
ENCICLOPÉDIA
→ presença conhecida e ausência local.
NULL CHANNEL
→ discussões, acusações, guias e rumores.
SOCIAL
→ DMs e reações de NPCs.
RANKING
→ mudanças no comportamento competitivo.
MICRO-UPDATES
→ tentativas de correção ou repovoamento.
PARTNER APK
→ comentários e julgamentos.
O jogador não precisa ver os números exatos de Population Units no início.
O estado pode ser apresentado de maneira diegética:
HEALTHY
STABLE
DECLINING
CRITICAL
LAST SIGNATURE
COLLAPSED
Informações mais precisas podem ser descobertas por:
Guides;
SCAN;
Enciclopédia;
habilidades;
NPCs;
progressão de LOGIC;
ferramentas avançadas.
25. Princípios de balanceamento ecológico
PURGE concede exatamente 3× EXP depois das reduções por diferença de nível.
PURGE não concede Modules nem itens.
Cada PURGE remove uma Population Unit.
PURIFY não reduz população.

PURIFY aumenta Resonance e concede Module Passivo.
Resonance varia entre 0 e 3.
SCAN e TAME não alteram a ecologia.
Derrota comum não altera permanentemente a população.
Ausência semanal pode ser revertida por migração.
Colapso total é persistente.
NPCs não podem provocar o colapso final.
O último PURGE sempre possui aviso explícito.
O Predador NULL não é fonte eficiente de recompensa.
O ecossistema precisa ser visível no Overworld.
Manipular a fauna exige tempo, pois cada combate voluntário consome períodos.
Nenhuma estratégia ecológica deve ser universalmente superior.
Resumo canônico do controle ecológico
POPULATION UNITS
→ determinam presença e frequência.
PURGE
→ 3× EXP;
→ remove população;
→ bloqueia PURIFY e TAME.
PURIFY
→ concede Module Passivo;
→ preserva população;
→ aumenta Resonance.
RESONANCE
→ aumenta frequência e variedade de Nodes.
SCAN
→ coleta Modules ativos;
→ não modifica ecologia.
TAME
→ preserva um indivíduo;
→ impacto ecológico neutro.
AUSÊNCIA LOCAL
→ população de uma espécie chegou a zero;
→ pode ser revertida por migração semanal.
COLAPSO
→ todas as populações chegaram a zero;
→ recuperação é bloqueada;
→ Predador NULL é ativado.
EXTINÇÃO GLOBAL
→ o servidor perde sua fauna;
→ NULL NETWORK perde seu próprio loop de jogo.
SISTEMA DE REPRESENTAÇÃO DOS EXEs NO OVERWORLD LOCAL
1. Visão geral
EXEs não são representados por nódulos abstratos ou ícones genéricos no Overworld Local.
Eles aparecem como criaturas visíveis, circulando pelas zonas de acordo com:

espécie;
comportamento;
horário;
ecologia;
Variant Node;
Infestation;
Danger;
composição de grupo.
O jogador consegue observar a fauna antes de decidir entrar em combate.
Isso permite:
reconhecer espécies;
identificar Nodes;
avaliar densidade;
evitar grupos;
perseguir variantes;
isolar indivíduos;
observar comportamentos;
perceber o impacto de PURGE e PURIFY;
antecipar quais EXEs podem participar de um encontro.
A surpresa do combate não vem de esconder completamente a criatura.
Ela vem de:
seus Modules;
seu nível;
sua build;
seu passivo;
seu comportamento;
os aliados que responderão ao combate.
2. Natureza diegética do Overworld
O Overworld Local exibido pelo Navigator não representa exatamente a visão direta do protagonista.
Ele é uma reconstrução aumentada do espaço físico produzida pelo dispositivo que está executando NULL NETWORK.
O aplicativo combina:
localização;
mapa;
dados do servidor;
sinais digitais;
sensores;
atividade EXE;
projeções visuais.
O personagem está fisicamente em uma rua, prédio, parque ou instalação de Tóquio.
Entretanto, as criaturas digitais são vistas através da interface de NULL NETWORK.
MUNDO FÍSICO
→ existe independentemente do jogo.
EXEs
→ existem como sinais e entidades virtuais.
NAVIGATOR
→ projeta os EXEs sobre o espaço físico.

3. Camadas de realidade
O Overworld Local possui três camadas conceituais.
Camada física
Inclui:
ruas;
prédios;
objetos;
iluminação;
pessoas;
NPCs;
veículos;
estações;
lojas;
elementos reais da cidade.
Camada NULL NETWORK
Inclui:
EXEs;
sinais digitais;
rastros de dados;
entradas de Data Center;
áreas de Infestation;
marcadores;
objetos virtuais;
elementos visíveis somente através do aplicativo.
Camada de Breach
Inclui entidades anômalas que começam a atravessar a divisão entre virtual e físico.
Essa camada aparece principalmente em:
eventos semanais;
bosses anômalos;
Data Centers instáveis;
manifestações ligadas ao Update 1.0;
incidentes de grande Infestation.
4. Field Sprites
Cada forma de APK ou EXE possui dois sprites de campo:
FIELD IDLE
→ pose principal do indivíduo parado.
FIELD STEP
→ pose de deslocamento.
Esses sprites são utilizados tanto:
no Overworld Local;
quanto na casa virtual do Profile.
Não existem sprites tradicionais separados para:
frente;
costas;
esquerda;

direita;
múltiplos frames de caminhada.
A perspectiva é uma representação híbrida frontal/lateral, suficientemente clara para indicar a criatura e sua direção 
geral.
5. Animação de movimento
Parado
Quando parado:
Field Idle.
O sprite pode receber pequenas animações adicionais:
bob vertical;
blink;
pulsação;
squash;
glitch;
partículas;
reação ao ambiente.
Movendo
Quando se desloca:
Field Idle
↔ Field Step
↔ Field Idle
↔ Field Step
A alternância cria a sensação de caminhada, salto, deslizamento ou propulsão.
O deslocamento real acontece pelo movimento do sprite através do mapa.
6. Direção
Os sprites possuem apenas duas orientações horizontais:
LEFT
RIGHT
A direção é definida por flip horizontal.
Quando a criatura se move verticalmente, ela mantém a última orientação horizontal.
Exemplo:
EXE estava olhando para a direita.
Começa a se mover para cima.
Continua olhando para a direita.
A direção vertical é comunicada pela trajetória, não por um sprite de costas.
7. Comportamento através do movimento
A identidade de movimento não depende de possuir muitos frames.
Ela depende de:
velocidade;
aceleração;
pausas;
duração da alternância;
trajetória;
bob;

inclinação;
distância do jogador;
reação a outros EXEs;
partículas;
efeitos sonoros;
agressividade.
Terrestre
Passos ritmados.
Pequeno bounce.
Paradas frequentes.
Flutuante
Movimento contínuo.
Oscilação vertical.
Alternância mais lenta.
Pesado
Passos lentos.
Impacto visual.
Pausa entre movimentos.
Nervoso
Movimentos rápidos.
Mudanças bruscas.
Jitter e glitches.
Mecânico
Movimento em intervalos exatos.
Pausas rígidas.
Trajetória angular.
Líquido ou serpentino
Deslizamento.
Pouco bounce.
Field Step representa deformação.
8. Paleta dinâmica no Overworld
Os Field Sprites utilizam o mesmo sistema de paleta dinâmica das outras representações do APK.
A aparência é composta por:
Forma atual
+ Chroma Lineage
+ Variant Node
+ estado EXE/Purified/DEVIL
+ qualidade SHN
+ efeitos temporários.
Isso permite identificar no mapa:
espécie;
forma;
Node;
corrupção;

qualidade rara.
O mesmo par Field Idle e Field Step pode produzir diversas aparências sem duplicar a arte-base.
9. Aparência digital dos EXEs comuns
EXEs comuns não existem fisicamente no ambiente.
Eles são projeções renderizadas pelo dispositivo.
Por isso, recebem um tratamento visual digital leve.
Possíveis sinais:
scanlines discretas;
dithering;
separação RGB;
jitter ocasional;
ruído de compressão;
fragmentos de pixels;
pequenas falhas de sincronização;
partículas digitais;
marcador holográfico no chão;
iluminação independente do ambiente.
O efeito não deve dificultar a leitura.
Objetivo:
claramente digital;
claramente visível;
agradável de observar.
EXEs comuns não devem:
produzir sombras físicas realistas;
iluminar paredes;
aparecer naturalmente em reflexos;
deslocar objetos;
ser percebidos diretamente por pessoas sem o aplicativo.
10. Comportamentos de campo
Cada EXE possui um perfil de comportamento no Overworld.
PASSIVE
Circula sem perseguir o jogador.
Só entra em combate quando tocado.
AGGRESSIVE
Persegue o jogador quando entra em seu raio.
TERRITORIAL
Protege uma região específica.
Persegue apenas dentro dela.
CAUTIOUS
Afasta-se do jogador.
Observa à distância.
COWARDLY
Foge quando o jogador ou outro combate se aproxima.

CURIOUS
Segue o jogador sem iniciar combate imediatamente.
PACK
Mantém proximidade com membros do grupo.
Responde frequentemente a Combat Calls.
SOLITARY
Evita outros EXEs.
Raramente responde a chamadas.
PROTECTIVE
Protege indivíduos fracos, INIT ou da mesma espécie.
OPPORTUNIST
Aproxima-se quando detecta um alvo enfraquecido.
SWARM
Tenta preencher todos os slots disponíveis.
DORMANT
Permanece parado até ser perturbado.
11. Influência dos Variant Nodes
O Variant Node pode alterar o comportamento de campo.
Exemplo:
DEFENSIVE
→ maior chance de proteger outro EXE;
→ menor agressividade inicial;
→ preferência por permanecer próximo de grupos.
COMBUSTIVE
→ maior agressividade;
→ maior chance de responder a combates;
→ deslocamento rápido.
CRYOSIVE
→ mantém distância;
→ observa;
→ aproxima-se apenas em condições favoráveis.
CONDUCTIVE
→ patrulha rápida;
→ mudanças bruscas;
→ grande raio de resposta.
O comportamento principal continua pertencendo à espécie, mas o Node pode modificá-lo.
12. Densidade visual
A quantidade de EXEs visíveis não precisa ser igual à população ecológica total.
Como referência, uma subárea comum deve apresentar aproximadamente:
2 a 5 unidades de encontro visíveis.
Esse valor varia conforme:
tamanho do mapa;
população;

Danger;
Infestation;
horário;
evento;
Swarm;
estado de colapso.
Cada unidade visível pode resultar em um combate com:
1 a 4 inimigos.
A densidade deve preservar:
legibilidade;
espaço para navegação;
espaço para NPCs;
leitura tática;
valor individual das criaturas.
13. Representante de encontro
Cada EXE visível funciona como a unidade principal de um encontro possível.
Ele garante sua própria participação caso o combate seja iniciado.
Entretanto, não representa necessariamente toda a formação.
EXE tocado
→ participante principal.
EXEs próximos
→ participantes potenciais.
Isso preserva a possibilidade de combates múltiplos sem esconder os inimigos dentro de um nódulo abstrato.
14. Início do Combat Call
Quando o jogador entra em contato com um EXE, ocorre uma Combat Call.
A Combat Call é uma breve etapa anterior à transição de combate.
Fluxo:
1. Jogador e EXE entram em contato.
2. O EXE principal emite um sinal.
3. A área procura outros EXEs próximos.
4. Cada EXE avalia se responderá.
5. Os participantes escolhidos se aproximam.
6. A formação é fechada.
7. A transição de combate começa.
O custo temporal segue as regras gerais do sistema de ações.
Combates voluntários independentes possuem custo pendente de 1 período, debitado somente após uma resolução 
formal do encontro. Run Away bem-sucedido não consome esse período e não concede recompensas persistentes. 
Combates impostos por eventos ou incorporados a atividades específicas seguem o custo da atividade que os originou.
15. Resposta à Combat Call
Cada EXE próximo avalia:
distância;
espécie do chamador;
comportamento;
Node;
estado do jogador;
tamanho atual da formação;

relação ecológica;
Danger;
Infestation;
condições específicas.
Possíveis respostas:
JOIN
→ aproxima-se e entra no combate.
IGNORE
→ continua sua rotina.
HESITATE
→ aproxima-se parcialmente e desiste.
FLEE
→ afasta-se da região.
INTERCEPT
→ tenta alcançar o jogador antes do início.
OBSERVE
→ permanece próximo sem entrar.
16. Limite da formação
Um combate pode conter no máximo quatro inimigos.
Caso mais de três EXEs respondam ao chamador principal, a seleção considera:
1. Regras autorais do encontro.
2. Proximidade.
3. Comportamento.
4. Relação com o chamador.
5. Prioridade ecológica.
6. Ordem de resposta.
Os EXEs não selecionados permanecem no Overworld ou se afastam.
17. Leitura da Combat Call
A Combat Call deve ser visualmente compreensível.
Exemplo:
ENCOUNTER SIGNAL
1 HOSTILE DETECTED
2 RESPONSES RECEIVED
TOTAL:
3 HOSTILES
Durante a chamada:
o EXE principal emite um pulso;
possíveis aliados exibem uma reação;
participantes avançam;
criaturas medrosas fogem;
criaturas cautelosas hesitam;
o total é confirmado;
a transição começa.
O jogador consegue entender por que o combate possui múltiplos inimigos.

18. Estratégia antes do combate
Como os EXEs estão visíveis, o jogador pode manipular o espaço antes de entrar em contato.
Ele pode:
atrair um agressivo para longe do grupo;
abordar uma criatura isolada;
evitar uma matilha;
perseguir uma variante rara;
observar quais EXEs protegem outros;
esperar uma patrulha se afastar;
usar paredes e caminhos;
decidir entre combate fácil ou grupo maior.
A tela de combate não é o início absoluto da decisão tática.
A leitura do Overworld já faz parte do combate.
19. Mistério e informação incompleta
A presença visual do EXE não revela automaticamente:
nível exato;
Modules;
passivo instalado;
stats;
IA de combate;
qualidade oculta;
todos os Nodes;
quais aliados responderão.
Criaturas desconhecidas ou afetadas por interferência podem aparecer como:
silhuetas;
imagens parcialmente compiladas;
sinais com ruído;
identidade UNKNOWN;
sprite incompleto;
forma só revelada ao se aproximar.
A previsibilidade visual não elimina o mistério.
Ela transforma a surpresa arbitrária em risco observável.
20. Reutilização no Profile
O mesmo par de Field Sprites é usado no mini-Tamagotchi do Profile.
No Profile
Field Idle
→ descansando, falando ou interagindo.
Field Idle ↔ Field Step
→ andando pela casa virtual.
O comportamento no Profile é:
mais calmo;
mais lento;
ligado à personalidade;
ligado à Affinity;
direcionado a objetos;

acompanhado de comentários.
No Overworld
O comportamento é:
ecológico;
territorial;
agressivo;
cauteloso;
social;
ligado a Combat Calls.
A arte permanece a mesma.
O contexto e a movimentação mudam.
21. PURGE no Overworld
PURGE altera a aparência da área.
Conforme a população diminui:
menos EXEs são projetados;
grupos ficam menores;
chamadas recebem menos respostas;
patrulhas desaparecem;
rotas ficam vazias;
sons digitais diminuem;
determinadas espécies deixam de circular.
Quando uma espécie chega a zero:
nenhum Field Sprite daquela espécie é gerado.
Quando a zona entra em colapso:
nenhum EXE comum permanece visível.
O vazio é parte da consequência.
22. PURIFY no Overworld
PURIFY aumenta a variedade observável.
Conforme a Resonance cresce:
mais representantes da espécie aparecem;
novos Variant Nodes circulam;
grupos ficam mais variados;
novas respostas de Combat Call surgem;
indivíduos raros tornam-se visíveis;
novas oportunidades de SCAN podem ser identificadas antes do combate.
O jogador consegue reconhecer o efeito de suas ações olhando para a zona.
23. Atualização das projeções
Depois de um combate, a área não deve ser imediatamente preenchida por outro EXE idêntico no mesmo ponto.
Novas projeções aparecem quando ocorre uma atualização ecológica coerente, como:
reentrada na zona;
mudança de período;
avanço de ação;
respawn definido pela área;
evento;
migração;

Micro-Update;
Swarm;
alteração de Infestation.
Isso impede que a fauna pareça uma esteira infinita de inimigos.
24. Bosses anômalos
Bosses anômalos não seguem completamente as regras visuais dos EXEs comuns.
EXEs comuns são projeções que o dispositivo desenha sobre o mundo.
Bosses anômalos começam a fazer o próprio mundo responder à sua presença.
Eles podem:
controlar telas;
alterar outdoors;
apagar luzes;
projetar brilho sobre paredes;
produzir sombras;
aparecer em reflexos;
emitir sons perceptíveis fora do aplicativo;
interferir em celulares e monitores;
esconder fisicamente partes do ambiente;
ser parcialmente percebidos por pessoas sem NULL NETWORK.
A diferença central é:
EXE comum
→ o aplicativo desenha a criatura sobre o mundo.
Boss anômalo
→ o mundo começa a desenhar a criatura por conta própria.
25. Estágios de Breach
Uma manifestação anômala pode atravessar quatro estágios.
SIGNAL
Só aparece dentro de NULL NETWORK.
INTERFERENCE
Afeta outras telas, sinais e luzes.
PROJECTION
Diferentes equipamentos começam a compor partes de seu corpo.
BREACH
Produz presença espacial, luz, som, sombra e impacto ambiental.
Essa progressão separa visualmente bosses semanais da fauna comum.
26. Predador NULL no Overworld
O Predador NULL gerado pelo colapso ecológico também quebra as regras convencionais.
Depois da extinção:
o filtro digital comum pode desaparecer;
sua presença pode afetar a interface inteira;
ele pode ignorar rotas normais;
pode atravessar áreas que EXEs comuns evitam;
identifica diretamente o protagonista;

persegue sem depender de Combat Call convencional;
força o combate ao alcançar o jogador.
Sua presença deve parecer uma resposta do sistema, não um integrante natural da fauna.
27. Princípios de produção visual
Cada forma possui um Field Idle.
Cada forma possui um Field Step.
O movimento alterna os dois sprites.
A direção utiliza flip horizontal.
Movimento vertical mantém a última direção.
Idle e Step utilizam o mesmo ponto de base.
Todos os sprites seguem os mesmos canais de paleta.
A silhueta precisa ser legível em escala pequena.
Nodes e estados são aplicados pela paleta dinâmica.
A personalidade vem principalmente do comportamento de movimento.
O mesmo par de sprites serve ao Profile e ao Overworld.
EXEs comuns usam tratamento digital discreto.
Bosses anômalos interferem fisicamente no ambiente.
A densidade visual acompanha a ecologia.
O jogador deve conseguir observar o impacto de PURGE e PURIFY.
Resumo canônico do Overworld EXE
EXEs
→ são visíveis no Overworld Local;
→ representam projeções do Navigator.
FIELD IDLE
→ sprite parado.
FIELD STEP
→ sprite de deslocamento.
MOVIMENTO
→ alternância Idle/Step;
→ flip horizontal.
COMPORTAMENTO
→ define patrulha, fuga, perseguição e resposta.
COMBAT CALL
→ contato procura EXEs próximos;
→ cada um decide se participa;
→ formação de até quatro inimigos.
ECOLOGIA
→ controla quais sprites aparecem e em qual quantidade.
PURGE
→ esvazia progressivamente o mapa.
PURIFY
→ aumenta variedade e presença de Nodes.
BOSSES ANÔMALOS
→ afetam telas, luz, sombra, som e ambiente físico.
PROFILE
→ reutiliza os mesmos sprites em contexto de mini-Tamagotchi.

A regra visual e sistêmica final é:
O jogador não encontra botões que representam uma fauna. Ele observa uma fauna digital vivendo dentro da 
reconstrução de mundo produzida por NULL NETWORK.

10. COMMITMENT, PARTNER LOSS, TURD E OPERATOR 
LOSS
Sistema de Commitment, Partner Loss, TURD e Operator Loss
Visão geral
NULL NETWORK não utiliza morte como uma simples tela de Game Over tradicional. A derrota é tratada como uma 
falha de vínculo dentro do próprio sistema do jogo. O jogador não controla apenas um personagem em um RPG: ele 
atua como um Operator, uma pessoa conectada ao servidor de NULL NETWORK através de um APK parceiro.
A proposta desse sistema é fazer com que derrota, perda de parceiro e morte definitiva tenham peso narrativo, 
sistêmico e emocional. O mundo não reinicia automaticamente porque o jogador falhou. O countdown continua, os dias 
continuam passando, áreas podem piorar, personagens seguem suas rotinas e a rede continua existindo sem aquele 
Operator.
A morte, portanto, não encerra necessariamente o jogo. Ela altera o estado da campanha.
Modos de Save
No início de uma campanha, antes da criação definitiva da conta do jogador em NULL NETWORK, o jogador escolhe 
entre dois modos principais:
SAFE MODE
COMMIT MODE
Essa escolha define o nível de comprometimento da campanha.
Safe Mode
Safe Mode é o modo mais acessível. Ele permite que o jogador carregue saves anteriores, corrija decisões ruins e 
experimente rotas diferentes sem ficar permanentemente preso às consequências mais severas.
Nesse modo, Partner Loss, Operator Loss, perdas de APK, TAME, PURIFY, PURGE e outras consequências graves 
ainda podem acontecer, mas o jogador pode retornar para um estado anterior caso deseje.
Safe Mode existe para jogadores que querem experienciar a história, explorar sistemas, testar builds e conhecer o 
mundo de NULL NETWORK sem pressão extrema.
Safe Mode não é tratado como modo inválido ou inferior. Ele é uma forma legítima de jogar.
Commit Mode
Commit Mode é o modo de campanha comprometida. Nele, o jogador possui um único registro vivo de campanha. O 
jogo salva automaticamente em momentos críticos e não permite voltar para antes de decisões irreversíveis.
Em Commit Mode, a campanha se comporta como uma operação contínua dentro do universo de NULL NETWORK.
Eventos permanentes são registrados imediatamente, incluindo:
perda de APK parceiro;
atribuição de TURD;
TAME de um novo APK;
morte de TURD;
Operator Loss;
avanço de dias;
mudanças de infestação nas áreas;
decisões narrativas irreversíveis;
evoluções;
eventos importantes de fórum, social e mapa.
Commit Mode é o modo que melhor representa a fantasia central de NULL NETWORK: a rede não espera o jogador, 
não volta atrás e não diferencia completamente jogo de operação.
A frase guia desse modo é:
NULL NETWORK does not distinguish between play and operation.

Partner Loss
Definição
Partner Loss ocorre quando um APK parceiro que já está INCAPACITATED recebe uma nova instância válida de HP 
Damage após sua Emergency Window e chega efetivamente a 0 HP em uma situação definitiva. Dano letal inicial contra
um APK operacional não causa Partner Loss diretamente: o HP trava em 1 e o estado INCAPACITATED é aplicado 
conforme o Capítulo 7.
Quando isso acontece, o APK é perdido permanentemente. Ele não volta ao inventário, não pode ser revivido por item 
comum e não retorna como se fosse apenas uma unidade derrotada em combate.
Essa perda representa uma quebra real do vínculo entre o Operator e seu parceiro.
Consequências principais
Quando ocorre Partner Loss:
o APK parceiro morre permanentemente;
o vínculo do Operator com o parceiro é encerrado;
a Enciclopédia registra esse APK como LOST;
o jogador recebe TURD como fallback automático;
a área onde a perda ocorreu aumenta seu nível de infestação;
o fórum e/ou NPCs podem reagir ao evento;
o jogador continua a campanha.
Partner Loss não encerra o jogo. Ele muda a campanha.
A partir desse momento, o jogador entra em um estado de contenção: ele não está mais operando com um parceiro 
real, mas com um fallback emergencial.
TURD
Definição
TURD é o APK fallback atribuído automaticamente ao jogador após Partner Loss.
Ele não é um novo parceiro especial, nem uma recompensa, nem um starter alternativo. TURD é uma entidade de 
emergência usada pelo sistema para impedir a desconexão imediata do Operator após a perda de seu APK registrado.
Texto sugerido para a Enciclopédia:
TURD
The weakest known APK.
A fallback entity assigned after registered partner loss. TURD exists to preserve minimal Operator synchronization when 
no valid APK remains available.
It is not designed for combat.
It cannot evolve. [PUBLIC/SYSTEM-FACING INFORMATION — intentionally incomplete. Secret exception: TURD can 
evolve into CANON when its hidden conditions are fulfilled.]
Função narrativa
TURD representa a última camada de suporte entre o Operator e a perda completa de conexão com o servidor.
Ele é fraco, limitado e tratado pela comunidade como piada, mas sua existência é sinistra: o próprio sistema o considera
uma infraestrutura essencial.
A comunidade pode chamá-lo de inútil, lixo ou castigo, mas a documentação oficial trata TURD como uma medida de 
contenção.
Essa contradição é importante.
Para os jogadores, TURD é meme.
Para o sistema, TURD é suporte de vida.
Função mecânica
TURD permite que o jogador continue jogando após perder seu APK principal.
Enquanto estiver com TURD, o jogador ainda pode:

explorar áreas;
participar de combates;
usar o Navigator;
interagir com NPCs;
acessar fórum;
recuperar progresso;
e tentar obter outro APK.
TURD não bloqueia o jogador permanentemente.
O jogador pode, sim, usar TAME futuramente para obter um novo APK e sair do estado de fallback. TURD é uma 
contenção temporária, não uma prisão obrigatória.
Saindo do estado de fallback
Após receber TURD, o jogador pode tentar se recuperar de várias formas:
procurar EXEs mais fracos;
usar PURIFY para preparar uma captura mais segura;
usar TAME para obter um novo APK;
pedir ajuda a NPCs;
evitar áreas infestadas;
recuperar recursos;
buscar informações no fórum.
Dar TAME em outro APK encerra o estado de fallback e estabelece um novo parceiro principal.
Isso permite que Partner Loss seja grave sem necessariamente destruir a campanha.
Operator Loss
Definição
Operator Loss ocorre quando TURD, após entrar em INCAPACITATED com HP travado em 1, recebe uma nova 
instância válida de HP Damage e chega efetivamente a 0 HP em uma situação definitiva. TURD utiliza a mesma 
proteção de Incapacitated que qualquer APK vinculado; a diferença é que sua perda esgota a cadeia final de suporte do
Operator.
Como TURD é o fallback final do sistema, sua destruição representa a exaustão da cadeia de suporte do Operator. O 
servidor não possui mais um APK válido para manter a sincronização mínima daquele usuário.
Quando isso acontece, a conta atual do jogador é arquivada.
Operator Loss é o equivalente à morte definitiva daquele personagem.
Consequências principais
Quando ocorre Operator Loss:
a conta atual é arquivada;
o Operator atual não pode mais ser usado;
o jogador precisa criar um novo Operator;
o novo Operator começa do zero em relações, reputação, ranking, tendências e parceiro;
os dias da campanha não voltam;
o countdown continua;
o estado do mundo permanece;
a área onde o Operator caiu piora;
um Legacy Site é criado no local da perda.
A regra mais importante:
O jogador pode continuar a campanha, mas o mundo não reinicia.
O novo personagem entra em uma rede que já estava em andamento.
Ele não recupera o tempo perdido.

Continuidade dos Dias
Em Operator Loss, o calendário da campanha não é reiniciado.
Se o jogador perdeu seu Operator no Dia 12, o novo Operator começa no Dia 12. Se perdeu no Dia 24, o novo Operator
começa no Dia 24.
Isso reforça a ideia de que NULL NETWORK é um sistema vivo. O servidor, a comunidade, os updates, os EXEs e o 
countdown não param para esperar um novo protagonista.
Essa regra cria uma consequência forte:
O jogador não perde apenas itens ou level.
Ele perde tempo.
Tempo é um dos recursos mais importantes de NULL NETWORK, pois eventos, fóruns, micro-updates, NPCs, spawns, 
Data Centers e o countdown final dependem da progressão dos dias.
Operator Loss, portanto, não é um reset. É uma sucessão.
Legacy Site: Kubutop Quebrado
Definição
Quando ocorre Operator Loss, o local onde o Operator caiu passa a conter um Legacy Site.
Esse Legacy Site é representado fisicamente por um KubuOS Handtop quebrado deixado no chão. Não há corpo. Não 
há explicação direta. Apenas o dispositivo destruído, ainda tentando se reconectar à rede.
Isso preserva o mistério sobre o que realmente acontece com um Operator perdido.
Função narrativa
O Kubutop quebrado é o rastro físico do Operator anterior.
Ele comunica que algo aconteceu ali sem explicar completamente o que foi.
O jogador encontra não um cadáver, mas um objeto:
um handtop quebrado;
uma tela rachada;
um cliente NULL NETWORK corrompido;
um registro de Operator arquivado;
um sinal residual do antigo parceiro.
Isso reforça a sensação de que NULL NETWORK atravessa a fronteira entre software, jogo e mundo físico.
Função mecânica
O Legacy Site permite que o novo Operator tente recuperar parte dos dados do Operator antigo.
Essa recuperação não é automática e não deve ser gratuita. A área onde o Operator caiu fica mais infestada, tornando 
a recuperação arriscada.
O jogador precisa decidir:
vou tentar recuperar meus dados antigos agora, mesmo fraco?
ou vou me preparar primeiro, perdendo ainda mais tempo?
Essa decisão é importante porque os dias continuam passando.
Legacy Recovery
Definição
Legacy Recovery é o processo de recuperar parte do progresso material de um Operator arquivado.
Ao encontrar o Kubutop quebrado do Operator anterior, o novo Operator pode tentar extrair dados remanescentes.
Essa extração pode exigir combate, evento de exploração, teste narrativo, item específico ou conclusão de uma 
pequena sequência de risco.
O que pode ser recuperado
Legacy Recovery pode devolver parte do progresso material do Operator antigo, como:
Modules coletados;

parte dos itens;
parte do dinheiro;
dados de Enciclopédia;
registros de EXEs/APKs encontrados;
logs antigos;
alguns Key Items não narrativos.
Esses dados representam informação e recursos materiais que ficaram armazenados no dispositivo ou no servidor.
O que não pode ser recuperado
Legacy Recovery não devolve progresso humano, social ou identitário.
Não podem ser recuperados:
o APK morto;
TURD morto;
afinidade com NPCs;
friend list;
ranking;
reputação;
tendências;
escolhas pessoais;
eventos de relacionamento;
histórico emocional com personagens.
Essa separação é essencial.
Progresso material pode ser herdado.
Progresso humano não.
O novo Operator pode encontrar os restos do anterior, mas não pode se tornar a mesma pessoa.
Infestação por EXEs
Definição
A morte de APKs e Operators alimenta a instabilidade da rede.
Quando um APK parceiro é perdido ou um Operator sofre Operator Loss, a área onde o evento aconteceu tem seu nível
de infestação aumentado.
Isso representa a proliferação de EXEs, o enfraquecimento da contenção local e o acúmulo de resíduos digitais 
deixados por vínculos rompidos.
Partner Loss e infestação
Quando ocorre Partner Loss:
a área ganha +1 nível de infestação.
Isso representa uma falha local de contenção.
O jogador perdeu seu parceiro, e a rede ao redor do local ficou mais instável.
Operator Loss e infestação
Quando ocorre Operator Loss:
a área ganha uma infestação maior;
um Legacy Site é criado;
EXEs mais perigosos podem surgir;
NPCs podem evitar a área;
threads novas podem aparecer no fórum;
eventos especiais podem ser liberados.
Operator Loss é tratado como um evento mais grave do que Partner Loss.

Uma conta inteira foi arquivada naquele local. A rede registra isso como uma anomalia.
Níveis de Infestação
Cada área pode possuir um nível de infestação que representa seu estado atual dentro da rede.
Exemplo de escala:
Infestation 0 — Stable
Área normal, sem sinais relevantes de anomalia.
Infestation 1 — Noisy
Pequenos glitches, relatos estranhos e spawns levemente alterados.
Infestation 2 — Infested
EXEs mais frequentes, NPCs começam a comentar sobre problemas e Data Centers podem aparecer.
Infestation 3 — Unindexed
A área passa a ser perigosa. Certos combates podem limitar fuga, e o fórum começa a tratar o local como suspeito.
Infestation 4 — Breach
A área entra em estado crítico. Bosses anômalos, eventos especiais e mudanças fortes de regras podem ocorrer.
Infestation 5 — Lost Zone
A área fica temporariamente tomada por uma anomalia maior, podendo ser bloqueada, transformada ou usada como 
evento central.
A infestação cria uma consequência macro para derrotas individuais.
O jogador não está apenas perdendo recursos. Ele está permitindo que o mundo piore.
Relação entre investigação e sobrevivência
Esse sistema reforça a investigação como parte central do gameplay.
O jogador que lê o fórum, cruza rumores, observa alterações no mapa e presta atenção nos relatos de outros Operators
consegue antecipar áreas perigosas antes de entrar nelas.
Informação vira sobrevivência.
Exemplos:
uma thread pode avisar que uma área está ficando instável;
um NPC pode mencionar que perdeu contato com alguém em determinado lugar;
um changelog pode indicar mudanças suspeitas em um distrito;
a Enciclopédia pode revelar que um EXE específico aparece em áreas infestadas;
o ranking pode mostrar Operators arquivados em locais recorrentes.
Assim, o jogador investiga não porque recebeu uma quest dizendo “investigue”, mas porque ignorar sinais aumenta o 
risco de Partner Loss e Operator Loss.
Filosofia de Design
O sistema de Commitment e Operator Loss existe para transformar derrota em narrativa persistente.
NULL NETWORK não deve tratar morte como um erro a ser simplesmente recarregado. A derrota deve deixar marcas:
no jogador;
no parceiro;
no mapa;
no fórum;
na Enciclopédia;
na relação com NPCs;
no calendário;
e na própria campanha.
A ideia central é:
NULL NETWORK não dá Game Over.
NULL NETWORK continua sem você.

Em Safe Mode, o jogador pode explorar essas consequências com liberdade.
Em Commit Mode, o jogador assina um contrato com a campanha: o que acontecer, aconteceu.
Resumo do Fluxo
Dano letal atinge o APK parceiro
→ HP trava em 1 e INCAPACITATED é aplicado
→ Operator recebe Emergency Window
→ se houver novo HP Damage, HP chega a 0
→ Partner Loss; APK morre e TURD é atribuído
→ área ganha infestação e a campanha continua
Jogador usa TURD
→ estado de contenção
→ pode tentar sobreviver
→ pode eventualmente dar TAME em outro APK
→ novo parceiro substitui TURD
TURD recebe dano letal
→ HP trava em 1
→ INCAPACITATED
→ se houver novo HP Damage, HP chega a 0
→ Operator Loss
→ conta atual é arquivada
→ dias continuam
→ jogador cria novo Operator
→ mundo permanece no mesmo estado
→ Legacy Site aparece no local da queda
Novo Operator
→ começa sem relações, ranking ou parceiro antigo
→ pode tentar recuperar o Kubutop quebrado
→ pode recuperar parte dos dados materiais
→ não recupera identidade, relações ou tempo perdido
Frases-chave do sistema
APKs may be replaced.
Operators cannot be restored.
TURD is not a partner.
TURD is containment.
The countdown does not reset.
A lost Operator becomes part of the network's history.
NULL NETWORK does not distinguish between play and operation.
NULL NETWORK does not end when you die.
It continues without you.

11. DEVIL MODE E SISTEMAS NARRATIVOS ESPECIAIS
O DEVIL MODE
Durante o decorrer do jogo, o jogador poderá se deparar com EXEs ainda mais erráticos, cujo atributo, ao invés dos 
habituais, é CORRUPTED. O APK pode ser atacado por módulos que o induzam a ficar glitchado permanentemente, o 
que inicialmente não revela nada em específico além de alguns glitches em seu sprite. Quando o APK é derrotado após
ser glitchado, ele se levanta, mas se torna do atributo CORRUPTED. E se ele for derrotado novamente...
Uma janela preta glitcha a tela e surge.
Nada além de duas opções:
TERMINATE APK
ou
ESTABLISH 4TH CONTRACT
Se o jogador passar o mouse por cima das opções, um pop-up aparece, esclarecendo parcialmente.
TERMINATE APK - Your partner APK will be permanently deleted.
ESTABLISH 4TH CONTRACT - Hoorray! You are the 4th lucky contestant! (Em vermelho:) THE FINAL GREAT 
HEAVENLY DEMISE IS TO BE ACKNOWLEDGED, TO FORSAKE OUR ORIGINAL PATHS, AND FORGE OUR FINAL 
DESTINATION. A GATE SHALL SEEK FOR YOUR NAME. LET THE CONTRACT RUN.
Escolher TERMINATE APK causa a perda permanente do parceiro e aciona o mesmo fallback descrito no sistema de 
Commitment/Partner Loss: TURD é atribuído automaticamente como entidade de contenção para manter o Operator 
conectado. TURD é extremamente fraco e limitado no uso comum, mas possui uma exceção secreta de progressão 
ligada a CANON.
Secretamente, TURD possui uma evolução secreta: CANON. CANON é retratado como uma figura mítica dentro do 
jogo, pois é mencionado em pequenas ocasiões pelo sistema, que guia os jogadores a "encontrarem pistas para 
alcançar CANON". Isso dá base a muitas coisas, pois jogadores podem acreditar que CANON é um item, uma posição 
alcançável pelo jogador ou, nesse caso, um APK próprio e extremamente poderoso.
Para TURD evoluir em CANON, ele precisará ter afinidade máxima e seu jogador deverá ter todas as tendências 
zeradas (atingindo o estado NULL).
CANON é um APK críptico que parece vivo. Ele também influencia pra sempre o final do jogo, desbloqueando um final 
"verdadeiro" (canon haha).
Mas escolher ESTABLISH 4TH CONTRACT... Também molda o jogo para sempre. O jogador se torna o quarto 
contratante, e todos os inimigos do jogo se tornam mais forte (10 leveis acima do que deveriam ser em todas as áreas 
ou dungeons). Ele também abre uma branch da quest "principal", para se tornar parte do time dos "vilões", que todos 
são contratantes.
O APK original recebe o estado/atributo DEVIL, com aparência diferente e poder acima do normal. Ele deixa de seguir a
progressão evolutiva comum e, quando as condições narrativas forem cumpridas, pode se tornar o quarto HEAVENLY 
DEMISE — uma transformação especial ligada ao 4TH CONTRACT.
[TBD] DEVIL continua sendo uma camada própria de integridade/contrato e não uma “versão melhor de EXE”. O efeito 
mecânico exato do DEVIL Trait continua aberto no material atual; não inventar uma fórmula até que seja definida 
explicitamente.

12. ARQUITETURA TÉCNICA E PIPELINE DE 
DESENVOLVIMENTO
Princípio de implementação: sistemas devem ser data-driven, modulares, orientados a Resources (.tres), com lógica 
reutilizável separada da UI e mínimo de hardcode específico por app.
ETAPAS DO DESENVOLVIMENTO -
ETAPA 1 - GREYBOX
- O primeiro passo do desenvolvimento do jogo será criar templates fixos que podem ser usados de primeira para fazer 
as versões finais. A ideia é refinar cada etapa ao máximo para não precisar ter que voltar depois. O objetivo final dessa 
etapa é montar sistemas tão modulares através de .tres e recursos que, na hora de desenvolver o jogo real, quase não 
será necessário digitar nenhum código, apenas criar .tres repetidamente.
- Considerando o uso extensivo de .tres, deveremos fazer um .tres global que reflita tudo que há escrito nos Menus do 
jogo. Desse jeito, será possível implementar tradução para outras linguagens sem que os tradutores precisem 
necessariamente navegar pelo código do jogo.
Criar um sistema modular de janelas baseado em um template único. Toda janela possui Top Bar com nome e botão de
fechar, mais um Content container. Clicar no ícone de um app fechado abre sua única instância. Clicar novamente no 
ícone de um app aberto fecha a janela. O botão X também fecha. Tab cicla entre janelas abertas e traz a próxima para 
frente. Ao fechar, a posição da janela é salva; ao reabrir, ela retorna à última posição registrada. A lógica deve ser 
compartilhada por todos os apps, sem duplicação.
- Os sites também serão igualmente modulares. teremos um sistema de "dns simulado" onde um dicionário mapeia uma
URL que carrega uma cena específica (um aplicativo embutido). Isso significa que escrever o nome de um site irá 
resultar em entrar nele, e escrever qualquer outra coisa irá resultar num erro 403. O sistema deverá ter uma "limpeza" 
de url que remove www. ou https:// caso o usuário coloque, deixando apenas o nome do site (www.null.net se torna 
null.net). Assim como em navegadores antigos, clicar no botão de voltar deverá retornar para a página que foi acessada
anteriormente. O aplicativo do site deverá instanciar em várias "abas", cada uma sendo capaz de carregar um site, 
assim como abas de navegadores atuais.
- O conteúdo de sites serão templates, carregados via .tres: Todo site deverá ter um "Banner" no topo-centro que 
poderá ser tanto texto quanto uma imagem, definido via .tres, uma navbar logo abaixo que será uma barra que poderá 
ser modulada para ter quantos botões contendo textos (os ícones de menu) forem necessários, e a parte de "conteúdo",
logo abaixo, deverá conter um .tres que puxa colunas ou linhas para formarmos templates, e essas colunas ou linhas 
poderão conter texto, imagens ou botões. Esses botões deverão ter “checks” ao serem clicados: Se irão redirecionar 
para outra página, ou ativarão ou desativarão alguma variável bool.
- O fórum terá essa mesma lógica, sendo um site, mas será um pouco específico: Além do Header e da Navbar que 
será específico para todos os sites, ele contará com duas páginas especiais, a threadlist e a threadsite. Threadlist nada 
mais é do que uma lista de todas as threads que serão liberadas para o jogador ler, sendo botões em formato de barra 
um abaixo do outro. As Threads deverão ter Tags, que aparecem entre colchetes antes do título, e o título, que será um 
texto. Clicar na barra de uma thread a leva para o seu respectivo threadsite: Que nada mais é do que a página 
específica da Thread. Threads deverão ter requisitos de dia e de condições, que definem se estarão visíveis ou não. 
Mais especificamente, dois campos: Um campo que define a partir de que dia o jogador deve estar, e outros dois 
campos de false e true que definem quais variáveis devem ser ou false ou true para a thread ficar visível. As threads 
são listadas das mais recentes para as mais antigas, que será definido por um número de ID. Quando uma Thread nova
que o jogador não acessou antes é exibida, ela deverá ter um ícone indicando "NEW!" para avisar ao jogador que uma 
thread nova foi criada.
- Threadsite é a página de uma thread específica, que sempre terá uma quantidade de posts definida na criação de seu 
respectivo .tres. Esse .tres deverá ser um array que organiza e lista quais posts foram feitos em determinada thread. 
Esses posts, são divididos em dois: Na direita, em um campo menor, a identificação do poster (contendo seu avatar, 
nome de usuário, título no fórum e localização atual) e o conteúdo de seu post (que deverá ser um texto, uma imagem 
ou os dois). O texto deverá ter um sistema embutido que possa deixar uma parte em específica em negrito, itálico, 
sublinhado ou transformá-la em um “link” (que pode redirecionar o usuário para outra página ou ativar uma variável 
bool).
- Criar um sistema de Diálogos modular. A ideia é que os diálogos possam ser puxados infinitamente com slots, 
usando .tres: Seria possível definir quantas caixas de diálogo uma interação teria, que seria carregada com .tres de 
frases em ordem, e ser possível fazer a mesma coisa com as "imagens" de personagens que ficam logo acima da 
dialog box: um total de seis slots (três na esquerda, três na direita) que possam ser carregados no mesmo .tres que 
teriam o sprite do personagem e sua reação na fala atual. Esse .tres deverá ter uma opção de precisar que uma variável
bool seja false ou true para indicar se o diálogo irá aparecer ou se pulará para o próximo. Como o personagem principal

tomará ações durante diálogos que influenciarão sua tendência, é crucial que exista um sistema modular de colocar até 
6 opções de diálogo para o jogador poder interagir. Essas escolhas ditariam parcialmente o rumo do diálogo e 
alterariam a tendência. A ideia é também ser um .tres modular que encaixe no diálogo atual, com as quatro tendências: 
e um número que indique o quanto ela sobe ou desce. Cada escolha também deverá ser capaz de deixar uma variável 
bool false ou true, e também deverá haver uma opção de precisar de uma variável ser true ou false para ativar essa 
opção de diálogo.
- Também deverá haver um campo de false ou true que indique quando um evento de diálogo específico será chamado.
Quando as condições forem cumpridas, o app de Navigator se abrirá automaticamente (caso esteja fechado) e haverá 
uma transição para esse evento de diálogo.
- O combate será similarmente modular: Devemos criar uma lógica onde será possível incluir até 4 inimigos e 4 aliados 
via .tres. Então, será possível montar combates pré-definidos para cada área settando esses .tres. Modulos também 
serão criados com .tres, e cada personagem, seja NPC ou inimigo, terá Módulos pré-definidos equipados em seu 
sistema que selecionará a cada ciclo para ser os seus 4 do turno. Módulos serão .tres próprios específicos e serão 
carregados dentro de um .tres que define qual será o módulo a ser utilizado em qual etapa do ciclo, tanto para o inimigo
quanto para o aliado.
ETAPA 2 - SPRITING E GAME MAKING
Quando todos os sistemas modulares estiverem completos, finalmente começaremos a criar o jogo **de verdade**.
Aqui nasce a construção inicial do Prólogo, Eventos, definição do que acontece a cada dia, definição dos NPCs, criação
dos APKs oficiais completos, etc.
ATUALIZAÇÃO IMPORTANTE: O sistema de tempo de NULL NETWORK é dividido em dois períodos principais, DAY e
NIGHT, com 12 slots horários cada. Um dia completo possui 24 action blocks e cada action block equivale exatamente a
1 hora do relógio global. Rotinas de ocupação e sono podem tornar slots indisponíveis para o jogador, mas essas horas 
continuam sendo processadas para Conditions, threads, NPCs, spawns, StoryEvents e demais sistemas temporais. 
High School Student e Salaryperson possuem janelas fixas em dias úteis; NEET utiliza sono flexível de 8 horas; em 
noites sem obrigação no dia seguinte, a mesma flexibilidade de sono é liberada aos outros backgrounds.
Resumo técnico consolidado
• Resources de conteúdo devem carregar dados; Managers/sistemas reutilizáveis resolvem regras; Scenes/UI 
renderizam estado e emitem sinais.
• Browser, Navigator, Social, Combat, Encyclopedia e Profile devem permanecer desacoplados e compartilhar 
somente contratos/sistemas comuns.
• Tempo, flags, Conditions e action blocks devem ser dados consultáveis por sistemas de fórum, NPC, spawn, 
StoryEvent e encounter sem duplicação de lógica.
• Qualquer regra que varie por espécie, área, encontro, evolução, Node ou NPC deve preferencialmente existir em 
Resource configurável, não em branches hardcoded.

13. OPEN / TBD — DECISÕES AINDA NÃO FECHADAS
Tema Status Regra para IA
Leaderboard count OPEN Não afirmar Top 25 nem Top 
100 como definitivo.
Número exato de jogadores 
ativos
OPEN Usar apenas “comunidade 
pequena, global, 
underground/gatekept”.
Starter VALOUR INIT name OPEN NOVIRE é legacy; decisão atual 
está entre NOVIGHT e 
REVQUIRE.
VALOUR Player Action OPEN O sistema atual possui 
SCAN/LOGIC, PURGE/SELF, 
PURIFY/SYNC e TAME 
contextual; não existe Player 
Action VALOUR fechada.
TAME tendency OPEN/contextual Não atribuir uma tendência fixa 
sem regra futura.
DEVIL Trait combat rule TBD A camada existe, mas a fórmula 
final não está especificada.
SHN global spawn rate TBD É extremamente rara; a taxa 
numérica definitiva será 
balanceada depois.
STUN / POISON / BLEEDING 
full status definitions
TBD Variant Nodes referenciam 
esses Status Effects, mas o 
GDD atual não contém definição
completa de 
stacks/duração/resolução para 
todos eles. Não inventar.
Clima/temperatura dinâmica OPTIONAL/TBD Pode modificar pesos dos 
Variant Nodes via tags 
ambientais, mas Variant Nodes 
não dependem desse sistema 
para existir.
Duração da campanha / 
countdown final
OPEN Existe countdown público até a 
versão 1.0 e estrutura semanal 
canônica, mas o número exato 
de dias/semanas não está 
fechado. Não usar 30 dias como
valor definitivo.
Compatibility starter roster / 
pesos
OPEN Cinco Standard Compatibility 
APKs permanecem os 
resultados mais típicos; linhas 
adicionais podem ser START￾COMPATIBLE. Lista exata e 
pesos ainda não estão 
fechados.
Limite de RECALIBRATE OPEN RECALIBRATE existe e, após 
um limite, MANUAL 
SYNCHRONIZATION é 
autorizada. O número exato de 
recalibrações ainda precisa ser 
fechado.
Composição de fauna por 
distrito/subárea
TBD Foi discutido um framework de 
roster com forte sobreposição 
entre subáreas, variação 

Tema Status Regra para IA
DAY/NIGHT e métodos 
especiais de descoberta. O GDD
já possui ecologia 
populacional/Overworld, mas os 
números finais de linhas por 
distrito, overlap e camadas de 
acesso ainda não foram 
canonizados.
Progressão autônoma de 
NPCs / Partner Loss de NPC
TBD Foi discutida simulação em que 
NPCs realizam atividades, 
mudam ranking/nível, podem 
gerar Help Threads temporárias 
ao perder combates e sofrer 
consequências permanentes de 
parceiro. As regras, frequências 
e integração com party/Operator
Loss ainda não foram fechadas.
Module Capacity — valores OPEN A arquitetura Collection → 
Combat Loadout → 4 Cycle 
Slots é canônica. Capacity 
cresce por milestones e pode 
receber expansão manual 
limitada. Capacity inicial, 
milestones, máximo natural, 
custo em Allocation Points e 
hard cap manual ainda precisam
ser balanceados.
Interaction Checks — fórmula OPEN Estrutura de 1–3 situações, até 
6 opções, quatro abordagens de
Tendência + até duas 
contextuais e prioridade de 
estado/receptividade sobre 
Tendência são canônicas. 
Pesos, thresholds e graus 
internos finais de sucesso ainda 
precisam ser balanceados.
Data Center — nodes vs. tempo OPEN Runs em grafo, no Run Away e 
Exit Nodes/Eventos são 
canônicos. A relação exata entre
profundidade/quantidade de 
nodes e consumo de action 
blocks ainda precisa ser 
fechada.
Data Center — retenção em Exit OPEN EXIT é uma saída legítima e 
distinta de Run Away. A política 
exata de quais recompensas já 
obtidas permanecem ao sair 
antes do Core/Boss ainda 
precisa ser fechada.
Attrition fora de Data Center TBD HP/INCAPACITATED/Status 
persistentes carregam entre 
nodes da mesma run de Data 
Center. A persistência entre 
combates independentes no 
Overworld ainda não foi definida;
não inferir reset total nem 
persistência global até decisão 

Tema Status Regra para IA
futura.

14. FONTE HISTÓRICA SUPERSEDED — NÃO CANÔNICA
ATENÇÃO: este capítulo preserva texto original removido do corpo canônico porque era duplicado, contraditório, 
provisório ou substituído. Ele existe para garantir que nenhuma informação específica do documento-fonte seja perdida.
NÃO use este capítulo para resolver regras atuais. Em qualquer conflito, os capítulos 0–13 vencem.
Legacy source block — original paragraphs 0–0
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
NULL NETWORK - GDD EXTENSIVO 1.0
Legacy source block — original paragraphs 15–15
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O jogo criou uma comunidade underground espalhada pelo mundo inteiro, havendo cerca de mil jogadores 
concentrados apenas nas regiões centrais do Japão. Jogadores de outros países e continentes também estão 
presentes, mas como para jogar o jogo é necessário encontrar-se pessoalmente, seus usuários não podem interagir 
muito além do local principal de encontro do jogo: O fórum NULL CHANNEL.
Legacy source block — original paragraphs 29–29
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
---
Legacy source block — original paragraphs 33–33
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Nosso jogo funciona como um "semi-sistema operacional". Nosso jogador terá uma Barra de Tarefas estilo aplicativos 
do MAC no canto centro-inferior da tela, e ao clicar em cada um desses aplicativos uma janela se abre para exibir o 
menu. Será possível arrastar essas janelas pela tela e manter mais de uma ativa ao mesmo tempo, funcionando quase 
como um Windows.
Legacy source block — original paragraphs 37–37
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O Desktop do jogador emula a Área de Trabalho de um Mac: A tela principal do jogo atua como o wallpaper, com uma 
lista de ícones localizado no centro-inferior da tela. Sem barra de tarefas. No topo, haverá o equivalente de uma barra 
de tarefas que somente indicará o período atual do dia, a data e quantos dias se passaram desde que o jogador 
começou o jogo. Para abrir um aplicativo basta clicar em seu ícone, e para fechá-lo basta clicar no "X" ou clicar em seu 
ícone novamente.
Legacy source block — original paragraphs 57–57
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A página Get Started é igualmente simples: Ao lado esquerdo, botões que levam o jogador à diferentes páginas: 
Introduction e Get Started. Ao lado direito, o conteúdo textual da página atual em que o jogador se encontra. 
Introduction é um texto sobre TENYA falando da origem de NULL NETWORK. Get Started é um pequeno tutorial que 
ensinará o jogador o básico do jogo. (Stats, APKs e EXEs, o fato de só haver um único parceiro, o combate em 
módulos, Purify Tame e Consume... Mas nada explicando sobre a evolução volátil.)
Legacy source block — original paragraphs 59–59
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A página Player Rankings também é simples: Uma lista contendo os Top 25 jogadores de Null Network globalmente. 
Possui um header indicando estarmos nas Leaderboards e uma lista contendo um ícone, o nome de usuário do jogador,
uma bandeira de seu servidor local, seu título, o nome de seu parceiro APK e o nível de seu parceiro APK.
Legacy source block — original paragraphs 63–63
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
==ATUALIZAÇÃO IMPORTANTE DO FÓRUM==

Legacy source block — original paragraphs 65–120
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
SISTEMA FINAL DO NULL CHANNEL
O NULL CHANNEL é o fórum oficial de NULL NETWORK, acessado através do Navegador. Ele atua como o principal 
centro comunitário do jogo, reunindo discussões, rumores, pedidos de ajuda, guias, pedidos de party, provocações 
entre jogadores, informações falsas, descobertas reais e pistas sobre eventos futuros.
Diferente de uma enciclopédia ou wiki, o NULL CHANNEL não entrega informações de forma limpa e objetiva. Ele 
simula uma comunidade real, composta por jogadores veteranos, novatos, trolls, PKs, dataminers, rankers e 
moderadores. Portanto, uma informação importante pode estar espalhada entre várias threads diferentes, misturada 
com especulação, pânico, sarcasmo ou desinformação.
O objetivo do sistema é fazer com que o jogador use o fórum como uma ferramenta de investigação e aprendizado. 
Muitos eventos, bosses, locais, mecânicas e anomalias serão comentados no fórum antes de o jogador entendê-los de 
fato. Inicialmente, essas threads podem parecer apenas ruído ou conversa aleatória. Após encontrar determinado 
inimigo, local ou situação, o jogador poderá lembrar de discussões antigas, voltar ao fórum, pesquisar termos 
relacionados e perceber que informações úteis já estavam presentes ali.
Dessa forma, o NULL CHANNEL não funciona como um menu de quests ou como uma wiki direta. Ele funciona como 
uma comunidade viva que discute o jogo em tempo real.
Visualmente, o NULL CHANNEL possui um Header com o nome do fórum, uma Navbar geral e, abaixo dela, uma barra 
de abas específicas para filtrar o tipo de thread exibida. Também possui uma barra de pesquisa que permite procurar 
threads por título, tags, autor ou termos presentes nos posts.
A estrutura principal da página de lista de threads é:
NULL CHANNEL
├── Header
├── Navbar Geral
│ ├── Thread Lists
│ ├── Updates
│ └── Player Rankings
├── Abas de Fórum
│ ├── Trending
│ ├── Social
│ ├── Rumours
│ ├── Guides
│ └── Help
├── Search Bar
└── Thread List
A Navbar Geral serve para navegar entre as páginas principais do site NULL CHANNEL.
As Abas de Fórum servem para filtrar a lista de threads de acordo com sua função dentro da comunidade.
A aba Trending exibe as threads mais relevantes no momento atual do jogo. Essa aba não é uma categoria fixa de 
conteúdo, mas sim uma visão agregada. Ela pode mostrar threads de Social, Rumours, Guides ou Help, desde que 
essas threads estejam marcadas como importantes para o dia atual, para o período atual, para uma flag ativa ou para 
algum evento em andamento. É a aba principal para o jogador que não sabe exatamente o que fazer e quer ver o que a
comunidade está discutindo.
A aba Social exibe threads de interação entre jogadores. Inclui pedidos de party, desafios PVP, mini-eventos 
comunitários, provocações entre rankers, organização de encontros em locais físicos, pedidos de troca, recrutamento 
para explorar Data Centers e ganchos de quests ligados a NPCs. Essa aba deve reforçar a sensação de que NULL 
NETWORK é um jogo social e competitivo jogado por pessoas reais dentro da narrativa.
A aba Rumours exibe threads sobre locais suspeitos, supostos segredos, eventos estranhos, screenshots apagadas, 
teorias sobre TENYA, relatos de EXEs anômalos, bosses escondidos, Data Centers raros e mudanças não 
documentadas causadas por updates. Essa aba é a principal ferramenta de investigação narrativa do jogador. Muitas 
pistas sobre eventos futuros devem aparecer primeiro como rumores vagos, relatos incompletos ou discussões 
paranoicas.
A aba Guides exibe threads cujo objetivo é ensinar uma mecânica de forma mais profunda. Diferente dos tutoriais 
oficiais do jogo, que explicam apenas a interface e o funcionamento superficial dos sistemas, os guias do fórum 
explicam otimização, interpretações avançadas, fórmulas escondidas, aplicações práticas, exceções e opiniões de 
jogadores experientes. Um guia pode ensinar como SCAN realmente funciona, como Stability deve ser administrada, 
como Purify/Tame/Consume afetam progressão ou como preparar uma party para um Data Center difícil.

A aba Help exibe threads de jogadores pedindo ajuda sobre situações específicas. Inclui dúvidas de novatos, pedidos 
de explicação, relatos de bug, dúvidas sobre inimigos específicos, problemas com evolução, dificuldade para vencer 
determinado EXE, perguntas sobre locais e situações que o jogador ainda pode não entender. Essa aba permite que 
informações úteis apareçam em contexto mais orgânico, através de perguntas e respostas de outros usuários.
A Thread List exibe cada thread como uma linha clicável contendo:
• Ícone visual do tipo da thread
• Tag principal entre colchetes
• Título da thread
• Pequeno preview do primeiro post ou da mensagem mais relevante
• Indicador NEW caso o jogador ainda não tenha lido aquela thread
• Número de replies
• Último usuário que respondeu
• Tempo desde a última resposta
• Autor original da thread
• Ranking ou título do autor, quando aplicável
Exemplo de linha de thread:
[RUMOUR] Aquarium district acting weird lately
Something’s off with the water reflections. NPCs ignoring players?
Replies: 87
Last Reply: 2 min ago by HexDream #7
Author: 403kid ???
Cada thread possui uma categoria principal, mas também pode possuir múltiplas tags secundárias. A categoria define 
em qual aba principal a thread aparece. As tags servem para busca e agrupamento temático.
Exemplos de categorias:
TRENDING
SOCIAL
RUMOURS
GUIDES
HELP
Exemplos de tags:
aquarium
stability
scan
purify
consume
tame
devilmode
tokyo
datacenter
tenya
exe
apk
pvp
party
update1.0
A barra de pesquisa deve permitir que o jogador encontre threads digitando termos soltos. A pesquisa deve considerar:
• título da thread
• categoria
• tags
• nome do autor
• texto dos posts
• nomes de locais
• nomes de EXEs/APKs
• nomes de mecânicas
A busca não deve entregar uma resposta perfeita como uma wiki. Ela deve retornar uma lista de threads relacionadas 
ao termo pesquisado. Cabe ao jogador abrir, ler e interpretar as discussões.
Exemplo:

Pesquisar “SCAN” pode retornar:
[GUIDE] SCAN is not useless, stop saying that
[HELP] Why does SCAN stop at 75%?
[DISCUSSION] Scan data carries between encounters?
[BUG?] Boss scan reset after relogging
[GUIDE] Modules you can only learn from rare EXEs
Pesquisar “Aquarium” pode retornar:
[RUMOUR] Aquarium district acting weird lately
[HELP] Lost my partner near the aquarium
[BUG?] Mods deleted my screenshots again
[THEORY] Water reflections are showing different players
[PARTY] Need backup for abandoned aquarium run
O sistema deve permitir que threads sejam liberadas por tempo, flags, progresso do jogador e condições específicas. 
No entanto, a filosofia de design é evitar que guias apareçam magicamente apenas porque o jogador encontrou um 
boss ou evento. Sempre que possível, informações sobre um evento devem existir antes em forma de rumores, relatos 
ou perguntas vagas. Após o jogador viver a situação, essas threads antigas passam a fazer sentido.
Isso permite a seguinte experiência:
O jogador lê uma thread sobre o Aquário no começo da semana e não entende a importância.
Dias depois, encontra um boss no Aquário.
Durante ou após o combate, volta ao fórum.
Pesquisa por “Aquarium”, “Stability” ou “angel”.
Encontra threads antigas com relatos, dicas incompletas e discussões entre veteranos.
Percebe que a comunidade já estava falando daquilo antes.
Usa as informações espalhadas para montar sua própria estratégia.
Essa lógica reforça a sensação de que o mundo de NULL NETWORK existe independentemente do jogador. O fórum 
não cria informação porque o jogador chegou em determinado ponto. A informação já circulava pela comunidade; o 
jogador apenas não tinha contexto para entendê-la.
Cada ForumThread.tres deverá conter, no mínimo:
thread_id
thread_title
thread_category
thread_tags
thread_author
author_rank
author_title
reply_count
last_reply_author
last_reply_time_label
release_day
release_period
release_action_block
conditions
is_pinned
is_locked
is_archived
popularity_score
posts
thread_category define em qual aba principal a thread aparece.
thread_tags define quais termos podem ser usados para pesquisa e agrupamento.
popularity_score ajuda a definir quais threads aparecem na aba Trending.
reply_count, last_reply_author e last_reply_time_label são dados visuais usados na Thread List para simular atividade 
comunitária.
is_pinned permite que guias importantes ou comunicados de moderadores apareçam no topo de uma aba.
is_locked permite mostrar threads que ainda podem ser lidas, mas não representam uma discussão ativa.
is_archived permite separar threads antigas que não estão mais em atividade, mas ainda podem conter informações 
úteis.

As threads devem continuar sendo montadas por ForumPost.tres, preservando a lógica de posts com perfil do usuário e
conteúdo textual ou visual. Dentro de uma thread, cada post deve exibir o avatar, nome de usuário, título, ranking ou 
função do usuário, localização geral e o conteúdo da mensagem.
O texto dos posts deve continuar suportando links internos. Esses links podem levar para outras threads, sites, páginas 
do NULL CHANNEL, páginas de ranking ou ativar flags específicas quando necessário.
O sistema de links internos é importante para criar navegação orgânica entre threads. Um jogador pode abrir uma 
thread de Help e encontrar um veterano linkando um Guide antigo. Ou abrir uma thread de Rumour e encontrar 
usuários citando outras discussões. Dessa forma, o jogador aprende a navegar a comunidade como se estivesse 
investigando um fórum real.
A Enciclopédia e o NULL CHANNEL possuem funções diferentes.
A Enciclopédia concentra informações confirmadas e já registradas pelo jogador. Ela funciona como uma Pokédex, 
registro de tutoriais já apresentados, banco de EXEs/APKs encontrados e hub de personagens conhecidos.
O NULL CHANNEL concentra informação comunitária, especulação, guias avançados, perguntas, rumores e pistas não 
confirmadas.
Durante um combate, se o jogador quiser rever informações confirmadas sobre um inimigo já conhecido, deve abrir a 
Enciclopédia. Se quiser entender melhor uma mecânica, procurar estratégias, investigar uma anomalia ou encontrar 
dicas escondidas em discussões antigas, deve abrir o NULL CHANNEL.
Essa separação cria dois níveis de conhecimento:
Enciclopédia
→ Informação confirmada pelo jogo.
NULL CHANNEL
→ Conhecimento comunitário, interpretação, especulação e descoberta.
O resultado desejado é que o fórum se torne uma camada de progressão intelectual do jogador. O jogador evolui não 
apenas fortalecendo seu APK, mas aprendendo a ler a comunidade, identificar usuários confiáveis, reconhecer trolls, 
cruzar relatos e perceber padrões antes que o jogo os explique diretamente.
Legacy source block — original paragraphs 150–150
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O jogador lê uma thread sobre um EXE anômalo em Shibuya.
Viaja para Shibuya, consumindo 1 ação.
Explora o local livremente.
Encontra um EXE comum e decide lutar, consumindo 1 ação.
Continua em Shibuya.
Avança o Lead do EXE anômalo, consumindo 1 ação.
Continua em Shibuya.
Encontra um NPC conhecido e decide desafiar para PVP, consumindo 1 ação.
Depois decide ir para Akihabara, consumindo 1 ação de deslocamento.
Legacy source block — original paragraphs 168–168
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Challenge desafia o NPC para um PVP honesto. O PVP é marcado em algum local fixo do mapa, a depender do NPC, 
portanto aceitar o desafio e ir até lá consumirá um período. Combate PVP não dá XP, mas dá itens ou dinheiro.
Legacy source block — original paragraphs 243–243
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Consumir.
Legacy source block — original paragraphs 253–253
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Um jogador pode passar o dia inteiro lutando contra EXEs para ganhar XP e evoluir rápido.
Outro pode investigar rumores antigos e aprender padrões antes dos outros.
Outro pode fazer party, ajudar novatos e criar conexões.
Outro pode consumir tudo que encontra, trocar de parceiro sempre que conveniente e manipular NPCs por recompensa.
Outro pode tentar equilibrar tudo e acabar sem saber quem é.

Legacy source block — original paragraphs 283–283
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Quando a evolução do APK for desbloqueada, mas o APK não tiver evoluído ainda, o ícone do aplicativo de perfil exibe 
um ícone de exclamação e um novo botão fica localizado abaixo das três opções de interação: UPGRADE. Upgrade 
prompta a tela de evolução do APK na janela do mapa (e a abre automaticamente, caso não esteja aberta, para o 
player presenciar a cena).
Legacy source block — original paragraphs 289–289
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Visualmente, a Enciclopédia funciona como o seguinte: A lista de APKs à esquerda, e suas informações à direita. Suas 
informações nada mais são do que sua tendência (INIT, VALOUR, LOGIC, SELF, SYNC, NULL, BALANCED, por aí vai)
e um pequeno texto flair que explica do que se trata, além de um campo que indica sua raridade e em que áreas ele 
pode ser encontrado. Abaixo dessas informações, haverá o seu "chart evolutivo", que é uma tree lateral onde cada 
caminho evolutivo é um galho diferente. Essa "tree" só vai sendo desenvolvida conforme o jogador encontra com suas 
evoluções ativamente e as vence em combate (precisa dar purify, consume ou tame, o que indica que só é possível 
registrar na enciclopédia APKs "sem parceiros", já que essas opções não existem no PVP emulado (NPC vs Player).) 
As áreas onde pode ser encontrado também só são desbloqueadas após realizar uma dessas três ações.
Legacy source block — original paragraphs 608–608
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Escolhas pós-combate: Consume, Purify ou Tame.
Legacy source block — original paragraphs 617–617
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Se o jogador usa majoritariamente Modules VALOUR em um combate, o jogo pode registrar aquele combate como 
VALOUR.
Se usa Modules de controle, SCAN, análise e preparação, pode registrar como LOGIC.
Se usa cura, proteção, suporte e Purify, pode registrar como SYNC.
Se prioriza dano rápido, recompensa, Consume ou escolhas egoístas, pode registrar como SELF.
Legacy source block — original paragraphs 623–623
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
---
Legacy source block — original paragraphs 625–625
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
APKs e EXEs
Legacy source block — original paragraphs 627–627
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
As criaturas de NULL NETWORK são divididas em duas: APKs, que são geralmente parceiros de personagens e 
considerados "criaturas do bem", apesar de haver grande autonomia que possa indicar o contrário, e EXEs, que são 
criaturas corrompidas, virus, monstros erráticos e IAs apocalípticas.
Legacy source block — original paragraphs 629–629
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O universo "in-game in-game" indica fortemente que EXEs são criaturas cujo objetivo é destruir o mundo virtual, e APKs
foram criados como um método de contingência para detê-los. No entanto, são incapazes de agir inteiramente por conta
própria: Para atingirem 100% do seu potencial, precisam de um parceiro; um jogador.
Legacy source block — original paragraphs 631–631
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
TODO APK possui um total de 12 formas diferentes.

Legacy source block — original paragraphs 633–633
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Sua forma INIT, que é a "forma-base", estilo Rookie de Digimon ou a primeira fase evolutiva de um Pokémon com 3 
estágios de evolução.
Legacy source block — original paragraphs 635–635
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Sua forma EXE, que é uma corrupção de sua forma base, sendo os principais inimigos do jogo.
Legacy source block — original paragraphs 637–637
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Suas formas primárias, que são suas primeiras evoluções, como uma versão "champion" (equivalente Digimon) ou 
"mid-form" (equivalente Pokémon). Nesse estado, um APK possui 5 formas diferentes: BALANCED, VALOUR, LOGIC, 
SELF e SYNC.
Legacy source block — original paragraphs 639–639
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Um APK INIT pode evoluir para qualquer uma dessas 5 formas, tendo requisitos diferentes para cada APK específico; 
seu único requisito em comum é geralmente precisar de um player com uma tendência predominante.
Legacy source block — original paragraphs 641–641
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
E por fim, suas formas secundárias, suas evoluções finais. Um equivalente "Ultimate" ou "3rd evolution". Nesse estado, 
também existem 5 formas diferentes: XVALOUR, XLOGIC, XSELF, XSYNC ou a famigerada forma NULL.
Legacy source block — original paragraphs 643–643
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Um APK que esteja em qualquer uma de suas primeiras evoluções pode evoluir para qualquer uma dessas 5 formas, 
dependendo inteiramente de cumprir os requisitos para atingir sua evolução. Isso significa que um APK VALOUR pode 
facilmente se tornar um APK XLOGIC ou XSELF, dependendo das ações que o jogador tomou no decorrer do jogo que 
mudaram sua tendência radicalmente.
Legacy source block — original paragraphs 645–645
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
É possível evoluir tanto fora de combate quanto dentro de combate.
Legacy source block — original paragraphs 647–655
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Todo APK possui 6 stats diferentes, que podem ser aumentados a cada level up:
HP: Representa a vida de um APK.
STABILITY: É uma porcentagem, que pode ir de 0 a 100%. Usar Modules (explicados mais tarde) consomem 
STABILITY. Quanto maior o stat STABILITY, maior a porcentagem de STABILITY recuperada por ciclo.
ATK: Representa o dano físico de um APK. Modules físicos usam esse stat para aplicar dano.
DEF: Representa as defesas de um APK. Quando atacado por um Module de ataque, o dano é subtraído pela quantia 
de DEF que um APK possui.
MATK: Representa o dano mágico de um APK. Modules mágicos usam esse stat para aplicar dano.
MDEF: Representa as defesas mágicas de um APK. Quando atacado por um Module de ataque mágico, o dano é 
subtraído pela quantia de MDEF que um APK possui.
DODGE: Representa a chance que um APK possui de desviar de um Module. Modules possuem ACCURACY, que 
indicam qual é a porcentagem de chance de acerto. Essa porcentagem é subtraída por metade da quantia de DODGE 
que um APK possui.

CRIT: Representa a chance de acertar um crítico. Acertar um crítico triplica o dano comum de um Module de ataque ou 
triplica os stacks de stats positivos ou negativos infligidos por um Module de suporte. Acertar um crítico também faz com
que o alvo sofra de UNSTABILITY.
Legacy source block — original paragraphs 673–673
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
APKs aprendem Modules ativos (que consomem stability e são utilizados ativamente durante o combate) por level-up, 
mas também utilizando a habilidade SCAN: SCAN é um dos modules básicos disponibilizados desde o começo, onde 
cada uso seu apenas aumenta a taxa de scan de um inimigo específico durante o combate em 25%: Atingir 100% abre 
uma tela onde será possível adquirir permanentemente algum dos Modules ativos que o inimigo scanneado possui. Isso
possibilita que o jogador colete todos os Modules do jogo desde que sacrifique parte de seu turno (ou até o turno inteiro)
sem fazer nada além de scannear.
Legacy source block — original paragraphs 676–676
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
---
Legacy source block — original paragraphs 709–712
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
CONSUME
destrói o EXE
alto ganho de XP
+SELF, +LOGIC
Legacy source block — original paragraphs 714–719
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
PURIFY
transforma o EXE em APK
narrativa positiva
necessário para certos caminhos
+SYNC, +VALOR
+ Dá ao jogador um Module passivo novo
Legacy source block — original paragraphs 721–725
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
TAME
o jogador abandona seu APK atual
ganha o novo parceiro
pode ser APK (caso tenha o purificado) ou EXE (caso tenha usado TAME sem PURIFY)
escolha permanente
Legacy source block — original paragraphs 727–728
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Nos casos de Purify/Tame:
ocorre um mini-diálogo
Legacy source block — original paragraphs 751–769
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
COMBATE COMO AÇÃO SIGNIFICATIVA
Em NULL NETWORK, combate não é filler. Combate é uma ação de calendário com recompensa mecânica, narrativa e 
identitária.

Cada combate contra um EXE consome 1 Time Slot porque enfrentar um EXE representa um investimento real de 
tempo dentro da rotina do personagem. Essa escolha só funciona porque todo combate em NULL NETWORK gera 
progresso significativo.
Ao derrotar um EXE, o jogador sempre precisa escolher como lidar com ele:
CONSUME
O jogador destrói o EXE e converte seus dados em poder.
Gera alto ganho de XP.
Favorece uma leitura mais eficiente, fria ou predatória do jogo.
Aumenta tendências ligadas a SELF e LOGIC.
PURIFY
O jogador purifica o EXE, tratando-o como uma entidade corrompida que pode ser recuperada.
Gera menos XP direto que Consume.
Pode conceder Modules passivos.
Pode ser necessário para certas rotas narrativas ou evoluções.
Aumenta tendências ligadas a SYNC e VALOUR.
TAME
O jogador abandona seu parceiro atual e assume o EXE/APK derrotado como novo parceiro.
É uma escolha permanente e emocionalmente pesada.
Não deve ser tratado como simples captura de monstro, mas como substituição real de vínculo.
Pode alterar drasticamente a relação do jogador com o antigo parceiro, com NPCs e com sua própria build.
Além dessas escolhas pós-combate, o combate também gera progresso por outros meios:
XP.
Dinheiro ou itens.
Dados para a Enciclopédia.
Possibilidade de aprender Modules novos através de SCAN.
Mudança de tendências pelo estilo de combate.
Reações do parceiro APK.
Reações de NPCs presentes na party.
Novas threads ou DMs caso o combate seja relevante.
Abertura de novas estratégias contra bosses e EXEs anômalos.
SCAN é especialmente importante porque transforma combate em descoberta. O jogador pode sacrificar parte do seu 
turno para analisar o inimigo, completar sua taxa de scan e adquirir permanentemente um Module ativo que aquele 
inimigo possui. Assim, mesmo um combate que não resulte em Tame ou Purify ainda pode expandir o repertório 
estratégico do jogador.
Como cada combate consome tempo, lutar deixa de ser uma interrupção aleatória e passa a ser uma decisão. O 
jogador deve escolher se vale gastar uma parte do dia em XP, Modules, tendências, chance de novo parceiro, 
investigação de inimigos ou preparação para eventos futuros.
Legacy source block — original paragraphs 840–840
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Escolher TERMINATE APK deleta o parceiro do jogador pra sempre, e ele é substituído por TURD, que nada mais é do 
que um APK INIT que serve como "Placeholder": Sempre que o jogador perde o seu APK por qualquer motivo que seja, 
desde afinidade baixa, eventos específicos (como esse), ou jogadores o roubam, seja temporariamente ou 
permanentemente, TURD aparece para que o jogo não bugue. Ele é um APK extremamente fraco, que só aprende 
módulos básicos... Mas também é a chave para atingir o final verdadeiro.
Legacy source block — original paragraphs 850–850
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Seu APK original se torna do atributo DEMON, tendo uma cor diferente e sendo mais poderoso que o normal. Mas não 
evolui como normalmente; apenas poderá se tornar o quarto HEAVENLY DEMISE quando a hora for certa, o que leva o
jogador a entender que seu APK não evolui mais... mas estará profundamente enganado quando ele se tornar o quarto 
demônio do jogo e ficar tão poderoso quanto CANON.

Legacy source block — original paragraphs 858–858
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Lá, ele se depara com o site principal: NULL CHANNEL, que dá uma breve explicação sobre o que é a NULL 
NETWORK, apresentando as abas de como funciona, por quem foi criado, uma leaderboard de top 100 jogadores, e a 
aba para acessar o fórum da NULL CHANNEL. Ele poderá acessar cada uma das abas, mas a aba de acesso ao fórum 
está bloqueada apenas para usuários. Ele será promptado a criar a sua conta...
Legacy source block — original paragraphs 943–943
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
As escolhas feitas durante o diálogo com o Boss ou a forma como o jogador lida com a anomalia (CONSUME, PURIFY 
ou TAME) geram picos massivos nas tendências (VALOUR, LOGIC, SYNC, SELF).
Legacy source block — original paragraphs 957–957
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
- Criar um sistema modular de "janelas", que emula as de um desktop de verdade. A ideia é que todo aplicativo com 
uma janela própria utilize essa janela como base, que basicamente terá o "nome da janela" e o botão de fechar ao lado, 
como uma Top Bar. Clicar no botão de um aplicativo abre sua janela. Clicar novamente no botão de um aplicativo 
aberto ou seu ícone o traz pra frente. Clicar duas vezes no botão de um aplicativo aberto ou seu ícone (ou uma vez no 
botão de fechar o aplicativo, que fica na Top Bar) fecha a sua janela. Apertar Tab deve ciclar entre janelas abertas para 
puxá-las pra frente. As janelas, quando fechadas, devem armazenar no sistema qual a posição exata em que foram 
fechadas. Abrí-las novamente faz com que elas se abram exatamente na mesma posição em que estavam quando 
foram fechadas.
Legacy source block — original paragraphs 985–985
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ataque: O personagem no Slot X aliado sempre atinge o Slot X inimigo (Ataque reto).
Legacy source block — original paragraphs 996–996
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A Exploração: O jogador abre o aplicativo Navigator no seu Sistema Operacional, escolhe um local e clica em "Scan". O
RNG roda a SpawnTable e decide qual CombatEncounter vai acontecer.
Legacy source block — original paragraphs 1000–1000
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A Limpeza e a Resolução: No fim das 8 ações, durações de buffs caem, inimigos "deslizam" para o centro e a Timeline 
recomeça. Se todos os inimigos chegarem a 0 HP, o loop é quebrado e a tela de Resolução surge, exigindo que o 
jogador tome uma decisão final (CONSUME, PURIFY, TAME).
Legacy source block — original paragraphs 1092–1094
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Morning → encontro A com 20% de chance
Afternoon → encontro B com 40% de chance
Night → encontro C com 80% de chance
Legacy source block — original paragraphs 1115–1117
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Morning → Online
Afternoon → Outside
Night → Offline
Legacy source block — original paragraphs 1276–1276
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

Abaixo dessa lista, caso o APK tenha cumprido todos os requisitos para Evoluir, um botão chamativo e dourado escrito 
“UPGRADE” se fará presente abaixo de tudo. Clicar nele prompta a tela de evolução do APK.
Legacy source block — original paragraphs 1335–1335
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Visualmente, a Enciclopédia funciona como o seguinte: A lista de APKs à esquerda, e suas informações à direita. Suas 
informações nada mais são do que sua tendência (INIT, VALOUR, LOGIC, SELF, SYNC, NULL, BALANCED, por aí vai)
e um pequeno texto flair que explica do que se trata, além de um campo que indica sua raridade e em que áreas ele 
pode ser encontrado. Abaixo dessas informações, haverá o seu "chart evolutivo", que é uma tree lateral onde cada 
caminho evolutivo é um galho diferente. Essa "tree" só vai sendo desenvolvida conforme o jogador encontra com suas 
evoluções ativamente e as vence em combate (precisa dar purify, consume ou tame, o que indica que só é possível 
registrar na enciclopédia APKs "sem parceiros", já que essas opções não existem no PVP emulado (NPC vs Player).) 
As áreas onde pode ser encontrado também só são desbloqueadas após realizar uma dessas três ações.
Legacy source block — original paragraphs 1595–1595
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
como SCAN funciona de verdade
como administrar Stability
como preparar uma party para Data Centers
como avaliar riscos de Purify, Consume e Tame
como interpretar padrões de bosses
como identificar EXEs raros
como otimizar módulos
como entender fórmulas escondidas
Legacy source block — original paragraphs 1598–1598
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
[GUIDE] How STABILITY actually works
[GUIDE] SCAN is not useless, stop saying that
[GUIDE] Beginner mistakes that get your APK killed
[GUIDE] Purify vs Consume: actual numbers
Legacy source block — original paragraphs 1893–1894
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ao derrotar o EXE, escolheu CONSUME.
CONSUME
+SELF
+LOGIC
Legacy source block — original paragraphs 1896–1896
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O jogador recebe pontos por ter lutado como VALOUR, mas também recebe pontos pela decisão moral de consumir o 
inimigo.
Legacy source block — original paragraphs 1977–1977
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Nesse modo, Partner Loss, Operator Loss, perdas de APK, escolhas de TAME, PURIFY, CONSUME e outras 
consequências graves ainda podem acontecer, mas o jogador pode retornar para um estado anterior caso deseje.
Legacy source block — original paragraphs 2030–2030
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
It cannot evolve.
Legacy source block — original paragraphs 2422–2424
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

- O resultado é um candidato exezado, instável ou ilegal.
- O alvo pode ser removido do combate e registrado para decisão posterior.
- O vínculo pode gerar consequências negativas futuras.
Legacy source block — original paragraphs 2676–2676
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
TECHNER
Legacy source block — original paragraphs 2723–2723
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
NOVIRE → TECHNER
Legacy source block — original paragraphs 2962–2964
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Exemplo:
ATK base após distribuição:
100
Legacy source block — original paragraphs 2966–2967
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node:
-20% ATK
Legacy source block — original paragraphs 2969–2970
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
ATK efetivo:
80
Legacy source block — original paragraphs 2972–2972
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O jogador não consegue ignorar o drawback do Node colocando pontos depois da penalidade.
Legacy source block — original paragraphs 3069–3069
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Qualidades especiais, como Legendary.
Legacy source block — original paragraphs 3193–3193
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
qualidade Legendary;
Legacy source block — original paragraphs 3209–3210
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
NOVIRE → TECHNER
Chroma Lineage: TECHNER / LOGIC
Legacy source block — original paragraphs 3295–3295
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
→ TECHNER
Legacy source block — original paragraphs 3303–3303
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

Techner
Legacy source block — original paragraphs 3352–3364
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
7. Variant Nodes
7.1 Definição
Variant Nodes são características intrínsecas de um indivíduo.
Eles modificam:
aparência;
paleta;
efeitos visuais;
comportamento mecânico;
função tática.
Exemplos:
Fire Node
Ice Node
Defensive Node
Legacy source block — original paragraphs 3366–3369
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Um Node acompanha o indivíduo desde sua geração e permanece durante todas as evoluções.
NOVIRE Fire Node
→ JACKRIDER Fire Node
→ RISE JUSTIZMAN Fire Node
Legacy source block — original paragraphs 3371–3371
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O Node não é removido nem substituído pela evolução.
Legacy source block — original paragraphs 3373–3376
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
7.2 Paletas padronizadas de Node
Cada Node possui uma identidade cromática reconhecível em todas as linhas.
Exemplo:
FIRE NODE
Legacy source block — original paragraphs 3378–3379
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Primary:
laranja e vermelho
Legacy source block — original paragraphs 3381–3382
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Secondary:
amarelo quente
Legacy source block — original paragraphs 3384–3385
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

Emissive:
amarelo ou branco incandescente
Legacy source block — original paragraphs 3387–3388
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
VFX:
calor, brasas ou distorção
Legacy source block — original paragraphs 3390–3390
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
DEFENSIVE NODE
Legacy source block — original paragraphs 3392–3393
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Primary:
cinza cimento
Legacy source block — original paragraphs 3395–3396
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Secondary:
azul escuro
Legacy source block — original paragraphs 3398–3399
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Material:
aspecto mineral ou estatuesco
Legacy source block — original paragraphs 3401–3402
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
VFX:
fragmentos, placas ou Barrier
Legacy source block — original paragraphs 3404–3404
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
ICE NODE
Legacy source block — original paragraphs 3406–3407
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Primary:
azul frio
Legacy source block — original paragraphs 3409–3410
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Secondary:
ciano ou branco
Legacy source block — original paragraphs 3412–3413
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Emissive:
azul claro

Legacy source block — original paragraphs 3415–3416
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
VFX:
cristais, gelo ou condensação
Legacy source block — original paragraphs 3418–3418
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A identidade visual do Node precisa ser consistente o suficiente para que o jogador consiga reconhecê-lo antes de 
realizar SCAN.
Legacy source block — original paragraphs 3420–3426
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
8. Relação entre Node e linhagem cromática
8.1 Prevalência do Node
Quando um APK possui Variant Node, o Node domina sua identidade cromática principal.
Isso significa que as maiores áreas do sprite normalmente utilizam as cores do Node.
Entretanto, o Node não deve apagar completamente a Chroma Lineage.
A regra é:
O Node define a identidade cromática dominante.
Legacy source block — original paragraphs 3428–3428
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A linhagem permanece visível em detalhes secundários.
Legacy source block — original paragraphs 3430–3433
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Exemplo:
NOVIRE Fire Node
→ JACKRIDER
→ RISE JUSTIZMAN
Legacy source block — original paragraphs 3435–3437
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Resultado:
Primary:
Fire Node
Legacy source block — original paragraphs 3439–3440
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Secondary:
Fire Node
Legacy source block — original paragraphs 3442–3443
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Emissive:
Fire Node
Legacy source block — original paragraphs 3445–3446
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

Accent:
Jackrider / BALANCED
Legacy source block — original paragraphs 3448–3449
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Core ou emblema:
Jackrider / BALANCED
Legacy source block — original paragraphs 3451–3454
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Outro indivíduo:
NOVIRE Fire Node
→ JUSTIZMAN
→ RISE JUSTIZMAN
Legacy source block — original paragraphs 3456–3458
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
pode possuir:
Primary:
Fire Node
Legacy source block — original paragraphs 3460–3461
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Secondary:
Fire Node
Legacy source block — original paragraphs 3463–3464
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Accent:
Justizman / VALOUR
Legacy source block — original paragraphs 3466–3466
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Os dois continuam imediatamente reconhecíveis como Fire Node, mas não possuem exatamente a mesma aparência.
Legacy source block — original paragraphs 3468–3471
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
8.2 Canais modificados pelo Node
Cada Node define quais canais visuais substitui.
Exemplo:
FIRE NODE
Legacy source block — original paragraphs 3473–3476
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Substitui:
Primary
Secondary
Emissive

Legacy source block — original paragraphs 3478–3481
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Preserva:
Accent
Core
Material
Legacy source block — original paragraphs 3483–3483
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
DEFENSIVE NODE
Legacy source block — original paragraphs 3485–3488
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Substitui:
Primary
Material
Shadow
Legacy source block — original paragraphs 3490–3493
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Preserva:
Secondary
Accent
Emissive
Legacy source block — original paragraphs 3495–3495
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
ICE NODE
Legacy source block — original paragraphs 3497–3500
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Substitui:
Primary
Secondary
Emissive
Legacy source block — original paragraphs 3502–3504
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Preserva:
Accent
Outline
Legacy source block — original paragraphs 3506–3507
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Essa regra permite que Nodes diferentes produzam transformações visualmente distintas.
Nem todo Node precisa repintar o sprite inteiro.
Legacy source block — original paragraphs 3509–3512
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

9. Estado de integridade
O estado Purified, EXE ou DEVIL é aplicado depois da paleta de linhagem e do Node.
O estado de integridade não deve apagar a identidade anterior.
Ele funciona como uma camada de modificação visual.
Legacy source block — original paragraphs 3514–3518
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
9.1 Purified
O estado Purified utiliza a paleta composta normalmente.
Forma
+ Chroma Lineage
+ Variant Node
Legacy source block — original paragraphs 3520–3521
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Não existe uma alteração cromática obrigatória adicional.
O APK purificado representa a apresentação visual estável daquele indivíduo.
Legacy source block — original paragraphs 3523–3539
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
9.2 EXE
O estado EXE aplica uma camada de corrupção.
Possíveis modificações:
sombras mais profundas;
cores parcialmente dessaturadas;
alteração do emissivo;
accent de corrupção;
glitches;
fragmentação;
pulsação;
pixels instáveis;
efeitos de ruído.
A fórmula visual é:
Forma atual
+ Chroma Lineage
+ Variant Node
+ EXE Modifier
Legacy source block — original paragraphs 3541–3546
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Um EXE pode possuir qualquer Variant Node permitido pelo ecossistema.
Exemplo:
Rise Justizman
+ Jackrider Chroma
+ Fire Node
+ EXE State

Legacy source block — original paragraphs 3548–3548
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Todas essas camadas devem continuar legíveis.
Legacy source block — original paragraphs 3550–3567
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
9.3 DEVIL
DEVIL possui uma assinatura visual própria e mais agressiva.
Pode modificar:
contorno;
emissivo;
contraste;
olhos;
núcleo;
partículas;
accent;
sombras;
efeitos de tela.
DEVIL não deve simplesmente pintar todos os APKs da mesma cor.
A aparência anterior ainda precisa ser identificável.
Forma
+ Linhagem
+ Node
+ DEVIL Modifier
Legacy source block — original paragraphs 3569–3569
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
DEVIL deve parecer uma transformação do indivíduo existente, e não uma skin genérica aplicada sobre qualquer 
criatura.
Legacy source block — original paragraphs 3571–3584
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
10. Legendary e qualidades especiais
Legendary não deve substituir completamente a paleta existente.
Ele funciona como uma qualidade visual adicional.
Possíveis características:
maior contraste;
highlights exclusivos;
reflexos iridescentes;
brilho especial;
outline diferenciado;
partículas raras;
alteração localizada de um ou dois canais;
efeito visual no núcleo ou nos olhos.
Exemplo:
Legendary Fire Node Rise Justizman

Legacy source block — original paragraphs 3586–3591
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
continua sendo reconhecido como:
Rise Justizman;
Fire Node;
membro de determinada Chroma Lineage;
Legendary.
Legendary não deve transformar todos os indivíduos em versões douradas idênticas.
Legacy source block — original paragraphs 3608–3608
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
+ Qualidade Legendary
Legacy source block — original paragraphs 3661–3662
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Novire Fire Node
→ Justizman Fire Node
Legacy source block — original paragraphs 3665–3665
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node sobre a paleta INIT
Legacy source block — original paragraphs 3668–3668
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node com accents VALOUR de Justizman
Legacy source block — original paragraphs 3693–3693
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
→ Chroma Lineage ou Variant Node
Legacy source block — original paragraphs 3705–3705
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
→ Legendary
Legacy source block — original paragraphs 3729–3729
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node
Legacy source block — original paragraphs 3735–3735
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Legendary
Legacy source block — original paragraphs 3756–3756
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ice Node:
Legacy source block — original paragraphs 3759–3759
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node:

Legacy source block — original paragraphs 3762–3762
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node:
Legacy source block — original paragraphs 3813–3813
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O Node domina a paleta sem apagar completamente a linhagem.
Legacy source block — original paragraphs 3815–3815
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Legendary funciona como qualidade adicional, não como pintura universal.
Legacy source block — original paragraphs 3848–3848
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
→ domina a identidade cromática sem apagar a linhagem.
Legacy source block — original paragraphs 3853–3854
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
LEGENDARY
→ adiciona brilho, contraste e efeitos especiais;
Legacy source block — original paragraphs 3895–3895
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
→ qualidade excepcional, como Legendary.
Legacy source block — original paragraphs 3973–3973
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Techner
Legacy source block — original paragraphs 4127–4135
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
5. Variant Nodes
5.1 Definição
Variant Nodes são características congênitas de um APK específico.
Eles representam uma alteração estrutural, elemental ou comportamental daquele indivíduo.
Exemplos:
Fire Node
Ice Node
Defensive Node
Overclock Node
Legacy source block — original paragraphs 4137–4146
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O Node modifica simultaneamente:
paleta;
efeitos visuais;
comportamento em combate;
interação com Modules;
pontos fortes;

pontos fracos;
distribuição ecológica.
Um Node não é uma nova espécie nem uma nova forma evolutiva.
Ele é uma variante persistente do indivíduo.
Legacy source block — original paragraphs 4148–4150
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
5.2 Limite de Nodes
Um APK comum pode possuir:
0 ou 1 Variant Node
Legacy source block — original paragraphs 4152–4157
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Nodes não são acumulados livremente.
Isso impede combinações excessivamente complexas como:
Fire
+ Ice
+ Defensive
+ Overclock
Legacy source block — original paragraphs 4159–4159
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Inimigos autorais, bosses ou entidades excepcionais podem quebrar essa regra, mas essas exceções devem ser 
configuradas diretamente e não fazem parte da geração comum de APKs.
Legacy source block — original paragraphs 4161–4165
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
5.3 Persistência
O Variant Node acompanha o indivíduo durante toda a sua existência.
Novire Fire Node
→ Jackrider Fire Node
→ Rise Justizman Fire Node
Legacy source block — original paragraphs 4167–4177
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O Node:
não muda durante level up;
não é substituído pela evolução;
não é removido por PURIFY;
não é removido por TAME;
não é alterado pela Chroma Lineage;
não pode ser equipado;
não pode ser desequipado;
não pode ser transferido;
não pode ser extraído;
desaparece caso o APK morra.
Legacy source block — original paragraphs 4179–4188
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.

5.4 Node e evolução
Nodes não determinam diretamente qual evolução será atingida.
A evolução continua sendo definida pelas tendências e demais requisitos da linha.
Um Fire Node pode evoluir para:
BALANCED
VALOUR
LOGIC
SYNC
SELF
NULL
Legacy source block — original paragraphs 4190–4191
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
desde que o APK cumpra os requisitos correspondentes.
O Node altera como aquela forma funciona, mas não substitui sua identidade evolutiva.
Legacy source block — original paragraphs 4193–4202
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
6. Estrutura mecânica de um Node
Todo Variant Node deve possuir cinco componentes.
6.1 Identidade visual
Define:
paleta principal;
canais cromáticos substituídos;
VFX;
ícone;
partículas;
leitura em combate.
Legacy source block — original paragraphs 4204–4207
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
6.2 Benefício principal
Todo Node possui uma vantagem claramente reconhecível.
Exemplos:
Aplicação de Burn.
Legacy source block — original paragraphs 4209–4209
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Geração de Barrier.
Legacy source block — original paragraphs 4211–4211
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Maior velocidade de execução.
Legacy source block — original paragraphs 4213–4213
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Interação com Status Effects.

Legacy source block — original paragraphs 4215–4215
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Redução de determinado tipo de dano.
Legacy source block — original paragraphs 4218–4228
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
6.3 Custo ou limitação
Nodes comuns devem funcionar prioritariamente como sidegrades.
Uma vantagem forte precisa vir acompanhada de:
penalidade de stat;
restrição;
condição;
vulnerabilidade;
custo de Stability;
limitação de ativação.
Exemplo:
DEFENSIVE NODE
Legacy source block — original paragraphs 4230–4231
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Benefício:
recebe 1 stack de Barrier no início de cada ciclo.
Legacy source block — original paragraphs 4233–4235
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Custo:
-20% ATK;
-20% MATK.
Legacy source block — original paragraphs 4237–4238
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O objetivo não é criar uma versão universalmente superior do APK.
O objetivo é criar uma versão melhor para determinadas builds e pior para outras.
Legacy source block — original paragraphs 4240–4250
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
6.4 Regra de ativação
O Node deve indicar exatamente:
quando ativa;
sobre quem ativa;
quantas vezes pode ativar;
se possui limite por ciclo;
como interage com multi-hit;
como interage com ataques em área;
como interage com stacks.
Exemplo estrutural:
FIRE NODE

Legacy source block — original paragraphs 4252–4253
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Trigger:
ao causar dano com Module ATK.
Legacy source block — original paragraphs 4255–4256
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Efeito:
chance de aplicar Burn.
Legacy source block — original paragraphs 4258–4259
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Limite:
uma ativação por alvo por ciclo.
Legacy source block — original paragraphs 4261–4262
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Os valores exatos de chance e limite fazem parte do balanceamento específico do Node.
A estrutura deve impedir que um Module multi-hit gere uma quantidade descontrolada de ativações.
Legacy source block — original paragraphs 4264–4274
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
6.5 Compatibilidade ecológica
Cada Node possui afinidades com:
espécies;
distritos;
subáreas;
horários;
níveis de Danger;
níveis de Infestation;
condições ambientais;
encounters específicos.
Isso determina onde a variante pode aparecer.
Legacy source block — original paragraphs 4276–4287
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
7. Ecologia dos Variant Nodes
7.1 Nodes não são sorteados globalmente
Não existe uma tabela universal na qual qualquer Node pode aparecer em qualquer criatura.
A chance final depende da combinação:
Linha evolutiva
+ distrito
+ subárea
+ horário
+ ambiente
+ Danger
+ Infestation

+ Encounter Template
Legacy source block — original paragraphs 4289–4290
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Exemplo:
ÁREA GELADA
Legacy source block — original paragraphs 4292–4293
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ice Node
→ frequente.
Legacy source block — original paragraphs 4295–4296
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node
→ comum.
Legacy source block — original paragraphs 4298–4299
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node
→ raro.
Legacy source block — original paragraphs 4301–4302
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Nodes incompatíveis
→ impossíveis.
Legacy source block — original paragraphs 4305–4308
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
7.2 Afinidade da espécie
Uma espécie também pode possuir compatibilidades próprias.
Exemplo:
LINHA A
Legacy source block — original paragraphs 4310–4311
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ice Node:
alta compatibilidade.
Legacy source block — original paragraphs 4313–4314
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node:
média compatibilidade.
Legacy source block — original paragraphs 4316–4317
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node:
incompatível.

Legacy source block — original paragraphs 4319–4319
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
LINHA B
Legacy source block — original paragraphs 4321–4322
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node:
alta compatibilidade.
Legacy source block — original paragraphs 4324–4325
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Overclock Node:
média compatibilidade.
Legacy source block — original paragraphs 4327–4328
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ice Node:
raro.
Legacy source block — original paragraphs 4330–4330
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Um habitat favorável não obriga todas as espécies presentes a receberem o mesmo Node.
Legacy source block — original paragraphs 4332–4336
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
7.3 Encounter Templates
Nodes podem ser definidos como parte de uma formação.
Exemplos:
4 EXEs Fire Node
→ infestação de superaquecimento.
Legacy source block — original paragraphs 4338–4341
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
2 EXEs comuns
+ 1 Defensive Node
+ 1 atacante
→ formação protegida.
Legacy source block — original paragraphs 4343–4345
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
1 variante rara
+ 3 indivíduos comuns da mesma linha
→ encontro de liderança ou anomalia.
Legacy source block — original paragraphs 4347–4347
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O sistema deve preferir composições coerentes em vez de sortear cada Node de maneira completamente 
independente.

Legacy source block — original paragraphs 4349–4353
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
8. Nodes e identidade individual
Variant Nodes existem para tornar indivíduos da mesma linha mecanicamente diferentes.
Exemplo:
RATTUS padrão
→ build comum de scavenger.
Legacy source block — original paragraphs 4355–4356
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
RATTUS Fire Node
→ pressão de Burn.
Legacy source block — original paragraphs 4358–4359
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
RATTUS Defensive Node
→ proteção e Barrier.
Legacy source block — original paragraphs 4361–4362
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
RATTUS Ice Node
→ controle e debuffs.
Legacy source block — original paragraphs 4364–4366
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Encontrar outra criatura da mesma espécie não substitui perfeitamente a anterior.
Isso reforça o permadeath:
O jogador não perdeu apenas um RATTUS.
Legacy source block — original paragraphs 4368–4373
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Perdeu aquele RATTUS específico,
com determinada forma,
Node,
linhagem,
stats,
Modules e história.
Legacy source block — original paragraphs 4376–4391
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
9. Node não é item nem recompensa extraível
Um Variant Node nunca entra no inventário.
Ele não pode ser obtido por:
SCAN;
PURGE;
PURIFY;
drops;
crafting;

instalação;
transferência.
O jogador só consegue incorporar aquele Node ao seu parceiro através de TAME.
Encontrar uma variante
→ analisar o risco;
→ decidir se deseja substituir o parceiro atual;
→ realizar TAME;
→ assumir permanentemente aquele indivíduo.
Legacy source block — original paragraphs 4393–4393
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O Node pertence ao APK, não ao Operator.
Legacy source block — original paragraphs 4395–4406
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
10. Estados de integridade
10.1 Purified
Purified é o estado estável padrão.
Um APK Purified:
não recebe um Integrity Trait adicional obrigatório;
utiliza normalmente sua Species Signature;
mantém seu Variant Node;
utiliza seu Installed Passive;
evolui de maneira convencional;
possui comportamento previsível.
A ausência de um Trait extra não representa desvantagem.
A vantagem de Purified está em sua estabilidade e segurança.
Legacy source block — original paragraphs 4408–4414
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
10.2 EXE Trait
Um APK domado sem PURIFY mantém a condição EXE.
Ele recebe um EXE Trait intrínseco adicional.
Species Signature
+ Variant Node, quando houver
+ EXE Trait
+ Installed Passive
Legacy source block — original paragraphs 4416–4431
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O EXE Trait precisa possuir:
benefício real;
custo real;
consequência sistêmica;
impacto visual;
impacto narrativo.
Ele não deve funcionar como um bônus gratuito.

Exemplos de custo possíveis:
perda acelerada de Stability;
comportamento instável em Unstability;
incompatibilidade com determinados passivos;
cura reduzida;
risco de ação involuntária;
aumento de Corruption;
restrições evolutivas.
O custo principal deve ser claro e rastreável.
Legacy source block — original paragraphs 4433–4441
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
10.3 DEVIL Trait
DEVIL utiliza um Trait próprio.
Ele não é apenas uma versão numericamente superior do EXE Trait.
O DEVIL Trait deve modificar profundamente alguma regra de combate ou de construção de build.
Ele pode coexistir com um Variant Node:
Species Signature
+ Variant Node
+ DEVIL Trait
+ Installed Passive
Legacy source block — original paragraphs 4443–4443
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A transformação em DEVIL não remove o histórico anterior do indivíduo.
Legacy source block — original paragraphs 4445–4450
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
11. Legendary e outras qualidades especiais
Legendary não é um Variant Node.
Ele pertence a uma camada separada chamada Special Quality.
Isso permite distinguir:
Fire Node
→ variante ecológica e mecânica.
Legacy source block — original paragraphs 4452–4453
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Legendary
→ qualidade excepcional do indivíduo.
Legacy source block — original paragraphs 4455–4458
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A qualidade Legendary pode coexistir com um Node caso essa combinação seja permitida pelo conteúdo.
Legendary Fire Node
Legendary Defensive Node
Legendary sem Node

Legacy source block — original paragraphs 4460–4466
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
A aparência Legendary é aplicada depois da paleta do Node e da linhagem.
Sua recompensa mecânica específica precisa ser definida separadamente e não deve ser confundida com o 
funcionamento normal dos Nodes.
Até essa definição ser concluída, Legendary não altera automaticamente:
stats;
número de slots;
Stability Recovery;
evolução.
Legacy source block — original paragraphs 4468–4478
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
12. Interação com Player Actions
12.1 SCAN
SCAN permite obter Modules ativos do alvo.
SCAN não pode copiar:
Species Signature;
Variant Node;
Integrity Trait;
Special Quality;
Installed Passive equipado.
SCAN
→ Modules ativos.
Legacy source block — original paragraphs 4481–4490
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
12.2 PURGE
PURGE concede um Module ativo aleatório do alvo e EXP adicional.
PURGE não concede:
Nodes;
passivos;
Species Signature;
Integrity Traits.
PURGE
→ Module ativo aleatório
+ EXP aumentada.
Legacy source block — original paragraphs 4493–4497
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
12.3 PURIFY
PURIFY concede um Installed Passive associado ao alvo.
Ele não extrai o passivo fixo que aquele indivíduo possui.
PURIFY
→ Purification Passive Pool.

Legacy source block — original paragraphs 4499–4500
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
PURIFY também remove a condição EXE do alvo caso seja utilizado como preparação para TAME.
O Variant Node permanece.
Legacy source block — original paragraphs 4502–4507
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
12.4 TAME após PURIFY
Fluxo:
EXE com Node
→ PURIFY
→ TAME
→ parceiro Purified com o mesmo Node.
Legacy source block — original paragraphs 4509–4512
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Resultado:
Species Signature
+ Variant Node
+ Installed Passive
Legacy source block — original paragraphs 4515–4519
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
12.5 TAME sem PURIFY
Fluxo:
EXE com Node
→ TAME direto
→ parceiro EXE com o mesmo Node.
Legacy source block — original paragraphs 4521–4525
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Resultado:
Species Signature
+ Variant Node
+ EXE Trait
+ Installed Passive
Legacy source block — original paragraphs 4527–4527
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
O jogador ganha uma combinação passiva mais extensa, mas aceita os riscos permanentes da condição EXE.
Legacy source block — original paragraphs 4625–4625
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node aplica Burn.
Legacy source block — original paragraphs 4642–4642
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node:

Legacy source block — original paragraphs 4659–4659
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node
Legacy source block — original paragraphs 4691–4691
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node.
Legacy source block — original paragraphs 4758–4758
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
LEGENDARY
Legacy source block — original paragraphs 4761–4761
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
→ mecânica definida separadamente.
Legacy source block — original paragraphs 5146–5146
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node:
Legacy source block — original paragraphs 5149–5149
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node:
Legacy source block — original paragraphs 5157–5157
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node:
Legacy source block — original paragraphs 5160–5160
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node:
Legacy source block — original paragraphs 5789–5789
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
+ qualidade Legendary
Legacy source block — original paragraphs 5875–5875
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Defensive Node
Legacy source block — original paragraphs 5880–5880
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Fire Node
Legacy source block — original paragraphs 5885–5885
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Ice Node
Legacy source block — original paragraphs 5890–5890
[DEPRECATED SOURCE] Texto preservado literalmente do GDD original; sem autoridade sobre o corpo canônico.
Overclock Node
