# 0003 — Microsoft Graph + MSAL para acesso à conta

- **Data:** 2026-10-13
- **Status:** aceita para o Graph; a parte de autenticação (MSAL) foi **substituída pela ADR 0007** (login OAuth próprio, sem assinatura da Apple)

## Contexto
O EWS está sendo desligado. IMAP com OAuth não tem calendário e sofre o mesmo bloqueio de consentimento. Ver `docs/pesquisa/reports`.

## Opções consideradas
1. Microsoft Graph.
2. IMAP/SMTP com OAuth.
3. EWS.

## Decisão
Microsoft Graph para e-mail e calendário, com autenticação via MSAL (iOS/macOS 2.x, exige macOS 14 ou mais novo).

## Consequências
- Limites: 4 requisições simultâneas por caixa postal; delta é uma pasta por vez → índice de busca local obrigatório.
- Consentimento de administrador é o maior risco: fazer a verificação de editor cedo, pedir permissões aos poucos e oferecer a URL de consentimento para o TI.
- Notificações em tempo real exigem webhook; no Mac começamos com polling do delta (30–60 s).
- Redirect URIs restritos ao bundle do MasterMail; forks registram o próprio client ID.
