# Visão

## Em uma frase
Um cliente de e-mail nativo, rápido e open source, que usa IA para tirar o trabalho braçal da caixa de entrada.

## Por que existe
- Uso próprio no dia a dia (eu sou o primeiro usuário).
- Projeto público no GitHub.

## Objetivos
1. **Rápido** — abrir, buscar e navegar sem espera.
2. **Compatível com Microsoft** — e-mail e calendário (Outlook / Exchange / Microsoft 365).
3. **IA integrada** — validar, classificar e organizar e-mails.

## Decisões tomadas
- Plataforma: só macOS na v1 ([ADR 0001](decisoes/0001-plataforma-macos.md)).
- Provedores: só Microsoft ([ADR 0002](decisoes/0002-somente-microsoft.md)), via Graph + MSAL ([ADR 0003](decisoes/0003-microsoft-graph-msal.md)).
- IA: local por padrão, nuvem com opt-in ([ADR 0004](decisoes/0004-ia-local-nuvem-opt-in.md)).
- Licença: GPL-3.0 ([ADR 0005](decisoes/0005-licenca-gpl3.md)).
- Pasta local gravada na mensagem, no servidor ([ADR 0006](decisoes/0006-pasta-local-na-mensagem.md)).
- Login OAuth próprio e distribuição sem assinatura da Apple ([ADR 0007](decisoes/0007-login-proprio-sem-assinatura-apple.md)).
- Núcleo como biblioteca, app/CLI/MCP como cascas ([ADR 0008](decisoes/0008-nucleo-como-biblioteca.md)).

## Fora do escopo (por enquanto)
- iOS / iPadOS.
- Gmail, iCloud, IMAP genérico (para e-mail; agenda do iCloud é visível e Lembretes são editáveis, ver adendo da ADR 0002).
- Servidor próprio (relay de push).
