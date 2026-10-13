# 0007 — Login OAuth próprio e distribuição sem assinatura da Apple

- **Data:** 2026-10-13
- **Status:** aceita (substitui a parte "MSAL" da ADR 0003; o Graph continua)

## Contexto
O dono do projeto decidiu não pagar o Apple Developer Program (US$ 99/ano) por enquanto. Sem ele não há assinatura Developer ID nem notarização. Consequências verificadas (2026-10-13):
- O MSAL guarda o cache de tokens no keychain protegido, que exige Team ID e provisioning profile. Em app não assinado, a Microsoft documenta que ele pede credenciais a cada aquisição de token.
- O Homebrew 5 descontinuou `--no-quarantine` e desabilita casks não assinados no tap oficial desde setembro de 2026.
- No macOS 15+ o Gatekeeper exige Ajustes → Privacidade e Segurança → "Abrir mesmo assim".

## Opções consideradas
1. Pagar o programa e manter MSAL + Homebrew oficial.
2. Login OAuth escrito no projeto, token em arquivo, distribuição por release no GitHub e tap próprio do Homebrew.
3. Manter MSAL sem assinatura (login a cada renovação).

## Decisão
Opção 2.
- **Login:** fluxo Authorization Code + PKCE contra o endpoint v2 do Entra, com `ASWebAuthenticationSession`. Sem MSAL. Redirect `msauth.<bundle id>://auth` registrado no Entra.
- **Token:** refresh token guardado em arquivo com permissão 0600 em `~/Library/Application Support/MasterMail/`, não no Keychain (com assinatura ad-hoc o Keychain abre diálogo a cada build).
- **Distribuição:** binário assinado ad-hoc, publicado como release no GitHub; tap próprio do Homebrew (`victortabs/homebrew-mastermail`); instruções de `xattr -d com.apple.quarantine` e "Abrir mesmo assim".
- **Atualização:** Sparkle 2 com chave EdDSA (funciona com assinatura ad-hoc). Não ligar Hardened Runtime com Library Validation.

## Consequências
- Token em texto puro no disco, protegido só por permissão de arquivo. Risco aceito para uso pessoal; documentar no README.
- Fricção de instalação para outros usuários. É o preço de não pagar.
- Sem broker nem SSO; já era assim com MSAL no macOS.
- **Reabrir** quando: alguém com Developer ID quiser assinar os releases, ou quando o número de usuários justificar os US$ 99. Nesse momento, voltar ao MSAL é trocar o módulo de login; o resto do app não muda.
