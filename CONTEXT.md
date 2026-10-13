# MasterMail

Cliente de e-mail nativo para macOS, só para contas Microsoft, com IA para classificar e organizar a caixa de entrada. Este arquivo é o glossário do projeto: define o que cada termo **é**, nunca como é implementado.

## Linguagem

### Mensagens e conversas

**Mensagem**:
Um e-mail individual, recebido ou enviado.
_Evitar_: item, e-mail (quando o sentido for a unidade), post

**Conversa**:
O conjunto de mensagens ligadas por resposta ou encaminhamento, mostrado em ordem cronológica, com cada mensagem indicando a qual outra ela responde.
_Evitar_: thread, tópico, cadeia

**Ramo**:
Uma bifurcação dentro de uma conversa: duas ou mais mensagens que respondem à mesma mensagem-mãe, em geral para grupos de destinatários diferentes.
_Evitar_: fork, sub-thread

**Responder**:
Responder a todos os participantes da mensagem. É a ação padrão; no MasterMail "responder" nunca significa responder só ao remetente.
_Evitar_: reply all, responder a todos (redundante)

**Responder ao remetente**:
Responder só a quem enviou a mensagem, excluindo os demais participantes. Ação secundária e deliberada.
_Evitar_: reply, responder só

### Organização

**Categoria**:
Etiqueta colorida da conta Microsoft, guardada no servidor e visível em qualquer cliente Outlook, inclusive no celular. Uma mensagem pode ter várias. É o que a IA atribui automaticamente.
_Evitar_: tag, label, etiqueta (são a mesma coisa; usar sempre Categoria)

**Pasta do servidor**:
Pasta da caixa postal Microsoft. O MasterMail indexa todas para a busca, mostra só as padrão (Caixa de Entrada, Enviados, Rascunhos, Arquivo, Lixeira, Lixo eletrônico) e nunca navega pelas demais, reorganiza ou cria. Organizar é com Pasta local.
_Evitar_: folder, pasta do Outlook

**Pasta local**:
Agrupamento de mensagens que existe só dentro do MasterMail, invisível em outros clientes. Uma mensagem fica em uma única Pasta local, para onde vai depois de lida, por Regra ou Sugestão aceita; no servidor ela continua na Caixa de Entrada. Sincroniza entre Macs porque fica gravada na própria mensagem (ver ADR 0006).
_Evitar_: pasta virtual, smart folder, label local

**Caixa de entrada**:
A visão das mensagens que ainda não foram tratadas: não estão em Pasta local, não foram arquivadas nem apagadas, e não são Ruído.
_Evitar_: inbox, recebidos

**Triagem**:
A visão das mensagens que a IA marcou como Ruído e que o usuário ainda não confirmou.
_Evitar_: spam, lixo, outros

**Arquivar**:
Mover a mensagem para a pasta Arquivo Morto do servidor. Some de todos os clientes. Nunca é automático.
_Evitar_: archive, done

**Adiar**:
Esconder uma mensagem da Caixa de entrada até uma data e hora. Só local; o servidor não sabe.
_Evitar_: snooze, soneca

**Apagar**:
Mover a mensagem para Itens Excluídos do servidor.
_Evitar_: deletar, excluir

### IA

**Tipo**:
A classe que a IA atribui a toda mensagem, de um conjunto fixo e pequeno (Pessoa, Newsletter, Notificação automática, Promoção, Financeiro, Convite). Define se a mensagem é ruído ou não.
_Evitar_: classificação, label de IA

**Ruído**:
Mensagem cujo Tipo não é Pessoa nem Convite. Não aparece na caixa de entrada por padrão.
_Evitar_: spam (é outra coisa: spam é malicioso ou indesejado; ruído é legítimo mas secundário)

**Sugestão**:
Ação que a IA propõe (atribuir Categoria, mover para Pasta local, marcar como Ruído), sempre acompanhada de uma Justificativa, e que só acontece depois que o usuário aceita.
_Evitar_: ação automática, auto-move

**Justificativa**:
A explicação, em linguagem natural, de por que a IA fez uma Sugestão. O usuário vê antes de aceitar.
_Evitar_: reasoning, log

**Explicação**:
O que o usuário escreve, em linguagem natural, ao corrigir a IA ("isso é ruído porque é o aviso automático do banco"). Vira uma Regra.
_Evitar_: feedback, comentário

**Importante**:
Marca que a IA dá a uma mensagem pela urgência do conteúdo, independente do Tipo. É o único caso que gera notificação no Mac.
_Evitar_: urgente, VIP, prioridade

**Regra**:
Condição determinística derivada de uma Explicação ou de correções repetidas (ex.: remetente X → Financeiro). Resolve a mensagem sem chamar modelo nenhum.
_Evitar_: filtro, skill, prompt

### Busca

**Índice local**:
Cópia pesquisável de todas as mensagens guardada no Mac (remetente, destinatários, data, assunto, Organização, Tipo, Categoria e texto puro), que torna a busca rápida e determinística sem depender do servidor. Não contém resumo nem anexo.
_Evitar_: cache, banco

**Resumo**:
Texto que a IA gera sobre uma Conversa, só quando pedido, e guarda para não gerar de novo.
_Evitar_: sumário, TL;DR

### Aba lateral

**Aba lateral**:
O painel de conversa com a IA. Age sobre o Contexto atual e propõe ações como Sugestão: lista o que vai fazer e espera o usuário aceitar.
_Evitar_: chat, copilot, assistente

**Contexto**:
O que está selecionado quando o usuário fala com a Aba lateral: nada, uma mensagem, várias mensagens, uma Conversa, ou um trecho de texto. Define sobre o que a IA age.
_Evitar_: seleção, escopo

### Calendário e tarefas

**Agenda do Mac**:
Calendários que o macOS já conhece (iCloud e outras contas de Ajustes do Sistema). O MasterMail só mostra; editar é no Calendário.app.
_Evitar_: iCloud (é só uma das fontes), EventKit (é o mecanismo)

**Agenda Microsoft**:
O calendário da conta Microsoft 365. O MasterMail cria, edita, move e convida.
_Evitar_: calendário do Outlook, Exchange

**Lembrete**:
Tarefa do Lembretes.app (iCloud). O MasterMail lê, cria e edita; é onde nasce uma tarefa criada a partir de uma mensagem.
_Evitar_: tarefa, to-do, Microsoft To Do

### Pessoas

**Contato**:
Uma pessoa com quem o usuário troca mensagens, identificada pelo endereço de e-mail.
_Evitar_: remetente (é o papel numa mensagem, não a pessoa), destinatário

**Organização**:
O conjunto de Contatos que compartilham o domínio do e-mail (ex.: @bdil.com.br → Bacio di Latte). Nasce sozinha das mensagens e dos contatos salvos na conta; o usuário renomeia e funde. Domínios públicos (gmail.com, outlook.com) não formam Organização.
_Evitar_: empresa, domínio, cliente
