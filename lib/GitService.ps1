function Get-GitStagedDiff {
    # 1. Carrega as flags de configuracao
    $includeUntracked = Get-AppConfig "INCLUDE_UNTRACKED"
    $includeUnstaged = Get-AppConfig "INCLUDE_UNSTAGED"
    $maxTotalChars = [int](Get-AppConfig "MAX_DIFF_CHARS")
    if ($maxTotalChars -le 0) { $maxTotalChars = 80000 }

    $contextLines = Get-AppConfig "DIFF_CONTEXT_LINES"
    if ([string]::IsNullOrWhiteSpace($contextLines)) { $contextLines = "1" }

    $ignoredExts = (Get-AppConfig "IGNORED_EXTENSIONS").Split(',') | ForEach-Object { $_.Trim().ToLower() }
    $priorityExts = (Get-AppConfig "PRIORITY_EXTENSIONS").Split(',') | ForEach-Object { $_.Trim().ToLower() }

    $finalDiff = ""
    $fileSummary = "### SUMÁRIO DE ARQUIVOS ALTERADOS:`n"

    # 2. Captura lista de arquivos (Staged, Unstaged, Untracked)
    $stagedAll = @(git diff --cached --name-only)
    $unstagedAll = if ($includeUnstaged -ieq "True") { @(git diff --name-only) } else { @() }
    $untrackedAll = if ($includeUntracked -ieq "True") { @(git ls-files --others --exclude-standard) } else { @() }

    # 2.1 Arquivos sensiveis (.env, chaves, appsettings) nunca vao para a IA: so o nome aparece no sumario
    $skipped = @()
    $stagedFiles = @($stagedAll | Where-Object { -not (Test-SensitiveFile $_) })
    $unstagedFiles = @($unstagedAll | Where-Object { -not (Test-SensitiveFile $_) })
    $untrackedFiles = @($untrackedAll | Where-Object { -not (Test-SensitiveFile $_) })
    $skipped += @($stagedAll + $unstagedAll + $untrackedAll) | Where-Object { Test-SensitiveFile $_ } | Select-Object -Unique

    # Cria o sumário visual primeiro
    foreach ($f in $stagedFiles) { $fileSummary += "- [STAGED] $f`n" }
    foreach ($f in $unstagedFiles) { $fileSummary += "- [UNSTAGED] $f`n" }
    foreach ($f in $untrackedFiles) { $fileSummary += "- [UNTRACKED] $f`n" }
    foreach ($f in $skipped) { $fileSummary += "- [OMITIDO - SENSÍVEL] $f`n" }

    $finalDiff += $fileSummary + "`n--- DETALHES DO DIFF (Otimizado Context-U$contextLines) ---`n"

    # 3. Processa Diff individual por arquivo para controle de tamanho
    # Prioridade para arquivos STAGED
    $allFiles = $stagedFiles | Select-Object -Unique

    foreach ($file in $allFiles) {
        # Pula se for extensão ignorada
        $ext = [System.IO.Path]::GetExtension($file).ToLower()
        if ($ignoredExts -contains $ext) {
            $finalDiff += "`n[INFO] Arquivo $file ignorado (extensão na whitelist de bloqueio).`n"
            continue
        }

        # Define limite por arquivo baseado na prioridade
        $fileLimit = if ($priorityExts -contains $ext) { 25000 } else { 8000 }

        # Pega o diff deste arquivo com compressão avançada (-U para contexto, -w para ignorar espaços)
        $fileDiff = git diff --cached "-U$contextLines" -w --no-color --no-ext-diff -- "$file"

        # Mascara chaves e credenciais antes de qualquer envio
        $fileDiff = Remove-SecretsFromText ($fileDiff -join "`n")

        # Truncamento inteligente
        if ($fileDiff.Length -gt $fileLimit) {
            $fileDiff = $fileDiff.Substring(0, $fileLimit) + "`n[... DIFF TRUNCADO POR TAMANHO NO ARQUIVO $file ...]"
        }

        $finalDiff += "`n--- FILE: $file ---`n" + $fileDiff

        # Se ja atingimos o limite total, paramos de adicionar diffs
        if ($finalDiff.Length -gt $maxTotalChars) {
            $finalDiff = $finalDiff.Substring(0, $maxTotalChars) + "`n`n[!!! LIMITE TOTAL DE CARACTERES ATINGIDO ($maxTotalChars). MUDANÇAS ADICIONAIS OCULTADAS !!!]"
            break
        }
    }

    # 4. Adiciona Unstaged se houver e se houver espaço
    if ($includeUnstaged -ieq "True" -and $finalDiff.Length -lt $maxTotalChars) {
        $finalDiff += "`n--- ALTERACOES NAO PREPARADAS (UNSTAGED) ---`n"
        foreach ($file in $unstagedFiles) {
            if ($finalDiff.Length -gt $maxTotalChars) { break }

            $ext = [System.IO.Path]::GetExtension($file).ToLower()
            if ($ignoredExts -contains $ext) { continue }

            $fileDiff = git diff "-U$contextLines" -w --no-color --no-ext-diff -- "$file"
            $fileDiff = Remove-SecretsFromText ($fileDiff -join "`n")
            $unstagedLimit = if ($priorityExts -contains $ext) { 15000 } else { 5000 }

            if ($fileDiff.Length -gt $unstagedLimit) { $fileDiff = $fileDiff.Substring(0, $unstagedLimit) + "... [Truncado]" }
            $finalDiff += "`n--- FILE (UNSTAGED): $file ---`n" + $fileDiff
        }
    }

    return $finalDiff
}

function Get-GitBranch {
    $branch = git rev-parse --abbrev-ref HEAD
    if ($LASTEXITCODE -ne 0) { return "N/A" }
    return $branch.Trim()
}

function Get-GitRepoRoot {
    return git rev-parse --show-toplevel
}

function Get-GitDefaultBase {
    # Branch remota padrao (origin/HEAD); se nao existir, tenta origin/main e origin/master
    $ref = git symbolic-ref --quiet refs/remotes/origin/HEAD 2>$null
    if ($LASTEXITCODE -eq 0 -and $ref) { return ($ref -replace '^refs/remotes/', '') }

    foreach ($candidate in @("origin/main", "origin/master", "main", "master")) {
        git rev-parse --verify --quiet $candidate *> $null
        if ($LASTEXITCODE -eq 0) { return $candidate }
    }
    return $null
}

function Get-GitReviewDiff {
    # Diff de tudo que esta no HEAD e ainda nao esta na base (merge-base), para revisao pre-push
    param(
        [Parameter(Mandatory = $true)][string]$Base,
        [int]$MaxChars = 80000
    )

    $contextLines = Get-AppConfig "DIFF_CONTEXT_LINES"
    if ([string]::IsNullOrWhiteSpace($contextLines)) { $contextLines = "1" }

    $mergeBase = git merge-base $Base HEAD 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($mergeBase)) { return $null }

    # Arquivos sensiveis ficam de fora do pathspec, nunca chegam a ser lidos para o prompt
    $files = @(git diff --name-only $mergeBase HEAD | Where-Object { -not (Test-SensitiveFile $_) })
    if ($files.Count -eq 0) { return "" }

    $diff = (git diff "-U$contextLines" -w --no-color --no-ext-diff $mergeBase HEAD -- @files) -join "`n"
    $diff = Remove-SecretsFromText $diff

    if ($diff.Length -gt $MaxChars) {
        $diff = $diff.Substring(0, $MaxChars) + "`n`n[!!! LIMITE TOTAL DE CARACTERES ATINGIDO ($MaxChars). MUDANÇAS ADICIONAIS OCULTADAS !!!]"
    }
    return $diff
}
