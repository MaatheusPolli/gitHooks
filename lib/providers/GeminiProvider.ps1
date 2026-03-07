function Invoke-Gemini {
    param([string]$prompt)
    # 1. Utiliza pipe para enviar o prompt ao Gemini, o que evita erros de estouro de buffer (CLI limits)
    # 2. A flag -p "" sinaliza o modo nao-interativo e anexa ao conteúdo do stdin
    return $prompt | gemini -p "Gere a mensagem de commit baseada no diff:"
}


