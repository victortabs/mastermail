# Microsoft Graph + MSAL for a third-party native Apple mail/calendar client (status as of Oct 2026)

Note on method: findings come from Microsoft Learn pages fetched in this session (throttling limits, delta query for messages, large attachments, Outlook change notifications, findMeetingTimes, the MSAL keychain and SSO docs), the MSAL objc GitHub README, Message Center mirrors, and admin and community blogs. Items marked "[not re-verified this session]" are well-established facts from Microsoft docs that I did not fetch again. Check them before relying on them.

## Q1. What are the biggest practical gotchas and limits for a fast, offline-capable client using Graph?

### Takeaway
The binding constraint is Outlook's per-app, per-mailbox throttle. That is 10,000 requests per 10 minutes and only **4 concurrent requests** per mailbox, plus 150 MB of uploads per 5 minutes. Delta sync works one folder at a time. Attachments over 3 MB need an upload session, with a hard cap of 150 MB. A client has to be designed around these limits: low concurrency, heavy `$select`, delta per folder, and raw `$value` downloads.

### Cited Findings
**Throttling**
- Outlook limits apply per app ID plus mailbox. Exceeding them on one mailbox does not affect other mailboxes. The limits are **10,000 API requests in a 10-minute period**, **four concurrent requests**, and **150 MB upload (PATCH, POST, PUT) in a 5-minute period**. They apply to both v1.0 and beta. — [Graph throttling limits](https://learn.microsoft.com/en-us/graph/throttling-limits)
- The Outlook limits cover message, mailFolder, mailSearchFolder, messageRule, outlookCategory, attachment, event, eventMessage, calendar, calendarGroup, contact and the related resources. — [Graph throttling limits](https://learn.microsoft.com/en-us/graph/throttling-limits)
- For JSON batching against Outlook, Graph sends at most 4 requests from an unordered batch to Outlook at a time. With `dependsOn`, requests run one at a time, and an app can run up to 4 such sequential batches concurrently against the same mailbox. — [Graph throttling limits](https://learn.microsoft.com/en-us/graph/throttling-limits)
- A JSON batch holds at most 20 requests. Each request inside a batch counts separately toward throttling. A batch can return 200 while individual sub-responses return 429 with Retry-After, so the client must retry sub-requests. [not re-verified this session] — [JSON batching](https://learn.microsoft.com/en-us/graph/json-batching)
- The subscription service has its own limits: 500 POST/PUT/DELETE/PATCH requests per 20 seconds per app per tenant, and 2,000 per 20 seconds per app across all tenants. — [Graph throttling limits](https://learn.microsoft.com/en-us/graph/throttling-limits)

**Delta query (mail)**
- "Delta query is a per-folder operation." To track a folder hierarchy, each folder is tracked separately. The client stores an `@odata.deltaLink` per folder and pages with `@odata.nextLink`. Deletions arrive as `@removed: {reason: "deleted"}`. — [Delta query for messages](https://learn.microsoft.com/en-us/graph/delta-query-messages)
- Message delta supports `$select`, `$top` and `$expand`. The only supported `$filter` is `receivedDateTime ge|gt {value}`, and using it caps results at **5,000 messages**. The only supported `$orderby` is `receivedDateTime desc`. **`$search` is not supported.** Page size is set with `Prefer: odata.maxpagesize`. A `changeType=created|updated|deleted` custom option is available. — [Delta query for messages](https://learn.microsoft.com/en-us/graph/delta-query-messages)
- Folders have their own delta at `/me/mailFolders/delta`. Calendar sync uses `/me/calendarView/delta` with a fixed start and end window. Recurring series are expanded into instances inside the window. [not re-verified this session] — [Delta query overview](https://learn.microsoft.com/en-us/graph/delta-query-overview)

**Attachments**
- Files under 3 MB go in a single POST to `/attachments`. Files from 3 MB to **150 MB** need `createUploadSession` and sequential byte-range PUTs, ideally under 4 MB per chunk, to a pre-authenticated `outlook.office.com` URL with no Authorization header. Creating an upload session for a file under 3 MB fails with `ErrorAttachmentSizeShouldNotBeLessThanMinimumSize`. A known issue affects large attachments in shared or delegated mailboxes. — [Attach large files](https://learn.microsoft.com/en-us/graph/outlook-large-attachments)
- For downloads, use `/attachments/{id}/$value` for raw bytes. Avoid base64 `contentBytes` for large files, and use `$select` to fetch metadata without content. — [Attach large files](https://learn.microsoft.com/en-us/graph/outlook-large-attachments)
- The 150 MB per 5 minutes per-mailbox upload throttle means a user sending several large attachments in a row can hit 429 on uploads. — [Graph throttling limits](https://learn.microsoft.com/en-us/graph/throttling-limits)

**Other Mail/Calendar API surface** [not re-verified this session; from Graph API reference]
- MIME is available. `GET /me/messages/{id}/$value` returns the RFC 822 MIME. `sendMail` and message creation accept a base64 MIME body with `Content-Type: text/plain`. This matters for S/MIME and for an IMAP-like local store. — [Get MIME content](https://learn.microsoft.com/en-us/graph/outlook-get-mime-message)
- Threading uses `conversationId` and `conversationIndex` on message. There is no "threads" resource for mailbox mail; `/conversations` belongs to Microsoft 365 Groups. The client has to group messages by conversationId locally. — [message resource](https://learn.microsoft.com/en-us/graph/api/resources/message)
- Focused Inbox is exposed through the `inferenceClassification` property (focused or other) and `/me/inferenceClassification/overrides`. Categories come from `/me/outlook/masterCategories`. Inbox rules come from `/me/mailFolders/inbox/messageRules`, and only Inbox rules are supported. Drafts flow: `createReply`, `createReplyAll`, `createForward`, then PATCH, then `send`. — [Mail API overview](https://learn.microsoft.com/en-us/graph/api/resources/mail-api-overview)

**Calendar specifics**
- `findMeetingTimes` is **not supported for personal Microsoft accounts** or for application permissions. It needs `Calendars.Read.Shared` (delegated, work or school). It is not available in 21Vianet China. — [findMeetingTimes](https://learn.microsoft.com/en-us/graph/api/user-findmeetingtimes)
- Teams meeting links are created by setting `isOnlineMeeting=true` and `onlineMeetingProvider=teamsForBusiness` on the event. Personal accounts get `teamsForBusiness` only in limited cases, and Skype is legacy. [not re-verified this session] — [event resource](https://learn.microsoft.com/en-us/graph/api/resources/event)

### Inferences
- With only 4 concurrent requests per mailbox, a "fast" client has to minimise round trips. Useful tactics: send `$select` with list-view fields only (subject, from, receivedDateTime, isRead, flag, bodyPreview, conversationId, hasAttachments, inferenceClassification, categories, parentFolderId), fetch bodies lazily, prioritise the visible folder, and serialise background work. 10,000 requests per 10 minutes, about 16 per second, is generous for one user. Concurrency is the real bottleneck.
- Initial sync of a large mailbox should start with Inbox, Sent and the top folders, delta-paging with `Prefer: odata.maxpagesize` around 50–100. Older mail can backfill later. A `receivedDateTime` filter on delta caps at 5,000, so it only suits a "recent window" quick start.
- Search cannot use delta. Offline search needs a local index (SQLite FTS), with server `$search` for messages outside the local cache.
- Calendar delta needs a sliding window, for example −1 to +12 months, that is re-anchored periodically because the window is fixed per delta token.

### Gaps
- I did not fetch the `$search` limits for messages, such as result caps and no `$orderby` with `$search`, or the Microsoft Search API (`/search/query`) constraints for mail. Verify these before designing search.
- I did not confirm the delta token expiry or "resync required" (410 Gone / syncStateNotFound) behavior for Outlook delta this session.
- I could not fully verify Teams-link behavior for personal accounts.

## Q2. How does sync work best without a backend server (delta cadence, push alternatives)?

### Takeaway
Graph change notifications need an HTTPS endpoint (webhook), Event Hubs or Event Grid that Microsoft can reach, plus subscription renewal. A pure client app cannot receive them directly. Without a server, the realistic design is delta polling with a foreground cadence and best-effort OS background refresh. Real-time push, especially APNs on iOS, needs a small relay server.

### Cited Findings
- Outlook change notifications are delivered "via webhooks". The subscription carries a `notificationUrl`. The supported resources are contact, event and message, with or without encrypted resource data. Resource data requires an encryption certificate whose private key the receiver holds. — [Outlook change notifications](https://learn.microsoft.com/en-us/graph/outlook-change-notifications-overview)
- There is a maximum of **1,000 active subscriptions per mailbox across all applications**. — [Outlook change notifications](https://learn.microsoft.com/en-us/graph/outlook-change-notifications-overview)
- Delegated subscriptions cover only the signed-in user's own mailbox. The `.Shared` permissions **do not support** subscriptions on shared or delegated folders. Those require application permissions, which an end-user client cannot realistically get. — [Outlook change notifications](https://learn.microsoft.com/en-us/graph/outlook-change-notifications-overview)
- Personal Microsoft accounts are supported for message, event and contact subscriptions with Mail.Read / Calendars.Read. — [Outlook change notifications](https://learn.microsoft.com/en-us/graph/outlook-change-notifications-overview)
- Subscriptions expire and must be renewed. Microsoft Learn sets the Outlook maximum at **4,230 minutes (under 3 days) without resource data, and 1 day with resource data**. One third-party guide says 10,080 minutes, which conflicts with Microsoft. — [Outlook change notifications (en-MY)](https://learn.microsoft.com/en-MY/graph/outlook-change-notifications-overview); contradicted by [Nylas guide](https://cli.nylas.com/guides/microsoft-graph-change-notifications)
- Lifecycle notifications (`reauthorizationRequired`, `subscriptionRemoved`, `missed`) exist so the app can detect lost subscriptions and resync with delta. — [Lifecycle notifications](https://learn.microsoft.com/en-us/graph/change-notifications-lifecycle-events)
- The `$filter` on subscriptions has non-obvious semantics. For an `isRead eq false` filter, marking a message read fires a "Deleted" notification. — [Outlook change notifications](https://learn.microsoft.com/en-us/graph/outlook-change-notifications-overview)

### Inferences
- **Serverless design:** keep a delta token per folder plus one calendarView delta. Poll the visible folder and Inbox every ~30–60 s while the app is in the foreground, and other folders every few minutes. That stays far under 10,000 requests per 10 minutes. On iOS, use BGAppRefreshTask, which is opportunistic and roughly every 15+ minutes at the OS's discretion, so new-mail alerts will be delayed and unreliable. On macOS, a background agent can poll continuously.
- **Minimal relay for push:** a tiny stateless service receives Graph webhooks (without resource data, so no decryption is needed and no mail content touches the server) and forwards a silent APNs push, after which the device runs delta. The server needs only the subscription ID-to-device-token mapping. Subscriptions can be created from the device with the user's delegated token pointing at the relay URL, so the server never holds Graph tokens. Renewal also needs a token, so either the device renews on wake, which fits the ~3-day maximum, or the server stores refresh tokens, which raises the security and privacy bar.
- Treat notifications only as a "poke to run delta". Never use them as the source of truth, given missed and removed lifecycle events.

### Gaps
- I did not verify whether Graph has added any client-reachable push channel (for example, a native-app-friendly long poll). I found none.
- I did not verify current iOS background-refresh frequency figures.

## Q3. What consent and verification hurdles block enterprise users from using a new third-party app?

### Takeaway
This is the biggest risk for a new client in 2026. Since **November 2025**, the Microsoft-managed default consent policy blocks user consent to **Mail.\*, Calendars.\*, IMAP/POP/EWS/EAS.AccessAsUser.All and MailboxSettings.\*** for third-party apps. Users then see "Need admin approval". The exception is a Microsoft-curated list of "popular mail clients" (Apple Mail, Spark, eM Client, Thunderbird, Samsung/Android mail). A new app must expect an admin-consent step in most tenants. Publisher verification is necessary but not sufficient.

### Cited Findings
- **Aug 2025:** the Microsoft-managed policy began blocking user consent for Files.Read.All, Files.ReadWrite.All, Sites.Read.All and Sites.ReadWrite.All. **Nov 2025:** it extended to Mail.Read, Mail.ReadBasic, Mail.ReadWrite, the Mail.\*.Shared variants, Calendars.Read, Calendars.ReadBasic, Calendars.ReadWrite, the Calendars.\*.Shared variants, EWS.AccessAsUser.All, EAS.AccessAsUser.All, POP.AccessAsUser.All, IMAP.AccessAsUser.All, MailboxFolder.\*, MailboxItem.Read, MailboxSettings.Read/ReadWrite, Chat.\* and OnlineMeetings.\*. **Mail.Send was not listed.** Existing consents keep working. New users and new or broader permission requests are blocked. — [Topedia, Nov 2025 (table updated May 2026)](https://blog-en.topedia.com/2025/11/microsoft-managed-default-app-consent-policy-now-blocks-20-additional-permissions/); [Office365ITPros on MC1097272](https://office365itpros.com/2025/06/19/app-consent-policy-user-app-consent/)
- **June–July 2026:** a further 8 were added: Contacts.ReadWrite, Contacts.Read.Shared, Contacts.ReadWrite.Shared, People.Read, Tasks.Read, Tasks.ReadWrite, Tasks.Read.Shared, Tasks.ReadWrite.Shared. Only tenants on Microsoft-managed policies are affected; custom policies are not. — [Topedia, May 2026](https://blog-en.topedia.com/2026/05/microsoft-managed-default-app-consent-policy-will-block-8-additional-permissions/)
- If "Enable user consent for popular Mail clients" is on, the tenant uses the policy `microsoft-user-default-allow-consent-apps`, and users can still consent to approved popular mail apps. Otherwise `microsoft-user-default-recommended` requires admin consent. — [Topedia, May 2026](https://blog-en.topedia.com/2026/05/microsoft-managed-default-app-consent-policy-will-block-8-additional-permissions/)
- That allow-list policy names Apple Mail, Spark Email, eM Client, Android-Samsung, Android-Mail and Thunderbird. No public criteria for inclusion were found. — [Entra docs diff (Manage app consent policies, 2026-08-28)](https://entradiff.merill.net/changes/2026-08-28/manage-app-consent-policies-21/)
- Multi-tenant apps registered after Nov 2020 show "unverified" in the consent prompt unless publisher verified, and verified apps show a blue badge. With risk-based step-up consent, users cannot consent to unverified multi-tenant apps registered after Nov 8, 2020 that request more than basic sign-in permissions. — [Publisher verification overview](https://learn.microsoft.com/en-ca/entra/identity-platform/publisher-verification-overview); [Configure publisher domain](https://learn.microsoft.com/sr-latn-rs/entra/identity-platform/howto-configure-publisher-domain)
- Many security-conscious tenants already set "allow user consent only for verified publishers, low-impact permissions" or disable user consent entirely. — [Practical365](https://practical365.com/practical-protection-protecting-your-tenant-by-restricting-applications/)
- Thunderbird's experience: it moved to a new Entra app (`9e5f94bc-e8a4-4e73-b8be-63364c29d753`, "Mzla Technologies Corporation") to meet publisher-verification requirements. Its users in restricted tenants see "Need admin approval", and Mozilla publishes an admin-consent URL for IMAP.AccessAsUser.All, POP.AccessAsUser.All, SMTP.Send and offline_access. — [Mozilla KB: Microsoft OAuth and Thunderbird in 2026](https://support.mozilla.org/en-US/kb/microsoft-oauth-authentication-and-thunderbird-202/revision/275611)
- Older guides list Thunderbird's previous app ID as `08162f7c-0fd2-4200-a84a-f25a4db0b584`. — [eightwone](https://eightwone.com/2020/07/01/configuring-exchange-account-with-imap-oauth2/)

### Inferences
- A new third-party app on Graph or IMAP with Mail.ReadWrite will hit **admin consent required** in most tenants on Microsoft defaults, unless Microsoft adds it to the "popular mail clients" list. That is a business-development path with unknown criteria.
- The onboarding UX should detect `AADSTS65001` / `AADSTS90094` (admin approval needed) and offer three things: a pre-built admin-consent URL (`https://login.microsoftonline.com/{tenant}/adminconsent?client_id=...`), an email template for IT, and a pointer to the tenant's admin consent workflow.
- Do publisher verification early, using an MPN/Partner Center account with a domain that matches the publisher domain. Without it, the "unverified" label and step-up consent block even permissive tenants.
- Conditional Access (compliant or managed device, app protection policies) can still block a third-party app after consent. Brokered auth through Authenticator or Company Portal is needed for device-based CA. Intune APP (MAM) requires integrating the Intune SDK.
- Personal Outlook.com accounts are not subject to tenant consent policies; the user consents directly.

### Gaps
- I found no official Microsoft statement on how an app qualifies for the "popular mail clients" allow-list.
- I did not fetch the MC post for the November 2025 expansion directly. The permission list comes from the Topedia secondary source.
- I did not verify whether Mail.Send alone is user-consentable under the current policy beyond its absence from the list.

## Q4. MSAL for iOS/macOS, app registration, scopes, and the public client ID in OSS

### Takeaway
MSAL objc ships as an SPM binary package and now requires iOS 17+ / macOS 14+ for MSAL 2.x. Register a multi-tenant + personal-accounts public client with redirect `msauth.<bundle>://auth`, enable the keychain group, and use the broker on iOS. A public client ID is not a secret and can be committed, but forks reusing your ID consume your reputation and throttling.

### Cited Findings
- MSAL for iOS/macOS 1.1.14 and later is distributed as a binary Swift package. MSAL 2.x has breaking changes and requires **iOS 17+ and macOS 14+**. It supports personal Microsoft accounts and Entra work or school accounts. — [MSAL objc GitHub](https://github.com/AzureAD/microsoft-authentication-library-for-objc)
- The default keychain access group is **`com.microsoft.adalcache` on iOS** and **`com.microsoft.identity.universalstorage` on macOS**, added under Keychain Sharing capabilities. A custom group goes in `config.cacheConfig.keychainSharingGroup`. Error -34018 means a misconfigured keychain group. Keychain SSO on macOS requires a properly signed app. — [MSAL keychain config](https://learn.microsoft.com/en-us/entra/msal/objc/howto-v2-keychain-objc)
- iOS broker (Microsoft Authenticator) setup: register redirect `msauth.<bundle.id>://auth` in CFBundleURLSchemes, add `msauthv2`/`msauthv3` to LSApplicationQueriesSchemes, and call `MSALPublicClientApplication.handleMSALResponse` in AppDelegate or SceneDelegate. The broker provides SSO on Entra-registered devices and Conditional Access compliance. — [MSAL SSO macOS/iOS](https://learn.microsoft.com/en-us/entra/msal/objc/single-sign-on-macos-ios)
- On iOS, SSO with Safari uses ASWebAuthenticationSession. **On macOS, MSAL supports only WKWebView, which has no SSO with Safari.** — [MSAL SSO macOS/iOS](https://learn.microsoft.com/en-us/entra/msal/objc/single-sign-on-macos-ios)
- Apps sharing a keychain can delete each other's tokens. Be careful with remove operations. — [MSAL SSO macOS/iOS](https://learn.microsoft.com/en-us/entra/msal/objc/single-sign-on-macos-ios)
- Public clients use auth code + PKCE with no secret. Microsoft samples place the client ID in client-side config files. — [MS Graph quickstart sample](https://github.com/girliemac/mslearn-retrieve-m365-data-with-msgraph-quickstart)
- Scopes typically used for a mail plus calendar client: `Mail.ReadWrite`, `Mail.Send`, `Calendars.ReadWrite`, `MailboxSettings.ReadWrite` (for rules and auto-replies), `offline_access` and `User.Read`. Add `.Shared` variants for shared or delegated mailboxes and calendars. Note that several of these are now in the blocked-for-user-consent set (see Q3). — [Topedia permission table](https://blog-en.topedia.com/2025/11/microsoft-managed-default-app-consent-policy-now-blocks-20-additional-permissions/)

### Inferences
- Shipping the client ID in a public repo is standard practice. Thunderbird's ID is public and documented by Mozilla. Risks: a malicious fork with the same ID and redirect could phish consent under your verified name, and forks share your app identity in tenant allow-lists and sign-in logs. Mitigations: restrict redirect URIs to your bundle-ID scheme, and document that forks should register their own ID, for example via a build-time config override.
- On macOS, consider the Enterprise SSO plug-in / Platform SSO through Company Portal for managed Macs. MSAL can use it when present. I did not verify the details this session.
- Request scopes incrementally. For example, ask for Calendars only when the user opens the calendar. This reduces initial-consent friction in tenants that allow partial consent.

### Gaps
- I did not verify macOS broker details (Company Portal SSO extension / Platform SSO support in MSAL 2.x) or the exact current MSAL version number.

## Q5. Graph vs IMAP+OAuth vs EWS: recommendation for 2026

### Takeaway
EWS is dead for new work. Exchange Online starts disabling it tenant by tenant on **Oct 1, 2026**, and removes it permanently on **Apr 1, 2027**. Use **Graph as primary** for M365 and Outlook.com, since it is the only path with calendar, categories, Focused Inbox, rules and the change-notification model. IMAP/SMTP + XOAUTH2 is a fallback with no calendar and the same consent hurdles (IMAP.AccessAsUser.All is also blocked from user consent).

### Cited Findings
- MC1227454 (Feb 5, 2026): from **Oct 1, 2026**, Microsoft sets EWSEnabled=False for tenants that have not configured an EWS AppID AllowList. Admins can re-enable it until **Apr 1, 2027**, after which EWS is permanently removed with no exceptions. Exchange Server on-premises is unaffected. — [MC1227454 mirror](https://mc.merill.net/message/MC1227454); [UWaterloo notice](https://uwaterloo.ca/science-computing/news/retirement-exchange-web-services-ews-october-1-2026); [Petri](https://petri.com/microsoft-counts-down-to-end-of-exchange-web-services/)
- Some secondary sites wrongly describe Oct 1, 2026 as the final shutdown. — [Cloudiway](https://cloudiway.com/blog/ews-discontinued-what-it-mean-how-to-get-ready/), versus the MC post above
- EWS was also blocked for Kiosk/F1/F3-licensed mailboxes, returning 403. One source dates this to July 1, 2026. — [AvePoint Aug 2026](https://www.avepoint.com/blog/manage/august-2026-updates-microsoft-ews-retirement)
- Graph has no public-folder API. — [Commvault docs](https://documentation.commvault.com/11.44/software/move_your_exchange_online_protection_from_ews_to_microsoft_graph.html)
- SMTP AUTH basic auth: per the MC786329 update of Jan 27, 2026, it is unchanged through Dec 2026, disabled by default for existing tenants at the end of Dec 2026 (re-enable possible), and unavailable for new tenants after that. The final removal date will be announced in H2 2027. — [MC786329 diff](https://mc.merill.net/message/MC786329/compare/2025-06-12T17-33-31-167Z/2026-01-27T20-11-01-253Z)
- IMAP/POP/SMTP with OAuth uses the scopes IMAP.AccessAsUser.All, POP.AccessAsUser.All and SMTP.Send, which Thunderbird requests. Tenant admins may also have disabled SMTP AUTH per mailbox. — [Mozilla KB](https://support.mozilla.org/en-US/kb/microsoft-oauth-authentication-and-thunderbird-202/revision/275611); [Office365ITPros IMAP OAuth](https://office365itpros.com/2022/07/14/imap4-clients-to-exchange-online/)

### Inferences
- **Recommendation:** use Graph for Microsoft accounts, covering both M365 and Outlook.com. It gives mail, calendar, contacts, categories, flags, Focused Inbox, rules, MIME access, delta sync and optional push via a relay. IMAP+XOAUTH2 brings no consent advantage, because IMAP.AccessAsUser.All is equally blocked, and it lacks calendar. Keep it only if the app already has a generic IMAP engine and wants code reuse; it is acceptable as a mail-only fallback. Do not build on EWS. On-prem Exchange support, if needed, would be EWS against on-prem only, which is a niche case.
- Graph gaps to plan around: public folders, the 4-concurrency limit, per-folder delta, the lack of push without a server, and server-side search only through `$search` / Microsoft Search.

### Gaps
- **Personal Outlook.com differences** were only partly verified. Confirmed: findMeetingTimes is unsupported for MSA, and change notifications are supported for MSA. Not verified this session: Focused Inbox/inferenceClassification, messageRules and onlineMeeting availability for MSA, or Outlook.com IMAP OAuth scopes (`https://outlook.office.com/IMAP.AccessAsUser.All`). Also unverified is whether Outlook.com still allows app-password or basic IMAP.
- I could not retrieve the Exchange Team blog post on EWS directly; only the MC post via mirrors.
- I found no Stack Overflow, Reddit or GitHub-issue evidence this session on real-world 429 frequency for single-user clients.
