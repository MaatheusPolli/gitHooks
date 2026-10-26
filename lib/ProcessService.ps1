# Executa um CLI de IA em job, com timeout, enviando o texto pelo stdin.
# Em falha, lanca erro com o codigo de saida e o inicio do stderr (o motivo real da falha).
# Os argumentos vao como array, sem passar por aspas da linha de comando.
function Invoke-CliWithTimeout {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory = $true)][string]$InputText,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$TimeoutSeconds = 60
    )

    $job = Start-Job -ScriptBlock {
        param($cmd, $cmdArgs, $text)
        $OutputEncoding = New-Object System.Text.UTF8Encoding($false)
        [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
        $errFile = [System.IO.Path]::GetTempFileName()
        try {
            $out = $text | & $cmd @cmdArgs 2> $errFile
            $code = $LASTEXITCODE
            $err = Get-Content $errFile -Raw -ErrorAction SilentlyContinue
            [pscustomobject]@{ ExitCode = $code; Output = ($out -join "`n"); Error = $err }
        }
        finally {
            Remove-Item $errFile -Force -ErrorAction SilentlyContinue
        }
    } -ArgumentList $Command, $Arguments, $InputText

    if (-not (Wait-Job $job -Timeout $TimeoutSeconds)) {
        Stop-Job $job
        Remove-Job $job -Force
        throw "$Name excedeu $TimeoutSeconds s (possivel login pendente ou travamento)."
    }

    $result = Receive-Job $job
    Remove-Job $job -Force

    if (-not $result) { throw "$Name nao retornou resultado." }
    if ($result.ExitCode -ne 0) {
        $msg = "$Name saiu com codigo $($result.ExitCode)."
        $detail = ([string]$result.Error).Trim()
        if ($detail) {
            if ($detail.Length -gt 300) { $detail = $detail.Substring(0, 300) }
            $msg += " $detail"
        }
        throw $msg
    }
    return $result.Output
}
