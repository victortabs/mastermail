# MasterMail

Cliente de e-mail **nativo em Swift** para Apple, rápido, compatível com **Microsoft (Outlook/Exchange/365) e Calendário**, com **IA integrada** para validar, organizar e priorizar e-mails.

> 🚧 **Status: construção da v1.** Planejamento fechado; o glossário está em [CONTEXT.md](CONTEXT.md) e as decisões em [docs/decisoes/](docs/decisoes/).

## Documentação

| Documento | Conteúdo |
|---|---|
| [CONTEXT.md](CONTEXT.md) | Glossário do domínio |
| [docs/00-visao.md](docs/00-visao.md) | O que é, para quem, objetivos |
| [docs/01-requisitos.md](docs/01-requisitos.md) | Funcionalidades e requisitos |
| [docs/02-arquitetura.md](docs/02-arquitetura.md) | Opções técnicas em estudo |
| [docs/03-entra.md](docs/03-entra.md) | Registrar o app no Entra e obter o Client ID |
| [docs/setup-maquina.md](docs/setup-maquina.md) | Compilar e rodar |
| [docs/ideias.md](docs/ideias.md) | Caixa de entrada de ideias soltas |
| [docs/pesquisa/](docs/pesquisa/reports/) | Pesquisas de mercado e técnicas |
| [docs/decisoes/](docs/decisoes/) | Registro de decisões técnicas (ADRs) |

## Conta e dados pessoais

O login Microsoft é restaurado ao reabrir o aplicativo, com renovação automática da autorização. Falhas temporárias de conexão preservam a sessão; uma revogação pela Microsoft pode exigir novo login.

Tokens de acesso, configurações pessoais e o Índice local ficam em `~/Library/Application Support/MasterMail/`, fora da pasta do código. Esses dados não são enviados ao GitHub. O arquivo de tokens tem permissões restritas ao usuário do Mac, mas não recebe criptografia adicional do aplicativo. Não compartilhe essa pasta em issues, anexos ou diagnósticos.

## Licença

[GPL-3.0](LICENSE).
