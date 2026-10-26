function Invoke-Copilot {
    param([string]$prompt)
    # Desativado: o 'gh copilot suggest/explain' e interativo e nao devolve uma mensagem
    # de commit de forma nao interativa. Antes ele recebia o diff como argumento de linha
    # de comando (estoura o limite do Windows) e nao checava o codigo de saida.
    throw "Provedor Copilot nao suportado para gerar mensagens (o gh copilot e interativo). Use Gemini ou Claude."
}
