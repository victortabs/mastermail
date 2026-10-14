# Avaliação do MasterMail — 13/10/2026

O projeto tem uma base adequada para continuar: app nativo, núcleo separado da interface, índice SQLite com FTS5, autenticação própria com PKCE e IA com nuvem opt-in. A maior fonte de atrito está na coordenação entre interface, operações de rede e estado local. Vários fluxos já existem, mas sua presença no código não significa que estejam completos ou validados em uma conta Microsoft real.

Esta revisão analisou o app, o núcleo, os testes e os requisitos. Implementou correções de confiabilidade e navegação sem mudar as decisões de plataforma, distribuição, conta única ou consentimento para IA. Os testes usam mensagens sintéticas e servidor simulado.

## Correções entregues

| Área | Problema encontrado | Comportamento implementado |
|---|---|---|
| Envio | Um segundo envio cancelava o timer do primeiro. | Cada mensagem tem seu timer e seu desfazer. A ação expira quando começa a chamada de envio. |
| Rascunho | Texto e destinatários só eram gravados na hora de enviar. Desfazer podia deixar um rascunho vazio. | Gravação automática após uma pausa de 800 ms e gravação obrigatória antes de fechar o editor para envio. Escritas serializadas. Falha ao salvar mantém o editor aberto. |
| Enviar e arquivar | A mensagem original era arquivada antes do envio, inclusive se ele falhasse; a confirmação de participantes perdia a intenção de arquivar. | Arquivar acontece após o envio bem-sucedido. A intenção é preservada na confirmação e na nova tentativa pela Caixa de saída. |
| Nova tentativa | O erro do envio anterior continuava preenchido após uma tentativa bem-sucedida. | Cada tentativa limpa seu erro e só retira a mensagem da Caixa de saída depois do sucesso. |
| Composição | Abrir outra composição substituía o editor atual. Encaminhar como anexo perdia o assunto preenchido. | Composição existente é preservada; assunto do encaminhamento é mantido; envio sem destinatário fica desabilitado. |
| Busca | Cada tecla iniciava trabalho; respostas antigas podiam substituir a busca atual; complemento do servidor ignorava operadores locais. | Espera de 250 ms, busca local fora da thread da interface, publicação apenas da consulta atual e complemento remoto restrito a buscas sem operadores. A pasta real do resultado remoto é preservada. |
| Operadores | Nomes com espaços eram partidos; operadores inválidos podiam ampliar silenciosamente a busca. | Suporte a `from:"Ana Silva"` e `in:"Obras 2026"`. Operadores desconhecidos ou datas inválidas permanecem como texto. |
| Leitura | Download do corpo reutilizava um índice de uma conversa que podia ter mudado ou desaparecido. | Revalidação por id após a rede. Atualização somente do corpo, preservando lido, sinalizador e organização. Seleção cancela a tarefa de leitura anterior. |
| Fila | Drenagens simultâneas podiam repetir ações; qualquer HTTP 4xx descartava trabalho; falha de gravação era ignorada. | Uma drenagem por vez, persistência com erro explícito e conservação das ações recusadas, incluindo 401 e 429. Escritas e desfazer passam pela mesma fila. Renomear e aplicar plano enfileiram em lote. |
| Sincronização | Delta e reconciliação de Pastas locais podiam sobrescrever alterações offline ainda pendentes. | Ações pendentes protegem os campos locais até sua execução. Erros de sincronização aparecem no rodapé com tentar de novo e reconectar. |
| Pastas do servidor | Descoberta limitada a um nível de subpastas e uma página. | Descoberta de todos os níveis e acompanhamento de `@odata.nextLink`, com prevenção de duplicatas. |
| Autenticação | Requisições simultâneas renovavam o mesmo token em paralelo; operações antigas podiam continuar após sair. | Renovação compartilhada, validação da sessão após respostas e cancelamento dos envios pendentes ao sair. Sessão de autenticação e janela são retidas até o callback. |
| Conta única | Uma reconexão com outra identidade poderia reutilizar dados e ações da conta anterior. | O índice registra seu proprietário e exige a mesma identidade para reconectar, sem apagar dados. Na primeira execução após a migração, o índice existente é associado à conta conectada. |
| Limites do Graph | Não havia pausa depois de throttling. | Respostas 429/503 respeitam `Retry-After` numérico; ausência do cabeçalho usa 60 s. O próximo ciclo tenta novamente. |
| Arquivar e apagar | O registro local era apagado antes da rede; falha podia esconder a mensagem e movimento descartava metadados locais. | Falha restaura a lista; sucesso preserva classificação, Pasta local e Adiar ao substituir o id. Desfazer também preserva esses dados. |
| IA desligada | Controles e classificações continuavam visíveis; Ruído continuava escondido. | Controles, Tipos e Justificativas somem; Caixa de entrada inclui o Ruído; novos ciclos de classificação param. Modelo do Organizador fica configurável. |
| HTML | Bloqueio remoto só era instalado depois de compilar uma lista assíncrona. | Política de conteúdo presente antes do carregamento. Imagens remotas exigem consentimento, scripts e outros recursos permanecem bloqueados; navegação externa exige clique. |
| Teclado e lista | Atalhos podiam interferir em campos; ações pelo mouse não avançavam a seleção de forma consistente. | Campos de texto e modificadores padrão do Mac são respeitados; remoção da mensagem avança a seleção. Toast tem botão explícito para desfazer. |
| Calendário | Respostas antigas podiam preencher outra semana; falha na criação fechava o formulário. | Apenas a carga atual publica eventos. Falha conserva o formulário; criação duplicada e intervalo sem duração ficam bloqueados. |

O tratamento de pausa e paginação segue as orientações da Microsoft: [throttling](https://learn.microsoft.com/en-us/graph/throttling) e [paginação](https://learn.microsoft.com/en-us/graph/paging).

## O que ainda precisa ser resolvido

As prioridades abaixo são recomendações desta avaliação. Não representam funcionalidades entregues neste lote.

### Próximo lote: completar confiabilidade

1. **Retomar rascunhos no editor.** A lista Rascunhos ainda abre a mensagem como leitura. É preciso reabrir o rascunho existente, preservar HTML e anexos e editar sem duplicar assinatura ou citação.
2. **Persistir o estado da Caixa de saída.** Mensagens salvas no servidor sobrevivem ao encerramento, mas a lista de falhas e os timers vivem na memória. Reinício deve reconstruir as pendências; saída do app deve explicar o destino dos envios aguardando 10 s.
3. **Resolver recusas permanentes da fila.** Ações não somem, mas a fila para no primeiro erro. Falhas 403/404 precisam de uma visão por ação, descarte deliberado e reconciliação do estado local. Uma reconexão resolve autenticação, não toda recusa.
4. **Recuperar delta expirado.** `MailSync` precisa tratar cursor inválido e refazer a indexação sem perder organização local nem deixar mensagens antigas no índice.
5. **Completar regras automáticas e Sugestões.** A classificação por Tipo existe; o pipeline ainda não executa integralmente `pastaLocal` e `categoria` das regras para novas mensagens. Categoria proposta pelo modelo também não tem um fluxo geral de confirmação e gravação.
6. **Validar envio programado no Exchange real.** Gravar uma propriedade estendida não comprova que o servidor vai segurar o envio nem que a mensagem poderá ser editada até lá. Não tratar esse requisito como validado antes do teste completo.

### Depois: melhorar a experiência diária

- Buscar nomes de anexos e Categorias, destacar termos e agrupar resultados. A busca textual e os operadores estão disponíveis; esses complementos ainda faltam.
- Usar chips de destinatários e interpretar corretamente nomes com vírgulas. O controle atual é um campo de texto com autocompletar. Completar validação de endereço e tratamento de cópias.
- Completar os menus e atalhos documentados, incluindo ações da conversa; auditar VoiceOver e foco. Trocar telas recria parte do estado local das views.
- Editar e mover eventos pela interface, apresentar compromissos simultâneos lado a lado e oferecer mês. O núcleo tem atualização de evento, mas o detalhe atual não oferece edição.
- Ler e editar Lembretes; cancelar lembrete de acompanhamento quando chegar resposta.
- Guardar Resumos com invalidação quando a Conversa mudar. Hoje a Aba lateral gera novamente; ainda não existe armazenamento do Resumo.
- Oferecer Quick Look e upload de anexos acima de 3 MB.

### Preparação para uso contínuo e distribuição

- Medir navegação, busca e primeira indexação com 100 mil mensagens sintéticas. A revisão não demonstrou esse desempenho. `refreshPeople` percorre o índice; sua chamada pela interface precisa sair da thread principal.
- Separar `AppModel` em coordenação de conta, lista, sincronização e envio. O objeto concentra responsabilidades demais; extração deve acompanhar testes de comportamento.
- Migrar a fila de JSON para transações no SQLite se o volume de ações crescer. Persistir o arquivo inteiro a cada confirmação favorece durabilidade, mas tem custo em lotes grandes.
- Medir retenção de HTML: a regra de 12 meses não faz uma limpeza periódica de corpos já guardados ou baixados sob demanda.
- Implementar release, atualização automática e documentação de instalação. A restrição de assinatura ad-hoc permanece.

## Validação e limites

- Base inicial: 42 testes do núcleo passaram e o app compilou.
- Resultado final: **54 testes do núcleo e 7 testes de coordenação do app passaram**. O teste via Xcode também compilou o aplicativo em Debug. `git diff --check` passou.
- Nova cobertura: envios concorrentes, cancelamento, falha ao salvar, nova tentativa, fila persistida, drenagem concorrente, token compartilhado, saída durante requisição, throttling, proteção de ações locais, substituição de id, operadores com espaços e pastas profundas com paginação.
- Testes do app rodam sem abrir o aplicativo principal, com diretórios temporários e servidor simulado.
- Não foram feitos envios, alterações na caixa postal, medições de 100 mil mensagens ou auditoria manual de VoiceOver em uma conta real.
- Arquivar e apagar continuam exigindo conexão; falhas mantêm a mensagem disponível. Fila offline dessas movimentações precisa incluir troca de ids, desfazer e reconciliação antes de ser habilitada.
- A base antiga não tinha identidade gravada. A associação inicial usa a conta conectada; bases já misturadas antes desta revisão exigem análise específica.
