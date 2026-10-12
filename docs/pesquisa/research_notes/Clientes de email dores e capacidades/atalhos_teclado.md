# Keyboard Shortcuts and Keyboard-First Workflows in Email Clients (Superhuman as primary reference)

Research date: October 2026. Note: Superhuman's official help center (help.superhuman.com) returned HTTP 403/404 to automated fetches, and the official shortcut PDF (download.superhuman.com) is an image-only Figma export with no extractable text. The Superhuman tables below therefore come from third-party mirrors (pie-menu.com, nickgray.net, tutorialtactic PDF), cross-checked against Gmail's official list where possible. Treat individual Superhuman bindings as "very likely correct, not verified against first-party text."

## 1. What exact shortcuts does Superhuman use, why are they the gold standard, and which are Gmail-compatible?

### Takeaway
Superhuman's map is essentially Gmail's single-key vocabulary (E, R, F, C, S, /, #, !, J/K, X, L, V, Z, G+letter) refined and extended with its own keys (H = Remind Me, Enter = Reply All, Cmd+K palette, Tab = next split, Cmd+Shift+Enter = send & done). Its "gold standard" status comes less from the key choices themselves (HN users note they are "almost the exact same" as Gmail's) and more from total keyboard coverage, sub-100ms response, a universal command palette, and aggressive teaching (mandatory 1:1 onboarding, hints in UI).

### Cited Findings

**Superhuman Mail (Mac) shortcut table** — 72 Mac shortcuts across 8 sections — [pie-menu.com](https://pie-menu.com/shortcuts/superhuman); partially corroborated by [nickgray.net](https://nickgray.net/superhuman/)

| Section | Action | Superhuman | Gmail equivalent ([Gmail help](https://support.google.com/mail/answer/6594?hl=en&co=GENIE.Platform%3DDesktop)) |
|---|---|---|---|
| Actions | Superhuman Command (palette) | Cmd+K | none (Gmail Cmd+K = insert link in compose) |
| Actions | Search | / | / (same) |
| Actions | Undo | Z | z (same) |
| Actions | Show shortcuts | Shift+? | ? (same) |
| Conversations | Mark Done (Archive) | E | e (same) |
| Conversations | Mark Not Done (back to inbox) | Shift+E | — |
| Conversations | Remind Me (snooze) | H | b (different) |
| Conversations | Star | S | s (same) |
| Conversations | Mark read/unread toggle | U | Shift+i / Shift+u (Gmail's `u` = back to list) — CONFLICT |
| Conversations | Trash | Shift+# | # (same key) |
| Conversations | Spam | Shift+! | ! (same key) |
| Conversations | Mute | Shift+M | m |
| Conversations | Unsubscribe | Cmd+U | — |
| Messages | Compose | C | c (same) |
| Messages | Reply All | Enter | a (different; Gmail Enter = open) |
| Messages | Reply | R | r (same) |
| Messages | Forward | F | f (same) |
| Messages | Open links & attachments | Cmd+O | — |
| Messages | Expand message / all | O / Shift+O | ; (expand all) |
| Labels | Add/remove label | L | l (same) |
| Labels | Remove label / all labels | Y / Shift+Y | (y legacy "remove label" in old Gmail) |
| Labels | Move | V | v (same) |
| Calendar | Toggle calendar / prev day / next day | 0 / - / = | — |
| Navigation | Next / previous split | Tab / Shift+Tab | ` / ~ (next/prev inbox section) |
| Navigation | Next / previous conversation | J / K (pie-menu lists K=next, J=previous; nickgray only lists "J or K") | j = older (down), k = newer (up) |
| Navigation | Jump to top/bottom | Cmd+Up / Cmd+Down | — |
| Navigation | New window / new tab | Cmd+N / Cmd+T | — |
| Navigation | Next / prev tab | Cmd+Shift+] / Cmd+Shift+[ | — |
| Navigation | Switch tab 1..n | Cmd+1, Cmd+2… | — |
| Navigation | Switch account 1..n | Ctrl+1, Ctrl+2… | — |
| Navigation | Font size | Cmd+= / Cmd+- | — |
| Selection | Select conversation | X | x (same) — [nickgray.net](https://nickgray.net/superhuman/) |
| Selection | Extend selection | Shift+J / Shift+K | — — [nickgray.net](https://nickgray.net/superhuman/) |
| Compose | To / Cc / Bcc / From | Cmd+Shift+O / C / B / F | Cmd+Shift+c / b / f (same for Cc/Bcc/From) |
| Compose | Edit subject / edit message | Cmd+Shift+S / Cmd+Shift+M | — |
| Compose | Attach | Cmd+Shift+A | — |
| Compose | Discard draft | Cmd+Shift+, | — |
| Compose | Move contacts to Bcc (Instant Intro) | Cmd+Shift+I | — |
| Compose | Remind me (on draft) / Send later | Cmd+Shift+H / Cmd+Shift+L | — |
| Compose | Use Snippet | Cmd+; | (Gmail Cmd+; = next misspelled word) |
| Compose | Send | Cmd+Enter | Cmd+Enter (same) |
| Compose | Send & Mark Done | Cmd+Shift+Enter | — |
| Compose | Instant Send (skip undo delay) | Cmd+Shift+Z | — |
| Format | Bold/Italic/Underline | Cmd+B/I/U | same |
| Format | Hyperlink | Cmd+K (context-dependent; palette elsewhere) | Cmd+K (same) |
| Format | Strikethrough | Cmd+Shift+X | — |
| Format | Numbers / Bullets / Quote | Cmd+Shift+7 / 8 / 9 | same |
| Format | Indent / outdent | Cmd+] / Cmd+[ , Tab/Shift+Tab in lists | same |

- "Go to" sequences in Superhuman: G then I (Inbox/Important), G then D (Drafts), G then T (Sent), G then E (Done), G then H (Reminders) — [tutorialtactic Superhuman PDF](https://tutorialtactic.com/wp-content/uploads/2023/08/Superhuman-Shortcuts-PDF.pdf); same pattern in a 2019 list — [Daniel Miessler](https://danielmiessler.com/blog/my-favorite-superhuman-shortcuts). These mirror Gmail's g+i, g+d, g+t, g+s, g+a — [Gmail help](https://support.google.com/mail/answer/6594?hl=en&co=GENIE.Platform%3DDesktop)
- Official sources say the full list is shown in-app via Cmd+K → "Shortcuts" and offered as a downloadable PDF; Superhuman optimizes shortcuts for US QWERTY and has a separate International Keyboard Shortcuts page; troubleshooting advises checking conflicts with macOS/Windows shortcuts, other apps, and Chrome extensions — [Superhuman Help: Desktop Shortcuts / Shortcuts Not Working (search snippet)](https://help.superhuman.com/hc/en-us/articles/46005544514061-Keyboard-Shortcuts-Not-Working)
- Superhuman Docs (a newer product) has its own shortcut list opened with Ctrl+/ on Mac — [Superhuman Help](https://help.superhuman.com/hc/en-us/articles/46210352258701-Keyboard-shortcuts-in-Superhuman-Docs)
- HN skepticism: "Almost the exact same one you can turn on in Gmail" (gbourne) — shortcuts alone were not seen as a differentiator; others point to Mutt or MailMate as long-standing keyboard-driven alternatives — [HN: Superhuman is Sublime Text for Email](https://news.ycombinator.com/item?id=25620176)
- A defender on HN: "every single interaction can be done on the keyboard" — [HN thread](https://news.ycombinator.com/item?id=23614167) (via search snippet)
- HN user reported Mimestream's Gmail shortcuts broke under a second keyboard locale while Superhuman handled it fine — [Show HN: Mimestream](https://news.ycombinator.com/item?id=24422432) (via search snippet)

**Gmail full official list (desktop web; must be turned on in Settings → "Keyboard shortcuts on")** — [Gmail help](https://support.google.com/mail/answer/6594?hl=en&co=GENIE.Platform%3DDesktop)
- Actions: `,` toolbar focus; `x` select; `s` star; `e` archive; `m` mute; `!` spam; `#` delete; `r`/`Shift+r` reply (new window); `a`/`Shift+a` reply all; `f`/`Shift+f` forward; `Shift+n` update conversation; `]`/`[` archive and go to previous/next; `z` undo; `Shift+i` read; `Shift+u` unread; `_` unread from selected message; `+`/`=` important; `-` not important; `b` snooze; `;` expand all; `:` collapse all; `Shift+t` add to Tasks.
- Jumping: g+i Inbox, g+s Starred, g+b Snoozed, g+t Sent, g+d Drafts, g+a All mail, g+k Tasks, g+l label.
- Selection: *+a all, *+n none, *+r read, *+u unread, *+s starred, *+t unstarred.
- Navigation: g+n / g+p page; `u` back to list; `k` newer, `j` older; `o`/Enter open; `` ` `` / `~` next/prev inbox section; `p`/`n` previous/next message in a conversation.
- Application: `c` compose, `d` compose in new tab, `/` search, `.` more actions, `v` move to, `l` label as, `?` shortcut help.
- Compose: Cmd+Enter send; Cmd+Shift+c/b/f Cc/Bcc/From; Cmd+k link; Cmd+; next misspelling; Cmd+m spelling suggestions.

### Inferences
- A Gmail-compatible core (c, r, a/Enter, f, e, #, !, s, x, j/k, /, l, v, z, g-sequences, Cmd+Enter, Cmd+Shift+c/b) is the de facto lingua franca; Superhuman, Shortwave, Spark (Superhuman/Gmail presets), and Mimestream (Gmail preset) all converge on it. A new client should ship it as default or a preset to minimize switching cost.
- Notable Superhuman deviations from Gmail: H (remind) vs b (snooze); Enter = Reply All; U toggles read state (vs Gmail's u = back to list); Tab cycles splits. These are the spots where a "Gmail mode" vs "Superhuman mode" preset would differ.
- Superhuman's "gold standard" reputation rests on the system (coverage + speed + palette + teaching), not unique key choices.

### Gaps
- Could not fetch Superhuman's first-party shortcut list text (403 / image-only PDF). The J/K direction is listed inconsistently by third parties (pie-menu: K=next, J=previous); Gmail convention is j=down/older, k=up/newer and Superhuman is widely understood to follow it, but this was not verified against first-party text.
- Did not find first-party documentation of shortcuts for Superhuman's newer AI features (Ask AI, Write with AI, Auto Summarize) beyond "Cmd+K → Ask AI".

## 2. How do apps teach and surface shortcuts? What does command palette design look like? (plus other apps' full tables)

### Takeaway
Teaching happens on three layers: (1) human onboarding (Superhuman's historical mandatory 30-min 1:1 call), (2) in-context hints (shortcut shown next to every button/command; running a command via the palette shows its key), and (3) a universal palette (Cmd+K) plus a "?" cheat sheet. Superhuman's own command palette guidance is the most explicit design spec available: one global hotkey, omnipotent coverage, fuzzy + synonym matching, ranking, context-aware ordering, and shortcut hints in every row.

### Cited Findings

**Onboarding/coaching**
- Early Superhuman users had to complete a mandatory 30-minute 1:1 video call with an onboarding specialist before using the product; the specialist configured workflow, imported mail, trained keyboard shortcuts and guided to Inbox Zero; ~20 people worked on onboarding full-time at peak — [Gainsight: 5 Lessons from Superhuman's Onboarding](https://www.gainsight.com/blog/5-lessons-i-learned-from-superhumans-onboarding/); [Flowjam teardown](https://www.flowjam.com/blog/superhuman-onboarding-teardown-30-minute-wow-session)
- A pre-call survey tailored the session to the user's priorities — [rebryk substack](https://rebryk.substack.com/p/how-to-get-actionable-insights-onboarding)
- Superhuman blog lists "shortcut hints appear in the UI, and Cmd+K opens a command library" as part of its speed strategy — [Superhuman blog: built for speed](https://blog.superhuman.com/superhuman-is-built-for-speed/)

**Superhuman command palette design principles** — [Superhuman blog: How to build a remarkable command palette](https://blog.superhuman.com/how-to-build-a-remarkable-command-palette/)
1. Available everywhere via the same shortcut; pressing the shortcut again dismisses it.
2. Keyboard-first: users "don't need to take their hands away from the keyboard."
3. Discoverability: the one place where "users can find every command."
4. Shortcut hints: running a command teaches its shortcut so users "learn the shortcut for next time."
5. Omnipotence: every action has a command; each new UI element should get a corresponding command.
6. "Visually imposing"; a partially cut-off last row invites exploration.
7. An icon per command for scanability.
8. Forgiving "fuzzy string matching."
9. Synonyms/aliases, shown as "<command title> (<matching alias>)" to teach preferred vocabulary.
10. Relevance ranking: default scores, per-command "scale" multipliers, "follow" relationships, refined by usage data.
11. Context changes ranking; hide commands only when "fully irrelevant."
12. Graceful conflict handling: when Cmd+K conflicts locally (e.g., insert link in compose), pressing it a second time opens the palette.

**Other apps' surfacing mechanisms**
- Gmail: "?" opens shortcut help; shortcuts are off by default and must be enabled in settings — [Gmail help](https://support.google.com/mail/answer/6594?hl=en&co=GENIE.Platform%3DDesktop)
- Shortwave: Ctrl/Cmd+/ or Shift+/ opens shortcut reference; Cmd+K (also Cmd+Shift+K, Cmd+Shift+P) opens the command palette covering navigation, triage, compose, labels, AI assistant, experiments — [Shortwave shortcuts](https://www.shortwave.com/docs/references/shortcuts/)
- Spark: Cmd+K "Command Center" — [Spark help](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts)
- HEY: "?" for help; `h` or Cmd+J opens the "HEY menu" (a menu-palette) — [HEY shortcuts](https://www.hey.com/keyboard-shortcuts/)
- Mimestream: native macOS menu bar shows every command with its key equivalent; users can override any menu shortcut via macOS System Settings — [Mimestream help](https://mimestream.com/help/user-guide/keyboard-shortcuts)

**Mimestream full table (Default / Apple Mail / Gmail presets)** — [Mimestream help](https://mimestream.com/help/user-guide/keyboard-shortcuts)

| Action | Mimestream default | Apple Mail set | Gmail set |
|---|---|---|---|
| New message | ⌘N | ⌘N | C |
| Reply / Reply All / Forward | ⌘R / ⇧⌘R / ⇧⌘F | same | R / A / F |
| Archive | ⌃⌘A | ⌃⌘A | E |
| Trash | ⌘⌫ | ⌘⌫ | # |
| Report spam | ⇧⌘J | ⇧⌘J | ! |
| Message search | ⌥⌘F | ⌥⌘F | / |
| Assign labels / Move to… | ⌘L / ⇧⌘M | same | same |
| Expand/collapse messages | ⇧⌘Z (as listed) | ⇧⌘Z | ; |
| Send | ⌘⏎ | ⇧⌘D | ⌘⏎ |
| Send and Archive | ⇧⌘⏎ | ⇧⌘⏎ | ⇧⌘⏎ |
| Insert template | ⌘/ | ⌘/ | ⌘/ |
| Go to Inbox/Starred/Snoozed/Drafts/Sent/All/Trash/Spam | ⌘1…⌘8 | ⌘1…⌘8 | ⌃⌘1…⌃⌘8 |
| Switch profiles | ⌃⌘1… | ⌘1… | ⌘1… |
| Go to folder… | ⇧⌘O | ⇧⌘O | ⇧⌘O |
| Open in Gmail | ⌃⌘G | ⌃⌘G | ⌃⌘G |
| Hide/Show Sidebar / Viewing Pane | ⌃⌘S / ⌃⌘V | same | same |
| Formatting | standard ⌘B/I/U, ⌘[ ⌘] indent, ⌘' quote level, ⇧⌘I inline code, ⇧⌘B code block | same | same |
Notes: navigation shortcuts change if folders/profiles are reordered; Archive/Trash keys depend on the "Delete Key" preference; any menu shortcut can be overridden at OS level. A reviewer wished presets were individually editable — [TidBITS (via search)](https://tidbits.com/2023/05/24/why-i-use-mimestream-for-gmail/)

**Spark** — presets on Mac: Spark Desktop, Spark Classic, Apple Mail, Gmail, Superhuman, Custom; Windows: Spark Desktop, Gmail, Superhuman, Custom; iPad fixed set; Android none. Custom: Settings → Shortcuts → Custom, assign any key to any action. Spark Desktop set: E = Mark as Done (archive), ⌘⇧E = mark all done, ⇧R = Reply, R = Reply All, C = compose, S = snooze, ⌘F = search, ⌘K = Command Center, ⌘⇧1/2 = Inbox/Calendar, / = toggle sidebar, ⌘↩ = send; iPad archive = ⌘⌫ — [Spark help](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts). Third-party Spark lists conflict with the official page — [search note; DefKey](https://defkey.com/spark-mail-shortcuts)

**HEY** — [HEY keyboard shortcuts](https://www.hey.com/keyboard-shortcuts/)
- Navigation: 1 Imbox, 2 Feed, 3 Paper Trail, 4 Reply Later, 5 Set Aside, 6 Bubble Up, 9 Previously Seen, 0 Calendar toggle, s or / search, h or ⌘J HEY menu, ? help.
- Imbox: w write, o Power Through New, z Bubbled Up.
- Message: r Reply Now, l Reply Later, a Set Aside, z Bubble Up, f forward, b label, v move, t trash, > see more.
- Bulk: x select, j/k or arrows next/prev, Enter open, ; focus bulk menu, u mark unseen, i Imbox, p Paper Trail, d Feed, o Read Together, r Reply Together, n Collection, y sticky, g merge, - ignore, t trash.
- Pop-up menus: Enter/Space open, arrows navigate, Esc clears input then closes, Tab closes and focuses next element.

**Shortwave** (Gmail-compatible, supports many Spark & Gmail shortcuts) — [Shortwave shortcuts](https://www.shortwave.com/docs/references/shortcuts/); [Migrating from Spark](https://www.shortwave.com/docs/migrations/migrating-from-spark-mail/)
- Compose: C new, N new thread from search, A reply all, R reply, F forward, Cmd+Shift+C/B Cc/Bcc, Cmd+Shift+I move last sender to Bcc with thank-you (Instant Intro equivalent), Cmd+Shift+A attach, Cmd+K link, Cmd+Shift+D or Cmd+Shift+, discard, Cmd+Enter send, Cmd+Shift+Enter send & done, Z / Cmd+Z undo send.
- Threads: Y Ask AI, D or E done, [ / ] done and next/prev, T todos, B or H snooze, S star, L label, V move, # or Delete delete, Cmd+U unsubscribe, Cmd+B block, ! spam, M mute, Cmd+C copy link, U/Shift+U unread, Shift+I read, + / - important.
- List: J/K or arrows, X multi-select, → or Enter open in side panel, ← or Esc close, Space/Shift+Space page, Cmd+\ sidebar.
- Go-to: G+I inbox, G+O todos, G+S starred, G+B/H snoozed, G+E done, G+T sent, G+D drafts, G+! spam, G+# trash, G+1..9 favorited searches.
- Global: Cmd+J AI assistant, Cmd+; AI snippet, Cmd+' saved prompt, Alt+1..9 switch account, Cmd+, settings, Cmd+Shift+L theme.
- Markdown-style formatting in compose (**bold**, `code`, `>` quote, `-` list), plus +name / -name / @name participant shortcuts.

**Apple Mail** — archive is Control-Command-A; shortcuts are mostly modifier combos (e.g., Shift-Command-D send, Shift-Command-U unread); Move to Folder has no default shortcut but can be bound via System Settings → Keyboard → App Shortcuts — [Apple Support: Mail shortcuts](https://support.apple.com/guide/mail/keyboard-shortcuts-mlhlb94f262b/mac); [Canary blog](https://canarymail.io/blog/mac-mail-customize-keyboard-shortcuts)

**Outlook for Mac** (M365/2024/2021) — [Microsoft Support](https://support.microsoft.com/en-us/accessibility/outlook/mac/keyboard-shortcuts-in-outlook-for-mac)
| Action | Shortcut |
|---|---|
| New mail / Reply / Reply all / Forward | ⌘N / ⌘R / ⇧⌘R / ⌘J |
| Send | ⌘Return |
| Send/receive all | ⌃⌘K |
| Archive | ⌃E |
| Delete / permanent delete | Delete / ⇧Delete |
| Mark read / unread / all read | ⌘T / ⇧⌘T / ⌥⌘T |
| Flag today/tomorrow/this week/next week/no date/custom/reminder | ⌃1/⌃2/⌃3/⌃4/⌃5/⌃6/⌃= |
| Move to folder | ⇧⌘M |
| Search folder / find in item | ⌥⌘F / ⌘F |
| Next / previous message | ⌃] / ⌃[ |
| Mail / Calendar / Contacts | ⌘1 / ⌘2 / ⌘3 |
Microsoft states some macOS versions/utilities may conflict; custom shortcuts possible through a separate mechanism.

### Inferences
- For a native Swift client the best "teaching stack" is: menu bar with key equivalents (free discoverability, HIG-compliant), a Cmd+K palette that shows the shortcut on every row and teaches on execution, hover/tooltips with key hints on toolbar buttons, a "?" cheat-sheet overlay, and on iPad the system ⌘-hold overlay (UIKeyCommand discoverabilityTitle).
- Preset sets (Default / Gmail / Superhuman / Apple Mail) plus per-action custom remapping, as Spark does, is the most complete customization model observed; Mimestream's preset-only model draws user complaints.

### Gaps
- Linear/Raycast palette design was not separately researched; Superhuman's own article covers the same principles.
- No first-party data on how much 1:1 onboarding improved shortcut adoption/retention.
- Current status of Superhuman's mandatory onboarding (2025-2026, post-Grammarly acquisition) not verified; it may now be optional/self-serve.

## 3. What design/engineering techniques make these apps "feel" instant? (plus Inbox Zero flows)

### Takeaway
Superhuman's speed is a product principle: every interaction < 100ms (Paul Buchheit's threshold), target < 50ms "whenever possible", achieved via a local email database, caching, preloading/prerendering of likely-next threads, minimal animations, continuous performance measurement, and keyboard-over-mouse. Optimistic UI (act locally, sync in background, undo instead of confirm) is the implied pattern, though Superhuman's speed post does not use that phrase.

### Cited Findings
- 100ms rule attributed to Gmail creator Paul Buchheit as the threshold "where interactions feel instantaneous"; Superhuman targets under 50ms whenever possible, 100ms max; a new renderer shows emails in 1-2 frames (< 32ms) — [Superhuman blog: built for speed](https://blog.superhuman.com/superhuman-is-built-for-speed/)
- Techniques listed: continuous performance measurement; local database of emails (works offline); caching; preloading/prerendering threads likely to be opened next; minimal animations; keyboard shortcuts instead of gestures; shortcut hints + Cmd+K; runs on Gmail and Outlook APIs but adds local storage/caching — same source
- Cited evidence: Amazon ~1% sales per 100ms latency; Google 500ms slower search → 20% traffic drop; network latency NY–SF ≈ 14ms vacuum / 21ms fiber; 4G can add up to 100ms — same source
- Speed features named: Split Inbox, Remind Me, Snippets, Instant Intro, Quick Links, Quick Quote, See Your Day, Select All from Here, Unsubscribe, Block; customers report saving ~3h/week (marketing claim) — same source
- Third-party design guide claims ~50-60ms targets for archive/send and an optimistic archive flow (UI first, server sync in background) — [blakecrosley.com](https://blakecrosley.com/es/guides/design/superhuman) (unverified against Superhuman sources)
- General case for optimistic UI: 100ms is the limit to feel instantaneous; e.g., Instagram like button — [Algolia engineering blog](https://www.algolia.com/blog/engineering/maintaining-speed-perception-with-neuralsearch-and-optimistic-ui/)
- Undo instead of confirmation: Superhuman "you can hit Undo, and it will never have sent"; Z undo as safety net; Cmd+Shift+Z "Instant Send" bypasses the undo window — [Superhuman blog: fastest email experience](https://blog.superhuman.com/the-fastest-email-experience-ever-made/); [pie-menu](https://pie-menu.com/shortcuts/superhuman). Shortwave: Z/Cmd+Z undo send returns message to draft — [Shortwave](https://www.shortwave.com/docs/references/shortcuts/)
- HN: "no Electron app deserves a 'Sublime Text of X'" — native speed is seen as a credibility signal — [HN](https://news.ycombinator.com/item?id=25620176)

**Inbox Zero flows**
- Get Me To Zero: in settings; marks everything older than a chosen period as Done (messages stay in Done, not deleted) — [third-party walkthrough, sponsored](https://huelife-xqvj9.kinsta.page/smart-email-clients/transcripts/superhuman-tutorial-2026-getting-started.html)
- Split Inbox: customizable micro-inboxes (examples: Notifications, Calendar, VIP, Board & Investors); Tab/Shift+Tab to cycle — [Superhuman: Gmail alternative](https://superhuman.com/gmail-alternative); [Superhuman Help: Executives](https://help.superhuman.com/hc/en-us/articles/47718700548621-Executives); [pie-menu](https://pie-menu.com/shortcuts/superhuman)
- Auto Summarize: 1-line summary above every email; Ask AI via Cmd+K — [Superhuman: Gmail alternative](https://superhuman.com/gmail-alternative)
- Instant Intro (Cmd+Shift+I): thank introducer, move them to Bcc, start reply — [Superhuman blog](https://blog.superhuman.com/the-fastest-email-experience-ever-made/); Shortwave equivalent Cmd+Shift+I — [Shortwave](https://www.shortwave.com/docs/references/shortcuts/)
- Send & Mark Done (Cmd+Shift+Enter) in Superhuman, Shortwave; Send and Archive (⇧⌘⏎) in Mimestream — sources above
- Archive-and-advance: Gmail `]`/`[`; Shortwave `[`/`]` — [Gmail](https://support.google.com/mail/answer/6594?hl=en&co=GENIE.Platform%3DDesktop), [Shortwave](https://www.shortwave.com/docs/references/shortcuts/)
- Remind Me (H) / reminders on sent drafts (Cmd+Shift+H) and Send Later (Cmd+Shift+L) — [pie-menu](https://pie-menu.com/shortcuts/superhuman)
- HEY alternative model: triage buckets (Reply Later `l`, Set Aside `a`, Bubble Up `z`) and batch modes (Power Through `o`, Read Together, Reply Together) — [HEY](https://www.hey.com/keyboard-shortcuts/)

### Inferences
- For a Swift client: local-first store (SQLite/GRDB/SwiftData) as source of truth; mutate UI synchronously on keypress, enqueue server ops (Gmail API / IMAP / Graph) with retry; prefetch the next N threads in the list direction of travel; pre-render HTML bodies (WKWebView pool) before open; replace confirmation dialogs with Undo (Z / ⌘Z) and a delayed send queue; avoid long animations; instrument keypress→paint latency with signposts.
- "Auto-advance after archive" behavior (next vs previous) should be configurable, and archive/advance must not re-layout the list visibly.

### Gaps
- No first-party Superhuman engineering detail on optimistic UI conflict resolution or prefetch heuristics.
- No reliable source found for "auto-archive" feature specifics in Superhuman.

## 4. What do keyboard power users complain is missing in Apple Mail and Outlook for Mac?

### Takeaway
Evidence is thin and mostly indirect: Apple Mail and Outlook for Mac rely on multi-modifier chords (Apple Mail archive ⌃⌘A; Outlook archive ⌃E, next message ⌃]) with no single-key Gmail-style mode, no command palette, no go-to sequences, and missing default bindings (e.g., Apple Mail Move to Folder). Power users work around via macOS App Shortcuts remapping or switch to Mimestream/Superhuman/MailMate.

### Cited Findings
- Apple Mail archive default is Control-Command-A; many users remap it to a single key or Cmd+E via System Settings → Keyboard Shortcuts — [Canary Mail blog](https://canarymail.io/blog/mac-mail-customize-keyboard-shortcuts) (vendor blog, treat as opinion); [Apple Support](https://support.apple.com/guide/mail/keyboard-shortcuts-mlhlb94f262b/mac)
- Apple Mail Move to Folder has no built-in shortcut — [search summary of Apple/OSXDaily sources](https://osxdaily.com/2024/04/18/15-mail-keyboard-shortcuts-for-mac/)
- Accidental triggers: a user hit Cmd+Shift+Y and added all highlighted senders to Contacts; advice was to rebind in System Settings — [Apple Community](https://discussions.apple.com/thread/2511584)
- Outlook for Mac: archive ⌃E, next/prev ⌃]/⌃[; Microsoft notes conflicts with some macOS versions and utilities — [Microsoft Support](https://support.microsoft.com/en-us/accessibility/outlook/mac/keyboard-shortcuts-in-outlook-for-mac)
- Mimestream exists explicitly to give Gmail users a native Mac client with Gmail single-key presets — [Mimestream help](https://mimestream.com/help/user-guide/keyboard-shortcuts); [MacStories review](https://www.macstories.net/reviews/mimestream-the-perfect-email-app-for-gmail-users-on-the-mac/)
- HN: some users are content with macOS Mail; complaints focus on search quality (sn41) rather than shortcuts — [HN](https://news.ycombinator.com/item?id=25620176)

### Inferences
- The gap a new client can fill: single-key mode (opt-in, Gmail/Superhuman compatible) on top of standard Cmd menu shortcuts; command palette; go-to sequences; snooze/remind keys; move-to/label pickers with fuzzy type-ahead; send-and-archive; archive-and-advance.

### Gaps
- Did not find a good corpus of Reddit complaints specifically on Apple Mail / Outlook Mac keyboard workflow (searches returned SEO listicles). This is a known gap; a dedicated Reddit search (r/MacOS, r/Outlook, r/productivity) is recommended.

## 5. What macOS-native conventions and accessibility requirements must be respected?

### Takeaway
Respect system-reserved shortcuts, expose every command in the menu bar with its key equivalent, keep standard editing/document keys (⌘C/V/X/Z/A/N/O/S/P/W/Q/H/,) with their standard meanings, display modifiers in ⌃⌥⇧⌘ order, support Full Keyboard Access and VoiceOver, and make single-character shortcuts toggleable/remappable (WCAG 2.1.4) because they collide with screen-reader quick-nav keys and speech input.

### Cited Findings
- Apple HIG Keyboards page could not be fetched (content didn't render). General HIG guidance (from model knowledge, not verified this session): don't reassign system-reserved shortcuts (⌘Q, ⌘H, ⌘Space, ⌘Tab, ⌥⌘Esc, ⇧⌘3/4/5); modifier display order ⌃ ⌥ ⇧ ⌘; expose commands in the menu bar; on iPad, holding ⌘ shows the discoverability overlay populated from UIKeyCommand titles — [Apple HIG: Keyboards](https://developer.apple.com/design/human-interface-guidelines/keyboards) (UNVERIFIED — page did not load)
- Mimestream follows native conventions (⌘N, ⌘R, ⇧⌘R, ⌘W, ⌘,, ⌘1-8 mailboxes, ⌘0 main window, ⌃⇥ tabs, 🌐F full screen) and notes any app menu shortcut can be overridden via macOS App Shortcuts — [Mimestream help](https://mimestream.com/help/user-guide/keyboard-shortcuts)
- macOS-native apps conflict zones observed: Superhuman uses Cmd+K both as palette and as insert-link in compose (resolved by "press twice"); Cmd+U = unsubscribe vs underline in compose (context-dependent) — [Superhuman palette blog](https://blog.superhuman.com/how-to-build-a-remarkable-command-palette/); [pie-menu](https://pie-menu.com/shortcuts/superhuman). Shortwave notes conflicts with browser extensions like 1Password — [Shortwave](https://www.shortwave.com/docs/references/shortcuts/)
- Superhuman optimizes for US QWERTY and maintains a separate international layout page; layout issues (e.g., # ! / ? on non-US keyboards) are a known pain — [Superhuman Help (snippet)](https://help.superhuman.com/hc/en-us/articles/46005544514061-Keyboard-Shortcuts-Not-Working); [HN Mimestream thread](https://news.ycombinator.com/item?id=24422432)
- WCAG 2.1.4 Character Key Shortcuts (Level A): single-character shortcuts must be able to be turned off, remapped to include a modifier, or be active only when the relevant component has focus; rationale: screen readers use letter keys (e.g., H for headings) and speech-input users trigger them accidentally — [W3C Understanding 2.1.4](https://www.w3.org/WAI/WCAG21/Understanding/character-key-shortcuts); [DAISY KB](https://kb.daisy.org/publishing/docs/wcag/character-key-shortcuts.html)
- HEY's pop-up menus define explicit keyboard focus behavior (Enter/Space open, Esc clears then closes, Tab closes and moves focus) — a good model for accessible pickers — [HEY](https://www.hey.com/keyboard-shortcuts/)

### Inferences
- In SwiftUI/AppKit: implement every action as a menu command (`.commands`/`CommandMenu`, `keyboardShortcut`) so it appears in the menu bar and macOS Help search; route single-key shortcuts only when the message list/reader has focus (never in text fields), satisfying WCAG 2.1.4's "active only on focus" route, plus a setting to disable single-key mode entirely.
- With VoiceOver on, VO uses Ctrl+Option chords (VO keys), so single-letter app shortcuts generally reach the app, but VoiceOver Quick Nav / single-key navigation can intercept letters; provide accessibility labels and `accessibilityCustomActions` (archive, reply, snooze) on rows so rotor users get the same verbs. (Inference — not verified against Apple docs this session.)
- Full Keyboard Access: ensure all pickers (move, label, snooze, palette) are fully navigable with Tab/arrows/Space/Esc and have visible focus rings.
- Use Ctrl+number or ⌘number consistently: Mimestream and Outlook use ⌘1.. for mailboxes/modules; Superhuman uses ⌘1.. for tabs and Ctrl+1.. for accounts. Pick one scheme and document it.
- iOS/iPadOS: hardware keyboard support via UIKeyCommand with discoverability titles; Spark offers a fixed iPad set, with ⌘⌫ archive — [Spark](https://sparkmailapp.com/help/tips-tricks/use-keyboard-shortcuts).

### Gaps
- Apple HIG Keyboards page text not retrieved; reserved-shortcut list is from model knowledge.
- No source found describing how Superhuman, Mimestream, or Spark behave with VoiceOver or Full Keyboard Access specifically.
- Vim-style beyond j/k/g-sequences (e.g., counts, modal editing, `dd`) not found in any mainstream client; mutt/aerc remain the reference for full vim-style (not researched in depth).
