# Executa um CLI de IA com timeout, enviando o texto pelo stdin.
# Em falha, lanca erro com o codigo de saida e o inicio do stderr (o motivo real da falha).
# No timeout, encerra a arvore inteira do processo (taskkill /T), sem deixar filhos orfaos.
# Os argumentos vao como array; em .cmd/.bat (shims do npm) o cmd.exe faz a chamada.
function Invoke-CliWithTimeout {
    param(
        [Parameter(Mandatory = $true)][string]$Command,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$InputText,
        [Parameter(Mandatory = $true)][string]$Name,
        [int]$TimeoutSeconds = 60
    )

    $appInfo = Get-Command $Command -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $appInfo) { throw "$Name nao encontrado no PATH (comando '$Command')." }
    $path = $appInfo.Source

    # Argumentos com aspas: "" vazio vira "" (o PowerShell 5.1 perde argumento vazio sem aspas)
    $quoted = $Arguments | ForEach-Object { '"' + ($_ -replace '"', '\"') + '"' }
    if ($path -match '\.(cmd|bat)$') {
        $fileName = "cmd.exe"
        $argString = '/c ""' + $path + '" ' + ($quoted -join ' ') + '"'
    }
    else {
        $fileName = $path
        $argString = $quoted -join ' '
    }

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $fileName
    $psi.Arguments = $argString
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.StandardOutputEncoding = $utf8
    $psi.StandardErrorEncoding = $utf8

    $proc = [System.Diagnostics.Process]::Start($psi)
    # Le saida e erro em paralelo ao envio do stdin, para nao travar com buffer cheio
    $outTask = $proc.StandardOutput.ReadToEndAsync()
    $errTask = $proc.StandardError.ReadToEndAsync()
    try {
        $bytes = $utf8.GetBytes($InputText)
        $proc.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
        $proc.StandardInput.BaseStream.Close()
    }
    catch {
        # O processo pode ter encerrado antes de ler o stdin; o codigo de saida explica o resto
    }

    if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
        & taskkill /T /F /PID $proc.Id *> $null
        throw "$Name excedeu $TimeoutSeconds s (possivel login pendente ou travamento)."
    }
    $proc.WaitForExit()

    $output = $outTask.Result
    if ($proc.ExitCode -ne 0) {
        $msg = "$Name saiu com codigo $($proc.ExitCode)."
        $detail = ([string]$errTask.Result).Trim()
        if ($detail) {
            if ($detail.Length -gt 300) { $detail = $detail.Substring(0, 300) }
            $msg += " $detail"
        }
        throw $msg
    }
    return $output.TrimEnd()
}
