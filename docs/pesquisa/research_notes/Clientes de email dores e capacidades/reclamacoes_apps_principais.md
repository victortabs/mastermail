# Complaints about mainstream email clients (new/classic Outlook, Outlook Mac/iOS, Apple Mail, Gmail, Thunderbird), 2023-2026

Note on method: ~17 searches and fetches (Oct 2026). Reddit, App Store and Hacker News pages could not be fetched directly. Reddit sentiment therefore comes through secondary summaries and comment threads (e.g., mjtsai.com comments, a Reddit r/MacOSBeta thread linked by mjtsai). Treat the frequency rankings as qualitative judgment, not measured data. The one quantitative breakdown (unstar.app) has an unverified methodology.

## Q1. What are the top 10-15 complaints overall, and which apps suffer from each?

### Takeaway
The biggest and most urgent issue in Oct 2026 is structural. Microsoft began disabling Exchange Web Services (EWS) in Exchange Online on Oct 1, 2026. macOS Mail, Calendar and Contacts still depend on EWS for M365 accounts, and Apple's promised Graph API migration ("a future update to macOS 27") has not shipped. Beyond that, the recurring complaints are new Outlook's slowness and missing features, notification delays (Gmail, Outlook mobile), unreliable search (Apple Mail, Gmail app, Outlook mobile), sync stalls, forced AI/UI changes, and privacy (new Outlook's cloud sync of third-party credentials).

### Cited Findings

**Ranked catalog (my ranking by severity x frequency, with sources):**

1. **M365/Exchange breaking in macOS Mail/Calendar because of EWS retirement. Severity: critical, very current. Affects macOS Mail, Calendar, Contacts, Notes and Reminders; legacy Outlook for Mac.**
   - Microsoft began disabling EWS by default in Exchange Online on Oct 1, 2026 ("phased rollout"). Permanent shutdown is set for April 1, 2027, with "no extensions currently planned". Apple's Mail and Calendar on Mac still use EWS for M365 accounts. iPhone/iPad are unaffected because they use ActiveSync. On-prem Exchange is unaffected. — [MacRumors, Oct 1 2026](https://www.macrumors.com/2026/10/01/apple-mail-mac-stop-sync-microsoft-365/)
   - Microsoft MC676299: "on October 1, 2026, we will start blocking EWS requests from non-Microsoft apps to Exchange Online". — [MC676299 via mc.merill.net](https://mc.merill.net/message/MC676299)
   - Microsoft's plan is a "phased, admin controllable disablement plan that starts in October 2026". — [Microsoft Tech Community, "Exchange Online EWS, your time is almost up"](https://techcommunity.microsoft.com/blog/exchange/exchange-online-ews-your-time-is-almost-up/4492361)
   - Apple says it is "working with Microsoft to update Mail, Calendar, Contacts, Notes, and Reminders to use the Graph API" in a future macOS 27 update. — [Apple Platform Deployment](https://support.apple.com/en-bw/guide/deployment/dep158966b23/1/web/1.0)
   - Status of Apple's fix: Apple skipped the 27.1 betas, and the macOS 27.2 beta release notes don't mention Graph. — [MacRumors](https://www.macrumors.com/2026/10/01/apple-mail-mac-stop-sync-microsoft-365/)
   - macOS 27 is Apple silicon only, so Intel Macs will never get the Graph fix. Also reported: tenants where `EWSEnabled` is null get set to False on Oct 1, and apps can be allow-listed by app ID. — [macos-tahoe.com (third-party blog quoting MS Learn/Apple)](https://macos-tahoe.com/blog/apple-mail-exchange-accounts-ews-shutdown-october-2026-guide/)
   - User reports: "On the macOS 27 RC, Apple Mail stopped receiving messages and showed a warning icon beside Exchange" (Reddit r/MacOSBeta). Another user said Mail stopped working with an O365 account on the 27 RC and a `defaults write` workaround did nothing. Another: "their organization disabled EWS, which makes Mail.app with Exchange unusable". — [mjtsai.com, Aug 20 2026 + comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
   - "Microsoft told administrators Mac users would need to switch to Outlook." The author expects the Mac loss to be permanent. — [Jonathan Harbourne, Medium, "The Mac experience at work just died"](https://medium.com/@jharbourne/the-mac-experience-at-work-just-died-here-is-the-error-code-2e8c3c5860be)
   - Legacy Outlook for Mac: "starting October 2026, the legacy Outlook for Mac client will stop working against Exchange Online mailboxes." — [Microsoft Support, as quoted by macos-tahoe.com](https://macos-tahoe.com/blog/apple-mail-exchange-accounts-ews-shutdown-october-2026-guide/)
   - Sources conflict on scope. One university notice lists only "Apple Mail (macOS 11 Big Sur or earlier)" as affected. — [W&M IT](https://www.wm.edu/offices/it/announcements/microsoft-exchange-web-services-ending-oct-1-2026.php). MacRumors and Apple's own statement imply current macOS Mail is affected. I trust MacRumors and Apple more here.

2. **New Outlook for Windows: slow, missing features, forced migration. Severity: high, frequent. Affects new Outlook (Windows).**
   - Windows Central (headline): "Microsoft is wrong: The new Outlook for Windows is not ready for prime time". The columnist says the app is slow (much slower than Mail & Calendar) and that notifications trickle in late. — [Windows Central](https://windowscentral.com/software-apps/windows-11/microsoft-is-wrong-the-new-outlook-for-windows-is-not-ready-for-prime-time) (article body was truncated on fetch; details come from the search snippet)
   - A March 2026 Microsoft Q&A post lists these gaps: inability to accept meeting invitations "in a way that automatically updates my calendar"; no way to pre-draft and schedule emails; several add-ins no longer work; and performance "degrades noticeably with large archives". — [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/a/12649484)
   - Rules are "far less capable" than in classic Outlook, and To Do replaces the Tasks folder. — [kataan.org list of missing features](https://www.kataan.org/tag/outlook)
   - Reddit sentiment (secondhand summary) centres on the interface, performance, and the sense that Microsoft is "pushing this new version too aggressively", sometimes making it hard to revert to classic. — [Blackbox Operations blog](https://erp.blackboxoperations.com/blog/new-outlook-vs-old-what)
   - Older threads: "New Outlook issues" (May 2023). — [Microsoft Tech Community](https://techcommunity.microsoft.com/t5/outlook/new-outlook-issues/m-p/3900247)

3. **Notification delays. Severity: high, the most frequent complaint in app reviews. Affects the Gmail iOS app, Outlook mobile, Spark, and Apple Mail (fetch schedule).**
   - Across 1-3 star reviews of Gmail, Outlook, Spark and Proton, notification delays are the top complaint category at 18%. Examples: Gmail "notifications routinely arrive 20 to 40 minutes after the email actually lands"; Outlook's Focused Inbox "swallows half my notifications" and the rest "arrive 15 minutes late". — [unstar.app 2026 ranking (methodology unverified; some quotes may be illustrative)](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)
   - Apple Mail with non-push accounts fetches on a schedule, so alerts can lag up to 15 minutes. — [MacRumors forums "Apple Mail fiasco" (undated)](https://forums.macrumors.com/threads/apple-mail-fiasco.2450163/)
   - Gmail push problems are often blamed on iOS background restrictions, Focus modes or Scheduled Summary. — [Inbox Zero guide 2026](https://www.getinboxzero.com/blog/post/gmail-push-notifications-not-working-iphone-android); [theitbros](https://theitbros.com/gmail-not-updating-on-iphone/)
   - New Outlook (Windows) notifications "trickle in" behind other apps. — [Windows Central](https://windowscentral.com/software-apps/windows-11/microsoft-is-wrong-the-new-outlook-for-windows-is-not-ready-for-prime-time)

4. **Search unreliability. Severity: high, frequent (14% of negative reviews per unstar). Affects Apple Mail (macOS), the Gmail app, and Outlook mobile.**
   - Apple Mail on macOS 15.3 (March 2025): shows "Indexing..." for about 30 seconds, then misses emails, including ones from the same day. Rebuilding mailboxes, re-adding accounts and Spotlight tweaks all failed. — [Apple Community thread](https://discussions-kr-prz.apple.com/thread/256016852)
   - Apple Mail search depends on Spotlight and the Envelope Index, and it broke after the Big Sur, Monterey and Ventura upgrades. A whole cottage industry of fix guides exists, which is itself a signal. — [iBoysoft (Dec 2024)](https://iboysoft.com/howto/apple-mail-search-not-working.html); [MacPaw](https://macpaw.com/how-to/mac-mail-search-not-working); [Canary blog](https://canarymail.io/blog/mac-mail-search-not-working)
   - Gmail app search "missed 4 invoices from the past 30 days" that web Gmail found. Outlook mobile search "silently excludes" the Other (non-Focused) folder. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)
   - In June 2026 Microsoft put Copilot AI suggestions above email results in Outlook search (new Outlook on Windows, iOS, Android and web). After about three months of complaints that this "buried the emails people wanted", Microsoft cancelled it on July 23, 2026. Meanwhile the Copilot button in classic Outlook is getting bigger. — [Office Watch](https://office-watch.com/2026/outlook-copilot-search-canceled/)

5. **Sync stalls / silent account failures. Severity: high. Affects macOS Mail with M365, Outlook mobile and Mac, the Gmail app (Workspace), and Outlook with Gmail accounts.**
   - "Mail on Mac not syncing with 365" (Microsoft Q&A): accounts work in iOS Mail, Outlook and OWA but not macOS Mail. Fixes are remove and re-add, or clearing Office credentials from Keychain. Re-enabling EWS did not fix it for one person. — [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/questions/5669505/mail-on-mac-not-syncing-with-365); [yomotherboard](https://yomotherboard.com/answer/answer-to-apple-mail-suddenly-stopped-syncing-exchange-accounts-on-macos/)
   - Classic recurring issue: an Exchange account in Apple Mail suddenly keeps prompting "Enter Password". — [mysysadmintips](https://mysysadmintips.com/microsoft-exchange-account-stops-working-in-apple-mail-enter-password)
   - Microsoft's known-issues page (Oct 2025) says "Outlook for Mac and Outlook Mobile intermittently stop syncing", and that a location change to a recurring event doesn't sync to the Outlook Mobile calendar. — [Microsoft Support known issues](https://support.microsoft.com/ja-JP/Support/known-issues/fixes-or-workarounds-for-outlook-mobile-apps)
   - Outlook on iOS 18.5 "has frozen and will not synch new emails" (July 2025). — [Microsoft Q&A](https://learn.microsoft.com/answers/a/12128626)
   - Gmail accounts in Outlook "stop syncing every 2-3 weeks" because OAuth expires silently with no re-auth prompt. A Gmail Workspace account "routinely stops syncing for 6+ hours". — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)
   - A commenter moved work email from Apple Mail to new Outlook because of sync problems and compared it to the 2019 Catalina Mail data-loss episode. — [mjtsai comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)

6. **Privacy / data handling: new Outlook syncs third-party accounts through the Microsoft cloud. Severity: medium-high (EU/privacy-focused users, IT). Affects new Outlook (Windows).**
   - New Outlook syncs non-Microsoft accounts (Gmail, Yahoo, iCloud, IMAP) through the Microsoft cloud. Heise reported that it sends IMAP/SMTP usernames and passwords to Microsoft servers. — [Guru3D citing Heise](https://www.guru3d.com/story/security-concerns-surrounding-data-transfer-in-the-new-outlook-application/)
   - "Sync with Microsoft Cloud" is on by default for new IMAP accounts. The only way to turn it off is to remove the account and add it back. — [ImageWay hosting blog (2023)](https://imageway.com/2023/email-hosting-blog/disable-sync-with-microsoft-cloud-feature-in-outlook-to-preserve-privacy)
   - Forum thread: "New Outlook forces sync to Microsoft Cloud when adding IMAP account". — [ElevenForum](https://www.elevenforum.com/t/new-outlook-forces-sync-to-microsoft-cloud-when-adding-imap-account.18627/post-352959)
   - Note: I could not find Microsoft primary documentation confirming credential handling. The claims rest on Heise and secondary reporting.
   - Spark's smart inbox requires uploading email metadata to Readdle servers. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)

7. **Unwanted auto-categorization / UI changes. Severity: medium, frequent around launches. Affects Apple Mail on iOS 18.2+ (Categories), Outlook Focused Inbox, Spark, and Copilot in Outlook.**
   - Apple Mail Categories are on by default in iOS 18.2. Complaints: it feels like four inboxes instead of one; mail from the same sender lands "either primary or updates, seemingly randomly"; bills sorted as promotions are a risk; there are no custom rules to route mail. — [TidBITS Talk](https://talk.tidbits.com/t/new-mail-category-feature/30647); [iDrop News](https://www.idropnews.com/how-to/dont-like-the-new-mail-categories-in-ios-182-heres-how-to-turn-them-off/232442/); [MacRumors how-to](https://macrumors.com/how-to/turn-off-apple-mail-categories)
   - Outlook's Focused Inbox toggle "moved 3 times in the past year". UI churn accounts for 5% of negative reviews. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)
   - New Outlook for Mac is criticized as a "web-style design inside a Mac window"; it "feels separate from macOS". — [mjtsai comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)

8. **Calendar integration (M365 calendars in Apple Calendar; meeting invites). Severity: medium-high for business users. Affects Apple Calendar on iOS and macOS, and new Outlook.**
   - Shared M365 calendars show in desktop Outlook but not in iOS Calendar, reportedly because iOS's ActiveSync doesn't fully honor shared-folder permissions. The toggle-the-Calendars-switch workaround breaks on new devices and resets. — [CiraSync (vendor, sells a fix)](https://cirasync.com/blog-articles/outlook-shared-calendar-not-showing-on-iphone-fix/)
   - macOS Calendar with M365 runs over EWS, so it is affected by the EWS shutdown (see #1). — [MacRumors](https://www.macrumors.com/2026/10/01/apple-mail-mac-stop-sync-microsoft-365/)
   - New Outlook: accepting invites doesn't update the calendar correctly (one user's report). — [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/a/12649484)

9. **Rules/filters and spam. Severity: medium. Affects new Outlook (weaker rules), Apple Mail Categories (no rules), and the Gmail app (spam).**
   - New Outlook rules are "far less capable". — [kataan.org](https://www.kataan.org/tag/outlook)
   - Gmail: reminders sent to spam "8 times" despite being marked not spam. Spam accounts for 9% of negative reviews and unsubscribe for 8%. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)

10. **Missing automation / extensibility. Severity: medium (power users, admins). Affects new Outlook for Mac and new Outlook for Windows.**
    - Microsoft cancelled AppleScript for new Outlook for Mac: "We have decided not to move forward with this feature"; full compatibility "isn't feasible". — [Microsoft 365 Roadmap 88537](https://www.microsoft.com/en-us/microsoft-365/roadmap?filters=&searchterms=88537), via [mjtsai](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
    - COM add-ins don't work in new Outlook for Windows. — [Microsoft Q&A](https://learn.microsoft.com/en-us/answers/a/12649484)
    - A university help desk "doesn't recommend" new Outlook for Mac because of missing features and bugs. — [Univ. of Richmond KB](https://spidertechnet.richmond.edu/TDClient/1955/Portal/KB/ArticleDet?ID=136829); [WKU "Missing features in New Outlook"](https://td.wku.edu/TDClient/34/Portal/KB/ArticleDet?ID=3730)

11. **Attachments. Severity: low-medium (6% of negative reviews). Affects Outlook mobile.**
    - Files over 10MB "routinely fail with a generic error". — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)

12. **Battery / performance on mobile. Severity: low-medium (7% of negative reviews). Affects the Gmail app.**
    - 18% of battery going to Gmail with no manual interaction. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)

13. **Ads / cost. Severity: medium for free users. Affects new Outlook for Windows and the free tier of Outlook.com.**
    - Microsoft says paid M365 users see no ads, while free accounts (Outlook.com, Hotmail, Gmail) see ads in Outlook for Windows. — [Microsoft Outlook for Windows page](https://www.microsoft.com/microsoft-365/outlook/outlook-for-windows)

14. **Thunderbird and Exchange. Historically it needed paid add-ons; native support is new.**
    - Before 2025, Exchange in Thunderbird needed paid add-ons (Owl, ExQuilla) or "sometimes-fickle IMAP/POP". Native EWS arrived in Thunderbird 144/145 (late 2025). — [Linuxiac](https://linuxiac.com/microsoft-exchange-support-coming-to-thunderbird-in-october-2025/); [Yahoo Tech](https://tech.yahoo.com/apps/articles/thunderbird-mail-getting-closer-full-145120760.html)
    - Thunderbird 154 added Microsoft Graph for email. A commenter says contacts and calendars were not yet covered. — [Thunderbird blog Sept 2026](https://blog.thunderbird.net/2026/09/thunderbird-desktop-new-protocol-support-microsoft-graph-api/); [mjtsai comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)

15. **Outlook.com sign-in in Apple Mail (Oct 2025). Severity: medium, partly unconfirmed. Affects Apple Mail on macOS Sequoia and Tahoe.**
    - Some users couldn't add Outlook.com, Hotmail or Live accounts. The direct "Outlook.com" option is gone, leaving only Exchange or IMAP. M365 Exchange accounts appeared unaffected, and AppleInsider staff couldn't reproduce it. — [AppleInsider](https://appleinsider.com/articles/25/10/06/apple-mail-breaks-outlook-sign-ins-but-only-if-youre-unlucky); [PhoneArena](https://www.phonearena.com/news/macos-update-breaks-outlook-login-in-apple-mail-for-some-users_id174706); [Microsoft Q&A "Unable to add Exchange email address in Apple Mail"](https://learn.microsoft.com/en-us/answers/questions/5575210/unable-to-add-exchange-email-address-in-apple-mail)

**Aggregated review complaint shares (all four apps combined: Gmail, Outlook, Spark, Proton).** Notifications 18%, search 14%, threading 11%, multi-account sync 10%, spam 9%, unsubscribe 8%, battery 7%, attachments 6%, UI changes 5%, privacy 5%. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026) (no sample size, date range or per-app breakdown; treat as indicative only)

### Inferences
- **Mapping to the requested themes (approximate rank):**
  1. Exchange/M365 compatibility (critical, especially on Mac)
  2. Sync reliability
  3. Notifications
  4. Search
  5. Performance (new Outlook)
  6. Calendar
  7. Privacy
  8. UI clutter / AI intrusion
  9. Rules/filters
  10. Spam
  11. Multi-account
  12. Attachments
  13. Cost/ads
  14. Offline and accessibility: no evidence found
- No single mainstream app delivers native-feeling macOS/iOS UI, reliable M365 sync over Graph, and fast local search all at once. Each incumbent fails at least one of those.
- The EWS shutdown creates a time-limited window. Mac users with M365 who refuse new Outlook have few native options until Apple ships Graph support, and Intel Mac users get none at all.

### Gaps
- Could not fetch Reddit, App Store or Hacker News directly, so there are no verbatim r/Outlook or r/sysadmin quotes and no current App Store star ratings.
- No reliable evidence found for offline-mode or accessibility complaints in these apps.
- No per-app quantitative split of complaints. The unstar.app numbers are aggregated and unverified.
- The Windows Central article body could not be fetched, so its date and full complaints are unknown.

## Q2. Why do people abandon new Outlook / Apple Mail / Gmail app for alternatives?

### Takeaway
- **New Outlook:** people leave because it feels like a slow web wrapper with missing classic features (rules, add-ins, scheduling, AppleScript on Mac), plus aggressive forced migration and AI clutter.
- **Apple Mail:** people leave over broken search, sync stalls with Exchange, unwanted Categories, and now the EWS cutoff for M365 on Mac.
- **Gmail app:** people leave over late notifications, weak in-app search, spam misclassification, and battery drain.

### Cited Findings
- New Outlook: slow and not ready ([Windows Central](https://windowscentral.com/software-apps/windows-11/microsoft-is-wrong-the-new-outlook-for-windows-is-not-ready-for-prime-time)); missing scheduling, broken invite handling, add-ins and large-archive performance ([MS Q&A](https://learn.microsoft.com/en-us/answers/a/12649484)); pushed "too aggressively" ([Blackbox summary of Reddit](https://erp.blackboxoperations.com/blog/new-outlook-vs-old-what)).
- New Outlook for Mac is a "significant functional step back"; IT departments "will face many angry calls"; the UI is "web-style design inside a Mac window". — [mjtsai comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
- Copilot search suggestions buried emails, and Microsoft rolled them back. — [Office Watch](https://office-watch.com/2026/outlook-copilot-search-canceled/)
- Apple Mail: search misses mail ([Apple Community](https://discussions-kr-prz.apple.com/thread/256016852)); M365 sync stalls ([MS Q&A](https://learn.microsoft.com/en-us/answers/questions/5669505/mail-on-mac-not-syncing-with-365)); Categories ([TidBITS](https://talk.tidbits.com/t/new-mail-category-feature/30647)).
- One user moved from Apple Mail to new Outlook because of sync failures. Another plans to "leave Microsoft and stay off macOS 27" rather than wait for Apple. — [mjtsai comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
- Alternatives already marketing Graph support for Mac: MailMaven (Graph + AppleScript), DavMail (Graph), Thunderbird 154 (Graph email). — [mjtsai](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/); [Thunderbird blog](https://blog.thunderbird.net/2026/09/thunderbird-desktop-new-protocol-support-microsoft-graph-api/)
- Gmail app: notification delays, search misses, spam not learning, battery drain, and Workspace sync pauses. — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)
- Vendors are already marketing to Outlook-for-Mac switchers (e.g., Mailbird's "Best Outlook for Mac Replacement (2026)"). — [getmailbird.com](https://www.getmailbird.com/best-outlook-for-mac-replacement-2026-top-macos-email-clients/)

### Inferences
- Mac users with M365 are being squeezed from both sides. Apple Mail is breaking (EWS), and the Microsoft-sanctioned alternative (new Outlook for Mac) is disliked as non-native and less capable. This is the clearest switching trigger for a native Swift M365 client.

### Gaps
- No survey data on churn rates or which alternatives people actually pick.

## Q3. What specific problems happen with Microsoft 365/Exchange accounts in Apple Mail and Calendar on Mac/iOS?

### Takeaway
- **macOS:** Mail, Calendar and Contacts use EWS for M365, and Microsoft began blocking EWS from non-Microsoft apps on Oct 1, 2026 (full shutdown Apr 1, 2027). Apple's Graph migration is promised for "a future update to macOS 27" but not yet shipped, and it will never reach Intel Macs. Even before the shutdown there were chronic problems: sync stalls, repeated password prompts, broken account adding, and slow, incomplete search.
- **iOS:** iOS uses ActiveSync and survives the EWS shutdown, but shared calendars and delegated mailboxes are poorly supported.

### Cited Findings
- EWS cutoff details, Apple's statement, macOS 27.2 beta silence, and iOS unaffected (ActiveSync). — [MacRumors](https://www.macrumors.com/2026/10/01/apple-mail-mac-stop-sync-microsoft-365/); [Apple](https://support.apple.com/en-bw/guide/deployment/dep158966b23/1/web/1.0); [MC676299](https://mc.merill.net/message/MC676299)
- Workarounds: admins can re-enable or allow-list EWS until April 2027, or move users to Outlook. — [MacRumors](https://www.macrumors.com/2026/10/01/apple-mail-mac-stop-sync-microsoft-365/); [macos-tahoe.com](https://macos-tahoe.com/blog/apple-mail-exchange-accounts-ews-shutdown-october-2026-guide/)
- Universities are warning staff, e.g., Cornell's "prepare for EWS retirement" and PolyU's Aug 2026 notice. — [Cornell IT](https://it.cornell.edu/microsoft-outlook/prepare-ews-retirement); [PolyU ITS](https://www.polyu.edu.hk/its/news-and-events/its-enewsletter/get-connected/2026-aug/04-microsoft-exchange-web-services-retirement/)
- Mail's EWS support "has been buggy" even before the shutdown. — [Michael Tsai](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
- macOS Mail stops syncing M365 while iOS, OWA and Outlook are fine; fixes are re-adding the account or clearing Keychain. — [MS Q&A](https://learn.microsoft.com/en-us/answers/questions/5669505/mail-on-mac-not-syncing-with-365)
- Repeated "Enter Password" prompts for Exchange in Apple Mail (often tied to modern auth or tokens). — [mysysadmintips](https://mysysadmintips.com/microsoft-exchange-account-stops-working-in-apple-mail-enter-password)
- Unable to add Exchange accounts to Apple Mail (2025). — [MS Q&A](https://learn.microsoft.com/en-us/answers/questions/5575210/unable-to-add-exchange-email-address-in-apple-mail)
- Shared M365 calendars are missing in iOS Calendar, and the workaround breaks on device changes. Outlook mobile avoids this by using Graph. — [CiraSync (vendor)](https://cirasync.com/blog-articles/outlook-shared-calendar-not-showing-on-iphone-fix/)
- macOS Tahoe 26.1: incoming mail text displayed as stacked boxes (rendering bug; German Apple Community). — [Apple Community DE](https://communities.apple.com/de/thread/256191956)

### Inferences
- Users can't do without Graph API-based sync (mail, calendar, contacts, shared/delegated calendars). Any client still on EWS is dead for Exchange Online after April 2027.
- Shared calendars and delegation are a recurring pain point that native Apple apps handle poorly, which is a clear differentiator for the target product.

### Gaps
- No evidence found on how Apple Mail handles M365 shared mailboxes, delegation, room booking or Teams meeting links on Mac. Likely weak, but not verified.
- Unclear whether Apple's Graph update will ship in 27.x, or when.

## Q4. What do users say is missing that they wish existed?

### Takeaway
The asks fall into four groups:
- Native Mac/iOS feel combined with full M365 fidelity: Graph sync, shared calendars, reliable meeting invites, rules.
- Instant, reliable notifications and search.
- Control over AI and auto-categorization (opt-in, not imposed).
- Privacy: no credential relay through vendor clouds.

### Cited Findings
- Scheduled send and reliable invite acceptance (new Outlook). — [MS Q&A](https://learn.microsoft.com/en-us/answers/a/12649484)
- Full-power rules and classic Tasks. — [kataan.org](https://www.kataan.org/tag/outlook)
- AppleScript/automation in Outlook for Mac (cancelled by Microsoft). — [Roadmap 88537 via mjtsai](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
- Custom routing rules for Apple Mail Categories, and categories that are predictable. — [TidBITS](https://talk.tidbits.com/t/new-mail-category-feature/30647)
- Search that puts emails before AI suggestions. — [Office Watch](https://office-watch.com/2026/outlook-copilot-search-canceled/)
- A native-feeling Outlook alternative on Mac ("web-style design inside a Mac window" complaint). — [mjtsai comments](https://mjtsai.com/blog/2026/08/20/the-end-of-ews-in-mail-and-applescript-in-outlook/)
- Visible account and auth errors instead of silent sync stops (Outlook OAuth expiry; Spark paused-account icon). — [unstar.app](https://unstar.app/blog/gmail-outlook-spark-protonmail-email-apps-ranked-2026)
- Local-only handling of credentials (the reaction to new Outlook's cloud sync). — [Guru3D/Heise](https://www.guru3d.com/story/security-concerns-surrounding-data-transfer-in-the-new-outlook-application/)

### Inferences
- These point to the following product requirements for a native Swift M365 client:
  1. Graph-based sync for mail, calendar and contacts, including shared/delegated calendars.
  2. Local, fast, complete search that doesn't depend on Spotlight.
  3. Real push notifications (Graph change notifications through a relay; design for privacy).
  4. Explicit, visible auth and sync health.
  5. Server-side rules (Exchange inbox rules) editable in the client.
  6. Optional AI.
  7. Native AppKit/SwiftUI UX.
  8. A clear privacy stance: tokens stay on-device and there is no mail-content relay.
  9. Apple-native automation (Shortcuts/AppleScript), which fills the gap Microsoft left.

### Gaps
- No direct wishlist threads from Reddit or UserVoice were captured. These wishes are derived from complaints.
