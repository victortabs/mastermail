# Arquitetura

O MasterMail tem duas camadas: `MasterMailCore`, pacote Swift com as operações de domínio e persistência, e o app macOS em SwiftUI. O núcleo não depende de SwiftUI ou AppKit; usa Foundation, GRDB, FoundationModels e EventKit nas integrações próprias da plataforma.

| Responsabilidade | Implementação |
|---|---|
| Autenticação Microsoft | OAuth Authorization Code com PKCE; tokens em arquivo privado; sessão visual no app |
| Caixa postal e agenda Microsoft | `GraphClient`, actor com renovação compartilhada de token e pausa por throttling |
| Índice local | `MailStore`, SQLite/GRDB com FTS5 e migrações |
| Sincronização | `MailSync`, delta por pasta; polling e primeira indexação coordenados pelo app |
| Ações offline | `ActionQueue`, actor com arquivo JSON persistido e execução em ordem |
| Pastas locais | Propriedade estendida na mensagem Microsoft e representação no índice |
| IA | Regras determinísticas, FoundationModels quando disponível e OpenRouter com opt-in |
| Interface | SwiftUI; WKWebView para corpos HTML com recursos remotos bloqueados por padrão |
| Composição | Rascunho Microsoft, editor rich text, gravação automática e timer local de desfazer envio |
| Agenda do Mac e Lembretes | EventKit |
| Projeto e testes | `project.yml` gera o projeto pelo XcodeGen; Swift Testing no pacote e no alvo de testes do app |

A v1 usa uma conta Microsoft por instalação. O índice registra a identidade proprietária e impede reutilização por outra conta. Pastas do servidor são descobertas em todos os níveis para indexação; a interface navega nas pastas padrão e nas Pastas locais.

Os testes de coordenação compilam as views e modelos sem o ponto de entrada `MasterMailApp`, usam servidor simulado e não inicializam a conta pessoal. Os testes do núcleo rodam com `swift test` usando o Xcode completo.

## Decisões

- [ADR 0001](decisoes/0001-plataforma-macos.md): macOS nativo.
- [ADR 0003](decisoes/0003-microsoft-graph-msal.md) e [ADR 0007](decisoes/0007-login-proprio-sem-assinatura-apple.md): Microsoft Graph, OAuth próprio, assinatura ad-hoc e distribuição planejada pelo GitHub/Homebrew.
- [ADR 0004](decisoes/0004-ia-local-nuvem-opt-in.md): IA local e nuvem opt-in.
- [ADR 0006](decisoes/0006-pasta-local-na-mensagem.md): Pasta local gravada na mensagem.
- [ADR 0008](decisoes/0008-nucleo-como-biblioteca.md): núcleo como biblioteca para futuras interfaces.

## Evolução necessária

`AppModel` concentra coordenação de conta, sincronização, leitura, ações e envio. Separar essas responsabilidades com testes de comportamento facilita a próxima etapa. Persistência da Caixa de saída, recuperação de delta inválido e conclusão dos fluxos de regras, rascunhos e agenda estão detalhadas na [avaliação de 13/10/2026](avaliacao-2026-10-13.md).
