# Requisitos

> MoSCoW: **Must** (v1, sem isso o Victor não larga o Outlook), **Should** (logo depois da v1), **Could** (desejável), **Won't** (agora não). Vocabulário conforme `CONTEXT.md`.
>
> Consolidado em 2026-10-13 a partir da entrevista de planejamento. Sem pendências.
>
> **Status (2026-10-13, fim do dia):** ✅ feito · 🟡 parcial · ⬜ não começou. Atualizar a cada entrega.

## Conta e sincronização
| Requisito | Prioridade | Notas |
|---|---|---|
| Login com uma conta Microsoft 365 (trabalho), OAuth próprio sem MSAL | Must | ADR 0003 (Graph) + ADR 0007 (login). **✅** |
| Consentimento fácil para outros usuários: detectar bloqueio do admin, oferecer URL de consentimento e texto para o TI | Must | Escopos pedidos aos poucos. **✅** |
| Sincronização por polling (30–60 s) com o app aberto | Must | Sem servidor próprio. **✅** |
| Painel de saúde da sincronização; falha de envio ruidosa; caixa de saída visível | Must | Dor nº 2 da pesquisa. **✅** rodapé de indexação, Caixa de saída com tentar de novo, alerta e atenção no Dock |
| Fila offline: ação local imediata, servidor depois | Must | **⬜** |
| Múltiplas contas / caixa unificada | Won't | Decisão explícita; v2. |
| Caixa compartilhada, calendário delegado | Won't | Usuário não usa. |

## Mensagens e conversas
| Requisito | Prioridade | Notas |
|---|---|---|
| Caixa de entrada = mensagens não tratadas (sem Pasta local, não arquivadas, não Ruído) | Must | **✅** |
| Conversa cronológica com Ramos explícitos e "em resposta a" | Must | Agrupar por `conversationIndex`; cabeçalhos como fallback. **✅** |
| `R` = Responder (a todos); `⌘R` = Responder ao remetente; aviso ao remover participante | Must | **✅** |
| Encaminhar, inclusive como anexo | Must | **🟡 encaminhar sim; como anexo não** |
| Lido/não lido, sinalizador, lixo eletrônico, apagar, arquivar (servidor) | Must | Arquivar nunca é automático. **✅** |
| Pastas do servidor: só leitura. Nunca mover nem criar. | Must | **✅** |
| Pasta local: uma por mensagem, gravada na mensagem no servidor | Must | ADR 0006. Mensagem lida com Pasta local sai da Caixa de entrada. **✅** |
| Adiar (snooze): esconder da Caixa de entrada até data/hora, só local | Must | **✅** |
| Lista "sem resposta sua" e "sem resposta deles há N dias", com lembrete que se cancela ao chegar resposta | Must | Mesma consulta ao Índice local. **✅ (listas; lembrete que se cancela: ⬜)** |
| Anexos: anexar, pré-visualizar (Quick Look), baixar; buscar por nome do anexo | Must | **🟡 abrir/salvar/anexar até 3 MB; Quick Look e nome no índice: ⬜** |
| Desfazer envio (timer) e desfazer ações (`z`) | Must | **✅** |
| Envio programado (servidor segura; fica em Rascunhos, editável) | Must | Via propriedade de envio adiado do Graph. **✅** |
| Rascunhos sincronizados no servidor | Must | **✅** |
| Cancelar inscrição em um clique | Must | List-Unsubscribe. **✅** |
| Imagens remotas bloqueadas por padrão; liberar por remetente/Organização | Must | **✅** por mensagem, por remetente ou por domínio |
| Alerta de phishing barato: domínio ≠ nome exibido, link texto ≠ destino | Should | Sem modelo. **✅** |
| Limpeza de parâmetros de rastreio em links | Could | **⬜** |

## Composição
| Requisito | Prioridade | Notas |
|---|---|---|
| Editor rich text com atalhos de Markdown; saída HTML; citação preservada | Must | **✅** |
| Assinaturas: colar HTML ou copiar do Outlook; sem tagline | Must | Não há API do Graph para assinaturas. **✅** |
| Autocompletar destinatários do histórico e dos Contatos | Must | **✅** |
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
| Categoria atribuída pela IA, gravada no servidor (visível no celular) | Must | **✅ (ao confirmar na Triagem)** |
| Sugestão sempre com Justificativa; usuário aceita com uma tecla | Must | **✅** |
| Explicação do usuário vira Regra (determinística, zero tokens) | Must | **✅** |
| Regra promovida a automática por decisão do usuário | Must | **✅** (⌘, → Regras) |
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
| Resumo de Conversa, sob demanda e guardado | Must | Longa → nuvem ou em pedaços (janela de 4k do modelo local). **✅** |
| Rascunhar resposta no editor, usando as respostas anteriores da mesma Conversa | Must | Nunca envia sozinha. **✅** |
| Criar Lembrete a partir de mensagem | Must | **✅** |
| Aprender estilo a partir dos Enviados (opt-in) | Should | **⬜** |
| Cadeia Regra → modelo local → OpenRouter com chave própria | Must | ADR 0004. **✅** |
| IA desligável de verdade: zero interface quando desligada; tudo gerado rotulado | Must | **🟡 desligável; linhas somem; validar interface zero** |

## Contatos e Organizações
| Requisito | Prioridade | Notas |
|---|---|---|
| Contatos derivados das mensagens + contatos salvos na conta | Must | **✅** |
| Organização por domínio, renomeável, fundível; domínios públicos excluídos | Must | **✅** |
| Visão por Organização: Contatos e todas as mensagens | Must | **✅** |

## Calendário e tarefas
| Requisito | Prioridade | Notas |
|---|---|---|
| Agenda Microsoft: ver, criar, editar, mover, convidar, aceitar/recusar | Must | **✅** |
| Agenda do Mac (iCloud etc.): só visualizar | Must | EventKit exige acesso total mesmo para ler. **✅** |
| Convite recebido por e-mail: aceitar/recusar atualizando a agenda | Must | **⬜** |
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
