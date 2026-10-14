#!/usr/bin/env python3
"""Junta resolvidos.jsonl + classificado.jsonl e imprime o resumo da caixa; ou compara com um gabarito.

Uso:
  relatorio.py                          # resumo em markdown (também grava resumo-AAAA-MM-DD.md)
  relatorio.py --comparar gabarito.jsonl --pasta <pasta com classificado.jsonl>
"""
import argparse, collections, json, os
from datetime import date

AQUI = os.path.dirname(os.path.abspath(__file__))
PRIV = os.path.abspath(os.path.join(AQUI, "..", "..", "..", "private-data", "caixa"))
RUIDO = {"newsletter", "notificacao", "promocao"}


def ler(caminho):
    if not os.path.exists(caminho):
        return []
    return [json.loads(l) for l in open(caminho) if l.strip()]


def para_voce(c):
    return c.get("quem") == "eu" and c.get("acao") not in (None, "nenhuma")


def resumo(pasta):
    lote = {m["id"]: m for m in ler(os.path.join(pasta, "lote.jsonl"))}
    cls = ler(os.path.join(pasta, "resolvidos.jsonl")) + ler(os.path.join(pasta, "classificado.jsonl"))
    faltam = set(lote) - {c["id"] for c in cls}
    out = [f"# Caixa — {date.today():%d/%m/%Y}", ""]
    if faltam:
        out.append(f"> {len(faltam)} mensagens do lote ainda sem classificação.\n")

    agir = sorted([c for c in cls if para_voce(c)], key=lambda c: (not c.get("importante"), c.get("prazo") or "9999"))
    out.append(f"## Com você ({len(agir)})")
    for c in agir:
        marca = "**!** " if c.get("importante") else ""
        prazo = f" — até {c['prazo'][8:10]}/{c['prazo'][5:7]}" if c.get("prazo") else ""
        out.append(f"- {marca}[{c.get('acao')}] {c.get('obra') or 'sem obra'}: {c.get('resumo')}{prazo}")

    pedidos = [c for c in cls if c.get("fase") == "pedido"]
    if pedidos:
        out.append(f"\n## Pedidos de orçamento novos ({len(pedidos)})")
        out += [f"- {c.get('obra') or 'sem obra'}: {c.get('resumo')}" for c in pedidos]
    resultados = [c for c in cls if c.get("fase") in ("ganho", "perdido")]
    if resultados:
        out.append(f"\n## Resultado de concorrência ({len(resultados)})")
        out += [f"- {'GANHOU' if c['fase'] == 'ganho' else 'perdeu'} {c.get('obra') or 'sem obra'}: {c.get('resumo')}" for c in resultados]

    alerta = [c for c in cls if c.get("importante") and not para_voce(c) and c.get("fase") not in ("ganho", "perdido")]
    if alerta:
        out.append(f"\n## Atenção, com a equipe ({len(alerta)})")
        for c in alerta:
            out.append(f"- {c.get('obra') or 'sem obra'}: {c.get('resumo')} ({c.get('quem')})")

    trabalho = [c for c in cls if c.get("tipo") not in RUIDO and not para_voce(c) and not c.get("importante")]
    por_obra = collections.defaultdict(collections.Counter)
    for c in trabalho:
        por_obra[c.get("obra") or "sem obra"][c.get("etapa") or "?"] += 1
    out.append(f"\n## Para ciência, por Obra ({len(trabalho)})")
    for obra, et in sorted(por_obra.items(), key=lambda x: -sum(x[1].values())):
        out.append(f"- {obra}: " + ", ".join(f"{n} {e}" for e, n in et.most_common()))

    ruido = collections.Counter(c["tipo"] for c in cls if c.get("tipo") in RUIDO)
    out.append(f"\n## Ruído ({sum(ruido.values())}): " + ", ".join(f"{n} {t}" for t, n in ruido.most_common()))
    texto = "\n".join(out)
    open(os.path.join(PRIV, f"resumo-{date.today():%Y-%m-%d}.md"), "w").write(texto)
    print(texto)


def comparar(gabarito, pasta):
    g = {c["id"]: c for c in ler(gabarito)}
    m = {c["id"]: c for c in ler(os.path.join(pasta, "classificado.jsonl"))}
    campos = {
        "tipo": lambda c: c.get("tipo"),
        "obra": lambda c: c.get("obra"),
        "etapa": lambda c: c.get("etapa"),
        "com você": para_voce,
        "importante": lambda c: bool(c.get("importante")),
        "prazo": lambda c: c.get("prazo"),
    }
    ids = [i for i in g if i in m]
    print(f"{len(ids)} de {len(g)} mensagens do gabarito classificadas\n")
    erros = collections.defaultdict(list)
    for nome, f in campos.items():
        ok = 0
        for i in ids:
            if f(g[i]) == f(m[i]):
                ok += 1
            else:
                erros[nome].append((g[i].get("_assunto", i)[:60], f(g[i]), f(m[i])))
        print(f"{nome:11} {ok:3}/{len(ids)}  {100 * ok // max(len(ids), 1)}%")
    # O erro que mais custa: algo que é com você e ficou de fora.
    perdidos = [i for i in ids if para_voce(g[i]) and not para_voce(m[i])]
    print(f"\nperdidos (era com você, modelo não marcou): {len(perdidos)}")
    for nome, lst in erros.items():
        print(f"\n### {nome}")
        for assunto, esperado, veio in lst:
            print(f"- {assunto} | gabarito={esperado} | modelo={veio}")


def teste():
    assert para_voce({"quem": "eu", "acao": "responder"})
    assert not para_voce({"quem": "eu", "acao": "nenhuma"})
    assert not para_voce({"quem": "equipe", "acao": "aprovar"})
    print("ok")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--pasta", default=os.path.join(PRIV, "trabalho"))
    ap.add_argument("--comparar")
    ap.add_argument("--teste", action="store_true")
    a = ap.parse_args()
    if a.teste:
        teste()
    elif a.comparar:
        comparar(a.comparar, a.pasta)
    else:
        resumo(a.pasta)
