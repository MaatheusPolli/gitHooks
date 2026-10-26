function Invoke-Gemini {
    param(
        [string]$prompt,
        [int]$TimeoutSeconds = 60
    )
    # -p ativa o modo nao-interativo; o texto do prompt entra pelo stdin.
    # A instrucao do -p e generica: quem define a tarefa e o template do prompt
    # (commit, code review), e nao o provedor
    return Invoke-CliWithTimeout -Command "gemini" -Arguments @("-p", "Siga exatamente as instrucoes do texto recebido.") -InputText $prompt -Name "Gemini CLI" -TimeoutSeconds $TimeoutSeconds
}
