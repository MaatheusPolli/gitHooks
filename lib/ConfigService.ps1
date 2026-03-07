

function Get-AppConfig {
    param([string]$key)
    
    # 1. Prioriza Variáveis de Ambiente (GitLab CI / Pipeline)
    $envValue = [System.Environment]::GetEnvironmentVariable($key)
    if (![string]::IsNullOrEmpty($envValue)) { return $envValue }

    # 2. Se não houver Env Var, busca no arquivo local settings.txt
    $base = Get-ProjectRoot
    $configPath = Join-Path $base "config\settings.txt"
    
    if (!(Test-Path $configPath)) { 
        if ($key -eq "PROVIDER") { return "Gemini" }
        return $null 
    }

    try {
        $lines = Get-Content $configPath -ErrorAction SilentlyContinue | Where-Object { $_.Trim() -and !$_.StartsWith("#") }
        foreach ($line in $lines) {
            $parts = $line -split "="
            if ($parts.Length -eq 2 -and $parts[0].Trim() -eq $key) {
                return $parts[1].Trim()
            }
        }
    } catch { }
    return $null
}


