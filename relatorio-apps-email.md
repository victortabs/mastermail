# Pesquisa técnica: clientes de e-mail (dores, capacidades e atalhos)

**Data da coleta:** 13/10/2026 (BRT) · **Autor:** Pesquiseiro (Grok Bot) · **Destinatário:** Victor Taborda

## 0. Método e limitações (leia primeiro)

- **Reddit:** o acesso direto (`reddit.com/*.json`, `old.reddit.com`) devolveu **HTTP 403** e o espelho Pullpush devolveu **429**. As threads foram lidas pelo índice de busca (WebSearch), que traz o post e de 3 a 7 comentários principais por thread. **Não li cada thread na íntegra.** As contagens abaixo são **aproximadas** e contam apenas os trechos lidos.
- **Amostra:** 36 threads de Reddit em 22 subreddits (lista completa no Anexo A), além de 4 threads da Gmail Community e 3 reviews independentes.
- **Fontes oficiais:** as páginas de atalhos de Gmail, Outlook, Apple Mail, Superhuman (PDF v8), Spark, HEY, Fastmail, Missive, Shortwave e Mimestream foram baixadas e lidas na íntegra. **Thunderbird** (support.mozilla.org) bloqueou com desafio JavaScript. **Proton** publica a lista só em imagem. Nesses dois casos usei fontes secundárias, sinalizadas na tabela.
- **Convenção:** **(nv) = não verificado nesta coleta.** Indica conhecimento prévio que ainda não foi confirmado numa fonte oficial. Antes de qualquer decisão de produto, confirme os itens (nv).

---

## 1. Reddit: dores, irritações e pedidos

### 1.1 Ranking de temas (menções nas 36 threads lidas)

| # | Tema | Threads com menção (≈) | Intensidade |
|---|---|---|---|
| 1 | Busca (falha, lenta, irrelevante, não cruza contas) | 13 | Crítica: é o motivo mais citado para abandonar um app |
| 2 | Sincronização e autenticação (OAuth M365, caixa de saída presa, ações que não propagam) | 11 | Crítica: gera e-mail perdido |
| 3 | Caixa unificada (multi-conta, multi-provedor) | 10 | Requisito eliminatório para quem tem 3 ou mais contas |
| 4 | Regressão de recursos (New Outlook vs Classic) | 6 | Alta |
| 5 | IA intrusiva, cara ou que deixa o app lento | 5 | Alta e polarizada |
| 6 | Organização: ordenar por remetente, pastas vs labels, regras | 7 | Média/alta |
| 7 | Preço / modelo de assinatura | 7 | Média |
| 8 | Calendário integrado fraco (Proton, HEY, New Outlook) | 6 | Média |
| 9 | Triagem e remetentes novos (Screener) | 5 | Média, muito elogiada quando existe |
| 10 | Follow-up, nudge e rastreamento de abertura | 5 | Média, com forte demanda em uso comercial |
| 11 | Notificações seletivas (VIP, por remetente/label) | 4 | Média |
| 12 | Privacidade, pixels e criptografia | 4 | Média, central para o nicho de privacidade |
| 13 | Newsletters, unsubscribe e spam | 4 | Média |
| 14 | Multiplataforma e sincronia de configurações | 4 | Média |
| 15 | Portabilidade e lock-in (sem IMAP, exportação) | 3 | Média |
| 16 | Acessibilidade (leitor de tela, teclado) | 4 | Nicho, mas eliminatória para quem precisa |
| 17 | Colaboração e caixa compartilhada | 4 | Alta em equipes |
| 18 | Performance (lentidão, consumo de recursos) | 5 | Média |
| 19 | Anexos (Office, limites, assinatura de PDF) | 3 | Baixa/média |
| 20 | Editor e composição (fonte, assinatura, tagline "Sent with") | 4 | Baixa/média |
| 21 | Snooze e lembretes | 3 | Baixa: é tido como básico e só reclamam quando falta |

### 1.2 Detalhamento por tema

**1. Busca (≈13).** A dor mais forte. As falhas citadas são de quatro tipos: (a) **recall**, quando colar o assunto exato não acha o e-mail; (b) **ranking**, quando um endereço exato devolve uma conversa errada; (c) **escopo**, quando a busca não cruza contas nem pastas, ou não junta inbox e enviados; (d) **determinismo**, quando a mesma busca dá resultados diferentes em dias diferentes. No Proton, a busca no corpo depende de indexação local criptografada, que leva horas ou dias e não existia no Android até ago/2026. No Apple Mail (macOS 26/27), o índice corrompe e a solução passa por "Rebuild" ou pela reconstrução do Envelope Index.
- "Outlook can't even find a mail item when you copy and paste the subject line into the search bar." ([r/sysadmin](https://www.reddit.com/r/sysadmin/comments/1te6nt1/is_the_new_outlook_search_function_really_this_bad/))
- "I'll even paste their exact email address… Outlook somehow decides that what I actually wanted was a completely different conversation." ([r/Outlook](https://www.reddit.com/r/Outlook/comments/1ukmlka/is_anyone_else_absolutely_fed_up_with_the_new/))
- "When I search the exact same phrase on different days, I expect the exact same results and both sets of results should be complete." ([r/Office365](https://www.reddit.com/r/Office365/comments/1ni74hj/new_outlook_is_a_disaster_why_do_they_persist_it/))
- "On big construction projects where you need to find something that was sent a year ago… it's just maddening." ([r/Outlook](https://www.reddit.com/r/Outlook/comments/1wjphac/new_outlook_is_terrible/))
- Proton, indexação lenta: [r/ProtonMail](https://www.reddit.com/r/ProtonMail/comments/1srolep/proton_search_message_content_syncing_really_slow/), [busca no Android](https://www.reddit.com/r/ProtonMail/comments/1vej4nv/body_search_in_android_app/), ["Search is a nightmare"](https://www.reddit.com/r/ProtonMail/comments/1e3zxq1/search_is_a_nightmare/)
- Apple Mail: ["Why is search still so terrible in Mail?"](https://www.reddit.com/r/MacOS/comments/1wl2s5c/why_is_search_still_so_terrible_in_mail/)
- HEY: "generally crappy search which fails you when you most need it" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/urtgkb/fastmail_to_hey_to_fastmail_to_hey_to_fastmail/)); "search was terribly slow" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/1t3l5qh/should_i_make_the_leap/))
- Observação técnica: parte das falhas vem do **servidor**, pois o New Outlook e o OWA dependem do índice do Exchange (houve, por exemplo, o incidente EX1469261 citado na busca). Um cliente que mantém **índice local próprio** fica imune a isso.

**2. Sincronização e autenticação (≈11).** Spark com M365: pede reautorização várias vezes ao dia, o envio falha em silêncio e só aparece um ponto vermelho no Outbox. Spark iOS: lido, flag, exclusão e movimentação feitos em outro app não se refletem. New Outlook com Google Workspace: e-mail excluído que continua no servidor e evento de calendário que não propaga.
- "I just notice the little red dot next to Outbox, which tells me, my emails aren't sending. I'm paying for Spark Premium." ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1m6ol3q/microsoft_365_accounts_unusable/))
- "Read status, flagging, deleting, and moving emails from another email app are no longer being reflected in the Spark app." ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1v1mvem/outlook_sync_issues_across_ios_devices/))
- "Deleted about 50 emails four hours ago. Checked online, they still aren't actually deleted from the server." ([r/Outlook](https://www.reddit.com/r/Outlook/comments/1wjphac/new_outlook_is_terrible/))
- Outras: [MS365 authentication issue](https://www.reddit.com/r/SparkMail/comments/1r0iqbj/ms365_authentication_issue/), [Finally giving up](https://www.reddit.com/r/SparkMail/comments/1tysezy/finally_giving_up/)
- **Implicação:** é preciso um **indicador de saúde de sincronização** e **falha de envio ruidosa**, com notificação e não só um ponto vermelho.

**3. Caixa unificada (≈10).** Aparece como requisito eliminatório. Superhuman não tem; o New Outlook só começou a liberar a visão "All Accounts" em ago/2026, com busca multi-conta prevista para out/2026 ([Microsoft RM564609](https://mc.merill.net/message/RM564609), [RM570441](https://mc.merill.net/message/RM570441), [Windows Latest](https://www.windowslatest.com/2026/09/05/new-outlook-quietly-added-5-new-features-in-august-but-the-all-inboxes-view-still-isnt-for-everyone/)). O eM Client gratuito aceita só 2 contas.
- "Why is Outlook still missing unified inbox and search - basic features in 2025??" ([r/Office365](https://www.reddit.com/r/Office365/comments/1jwl77g/why_is_outlook_still_missing_unified_inbox_and/))
- "For personal, I have 4 email accounts, and unified inbox is a must." ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1tysezy/finally_giving_up/))
- Superhuman: ["No Unified Inbox -- How do you survive?"](https://www.reddit.com/r/SuperhumanEmail/comments/1io7tcf/no_unified_inbox_how_do_you_survive/), [Unified Inbox in Superhuman](https://www.reddit.com/r/SuperhumanEmail/comments/1evtsd8/unified_inbox_in_superhuman/)
- Variante pedida: a caixa unificada deve **incluir subpastas filtradas por regras do servidor**, porque o Spark só mostra a INBOX ([r/software](https://www.reddit.com/r/software/comments/1n9ffbk/free_multiaccount_multiplatform_email_client_for/)).

**4. Regressão de recursos (≈6).** Itens que sumiram na migração para o New Outlook: autocompletar de destinatários já usados, "search all inboxes", reenviar mensagem, "run rule now", abrir convite e já definir lembrete, e pular para um item digitando a letra numa lista ordenada.
- "It is not just one missing feature. It is death by a thousand missing features." ([r/Outlook](https://www.reddit.com/r/Outlook/comments/1tkpczw/new_crappy_outlook_is_what_happens_when_microsoft/))
- "The action to re-send an e-mail is gone." ([r/Outlook](https://www.reddit.com/r/Outlook/comments/1wjphac/new_outlook_is_terrible/))

**5. IA (≈5, polarizada).** Reclamam de IA empurrada (popups), do custo de performance mesmo com a IA desligada, do preço e da tagline "Sent with Spark". Elogiam a IA aplicada a **busca, resumo e regras** e criticam a IA que redige.
- "Even with it 'off' it still takes up space just in case I want to change my mind." ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1s5p95b/ai_makes_me_want_to_leave_spark/))
- "I NEVER use it to help with writing email because I just have to undo what it suggests." ([mesma thread])
- "Spark team - pay attention to how Superhuman does AI - that's the exact way it should be done." ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1tysezy/finally_giving_up/))
- "actually useful AI (especially AI inside rules)" ([r/Missive](https://www.reddit.com/r/Missive/comments/1rxwdy8/after_trying_basically_every_email_client_missive/))

**6. Organização, regras e ordenação (≈7).** No Gmail não dá para ordenar por remetente e existem labels, mas não pastas. O New Outlook perdeu "run rule now". O HEY só filtra por remetente ou domínio, não por assunto. O Proton limita a 250 filtros e o Fastmail a 1.000.
- "I simply want to press a button and my inbox is sorted by sender." ([Gmail Community](https://support.google.com/mail/thread/225113394/gmail-sort-by-sender?hl=en)); ver também [r/GMail](https://www.reddit.com/r/GMail/comments/1kk4hrn/how_to_sort_my_inbox_by_sender/) e [r/GMail](https://www.reddit.com/r/GMail/comments/1v49f5j/putting_specific_senders_in_a_folder/)
- "The main downside for me is the lack of subject based filtering." ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/16ygopo/worth_the_switch_from_superhuman/))
- "the rules engine alone saved me probably 3 hours a week" ([r/Missive](https://www.reddit.com/r/Missive/comments/1rxwdy8/after_trying_basically_every_email_client_missive/))
- Limites Proton/Fastmail: [Justin Harter](https://justinharter.com/an-actually-useful-review-of-proton-mail-vs-fastmail-vs-hey/) (review externo)

**7. Preço (≈7).** O Superhuman custa US$ 25 a 30 por mês e é considerado caro; o desconto educacional pesa na decisão. No HEY, US$ 99/ano é aceito por quem gosta do fluxo, mas pesa em equipe. O eM Client gratuito limita contas. Há demanda por licença vitalícia (Canary) e por bundle (Setapp).

**8. Calendário (≈6).** O Proton Calendar não tem busca no mobile e sincroniza devagar. O calendário do HEY é visto como fraco. No New Outlook o calendário é lento e não permite definir lembrete direto ao abrir o convite.
- [r/ProtonMail: "I'm pretty much done with Proton Calendar"](https://www.reddit.com/r/ProtonMail/comments/1wdm89x/im_pretty_much_done_with_proton_calendar/), [r/tutanota: Calendar issues](https://www.reddit.com/r/tutanota/comments/1w4k7bk/calendar_issues_more/)
- "Hey's calendar is horrible. The email is good" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/1t3l5qh/should_i_make_the_leap/))

**9. Triagem e Screener (≈5).** É o recurso mais elogiado do HEY. Críticas: a triagem cansa ("afraid to open the app"), há só 3 categorias fixas e listas de e-mail caem no lugar errado.
- "nothing gets to your inbox until you see it in the Screener and accept" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/1sv2jst/is_heyemail_worth_using/))
- "too limiting in terms of sorting my mail (3 fixed categories)" (mesma thread)

**10. Follow-up e rastreamento (≈5).** No Gmail, os "Nudges" são heurísticos e deixam threads de fora; os usuários recorrem a Boomerang e FollowUpThen. No Missive, a única falta citada é **open tracking**; quem precisa disso usa uma segunda ferramenta ou um CRM.
- [r/GMail: reminders when sent emails haven't been responded to](https://www.reddit.com/r/GMail/comments/1ug9yds/how_to_get_inbox_reminders_when_sent_emails/), [r/GMail: follow up add-on](https://www.reddit.com/r/GMail/comments/1w5l4yp/looking_for_follow_up_add_on/)
- "Only thing missing is email open tracking." ([r/Missive](https://www.reddit.com/r/Missive/comments/1rxwdy8/after_trying_basically_every_email_client_missive/))
- **Tensão de produto:** existe ao mesmo tempo demanda por rastrear o que a pessoa envia e por bloquear rastreamento no que ela recebe (tema 12).

**11. Notificações seletivas (≈4).** O pedido é notificar só VIPs, só uma label ou só uma thread. O Apple Mail tem VIP; o Gmail exige gambiarra com filtro, label e notificação por label.
- [r/applehelp](https://www.reddit.com/r/applehelp/comments/1ejnevd/vip_inbox_notifications_no_other_email/), [r/ios](https://www.reddit.com/r/ios/comments/1i4k65h/can_i_get_notifications_when_i_get_an_email_from/), [r/GMail](https://www.reddit.com/r/GMail/comments/1h5rr5r/can_i_make_mails_from_important_contacts_get/)
- Também aparece no Spark, com push que não chega em contas Microsoft ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1r0iqbj/ms365_authentication_issue/)).

**12. Privacidade e pixels (≈4).** O consenso é bloquear imagens remotas e usar proxy de imagens. O Proton bloqueia pixels conhecidos e limpa parâmetros de rastreio de links ([Proton](https://proton.me/support/email-tracker-protection)). O HEY tem "No spy tracking" e image proxy (página oficial do HEY).
- ["Spy pixels in emails have become endemic"](https://www.reddit.com/r/ProtonMail/comments/llsmd1/spy_pixels_in_emails_have_become_endemic_bbc/)

**13. Newsletters e spam (≈4).** Pedem unsubscribe em massa, agrupamento por remetente e uma "faixa de leitura" separada. O Gmail lançou "Manage subscriptions" ([Google](https://support.google.com/mail/answer/15621070)).
- [r/productivity: Email out of control](https://www.reddit.com/r/productivity/comments/1gmv24u/email_out_of_control_with_unread_emails_and/), [r/YouShouldKnow](https://www.reddit.com/r/YouShouldKnow/comments/1jfcb91/ysk_you_can_delete_almost_all_marketing_emails_by/)

**14. Multiplataforma e sincronia de configurações (≈4).** O Thunderbird não sincroniza perfil e configurações entre dispositivos. O Mimestream é só para Mac. Há pedido explícito de PC, Mac e Android com a mesma configuração ([r/software](https://www.reddit.com/r/software/comments/1n9ffbk/free_multiaccount_multiplatform_email_client_for/), [r/Windows11](https://www.reddit.com/r/Windows11/comments/1qn2vwa/recommendation_for_a_mail_app_on_windows_11/)).

**15. Portabilidade (≈3).** O HEY não tem IMAP e, na saída, entrega "um mbox gigante desorganizado" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/1t3l5qh/should_i_make_the_leap/), [r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/16ygopo/worth_the_switch_from_superhuman/)). Em empresas, o TI às vezes **bloqueia clientes de terceiros** no M365 ([r/Office365](https://www.reddit.com/r/Office365/comments/1jwl77g/why_is_outlook_still_missing_unified_inbox_and/)).

**16. Acessibilidade (≈4).** Usuários cegos evitam o New Outlook e citam Thunderbird, Outlook Classic e clientes novos feitos para NVDA/JAWS (QuickMail, ZBox) ([r/Blind](https://www.reddit.com/r/Blind/comments/1wrlkq3/email_clients_for_windows/), [r/BlindAndFine](https://www.reddit.com/r/BlindAndFine/comments/1wtb99w/zbox_a_new_fully_accessible_email_client_for/), [r/Blind](https://www.reddit.com/r/Blind/comments/1jljnir/what_email_app_works_well_on_a_windows_machine/)).

**17. Colaboração (≈4).** Pedem caixa compartilhada, atribuição, comentários internos e busca em várias caixas compartilhadas ("made shared mailboxes auto appear… but no ability to search them all"; [r/Office365](https://www.reddit.com/r/Office365/comments/1ni74hj/new_outlook_is_a_disaster_why_do_they_persist_it/)). Missive é tido como "Front without the price tag" ([r/Missive](https://www.reddit.com/r/Missive/comments/1rxwdy8/after_trying_basically_every_email_client_missive/)).

**18. Performance (≈5).** O Apple Mail é lento para alguns usuários, o Thunderbird é "slower/less polished", o Spark "resource hog" e o eM Client tem busca lenta. O Superhuman e o Mimestream são lembrados pela velocidade.

**19. Anexos (≈3).** Pedem que arquivos Office abram direto (Outlook mobile é a referência), assinatura de PDF sem Adobe (Spark exige Adobe; [r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1s5p95b/ai_makes_me_want_to_leave_spark/)) e fluxo de salvar no SharePoint sem erros de "nome longo" ([r/Outlook](https://www.reddit.com/r/Outlook/comments/1wjphac/new_outlook_is_terrible/)).

**20. Editor e composição (≈4).** A tagline "Sent with Spark" é ativada por padrão. Pedem autocompletar de contatos, verificação ortográfica antes de enviar, fonte e tamanho customizáveis e janelas destacáveis. A primeira rodada desta pesquisa já tinha registrado as reclamações sobre fonte no Superhuman.

**21. Snooze e lembretes (≈3).** É tratado como básico. No Apple Mail, a falta de snooze específico por provedor aparece na lista de "missing features" da busca sobre o app.

### 1.3 O que as pessoas amam (e por quê)

| App | O que é amado | Por quê (citação) |
|---|---|---|
| **Superhuman** | Velocidade, atalhos, IA discreta, follow-up | "Expensive but does what I want and super fast" ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1tysezy/finally_giving_up/)); "the one I always go back to" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/urtgkb/fastmail_to_hey_to_fastmail_to_hey_to_fastmail/)) |
| **HEY** | Screener, Imbox/Feed/Paper Trail, "divertido" | "HEY is actually fun to use, so I cannot give it up" (mesma thread) |
| **Fastmail** | Confiabilidade, aliases, regras, IMAP | "absolutely rock solid" (mesma thread); "never been happier" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/1t3l5qh/should_i_make_the_leap/)) |
| **Missive** | Regras, multi-conta, IA nas regras, equipe | "first one that combines fast UX, strong rules, multi-account support, and actually useful AI" ([r/Missive](https://www.reddit.com/r/Missive/comments/1rxwdy8/after_trying_basically_every_email_client_missive/)) |
| **Spark** | Caixa unificada no plano grátis, "Mark as read" em grupo | "United unread inbox" ([r/SparkMail](https://www.reddit.com/r/SparkMail/comments/1s5p95b/ai_makes_me_want_to_leave_spark/)) |
| **Thunderbird** | Grátis, open source, extensível, confiável | "THUNDERBIRD is the only reliable solution, with contact, agenda and tasks sync" ([r/Windows11](https://www.reddit.com/r/Windows11/comments/1qn2vwa/recommendation_for_a_mail_app_on_windows_11/)) |
| **eM Client** | Integra calendários de vários provedores | "combines calendars brilliantly" (mesma thread) |
| **FairEmail** | Configurável, privacidade, open source | Síntese de [r/androidapps](https://www.reddit.com/r/androidapps/comments/1r2eozb/email_client/) |
| **Mimestream** | Nativo de Mac, rápido, fiel ao Gmail | Síntese de [r/macapps](https://www.reddit.com/r/macapps/comments/17mfpem/canaray_vs_spark_vs_mimestream_for_email_app/) |
| **Proton / Tuta** | Criptografia, bloqueio de pixels | [r/ProtonMail](https://www.reddit.com/r/ProtonMail/comments/llsmd1/spy_pixels_in_emails_have_become_endemic_bbc/), [r/tutanota](https://www.reddit.com/r/tutanota/comments/1e8no9o/proton_mail_vs_tutanota_why_did_you_choose/) |

**Padrão:** os apps amados resolvem **uma dor de forma radical**, como velocidade, controle de entrada, confiabilidade ou regras. Os apps odiados quebram o **básico**: busca, sincronização e envio.

---

## 2. Matriz de capacidades

Legenda: ✅ sim · ⚠️ parcial ou com restrição · ❌ não · (nv) não verificado nesta coleta. Preços em USD, salvo indicação, consultados em out/2026.

### 2.1 Plataforma, provedores e preço

| App | Plataformas | Provedores / IMAP | Caixa unificada | Preço (verificado?) |
|---|---|---|---|---|
| Gmail | Web, iOS, Android | Gmail; outras contas via IMAP no app mobile (nv) | ⚠️ só no mobile (nv) | Grátis; Workspace pago (nv) |
| Outlook (new) | Win, Mac, Web, iOS, Android | M365, Outlook.com, Gmail, iCloud, IMAP (nv) | ⚠️ "All Accounts" em liberação gradual desde ago/2026; busca multi-conta prevista para out/2026 ([MS](https://mc.merill.net/message/RM564609)) | Grátis / M365 |
| Outlook (classic) | Win, Mac | Exchange, IMAP, POP, PST | ⚠️ (nv) | M365 / licença |
| Apple Mail | macOS, iOS | iCloud, Gmail, Exchange, IMAP | ✅ (nv) | Grátis |
| Superhuman | Web, Mac, Win, iOS, Android (nv) | Gmail e Outlook/M365 ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/urtgkb/fastmail_to_hey_to_fastmail_to_hey_to_fastmail/)) | ❌ ([r/SuperhumanEmail](https://www.reddit.com/r/SuperhumanEmail/comments/1io7tcf/no_unified_inbox_how_do_you_survive/)) | 25/mês no plano anual, 30 no mensal; Business 33/40 ([superhuman.com](https://superhuman.com/plans/mail)) |
| Spark | Mac, Win, iOS, Android | Gmail, M365, iCloud, Yahoo, IMAP, Proton (via Bridge) ([help](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts)) | ✅ | Free; Plus 10/mês ou 99/ano; Pro 20/mês ou 199/ano ([pricing](https://sparkmailapp.com/pricing)) |
| HEY | Web, Mac, Win, Linux, iOS, Android (nv) | Só HEY (sem IMAP) | ⚠️ "Link multiple accounts" (só HEY) | 99/ano ([fonte secundária](https://www.hey.com/pricing/), nv) |
| Fastmail | Web, iOS, Android | Provedor próprio; IMAP/JMAP aberto | ⚠️ (nv) | Individual 60/ano ou 6/mês ([pricing](https://www.fastmail.com/pricing/)) |
| Proton Mail | Web, iOS, Android, desktop | Provedor próprio; IMAP só via Bridge (nv) | ❌ (nv) | Plus 47,88/ano ou 4,99/mês ([pricing](https://proton.me/mail/pricing)) |
| Tuta | Web, desktop, iOS, Android | Provedor próprio, sem IMAP (nv) | ❌ (nv) | Revolutionary €3/mês no plano anual (fonte secundária) |
| Thunderbird | Win, Mac, Linux, Android (K-9) | IMAP, POP, Exchange (via add-on ou nativo, nv) | ✅ (nv) | Grátis, open source |
| Mimestream | Só macOS | Só Gmail | ⚠️ perfis múltiplos (nv) | 4,99/mês ou 49,99/ano (fonte secundária) |
| Shortwave | Web, Mac, Win, iOS, Android | Gmail; outros via encaminhamento ([docs](https://www.shortwave.com/docs/references/shortcuts/)) | ⚠️ "Unified inbox via forwarding" ([docs](https://www.shortwave.com/docs/references/shortcuts/)) | Free; Pro 18/seat; Business 30/45/120 (fonte secundária) |
| Missive | Mac, Win, Linux (nv), Web, iOS, Android | Gmail, M365, IMAP, SMS/WhatsApp (nv) | ✅ | 14 a 36 por usuário/mês ([pricing](https://missiveapp.com/pricing)) |
| Canary | Mac, Win, iOS, Android | Gmail, Outlook, iCloud, IMAP | ✅ | Free; Growth 36/ano; Pro+ 100/ano; vitalício 100/300 ([pricing](https://canarymail.io/pricing)) |
| Notion Mail | **Encerrado em 22/09/2026** ([Notion Help](https://www.notion.com/help/notion-mail-inbox-is-going-away-what-to-do-next), [TechCrunch](https://techcrunch.com/2026/06/25/notion-mail-shuts-down-amid-agent-takeover/)) | Era só Gmail | n/a | n/a |
| Airmail | Mac, iOS | Gmail, Exchange, iCloud, IMAP | ✅ (nv) | Pro 5,99/mês ou 29,99/ano; grátis limitado a 1 conta ([help](https://help.airmailapp.com/en-us/article/airmail-pro-pricing-and-subscription-plans-189o6bh/)) |
| eM Client | Win, Mac, iOS, Android | Gmail, Exchange, IMAP, CalDAV | ✅ | Grátis com 2 contas em 1 dispositivo; Personal 49,95/ano; Business 59,95/ano ([pricing](https://www.emclient.com/pricing)) |
| Mailspring | Win, Mac, Linux | IMAP, Gmail, M365 (nv) | ✅ (nv) | Grátis; Pro pago (nv) |
| FairEmail | Android | IMAP, POP, Gmail, Outlook | ✅ (nv) | Grátis; Pro pago (nv) |
| SaneBox (camada de triagem, não é cliente) | Web (painel), iOS, Android (Digest); funciona em qualquer cliente | Gmail, M365, Exchange/ActiveSync, iCloud, Yahoo, Fastmail, qualquer IMAP ([FAQ](https://www.sanebox.com/faq)) | n/a (usa a caixa unificada do cliente; pastas Sane duplicadas por conta) | Snack US$ 9,49/mês ou 65/ano; Lunch 15,99 ou 109; Dinner 42,99 ou 319 (fontes secundárias, ver 5.2) |
| Front | Web, desktop, mobile | Gmail, M365, IMAP, canais | ✅ (equipe) | Mais caro que Missive; IA paga à parte (síntese da busca, nv) |

### 2.2 Recursos de fluxo

Para economizar espaço: **S** = snooze, **FU** = lembrete de follow-up, **SL** = enviar depois, **US** = desfazer envio, **Cat** = split inbox ou categorização automática, **Scr** = screener de remetentes novos, **Reg** = regras/filtros, **Tpl** = templates/snippets.

| App | Busca | S | FU | SL | US | Cat | Scr | Reg | Tpl |
|---|---|---|---|---|---|---|---|---|---|
| Gmail | Operadores avançados (servidor) | ✅ (`b`, [Google](https://support.google.com/mail/answer/6594)) | ⚠️ Nudges heurísticos | ✅ (nv) | ✅ (nv) | ✅ abas (nv) | ❌ | ✅ filtros, sem ordenar por remetente | ✅ (nv) |
| Outlook new | Servidor (Exchange); queixas | ✅ (nv) | ⚠️ flag ([MS](https://support.microsoft.com/en-us/office/keyboard-shortcuts-for-outlook-3cdeb221-7ae5-4c1d-8c1d-9e63216c1efd)) | ✅ (nv) | ✅ (nv) | ✅ Focused | ❌ | ⚠️ sem "run now" | ✅ (nv) |
| Outlook classic | Local + servidor; Advanced Find, Search folders ([MS](https://support.microsoft.com/en-us/office/keyboard-shortcuts-for-outlook-3cdeb221-7ae5-4c1d-8c1d-9e63216c1efd)) | ❌ (nv) | ✅ Flag for follow up | ✅ (nv) | ⚠️ (nv) | ✅ | ❌ | ✅ completo | ✅ Quick Parts (nv) |
| Apple Mail | Spotlight; índice frágil | ✅ (nv) | ✅ "Follow up" (nv) | ✅ (nv) | ✅ Cmd-Z "Unsend" ([Apple](https://support.apple.com/guide/mail/keyboard-shortcuts-mlhlb94f262b/mac)) | ✅ Categorias (nv) | ❌ | ✅ Rules | ❌ (nv) |
| Superhuman | Rápida (nv) | ✅ Remind Me `H` | ✅ "Remind me" no compose | ✅ `Ctrl+Shift+L` | ✅ (nv) | ✅ Splits | ❌ | ⚠️ auto-labels (nv) | ✅ Snippets ([PDF](https://download.superhuman.com/Superhuman_Keyboard_Shortcuts.pdf)) |
| Spark | Smart Search | ✅ | ✅ ([help](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts)) | ✅ | ✅ timer ajustável | ✅ Smart Inbox | ✅ Gatekeeper | ⚠️ Smart Folders | ✅ Templates |
| HEY | Lenta (queixas) | ⚠️ Set Aside/Bubble Up | ✅ Bubble Up | ✅ (nv) | ✅ (nv) | ✅ Imbox/Feed/Paper Trail | ✅ Screener | ⚠️ só por remetente/domínio | ❌ (nv) |
| Fastmail | Rápida, cruza pastas ([help](https://www.fastmail.help/hc/en-us/articles/360058753534-Keyboard-shortcuts)) | ✅ `b` | ⚠️ (nv) | ✅ (nv) | ✅ (nv) | ❌ (nv) | ❌ | ✅ até 1.000 (Sieve) | ✅ (nv) |
| Proton | Corpo indexado localmente (lento) | ✅ (nv) | ❌ (nv) | ✅ (nv) | ✅ (nv) | ✅ Categories (ago/2026, [blog](https://proton.me/blog/shortcuts)) | ❌ | ✅ até 250 | ⚠️ (nv) |
| Tuta | Local criptografada | ❌ (nv) | ❌ (nv) | ⚠️ (nv) | ❌ (nv) | ❌ | ❌ | ✅ regras de caixa (nv) | ✅ (nv) |
| Thunderbird | Local (Gloda) + quick filter | ❌ nativo (nv) | ⚠️ tags | ✅ Send Later `Ctrl+Shift+Enter` (wiki) | ❌ (nv) | ❌ | ❌ | ✅ filtros locais | ✅ templates |
| Mimestream | Gmail + local | ✅ | ❌ (nv) | ✅ (nv) | ✅ (nv) | ✅ categorias Gmail | ❌ | ✅ filtros Gmail | ✅ `⌘/` Templates |
| Shortwave | IA + operadores | ✅ `B/H` | ⚠️ (nv) | ✅ (nv) | ✅ `Ctrl+Z` | ✅ Bundles | ❌ | ✅ auto-labels por IA | ✅ AI Snippets |
| Missive | Boa (elogiada) | ✅ | ✅ (nv) | ✅ (nv) | ✅ (nv) | ⚠️ | ❌ | ✅ fortes, com IA | ✅ Responses |
| Canary | (nv) | ✅ (nv) | ✅ (nv) | ✅ (nv) | ✅ (nv) | ✅ (nv) | ✅ Screener (nv) | ⚠️ (nv) | ✅ (nv) |
| Airmail | (nv) | ✅ | ✅ (nv) | ✅ | ✅ | ⚠️ | ❌ | ✅ (nv) | ✅ (nv) |
| eM Client | Local; lenta para alguns | ✅ (nv) | ⚠️ | ✅ (nv) | ✅ (nv) | ❌ | ❌ | ✅ | ✅ |
| Mailspring | Local | ✅ Pro (nv) | ✅ Pro (nv) | ✅ Pro (nv) | ✅ (nv) | ❌ | ❌ | ✅ (nv) | ✅ (nv) |
| SaneBox | n/a (usa a busca do cliente) | ✅ SaneSnooze (pastas) | ✅ SaneReminders e @SaneNoReplies | ❌ | ❌ | ✅ SaneLater, News, CC, pastas DIY | ⚠️ treino por remetente e BlackHole; sem quarentena de remetentes novos (o Digest destaca os novos) | ✅ filtros por remetente, domínio e assunto, com prévia | ❌ |
| FairEmail | Local + servidor | ✅ (nv) | ❌ (nv) | ✅ (nv) | ✅ (nv) | ⚠️ | ❌ | ✅ regras avançadas (nv) | ✅ (nv) |

### 2.3 IA, privacidade, calendário, colaboração e offline

| App | IA | Rastreamento / bloqueio de pixel | Criptografia | Calendário | Colaboração | Integrações | Offline |
|---|---|---|---|---|---|---|---|
| Gmail | Gemini (nv) | Proxy de imagens (nv) | TLS; S/MIME no Workspace (nv) | ✅ Google Cal | ⚠️ delegação | Add-ons | ⚠️ (nv) |
| Outlook new/classic | Copilot (atalho `Ctrl+3`, [MS](https://support.microsoft.com/en-us/office/keyboard-shortcuts-for-outlook-3cdeb221-7ae5-4c1d-8c1d-9e63216c1efd)) | Bloqueia conteúdo externo (classic, `Ctrl+Shift+W`) | S/MIME (nv) | ✅ | ✅ caixas compartilhadas | Add-ins, Teams, Loop | ✅ classic; ⚠️ new (nv) |
| Apple Mail | Apple Intelligence (nv) | Mail Privacy Protection (proxy de IP) | S/MIME (nv) | Separado (Calendar) | ❌ | Sistema | ✅ |
| Superhuman | ✅ Ask AI `?` | ⚠️ envia read status (nv) | ❌ | ✅ embutido (`0`, `B`) | ⚠️ Business (nv) | CRM (nv) | ✅ (nv) |
| Spark | ✅ +AI (resumo, tradução, auto-drafts) | (nv) | ❌ | ✅ | ✅ Teams: shared drafts/threads/inbox | Trello, Asana, Todoist, Notion, Slack etc. ([help](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts)) | ⚠️ |
| HEY | Agents/CLI (novidade no site) | ✅ "No spy tracking", Image Proxy ([hey.com](https://www.hey.com/keyboard-shortcuts/)) | ❌ E2E (nv) | ✅ HEY Calendar | ⚠️ HEY for Domains | API/CLI | ⚠️ |
| Fastmail | ❌ (nv) | ✅ bloqueia imagens (`Shift+L` mostra) | ❌ E2E | ✅ CalDAV | ⚠️ famílias/equipes | JMAP API | ⚠️ (nv) |
| Proton | Lumo / IA privada (nv) | ✅ bloqueio de pixels e limpeza de links ([Proton](https://proton.me/support/email-tracker-protection)) | ✅ E2E / PGP | ✅ (fraco no mobile) | ⚠️ | Bridge | ⚠️ |
| Tuta | ❌ | ✅ (nv) | ✅ E2E (pós-quântica, nv) | ✅ | ❌ | ❌ | ✅ (nv) |
| Thunderbird | ❌ nativo (nv) | ✅ bloqueia conteúdo remoto | ✅ OpenPGP/S/MIME | ✅ (Lightning) | ❌ | Add-ons | ✅ |
| Mimestream | ⚠️ (nv) | (nv) | ❌ | ⚠️ (nv) | ❌ | ❌ | ✅ |
| Shortwave | ✅ AI Assistant, MCP ([docs](https://www.shortwave.com/docs/references/shortcuts/)) | (nv) | ❌ | ⚠️ (nv) | ✅ share/assign | CRM, MCP | ⚠️ (nv) |
| Missive | ✅ IA nas regras | ❌ sem open tracking (removido) | ❌ | ✅ (atalhos de calendário) | ✅ forte (assign, chat interno) | Muitas, incl. SMS/WhatsApp (nv) | ⚠️ |
| Canary | ✅ (nv) | ✅ bloqueio (nv) | ✅ PGP (nv) | ✅ (nv) | ⚠️ (nv) | (nv) | (nv) |
| Airmail | ⚠️ (nv) | (nv) | ⚠️ (nv) | ❌ (nv) | ❌ | Muitas (nv) | ✅ |
| eM Client | ⚠️ (nv) | ✅ (nv) | ✅ PGP/S/MIME (nv) | ✅ elogiado | ⚠️ | ⚠️ | ✅ |
| Mailspring | ❌ | ✅ (nv) | ❌ | ❌ | ❌ | ⚠️ | ✅ |
| FairEmail | ❌ | ✅ forte | ✅ PGP/S/MIME (nv) | ❌ | ❌ | ❌ | ✅ |
| SaneBox | Classificação por cabeçalho e comportamento; sugestões de BlackHole por IA | n/a | n/a (credenciais cifradas, HSM; lê só cabeçalhos por padrão) | ❌ (ignora convites no NoReplies) | ❌ | Dropbox, Drive, Box (SaneAttachments); SaneFwd | n/a (serviço no servidor, 24/7) |
| Front | ✅ add-on pago | (nv) | ❌ | ⚠️ | ✅ referência (SLA, ticket) | Muitas | ⚠️ |

---

## 3. Atalhos de teclado

### 3.1 Fontes

| App | Fonte | Status |
|---|---|---|
| Gmail | https://support.google.com/mail/answer/6594 | ✅ lida na íntegra |
| Outlook (new, classic, web) | https://support.microsoft.com/en-us/office/keyboard-shortcuts-for-outlook-3cdeb221-7ae5-4c1d-8c1d-9e63216c1efd | ✅ |
| Apple Mail (macOS) | https://support.apple.com/guide/mail/keyboard-shortcuts-mlhlb94f262b/mac | ✅ (a página tem só ~30 atalhos; o restante está nos menus do app) |
| Superhuman | https://download.superhuman.com/Superhuman_Keyboard_Shortcuts.pdf (v8, Win/Linux; no Mac, ctrl → ⌘) | ✅ |
| Spark | https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts | ✅ |
| HEY | https://www.hey.com/keyboard-shortcuts/ | ✅ |
| Fastmail | https://www.fastmail.help/hc/en-us/articles/360058753534-Keyboard-shortcuts | ✅ |
| Missive | https://missiveapp.com/docs/advanced-features/shortcuts.md | ✅ |
| Shortwave | https://www.shortwave.com/docs/references/shortcuts/ | ✅ |
| Mimestream | https://mimestream.com/help/user-guide/keyboard-shortcuts | ✅ |
| Thunderbird | https://support.mozilla.org/kb/keyboard-shortcuts-thunderbird | ❌ bloqueada (desafio JS). Usei o resumo do índice de busca e o [MozillaWiki](https://wiki.mozilla.org/Thunderbird:Help_Documentation:Keyboard_Shortcuts) (2007, desatualizado). **Confirmar.** |
| Proton | https://proton.me/support/keyboard-shortcuts | ⚠️ a lista oficial está em imagem. Usei o [DefKey](https://defkey.com/protonmail-shortcuts) (2022). **Confirmar.** |

### 3.2 Tabela comparativa de ações comuns

(Os modificadores seguem a fonte: ⌘ no Mac, Ctrl no Windows. "g i" significa uma sequência: g e depois i.)

| Ação | Gmail | Outlook new (Win) | Outlook web | Outlook classic | Apple Mail | Superhuman | Spark (Mac) | HEY | Fastmail | Thunderbird* | Mimestream (padrão) | Shortwave | Missive (padrão / Gmail) | Proton* |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Compor | c | Ctrl+N | N | Ctrl+Shift+M | ⌘N | C | C | w | c | Ctrl+N / Ctrl+M | ⌘N | C | ⌘N / C | C |
| Responder | r | Ctrl+R | R / Ctrl+R | Ctrl+R | ⌘R | R | ⇧R | r | r | Ctrl+R | ⌘R | R | ⌘R / R | R (nv) |
| Responder a todos | a | Ctrl+Shift+R | Shift+R | Ctrl+Shift+R | ⇧⌘R | Enter | R |: | a | Ctrl+Shift+R | ⇧⌘R | A | ⌘⇧R / ⇧R | Shift+R (nv) |
| Encaminhar | f | Ctrl+F | Shift+F | Ctrl+F | ⇧⌘F | F | F | f | f | Ctrl+L | ⇧⌘F | F | ⌘⇧F / F | Shift+F (nv) |
| Arquivar / Done | e |: (nv) | E |: | ⌃⌘A | E | E |: | y | A | ⌃⌘A | E / D | ⌫ / E | A |
| Excluir | # | Delete | Delete | Delete | ⌫ (nv) | # | Delete | t | d | Delete | ⌘⌫ | # | ⌘⌫ / # | T |
| Marcar lido | Shift+i | Ctrl+Q | Q | Ctrl+Q | ⇧⌘U (alterna) | U (alterna) | U | e (bulk "seen", nv) | Shift+i | M (alterna) / R (thread) |: | Shift+I |: | R |
| Snooze | b |: |: |: |: | H | S | z (Bubble Up) | b |: | (nv) | B / H | ⌘⇧J / O |: (nv) |
| Buscar | / |: (nv) | Alt+Q | Ctrl+E / F3 | ⌥⌘F (nv) | / | ⌘F | s ou / | / | Ctrl+K (quick filter) / Ctrl+Shift+F | ⌥⌘F | / | ⌘F / / | / |
| Próxima / anterior | j / k | Ctrl+> / Ctrl+< | ↓ / ↑ | ↓ / ↑ | ↓ / ↑ | J / K | → / ← | j / k | j / k | F / B | ↓ / ↑ (nv) | J / K | ↓↑ / J K | J / K |
| Command palette |: | Alt (key tips) |: | Alt+Q (Tell Me) |: | Ctrl/⌘+K | ⌘K | h / ⌘J (menu) | Ctrl duas vezes (ajuda) |: |: | Ctrl+K | ⌘K | Shift+Space |
| Ir para inbox | g i | Ctrl+1 (Mail) | Ctrl+Shift+1 | Ctrl+Shift+I | ⌘1 (nv) | G I | ⌘⇧1 | 1 (Imbox) | g + nome da pasta |: (nv) | ⌘1 | G I | ⌘1 / G I | G I |
| Rótulo / mover | l / v | Ctrl+Shift+V (classic) |: | Ctrl+Shift+V | ⌃⌘M (pasta prevista) | L / V | L / ⌘⇧M | b / v | l / m ou v | 1–9 (tags) | ⌘L / ⇧⌘M | L / V | ⌘⇧L / L, ⌘⌥L / V |: (nv) |
| Desfazer | z | Ctrl+Z | Ctrl+Z | Ctrl+Z | ⌘Z (unsend) | Z | (nv) |: | z | Ctrl+Z | ⌘Z | Z | (nv) | (nv) |
| Enviar | ⌘/Ctrl+Enter | Ctrl+Enter | Ctrl+Enter | Alt+S / Ctrl+Enter | ⇧⌘D | Ctrl+Enter | ⌘↩ | ⌘↩ | Ctrl+Enter | Ctrl+Enter | ⌘↩ | Ctrl+Enter | (nv) | Ctrl+Enter |
| Ajuda de atalhos | ? | ? | Shift+? |: |: | via ⌘K | Settings › Shortcuts | ? | ? |: | Settings | Shift+? | Settings › Shortcuts | ? |

\* Thunderbird e Proton vêm de fontes secundárias; confirmar antes de usar como referência.

**Padrões que valem como convenção de fato:**
1. **Dialeto "Gmail" de tecla única** (c, r, a, f, e, #, j/k, /, g+letra, x, l, v, z, ?) é seguido por Superhuman, Shortwave, Fastmail, Proton e pelos presets "Gmail" de Missive, Mimestream, Spark e Outlook web. **Oferecer esse preset é praticamente obrigatório.**
2. **Command palette (⌘/Ctrl+K)**: Superhuman, Shortwave, Spark e Missive usam como porta de descoberta, mostrando o atalho de cada ação ao lado.
3. **Presets intercambiáveis**: Missive (Default/Gmail), Mimestream (Default/Apple Mail/Gmail), Spark (Desktop/Classic/Apple Mail/Gmail/Superhuman/Custom), Outlook web (Outlook/Gmail/Yahoo/Outlook.com) e Gmail (customizáveis).
4. **"Send & archive"** (⇧⌘↩ ou Ctrl+Shift+Enter) aparece em Superhuman, Shortwave, Spark e Mimestream.
5. **Diferenças a evitar:** no Spark, R é "reply all" e ⇧R é "reply", o inverso do Gmail. No Superhuman, Enter é "reply all".

### 3.3 Tabelas por app (núcleo de e-mail; listas completas nas fontes)

**Gmail** ([fonte](https://support.google.com/mail/answer/6594)). Os atalhos precisam ser ativados em Settings.
| Ação | Tecla | Ação | Tecla |
|---|---|---|---|
| Compor / em nova aba | c / d | Arquivar | e |
| Responder / todos / encaminhar | r / a / f | Arquivar e ir para anterior/próxima | ] / [ |
| Nova janela (resp/todos/enc) | Shift+r / Shift+a / Shift+f | Excluir / spam / silenciar | # / ! / m |
| Snooze | b | Marcar lido / não lido | Shift+i / Shift+u |
| Importante / não | + / - | Estrela | s |
| Desfazer | z | Selecionar | x |
| Label / mover / mais ações | l / v / . | Buscar | / |
| Próxima / anterior conversa | j / k | Próxima / anterior mensagem | n / p |
| Voltar à lista | u | Abrir | o ou Enter |
| Inbox / Starred / Snoozed / Sent / Drafts / All | g i / g s / g b / g t / g d / g a | Ir para label / tasks | g l / g k |
| Selecionar todos / nenhum / lidos / não lidos | *a / *n / *r / *u | Enviar | ⌘/Ctrl+Enter |
| Cc / Bcc / From | ⌘/Ctrl+Shift+c / b / f | Adicionar a Tasks | Shift+t |
| Ajuda | ? | Expandir / recolher tudo | ; / : |

**Outlook new (Windows)** ([fonte](https://support.microsoft.com/en-us/office/keyboard-shortcuts-for-outlook-3cdeb221-7ae5-4c1d-8c1d-9e63216c1efd))
| Ação | Tecla |
|---|---|
| Nova mensagem ou evento | Ctrl+N |
| Responder / todos / encaminhar | Ctrl+R / Ctrl+Shift+R / Ctrl+F |
| Enviar | Ctrl+Enter |
| Lido / não lido | Ctrl+Q / Ctrl+U |
| Flag | Insert |
| Excluir / excluir permanente | Delete / Shift+Delete |
| Próxima / anterior | Ctrl+> / Ctrl+< |
| Abrir em nova janela | Shift+Enter |
| Mail / Calendário / Copilot / People | Ctrl+1 / 2 / 3 / 4 |
| Painel de pastas | Ctrl+Y |
| Ajuda | ? |

**Outlook web / Outlook.com** (preset Outlook; pode trocar para Gmail/Yahoo em Settings › General › Accessibility)
| Ação | Tecla |
|---|---|
| Novo | N |
| Arquivar | E |
| Responder / todos | R / Shift+R |
| Encaminhar | Shift+F |
| Lido / não lido | Q / U |
| Buscar | Alt+Q |
| Enviar | Ctrl+Enter |
| Mail / Calendário | Ctrl+Shift+1 / 2 |
| Flag | Insert |
| Ajuda | Shift+? |

**Outlook classic** (fonte idem)
| Ação | Tecla |
|---|---|
| Nova mensagem | Ctrl+Shift+M |
| Responder / todos / encaminhar | Ctrl+R / Ctrl+Shift+R / Ctrl+F |
| Encaminhar como anexo | Ctrl+Alt+F |
| Enviar | Alt+S ou Ctrl+Enter |
| Buscar | Ctrl+E / F3 |
| Busca avançada | Ctrl+Shift+F |
| Search folder | Ctrl+Shift+P |
| Lido / não lido | Ctrl+Q / Ctrl+U |
| Mover / copiar para pasta | Ctrl+Shift+V / Ctrl+Shift+Y |
| Flag follow-up | Ctrl+Shift+G |
| Ir para pasta | Ctrl+Y |
| Inbox / Outbox | Ctrl+Shift+I / Ctrl+Shift+O |
| Excluir e ignorar conversa | Ctrl+Shift+D |
| Send/Receive | F9 |
| Mostrar conteúdo bloqueado | Ctrl+Shift+W |

**Apple Mail (macOS)** ([fonte](https://support.apple.com/guide/mail/keyboard-shortcuts-mlhlb94f262b/mac))
| Ação | Tecla |
|---|---|
| Novo | ⌘N |
| Responder / todos / encaminhar / redirecionar | ⌘R / ⇧⌘R / ⇧⌘F / ⇧⌘E |
| Enviar | ⇧⌘D |
| Cancelar envio (unsend) | ⌘Z |
| Lido / não lido | ⇧⌘U |
| Arquivar | ⌃⌘A |
| Junk | ⇧⌘J |
| Mover para caixa prevista | ⌃⌘M |
| Aplicar regras | ⌃⌘L |
| Filtro | ⌘L |
| Anexar | ⇧⌘A |
| Colar como citação | ⇧⌘V |
| Bcc / Reply-To | ⌥⌘B / ⌥⌘R |
| Buscar novos | ⇧⌘N |
| Texto puro / rico | ⇧⌘T |
| Sidebar | ⌃⌘S |

**Superhuman** ([PDF v8](https://download.superhuman.com/Superhuman_Keyboard_Shortcuts.pdf); no Mac, ctrl → ⌘)
| Ação | Tecla | Ação | Tecla |
|---|---|---|---|
| Command | Ctrl+K | Done / Not done | E / Shift+E |
| Buscar | / | Remind me (snooze) | H |
| Desfazer | Z | Ask AI | ? |
| Compor | C | Responder / todos / encaminhar | R / Enter / F |
| Estrela | S | Lido/não lido | U |
| Lixeira / spam / mute | # / ! / Shift+M | Unsubscribe | Ctrl+U |
| Label / remover / mover | L / Y / V | Próx/ant conversa | J / K |
| Próx/ant mensagem | N / P | Inbox / Done / Reminders | G I / G E / G H |
| Split seguinte | Tab | Trocar conta | Alt+1–9 |
| Send later / remind no compose | Ctrl+Shift+L / Ctrl+Shift+H | Snippet | ; |
| Enviar / enviar e done | Ctrl+Enter / Ctrl+Shift+Enter | Instant send | Shift+Z |
| Calendário dia / semana / evento | 0 / 0 0 / B | Filtros: unread / starred / no-reply | Shift+U / Shift+S / Shift+R |

**Spark Desktop (Mac)** ([fonte](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts)). Presets disponíveis: Spark, Classic, Apple Mail, Gmail, Superhuman e Custom.
| Ação | Tecla | Ação | Tecla |
|---|---|---|---|
| Compor | C | Responder / todos | ⇧R / R |
| Encaminhar | F | Done | E |
| Snooze / Pin / Set Aside | S / D / G | Lido | U |
| Spam | ⇧1 | Label / mover | L / ⌘⇧M |
| Prioridade | I | Próx/ant | → / ← |
| Command Center | ⌘K | Buscar | ⌘F |
| Enviar / enviar e done | ⌘↩ / ⌘⇧↩ | Template | ⌘⇧T |
| Gatekeeper aceitar / bloquear / bloquear domínio | ⌘T / ⌘B / ⌘⌥⇧B | Traduzir thread | ⌥⇧T |
| Inbox / Calendário / AI Assistant | ⌘⇧1 / ⌘⇧2 / ⌘⇧C | Resumo IA curto / detalhado | ⌘⇧S / ⌘⇧D |

**HEY** ([fonte](https://www.hey.com/keyboard-shortcuts/))
| Ação | Tecla | Ação | Tecla |
|---|---|---|---|
| Imbox / Feed / Paper Trail | 1 / 2 / 3 | Reply Later / Set Aside / Bubble Up | 4 / 5 / 6 |
| Previously Seen | 9 | Calendário ↔ e-mail | 0 |
| Buscar | s ou / | Menu HEY | h ou ⌘J |
| Novo e-mail | w | Power through new | o |
| Reply now / Reply later / Set aside / Bubble up | r / l / a / z | Forward / Label / Move / Trash | f / b / v / t |
| Bulk: selecionar / próx / ant | x / j / k | Bulk: Read Together / Reply Together / Merge | o / r / g |
| Mover p/ Imbox / Paper Trail / Feed | i / p / d | Ignorar / sticky / coleção | - / y / n |

**Fastmail** ([fonte](https://www.fastmail.help/hc/en-us/articles/360058753534-Keyboard-shortcuts))
| Ação | Tecla | Ação | Tecla |
|---|---|---|---|
| Compor | c | Buscar (todas as pastas) | / |
| Responder / todos / só remetente | r / a / Alt+r | Encaminhar | f |
| Arquivar | y | Arquivar e próx / ant | [ / ] |
| Lixeira / excluir permanente | d / % | Spam | ! |
| Mover | m ou v | Labels | l |
| Snooze (menu; b+1…7 predefinidos) | b | Pin | s |
| Lido / não lido | Shift+i / Shift+u | Mute / unmute | Shift+m / Alt+Shift+m |
| Próx / ant | j / k | Ir para pasta | g |
| Mostrar imagens bloqueadas | Shift+l | Desfazer (até 10 ações) / refazer | z / Ctrl+Shift+z |
| Mail / Contatos / Calendário | Shift+g m / a / c | Ajuda | ? (ou Ctrl duas vezes) |

**Thunderbird** (⚠️ fonte oficial bloqueada; dados do resumo da KB da Mozilla e do MozillaWiki. **Confirmar.**)
| Ação | Tecla |
|---|---|
| Nova mensagem | Ctrl+N / Ctrl+M |
| Responder / todos | Ctrl+R / Ctrl+Shift+R |
| Encaminhar | Ctrl+L |
| Arquivar | A |
| Alternar lido | M |
| Marcar thread lida | R |
| Marcar tudo lido | Ctrl+Shift+C |
| Tags | 1–9 (0 remove todas) |
| Próx msg / próx não lida / próx thread não lida | F / N / T |
| Anterior | B |
| Quick filter / buscar | Ctrl+K / Ctrl+Shift+F |
| Enviar agora / depois | Ctrl+Enter / Ctrl+Shift+Enter |
| Código-fonte | Ctrl+U |
| Editar como nova | Ctrl+E |
| Expandir / recolher threads | * / \ |

**Mimestream** ([fonte](https://mimestream.com/help/user-guide/keyboard-shortcuts)). Presets: Default, Apple Mail e Gmail.
| Ação | Default | Gmail |
|---|---|---|
| Nova | ⌘N | C |
| Responder / todos / encaminhar | ⌘R / ⇧⌘R / ⇧⌘F | R / A / F |
| Arquivar | ⌃⌘A | E |
| Lixeira | ⌘⌫ | # |
| Spam | ⇧⌘J | ! |
| Buscar | ⌥⌘F | / |
| Labels / mover | ⌘L / ⇧⌘M | ⌘L / ⇧⌘M |
| Enviar / enviar e arquivar | ⌘⏎ / ⇧⌘⏎ | idem |
| Template | ⌘/ | ⌘/ |
| Código-fonte | ⌥⌘U | ⌥⌘U |
| Inbox / Starred / Snoozed / Drafts / Sent | ⌘1 a ⌘5 | ⌃⌘1 a ⌃⌘5 |
| Ir para pasta | ⇧⌘O | ⇧⌘O |

**Shortwave** ([fonte](https://www.shortwave.com/docs/references/shortcuts/))
| Ação | Tecla | Ação | Tecla |
|---|---|---|---|
| Compor | C | Responder / todos / encaminhar | R / A / F |
| Done | D ou E | Done e próx / ant | [ / ] |
| Snooze | B ou H | Label / mover | L / V |
| Excluir / spam / bloquear spam | # / ! / Ctrl+B | Unsubscribe | Ctrl+U |
| Lido / não lido | Shift+I / Shift+U | Mute | M |
| Todo | T | Ask AI / AI Assistant | Y / Ctrl+J |
| Command palette | Ctrl+K | Buscar | / |
| Enviar / enviar e done | Ctrl+Enter / Ctrl+Shift+Enter | Desfazer envio / ação | Ctrl+Z ou Z |
| Inbox / Todos / Done | G+I / G+O / G+E | Trocar conta | Alt+1–9 |
| Compartilhar / atribuir thread | Ctrl+Shift+S / Ctrl+Shift+Z | Ajuda | Shift+? |

**Missive** ([fonte](https://missiveapp.com/docs/advanced-features/shortcuts.md)). Todos os atalhos são customizáveis.
| Ação | Default | Gmail |
|---|---|---|
| Novo rascunho | ⌘/Ctrl+N | C |
| Buscar | ⌘/Ctrl+F | / |
| Command | ⌘/Ctrl+K | ⌘/Ctrl+K |
| Arquivar | Backspace | E ou Y |
| Lixeira | ⌘/Ctrl+Backspace | # |
| Label / mover | ⌘⇧L / ⌘⌥L | L / V |
| Snooze | ⌘⇧J | O |
| Atribuir / atribuir a mim | ⌘⇧K / ⌘D | H / Q |
| Responder / todos / encaminhar | ⌘R / ⌘⇧R / ⌘⇧F | R / ⇧R / F |
| Reenviar | ⌘⇧E | ⌘⇧E |
| Próx / ant | ↓ / ↑ | J / K |
| Inbox / Team inboxes / Assigned to me |: | G I / G U / G K |
| Nova tarefa | ⌘T | T |
| Focar comentário (chat interno) | ⌘⇧C | ⇧C |

**Proton Mail** (⚠️ lista oficial em imagem; dados do [DefKey](https://defkey.com/protonmail-shortcuts), 2022. **Confirmar.**)
| Ação | Tecla |
|---|---|
| Compor | C |
| Enviar | Ctrl+Enter |
| Salvar | Ctrl+S |
| Buscar | / |
| Command palette | Shift+Space |
| Inbox / Drafts / Sent / Starred / Archive / Spam / Trash | G I / G D / G S / G . / G A / G X / G T |
| Selecionar | X |
| Lido / não lido | R / U |
| Estrela | . |
| Arquivar / lixeira / spam / inbox | A / T / S / I |
| Próx / ant | J / K |
| Ajuda | ? |

---

## 4. Síntese: lacunas de mercado e requisitos recomendados

### 4.1 Lacunas (o que nenhum app entrega junto)

1. **Busca determinística, local e entre contas.** Quem depende do índice do servidor (New Outlook, Proton no mobile) ou do Spotlight (Apple Mail) falha justamente onde o usuário mais precisa. Ninguém combina índice local completo, cobertura de todas as contas e todas as pastas e resultado reprodutível.
2. **Caixa unificada com profundidade.** Quem é bom em velocidade e IA (Superhuman, Shortwave, Mimestream) é monoprovedor. Quem é multi-provedor (Spark, Canary, eM Client) sofre com estabilidade ou limita contas.
3. **Confiabilidade observável.** Nenhum app expõe de forma clara o estado de sincronização, o OAuth expirado ou a falha de envio.
4. **IA opcional de verdade.** Os usuários querem IA em busca, resumo e regras, com custo zero de performance quando está desligada.
5. **Triagem tipo Screener sem lock-in.** O conceito do HEY é amado, mas fica preso a um provedor sem IMAP.
6. **Regras poderosas com teste.** Faltam "run now", condições por assunto e corpo, ação por IA e simulação ("o que esta regra pegaria?").
7. **Follow-up confiável** baseado em "sem resposta na thread", e não em heurística.
8. **Triagem que funciona em qualquer cliente, mas com inteligência real.** O SaneBox prova a demanda (pastas no servidor, treino por arrastar), porém classifica só por remetente e cabeçalho, com latência de minutos e movendo a mensagem depois de entregue (seção 5.2).
9. **Engenharia, construção e jurídico (nicho de Victor).** Precisam de busca em anexos, histórico de anos e exportação para pastas de obra no SharePoint/Drive sem erro de caminho. A dor aparece literalmente no relato de um usuário de construção em r/Outlook.

### 4.2 Requisitos priorizados para um app novo

**P0: sem isto o app é abandonado**
1. **Multi-conta e multi-provedor:** Gmail API, Microsoft Graph, IMAP/SMTP e JMAP, com caixa unificada que inclui subpastas escolhidas.
2. **Motor de busca local:** índice full-text (por exemplo SQLite FTS5 ou Tantivy) cobrindo cabeçalhos, corpo e texto de anexos (PDF, DOCX, XLSX). Operadores no estilo Gmail (`from:`, `to:`, `has:attachment`, `before:`, `in:`), escopo de todas as contas por padrão e resultados determinísticos. Meta de latência: menos de 100 ms em 1 milhão de mensagens (objetivo de projeto, não benchmark verificado).
3. **Sincronização robusta:** fila de operações offline idempotente, reconciliação bidirecional (lido, flag, mover, excluir), renovação proativa de tokens OAuth, **painel de saúde por conta** e **alerta alto de falha de envio**.
4. **Teclado em primeiro lugar:** preset "Gmail" completo, command palette ⌘/Ctrl+K com o atalho ao lado de cada ação, atalhos 100% remapeáveis e presets Outlook e Apple Mail.
5. **Básicos que não podem faltar:** undo send com timer, send later, snooze, autocompletar de destinatários a partir do histórico, verificação ortográfica, reenviar ("send again") e ordenar e agrupar por remetente.
6. **Privacidade padrão:** bloquear conteúdo remoto, usar proxy de imagens, remover parâmetros de rastreio de links e não incluir tagline de marketing.

**P1: diferenciais que geram adoção**
7. **Triagem treinável por gesto** (mover para a pasta cria a regra), classificada **antes** da notificação, explicável e gravada como pasta ou label no servidor, para valer em outros clientes. Inclui quarentena reversível de 7 dias para bloqueios, Digest diário e pasta automática de enviados sem resposta.
7b. **Screener opcional** para remetentes novos (aceitar, bloquear ou mandar para Feed ou Papelada), por domínio e por assunto, funcionando sobre IMAP e Gmail.
8. **Motor de regras** com condições compostas (remetente, assunto, corpo, anexo, cabeçalho List-Id), ações (mover, label, snooze, encaminhar, webhook), **"executar agora"**, **pré-visualização de impacto** e regra por IA em linguagem natural, opcional.
9. **Follow-up por thread:** "lembre-me se ninguém responder em N dias", cancelado automaticamente quando chega resposta.
10. **Notificações seletivas:** VIP, label, thread e horário de silêncio, com o mesmo comportamento em todos os dispositivos.
11. **Central de inscrições:** agrupar newsletters por remetente, fazer unsubscribe em massa (List-Unsubscribe one-click) e manter uma faixa de leitura separada.
12. **IA opcional e local quando possível:** resumo, busca semântica e extração de tarefas. Quando desligada, nenhum processo ou elemento de UI fica ativo, conforme pedido explícito no Reddit.

**P2: expansão**
13. Calendário integrado: Google, Graph e CalDAV, com convite que permite definir lembrete na hora.
14. Colaboração: caixa compartilhada, atribuição, comentário interno e rascunho compartilhado, no modelo Missive/Spark Teams.
15. Exportação estruturada: salvar thread e anexos em pasta de projeto no SharePoint, Drive ou disco local com regra de nomenclatura e tratamento de caminho longo.
16. Acessibilidade WCAG: testes com NVDA, JAWS e VoiceOver e navegação 100% por teclado.
17. Sincronia de configurações entre dispositivos, criptografada.
18. Opcional e com aviso ético: rastreamento de abertura para quem envia, configurável por mensagem.

**Anti-requisitos** (o que os usuários punem): IA forçada; regressão de recursos sem paridade; lock-in de provedor; tagline de marketing no e-mail; suporte por bot sem resolução.

---

## 5. Aprofundamento: Fastmail e SaneBox

Os dois produtos se complementam e há parceria oficial entre eles. O Fastmail é **provedor e cliente**: hospeda o e-mail e oferece web e apps. O SaneBox é uma **camada de triagem no servidor**: não é cliente nem provedor, conecta-se à caixa existente e move mensagens entre pastas. Por isso funciona com qualquer app de e-mail.

### 5.1 Fastmail

**Como funciona tecnicamente**
- **Protocolos:**
  - JMAP, protocolo JSON sobre HTTP (RFC 8620, núcleo, e RFC 8621, mail). O Fastmail é o principal autor da especificação.
  - API pública com endpoint de sessão `https://api.fastmail.com/jmap/session`, autenticada com `Authorization: Bearer <API_TOKEN>` ([fastmail.com/dev](https://www.fastmail.com/dev/)).
  - IMAP, SMTP, CalDAV e CardDAV para clientes de terceiros.
  - Não suporta ManageSieve: as regras só podem ser editadas pela web ([Sieve FAQ](https://www.fastmail.help/hc/en-us/articles/360058753814-Sieve-frequently-asked-questions)).
  - O suporte à extensão JMAP for Sieve (RFC 9661) é **não verificado**.
- **Regras:** a interface "Filters & Rules" gera um script **Sieve** e permite inserir código Sieve próprio em blocos editáveis ("Edit custom Sieve code"; [Using Sieve](https://www.fastmail.help/hc/en-us/articles/1500000280481-Using-Sieve-scripts-in-Fastmail), [Filters & Rules](https://www.fastmail.help/hc/en-us/articles/1500000278122-Filters-Rules)). Limite de **1.000 regras por usuário** e **até 50 condições por regra** na interface ([Account limits](https://www.fastmail.help/hc/en-us/articles/1500000277382-Account-limits)).
- **Endereços:**
  - **Masked Email:** endereço aleatório por site, que pode ser criado via JMAP (`MaskedEmail/set`) e é usado pelas integrações com 1Password e Bitwarden.
  - Aliases: 600 por conta mais 15 por usuário ([Account limits](https://www.fastmail.help/hc/en-us/articles/1500000277382-Account-limits)).
  - Domínio próprio, catch-all e plus addressing.
  - O limite de Masked Emails existe, mas o número exato não aparece na página oficial. O valor de 1.000 citado no Reddit é **não verificado**.
- **Limites de mensagem:** até 70 MB por e-mail, o que na prática dá um anexo de cerca de 50 MB. Envio diário de 4.000 a 80.000 conforme o plano. Acima da cota de armazenamento, a mensagem recebida tem bounce temporário 4xx e não é perdida ([Account limits](https://www.fastmail.help/hc/en-us/articles/1500000277382-Account-limits)).
- **Ecossistema:** mail, contatos, calendário, notas e arquivos (Files) no mesmo produto, como mostram os atalhos globais `Shift+g` seguido de m, a, c, n ou f.

**Recursos (resumo)**
- Busca em todas as pastas por padrão.
- Snooze com predefinições (`b` seguido de 1 a 7).
- Pin, mute, labels ou pastas (modo Labels).
- Agendamento de envio (`Ctrl+Shift+Enter`).
- Desfazer até 10 ações.
- Bloqueio de imagens remotas (`Shift+l` exibe).
- Resposta automática de férias, citada como "a mais inteligente" no review de [Justin Harter](https://justinharter.com/an-actually-useful-review-of-proton-mail-vs-fastmail-vs-hey/).
- Calendário e contatos com padrões abertos.
- App desktop em **Electron** (casca do webmail), segundo [síntese da busca](https://www.kevinthetechguy.ca/p/kevins-picks-the-fastmail-desktop), não verificado na fonte oficial.
- Parceria e desconto no SaneBox ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1mvej65/sanebox_integration/)).

**Preços oficiais** ([fastmail.com/pricing](https://www.fastmail.com/pricing/), lido em 13/10/2026)

| Plano | Mensal | Anual | 24 meses | 36 meses | Armazenamento |
|---|---|---|---|---|---|
| Individual | US$ 6/mês | US$ 60 (US$ 5/mês) | US$ 114 | US$ 168 | 60 GB (50 mail + 10 arquivos) |
| Duo | US$ 10/mês | US$ 96 (US$ 8/mês) | US$ 182,40 | US$ 268,80 | 120 GB (60/pessoa) |
| Family (até 6) | US$ 14/mês | US$ 132 (US$ 11/mês) | US$ 250,60 | (nv) | (nv) |
| Business Basic / Standard / Professional | Professional: US$ 10/mês, US$ 108/ano | Basic e Standard aparecem na página, mas não consegui extrair os preços (nv) | | | |

**Atalhos (lista completa da fonte oficial)** ([fonte](https://www.fastmail.help/hc/en-us/articles/360058753534-Keyboard-shortcuts)). Ativar em Settings › Display options › Accessibility. `?` ou Ctrl duas vezes abre a ajuda.

| Contexto | Atalho | Ação |
|---|---|---|
| Global | Shift+g m / a / c / n / f / s / ? | Mail / Contatos / Calendário / Notas / Arquivos / Configurações / Ajuda |
| Global | Shift+f; Shift+f l; Shift+f a; Shift+f 1..n | Menu de usuário; logout; logar outro usuário; trocar usuário |
| Global | z ou Ctrl+z / Ctrl+y (Win) ou Ctrl+Shift+z | Desfazer (até 10) / refazer |
| Mail | c | Compor |
| Mail | Alt+Shift+C / Alt+Shift+R / Alt+Shift+A | Compor / responder ao remetente / responder a todos em janela pop-out |
| Mail | g | Ir para pasta (digitar o nome) |
| Mail | Space / Shift+Space | Página abaixo / acima |
| Mail | / | Buscar (todas as pastas; Alt+Enter limita à pasta, Shift+Enter força todas) |
| Mail | Esc duas vezes | Tirar o foco do campo |
| Mail | Ctrl+Shift+i (⌘ no Mac) | Alternar a barra lateral |
| Snooze | b, depois 1 / 2 / 3 / 4 / 5 / 6 / 7 | +3 h / 18h hoje / amanhã 8h / sábado 8h / segunda 8h / último personalizado / escolher data |
| Lista | u | Atualizar |
| Lista | j / k | Próxima / anterior |
| Lista | o ou Enter | Abrir |
| Lista | x / Shift+x | Selecionar / selecionar intervalo |
| Lista | s | Fixar (pin) |
| Lista | * a ou ' a / * n ou ' n | Selecionar tudo / nada |
| Lista | > / < | Expandir / recolher pastas |
| Conversa | d | Lixeira |
| Conversa | # ou d ou ⌘Delete / Delete (na Lixeira ou Spam) | Excluir permanentemente |
| Conversa | m ou v | Mover |
| Conversa | Alt + arrastar | Copiar para pasta |
| Conversa | y | Arquivar (no modo Labels, remove a label) |
| Conversa | h | Remover a label Inbox |
| Conversa | ! | Spam |
| Conversa | Shift+i ou . r / Shift+u ou . u | Marcar lido / não lido |
| Conversa | . p / . n | Fixar / desafixar |
| Conversa | % | Excluir para sempre |
| Conversa | l | Menu de labels |
| Conversa | Shift+m / Alt+Shift+m | Silenciar / reativar |
| Leitura | j / k | Abrir próxima / anterior |
| Leitura | u | Voltar à lista |
| Leitura | [ / ] | Arquivar e abrir a próxima / a anterior |
| Leitura | r / a / Alt+r | Responder / todos / só o remetente (ignora Reply-To de lista) |
| Leitura | Enter | Resposta padrão |
| Leitura | f | Encaminhar |
| Leitura | Shift+l | Exibir imagens bloqueadas |
| Leitura | Shift+e / Alt+Shift+e | Expandir / recolher todas |
| Leitura | n / p | Focar a próxima / anterior mensagem da conversa |
| Leitura | e | Expandir a mensagem focada |
| Leitura | ; | Menu de ações |
| Leitura | : | Detalhes da mensagem |
| Leitura | " | Mostrar ou ocultar citações |
| Compor | Ctrl+Enter / Ctrl+Shift+Enter | Enviar / agendar envio |
| Compor | Ctrl+s / Ctrl+Shift+Alt+Backspace | Salvar rascunho / descartar |
| Compor | Ctrl+Shift+c / Ctrl+Shift+b | Mostrar Cc / Bcc |
| Compor | Ctrl+m | Reformatar texto puro |
| Compor | Ctrl+b / i / u / k / d | Negrito / itálico / sublinhado / link / código |
| Compor | Ctrl+Shift+5 / 6 / 7 / 8 / 9 | Subscrito / sobrescrito / tachado / lista com marcadores / lista numerada |
| Compor | Tab / Shift+Tab (no início do item) | Indentar / desindentar lista |
| Compor | Ctrl+[ / Ctrl+] | Diminuir / aumentar nível de citação |
| Contatos | n, j, k, x, Shift+x, s, e, Ctrl+s, Esc, #, r, / | Novo, próximo, anterior, selecionar, intervalo, fixar, editar, salvar, descartar, excluir, grupos, buscar |
| Calendário | n, v, d, e, w, m, a, o, g, t, j, k, Alt+j, Alt+k, Ctrl+s, Esc, / | Novo evento, menu, dia, 3 dias, semana, mês, agenda, fuso, ir para data, hoje, próximo, anterior, avanço lento, recuo lento, salvar, fechar, buscar |
| Notas | n, j, k, s, e, Ctrl+s, Esc duas vezes, #, / | Nova, próxima, anterior, fixar, editar, salvar, descartar, excluir, buscar |
| Arquivos | /, n, p, j, o, k, x, e, # ou d | Buscar, nova pasta, upload, próximo, abrir, anterior, selecionar, anexar a e-mail, excluir |

Observação: segundo a síntese da busca, os atalhos do Fastmail **não são remapeáveis**. Não confirmei isso na fonte oficial (nv).

**O que amam (Reddit)**
- Masked Email, domínio próprio, catch-all, ausência de rastreadores e uma interface "snappy": "Unlimited masked emails / No trackers / Snappy interface (hence the name) / You can use your own domain" ([r/fastmail](https://www.reddit.com/r/fastmail/comments/17s4jdl/why_did_you_choose_fastmail/)).
- O modelo de negócio: "I wanted a service where the business model is NOT to sell every piece of information they can collect about me" (mesma thread).
- Feeds montados com regras: "In Fastmail, I have built Feeds that work exactly how I want" (mesma thread). É o conceito do HEY reproduzido com regras abertas.
- Criar endereços sem cadastro prévio: "you don't have to create alias at all… when you have catch-all, it just use same email when you reply" ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1ibpvp9/switching_email_providers/)).
- Masked Email: "Masked emails are what ultimately sold me on the service" ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1pacau4/if_you_havent_used_masked_emails_yet_do_it_its/)).
- Confiabilidade: "absolutely rock solid" ([r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/urtgkb/fastmail_to_hey_to_fastmail_to_hey_to_fastmail/)).

**O que reclamam**
- **Masked Email:** só gera prefixo aleatório, não aceita endereço customizado nem importação, a criação no mobile é ruim e a integração com 1Password falha "3/4 of the time works" ([r/fastmail](https://www.reddit.com/r/fastmail/comments/12ir6qb/the_masked_email_fastmail_integration_isnt_great/), [r/fastmail](https://www.reddit.com/r/fastmail/comments/1pacau4/if_you_havent_used_masked_emails_yet_do_it_its/)).
- **Lock-in:** quem usa o domínio do Fastmail nas máscaras fica preso; a recomendação é usar domínio próprio ([r/fastmail](https://www.reddit.com/r/fastmail/comments/wotrz8/what_happens_to_masked_emails_if_you_move_from/)).
- **Spam:** "Not spam" não impede que a mensagem volte para o spam ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1ttp7a6/marking_an_email_as_not_spam_does_not_work_they/)).
- **Busca:** não destaca os termos no corpo da mensagem ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1vy8m0e/search_terms_not_highlighting_in_body_of_email/)).
- **Desktop e mobile:** o app desktop é uma casca do webmail com menos recursos do que Thunderbird ou Apple Mail ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1w2nsk7/mail_client_differences_mobile_as_compared_to/)).
- **Personalização visual limitada** e interface "boring", com cara de e-mail de trabalho ([Justin Harter](https://justinharter.com/an-actually-useful-review-of-proton-mail-vs-fastmail-vs-hey/); [r/HeyEmail](https://www.reddit.com/r/HeyEmail/comments/urtgkb/fastmail_to_hey_to_fastmail_to_hey_to_fastmail/)).
- Segundo a síntese da busca, faltam caixa unificada padrão, atalhos customizáveis e um painel de composição persistente como o do Gmail ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1vhayvj/just_switched_to_fastmail_after_gmail_feature_deprecation/)). Trecho não lido na íntegra (nv).

### 5.2 SaneBox

**Como funciona tecnicamente**
- **Arquitetura:** o SaneBox "doesn't send or receive your email". Ele mantém uma conexão com o servidor do usuário (IMAP, Gmail ou M365 via OAuth, Exchange e ActiveSync), observa a Inbox e **pede ao servidor que mova** cada mensagem para uma pasta `@Sane…`. Toda a organização é feita com **pastas no servidor**, por isso aparece em qualquer cliente: web, Apple Mail, Outlook ou celular ([FAQ](https://www.sanebox.com/faq)).
- **Classificação:** analisa **só os cabeçalhos** e o **comportamento histórico** do usuário: "which emails you open, which you respond to, how quickly you open an email, how quickly you respond, how often, how far back your relationship goes" ([FAQ](https://www.sanebox.com/faq)). Também usa a lista de contatos para identificar remetentes importantes ([Permissions](https://www.sanebox.com/help/36-permissions-needed-for-sanebox-to-work)).
- **Treino:** o usuário treina **arrastando a mensagem** para uma pasta Sane. A regra vale para o **remetente**, e opcionalmente para o domínio inteiro pelo Digest. Há também filtros por assunto, com coringa de 5 underscores, e por domínio ([release notes](https://www.sanebox.com/release-notes)).
- **Privacidade:** "SaneBox does its magic without ever reading the body of the email. It only analyzes data in the header" ([FAQ](https://www.sanebox.com/faq)).
  - As credenciais são cifradas com chave pública e as chaves ficam em HSM.
  - Os servidores de processamento não aceitam conexões da internet: o acesso é feito por VPN e bastion, com log auditado ([Security](https://www.sanebox.com/security)).
  - O SaneBox segue a política Limited Use das APIs do Google.
  - **Exceções declaradas,** em que o conteúdo é acessado temporariamente e não é armazenado:
    - SaneAttachments (envio para Dropbox ou Drive);
    - SaneFwd (reencaminhamento);
    - lembretes criados por endereço, como `9am@sanebox.com`;
    - snooze em modo "Top of Inbox", que lê o assunto.
  - Desligando essas opções, o acesso fica limitado aos cabeçalhos ([Privacy](https://www.sanebox.com/help/412-privacy-and-security-i-don-t-want-sanebox-reading-my-mail), [Zendesk](https://sanebox.zendesk.com/hc/en-us/articles/203094286-Privacy-Security-Can-SaneBox-read-my-email)).
  - O próprio SaneBox admite que os escopos OAuth concedidos são **mais amplos** do que o necessário por exigência dos provedores ([Permissions](https://www.sanebox.com/help/36-permissions-needed-for-sanebox-to-work)).
  - Um usuário relata que o Gmail exige reautorizar o acesso a cada 6 meses ([r/sanebox](https://www.reddit.com/r/sanebox/comments/1h61go3/my_sanebox_review_anyone_else_using_sanebox_and/)).
- **Latência:** ativar ou desativar um recurso leva de 5 a 30 minutos ([What is a feature](https://www.sanebox.com/help/138-what-is-a-feature)). Toda noite, entre 23h e 5h, o SaneBox processa os e-mails antigos da Inbox ([release notes](https://www.sanebox.com/release-notes)).
- **Apps:** iOS (Digest, push e sincronização de contatos), Android (anunciado nas release notes de 08/09/2026) e app avulso "SaneNoReply" para iOS. A síntese da busca menciona IA que resume threads e redige respostas no tom do usuário, mas não confirmei isso numa página oficial (nv).

**Recursos** (fontes: [Getting Started](https://www.sanebox.com/help/13), [Folder choices](https://sanebox.zendesk.com/hc/en-us/articles/203095496-Beyond-SaneLater-More-Sane-Folder-Choices), [Lunch plan](https://www.sanebox.com/help/207-what-do-i-get-with-the-lunch-subscription), [release notes](https://www.sanebox.com/release-notes))

| Recurso | O que faz |
|---|---|
| @SaneLater | Tira da Inbox o que é pouco importante. Pode ser desligado e renomeado. |
| @SaneNews | Recebe newsletters e boletins. |
| @SaneCC | Recebe as mensagens em que o usuário está só em cópia. |
| @SaneNotSpam | Resgata o que foi parar no spam por engano. |
| @SaneArchive | Arquivamento automático. |
| @SaneBlackHole | Treina o remetente para ir à Lixeira, com 7 dias de revisão. A IA sugere candidatos. **É filtro por remetente, não aprendizado de conteúdo.** |
| SaneSnooze (@SaneTomorrow, @SaneNextWeek, @SaneTonight, @SaneSaturday, @SaneNextMonth, pastas customizadas, inclusive com data fixa) | Snooze por pasta: arrastar a mensagem e ela volta depois. Opcionalmente envia auto-resposta avisando o remetente do atraso. |
| SaneReminders | Avisa se não houver resposta até um prazo, ou lembra o próprio usuário. Funciona por Cc/Bcc para endereços como `3days@`, `monday@`, `dec.31@`, `daily@`, `monthly@` e `yearly@sanebox.com`, ou pelo painel. A cota mensal depende do plano. |
| @SaneNoReplies | Reúne enviados das últimas 4 semanas sem resposta e pode ignorar convites de calendário. |
| SaneDoNotDisturb | Pausa a Inbox em horários agendados (dias úteis e fins de semana separados), com exceção por domínio e Digest no fim. |
| Digest | Resumo diário do que não foi lido nas pastas Sane, com ações de treinar, mover uma vez, snooze, arquivar e lixeira. Marca remetentes novos com um ponto verde. |
| SaneAttachments | Move anexos para Dropbox, Drive, Box etc., com filtro de tamanho (1 KB a 9 MB) e de tipo. |
| SaneFwd | Reencaminha mensagens para serviços como rastreadores de encomendas. |
| DIY Training Folders | Pastas customizadas treináveis, por exemplo "Family", com limpeza automática depois de N dias. |
| Email Deep Clean | Varre o histórico, mostra remetentes volumosos ou antigos e manda em massa para a Lixeira. |
| Filtros por assunto e domínio | Regras explícitas com prévia de quais mensagens seriam afetadas. |

**Preços**
- A página oficial `sanebox.com/pricing` é renderizada por JavaScript e não pôde ser lida. Os valores abaixo vêm de **duas fontes secundárias concordantes**: [thisandthat](https://www.thisandthat.chat/blog/sanebox-pricing/), lida na página oficial em 06/08/2026, e [usecarly](https://www.usecarly.com/blog/sanebox-review/), com dados de 28/09/2026.
- Conferido na fonte oficial: o plano Lunch tem 2 contas e 6 recursos ([help/207](https://www.sanebox.com/help/207-what-do-i-get-with-the-lunch-subscription)), e há 25% de desconto para educação, ONG e governo ([página de signup](https://www.sanebox.com/signup/2a13f2a3f9)).

| Plano | Mensal | Anual | 2 anos | Contas | Recursos |
|---|---|---|---|---|---|
| Snack | US$ 9,49 | US$ 65 | US$ 109 | 1 | 2 à escolha |
| Lunch | US$ 15,99 | US$ 109 | US$ 179 | 2 | 6 por conta |
| Dinner | US$ 42,99 | US$ 319 | US$ 529 | 4 | Todos, mais suporte por telefone |

- O preço subiu cerca de 36% em 14 meses: o Snack mensal custava US$ 7 em jul/2025 (usecarly).
- Há divergência no período de teste: as fontes secundárias falam em 7 dias e a página oficial de signup fala em 14 dias (nv).
- Plano Business só sob cotação.

**Atalhos**
- O SaneBox **não tem cliente de leitura** e, portanto, não tem atalhos próprios de e-mail. O artigo oficial "[Manage Your Email With Keyboard Shortcuts](https://sanebox.zendesk.com/hc/en-us/articles/215720557-Manage-Your-Email-With-Keyboard-Shortcuts)" só remete às listas de atalhos de Gmail, Outlook e iCloud, em imagens.
- Na prática, o "atalho" do SaneBox é o **atalho de mover para pasta** do cliente usado: `v` no Gmail, `m`/`v` no Fastmail, `Ctrl+Shift+V` no Outlook classic e `⌃⌘M` no Apple Mail.

**O que amam (Reddit)**
- Alívio de ansiedade: "adding Sanebox stopped me getting anxiety attacks every time I checked my messages" ([r/sanebox](https://www.reddit.com/r/sanebox/comments/1h61go3/my_sanebox_review_anyone_else_using_sanebox_and/)).
- Funciona com qualquer cliente e de forma invisível: "when you are in Fastmail you do not see anything except for the results of the sorting… it's just a matter of moving the email to where you want it to go" ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1mvej65/sanebox_integration/)).
- Treino e snooze por arrastar para pasta: "blocking email senders by dragging to another folder, and snoozing emails by dragging to yet another folder" ([r/sysadmin](https://www.reddit.com/r/sysadmin/comments/qtm5uq/anyone_using_sanebox/)).
- Follow-up por Bcc: "Any email that I'm asking for an action to be taken gets a bcc contact added… super useful to make sure no email message that needs something to occur gets followed-up on" (mesma thread).

**O que reclamam**
- **Classificação "burra", só por remetente:** "I dragged a notification email into the 'SaneLater' folder… and all of a sudden everything from the server goes in that folder"; "The Sane Black Hole especially was massively disappointing, I was expecting some form of learning. Not just filtering by sender" ([MPU Talk](https://talk.macpowerusers.com/t/some-long-thoughts-on-emails-filtering-and-sanebox/28819), fórum fora do Reddit).
- **Treino trabalhoso:** "the review asks me to review about 50-100 emails a day. Which seems kinda counter productive"; "how's it any different than me creating a filter in Gmail…?" ([r/sanebox](https://www.reddit.com/r/sanebox/comments/1l9ydfa/how_do_i_train_sanebox_most_efficiently/)).
- **Lentidão e excesso de e-mails do próprio serviço:** "it can be super slow… Sanebox itself sends far too many emails for a service that's supposedly all about clutter-free inboxes" ([r/sanebox](https://www.reddit.com/r/sanebox/comments/1h61go3/my_sanebox_review_anyone_else_using_sanebox_and/)).
- **Pastas duplicadas por conta:** "a shame that there are separate @sanenews and @sanelater folders for each email address" (mesma thread).
- **Lembrete que perde o anexo:** o lembrete chega como um e-mail novo, só com o texto, sem o PDF original ([MPU Talk](https://talk.macpowerusers.com/t/some-long-thoughts-on-emails-filtering-and-sanebox/28819)).
- **Movimentação depois da entrega:** a mensagem importante chega e depois some para uma pasta, o que gera desconfiança ([r/businessemail](https://www.reddit.com/r/businessemail/comments/1vmutnt/sanebox_alternatives/), [r/emailprivacy](https://www.reddit.com/r/emailprivacy/comments/1vmi231/sanebox_alternatives/); lidas só pelo resumo da busca).
- **Custo:** compensa só para quem recebe muito e-mail: "decided I didn't get nearly enough email daily for it to be worth the cost" ([r/fastmail](https://www.reddit.com/r/fastmail/comments/1mvej65/sanebox_integration/)). Há também resistência a "AI in my mailbox" na mesma thread.

### 5.3 O que um app novo deve copiar ou evitar

| | Fastmail | SaneBox |
|---|---|---|
| **Copiar** | JMAP como protocolo interno ou para sincronização: estado incremental (`/changes`) e push, muito mais eficiente que IMAP IDLE. Regras com saída em **Sieve legível e editável**, que preserva a portabilidade. Masked Email integrado ao fluxo de cadastro. Snooze com predefinições numeradas (`b` seguido de 1 a 7). Desfazer múltiplo (10 níveis). `[` e `]` para "arquivar e próxima". `Alt+r` para responder só ao remetente, ignorando Reply-To de lista. Busca em todas as pastas por padrão, com modificador para limitar ao escopo atual. | **Organizar via pastas no servidor**, o que dá compatibilidade com qualquer cliente e com o celular. **Treinar por arrastar:** o próprio gesto de mover cria a regra. Prévia do impacto de filtros. BlackHole com **7 dias de quarentena**, que torna o erro reversível. Digest diário com ações em lote e destaque para **remetentes novos**. NoReplies automático (enviados sem resposta, ignorando convites). Do Not Disturb agendado com exceções. Auto-resposta ao adiar ("respondo na segunda"). Modelo de privacidade **só com cabeçalhos**, explicado em linguagem clara. |
| **Evitar** | Masked Email só aleatório e preso ao domínio do provedor (permitir prefixo customizado, domínio próprio e exportação). "Not spam" que não aprende. Desktop que é só uma casca do webmail. Atalhos fixos, sem remapeamento. Busca sem destaque de termos. | Classificação **só por remetente**, sem distinguir assunto, tipo nem conteúdo, como no caso do servidor que envia notificações diferentes pelo mesmo endereço. Treino que exige revisar de 50 a 100 itens por dia. Latência de minutos. **Mover a mensagem depois de entregue**: o ideal é classificar antes de notificar. Gerar e-mails do próprio serviço. Lembrete que descarta anexos. Limitar recursos por plano ("escolha 2 de 10"). Escopos OAuth amplos sem explicação. |

**Implicação de arquitetura:** o SaneBox mostra que há mercado para **triagem independente do cliente**, mas a classificação só por cabeçalho e por remetente é o seu teto. Um app novo que controla o cliente pode fazer melhor:
1. Classificar **localmente** com cabeçalhos, conteúdo e comportamento, sem enviar o corpo a terceiros.
2. Aplicar a decisão **antes de notificar**.
3. Gravar o resultado como pasta ou label no servidor, para que funcione também em outros clientes.
4. Tornar cada decisão **explicável** ("movido porque…") e reversível com um gesto.

---

## Anexo A: Threads e fontes consultadas

**Reddit (36):**
- r/Outlook: 1wjphac, 1ukmlka, 1tkpczw
- r/Office365: 1jwl77g, 1ni74hj
- r/sysadmin: 1te6nt1
- r/SparkMail: 1r0iqbj, 1v1mvem, 1m6ol3q, 1tysezy, 1s5p95b
- r/GMail: 1kk4hrn, 1v49f5j, 1h5rr5r, 1ug9yds, 1w5l4yp
- r/HeyEmail: 1sv2jst, urtgkb, 16ygopo, 1t3l5qh
- r/SuperhumanEmail: 1io7tcf, 1htix3s, 1evtsd8
- r/Missive: 1rxwdy8
- r/Windows11: 1qn2vwa
- r/software: 1n9ffbk
- r/ProtonMail: 1srolep, 1qmtlzb, 1vej4nv, 1e3zxq1, 1wdm89x, llsmd1
- r/tutanota: 1w4k7bk, 1e8no9o
- r/MacOS: 1wl2s5c
- Complementares, lidas só pelo resumo do índice: r/applehelp 1ejnevd e 1wnh32k, r/ios 1i4k65h, r/androidapps 1r2eozb, r/Android 1uu0xxm, r/macapps 17mfpem, r/selfhosted 1njclqs, r/productivity 1gmv24u, r/Blind 1wrlkq3 e 1jljnir, r/BlindAndFine 1wtb99w, r/iphone 1dzw2j8

**Outros:** Gmail Community (3 threads sobre ordenar por remetente), justinharter.com (review), Windows Latest, Microsoft 365 Message Center (RM564609, RM570441), Notion Help, TechCrunch e as páginas de preço citadas na seção 2.

**Fontes que falharam:**
- sanebox.com/pricing: renderizada por JS; preços tirados de fontes secundárias
- O artigo de atalhos do SaneBox contém só imagens
- reddit.com e old.reddit.com (JSON): 403
- api.pullpush.io: 429
- support.mozilla.org (Thunderbird): desafio JavaScript
- proton.me/support/keyboard-shortcuts: lista só em imagem
- sparkmailapp.com/help/general/keyboard-shortcuts: 404 (a URL alternativa funcionou)
- A primeira URL de atalhos do Fastmail redirecionou para outra página (a URL correta funcionou)
- A página "Speed up with shortcuts" do Superhuman não traz a lista (usei o PDF oficial)
