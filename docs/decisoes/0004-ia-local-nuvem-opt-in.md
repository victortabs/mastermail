# 0004 — IA local por padrão, nuvem só com opt-in

- **Data:** 2026-10-13
- **Status:** aceita

## Contexto
O Foundation Models da Apple é gratuito e offline, mas tem uma janela de ~4.096 tokens. Serve para classificar, extrair dados e detectar golpe, mas não para resumir conversas longas.

## Opções consideradas
1. Local + nuvem opt-in.
2. Só local.
3. Só nuvem.

## Decisão
Cadeia, do mais barato ao mais caro, parando no primeiro que resolve:
1. **Regra** existente: determinística, zero tokens.
2. **Modelo local** (Foundation Models), quando o Mac tiver Apple Intelligence: classificar, extrair, tarefas curtas.
3. **Nuvem via OpenRouter**, só com opt-in explícito e **chave de API do próprio usuário** (sem servidor do projeto): resumos longos, rascunhos, perguntas sobre a caixa inteira, e classificação quando não houver modelo local.

O provedor de nuvem é qualquer modelo acessível pela OpenRouter (API compatível com OpenAI), não um fornecedor fixo. Tudo o que for gerado por IA aparece rotulado.

## Consequências
- Custo marginal zero no uso básico; privacidade por padrão.
- Falta validar: qualidade em pt-BR e o modo degradado em Macs sem Apple Intelligence.
- Resolvido: chave do próprio usuário. Sem conta nem servidor do projeto.
- Com a nuvem ligada, remetente, assunto e trecho de cada mensagem nova podem ir para a OpenRouter. O usuário (ou o TI dele) decide isso ao ligar.
