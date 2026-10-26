# Validacao do formato Conventional Commits (<tipo>(<escopo>)?!?: <descricao>)
# A validacao e apenas informativa: se nao casar, o texto bruto da IA e mantido (fallback)

$script:ConventionalCommitRegex = '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([^)\r\n]+\))?!?: \S.*'

function Test-ConventionalCommit {
    param([string]$Message)

    if ([string]::IsNullOrWhiteSpace($Message)) { return $false }

    $firstLine = ($Message.Trim() -split "`r?`n")[0]
    return ($firstLine -match $script:ConventionalCommitRegex)
}
