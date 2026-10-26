# Filtro de segredos: impede que arquivos sensiveis e chaves cheguem ao provedor de IA externo

# Nomes de arquivo (comparados com -like, sem diretorio) que nunca vao no prompt
$script:SensitiveFilePatterns = @(
    '.env',
    '.env.*',
    '*.pem',
    '*.pfx',
    '*.p12',
    '*.key',
    '*.ppk',
    '*.jks',
    '*.keystore',
    '*.kdb',
    '*.kdbx',
    '*.tfvars',
    'appsettings*.json',
    'id_rsa*',
    'id_ecdsa*',
    'id_ed25519*',
    'credentials.json',
    'secrets.json',
    '.npmrc',
    '.git-credentials',
    'web.config'
)

# Palavras-chave de credencial (sem "key" solto: casaria com codigo Pascal, ex.: "Key := 1")
$script:SecretKeyWords = 'password|passwd|pwd|senha|secret|token|api[_-]?key|access[_-]?key|client[_-]?secret|connection[_-]?string'

# Padroes de chaves/credenciais mascarados dentro do texto do diff.
# O grupo 1 (quando existir) e mantido e so o valor e trocado.
$script:SecretPatterns = @(
    @{ Name = 'PrivateKeyPem'; Regex = '-----BEGIN [A-Z ]*PRIVATE KEY-----[\s\S]*?-----END [A-Z ]*PRIVATE KEY-----'; Keep = $false },
    @{ Name = 'GoogleApiKey';  Regex = 'AIza[0-9A-Za-z\-_]{35}'; Keep = $false },
    @{ Name = 'OpenAIKey';     Regex = 'sk-[A-Za-z0-9_\-]{20,}'; Keep = $false },
    @{ Name = 'GitHubToken';   Regex = 'gh[pousr]_[A-Za-z0-9]{36,}'; Keep = $false },
    @{ Name = 'GitHubPat';     Regex = 'github_pat_[A-Za-z0-9_]{22,}'; Keep = $false },
    @{ Name = 'SlackToken';    Regex = 'xox[abprs]-[A-Za-z0-9\-]{10,}'; Keep = $false },
    @{ Name = 'AWSAccessKey';  Regex = 'AKIA[0-9A-Z]{16}'; Keep = $false },
    @{ Name = 'Jwt';           Regex = 'eyJ[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}\.[A-Za-z0-9_\-]{10,}'; Keep = $false },
    @{ Name = 'Bearer';        Regex = '(?i)(bearer\s+)[A-Za-z0-9\-._~+/]{16,}=*'; Keep = $true },
    @{ Name = 'XmlKeyValue';   Regex = "(?i)(key\s*=\s*[`"'](?:$script:SecretKeyWords)[`"']\s+value\s*=\s*)(`"[^`"]*`"|'[^']*')"; Keep = $true },
    @{ Name = 'Assignment';    Regex = "(?i)((?:[`"']?(?:$script:SecretKeyWords)[`"']?)\s*[=:]\s*)(`"[^`"]*`"|'[^']*'|[^\r\n]+)"; Keep = $true }
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
        if ($secret.Keep) {
            # Mantem a chave/prefixo (ex.: "password=", "Bearer ") e troca apenas o valor
            $clean = [regex]::Replace($clean, $secret.Regex, '${1}[REDACTED]')
        }
        else {
            $clean = [regex]::Replace($clean, $secret.Regex, '[REDACTED]')
        }
    }
    return $clean
}
