# Configurar uma máquina para o MasterMail

## 1. Ferramentas
```
brew install gh swiftlint swiftformat xcodegen
gh auth login
git clone https://github.com/victortabs/mastermail.git ~/Developer/mastermail
```
Requer Xcode 26 ou mais novo (Mac com Apple silicon).

Para o plugin do GitHub funcionar, adicione ao `~/.zshrc`:
```
export GITHUB_PERSONAL_ACCESS_TOKEN=$(gh auth token)
```

## 2. Plugins do Claude Code
Já estão declarados em `.claude/settings.json`. Ao abrir o Claude Code dentro da pasta do projeto, ele pergunta se quer instalar. Aceite.

| Plugin | Origem | Fase |
|---|---|---|
| superpowers, microsoft-docs, context7, mcp-server-dev, claude-md-management, github | oficial (Anthropic) | planejamento |
| swift-lsp, security-guidance, pr-review-toolkit, commit-commands | oficial (Anthropic) | código |
| swiftui-expert | [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) | código |
| axiom | [CharlesWiltgen/Axiom](https://github.com/CharlesWiltgen/Axiom) | código |

## 3. Servidores MCP do Xcode (só na máquina de desenvolvimento)
```
claude mcp add --transport stdio xcode -s project -- xcrun mcpbridge
claude mcp add --transport stdio mobilebuildmcp -s project -- npx -y mobilebuildmcp@2.7.1 mcp
```
- **xcode**: servidor MCP oficial da Apple, vem com o Xcode 26.3+.
- **mobilebuildmcp** (antigo XcodeBuildMCP, da Sentry): build, testes e simulador. Versão fixada; atualize conscientemente.

Com `-s project` os comandos gravam um `.mcp.json` na raiz do repositório. Faça commit dele para as outras máquinas herdarem.
