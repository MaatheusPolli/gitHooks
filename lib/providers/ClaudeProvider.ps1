function Invoke-Claude {
    param([string]$prompt)
    # -p (print mode) executa sem abrir sessao interativa; o prompt entra pelo stdin,
    # o que evita problemas de aspas e de tamanho na linha de comando
    $output = $prompt | claude -p
    if ($LASTEXITCODE -ne 0) { throw "Claude CLI saiu com código $LASTEXITCODE." }
    return ($output -join "`n")
}
