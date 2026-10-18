# Filtro de segredos: impede que arquivos sensiveis e chaves cheguem ao provedor de IA externo

# Nomes de arquivo (comparados com -like, sem diretorio) que nunca vao no prompt
$script:SensitiveFilePatterns = @(
    '.env',
    '.env.*',
    '*.pem',
    '*.pfx',
    '*.p12',
    '*.key',
    'appsettings*.json',
    'id_rsa*',
    '*.kdb',
    '*.kdbx'
)

# Padroes de chaves/credenciais mascarados dentro do texto do diff
$script:SecretPatterns = @(
    @{ Name = 'GoogleApiKey'; Regex = 'AIza[0-9A-Za-z\-_]{35}' },
    @{ Name = 'OpenAIKey';    Regex = 'sk-[A-Za-z0-9_\-]{20,}' },
    @{ Name = 'GitHubToken';  Regex = 'gh[pousr]_[A-Za-z0-9]{36,}' },
    @{ Name = 'AWSAccessKey'; Regex = 'AKIA[0-9A-Z]{16}' },
    @{ Name = 'Assignment';   Regex = '(?i)((?:password|passwd|pwd|senha|secret|token|api[_-]?key)\s*[=:]\s*)(?:"[^"]*"|''[^'']*''|[^\s"'']+)' }
)

function Test-SensitiveFile {
    param([Parameter(Mandatory = $true)][string]$Path)

    $name = Split-Path -Leaf $Path
    foreach ($pattern in $script:SensitiveFilePatterns) {
        if ($name -like $pattern) { return $true }
    }
    return $false
}

function Remove-SecretsFromText {
    param([string]$Text)

    if ([string]::IsNullOrEmpty($Text)) { return $Text }

    $clean = $Text
    foreach ($secret in $script:SecretPatterns) {
        if ($secret.Name -eq 'Assignment') {
            # Mantem a chave da atribuicao (ex.: "password=") e troca apenas o valor
            $clean = [regex]::Replace($clean, $secret.Regex, '${1}[REDACTED]')
        }
        else {
            $clean = [regex]::Replace($clean, $secret.Regex, '[REDACTED]')
        }
    }
    return $clean
}
