# User Problems and Complaints: Premium, Indie and AI-First Email Clients (2023-2026)

Research date: 2026-10-11. About 20 search/fetch calls. Many pricing sources are third-party aggregators that disagree with each other; these conflicts are flagged inline. Tags used: [PRICE], [M365] = Microsoft 365/Outlook support, [PERF] = native vs Electron, [PRIV] = privacy, [AI] = AI quality, [LOCK] = lock-in, [CAL] = calendar, [SYNC] = reliability, [DEAD] = abandoned/acquired, [TEAM] = team features.

## For each app: top praises, top complaints, pricing, platforms, account types (especially Microsoft 365/Exchange)

### Takeaway
Two problems come up again and again. First, the best-loved AI clients and the most polished native ones are Gmail-only: Mimestream, Shortwave, Notion Mail (now shut down), and Zero at launch was Gmail-first. Second, the clients that do support Microsoft 365 are either expensive (Superhuman at $25-40/month), Electron or web wrappers (Spark 3, Proton, Missive), or carry privacy or reliability doubts (Spark, Edison, Canary). Users mostly praise speed and keyboard flow (Superhuman), native feel (Mimestream), and AI that knows your whole inbox (Shortwave). They mostly complain about subscription cost, being Gmail-only, Electron bloat, and server-side processing of their mail.

### Cited Findings

**Superhuman (now part of Grammarly's "Superhuman" suite)**
- Paid, keyboard-shortcut-centric client founded 2014 by Rahul Vohra. Priced at $30/month, with a $10/month student tier. Gmail-only at first; Outlook integration added May 2022. AI instant-reply drafts announced Feb 2024 — [Wikipedia](https://en.wikipedia.org/wiki/Superhuman_(email_client))
- [PRICE] 2026 plans: Starter $30/month ($25 annual), Business $40/month (~$33 annual), plus custom Enterprise. No free plan, trial only — [Costbench](https://costbench.com/software/ai-productivity/superhuman/); [Usecarly](https://www.usecarly.com/blog/superhuman-pricing/); [Morgen](https://www.morgen.so/blog-posts/superhuman-pricing). Morgen also lists a separate "Superhuman Suite" with different Free/Pro/Business tiers, so pricing is confusing even to reviewers.
- [AI][PRICE] Business tier adds Auto Drafts in your voice, Ask AI over the whole inbox, custom auto labels, and HubSpot/Salesforce integration. One CRM review says HubSpot, Salesforce and Pipedrive are locked behind the $40 tier — [Morgen](https://www.morgen.so/blog-posts/superhuman-pricing); [Get-Alfred](https://get-alfred.ai/blog/superhuman-pricing)
- Reviews have questioned the price and the hype — [Wikipedia](https://en.wikipedia.org/wiki/Superhuman_(email_client))
- G2 comparison summary says Superhuman has higher quality of support than Shortwave — [G2](https://www.g2.com/compare/shortwave-communications-inc-shortwave-vs-superhuman-mail)
- [DEAD/acquired] Grammarly announced the acquisition in July 2025, price undisclosed. Superhuman's last valuation was $825M (2021), with an estimated ~$35M ARR — [Vestbee](https://vestbee.com/blog/articles/grammarly-acquires-superhuman); [Sacra](https://sacra.com/research/why-grammarly-bought-superhuman/). Grammarly's CEO said "the Superhuman product, team, and brand will continue" — [Implicator](https://www.implicator.ai/grammarly-acquires-superhuman-to-anchor-its-ai-productivity-ambitions/)
- In Oct 2025 the parent company was renamed Superhuman (Grammarly + Coda + Superhuman Mail + the "Superhuman Go" agent). Reported launch pricing: Pro $12/month, Business $33/month, with Business including Superhuman Mail — [TechRadar](https://techradar.com/ai-platforms-assistants/grammarly-has-rebranded-as-superhuman-launching-a-new-ai-assistant-that-works-across-100-apps); [AlternativeTo](https://alternativeto.net/news/2025/10/grammarly-s-parent-company-rebrands-as-superhuman-and-launches-a-new-ai-assistant). One source claims the rebrand was quietly reversed; this is uncorroborated — [Ainauten](https://news.ainauten.com/en/story/grammarlys-sloppelganger-saga)
- A class action was filed in March 2026 after Grammarly's "Expert Review" feature generated feedback that appeared to come from real writers (Stephen King, Kara Swisher) without their permission. This is a trust hit to the parent brand — [Wikipedia](https://en.wikipedia.org/wiki/Superhuman_(email_client))

**Spark (Readdle)**
- [PRICE] Premium is $7.99/month or $59.99/year in the US, €8.99/€69.99 in the EU — [App Store US](https://apps.apple.com/us/app/email-spark-by-readdle/id997102246); [Layer3labs review](https://www.layer3labs.io/guides/spark-email-review)
- [M365] Supports Gmail, Outlook, iCloud, Exchange and IMAP — [Layer3labs](https://www.layer3labs.io/guides/spark-email-review)
- [AI] AI compose, reply and summaries, built on OpenAI GPT — [Clean.email](https://clean.email/blog/ai-for-work/spark-mail-ai-review)
- [TEAM] Premium includes shared inboxes (assign, track, deadlines), shared templates and secure links — [App Store](https://apps.apple.com/us/app/email-spark-by-readdle/id997102246)
- [PERF] The 2022 move to Electron with Spark Desktop: "The app size and average RAM consumption has doubled". Another user called it "such a massive downgrade" (sidebar won't stay open, no preview pane, no separate windows). Readdle's Head of Spark conceded Electron "might be a bit slower than native" — [Michael Tsai blog](https://mjtsai.com/blog/2022/10/04/spark-switches-to-electron-and-subscriptions/)
- [PRICE] Subscription backlash at the same time: "Subscription is a deal breaker". Users objected to paying to remove the "Sent with Spark" signature ad, which Readdle later removed for Premium — [Michael Tsai blog](https://mjtsai.com/blog/2022/10/04/spark-switches-to-electron-and-subscriptions/)
- [PERF] A Windows user reported a 30+ second startup for Spark Desktop 3.8.3 (possibly antivirus-related) — [Bitdefender community](https://community.bitdefender.com/en/discussion/97207/bitdefender-causing-long-spark-desktop-startup-times). Hook users complain the Electron app lacks automation/linking — [Hook forum](https://discourse.hookproductivity.com/t/spark-desktop-electron-app-lacks-automation-for-linking/5763)
- [PRIV] Spark stores account access tokens on its servers to power push and send-later, and users can't turn the server component off. By contrast, Airmail and Canary let users disable it — [MacPowerUsers](https://talk.macpowerusers.com/t/spark-stores-email-account-credentials-on-their-servers/20388). Older report (Dutch) says the servers fetched headers and parts of message text for push notifications — [iCulture](https://www.iculture.nl/nieuws/spark-privacy-mail-platte-tekst/); [TidBITS](https://talk.tidbits.com/t/what-do-you-think-about-spark-by-readdle-security/10398)
- [SYNC] A long-time Premium subscriber (2023, Trustpilot) said the app went "sharply downhill", citing scheduled-send bugs and a messy redesign — [Trustpilot via search](https://fr-be.trustpilot.com/review/readdle.com). App Store reviews average about 4.6 stars across 3,200+ reviews, with recurring device-sync complaints — [Clean.email](https://clean.email/blog/ai-for-work/spark-mail-ai-review)

**Airmail**
- [PRICE] In 2019 it switched without warning from a paid app to a subscription. Previously paid features (notifications, multiple accounts) were cut off, which caused anger and claims of App Store guideline violations — [iMore](https://www.imore.com/ios-app-airmail-unannounced-switch-subscription-based-pricing-angers-users); [The Sweet Setup](https://thesweetsetup.com/airmail-switches-to-subscription-based-pricing/)
- [DEAD][SYNC] Reviewers report no updates for 6-9 months, folders vanishing after sleep, and missing or resurfacing messages. One calls support "abysmal" — [Trustpilot DE](https://de.trustpilot.com/review/airmailapp.com); [MacRumors](https://forums.macrumors.com/threads/airmail.2246739); [MacPowerUsers](https://talk.macpowerusers.com/t/airmail-subscription/12946?page=2)
- Name on the App Store is still "Airmail - Gmail Outlook Mail" (it supports multiple providers, M365 included) — [App Store](https://apps.apple.com/app/airmail-gmail-outlook-mail/id993160329)

**Canary Mail**
- Praise: Mac/iOS design, multi-account handling, built-in encryption (PGP) — [Trustpilot](https://ca.trustpilot.com/review/canarymail.io); [Business Today 2023](https://businesstoday.in/technology/reviews/story/canary-mail-review-a-powerful-ai-driven-email-assistant-398162-2023-09-13)
- [SYNC] "They try to fix bugs and new appears, it's at time totally unusable". Reviewers report slow message display, Windows/iOS bugs, and Android corrupting attachments — [Trustpilot](https://ca.trustpilot.com/review/canarymail.io)
- [AI] AI was called "more a gimmick", and Product Hunt reports an uneven AI experience with missing basic controls — [Trustpilot](https://ca.trustpilot.com/review/canarymail.io); [Product Hunt](https://producthunt.com/posts/canary-mail-3)
- [PRICE] Called "not worth the feature and stability", with slow or unreachable support and a refused refund — [Trustpilot](https://ca.trustpilot.com/review/canarymail.io). Pricing is inconsistent: Pro "from $20/year" (2023) vs Capterra "from $3/user/month", with a free version — [Business Today](https://businesstoday.in/technology/reviews/story/canary-mail-review-a-powerful-ai-driven-email-assistant-398162-2023-09-13); [Capterra](https://www.capterra.com/p/199141/Canary-Mail/alternatives/)

**Mimestream**
- Praise: truly native Mac app built in SwiftUI/Combine, universal binary. Mail "remains on the Gmail servers" — [Mimestream FAQ](https://mimestream.com/faqs). Widely reviewed as "a great, reliable Gmail app for the Mac" — [The Sweet Setup](https://thesweetsetup.com/mimestream-is-a-great-reliable-gmail-app-for-the-mac/); [TidBITS](https://talk.tidbits.com/t/why-i-use-mimestream-for-gmail/22280/19)
- [M365] Gmail only. Microsoft 365/Outlook, IMAP and JMAP are "planned", with users told to upvote on the roadmap. Mac only (macOS 12+); iOS is "in development" — [Mimestream FAQ](https://mimestream.com/faqs); [Supported Accounts](https://mimestream.com/help/user-guide/supported-accounts)
- [PRICE] $49.99/year or $4.99/month after a 14-day trial (per an older review; not verified on the official page) — [Kowatek](https://blog.kowatek.com/?p=29531)

**Shortwave**
- [AI] The AI is praised, especially for "interpreting past emails in a personalized manner" — [G2](https://www.g2.com/compare/shortwave-communications-inc-shortwave-vs-superhuman-mail)
- [M365] Gmail only. It sits on top of Gmail, and Outlook/iCloud are excluded — [Tooliverse](https://tooliverse.ai/tools/shortwave); [aitoolsatlas](https://aitoolsatlas.ai/tools/shortwave/review)
- [PRICE] Sources conflict. One lists Pro at $14/seat/month and Business at $24 (annual) — [Woodpecker](https://woodpecker.co/blog/?p=43721). Another lists ~$9 Personal and ~$29 Business — [thisandthat](https://www.thisandthat.chat/blog/shortwave-pricing/). Some users find it expensive for personal use — [aitoolsatlas](https://aitoolsatlas.ai/tools/shortwave/review)

**Notion Mail (SHUT DOWN 22 Sep 2026)**
- Praise: clean, calm design; custom "Views" like filtered Notion databases; block editor and slash commands; snippets with placeholders — [eesel (competitor, biased)](https://www.eesel.ai/blog/notion-mail-reviews); [Tom's Guide](https://www.tomsguide.com/computing/email/notion-mail-is-here-and-its-got-big-plans-for-your-inbox)
- [M365] Gmail/Google Workspace only, with "no support for Microsoft Outlook, custom domains, or any other email providers". Reviewers called this an "immediate dealbreaker for businesses on Microsoft 365" — [Clean.email](https://clean.email/blog/email-clients/notion-mail-review); [eesel](https://www.eesel.ai/blog/notion-mail-overview)
- Complaints: views have to be built by hand ("It's all on you"). AI is behind a paid plan and its drafts are generic. Notion integration is shallow (an email can't become a task or ticket). No shared inbox and no unified inbox. It turned Skiff's E2EE technology into a Gmail wrapper and dropped Skiff's privacy features — [eesel](https://www.eesel.ai/blog/notion-mail-reviews)
- Pricing: client free; full AI requires Business at $20/member/month — [eesel](https://www.eesel.ai/blog/notion-mail-reviews)

**HEY (37signals/Basecamp)**
- [PRICE] HEY for You $99/year (@hey.com address, HEY Calendar, spy-pixel blocking, 100GB). HEY for Domains $12/user/month ($10 for the first user), monthly only with no trial. Families $179/year — [HEY pricing](https://www.hey.com/pricing/)
- Platforms: web, Mac, Windows, Linux, iOS, Android — [HEY pricing](https://www.hey.com/pricing/)
- [LOCK] HEY is its own mail service with an opinionated workflow, not a client for existing accounts. The pricing page says nothing about IMAP or Outlook accounts — [HEY pricing](https://www.hey.com/pricing/). One blogger argues "the inflexibility of HEY founders is killing the product", criticizing the extra charge for custom domains and slower development after the 2021 exodus of about 20 of 58 Basecamp staff — [Hulry](https://hulry.com/hey-email/). TapSmart says the price "will put a lot of people off" — [TapSmart](https://www.tapsmart.com/apps/hey-email-review)
- [CAL] It bundles its own HEY Calendar — [HEY pricing](https://www.hey.com/pricing/)

**Proton Mail**
- [PERF] The desktop app is Electron. On Proton's own forum it was called "as slow and buggy as the website", with a multi-second splash screen "every single time". An informal GitHub benchmark showed about 375MB RAM, and the community asked for Tauri instead — [Proton inbox-desktop GitHub issue](https://github.com/ProtonMail/inbox-desktop/issues/2); [Privacy Guides](https://discuss.privacyguides.net/t/introducing-the-proton-mail-desktop-app/17331.md); [feddit](https://feddit.it/post/4145450)
- Long-form "leaving Proton Mail" posts exist — [nelson.cloud](https://nelson.cloud/leaving-proton-mail/); [Ask HN migration thread](https://hn.svelte.technology/item/40114623)

**Edison Mail / OnMail**
- [PRIV] In 2020 Motherboard reported, citing a J.P. Morgan document, that Edison sold market-research products built from scraped inbox data (purchase receipts) to finance, travel and e-commerce buyers. Users said they had been unaware. Edison pointed to an opt-out — [9to5Mac](https://9to5mac.com/2020/02/10/ios-mac-email-apps-scrape-sell-personal-data/); [Input](https://www.inputmag.com/tech/edison-mail-scrapes-users-inboxes-sells-the-data-to-clients); [TechBeacon](https://techbeacon.com/security/revealed-email-apps-steal-sell-user-data-outrage?amp); [MediaPost](https://www.mediapost.com/publications/article/347194/alleged-edison-email-scraping-fuels-privacy-concer.html)
- [DEAD] OnMail, Edison's privacy-branded email service, shut down on 31 July 2025. Edison asked users to opt in to sharing de-identified purchase data for "Edison Trends" — [Spam Resource](https://www.spamresource.com/2025/06/onmail-email-service-to-shut-down.html)

**Missive (team inbox)**
- [TEAM] Praised for "doing one thing really well (shared mailbox)". A TrustRadius user "cannot go back to Outlook". G2 rating 4.7 from 783 reviews — [Capterra](https://www.capterra.com/p/152884/Missive/reviews?page=2); [G2](https://www.g2.com/compare/microsoft-outlook-vs-missive); [TrustRadius](https://www.trustradius.com/compare-products/missive)
- [PRICE] "Pricing has increased over time". Plans are roughly $14-36/user/month (annual), AI usage is billed separately, and the free plan was reportedly removed. Capterra shows Starter $18, Productive $30 and Business $45, and still lists a free tier, so the sources conflict — [Usecarly](https://www.usecarly.com/blog/missive-review/); [Capterra pricing](https://www.capterra.com/p/152884/Missive/pricing/)

**New AI-native clients (2024-2026)**
- Zero (Mail0, YC X25): open-source (Next.js/React/Postgres), self-hostable, public beta May 2025 at 0.email, 10.5k+ GitHub stars. Offers AI drafts, summaries, conversational search, auto-labels, and Gmail plus Outlook in a unified inbox. It is web-based, not native — [YC launch](https://www.ycombinator.com/launches/NTI-zero-ai-native-email); [EmailExpert](https://emailexpert.com/examining-zero-an-ai-native-email-client-taking-a-new-approach-to-inbox-management/)
- Orchid: a "proactive work agent" over inbox and calendar from a Zero co-founder — [YC](https://ycombinator.com/companies/orchid-ai)

### Inferences
- Users love three things: keyboard speed (Superhuman), native Apple feel (Mimestream), and AI with whole-inbox context (Shortwave, Superhuman Ask AI). No app found here combines all three, and the two native/AI favourites exclude Microsoft 365.
- Users leave over subscription price versus perceived value (Superhuman, Spark, Airmail, Canary, Missive), being Gmail-only (Mimestream, Shortwave, Notion Mail), Electron regressions (Spark 3, Proton), privacy (Spark server tokens, Edison data sales), and bugs plus slow support (Airmail, Canary).
- M365 users have few premium options: Superhuman (expensive, cloud-processed), Spark (Electron, server-side tokens), Airmail/Canary (reliability complaints), and Zero (web, beta).

### Gaps
- Fastmail and Front: no search budget spent. Fastmail's Mac/iOS apps are widely reported to be web wrappers, but I found no citation here. Front is a team-support tool priced per seat; not researched.
- Cloze: not researched.
- Superhuman complaints specifically about Microsoft 365 (shared mailboxes, Exchange on-prem, delegated calendars): no sources found. Searches returned only generic Outlook shared-mailbox threads.
- Current official pricing for Mimestream, Shortwave and Canary was not verified on the vendors' own pages.
- Calendar support per app was only partly covered (HEY Calendar confirmed; Spark, Superhuman and Shortwave calendar quality not researched).
- Cora, Fyxer and Inbox Zero (AI assistants layered over Gmail/Outlook): no reliable sources found; Inbox Zero reportedly debuted Dec 2023 (unverified).

## Which apps were shut down, acquired or degraded, and why?

### Takeaway
The premium email client market has a long record of failures. Newton died twice because "the premium email market was too small" against free apps from Google, Microsoft and Apple. Airmail degraded after a hostile switch to subscriptions. Spark traded native for Electron. Edison closed OnMail amid its data-monetization history. Superhuman was absorbed into Grammarly's AI suite. Notion Mail (ex-Skiff) shut down in Sept 2026 because Notion is betting that agents, not inboxes, will handle email.

### Cited Findings
- Newton (ex-CloudMagic, 4M users at launch): relaunched in 2016 as a subscription with 40k+ paying users. It shut down on 25 Sep 2018, with the CEO saying the premium email market was too small against free apps from Google, Microsoft and Apple — [9to5Mac](https://9to5mac.com/2018/08/07/rip-newton-mail/); [MacStories](https://www.macstories.net/?p=55486); [PCWorld](https://www.pcworld.com/article/3297801/newtons-shutdown-means-windows-users-are-losing-the-only-good-email-app-its-not-gmail.html). Essential acquired and revived it, then shut it down again for 30 Apr 2020 when Essential closed — [Android Central](https://www.androidcentral.com/newton-mail-dies-second-time-following-essential-closure). It was then bought by Justin Mitchell and Maitrik Kataria and continued at $49.99/year — [MobileSyrup](https://mobilesyrup.com/2020/05/11/newton-mail-acquisition-new-features/). No 2024-2026 status was found.
- Airmail: switched to subscription in 2019, which removed paid features, followed by long update gaps and stability problems — [iMore](https://www.imore.com/ios-app-airmail-unannounced-switch-subscription-based-pricing-angers-users); [Trustpilot](https://de.trustpilot.com/review/airmailapp.com). A 2026 competitor blog claims users are leaving; it is marketing, so biased — [Mailbird](https://www.getmailbird.com/es/mejores-alternativas-airmail-mac/)
- Spark: moved from native to Electron and adopted a subscription in Oct 2022 — [Michael Tsai](https://mjtsai.com/blog/2022/10/04/spark-switches-to-electron-and-subscriptions/)
- Superhuman: acquired by Grammarly in July 2025, and the parent was renamed "Superhuman" in Oct 2025, with Mail bundled into the Business suite tier — [Vestbee](https://vestbee.com/blog/articles/grammarly-acquires-superhuman); [TechRadar](https://techradar.com/ai-platforms-assistants/grammarly-has-rebranded-as-superhuman-launching-a-new-ai-assistant-that-works-across-100-apps)
- Skiff → Notion Mail → shutdown: Notion bought Skiff (E2EE) and relaunched it as a Gmail-only client — [eesel](https://www.eesel.ai/blog/notion-mail-reviews). The shutdown was announced 25 Jun 2026 and took effect 22 Sep 2026 across web, desktop and iOS. Notion said more than 50% of users managed email through its agents without opening the inbox. Drafts, snippets and auto-label rules were deleted, and syncing to Notion databases stopped — [Android Authority](https://www.androidauthority.com/notion-mail-is-shutting-down-3681674/); [heise](https://www.heise.de/en/news/Notion-Mail-is-shutting-down-What-users-need-to-do-now-11345988.html); [AI Weekly](https://aiweekly.co/alerts/notion-mail-shuts-down-september-22-most-users-skipped-the-inbox)
- OnMail (Edison): shut down on 31 Jul 2025 — [Spam Resource](https://www.spamresource.com/2025/06/onmail-email-service-to-shut-down.html)

### Inferences
- Users of VC-funded or acquired clients have repeatedly lost their app or seen it changed (Newton x2, Skiff, Notion Mail, OnMail). An open-source client whose mail stays on the device would protect users against this, and it is a selling point in its own right: "your client can't be shut down or sold".
- Notion's stated reason (agents replacing the inbox UI) suggests rivals will build AI-agent layers over Gmail and M365 rather than fully featured clients.

### Gaps
- No hard churn numbers for any app.
- I could not confirm whether the Grammarly→Superhuman parent rename was reversed.
- Current status of Newton in 2024-2026 is unknown.

## Where is the clear market gap for a fast, native, open source, Microsoft-365-first Apple client with AI?

### Takeaway
No app in the evidence meets all five criteria: native Apple, Microsoft 365-first, AI, open source/local-first, and fair pricing. Mimestream proves there is demand for a native Swift client but is Gmail-only, with Outlook still on its roadmap. Shortwave and Notion Mail proved the appetite for AI but are or were Gmail-only. Superhuman supports Outlook but is a $25-40/month cloud product inside a Grammarly suite. Spark supports Exchange but is Electron and stores account tokens on its servers. Zero is open source with Outlook support but runs on the web.

### Cited Findings
- Native-only Gmail precedent: Mimestream (SwiftUI) supports Gmail only, with M365 "planned" — [Mimestream FAQ](https://mimestream.com/faqs)
- Gmail-only AI clients are a dealbreaker for M365 businesses — [eesel](https://www.eesel.ai/blog/notion-mail-overview); [aitoolsatlas](https://aitoolsatlas.ai/tools/shortwave/review)
- Electron regressions are the main complaint against Spark and Proton — [Michael Tsai](https://mjtsai.com/blog/2022/10/04/spark-switches-to-electron-and-subscriptions/); [Proton GitHub issue](https://github.com/ProtonMail/inbox-desktop/issues/2)
- Users explicitly prefer clients that let them disable server components (Airmail, Canary vs Spark) — [MacPowerUsers](https://talk.macpowerusers.com/t/spark-stores-email-account-credentials-on-their-servers/20388)
- Data-monetization history erodes trust (Edison) — [9to5Mac](https://9to5mac.com/2020/02/10/ios-mac-email-apps-scrape-sell-personal-data/)
- Price ceiling and value: Superhuman is $30-40/month with no free plan — [Costbench](https://costbench.com/software/ai-productivity/superhuman/); users balk at Spark's $59.99/year ("I'd pay $8 a year, not $8 a month") — [Michael Tsai](https://mjtsai.com/blog/2022/10/04/spark-switches-to-electron-and-subscriptions/)
- Open-source AI email has traction (Zero has 10.5k+ GitHub stars and supports Gmail and Outlook), but it is a web app — [EmailExpert](https://emailexpert.com/examining-zero-an-ai-native-email-client-taking-a-new-approach-to-inbox-management/)

### Inferences
- **Positioning gap:** "Mimestream for Microsoft 365, with Shortwave-level AI, open source and local-first." This means a native Swift client using Microsoft Graph, with mail and AI context processed on-device or with your own key, and no vendor server holding tokens. That directly answers complaints about Gmail-only support, Electron, privacy, and acquisition or shutdown risk.
- **Features to copy:** Superhuman's keyboard-first speed and split inbox. Shortwave's AI that reasons over past mail. Notion Mail's custom views and snippets. HEY's spy-pixel blocking. Spark's shared-inbox and team basics as a later phase.
- **Pricing signal:** keep below Superhuman by a wide margin, or offer free/BYO-key AI. The repeated anger at subscriptions that remove features (Airmail, Spark's signature ad) argues for a generous free core.
- **M365-specific needs:** shared mailboxes, delegated calendars, Focused Inbox and categories are unaddressed by the Gmail-first indie clients. I found no evidence that any premium client handles them well; this is a likely differentiator but needs validation.

### Gaps
- No direct user surveys measuring demand for M365 among indie-client users.
- No source tested Superhuman's or Spark's handling of M365 shared mailboxes or delegated calendars.
- Not checked whether Mimestream has shipped Outlook or iOS since its FAQ (Oct 2026 status unverified).
