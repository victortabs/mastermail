# Issue tracker: GitHub

Issues e specs deste repo ficam no GitHub Issues. Use o `gh` CLI para todas as operações.

## Convenções

- **Criar issue**: `gh issue create --title "..." --body "..."`. Use heredoc para corpo com várias linhas.
- **Ler issue**: `gh issue view <número> --comments`, filtrando comentários com `jq` e buscando também os labels.
- **Listar issues**: `gh issue list --state open --json number,title,body,labels,comments --jq '[.[] | {number, title, body, labels: [.labels[].name], comments: [.comments[].body]}]'` com os filtros `--label` e `--state` adequados.
- **Comentar**: `gh issue comment <número> --body "..."`
- **Aplicar / remover labels**: `gh issue edit <número> --add-label "..."` / `--remove-label "..."`
- **Fechar**: `gh issue close <número> --comment "..."`

O repo é inferido pelo `git remote -v`; o `gh` faz isso sozinho dentro do clone.

Lembrete: o repo é público. Nunca coloque chaves, tokens, client secrets ou e-mails reais em issues ou comentários.

## Pull requests como fonte de pedidos

**PRs como fonte de pedidos: não.** _(Mude para `sim` se este repo tratar PRs externos como pedidos de funcionalidade; o `/triage` lê esta flag.)_

Quando estiver em `sim`, PRs passam pelos mesmos labels e estados das issues, usando os equivalentes `gh pr`:

- **Ler PR**: `gh pr view <número> --comments` e `gh pr diff <número>` para o diff.
- **Listar PRs externos para triagem**: `gh pr list --state open --json number,title,body,labels,author,authorAssociation,comments` e manter só `authorAssociation` igual a `CONTRIBUTOR`, `FIRST_TIME_CONTRIBUTOR` ou `NONE` (descartar `OWNER`/`MEMBER`/`COLLABORATOR`).
- **Comentar / label / fechar**: `gh pr comment`, `gh pr edit --add-label`/`--remove-label`, `gh pr close`.

O GitHub usa a mesma numeração para issues e PRs, então um `#42` solto pode ser qualquer um: resolva com `gh pr view 42` e, se falhar, `gh issue view 42`.

## Quando um skill disser "publish to the issue tracker"

Crie uma issue no GitHub.

## Quando um skill disser "fetch the relevant ticket"

Rode `gh issue view <número> --comments`.

## Operações de wayfinding

Usadas pelo `/wayfinder`. O **mapa** é uma única issue com issues **filhas** como tickets.

- **Mapa**: uma issue com o label `wayfinder:map`, contendo as seções Notes / Decisions-so-far / Fog. `gh issue create --label wayfinder:map`.
- **Ticket filho**: issue ligada ao mapa como sub-issue do GitHub (`gh api` no endpoint de sub-issues). Onde sub-issues não estiverem habilitadas, adicione o filho a uma task list no corpo do mapa e coloque `Part of #<mapa>` no topo do corpo do filho. Labels: `wayfinder:<tipo>` (`research`/`prototype`/`grilling`/`task`). Ao ser assumido, o ticket é atribuído a quem está conduzindo.
- **Bloqueio**: as **dependências nativas de issue** do GitHub, a representação canônica e visível na UI. Adicione com `gh api --method POST repos/<owner>/<repo>/issues/<filho>/dependencies/blocked_by -F issue_id=<id-do-bloqueador>`, onde `<id-do-bloqueador>` é o **database id** numérico (`gh api repos/<owner>/<repo>/issues/<n> --jq .id`, _não_ o `#número` nem o `node_id`). O GitHub informa `issue_dependencies_summary.blocked_by` (só bloqueadores abertos). Sem dependências disponíveis, use uma linha `Blocked by: #<n>, #<n>` no topo do corpo do filho. Um ticket está desbloqueado quando todos os bloqueadores estão fechados.
- **Consulta de fronteira**: liste os filhos abertos do mapa (`gh issue list --state open`, restrito às sub-issues / task list do mapa), descarte os que têm bloqueador aberto (`issue_dependencies_summary.blocked_by > 0`, ou issue aberta na linha `Blocked by`) ou responsável atribuído; o primeiro na ordem do mapa vence.
- **Assumir**: `gh issue edit <n> --add-assignee @me`, a primeira escrita da sessão.
- **Resolver**: `gh issue comment <n> --body "<resposta>"`, depois `gh issue close <n>`, depois acrescente um ponteiro de contexto (resumo + link) em Decisions-so-far do mapa.
