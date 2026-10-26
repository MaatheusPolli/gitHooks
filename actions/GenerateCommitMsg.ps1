param(
    [Parameter(Position = 0)]
    [string]$arg1,
    [Parameter(Position = 1)]
    [string]$arg2,
    [Parameter(Position = 2)]
    [string]$arg3
)

# 1. Configura Core e Diretorio
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
# Diretorio de onde o git (ou o TortoiseGit) chamou o script: e o repositorio do usuario, nao o hub
$callerDir = (Get-Location).ProviderPath

# 1.1 Configura Encodings do PowerShell para evitar Mojibake ao ler STDOUT de programas externos (gemini.exe, etc)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
# UTF-8 sem BOM: com BOM o CLI recebe bytes extras no inicio do prompt
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Detecção de quem chamou (Git prepare-commit-msg vs TortoiseGit Start-Commit)
$commitMsgFile = ""
$source = ""
$workDir = ""

# Heurística: se Git, $arg1 é MSG e $arg2 é source. Se TortoiseGit, $arg1 é PATH (tmp list), $arg2 é MSG.
if ($arg2 -match "^(commit|merge|template|squash|message)$" -or $arg1 -match "COMMIT_EDITMSG") {
    # Padrão Git CLI
    $commitMsgFile = $arg1
    $source = $arg2
    $workDir = $arg3
}
else {
    # Padrão TortoiseGit (Start-Commit append automatico: PATH MESSAGEFILE CWD)
    $commitMsgFile = $arg2
    $workDir = $arg3
    $source = ""
}

# Carrega as funcoes
. (Join-Path $BaseDir "lib\PathService.ps1")
. (Join-Path $BaseDir "lib\ConfigService.ps1")
. (Join-Path $BaseDir "lib\LogService.ps1")
. (Join-Path $BaseDir "lib\GitService.ps1")
. (Join-Path $BaseDir "lib\AIService.ps1")
. (Join-Path $BaseDir "lib\SecretFilter.ps1")
. (Join-Path $BaseDir "lib\CommitFormat.ps1")

# LIMPA O LOG E INICIA A SESSAO
$clearLog = Get-AppConfig "CLEAR_LOG"
if ([string]::IsNullOrWhiteSpace($clearLog)) { $clearLog = "True" }

if ($clearLog -eq "True") {
    Write-Log "--- INICIO DA EXECUCAO ---" -Clear
}
else {
    Write-Log "--- INICIO DA EXECUCAO ---" 
}

Write-Log "PARAM RAW: arg1=$arg1 | arg2=$arg2 | arg3=$arg3"
Write-Log "INTERPRETADO: MsgFile=$commitMsgFile | Source=$source | WorkDir=$workDir"

# Validacao de Variaveis do TortoiseGit (caso o usuario digite na mao)
if ($commitMsgFile -match "%(MSGFILE|PATH|[1-4])%") {
    Write-Log "ERRO DE CONFIGURACAO: Variavel literal detectada. Remova as aspas e os %VAR% do TortoiseGit. Deixe apenas o caminho do script."
    exit 0
}
# Sem arquivo de mensagem, nao ha onde escrever: sai sem tocar em nada.
# (Antes havia uma "recuperacao" que pegava o *.tmp mais recente de %TEMP%, de qualquer
# programa, e podia sobrescrever arquivos alheios.)
if ($commitMsgFile -eq "%MSGFILE%" -or $commitMsgFile -eq "%4" -or [string]::IsNullOrWhiteSpace($commitMsgFile)) {
    Write-Log "ERRO: TortoiseGit nao passou o arquivo de mensagem (%MSGFILE%). Nada foi alterado."
    exit 0
}

# Limpeza de parametros
$cleanMsgFile = $commitMsgFile.Trim('"')
$cleanWorkDir = $workDir.Trim('"')
if ($workDir -match '\"$') { $cleanWorkDir = $workDir -replace '\"$', '\' }

# O git passa o caminho da mensagem relativo ao repositorio: resolve antes de trocar de pasta
if (-not [System.IO.Path]::IsPathRooted($cleanMsgFile)) { $cleanMsgFile = Join-Path $callerDir $cleanMsgFile }

# Tratamento do WorkDir (Se vier vazio ou %PATH%, usamos o diretorio de quem chamou como fallback)
if ($cleanWorkDir -eq "%PATH%" -or $cleanWorkDir -eq "%3" -or [string]::IsNullOrWhiteSpace($cleanWorkDir)) {
    if ($source -and (Test-Path $source)) { $cleanWorkDir = $source } else { $cleanWorkDir = $callerDir }
}

# Nao sobrescreve mensagem que o usuario ja escreveu (-m, merge, squash, amend, template)
if ($source -match "^(commit|merge|squash|message|template)$") {
    Write-Log "INFO: Origem '$source' com mensagem do usuario. Mantida."
    exit 0
}
# Arquivo ja com texto (que nao e so comentario do git) tambem e preservado.
# Se nao for possivel ler o arquivo, nao escrevemos nele (na duvida, nao sobrescreve)
$existingMsg = ""
if (Test-Path $cleanMsgFile) {
    try { $existingMsg = Get-Content $cleanMsgFile -Raw -ErrorAction Stop }
    catch {
        Write-Log "AVISO: nao foi possivel ler o arquivo de mensagem. Mantido: $($_.Exception.Message)"
        exit 0
    }
}
if ($existingMsg -match '(?m)^[^#\s]') {
    Write-Log "INFO: Arquivo de mensagem ja tem texto. Mantido."
    exit 0
}

try {
    if (Test-Path $cleanWorkDir) {
        Set-Location $cleanWorkDir -ErrorAction SilentlyContinue
        Write-Log "INFO: Diretorio de trabalho: $cleanWorkDir"
    }
    else {
        # Fallback seguro para o diretorio de quem chamou (nunca o hub)
        Set-Location $callerDir
    }
    
    # 3. Busca Diff
    Write-Log "INFO: Capturando Diff..."
    $diffContent = Get-GitStagedDiff
    
    if ([string]::IsNullOrWhiteSpace($diffContent)) { 
        Write-Log "FIM: Nenhum diff detectado para analise."
        exit 0 
    }
    Write-Log "INFO: Diff capturado ($($diffContent.Length) caracteres)."

    # 4. Busca Sugestao via IA
    $aiProvider = Get-AppConfig "PROVIDER"
    $promptFile = Get-AppConfig "PROMPT_FILE"
    if ([string]::IsNullOrWhiteSpace($promptFile)) { $promptFile = "commit-msg.txt" }
    
    $branch = Get-GitBranch
    Write-Log "INFO: Solicitando sugestao ao $aiProvider usando prompt $promptFile..."
    
    $promptPath = Join-Path $BaseDir "prompts\$promptFile"
    if (!(Test-Path $promptPath)) {
        Write-Log "AVISO: Prompt $promptFile nao encontrado. Usando padrao."
        $promptPath = Join-Path $BaseDir "prompts\commit-msg.txt"
    }
    
    $promptTemplate = Get-Content $promptPath -Raw -Encoding UTF8
    $fullPrompt = $promptTemplate.Replace("{{DIFF}}", $diffContent).Replace("{{BRANCH}}", $branch).Replace("{{AI_CLI}}", "$aiProvider-CLI")

    $suggestion = Get-AISuggestion -prompt $fullPrompt -provider $aiProvider
    
    if (![string]::IsNullOrWhiteSpace($suggestion)) {
        # Fora do Conventional Commits: apenas registra; o texto bruto e mantido (fallback)
        if (Test-ConventionalCommit $suggestion) {
            Write-Log "INFO: Mensagem no formato Conventional Commits."
        }
        else {
            Write-Log "AVISO: Mensagem fora do formato Conventional Commits. Usando texto bruto."
        }

        # O script agora capturou o STDOUT corretamente em UTF-8 devido ao bloqueio inicial.
        # Salvaremos como UTF8 (com BOM no PS 5.1) para garantir que o TortoiseGit leia perfeitamente.
        Set-Content -Path $cleanMsgFile -Value $suggestion -Encoding UTF8
        Write-Log "SUCESSO: Mensagem preenchida no arquivo: $cleanMsgFile"
    }
    else {
        Write-Log "AVISO: IA nao retornou texto."
    }
}
catch {
    Write-Log "ERRO CRITICO: $($_.Exception.Message)"
}

Write-Log "--- FIM DA EXECUCAO ---"
exit 0
