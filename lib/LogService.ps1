function Write-Log {
    param(
        [string]$message,
        [switch]$Clear # Se passar -Clear, ele limpa o arquivo
    )
    
    $logPath = Get-AppConfig "LOG_PATH"
    if ([string]::IsNullOrWhiteSpace($logPath)) { $logPath = "C:\LOG-GitHooks\debug.log" }

    try {
        $logDir = Split-Path -Parent $logPath
        if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logLine = "[$timestamp] $message"

        if ($Clear) {
            $logLine | Out-File $logPath -Force -Encoding UTF8
        } else {
            $logLine | Out-File $logPath -Append -Encoding UTF8
        }
    }
    catch { }
}
