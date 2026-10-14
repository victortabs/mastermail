# 0006 — Pasta local gravada na própria mensagem no servidor

- **Data:** 2026-10-13
- **Status:** aceita; a regra "uma Pasta local por mensagem" foi substituída pela [0010](0010-pastas-como-visoes.md). O mecanismo (propriedade na mensagem) continua.

## Contexto
O usuário quer organizar mensagens em pastas dentro do MasterMail sem mexer nas pastas do Outlook (no celular tudo deve continuar na Caixa de Entrada). Mas quer que a organização apareça igual em outro Mac e sobreviva a uma reinstalação.

## Opções consideradas
1. Guardar a Pasta local como propriedade oculta da mensagem no servidor (extended property / open extension do Graph).
2. Banco local sincronizado por iCloud Drive.
3. Banco local sem sincronia, com exportar/importar.

## Decisão
Opção 1. A Pasta local de cada mensagem é uma propriedade própria do MasterMail gravada na mensagem, que o Outlook ignora e não exibe.

## Consequências
- Sincroniza com a conta, sem arquivo nem serviço extra; reinstalar não perde nada.
- A organização é por conta, não por instalação.
- Cada mudança de pasta é uma escrita no Graph (conta no limite de requisições concorrentes).
- A lista de nomes de Pastas locais também precisa viver na conta (propriedade na caixa postal ou numa mensagem de configuração), não só a atribuição por mensagem.
- Atenção à quota de propriedades estendidas relatada em cenários de envio em massa; usar uma única propriedade nomeada reutilizada.
