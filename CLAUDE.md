# MasterMail — contexto para o Claude Code

- Cliente de e-mail nativo em Swift (Apple), open source no GitHub (repo público).
- Foco: velocidade, contas Microsoft (e-mail + calendário), IA para validação/organização de e-mails.
- **Fase atual: construção da v1** (planejamento fechado em 2026-10-13; ver `CONTEXT.md`, `docs/01-requisitos.md` e as ADRs). Antes de codar, ler `CONTEXT.md` e usar o vocabulário dele.
- Núcleo em `Core/` (pacote Swift `MasterMailCore`, sem SwiftUI/AppKit); app macOS em `App/` (ADR 0008).
- Projeto Xcode é gerado com `xcodegen` a partir de `project.yml`; não editar o `.xcodeproj` à mão.
- Documentação e conversas em português (pt-BR).
- Decisões técnicas ficam em `docs/decisoes/` (formato ADR, ver `0000-modelo.md`).
- Repo é público: nunca commitar chaves, tokens, client secrets ou e-mails reais.

## Agent skills

### Issue tracker

Issues ficam no GitHub Issues (`victortabs/mastermail`), via `gh`. Ver `docs/agents/issue-tracker.md`.

### Triage labels

Os cinco labels padrão: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. Ver `docs/agents/triage-labels.md`.

### Domain docs

Contexto único: `CONTEXT.md` na raiz e ADRs em `docs/decisoes/`. Ver `docs/agents/domain.md`.
