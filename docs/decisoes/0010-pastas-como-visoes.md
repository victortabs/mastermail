# 0010 — Pastas como visões: uma mensagem em várias pastas

- **Data:** 2026-10-14
- **Status:** aceita em 2026-10-14 (substitui a regra "uma Pasta local por mensagem" da ADR 0006)

## Contexto
A análise de dois meses de caixa real ([06-leitura-ia.md](../06-leitura-ia.md)) mostrou que o trabalho se organiza por **Projeto** (obra, orçamento), por **Cliente** e por **o que pede ação do usuário**, e que esses eixos se cruzam: um pedido de aprovação de projeto é ao mesmo tempo da obra X, do cliente Y e "com você". O usuário pediu, com estas palavras:

- ver a mesma mensagem em mais de um lugar, como acontece com várias Categorias;
- uma pasta de orçamentos geral e uma de orçamentos por cliente, e uma pasta só com os pedidos de orçamento;
- pastas de obra, separadas por obra em andamento, que também aparecem dentro do cliente ("cliente com cinco obras: clico na obra pelo cliente ou pela lista de obras e vejo o mesmo lugar");
- uma pasta do que espera a resposta dele;
- na navegação, priorizar as obras em andamento; o cliente é aberto menos vezes.

Com "uma Pasta local por mensagem", qualquer escolha esconde a mensagem dos outros lugares onde ela também faz sentido.

## Opções consideradas
1. **Pastas como visões.** A mensagem guarda atributos (Projeto, Etapa, quem deve agir e as Pastas manuais em que o usuário a colocou); cada pasta é um filtro sobre esses atributos. A mensagem aparece em todas as pastas que casam.
2. **Várias Pastas locais por mensagem**, todas escolhidas à mão ou por Regra, como etiquetas. É simples, mas o usuário (ou a IA) teria de atribuir cada pasta, e nada mantém "Orçamentos de um cliente" coerente com "Orçamentos".
3. **Manter uma pasta por mensagem** e resolver o resto só com busca. Não atende ao pedido.

## Decisão
Opção 1, com pastas manuais múltiplas como complemento.

**Projeto** é a unidade: pertence a um **Cliente** (uma Organização) e tem um estado que muda com o tempo:

```
Orçamento: solicitado → em proposta → ganho ─┬─→ Obra em andamento → Encerrada
                                            └─ perdido (arquivado)
```

Um orçamento ganho **vira** a obra: é a mesma pasta, que sai da seção Orçamentos e entra em Obras em andamento, com todo o histórico da concorrência.

Barra lateral, nesta ordem:

| Seção | O que mostra | De onde vem |
|---|---|---|
| **Caixa de entrada** | tudo que não é Ruído e ainda não foi aberto | sai ao abrir; a mensagem continua nas Pastas locais dela |
| **Com você** | o que pede ação do usuário e ele ainda não respondeu | `quem` = eu; sai sozinho quando há resposta enviada na Conversa |
| **Aguardando** | o que o usuário mandou e ninguém respondeu há N dias | Enviados, sem modelo |
| **Obras em andamento** ▸ uma pasta por obra | tudo da obra, de todas as Etapas | Projeto com estado "em andamento" |
| **Orçamentos** ▸ Pedidos novos · Em proposta · Resultado | tudo de concorrência, de todos os clientes | Etapa `concorrencia` + fase |
| **Clientes** ▸ Cliente ▸ Obras · Orçamentos | as mesmas pastas de Projeto, agrupadas pelo cliente | Projeto → Cliente |
| **Pastas** | pastas manuais, uma mensagem pode estar em várias | o usuário ou uma Regra |
| **Todas** | tudo que não é Ruído, aberto ou não | Tipo |
| **Triagem** | Ruído não confirmado | já existe |

A pasta de uma obra é **uma só** e aparece em dois lugares (Obras em andamento e dentro do Cliente). Abrir por qualquer um mostra a mesma lista.

**Caixa de entrada** é tudo que não é Ruído e o usuário ainda não abriu. Decisão do usuário: "se for para as pastas antes de eu ver, eu vou perder o e-mail". Como as Pastas locais são visões, a mensagem nova já está na pasta da Obra **e** na Caixa de entrada; ao abrir, sai só da Caixa de entrada. Com você continua até a resposta.

**Etapa** é gravada como Categoria do Outlook (confirmado pelo usuário): é a etiqueta visível no celular.

**Ordem de construção** (decisão do usuário): 1) Projetos e Pastas locais como visões; 2) Para e Cc separados no Índice local, com as pessoas em cópia guardadas; 3) contrato e assinatura sempre pela IA, com limpeza do corpo; 4) Resumo automático das Conversas longas.

## Consequências
- Mantém o mecanismo da ADR 0006 (uma única propriedade do MasterMail na mensagem, sincronizada pela conta), mas o conteúdo muda de "nome da pasta" para os atributos: Projeto, Etapa, fase, quem e a lista de pastas manuais.
- A lista de Projetos, seus Clientes e estados vive na configuração da conta, como a 0006 já previa para os nomes de pasta.
- Mudar o estado de um Projeto (ganhou, encerrou) move todas as mensagens dele de seção sem nenhuma escrita por mensagem.
- Muda o CONTEXT.md: **Pasta local** deixa de ser "uma por mensagem"; entram Pasta manual, Todas, Com você, Aguardando, Projeto, Orçamento, Obra, Cliente, Etapa, Fase, Prazo, Equipe, Grupo do Projeto e Perfil.
- Muda o requisito "Caixa de entrada = sem Pasta local" e a tecla `v` (passa a "adicionar a Pasta manual", não "mover").
- A IA precisa acertar o Projeto. No teste com Haiku, acertou 98–100% com uma lista de Projetos no perfil. Quando não acerta, a mensagem fica em Com você ou na Caixa de entrada, nunca some.
- Risco: muitas pastas. Obras encerradas e orçamentos perdidos saem da barra lateral e ficam acessíveis só pelo Cliente e pela busca.
