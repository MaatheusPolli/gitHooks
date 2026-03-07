function Invoke-Copilot {
    param([string]$prompt)
    $safePrompt = $prompt -replace '"', '\"'
    # Utiliza o GitHub CLI com a extensão de copilot
    # 'gh copilot explain' ou similar, adaptado para retornar texto
    return gh copilot suggest -t shell "$safePrompt"
}



