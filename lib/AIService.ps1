# Importa os provedores de IA (.ps1 independentes)
$LibDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
. (Join-Path $LibDir "ProcessService.ps1")
. (Join-Path $LibDir "providers\GeminiProvider.ps1")
. (Join-Path $LibDir "providers\ClaudeProvider.ps1")
. (Join-Path $LibDir "providers\CopilotProvider.ps1")

function Get-AISuggestion {
    param([Parameter(Mandatory = $true)][string]$prompt, [string]$provider = "Gemini")
    try {
        switch ($provider) {
            "Gemini" { return Invoke-Gemini $prompt }
            "Claude" { return Invoke-Claude $prompt }
            "Copilot" { return Invoke-Copilot $prompt }
            Default { throw "Provider '$provider' nao reconhecido." }
        }
    }
    catch { throw "Erro no motor de IA ($provider): $($_.Exception.Message)" }
}

