# Arquitetura (em estudo)

Decisões já tomadas aparecem riscadas, com o link para o ADR. Cada escolha vira um ADR em `decisoes/`.

## Temas para pesquisar
- ~~Acesso à Microsoft / autenticação~~ → Graph + MSAL ([ADR 0003](decisoes/0003-microsoft-graph-msal.md)).
- ~~Interface~~ → SwiftUI como base, AppKit onde o SwiftUI engasga (lista grande, editor, HTML). Sem Electron. macOS 26 como mínimo.
- **Armazenamento local / cache offline:** SwiftData, Core Data, SQLite (GRDB)…
- ~~IA~~ → local + nuvem opt-in ([ADR 0004](decisoes/0004-ia-local-nuvem-opt-in.md)).
- **Busca rápida:** índice local full-text (texto de todas as mensagens; HTML e anexos só recentes).
- ~~Distribuição~~ → release no GitHub + tap próprio, Sparkle, sem assinatura ([ADR 0007](decisoes/0007-login-proprio-sem-assinatura-apple.md)).
- ~~Estrutura~~ → núcleo como pacote Swift, app/CLI/MCP como cascas ([ADR 0008](decisoes/0008-nucleo-como-biblioteca.md)).
- **Armazenamento local:** SQLite (GRDB) com FTS5 é o candidato; decidir quando começar o código.
- **Conversas:** agrupar por `conversationIndex` do Graph (codifica a árvore de respostas); cabeçalhos como fallback.
- **Imagens remotas:** bloqueadas por padrão, liberadas por remetente/Organização.
