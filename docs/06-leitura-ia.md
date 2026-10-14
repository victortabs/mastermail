# Leitura da caixa com IA barata

> **Status:** proposta, 2026-10-14. Nasceu da análise de dois meses de caixa real (1.243 mensagens, 14/08 a 14/10/2026), feita com um modelo grande e depois repassada a um modelo barato (Haiku) com medição. Os dados reais ficam em `private-data/caixa/` (fora do git); aqui só o que vale para qualquer usuário.

## O que a caixa mostrou

| | |
|---|---|
| Ruído automático (newsletter, promoção, aviso de sistema) | 44%, quase todo resolvível por Regra de domínio |
| Trabalho | 56%, em ~275 Conversas |
| Mensagens da própria equipe do usuário | 29% do volume, 22% lidas |
| **Mensagens que pediam algo ao usuário** | **~6%** (~1,5 por dia útil) |

Três achados mudam o desenho da IA:

1. **O eixo é o projeto, não o remetente.** Num usuário que toca obras (e o mesmo vale para quem toca clientes, casos ou contas), cada mensagem pertence a um projeto, e 86% delas o identificam só pelo assunto. Pasta local por Organização não basta: uma Organização tem vários projetos, e um projeto envolve várias Organizações (cliente, arquiteto, fornecedor, seguradora, shopping).
2. **Cada mensagem está numa etapa do ciclo do projeto**, e as etapas são as mesmas para todos os projetos: concorrência, contrato, documentação, execução, compras, faturamento, pagamento, entrega. É a dimensão transversal que a Categoria (visível no celular) deveria carregar.
3. **"Importante" não basta; falta "é comigo".** O usuário está em cópia de quase tudo. O que ele quer ver primeiro é o pequeno conjunto que pede ação **dele**, separado do que pede ação da equipe.

## Fluxo proposto

```
mensagem nova
  │
  ├─ 1. Regra (zero tokens) ─ remetente, domínio ou domínio + assunto
  │     ~40% resolvidas aqui: ruído, faturas, fluxo interno de pagamento
  │     em que o usuário só está em cópia.
  │     Nunca resolve contrato e assinatura: esses vão sempre ao modelo
  │
  ├─ 2. Limpeza (zero tokens) ─ corta histórico citado, assinatura, aviso legal,
  │     bloco de reunião do Teams; texto médio cai para ~560 caracteres
  │
  ├─ 3. Modelo barato, em lote ─ recebe o Contexto do usuário (papel, equipe,
  │     lista de projetos) + até 25 mensagens; devolve um JSON por mensagem
  │
  └─ 4. Visões ─ "Com você" · "Atenção, com a equipe" · "Por projeto" · Triagem
```

A ordem é a da ADR 0004 (Regra → modelo local → nuvem). O passo 3 cabe no modelo local quando o lote for pequeno; a nuvem entra para lotes grandes.

## O que o modelo devolve

```json
{"id":"…","tipo":"pessoa","obra":"<chave da lista>","etapa":"orcamento",
 "acao":"responder","quem":"eu","prazo":"2026-10-22","importante":false,
 "resumo":"≤ 20 palavras","justificativa":"≤ 15 palavras"}
```

| campo | valores | para que serve |
|---|---|---|
| `tipo` | os seis Tipos do CONTEXT.md | Ruído ou não (já existe) |
| `obra` | chave de uma lista mantida pelo usuário, `nova: …` ou nulo | agrupar por projeto |
| `etapa` | orcamento, contrato, documentos, execucao, compras, medicao, pagamento, entrega, administrativo, pessoal | virar Categoria no servidor |
| `acao` | responder, aprovar, assinar, providenciar, nenhuma | o que a mensagem pede |
| `quem` | eu, equipe, externo, ninguem | separa "com você" de "com a equipe" |
| `prazo` | data ou nulo | ordenar e lembrar |
| `importante` | critério fechado (abaixo) | única notificação do Mac |

**Importante** só quando: risco de paralisação, multa, processo ou perda de dinheiro; prazo em até 2 dias úteis e `quem` = eu; resultado de concorrência; cliente reclamando; decisão do usuário sobre dinheiro ou jurídico. Conversa jurídica em andamento sem fato novo não conta.

As regras completas de decisão, com as armadilhas encontradas, estão na skill [`.claude/skills/leitura-caixa/SKILL.md`](../.claude/skills/leitura-caixa/SKILL.md).

## Medição com o Haiku

60 mensagens sorteadas (metade com o usuário citado, metade em cópia), classificadas antes pelo modelo grande como gabarito. O Haiku recebeu só a skill.

| campo | 1ª rodada | 2ª rodada |
|---|---|---|
| É com você (`quem` = eu e há ação) | 94%, 3 perdidos | **100%, nenhum perdido** |
| Projeto | 100% | 98% |
| Etapa | 94% | 96% |
| Tipo | 98% | 98% |
| Prazo | 93% | 94% |
| Importante | 89% | 93%, erra para mais |

Entre as rodadas entraram duas regras: revisão de projeto pedindo aprovação "a todos" é com o usuário; decisão sobre dinheiro/jurídico é Importante. Para repetir a medição: `relatorio.py --comparar` (ver a skill).

**Volume para o app:** ~17 mensagens por dia útil chegam ao passo 3. Em lote, isso é uma chamada por dia de ~8 mil tokens de entrada (instruções + Contexto + mensagens) e ~1,5 mil de saída.

## O que precisa mudar no app

| # | Mudança | Por quê |
|---|---|---|
| 1 | Guardar **Para** e **Cc** separados no Índice local | Hoje vêm misturados em `recipients`; "estou em cópia" é o sinal mais barato para decidir `quem` |
| 2 | **Contrato e assinatura nunca por Regra** | Assinatura eletrônica mistura pedido ("Complete com / Assinar") com aviso ("Concluído / Lembrete"). Uma Regra por domínio mandaria o pedido de assinatura de um contrato para a Triagem. Assunto com contrato, minuta, assinatura, aditivo ou procuração, e remetentes de assinatura eletrônica, jurídico e seguradora, vão sempre ao modelo |
| 3 | Limpeza do corpo antes de qualquer modelo | Histórico citado multiplica tokens e confunde quem pediu o quê |
| 4 | **Contexto do usuário** editável (papel, equipe, projetos) | Sem ele o modelo não distingue "com você" de "com a equipe". O app pode propor a lista de projetos a partir dos assuntos |
| 5 | Classificação em lote, não uma chamada por mensagem | O texto de instruções e o Contexto são pagos uma vez por lote |
| 6 | Resumo nunca copia CPF, senha, login, dados bancários | Esses dados circulam no corpo de mensagens reais |
| 7 | Corrigir o papel do usuário no prompt `organizer` | Hoje descreve "engenheiro que comanda o TI"; o perfil certo vem do Contexto |
| 8 | Etapa `pessoal` nunca é Ruído | Vida pessoal chega pela mesma caixa |

## Termos novos para o CONTEXT.md (a aprovar)

- **Projeto**: o trabalho a que uma Mensagem pertence (uma obra, um caso, uma conta). Vem de uma lista mantida pelo usuário; a IA atribui. Uma Mensagem tem no máximo um. _Evitar_: job, pasta, tag.
- **Etapa**: em que ponto do ciclo do Projeto a Mensagem está. Conjunto pequeno e fixo; é o que a IA grava como Categoria.
- **Com você**: Mensagem que pede uma ação ao próprio usuário (não à equipe dele). Primeira visão da Caixa de entrada.
- **Contexto do usuário**: papel, equipe e lista de Projetos que a IA lê antes de classificar. Não confundir com **Contexto** da Aba lateral; pode precisar de outro nome.

## Como rodar hoje, fora do app

Com o Claude Code nesta pasta: "lê a caixa" aciona a skill `leitura-caixa`, que roda com Haiku. Ela lê o Índice local em modo só leitura, nunca toca o servidor e grava tudo em `private-data/caixa/`. O perfil do usuário fica em `private-data/caixa/perfil.json` (modelo em `.claude/skills/leitura-caixa/perfil.exemplo.json`).

## Pastas, pessoas e resumos (pedido de 2026-10-14)

- **Uma mensagem em várias pastas.** Pastas viram visões sobre Projeto, Cliente, Etapa e `quem`: a mesma mensagem aparece em Com você, na pasta da obra e dentro do Cliente. Orçamento ganho vira obra na mesma pasta. Proposta na [ADR 0010](decisoes/0010-pastas-como-visoes.md).
- **Pedidos de orçamento.** O modelo marca `fase` em toda mensagem de concorrência (`pedido`, `proposta`, `ganho`, `perdido`). A pasta "Pedidos novos" é `fase` = `pedido`. Palavra-chave no assunto não serve: "convite" e "BID" também aparecem em convites de reunião e respostas automáticas.
- **Pessoas em cópia.** Média de 6,7 pessoas por mensagem de trabalho; ~1.150 pessoas distintas em dois meses, ~130 recorrentes. Guardar todas, com Organização, papel e Projetos em que aparecem. O grupo de um Projeto (quem costuma estar junto) serve para mostrar quem é quem, reconhecer o Projeto pelos copiados sem modelo e sugerir destinatários.
- **Resumo automático.** ~15% das Conversas de trabalho têm 4 mensagens ou mais e concentram metade das mensagens. Nelas, o Resumo passa a ser automático e incremental: resumo anterior + mensagem nova, sem reler a Conversa inteira.
