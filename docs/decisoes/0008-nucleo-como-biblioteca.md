# 0008 — Núcleo separado da interface, como biblioteca

- **Data:** 2026-10-13
- **Status:** aceita

## Contexto
O projeto quer, logo depois da v1, um CLI e um servidor MCP local que exponham o MasterMail a outras ferramentas e IAs. E, mais à frente, iOS.

## Opções consideradas
1. Um alvo só (app) e extrair depois.
2. Núcleo (sincronização, Índice local, Regras, cadeia de IA, Pasta local) como pacote Swift separado desde o início; app, CLI e MCP são cascas sobre ele.

## Decisão
Opção 2. Um pacote Swift `MasterMailCore` sem dependência de SwiftUI/AppKit; o app macOS é o primeiro cliente, o CLI o segundo.

## Consequências
- O CLI e o MCP viram trabalho pequeno quando o núcleo estiver estável.
- Custo: disciplina para não vazar UI no núcleo. Sem over-engineering: um pacote, não uma arquitetura em camadas.
