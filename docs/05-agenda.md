# Agenda: o que um app de calendário precisa ter

> Avaliação de 2026-10-14. Referências: Calendário da Apple, Outlook, Fantastical e Notion Calendar.
> ✅ feito · 🟡 parcial · ⬜ não começou. O status geral continua em [01-requisitos.md](01-requisitos.md).

A régua: um app de agenda é **funcional** quando dá para ver, criar, mudar e responder a qualquer compromisso sem abrir outro app, e não perde alertas. Ele é **bom** quando faz isso rápido (teclado, arrastar, um clique para entrar na reunião) e deixa claro o que é seu, o que é convite e o que já passou.

## Básico (sem isto não é funcional)

| Capacidade | Status | Como está no MasterMail |
|---|---|---|
| Visões dia, semana e mês | ✅ | `d` / `w` / `m`, `t` hoje, `←` `→` navegam, mini calendário na lateral |
| Criar evento | ✅ | `n`, botão `+` ou duplo clique no horário vazio |
| Editar evento | ✅ | Botão Editar no detalhe; título, horário, local, convidados, notas, alerta, "mostrar como" |
| Mover e mudar a duração | ✅ | Arrastar o evento (troca de dia na semana) e esticar pela borda de baixo; encaixa de 15 em 15 min |
| Apagar / cancelar | ✅ | Pede confirmação; se você organiza, avisa que os convidados recebem o cancelamento |
| Eventos que se repetem | ✅ | Criar com repetição (todo dia, dias úteis, semanal, mensal, anual, com data de fim); editar ou apagar "só este" ou "toda a série" |
| Dia todo e vários dias | ✅ | Faixa "dia todo" na semana, destaque colorido em cada dia do mês |
| Alertas | ✅ | O alerta escolhido no evento fica salvo na Microsoft (Outlook, celular e outros apps avisam). Notificação do próprio MasterMail é opcional, desligada por padrão (⌘, → Agenda) |
| Convites: responder | ✅ | Aceitar, Talvez e Recusar no detalhe e no cartão do convite na Conversa |
| Convites: ver quem respondeu | ✅ | Lista de convidados com o status de cada um e o resumo (aceitaram, talvez, recusaram, sem resposta) |
| Reunião online | ✅ | Criar reunião do Teams. "Entrar" abre direto no app do Teams (link de trabalho); Teams pessoal, Zoom, Meet e Webex abrem o link. Botão direito: abrir no app, no navegador ou copiar o link |
| Vários calendários com cor | ✅ | Agenda Microsoft + calendários do Mac com a cor de cada um; liga e desliga na lateral |
| Eventos no mesmo horário | ✅ | Lado a lado, dividindo a largura |
| Fuso horário | ✅ | Tudo no fuso do Mac; o Graph devolve já convertido |

## O que faz ser bom

| Capacidade | Status | Observação |
|---|---|---|
| Hoje sempre à vista | ✅ | Lista "Hoje" na lateral e faixa no topo do Mail |
| Linha de agora e passado apagado | ✅ | |
| "Mostrar como" (ocupado, livre, provisório, fora) | ✅ | Livre aparece só com contorno; provisório com borda tracejada |
| Enviar disponibilidade | ✅ | Escolhe a pessoa, vê os horários livres (Microsoft + Mac), tira os que não quer e envia. A pessoa clica num horário, a resposta pronta volta com uma referência no assunto e o MasterMail cria o evento com convite. Lista "Disponibilidade enviada" na lateral |
| Buscar eventos | ⬜ | Próximo passo: busca por título e convidado num intervalo de ±1 ano |
| Ver disponibilidade dos convidados ao marcar | ⬜ | Graph `getSchedule`; mostra os horários livres de todos no editor |
| Criar por texto ("almoço com Ana sexta 13h") | ⬜ | Pode usar o modelo local (ADR 0004) |
| Lista "próximos dias" (agenda em lista) | ⬜ | |
| Funcionar sem internet (cache da agenda) | ⬜ | Hoje a grade lê do servidor a cada troca de semana |
| Arrastar no mês | ⬜ | Só na semana e no dia |
| Fuso extra na régua de horas | ⬜ | Útil para quem marca com outro país |

## Limites conhecidos

- Eventos da Agenda do Mac são só leitura (decisão do produto). O alerta deles continua com o Calendário do Mac.
- Convidado não muda horário nem título de reunião dos outros: só responde (regra do Exchange).
- Uma série não deixa de se repetir pela edição: o Graph não aceita remover a repetição por PATCH. Para isso, apague a série e crie de novo.
- Se a notificação do MasterMail estiver ligada e o Outlook aberto, os dois avisam o mesmo alerta.
- Disponibilidade: sem servidor próprio, a confirmação depende da pessoa enviar a resposta pronta (o botão abre o e-mail dela). Se ela responder escrevendo, sem o botão, a mensagem chega normal e o evento é marcado à mão. O horário não fica reservado até ela escolher.
