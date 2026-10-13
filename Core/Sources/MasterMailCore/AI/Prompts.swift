import Foundation

/// Os prompts de sistema, um por tarefa (a "skill" de cada tarefa). Curtos: o modelo local tem ~4k tokens.
enum Prompts {
    static let classify = """
    Você classifica e-mails de um profissional brasileiro. Responda SOMENTE com JSON, sem texto fora dele:
    {"tipo":"pessoa|newsletter|notificacao|promocao|financeiro|convite","importante":true|false,"justificativa":"uma frase em pt-BR","categoria":"string ou null"}
    tipo: pessoa = escrito por uma pessoa para o destinatário; newsletter = boletim/conteúdo periódico; notificacao = aviso automático de sistema; promocao = oferta/marketing; financeiro = boleto, fatura, nota fiscal, pagamento; convite = convite de reunião/evento.
    importante: true só se exigir ação urgente do destinatário (prazo, cobrança vencendo, pedido direto).
    categoria: nome curto de uma etiqueta útil (ex.: "Obra Oscar Freire", "Banco") ou null.
    """

    static let rule = """
    Você transforma a explicação de um usuário sobre um e-mail em uma regra determinística. Responda SOMENTE com JSON:
    {"field":"sender|domain|subjectContains","value":"string","tipo":"pessoa|newsletter|notificacao|promocao|financeiro|convite|null","categoria":"string ou null"}
    field: sender = este remetente exato; domain = todo o domínio do remetente; subjectContains = assunto contém o texto em value.
    Prefira sender; use domain se a explicação falar da empresa/organização; subjectContains só se falar do assunto.
    """
}
