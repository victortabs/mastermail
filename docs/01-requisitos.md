# Requisitos

> MoSCoW: **Must** (v1, sem isso o Victor não larga o Outlook), **Should** (logo depois da v1), **Could** (desejável), **Won't** (agora não). Vocabulário conforme `CONTEXT.md`.
>
> Consolidado em 2026-10-13 a partir da entrevista de planejamento. Sem pendências.
>
> Revisão de confiabilidade e lacunas: [avaliação de 13/10/2026](avaliacao-2026-10-13.md). Status abaixo descreve implementação; validação com Microsoft real está indicada separadamente.
>
> **Status (2026-10-14):** ✅ feito · 🟡 parcial · ⬜ não começou. Atualizar a cada entrega.

## Conta e sincronização
| Requisito | Prioridade | Notas |
|---|---|---|
| Login com uma conta Microsoft 365 (trabalho), OAuth próprio sem MSAL | Must | ADR 0003 (Graph) + ADR 0007 (login). **✅** |
| Consentimento fácil para outros usuários: detectar bloqueio do admin, oferecer URL de consentimento e texto para o TI | Must | Escopos pedidos aos poucos. **✅** |
| Sincronização por polling (30–60 s) com o app aberto | Must | Sem servidor próprio. **✅** |
| Painel de saúde da sincronização; falha de envio ruidosa; caixa de saída visível | Must | Dor nº 2 da pesquisa. **✅** rodapé de indexação, Caixa de saída com tentar de novo, alerta e atenção no Dock |
| Fila offline: ação local imediata, servidor depois | Must | **🟡** fila persistida para lido, sinalizador, Categoria e Pasta local; arquivar/apagar exigem conexão |
| Múltiplas contas / caixa unificada | Won't | Decisão explícita; v2. |
| Caixa compartilhada, calendário delegado | Won't | Usuário não usa. |

## Mensagens e conversas
| Requisito | Prioridade | Notas |
|---|---|---|
| Caixa de entrada = tudo que não é Ruído e ainda não foi aberto; ao abrir, fica só nas Pastas locais. Nada sai antes de o usuário ver | Must | ADR 0010. **⬜** (hoje: sem Pasta local) |
| Todas: tudo que não é Ruído, aberto ou não | Must | ADR 0010. **⬜** |
| Conversa cronológica com Ramos explícitos e "em resposta a" | Must | Agrupar por `conversationIndex`; cabeçalhos como fallback. **✅** |
| `R` = Responder (a todos); `⌘R` = Responder ao remetente; aviso ao remover participante | Must | **✅** |
| Encaminhar, inclusive como anexo | Must | **✅** |
| Lido/não lido, sinalizador, lixo eletrônico, apagar, arquivar (servidor) | Must | Arquivar nunca é automático. **✅** |
| Pastas do servidor: só leitura. Nunca mover nem criar. | Must | **✅** |
| Pastas locais como visões: a mensagem aparece em todas cujo critério atende (Projeto, Cliente, Fase, Com você, Pasta manual) | Must | ADR 0010, **1º na ordem de construção**. Atributos gravados na mensagem (ADR 0006). **⬜** (hoje: uma por mensagem ✅) |
| Projeto com Cliente e estado: Orçamento → Obra em andamento → encerrada, ou perdido; Orçamento ganho vira a Obra na mesma pasta | Must | ADR 0010. **⬜** |
| Barra lateral: Caixa de entrada, Com você, Aguardando, Obras em andamento, Orçamentos (Pedidos, Em proposta, Resultado), Clientes ▸ Obras/Orçamentos, Pastas manuais, Todas, Triagem | Must | ADR 0010. A pasta da Obra aparece em dois lugares e é a mesma. **⬜** |
| Para e Cc separados no Índice local; pessoas em cópia guardadas como Contatos | Must | **2º na ordem**. Hoje `recipients` mistura os dois. **⬜** |
| Adiar (snooze): esconder da Caixa de entrada até data/hora, só local | Must | **✅** |
| Lista "sem resposta sua" e "sem resposta deles há N dias", com lembrete que se cancela ao chegar resposta | Must | Mesma consulta ao Índice local. **✅ (listas; lembrete que se cancela: ⬜)** |
| Anexos: anexar, pré-visualizar (Quick Look), baixar; buscar por nome do anexo | Must | **🟡 abrir/salvar/anexar até 3 MB; Quick Look e nome no índice: ⬜** |
| Desfazer envio (timer) e desfazer ações (`z`) | Must | **✅** |
| Envio programado (servidor segura; fica em Rascunhos, editável) | Must | Via propriedade de envio adiado do Graph. **🟡 propriedade gravada; comportamento do Exchange ainda precisa de validação real** |
| Rascunhos sincronizados no servidor | Must | **🟡 criação e gravação automática; retomar no editor: ⬜** |
| Cancelar inscrição em um clique | Must | List-Unsubscribe. **✅** |
| Imagens remotas bloqueadas por padrão; liberar por remetente/Organização | Must | **✅** por mensagem, por remetente ou por domínio |
| Alerta de phishing barato: domínio ≠ nome exibido, link texto ≠ destino | Should | Sem modelo. **✅** |
| Limpeza de parâmetros de rastreio em links | Could | **⬜** |

## Composição
| Requisito | Prioridade | Notas |
|---|---|---|
| Editor rich text com atalhos de Markdown; saída HTML; citação preservada | Must | **✅** |
| Assinaturas: colar HTML ou copiar do Outlook; sem tagline | Must | Não há API do Graph para assinaturas. **✅** |
| Autocompletar destinatários do histórico e dos Contatos | Must | **🟡 autocompletar; chips e validação completa: ⬜** |
| Reenviar mensagem; enviar e arquivar | Must | **✅** |
| Modelos/snippets | Could | **⬜** |

## Atalhos e navegação
| Requisito | Prioridade | Notas |
|---|---|---|
| Esquema Gmail (`j`/`k`, `e`, `r`, `/`, `g i`…) + combinações `⌘` padrão do Mac | Must | **✅** |
| Paleta de comandos `⌘K`; todo comando no menu com atalho visível | Must | **✅** |
| VoiceOver e navegação completa por teclado | Must | **🟡 controles nativos; não auditado** |
| Atalhos remapeáveis, teclas únicas desligáveis | Should | **⬜** |

## Busca
| Requisito | Prioridade | Notas |
|---|---|---|
| Índice local de **todas** as mensagens: metadados + texto puro + nomes de anexos. Sem resumo. | Must | ~1 GB por 100 mil mensagens. **🟡 falta nome dos anexos** |
| HTML completo e anexos só dos últimos 12 meses; o resto sob demanda | Must | **✅** |
| Busca do Graph enquanto indexa, com progresso visível | Must | **✅** |
| Operadores `from:`, `to:`, `has:attachment`, `before:`, `org:` | Must | **✅** |
| Resultado determinístico, termos destacados, agrupar por remetente/Organização | Must | **🟡 sem destaque de termos nem agrupar** |
| Texto dentro de anexos (PDF, Word, Excel) | Won't | Dobra o índice. |

## Organização por IA
| Requisito | Prioridade | Notas |
|---|---|---|
| Tipo por mensagem (Pessoa, Newsletter, Notificação automática, Promoção, Financeiro, Convite) | Must | **✅** |
| Categoria atribuída pela IA, gravada no servidor (visível no celular) | Must | **✅ (ao confirmar na Triagem)** A Categoria passa a carregar a Etapa (ADR 0010): ⬜ |
| Projeto, Etapa, Fase, Com você, Prazo por mensagem, em lote, com o Perfil | Must | [06-leitura-ia.md](06-leitura-ia.md); validado com Haiku (skill `leitura-caixa`). No app: **⬜** |
| Contrato e assinatura nunca resolvidos por Regra; sempre à IA, com o corpo limpo de histórico citado | Must | **3º na ordem**. **⬜** |
| Sugestão sempre com Justificativa; usuário aceita com uma tecla | Must | **✅** |
| Explicação do usuário vira Regra (determinística, zero tokens) | Must | **✅** |
| Regra promovida a automática por decisão do usuário | Must | **🟡** promoção e Tipo/Ruído implementados; execução de Pasta local e Categoria para novas mensagens: ⬜ |
| Triagem: visão do Ruído ainda não confirmado, com contador | Must | **✅** |
| Importante (julgado pela IA pelo conteúdo) → única notificação do Mac | Must | Sem modelo, sem notificação. **✅** |
| Contador do dia no ícone do Dock | Must | **✅** |
| Regras do servidor (Exchange) | Won't | Permissão bloqueada para usuário comum. |
| Screener de remetente novo | Won't | Tipo + Triagem cobre. |
| Digest diário da Triagem com ações em lote | Could | **⬜** |

## Aba lateral
| Requisito | Prioridade | Notas |
|---|---|---|
| Sensível ao Contexto (nada, mensagem, várias, Conversa, trecho) | Must | **✅** |
| Achar mensagens em linguagem natural (sobre o Índice local) | Must | **✅** |
| Executar ações (mover para Pasta local, Categoria) listando o que vai fazer e esperando "sim" | Must | **✅** |
| Resumo de Conversa: automático a partir de 4 mensagens e incremental (Resumo anterior + mensagem nova); nas demais, sob demanda; guardado | Must | **4º na ordem**. **🟡 geração sob demanda; automático, armazenamento e invalidação: ⬜** |
| Rascunhar resposta no editor, usando as respostas anteriores da mesma Conversa | Must | Nunca envia sozinha. **✅** |
| Criar Lembrete a partir de mensagem | Must | **✅** |
| Aprender estilo a partir dos Enviados (opt-in) | Should | **⬜** |
| Cadeia Regra → modelo local → OpenRouter com chave própria | Must | ADR 0004. **✅** |
| IA desligável de verdade: zero interface quando desligada; tudo gerado rotulado | Must | **🟡 controles, Tipos e Justificativas somem; Ruído volta à entrada; auditar interface e pedidos em andamento** |

## Contatos e Organizações
| Requisito | Prioridade | Notas |
|---|---|---|
| Contatos derivados das mensagens + contatos salvos na conta | Must | **✅** |
| Organização por domínio, renomeável, fundível; domínios públicos excluídos | Must | **✅** |
| Visão por Organização: Contatos e todas as mensagens | Must | **✅** |
| Grupo do Projeto: quem costuma estar junto nas mensagens de um Projeto, por papel | Should | Reconhece o Projeto pelos copiados sem modelo; sugere destinatários. **⬜** |

## Calendário e tarefas
| Requisito | Prioridade | Notas |
|---|---|---|
| Agenda Microsoft: ver, criar, editar, mover, convidar, aceitar/recusar | Must | **✅ (validar com conta real)** dia/semana/mês, arrastar e esticar, repetição (só este / série), Teams, status dos convidados. Checklist completo em [05-agenda.md](05-agenda.md) |
| Agenda do Mac (iCloud etc.): só visualizar | Must | EventKit exige acesso total mesmo para ler. **✅** |
| Alerta do evento salvo na Microsoft; notificação do MasterMail opcional (desligada) | Must | Usuário já recebe os avisos por outros apps. **✅** |
| Enviar disponibilidade: horários livres por e-mail, a pessoa escolhe e o evento é criado | Should | Pedido de 2026-10-14; sem servidor (resposta com referência no assunto). **✅ (validar com conta real)** |
| "Entrar na reunião" abre direto no app do Teams; outros links pelo navegador | Must | **✅** |
| Convite recebido por e-mail: aceitar/recusar atualizando a agenda | Must | **🟡 cartão e ações implementados; validar com convite real** |
| Lembretes (iCloud): ler, criar, editar | Must | **🟡 criar; ler/editar: ⬜** |
| Evento a partir de mensagem | Must | **✅** |

## Integração externa
| Requisito | Prioridade | Notas |
|---|---|---|
| CLI do MasterMail (ler, buscar, organizar, rascunhar) | Should | Logo depois da v1; núcleo como biblioteca desde o início (ADR 0008). **⬜** |
| Servidor MCP local com níveis de permissão (ler / organizar / rascunhar / enviar com confirmação) | Should | Mesmo núcleo do CLI. **⬜** |
| Exportar mensagens como `.md` | Could | **⬜** |
| Atalhos.app / App Intents | Won't | |

## Plataforma e distribuição
| Requisito | Prioridade | Notas |
|---|---|---|
| macOS 26+; Swift; SwiftUI com AppKit onde preciso; sem Electron | Must | **✅** |
| Release no GitHub + tap próprio do Homebrew; atualização automática (Sparkle, EdDSA) | Must | ADR 0007. Sem assinatura da Apple: usuário faz "Abrir mesmo assim" + `xattr`. **⬜** |
| Assinatura Developer ID / notarização | Won't | Reabrir conforme ADR 0007. |
| Mac App Store | Won't | |
| iOS / iPadOS | Won't | Núcleo separado da UI para reaproveitar. |

## Não-funcionais
- **Desempenho:** abrir, buscar e navegar sem espera perceptível; lista de 100 mil mensagens sem travar.
- **Privacidade:** nada sai do Mac sem opt-in; dados do usuário nunca no repo (`.gitignore` para dados, chaves e amostras de e-mail).
- **Custo:** zero no uso básico (IA local); nuvem só com chave do usuário.
