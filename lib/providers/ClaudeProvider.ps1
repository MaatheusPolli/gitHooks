function Invoke-Claude {
    param([string]$prompt)
    $safePrompt = $prompt -replace '"', '\"'
    # Ajuste o comando se o seu binário for 'claude-cli' ou similar
    return claude "$safePrompt"
}



