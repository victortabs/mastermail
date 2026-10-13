# Docs de domínio

Como os skills de engenharia devem usar a documentação de domínio deste repo ao explorar o código.

## Antes de explorar, leia

- **`CONTEXT.md`** na raiz do repo (glossário do domínio).
- **`docs/decisoes/`**: as ADRs do projeto. Leia as que tocam a área em que você vai mexer.
- **`docs/00-visao.md`, `docs/01-requisitos.md`, `docs/02-arquitetura.md`**: visão, requisitos e arquitetura da fase de planejamento.

Se algum desses arquivos não existir, **siga em silêncio**. Não aponte a ausência nem sugira criá-los de antemão. O skill `/domain-modeling` (via `/grill-with-docs` e `/improve-codebase-architecture`) cria esses arquivos sob demanda, quando termos ou decisões são de fato resolvidos.

## Estrutura

Repo de contexto único:

```
/
├── CONTEXT.md
└── docs/
    └── decisoes/
        ├── 0000-modelo.md          ← modelo de ADR
        ├── 0001-plataforma-macos.md
        └── ...
```

## ADRs novas

- Ficam em `docs/decisoes/`, numeradas em sequência (`NNNN-titulo-curto.md`).
- Seguem o formato de `docs/decisoes/0000-modelo.md`: Data, Status, Contexto, Opções consideradas, Decisão, Consequências.
- Escritas em português (pt-BR).

## Use o vocabulário do glossário

Quando sua saída nomear um conceito do domínio (título de issue, proposta de refatoração, hipótese, nome de teste), use o termo como definido no `CONTEXT.md`. Não troque por sinônimos que o glossário evita.

Se o conceito não estiver no glossário, isso é um sinal: ou você está inventando linguagem que o projeto não usa (reconsidere), ou há uma lacuna real (anote para o `/domain-modeling`).

## Sinalize conflitos com ADRs

Se sua saída contradisser uma ADR existente, diga isso explicitamente em vez de passar por cima:

> _Contradiz a ADR-0003 (Microsoft Graph + MSAL), mas vale reabrir porque…_
