# IA em clientes de email (estado em out/2026): capacidades, preços, privacidade e recepção

Nota de método: ~16 buscas e leituras. Muitas fontes de preço são agregadores (PricingSaaS, CostBench, UsagePricing) ou blogs de fornecedores concorrentes. A página da Apple sobre o Foundation Models não renderizou pelo WebFetch e o artigo da TechRepublic retornou 403, então os fatos sobre essas fontes vêm de reportagens secundárias e de notas técnicas e fóruns da Apple. Trate os preços exatos como provisórios.

## Matriz de recursos (resumo para quem vai escrever o relatório)

| Produto | Triagem/categorias | Resumos | Rascunho/voz | Perguntas ao inbox | Agêntico | Preço (2026) | Onde roda / privacidade |
|---|---|---|---|---|---|---|---|
| Apple Mail (Apple Intelligence) | Categorias Primary/Transactions/Updates/Promotions | Resumo no lugar do preview | Writing Tools (no sistema todo) | Nenhuma fonte encontrada | Nenhuma fonte encontrada | Grátis com hardware compatível | No dispositivo + Private Cloud Compute (não verificado nesta pesquisa) |
| Gmail + Gemini 3 | "AI Inbox" (testadores) mais as abas | AI Overviews de threads (grátis) | Help Me Write, Suggested Replies (grátis); Proofread (pago) | AI search answers (AI Pro/Ultra) | AI Inbox com to-dos | Grátis / Google AI Pro, Ultra | Nuvem; Google diz que não treina com o Gmail |
| Outlook + M365 Copilot | Flags de prioridade, triagem em linguagem natural | Resumos de thread com citações | Rascunho, reescrita, coaching de tom | Copilot Chat | Thread vira convite de reunião | US$18/usuário/mês (Business ≤300) ou US$30 (Enterprise), add-on | Nuvem (limite do tenant M365) |
| Superhuman (Grammarly → "Superhuman") | Auto Labels (preset; 10 personalizados no Business) | Summarize | AI Replies, Auto Drafts (Business), tom por destinatário | Ask AI (Business) | Auto Drafts | US$30 Starter / US$40 Business por mês | OpenAI, ZDR; Ask AI indexa os emails em fornecedor SOC 2 |
| Shortwave | Sim (detalhes não verificados) | Sim | Sim | Sim (principal diferencial do assistente) | — | Grátis, Pro US$18, Business US$30, Premier US$45, Max US$120 (subiu em jun/2026) | Nuvem; política não verificada |
| Notion Mail | AI labels por regras em linguagem natural | — | Notion AI | — | — | IA ilimitada no Business/Enterprise | **Encerra em 22/set/2026** |
| HEY | Screener (aprovação manual de primeiro remetente; não é IA) | — | — | — | — | não verificado | — |
| SaneBox | Triagem por IA com base em metadados (remetente, assunto, interação; não lê o corpo) | — | — | — | — | US$7/12/36 por mês | Funciona sobre servidor IMAP |
| Spark | Gatekeeper para primeiro remetente | não verificado | não verificado | não verificado | — | Tem plano grátis | não verificado |

## Quais recursos de IA são o mínimo esperado e quais diferenciam em 2026?

### Takeaway
Resumo de threads, rascunho assistido (help-me-write, respostas sugeridas, revisão) e categorização básica do inbox viraram o mínimo esperado. Gmail dá resumos e Help Me Write de graça e a Apple traz categorias e resumos no SO. O diferencial migrou para perguntas a todo o inbox com citações, rascunhos automáticos de fundo na voz do usuário, rótulos personalizados definidos por prompt e uma "visão de briefing" proativa. Esses recursos ficam atrás de planos de US$20 a US$40 por mês ou mais.

### Cited Findings
- Google lançou a "era Gemini" do Gmail em 8/jan/2026, sobre o Gemini 3. O rollout começou nos EUA em 9/jan, só em inglês, com outros idiomas e regiões prometidos para depois — [Let's Data Science](https://letsdatascience.com/news/google-integrates-gemini-3-ai-into-gmail-inbox-148c18ac); [CXO Digital Pulse](https://www.cxodigitalpulse.com/google-launches-gemini-era-of-gmail-with-ai-tools-to-simplify-inbox-management/)
- Os resumos de thread (AI Overviews) e as Personalized Suggested Replies são grátis para todos. As respostas de busca por IA (perguntas ao inbox) e o Proofread exigem Google AI Pro/Ultra — [Tom's Guide](https://www.tomsguide.com/ai/gmails-biggest-update-in-20-years-5-ai-features-that-could-change-email-forever)
- O AI Inbox do Gmail (visão priorizada com contas, compromissos, contatos frequentes e to-dos) estava "só para alguns testadores" segundo o Tom's Guide. Outro veículo diz que exige assinatura, então as fontes conflitam — [Tom's Guide](https://www.tomsguide.com/ai/gmails-biggest-update-in-20-years-5-ai-features-that-could-change-email-forever); [CXO Digital Pulse](https://www.cxodigitalpulse.com/google-launches-gemini-era-of-gmail-with-ai-tools-to-simplify-inbox-management/)
- O Apple Mail classifica mensagens em Primary, Transactions, Updates e Promotions, e os resumos de IA substituem o texto de preview — [Knak](https://knak.com/blog/apple-intelligence-ios18-2/); [emfluence](https://emfluence.com/blog/apple-ios-18-mail-app-updates-what-email-marketers-need-to-know)
- O Copilot no Outlook cobre resumos de thread com citações, rascunho e reescrita, coaching de tom, flags de prioridade, triagem e arquivamento em linguagem natural, e transformar uma thread em convite de reunião. O conjunto de recursos ficou "praticamente estável em 2026" e a mudança maior foi o preço — [usecarly](https://www.usecarly.com/blog/outlook-ai/); [Justin McKelvey](https://justinmckelvey.com/blog/copilot-for-outlook)
- Preço do Copilot: só como add-on de uma licença M365 qualificada. Copilot Business (≤300 usuários) custa US$18/usuário/mês no anual ou US$25,20 no mensal. O add-on Enterprise custa US$30. O Copilot Chat básico vem incluído, mas os recursos dentro da thread no Outlook exigem a licença paga — [eesel](https://eesel.ai/blog/copilot-pricing); [geotoolbox](https://geotoolbox.ai/blog/copilot-pricing.md)
- Uma universidade relatou que a licença do M365 Copilot caiu de US$360 para US$216 por usuário/ano em dez/2025 (preço educacional) — [CU Anschutz](https://www.cuanschutz.edu/offices/iss/iss-newsroom/oit-news-article/cu-anschutz-office-of-information-technology-newsroom-microsoft-365-copilot-license-price-drop)
- Superhuman: o Starter (US$30/mês, US$25 no anual) inclui AI Replies, Summarize, Auto Labels (só categorias preset) e Instant Reply. O Business (US$40/mês, US$33 no anual) acrescenta Auto Drafts, Ask AI, até 10 Auto Labels personalizados criados por prompt e CRM HubSpot/Salesforce. Não há plano grátis — [Fast.io review](https://www.fast.io/resources/superhuman-ai-review-2026.md); [aiproductivity.ai](https://aiproductivity.ai/pricing/superhuman/)
- Os Auto Labels do Superhuman marcam response needed, waiting on, meetings, marketing, cold pitches e social. Eles rotulam sem mover nem arquivar. Auto Labels e Auto Archive foram estendidos a todos os planos no 2º tri de 2025 — [Fast.io](https://www.fast.io/resources/superhuman-ai-review-2026.md); [PricingSaaS](https://pricingsaas.com/companies/superhuman/diffs/2025Q2)
- O Auto Drafts do Superhuman monitora o inbox e escreve rascunhos de resposta para follow-ups, mensagens recebidas e pedidos de agendamento, ajustando o tom por destinatário com base no histórico de enviados — [Fast.io](https://www.fast.io/resources/superhuman-ai-review-2026.md)
- A Grammarly comprou a Superhuman em jul/2025 (última avaliação de US$825M). Em out/2025 a Grammarly mudou de nome para Superhuman e lançou a Superhuman Suite (Grammarly, Coda, Mail, Go) — [Fast.io](https://www.fast.io/resources/superhuman-ai-review-2026.md)
- Shortwave: Free, Pro US$18, Business US$30, Premier US$45 e Max US$120 por assento/mês. Os preços subiram 20 a 29% em 30/jun/2026 e a cobrança passou a ser só mensal. Os planos se diferenciam por cota de IA, profundidade de histórico de busca e de threads, e não por recursos diferentes — [UsagePricing](https://usagepricing.com/blueprint/activity/shortwave-2026-06-30-price-change); [CostBench](https://www.costbench.com/software/ai-productivity/shortwave/); [PricingSaaS](https://pricingsaas.com/companies/shortwave)
- Notion Mail: AI labels a partir de regras em linguagem natural e "views" no lugar de pastas. Os recursos de IA podem ser testados de graça, mas o uso ilimitado exige o plano Business ou Enterprise. **O Notion Mail encerra em 22/set/2026** — [eesel 2026 overview](https://www.eesel.ai/en/blog/notion-mail-overview); [Notion help](https://www.notion.com/help/guides/organize-your-inbox-with-notion-ai-auto-labeling)
- SaneBox é uma camada de triagem por IA que usa remetente, assunto e padrões de interação, não o corpo da mensagem. Custa cerca de US$7/12/36 por mês, sem plano grátis. O SaneBlackHole bloqueia o remetente e faz unsubscribe silencioso — [Leave Me Alone (concorrente)](https://leavemealone.com/blog/best-sanebox-alternatives-2026/); [Hackceleration](https://hackceleration.com/labs/review/sanebox)
- HEY e Spark seguram o primeiro email de um remetente fora do inbox, num silo para triagem. O HEY Screener é um gatekeeper por decisão humana, não por IA — [The Sweet Setup](https://thesweetsetup.com/sanebox-blackhole-new-gatekeeper); [Toolradar](https://toolradar.com/compare/sanebox-vs-hey)

### Inferences
- Resumo e rascunho básico já são commodity: o Gmail dá de graça para bilhões de pessoas e a Apple embute no SO. Um cliente novo não consegue cobrar por esses recursos.
- O que ainda vende é "agir por mim com contexto": rascunhos de fundo na voz do usuário, perguntas ao inbox com citações e rótulos personalizados por prompt. Até os incumbentes cobram mais por isso (Gmail AI Pro, Superhuman Business, Copilot pago).
- O mercado de clientes independentes está se consolidando ou encolhendo: Notion Mail encerrado, Superhuman absorvido pela Grammarly, Shortwave aumentando preços. Isso sugere que o custo de inferência pesa na margem.
- O gatekeeping de primeiro remetente (HEY/Spark) e a triagem só por metadados (SaneBox) são opções de baixo custo e alta privacidade que funcionam sem LLM.

### Gaps
- Lista oficial e atual de recursos do Shortwave (agendamento, tarefas, provedor de modelo) e sua política de privacidade: não foram verificadas.
- Preços do HEY e recursos de IA do Spark em 2026: nenhuma fonte confiável encontrada.
- Mudanças no Apple Mail em iOS/macOS 26 (por exemplo, se há perguntas ao inbox ou extração de ações) não foram encontradas.
- Nenhum benchmark independente de precisão da categorização (Apple, Gmail, Superhuman, Notion).

## Do que os usuários reclamam na IA de email (precisão, privacidade, custo, UI intrusiva)?

### Takeaway
As reclamações se concentram em quatro pontos. Primeiro, resumos imprecisos, principalmente em threads encadeadas e em textos curtos. Segundo, IA ativada sem consentimento ou difícil de desligar. Terceiro, rascunhos automáticos desnecessários que ainda precisam de revisão. Quarto, custo alto: os melhores recursos ficam em planos de US$30 a US$45 ou mais e os preços subiram em 2026.

### Cited Findings
- Os resumos do Apple Mail "falham", especialmente em emails encadeados. Um usuário na Apple Community os chamou de imprecisos e inúteis — [Digital Trends](https://digitaltrends.com/?p=3815056); [Apple Community](https://discussions.apple.com/thread/256050273)
- Um usuário relatou que, com a Apple Intelligence desligada, os resumos continuaram aparecendo nas categorias Updates/Promotions no iOS 18.4.1, sem opção para desligar. É um relato único, de abr/2025, que não foi resolvido — [Apple Community](https://discussions.apple.com/thread/256050273)
- Profissionais de marketing temem que os resumos substituam o preview text e afetem a taxa de abertura — [emfluence](https://emfluence.com/blog/apple-ios-18-mail-app-updates-what-email-marketers-need-to-know); [Knak](https://knak.com/blog/apple-intelligence-ios18-2/)
- A Apple suspendeu os resumos de notificação de apps de notícias no iOS 18.3 (jan/2025) depois de manchetes falsas da BBC. Os resumos voltaram no iOS 26 com texto em itálico, o rótulo "Summarized by Apple Intelligence", o aviso "Summarization may change the meaning... Verify information" e um botão para reportar. A heise argumenta que o problema de fundo continua: há pouco texto de entrada — [Tom's Guide](https://www.tomsguide.com/ai/apple-intelligence/apple-intelligence-will-summarize-news-again-in-ios-26-after-false-headline-debacle); [9to5Mac](https://9to5mac.com/2025/07/24/heres-what-apple-intelligence-summarized-news-notifications-look-like-on-ios-26); [heise](https://heise.de/-10500053)
- Uma ação coletiva (nov/2025, San Jose) alega que o Google ativou "secretamente" o Gemini no Gmail, Chat e Meet sem consentimento, e que desligar exige navegar por várias camadas de configuração. O Google afirma que não treina modelos com emails pessoais e que o Gemini no Gmail não retém dados de email — [Quartz](https://qz.com/google-lawsuit-gemini-ai-read-private-emails); [Bloomberg Law](https://news.bloomberglaw.com/litigation/google-accused-in-suit-of-using-gemini-ai-tool-to-snoop-on-users)
- Há relatos de que o Gemini continua aparecendo no Gmail ou Drive depois de desligado — [Runbox blog](https://blog.runbox.com/tag/gemini)
- Precedente de alucinação: em 2023, a extensão Gmail do Bard inventou trocas de email inteiras que nunca aconteceram, nos testes de Kevin Roose — [Futurism](https://futurism.com/the-byte/google-gmail-tool-hallucinating-emails)
- O Auto Drafts do Superhuman escreve respostas para emails que não precisam de resposta (newsletters, notificações automáticas), então a revisão continua obrigatória. Não há plano grátis e o melhor da IA fica no plano de US$40. O app mobile fica atrás do desktop — [Fast.io](https://www.fast.io/resources/superhuman-ai-review-2026.md)
- Os números de tempo economizado do Superhuman ("4+ horas por semana", "30-40%") são autodeclarados — [Fast.io](https://www.fast.io/resources/superhuman-ai-review-2026.md)
- Custo: o Business do Superhuman subiu 32% no 3º tri de 2024 junto com novos recursos de IA. O Shortwave subiu 20 a 29% em jun/2026 — [PricingSaaS](https://pricingsaas.com/companies/superhuman/diffs/2024Q3); [UsagePricing](https://usagepricing.com/blueprint/activity/shortwave-2026-06-30-price-change)
- O Notion Mail foi criticado como um "wrapper" do Gmail, com views manuais e trabalhosas e a criptografia ponta a ponta do Skiff abandonada após a aquisição — [eesel 2025 review](https://www.eesel.ai/blog/notion-mail-reviews)
- O Unroll.me (unsubscribe grátis) pertence à NielsenIQ e lucra minerando dados do inbox, um exemplo clássico de problema de confiança — [Leave Me Alone](https://leavemealone.com/unroll-me-vs-sanebox/)

### Inferences
- Confiança se ganha com três coisas: controles de opt-in e opt-out visíveis dentro do app, rotulagem de conteúdo gerado por IA e links para a fonte (citações). O padrão de rótulo, aviso e reporte que a Apple adotou no iOS 26 e as citações do Copilot e do Superhuman Ask AI apontam para essa direção.
- Recursos agênticos que agem sem perguntar (rascunhos automáticos) geram ruído. Faz sentido limitá-los às threads classificadas como "precisa de resposta".

### Gaps
- Não encontrei threads do Reddit ou HN com críticas específicas ao Superhuman, Shortwave ou Copilot no Outlook. A busca não trouxe resultados.
- Nenhum dado quantitativo de satisfação ou adoção (por exemplo, % de usuários que desligam os resumos).

## Opções no dispositivo em plataformas Apple vs. APIs de LLM na nuvem: tradeoffs para um cliente de email

### Takeaway
O framework Foundation Models da Apple dá acesso gratuito, offline e privado a um LLM de cerca de 3B parâmetros no dispositivo, com geração guiada (structured output tipado) e tool calling. A janela de contexto é de apenas ~4.096 tokens por sessão, somando entrada e saída. Isso serve bem para classificar e extrair dados de um email, mas não para resumir threads longas ou responder perguntas sobre o inbox todo. Esses casos exigem chunking ou LLMs na nuvem (Claude, OpenAI), com o custo e o problema de privacidade de enviar o corpo dos emails para terceiros, mitigado por contratos de ZDR.

### Cited Findings
- A janela de contexto do Foundation Models é de 4.096 tokens por sessão e inclui instruções, prompt e resposta. Estourar o limite lança `.exceededContextWindowSize` e exige abrir uma nova sessão — [Apple TN3193](https://developer.apple.com/tutorials/data/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window.md); [InfoQ](https://infoq.com/news/2026/03/apple-foundation-models-context)
- A resposta pode falhar mesmo com a entrada um pouco abaixo do limite, porque a saída também conta. A Apple diz que o limite é "por volta de 4.000" e sem garantia de que se mantenha entre versões ou dispositivos — [Apple Developer Forums](https://developer.apple.com/forums/thread/790736); [Apple Developer Forums](https://developer.apple.com/forums/thread/800238)
- O iOS 26.4 adicionou `contextSize` em `SystemLanguageModel` e `tokenCount(for:)` para medir a entrada — [InfoQ](https://infoq.com/news/2026/03/apple-foundation-models-context)
- Desenvolvedores recomendam não contar com o modelo para resumir textos longos e quebrar a entrada em pedaços. Relatam também que recursos que funcionam na demo quebram no app publicado — [Natasha The Robot](https://www.natashatherobot.com/p/apple-foundation-models); [drobinin](https://drobinin.com/consulting/foundation-models-apple-intelligence/putting-apple-foundation-models-in-a-real-app/)
- Privacidade na nuvem (exemplo do Superhuman): os recursos de IA usam uma "mixture of models from OpenAI" sob acordo de Zero Data Retention. Com o Ask AI ativado, os emails ficam armazenados e indexados num fornecedor terceiro SOC 2, criptografados em trânsito e em repouso. Queries do Write with AI, Instant Reply e Auto Summarize não são armazenadas — [Superhuman Help](https://help.superhuman.com/article/555-superhuman-ai-tutorial)
- Em ago/2026, a OpenAI anunciou ZDR para os modelos mais capazes em clientes business — [TechCrunch](https://techcrunch.com/2026/08/19/openai-seeks-to-one-up-anthropic-with-new-customer-privacy-protections/)
- Em 2026, a Anthropic retém prompts e saídas de alguns modelos cobertos por 30 dias para trabalho de segurança. Clientes com ZDR passarão a precisar hospedar os dados em servidores próprios ou em clouds específicas (programa "Enterprise Frontier Safeguards") — [DeepLearning.AI The Batch](https://www.deeplearning.ai/the-batch/comparing-openai-and-anthropics-data-retention-policies); [Techzine](https://www.techzine.eu/news/applications/143746/anthropic-lets-companies-store-ai-data-in-their-own-cloud/). Ponto crítico: confira os termos atuais diretamente com a Anthropic antes de projetar o produto.
- O Gmail e o Superhuman resolvem perguntas ao inbox com indexação no servidor, ou seja, os emails ficam armazenados fora do provedor de email no caso do Superhuman — [Superhuman Help](https://help.superhuman.com/article/555-superhuman-ai-tutorial)

### Inferences
- Arquitetura híbrida sugerida para um cliente Apple-first:
  - **No dispositivo (Foundation Models):** classificação e categoria por email, extração de entidades e ações (datas, valores, to-dos) com `@Generable`, detecção de "precisa de resposta" e sinais de urgência e golpe. Tudo grátis, offline e sem enviar dados.
  - **Busca semântica local:** embeddings no dispositivo (Core ML / NaturalLanguage / MLX) com índice vetorial local, para perguntas ao inbox sem servidor.
  - **Nuvem com opt-in explícito (Claude, OpenAI):** resumo de threads longas, rascunhos na voz do usuário e respostas sobre o inbox todo que ultrapassem ~4k tokens. Use ZDR e mostre a divulgação "enviado para X".
- O limite de ~4k tokens e a exigência de hardware compatível com Apple Intelligence (iPhone 15 Pro ou mais novo, Macs com Apple silicon) obrigam a ter fallback para a nuvem ou um modo degradado em Macs Intel e iPhones antigos.
- O MLX permite rodar modelos abertos maiores (por exemplo, 7–8B quantizados) em Macs com Apple silicon, com contexto maior. O custo é RAM, tamanho do download e bateria. Isso é inferência, não verifiquei nesta pesquisa.
- O custo marginal zero da IA no dispositivo é uma vantagem estrutural contra Superhuman e Shortwave, cujos preços sobem com a cota de IA.

### Gaps
- A página do Foundation Models não renderizou pelo WebFetch. Os detalhes de ~3B parâmetros, tool calling, `@Generable` e requisitos de hardware vêm de conhecimento geral e de blogs, não de leitura direta. Confirme na documentação da Apple.
- Benchmarks de MLX e Core ML (latência, memória) para modelos de email não foram pesquisados.
- Idiomas suportados pelo Foundation Models (por exemplo, pt-BR) não foram verificados.
- Política atual de retenção da API do Claude para apps de consumidor: as fontes são secundárias e recentes (ago/2026), e os nomes de modelos citados nelas não foram verificados.

## Validação de emails: spoofing/phishing, exibição de SPF/DKIM/DMARC, BIMI e detecção de golpe por IA

### Takeaway
O BIMI exige DMARC em modo de enforcement (p=quarantine ou p=reject). Gmail e Apple Mail exibem o logo, mas o selo azul de verificado do Gmail exige um VMC. O Outlook não tinha adotado BIMI até meados de 2026. A detecção de golpe por LLM funciona muito bem em pesquisa (~99% em datasets e explica o veredito), mas o phishing gerado por IA desmonta as heurísticas antigas, como erros de ortografia. Nenhum cliente principal de consumo expõe de forma clara SPF/DKIM/DMARC junto com uma explicação de IA, e isso é uma oportunidade.

### Cited Findings
- O BIMI só funciona com DMARC em enforcement (p=quarantine ou p=reject, não p=none) — [Sectigo](https://www.sectigo.com/blog/gmail-blue-checkmark-bimi-requirements); [Loops](https://loops.so/glossary/bimi)
- O Gmail exibe o selo azul de verificado para remetentes autenticados por VMC. Segundo uma fonte, implementações só com CMC mostram o avatar da marca sem o selo. Outra fonte sugere que VMC ou CMC bastam, então há conflito — [Encryption Consulting](https://www.encryptionconsulting.com/bimi-with-vmc-and-cmc/); [Sectigo](https://www.sectigo.com/blog/gmail-blue-checkmark-bimi-requirements); [Red Sift](https://redsift.com/blog/gmail-expands-bimi-indicators-to-include-a-verified-icon)
- O Apple Mail suporta BIMI a partir do iOS 16 e do macOS Ventura — [Encryption Consulting](https://www.encryptionconsulting.com/bimi-with-vmc-and-cmc/)
- O Microsoft Outlook não adotou BIMI até meados de 2026 — [Encryption Consulting](https://www.encryptionconsulting.com/bimi-with-vmc-and-cmc/)
- As falhas da cadeia BIMI são silenciosas: o dono do domínio não recebe erro — [Encryption Consulting](https://www.encryptionconsulting.com/bimi-with-vmc-and-cmc/)
- Pesquisa: o ChatSpamDetector (GPT-4) chegou a 99,70% de acurácia num dataset de teste, explica o veredito e detecta domínios parecidos com os legítimos e encurtadores de URL — [arXiv 2402.18093](https://arxiv.org/pdf/2402.18093)
- APOLLO: pedir ao modelo que procure "intenção maliciosa" em vez de "intenção genérica" melhorou a detecção sem aumentar os falsos positivos. A ferramenta também gera explicações de alerta para o usuário — [arXiv 2410.07997](https://arxiv.org/pdf/2410.07997)
- Phishing reescrito por LLM degrada os detectores atuais — [arXiv 2411.13874](https://arxiv.org/html/2411.13874v1)
- Um fornecedor afirma que phishing gerado por IA tem CTR mais de 4x maior que o feito por humanos. É um dado de fornecedor, não verificado — [Bolster](https://bolster.ai/blog/ai-phishing-detection-platforms)
- A dica de "procurar erros de ortografia" está ficando obsoleta. A recomendação agora é verificar o domínio, inspecionar links e confirmar por canal oficial — [IsThisAScam](https://isthisascam.to/blog/ai-phishing-emails-2026)

### Inferences
- Um cliente diferenciado pode montar um "painel de confiança do remetente" a partir dos headers Authentication-Results/ARC (SPF/DKIM/DMARC pass/fail), do BIMI/VMC, de domínios parecidos e de "primeira vez que esse remetente escreve". Uma explicação gerada por LLM no dispositivo ("por que isso parece golpe") completa o painel. Os headers de autenticação já estão na mensagem, então isso é viável sem servidor.
- Os falsos positivos precisam ser baixos e explicáveis. Seguindo o APOLLO, mostre o motivo e não só um badge.

### Gaps
- Recursos oficiais e atuais de alerta de golpe por IA do Gmail e do Outlook (por exemplo, banners Gemini/Defender), além do Microsoft Defender for Office 365: a busca não trouxe fontes primárias.
- Se a Apple exibe algum selo de verificado próprio no Mail: as fontes só mencionam "digitally verified" de passagem.
- Nenhuma pesquisa encontrada sobre quanto usuários entendem ou confiam em indicadores SPF/DKIM exibidos na interface.
- Gerenciamento de newsletters e unsubscribe (por exemplo, "Manage subscriptions" no Gmail, unsubscribe em um clique na Apple): só cobri SaneBox, Clean Email (~US$2,50/mês no anual) e Unroll.me, via [Leave Me Alone](https://leavemealone.com/blog/best-sanebox-alternatives-2026/). Os recursos nativos de Gmail e Apple não foram verificados.
- Assistentes agênticos de agendamento (por exemplo, o Gemini propondo horários, scheduling no Copilot) além de "thread vira convite" e Auto Drafts: sem fontes primárias.
