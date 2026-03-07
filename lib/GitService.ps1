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
    $stagedFiles = git diff --cached --name-only
    $unstagedFiles = if ($includeUnstaged -ieq "True") { git diff --name-only } else { @() }
    $untrackedFiles = if ($includeUntracked -ieq "True") { git ls-files --others --exclude-standard } else { @() }

    # Cria o sumário visual primeiro
    foreach ($f in $stagedFiles) { $fileSummary += "- [STAGED] $f`n" }
    foreach ($f in $unstagedFiles) { $fileSummary += "- [UNSTAGED] $f`n" }
    foreach ($f in $untrackedFiles) { $fileSummary += "- [UNTRACKED] $f`n" }
    
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
        $fileDiff = git diff --cached -U$contextLines -w --no-color --no-ext-diff -- "$file"
        
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
            
            $fileDiff = git diff -U$contextLines -w --no-color --no-ext-diff -- "$file"
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



