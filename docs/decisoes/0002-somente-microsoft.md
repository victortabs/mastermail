# 0002 — Só contas Microsoft no início

- **Data:** 2026-10-13
- **Status:** aceita

## Contexto
Posição de mercado: "um Mimestream para Microsoft 365". Os clientes premium mais usados ignoram o M365.

## Opções consideradas
1. Só Microsoft.
2. Microsoft + Gmail.
3. Microsoft + IMAP genérico.

## Decisão
Só Microsoft (Microsoft 365 / Exchange Online e Outlook.com).

## Consequências
- Uma API, um fluxo de autenticação, menos superfície de teste.
- Usuários com contas mistas precisam de outro cliente por enquanto.

## Adendo (2026-10-13)
"Só Microsoft" vale para **e-mail**. Agenda e tarefas:
- Agenda Microsoft (Graph): leitura e escrita completas.
- Agenda do Mac (EventKit, inclui iCloud): só visualização.
- Lembretes (EventKit, iCloud): leitura e escrita. Tarefas criadas a partir de e-mail nascem aqui, não no Microsoft To Do.
