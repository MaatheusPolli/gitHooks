function Invoke-Claude {
    param(
        [string]$prompt,
        [int]$TimeoutSeconds = 60
    )
    # -p (print mode) executa sem abrir sessao interativa; o prompt entra pelo stdin,
    # o que evita problemas de aspas e de tamanho na linha de comando.
    # --tools= desativa as ferramentas: o modelo so recebe o diff e nao le arquivos
    # do repositorio (ex.: .env) por conta propria
    return Invoke-CliWithTimeout -Command "claude" -Arguments @("-p", "--tools=") -InputText $prompt -Name "Claude CLI" -TimeoutSeconds $TimeoutSeconds
}
