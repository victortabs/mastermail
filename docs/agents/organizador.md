# Agente organizador da caixa

Como um agente (o Haiku dentro do app, ou um agente externo como o Claude Code) propõe a organização inicial da caixa.

## Entrada: perfil agregado

O app monta um perfil **sem corpos de mensagem**: por domínio remetente, volume, % lidas, quantas vezes o usuário escreveu para o domínio e três assuntos de exemplo (`MailStore.profile`). Um agente externo consegue o mesmo com SQL no Índice local:

```
~/Library/Application Support/MasterMail/mail.sqlite
```

## Saída: `organization-plan.json`

O agente grava a proposta em `~/Library/Application Support/MasterMail/organization-plan.json`:

```json
{
  "summary": "3 frases sobre o que viu",
  "rules": [
    {"field": "domain", "value": "substack.com", "tipo": "newsletter", "pastaLocal": null, "reason": "boletim, 29% lido, nunca respondido"},
    {"field": "domain", "value": "bdil.com.br", "tipo": "pessoa", "pastaLocal": "Bacio di Latte", "reason": "cliente, 153 respostas"}
  ],
  "folders": [{"name": "Bacio di Latte", "description": "obras e RFPs", "domains": ["bdil.com.br"]}],
  "categories": ["Obra", "Financeiro"]
}
```

- `field`: `sender` (endereço exato), `domain`, `subjectContains`.
- `tipo`: `pessoa | newsletter | notificacao | promocao | financeiro | convite`. Ruído = newsletter, notificacao, promocao.
- `pastaLocal`: Pasta local de destino ou `null`.

## O que o app faz com isso

O arquivo é uma **Sugestão** (CONTEXT.md): aparece na tela "Organizar a caixa" (varinha na seção Pastas locais, ou ⌘K → Organizar). O usuário marca o que aceita. Ao aplicar:

1. Pastas locais são criadas.
2. Regras aceitas entram como **automáticas**: classificam o índice inteiro na hora (zero tokens); ruído coberto sai da Caixa de entrada direto para "Ruído".
3. Com "mover existentes" ligado, as mensagens que casam com regras de pasta vão para a Pasta local, e a propriedade é gravada no servidor pela fila offline (ADR 0006).
4. O arquivo é apagado. Regras ficam em ⌘, → Regras.

## Dentro do app

"Gerar proposta nova com o modelo" usa `openRouterHeavyModel` (padrão `anthropic/claude-haiku-5.5`) com a chave da OpenRouter do usuário (ADR 0004). O prompt está em `Core/Sources/MasterMailCore/AI/Prompts.swift` (`organizer`).

## Privacidade

Nunca commitar o perfil, o plano nem domínios de clientes no repositório: são dados do usuário. Ficam só em Application Support.

## Leitura contínua

A organização inicial (acima) olha domínios. A leitura do dia a dia, mensagem por mensagem, com Projeto, Etapa e "com você", está em [06-leitura-ia.md](../06-leitura-ia.md) e na skill `.claude/skills/leitura-caixa/`.
