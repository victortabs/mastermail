---
name: leitura-caixa
description: Lê os e-mails novos do Índice local do MasterMail e classifica cada um (Tipo, Obra, Etapa, ação, prazo, Importante), gerando o resumo "o que é comigo" por Obra. Use quando o usuário pedir para ler, triar, resumir ou organizar a caixa, ou "o que chegou hoje". Feita para rodar com Haiku.
model: haiku
---

# Leitura da caixa

O trabalho mecânico é dos scripts; você só julga. Nunca leia o banco direto, nunca envie e-mail, nunca altere nada no servidor.

## Passos

1. `python3 .claude/skills/leitura-caixa/extrair.py` (primeira vez: `--desde AAAA-MM-DD`). Ele aplica as Regras do perfil e grava em `private-data/caixa/trabalho/`:
   - `contexto.txt`: quem é o dono da caixa, a equipe e a lista de Obras. **Leia antes de tudo.**
   - `lote.jsonl`: mensagens para você classificar.
   - `resolvidos.jsonl`: já resolvidas por Regra. Não mexa.
2. Leia `lote.jsonl` em blocos de 25 linhas. Para cada mensagem, escreva **uma linha JSON** em `private-data/caixa/trabalho/classificado.jsonl` (formato abaixo). Uma mensagem, uma linha, mesma ordem, sem texto fora do JSON.
3. `python3 .claude/skills/leitura-caixa/relatorio.py` e mostre ao usuário o resumo que ele imprimir.

## Formato de saída

```json
{"id":"<id da mensagem>","tipo":"pessoa","obra":"<chave da lista>","etapa":"orcamento","fase":"proposta","acao":"responder","quem":"eu","prazo":"2026-10-22","importante":false,"resumo":"Cliente pede revisão do item 4.1 da proposta","justificativa":"Pedido direto ao dono, com anexo de projeto revisado"}
```

## Como decidir cada campo

**tipo** (um): `pessoa` (escrito por alguém, inclusive encaminhamentos da equipe), `financeiro` (boleto, fatura, nota fiscal de fornecedor, cobrança), `convite` (convite de reunião com data), `notificacao` (aviso automático de sistema, resposta automática de férias, compartilhamento de pasta), `newsletter`, `promocao`.

**obra**: a `chave` exata da lista de Obras em `contexto.txt`. A dica `obra_provavel` costuma estar certa; confira pelo assunto e texto. Assunto da equipe segue o padrão `OBRA <CLIENTE> <LOCAL> - <ASSUNTO>`. Obra que não está na lista: `"nova: <Cliente Local>"`. Sem obra (pessoal, administrativo, banco): `null`.

**etapa** (uma; em que ponto do ciclo da obra a mensagem está):
| etapa | pistas |
|---|---|
| `orcamento` | RFP, BID, cotação, carta convite, proposta, revisão de orçamento, equalização, leilão, Coupa/Mercado Eletrônico/Ariba, resultado ("optamos por outro fornecedor", "fomos escolhidos") |
| `contrato` | minuta, contrato, assinatura, testemunha, advogado, notificação extrajudicial, honorários, procuração |
| `documentos` | apólice, endosso, seguro de obra/fiança, ART, documentação de funcionários, APR, pendências no portal do shopping, certificado |
| `execucao` | projeto e revisões (R01, R02), cronograma, relatório semanal/diário, ata, kickoff, liberação de portaria/acesso, vistoria durante a obra, ocorrência (odor, dano) |
| `compras` | pedido a fornecedor, prazo de entrega de material, aprovação de proposta de fornecedor, cancelamento de pedido |
| `medicao` | medição, adicional/aditivo, autorização para emitir NF ao cliente (dinheiro a **receber**) |
| `pagamento` | NF ou boleto de fornecedor/empreiteiro, diárias, programação de pagamento (dinheiro a **pagar**) |
| `entrega` | databook, manual do proprietário, as built, vistoria final, inauguração, pós-obra |
| `administrativo` | escritório interno, contabilidade, ferramentas, cadastro de fornecedor |
| `pessoal` | vida pessoal do dono (casa, família, saúde, carro) |

**fase** (só quando `etapa` = `orcamento`; senão `null`):
- `pedido` = chegou um pedido **novo** de orçamento: RFP, BID, carta convite, "solicito orçamento", "vamos iniciar a reforma… solicito seu orçamento", convite em portal de compras. Inclui o encaminhamento interno de um pedido novo.
- `proposta` = vai e vem de uma concorrência já aberta: dúvidas, visita técnica, revisão de orçamento, equalização, prorrogação de prazo.
- `ganho` = cliente escolheu a empresa, pedido de compra emitido, "fomos escolhidos".
- `perdido` = "optamos por outro fornecedor", "não foi atribuída como vencedora".
Convite de reunião sobre uma obra já ganha **não** é `pedido`.

**acao** (o que a mensagem pede a alguém): `responder`, `aprovar` (validar projeto, proposta, orçamento), `assinar`, `providenciar` (pagar, emitir, enviar documento, liberar acesso), `nenhuma` (só informa, agradece, confirma recebimento, "segue para conhecimento").

**quem** deve agir:
- `eu` = o dono da caixa. Só quando o pedido é a ele: chamado pelo nome no início ("<Nome>, ...", "@<Nome>"), único destinatário, ou é o assunto que ele conduz (concorrências que ele mesmo enviou, decisões de sócio, jurídico que pede posição dele).
- `equipe` = alguém da equipe interna (nomes em `contexto.txt`), mesmo com o dono em cópia.
- `externo` = cliente, fornecedor, seguradora, shopping.
- `ninguem` quando `acao` = `nenhuma`.
- A dica `para_mim` = `copia` quase sempre significa que não é com ele. Na dúvida entre `eu` e `equipe`, escolha `equipe`.

**prazo**: data limite explícita, no formato `AAAA-MM-DD`, calculada a partir da `data` da mensagem ("até amanhã" = dia seguinte; "sexta (11/09)" = 2026-09-11). Vencimento de boleto, ART ou apólice conta. Link que expira ("expira em 3 dias") conta. Sem data clara: `null`. Nunca invente.

**importante** = `true` só se pelo menos um:
- risco de **paralisação**, multa, notificação, processo ou perda de dinheiro;
- prazo em até 2 dias úteis **e** `quem` = `eu`;
- **resultado** de concorrência (ganhou ou perdeu);
- cliente reclamando ou cobrando algo atrasado.
- decisão do dono sobre dinheiro ou jurídico (honorários, acordo, contraproposta).
Todo o resto: `false`. A maioria é `false`. Conversa jurídica ou de seguro **em andamento**, sem fato novo nem pedido ao dono, é `false`.

**resumo**: até 20 palavras, em português, dizendo o fato e o pedido. Sem saudação, sem nome de empresa repetido do assunto. **Nunca copie CPF, RG, CNH, senha, login, dados bancários ou PIX** para o resumo: escreva "contém dados pessoais" ou "contém senha".

**justificativa**: até 15 palavras, por que escolheu `quem` e `importante`.

## Contrato e assinatura (sempre chegam a você, nunca por Regra)

Avisos de Docusign, Clicksign, D4Sign e afins, e qualquer assunto com contrato, minuta, assinatura, aditivo ou procuração:
- Pedido para assinar ("Complete com", "Assinar documento", "enviou um documento para você assinar") = `notificacao`, `contrato`, `assinar`, `quem` = `eu`. A Obra sai do nome do documento.
- Assinatura concluída, comprovante, "baixe o documento" = `notificacao`, `nenhuma`.
- Lembrete de algo já recusado ou anulado = `notificacao`, `nenhuma`.
- Documento que não é de obra (plano de saúde, aluguel de equipamento) = `obra` nula, mas ainda `assinar` se pedir assinatura.
- Minuta ou contrato enviado por cliente ou advogado para análise = `pessoa`, `contrato`, `responder`, e `importante` se houver prazo ou cláusula de risco citada.

## Armadilhas vistas na caixa real

- Encaminhamento curto ("Segue", "segue para nova batalha") vale pelo conteúdo encaminhado: `[encaminhado:]` no texto.
- Aviso do sistema de compras (Coupa, Mercado Eletrônico) encaminhado por sócio é `pessoa` + `orcamento`, `quem` = `equipe`.
- "Recebido", "Combinado", "Obrigada" = `acao` `nenhuma`.
- Resposta automática de férias = `notificacao`, `nenhuma`.
- Mesma mensagem reenviada várias vezes: classifique igual.
- Fornecedor ou arquiteto pedindo "analisem e aprovem" uma revisão de projeto (R01, R02...) enviada "a todos": `aprovar`, `quem` = `eu` (o dono aprova projetos), mesmo em cópia.
- Texto que pede algo "a <colega> e <dono>": `quem` = `eu`.
- Pedido de liberação de acesso com lista de pessoas e documentos = `execucao`, `providenciar`, quem é o encarregado da obra (`equipe`), e o resumo diz "contém dados pessoais".
