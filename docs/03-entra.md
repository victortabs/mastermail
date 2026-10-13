# Registrar o MasterMail no Entra (Microsoft 365)

O MasterMail faz login com OAuth próprio, sem segredo (ADR 0007). Para isso a conta Microsoft precisa conhecer o app. Quem tem permissão de admin no tenant faz isso uma vez; o resultado é um **Client ID**, que é público e pode ficar no repositório.

## 1. Criar o registro

1. Abra o [Entra admin center](https://entra.microsoft.com) → **Identity → Applications → App registrations → New registration**.
2. **Name:** `MasterMail`.
3. **Supported account types:** "Accounts in any organizational directory and personal Microsoft accounts" (multi-tenant). Para uso só no próprio escritório, "single tenant" também funciona.
4. **Redirect URI:** plataforma **Mobile and desktop applications**, URI personalizada:
   ```
   msauth.io.github.victortabs.mastermail://auth
   ```
5. **Register**. Copie o **Application (client) ID**.

## 2. Permitir cliente público

Em **Authentication → Advanced settings → Allow public client flows:** **Yes**. Salve.

## 3. Permissões (delegadas, Microsoft Graph)

Em **API permissions → Add a permission → Microsoft Graph → Delegated**:

| Permissão | Para quê |
|---|---|
| `User.Read` | nome e e-mail da conta |
| `Mail.ReadWrite` | ler, marcar, Categoria, Pasta local (propriedade na mensagem) |
| `Mail.Send` | enviar, responder, envio programado |
| `offline_access` | manter o login sem pedir senha toda hora |

Depois: **Grant admin consent for <tenant>**. Sem isso, usuários comuns veem "Need admin approval" (política padrão da Microsoft desde nov/2025).

Calendário e Contatos (`Calendars.ReadWrite`, `Contacts.Read`) entram quando essas telas existirem; o app pedirá na hora.

## 4. Colocar o Client ID no app

Duas opções:

- **Na primeira abertura** o app pede o Client ID; cole e pronto (fica em UserDefaults).
- **No build**, edite `App/Config.xcconfig`:
  ```
  MASTERMAIL_CLIENT_ID = 00000000-0000-0000-0000-000000000000
  ```
  e rode `xcodegen generate` de novo.

## Forks

Quem faz fork registra o próprio app (passos acima) e troca o Client ID. Não reutilize o ID de outro projeto: o redirect URI está preso ao bundle `io.github.victortabs.mastermail`.
