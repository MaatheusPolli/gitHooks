function Invoke-Gemini {
    param(
        [string]$prompt,
        [int]$TimeoutSeconds = 60
    )
    # 1. Roda em job para poder aplicar timeout: o Gemini CLI pode travar esperando login
    # 2. O prompt entra pelo pipe (evita limites de buffer da CLI); a flag -p sinaliza modo nao-interativo
    # 3. O codigo de saida e devolvido para o chamador, que trata a falha (non-blocking)
    $job = Start-Job -ScriptBlock {
        param($text)
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $out = $text | gemini -p "Gere a mensagem de commit baseada no diff:"
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($out -join "`n") }
    } -ArgumentList $prompt

    if (-not (Wait-Job $job -Timeout $TimeoutSeconds)) {
        Stop-Job $job
        Remove-Job $job -Force
        throw "Gemini excedeu $TimeoutSeconds s (possível login pendente)."
    }

    $result = Receive-Job $job
    Remove-Job $job -Force

    if (-not $result) { throw "Gemini não retornou resultado." }
    if ($result.ExitCode -ne 0) { throw "Gemini CLI saiu com código $($result.ExitCode)." }

    return $result.Output
}
