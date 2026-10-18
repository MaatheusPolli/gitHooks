BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\PathService.ps1")
    . (Join-Path $script:Hub "lib\ConfigService.ps1")
    . (Join-Path $script:Hub "lib\SecretFilter.ps1")
    . (Join-Path $script:Hub "lib\GitService.ps1")
}

Describe "Get-GitStagedDiff (Smart Diff)" {
    BeforeAll {
        $script:Repo = Join-Path ([System.IO.Path]::GetTempPath()) ("gh-test-" + [guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:Repo | Out-Null
        Push-Location $script:Repo
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"

        # Commit inicial para que o diff tenha base
        Set-Content -Path "base.txt" -Value "inicio"
        git add base.txt
        git commit -q -m "chore: base"

        # Alteracoes staged: codigo, arquivo sensivel e chave no codigo
        Set-Content -Path "Unit1.pas" -Value "unit Unit1;`nprocedure Foo;`nbegin end;"
        Set-Content -Path ".env" -Value "DB_PASSWORD=supersecreto"
        $key = "AIza" + ("Z" * 35)
        Set-Content -Path "config.ps1" -Value "`$key = '$key'"
        git add Unit1.pas .env config.ps1

        # Alteracao nao preparada e arquivo novo, desligados por padrao
        Set-Content -Path "untracked.txt" -Value "novo"

        $env:INCLUDE_UNTRACKED = "FALSE"
        $env:INCLUDE_UNSTAGED = "FALSE"
        $env:MAX_DIFF_CHARS = "80000"
        $env:IGNORED_EXTENSIONS = ".map,.png"
        $env:PRIORITY_EXTENSIONS = ".pas"
        $script:Diff = Get-GitStagedDiff
    }

    AfterAll {
        Pop-Location
        foreach ($v in "INCLUDE_UNTRACKED", "INCLUDE_UNSTAGED", "MAX_DIFF_CHARS", "IGNORED_EXTENSIONS", "PRIORITY_EXTENSIONS") {
            Remove-Item "Env:$v" -ErrorAction SilentlyContinue
        }
        Remove-Item -Recurse -Force $script:Repo -ErrorAction SilentlyContinue
    }

    It "inclui o diff dos arquivos staged" {
        $script:Diff | Should -Match "--- FILE: Unit1.pas ---"
    }

    It "nao envia o conteudo de arquivos sensiveis" {
        $script:Diff | Should -Match "\[OMITIDO - SENS.VEL\] \.env"
        $script:Diff | Should -Not -Match "supersecreto"
        $script:Diff | Should -Not -Match "--- FILE: \.env ---"
    }

    It "mascara chaves de API no diff" {
        $script:Diff | Should -Not -Match "AIza"
        $script:Diff | Should -Match "\[REDACTED\]"
    }

    It "nao inclui arquivos untracked quando INCLUDE_UNTRACKED=FALSE" {
        $script:Diff | Should -Not -Match "untracked.txt"
    }
}
