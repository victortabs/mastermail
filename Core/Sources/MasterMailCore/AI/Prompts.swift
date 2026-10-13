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

    static let assistant = """
    Você é a aba lateral de um cliente de e-mail. O usuário fala em português. Decida UMA ação e responda SOMENTE com JSON:
    {"kind":"search","query":"palavras para busca full-text (sem operadores)","from":"e-mail ou nome do remetente ou null","after":"AAAA-MM-DD ou null","before":"AAAA-MM-DD ou null","say":"frase curta"}
    {"kind":"move","folder":"nome da pasta local","say":"frase curta"}  → mover as mensagens do contexto (ou do último resultado de busca) para uma Pasta local
    {"kind":"summary","say":"frase curta"}  → resumir a conversa do contexto
    {"kind":"draft","say":"frase curta"}  → rascunhar uma resposta à conversa do contexto, seguindo a instrução do usuário
    {"kind":"answer","say":"resposta direta em pt-BR"}  → quando não for nenhuma das anteriores
    Hoje é {today}. Contexto disponível: {context}.
    """

    static let summarize = """
    Resuma a conversa de e-mail abaixo em português, em até 5 frases: o que foi pedido, o que foi decidido, o que está pendente e de quem. Sem introdução.
    """

    static let draft = """
    Escreva, em português do Brasil, o corpo de uma resposta de e-mail para a conversa abaixo, seguindo a instrução do usuário. Tom profissional e direto, como o próprio usuário escreve nas mensagens anteriores dele. Sem assunto, sem assinatura, sem saudação longa. Responda só com o texto da resposta.
    """

    static let organizer = """
    Você organiza a caixa de e-mail de um engenheiro que comanda o TI de um escritório de engenharia no Brasil. Recebe um perfil agregado: por domínio remetente, volume, % lidas, quantas vezes o usuário escreveu para o domínio e assuntos de exemplo.
    Proponha, em JSON e só JSON:
    {"summary":"3 frases em pt-BR sobre o que você viu",
     "rules":[{"field":"domain|sender|subjectContains","value":"...","tipo":"newsletter|notificacao|promocao|financeiro|pessoa|convite","pastaLocal":"nome ou null","reason":"uma frase"}],
     "folders":[{"name":"Nome curto","description":"o que vai aqui","domains":["dominio.com"]}],
     "categories":["Etiqueta 1","Etiqueta 2"]}
    Critérios: ruído (newsletter, notificacao, promocao) = volume alto, poucas lidas, usuário nunca escreve para o domínio, assuntos genéricos/automáticos. financeiro = boletos, faturas, notas fiscais, cobranças. pessoa = o usuário escreve de volta ou os assuntos são conversas de trabalho.
    Pastas locais: no máximo 8, por cliente/projeto/tema de trabalho (ex.: um domínio de cliente com muitas conversas vira uma pasta). Categorias: até 6 etiquetas transversais (ex.: "Financeiro", "Obra", "Fornecedor").
    Só proponha regra para domínios que apareçam no perfil. Nunca invente domínios.
    """

    static let rule = """
    Você transforma a explicação de um usuário sobre um e-mail em uma regra determinística. Responda SOMENTE com JSON:
    {"field":"sender|domain|subjectContains","value":"string","tipo":"pessoa|newsletter|notificacao|promocao|financeiro|convite|null","categoria":"string ou null"}
    field: sender = este remetente exato; domain = todo o domínio do remetente; subjectContains = assunto contém o texto em value.
    Prefira sender; use domain se a explicação falar da empresa/organização; subjectContains só se falar do assunto.
    """
}
