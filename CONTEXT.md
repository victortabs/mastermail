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
Etiqueta colorida da conta Microsoft, guardada no servidor e visível em qualquer cliente Outlook, inclusive no celular. Uma mensagem pode ter várias. A IA grava nela a Etapa da mensagem; o usuário pode ter Categorias próprias além dessas.
_Evitar_: tag, label, etiqueta (são a mesma coisa; usar sempre Categoria)

**Pasta do servidor**:
Pasta da caixa postal Microsoft. O MasterMail indexa todas para a busca, mostra só as padrão (Caixa de Entrada, Enviados, Rascunhos, Arquivo, Lixeira, Lixo eletrônico) e nunca navega pelas demais, reorganiza ou cria. Organizar é com Pasta local e Projeto.
_Evitar_: folder, pasta do Outlook

**Pasta local**:
Visão do MasterMail que reúne mensagens por um critério: um Projeto, um Cliente, uma Fase, Com você, ou a escolha do usuário. Uma mensagem aparece em **todas** as Pastas locais cujo critério atende; nada é movido. A mesma Pasta local pode aparecer em mais de um lugar da barra lateral (a pasta de uma Obra aparece em Obras em andamento e dentro do Cliente) e é sempre a mesma lista. Invisível em outros clientes; no servidor a mensagem continua na Caixa de Entrada. Sincroniza entre Macs porque os atributos ficam gravados na própria mensagem (ADR 0006 e 0010).
_Evitar_: pasta virtual, smart folder, label local, mover para pasta

**Pasta manual**:
Pasta local em que o usuário, ou uma Regra, coloca mensagens uma a uma. Uma mensagem pode estar em várias.
_Evitar_: tag, etiqueta (é Categoria)

**Caixa de entrada**:
As mensagens que não são Ruído e que o usuário ainda não abriu. Ao abrir, a mensagem sai da Caixa de entrada e continua nas Pastas locais dela. Nenhuma mensagem sai da Caixa de entrada antes de o usuário vê-la, nem por Regra nem por IA.
_Evitar_: inbox, recebidos, não lidas

**Todas**:
Todas as mensagens que não são Ruído, abertas ou não. É onde o usuário vê o fluxo inteiro de trabalho sem a Triagem.
_Evitar_: tudo, all mail

**Com você**:
Mensagem que pede uma ação ao próprio usuário (responder, aprovar, assinar, providenciar), não à Equipe nem a terceiros. Continua em Com você depois de aberta e sai sozinha quando o usuário responde na Conversa ou marca como feita.
_Evitar_: pendente, to-do, follow-up, sem resposta sua

**Aguardando**:
Mensagem enviada pelo usuário que pede resposta e ainda não teve, há N dias. Sai sozinha quando a resposta chega.
_Evitar_: follow-up, sem resposta deles

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

### Projetos

**Projeto**:
O trabalho a que uma mensagem pertence: um Orçamento ou uma Obra. Pertence a um Cliente e tem um estado: Orçamento → Obra em andamento → Obra encerrada, ou Orçamento perdido. Um Orçamento ganho vira a Obra, com a mesma Pasta local e todo o histórico. Uma mensagem tem no máximo um Projeto; a IA atribui a partir da lista de Projetos do Perfil.
_Evitar_: job, caso, pasta (o Projeto tem uma Pasta local, não é uma)

**Orçamento**:
Projeto ainda em concorrência: do pedido do cliente até o resultado.
_Evitar_: cotação, RFP, BID, concorrência (são formas do pedido ou nomes da Etapa)

**Obra**:
Projeto ganho, em andamento ou encerrado. As Obras em andamento ficam no topo da barra lateral; as encerradas saem dela e continuam no Cliente e na busca.
_Evitar_: projeto (quando o sentido for só obra ganha), job

**Cliente**:
A Organização para quem um Projeto é feito. Agrupa as Obras e os Orçamentos dela. Gerenciadoras e arquitetos que falam em nome do Cliente não são o Cliente.
_Evitar_: conta, empresa, domínio

**Etapa**:
Em que ponto do ciclo do Projeto a mensagem está. Lista fixa: Orçamento, Contrato, Seguro e documentos, Execução, Compras, Medição, Pagamento, Entrega, mais Administrativo e Pessoal fora do ciclo. A IA grava a Etapa como Categoria. Pessoal nunca é Ruído.
_Evitar_: tag, status, fase (Fase é só do Orçamento)

**Fase**:
Em que ponto do Orçamento está uma mensagem da Etapa Orçamento: Pedido (chegou um pedido novo), Proposta (vai e vem, revisões), Ganho, Perdido. Pedido alimenta a Pasta local "Pedidos de orçamento"; Ganho sugere mudar o Projeto para Obra.
_Evitar_: etapa, status

**Prazo**:
Data limite que a IA extrai da mensagem (entrega de proposta, vencimento de ART, apólice ou boleto, link que expira). Nunca inventada: sem data clara, não há Prazo.
_Evitar_: deadline, vencimento (é um dos tipos de Prazo)

### IA

**Tipo**:
A classe que a IA atribui a toda mensagem, de um conjunto fixo e pequeno (Pessoa, Newsletter, Notificação automática, Promoção, Financeiro, Convite). Define se a mensagem é ruído ou não.
_Evitar_: classificação, label de IA

**Ruído**:
Mensagem cujo Tipo não é Pessoa nem Convite. Não aparece na caixa de entrada por padrão.
_Evitar_: spam (é outra coisa: spam é malicioso ou indesejado; ruído é legítimo mas secundário)

**Sugestão**:
Ação que a IA propõe (atribuir Categoria, Projeto ou Pasta manual, marcar como Ruído), sempre acompanhada de uma Justificativa, e que só acontece depois que o usuário aceita.
_Evitar_: ação automática, auto-move

**Justificativa**:
A explicação, em linguagem natural, de por que a IA fez uma Sugestão. O usuário vê antes de aceitar.
_Evitar_: reasoning, log

**Explicação**:
O que o usuário escreve, em linguagem natural, ao corrigir a IA ("isso é ruído porque é o aviso automático do banco"). Vira uma Regra.
_Evitar_: feedback, comentário

**Importante**:
Marca que a IA dá a uma mensagem pela urgência do conteúdo, independente do Tipo. Só quando há risco de paralisação, multa, processo ou perda de dinheiro; Prazo em até 2 dias úteis numa mensagem Com você; resultado de Orçamento; cliente reclamando; ou decisão do usuário sobre dinheiro ou jurídico. É o único caso que gera notificação no Mac.
_Evitar_: urgente, VIP, prioridade

**Regra**:
Condição determinística derivada de uma Explicação ou de correções repetidas (ex.: remetente X → Financeiro). Resolve a mensagem sem chamar modelo nenhum. Nunca resolve mensagem de contrato ou assinatura: essas vão sempre à IA.
_Evitar_: filtro, skill, prompt

### Busca

**Índice local**:
Cópia pesquisável de todas as mensagens guardada no Mac (remetente, destinatários, data, assunto, Organização, Tipo, Categoria e texto puro), que torna a busca rápida e determinística sem depender do servidor. Não contém resumo nem anexo.
_Evitar_: cache, banco

**Resumo**:
Texto que a IA gera sobre uma Conversa: o que foi pedido, decidido, o que está pendente e com quem. Automático nas Conversas com 4 ou mais mensagens e atualizado a cada mensagem nova (Resumo anterior + mensagem nova); nas demais, só quando pedido. Guardado para não gerar de novo.
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

**Alerta**:
Aviso antes de um evento ("15 min antes"), salvo no evento da Agenda Microsoft; quem avisa é o Outlook, o celular ou, se ligado, o MasterMail.
_Evitar_: lembrete (é a tarefa do Lembretes.app), notificação

**Disponibilidade**:
E-mail com horários livres da agenda para uma pessoa escolher. Cada horário é um botão que abre a resposta pronta; quando ela chega, o MasterMail cria o evento com convite.
_Evitar_: link de agendamento, Calendly

**Lembrete**:
Tarefa do Lembretes.app (iCloud). O MasterMail lê, cria e edita; é onde nasce uma tarefa criada a partir de uma mensagem.
_Evitar_: tarefa, to-do, Microsoft To Do

### Pessoas

**Contato**:
Uma pessoa com quem o usuário troca mensagens, identificada pelo endereço de e-mail.
_Evitar_: remetente (é o papel numa mensagem, não a pessoa), destinatário

**Equipe**:
Os Contatos da própria Organização do usuário. Separa o que é Com você do que é com a Equipe, mesmo com o usuário em cópia.
_Evitar_: time, funcionários

**Grupo do Projeto**:
Os Contatos que costumam estar juntos nas mensagens de um Projeto (cliente, arquitetura, shopping, fornecedores, Equipe), inclusive os que só aparecem em cópia. Mostra quem é quem, ajuda a reconhecer o Projeto pelos copiados e sugere destinatários.
_Evitar_: lista de distribuição, grupo de contatos

**Perfil**:
O que a IA lê antes de classificar: papel do usuário, Equipe e lista de Projetos. Mantido pelo usuário, com sugestões da IA.
_Evitar_: contexto (é o da Aba lateral), prompt

**Organização**:
O conjunto de Contatos que compartilham o domínio do e-mail (ex.: @bdil.com.br → Bacio di Latte). Nasce sozinha das mensagens e dos contatos salvos na conta; o usuário renomeia e funde. Domínios públicos (gmail.com, outlook.com) não formam Organização.
_Evitar_: empresa, domínio, cliente
