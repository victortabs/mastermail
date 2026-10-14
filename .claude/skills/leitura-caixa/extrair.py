#!/usr/bin/env python3
"""Puxa mensagens recebidas do Índice local, limpa o texto e aplica as Regras do perfil.

Saída (JSONL, uma mensagem por linha):
  lote.jsonl       mensagens que precisam do modelo (texto limpo + dicas)
  resolvidos.jsonl mensagens resolvidas por Regra, já no formato da classificação

Uso:
  extrair.py                      # desde a última execução (estado.json)
  extrair.py --desde 2026-10-01   # janela explícita
  extrair.py --ids ids.txt        # só esses ids (para comparar com o gabarito)
  extrair.py --teste              # roda as verificações internas
"""
import argparse, json, os, re, sqlite3, sys, unicodedata
from datetime import datetime

AQUI = os.path.dirname(os.path.abspath(__file__))
RAIZ = os.path.abspath(os.path.join(AQUI, "..", "..", ".."))
PRIV = os.path.join(RAIZ, "private-data", "caixa")
DB = os.path.expanduser("~/Library/Application Support/MasterMail/mail.sqlite")
LIMITE = 1500

# Pastas do servidor fora da leitura: Enviados, Rascunhos (sufixo do id do Graph).
FORA = ("EJAAA=", "EPAAA=")

# Onde começa o histórico citado de uma resposta/encaminhamento.
CITACAO = re.compile(
    r"(\bDe: .{0,120}?(Enviad[ao]( em)?|Data|Sent):|\bFrom: .{0,120}?(Sent|Date):|"
    r"\bEm .{5,80}? escreveu:|\bOn .{5,80}? wrote:|-----\s*(Mensagem original|Original Message|Compromisso original)|"
    r"_{20,}\s*Reunião do Microsoft Teams|Obter o Outlook para (iOS|Android))",
    re.I | re.S)
# Lixo que não ajuda a classificar.
LIXO = [
    re.compile(r"Atenção: O domínio \S+ deixará de funcionar.*?domínio \S+", re.I | re.S),
    re.compile(r"THIS E-MAIL IS INTENDED ONLY.*", re.I | re.S),
    re.compile(r"\b(Atenciosamente|Att|Abs|Cordialmente)\b[,.]?\s.*$", re.S),
]


# Contrato e assinatura nunca são resolvidos por Regra: um erro aqui custa caro (decisão de 2026-10-14).
SEMPRE_MODELO = re.compile(r"contrato|minuta|assinatura|assinar|aditivo|distrato|procura[cç][aã]o|notifica[cç][aã]o extrajudicial", re.I)


def sem_acento(s):
    return "".join(c for c in unicodedata.normalize("NFD", s or "") if unicodedata.category(c) != "Mn").lower()


def limpar(corpo):
    """Texto novo da mensagem, sem histórico citado nem assinatura. Se o novo é só 'Segue', traz um pedaço do citado."""
    t = re.sub(r"\s+", " ", corpo or "").strip()
    m = CITACAO.search(t)
    novo, citado = (t[:m.start()], t[m.start():]) if m else (t, "")
    for r in LIXO:
        novo = r.sub("", novo)
    novo = novo.strip()
    if len(novo) < 80 and citado:
        novo = (novo + " [encaminhado:] " + citado[:700]).strip()
    return novo[:LIMITE]


def carregar_perfil(caminho):
    if not os.path.exists(caminho):
        sys.exit(f"Perfil não encontrado: {caminho}. Crie a partir de perfil.exemplo.json.")
    p = json.load(open(caminho))
    p["_donos"] = {e.lower() for e in p["dono"]["enderecos"]}
    p["_obras"] = [(o["chave"], [sem_acento(a) for a in [o["chave"]] + o.get("apelidos", [])]) for o in p.get("obras", [])]
    return p


def regra_para(msg, perfil):
    """Primeira Regra que casa, ou None. Campos: remetente, dominio, assunto (regex), dominio+assunto."""
    de, dom, assunto = msg["de"], msg["dominio"], msg["assunto"]
    if SEMPRE_MODELO.search(assunto) or any(dom == d or dom.endswith("." + d) for d in perfil.get("sempre_modelo", [])):
        return None
    for r in perfil.get("regras", []):
        if "remetente" in r and r["remetente"] != de:
            continue
        if "dominio" in r and not (dom == r["dominio"] or dom.endswith("." + r["dominio"])):
            continue
        if "assunto" in r and not re.search(r["assunto"], assunto, re.I):
            continue
        if not any(k in r for k in ("remetente", "dominio", "assunto")):
            continue
        return r
    return None


def obra_provavel(msg, perfil):
    alvo = sem_acento(msg["assunto"] + " " + msg["texto"][:300])
    for chave, apelidos in perfil["_obras"]:
        if any(a and a in alvo for a in apelidos):
            return chave
    return None


def para_mim(msg, perfil, dest):
    """direto | copia. O Índice junta Para e Cc; aproximação: único destinatário ou citado no início do texto."""
    nomes = [sem_acento(n) for n in perfil["dono"].get("chamado_de", [])]
    inicio = sem_acento(msg["texto"][:160])
    if len(dest) == 1 and dest[0] in perfil["_donos"]:
        return "direto"
    if any(re.search(rf"(^|[@\s,]){re.escape(n)}\b", inicio) for n in nomes):
        return "direto"
    return "copia"


def ler(db, desde=None, ate=None, ids=None):
    con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
    con.row_factory = sqlite3.Row
    sql = ("select id, folder, receivedAt, fromName, fromAddress, recipients, subject, hasAttachments, "
           "conversationId, bodyText from message where 1=1")
    args = []
    if ids:
        sql += f" and id in ({','.join('?' * len(ids))})"
        args += ids
    else:
        if desde:
            sql += " and receivedAt >= ?"; args.append(desde)
        if ate:
            sql += " and receivedAt < ?"; args.append(ate)
    sql += " order by receivedAt"
    for r in con.execute(sql, args):
        if r["folder"].endswith(FORA):
            continue
        yield r


def montar(r, perfil):
    de = (r["fromAddress"] or "").lower()
    dest = [e.lower() for e in re.findall(r"<([^>]+)>", r["recipients"] or "")]
    msg = {
        "id": r["id"], "data": r["receivedAt"][:16], "conversa": r["conversationId"],
        "de": de, "dominio": de.split("@")[-1], "nome": r["fromName"],
        "interno": de.split("@")[-1] == perfil["empresa_dominio"],
        "assunto": r["subject"], "anexo": bool(r["hasAttachments"]),
        "n_destinatarios": len(dest), "texto": limpar(r["bodyText"]),
    }
    msg["para_mim"] = para_mim(msg, perfil, dest)
    msg["obra_provavel"] = obra_provavel(msg, perfil)
    return msg


def contexto(perfil):
    """Texto curto que o modelo lê antes do lote: dono, equipe e Obras."""
    d = perfil["dono"]
    linhas = [f"DONO DA CAIXA: {d['nome']} ({', '.join(d['enderecos'])}). {d['papel']}", "", "EQUIPE INTERNA:"]
    linhas += [f"- {e['nome']} <{e['email']}>: {e['papel']}" for e in perfil.get("equipe", [])]
    linhas += ["", "PARCEIROS:"] + [f"- {k}: {v}" for k, v in perfil.get("parceiros", {}).items()]
    linhas += ["", "OBRAS (use a chave exata):"]
    linhas += [f"- {o['chave']} | {o.get('cliente', '')} | {o.get('status', '')}" for o in perfil.get("obras", [])]
    return "\n".join(linhas) + "\n"


def resolvido(msg, regra):
    c = {k: regra.get(k) for k in ("tipo", "etapa", "acao", "quem")}
    c.update(id=msg["id"], obra=msg["obra_provavel"], prazo=None, importante=False,
             resumo=msg["assunto"][:120], justificativa=f"Regra: {regra.get('nota', 'perfil')}", origem="regra")
    c["acao"] = c["acao"] or "nenhuma"
    c["quem"] = c["quem"] or "ninguem"
    return c


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--desde"); ap.add_argument("--ate"); ap.add_argument("--ids")
    ap.add_argument("--perfil", default=os.path.join(PRIV, "perfil.json"))
    ap.add_argument("--saida", default=os.path.join(PRIV, "trabalho"))
    ap.add_argument("--db", default=DB)
    ap.add_argument("--teste", action="store_true")
    a = ap.parse_args()
    if a.teste:
        return teste()

    perfil = carregar_perfil(a.perfil)
    estado_p = os.path.join(PRIV, "estado.json")
    ids = [l.strip() for l in open(a.ids) if l.strip()] if a.ids else None
    desde = a.desde
    if not desde and not ids:
        desde = json.load(open(estado_p))["ultimo"] if os.path.exists(estado_p) else None
        if not desde:
            sys.exit("Primeira execução: informe --desde AAAA-MM-DD.")

    os.makedirs(a.saida, exist_ok=True)
    open(os.path.join(a.saida, "contexto.txt"), "w").write(contexto(perfil))
    open(os.path.join(a.saida, "classificado.jsonl"), "w").close()
    lote = open(os.path.join(a.saida, "lote.jsonl"), "w")
    res = open(os.path.join(a.saida, "resolvidos.jsonl"), "w")
    n_lote = n_res = 0
    ultimo = desde
    for r in ler(a.db, desde, a.ate, ids):
        msg = montar(r, perfil)
        ultimo = max(ultimo or "", r["receivedAt"])
        if msg["de"] in perfil["_donos"]:
            continue  # cópia de algo que o próprio dono mandou para si
        regra = regra_para(msg, perfil)
        if regra:
            res.write(json.dumps(resolvido(msg, regra), ensure_ascii=False) + "\n"); n_res += 1
        else:
            lote.write(json.dumps(msg, ensure_ascii=False) + "\n"); n_lote += 1
    if not ids:
        json.dump({"ultimo": ultimo, "em": datetime.now().isoformat(timespec="seconds")}, open(estado_p, "w"))
    print(json.dumps({"para_o_modelo": n_lote, "resolvidas_por_regra": n_res, "pasta": a.saida}))


def teste():
    t = limpar("Fulano, segue o orçamento revisado com a retirada do gradil e o piso novo da guarita. Atenciosamente Eng. Beltrano De: Ana <a@x.com> Enviada em: terça Assunto: RE: x texto velho")
    assert t == "Fulano, segue o orçamento revisado com a retirada do gradil e o piso novo da guarita.", t
    t = limpar("Segue De: Portal <c@x.com> Enviada em: segunda Para: Ciclano Assunto: Evento 4180 Convite")
    assert t.startswith("Segue [encaminhado:] De: Portal"), t
    p = {"empresa_dominio": "x.com", "dono": {"enderecos": ["eu@x.com"], "chamado_de": ["fulano"]},
         "obras": [{"chave": "Loja Centro", "apelidos": ["loja centro"]}],
         "regras": [{"dominio": "docusign.net", "assunto": "^(Concluído|Recusado)", "tipo": "notificacao"},
                    {"dominio": "docusign.net", "assunto": "Complete com|Assinar", "tipo": "notificacao", "acao": "assinar", "quem": "eu"}]}
    p["_donos"] = {"eu@x.com"}; p["_obras"] = [("Loja Centro", ["loja centro"])]
    m = {"de": "dse@docusign.net", "dominio": "docusign.net", "assunto": "Complete com o Docusign: Contrato Loja Centro", "texto": ""}
    assert regra_para(m, p) is None  # contrato vai sempre para o modelo
    m["assunto"] = "Concluído: Complete com o Docusign: X"
    assert "acao" not in regra_para(m, p)
    p["sempre_modelo"] = ["docusign.net"]
    assert regra_para(m, p) is None
    assert obra_provavel({"assunto": "OBRA LOJA CENTRO - CRONOGRAMA", "texto": ""}, p) == "Loja Centro"
    assert para_mim({"texto": "@Fulano de Tal, bom dia"}, p, ["a@x.com", "eu@x.com"]) == "direto"
    assert para_mim({"texto": "Ana, segue a NF"}, p, ["a@x.com", "eu@x.com"]) == "copia"
    print("ok")


if __name__ == "__main__":
    main()
