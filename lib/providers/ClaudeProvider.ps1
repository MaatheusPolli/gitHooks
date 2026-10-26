function Invoke-Claude {
    param([string]$prompt)
    # -p (print mode) executa sem abrir sessao interativa; o prompt entra pelo stdin,
    # o que evita problemas de aspas e de tamanho na linha de comando.
    # --tools="" desativa as ferramentas: o modelo so recebe o diff e nao le arquivos
    # do repositorio (ex.: .env) por conta propria. A forma com espaco (--tools "")
    # e perdida pelo PowerShell 5.1, por isso o sinal de igual
    $output = $prompt | claude -p --tools=""
    if ($LASTEXITCODE -ne 0) { throw "Claude CLI saiu com código $LASTEXITCODE." }
    return ($output -join "`n")
}
