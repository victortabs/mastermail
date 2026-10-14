# 0009 — Permissões do Mac e assinatura local fixa

- **Data:** 2026-10-14
- **Status:** aceita (complementa a ADR 0007 para compilações de uso pessoal)

## Contexto

O macOS identifica a assinatura ad-hoc pelo hash daquela compilação. Recompilar o app pode invalidar o reconhecimento das permissões concedidas anteriormente. O aplicativo também solicitava acesso ao calendário ao restaurar a conta de e-mail, sem consultar primeiro a autorização do EventKit.

## Opções consideradas

1. Continuar exclusivamente com assinatura ad-hoc e repetir a autorização depois de compilar.
2. Pagar o Apple Developer Program para obter uma identidade Apple.
3. Usar uma identidade própria e fixa somente na máquina de desenvolvimento e corrigir o ciclo de pedidos de acesso.

## Decisão

- Consultar o estado real da autorização antes de pedir acesso a calendário ou lembretes; respeitar recusas e compartilhar pedidos simultâneos.
- Ao restaurar a conta, reutilizar permissões existentes. O primeiro pedido ao calendário do Mac acontece ao abrir a agenda.
- Permitir uma identidade local opcional em `App/Signing.xcconfig.local`, ignorado pelo Git. Manter a chave privada no Keychain e usar o mesmo certificado nas próximas compilações.
- Manter assinatura ad-hoc como padrão para máquinas que não configuraram a identidade local. Não alterar proteções do macOS nem editar o banco de permissões.

## Consequências

A mudança inicial de identidade pode exigir uma nova autorização pelo usuário. A identidade própria permite testar a preservação de permissões entre versões no Mac local, sem assinatura paga. Não oferece Developer ID, notarização nem confiança automática para outros Macs. Cada desenvolvedor configura sua identidade privada; o repositório contém somente as referências opcionais e os testes com autorizações simuladas.

## Referências

- [Apple — TN3127: Inside Code Signing: Requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements)
- [Apple — macOS Code Signing In Depth](https://developer.apple.com/library/archive/technotes/tn2206/_index.html)
- [Apple — EKAuthorizationStatus](https://developer.apple.com/documentation/eventkit/ekauthorizationstatus)
