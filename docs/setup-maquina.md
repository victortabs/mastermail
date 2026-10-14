# Configurar uma máquina para o MasterMail

## 1. Ferramentas
```
brew install gh swiftlint swiftformat xcodegen
gh auth login
git clone https://github.com/victortabs/mastermail.git ~/Developer/mastermail
```
Requer Xcode 26 ou mais novo (Mac com Apple silicon) e macOS 26+.

## Compilar e rodar
```
xcodegen generate
xcodebuild -project MasterMail.xcodeproj -scheme MasterMail -configuration Debug -derivedDataPath build/DerivedData build
open build/DerivedData/Build/Products/Debug/MasterMail.app
```
Se o `xcode-select` apontar para o Command Line Tools, prefixe os comandos com `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

Testes do núcleo: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path Core`.

Testes de coordenação do app (servidor simulado, sem abrir a conta real):
```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project MasterMail.xcodeproj -scheme MasterMail -configuration Debug -derivedDataPath build/DerivedData -destination 'platform=macOS,arch=arm64' test
```

Se aparecer erro de macro `TestingMacros` com o Command Line Tools, use o `DEVELOPER_DIR` acima. O projeto usa as macros e frameworks do Xcode completo.

Primeiro login: precisa do Client ID do Entra, ver [03-entra.md](03-entra.md).

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
