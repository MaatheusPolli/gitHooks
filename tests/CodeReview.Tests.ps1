BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\PathService.ps1")
    . (Join-Path $script:Hub "lib\ConfigService.ps1")
    . (Join-Path $script:Hub "lib\SecretFilter.ps1")
    . (Join-Path $script:Hub "lib\GitService.ps1")

    $script:Repo = Join-Path ([System.IO.Path]::GetTempPath()) ("gh-review-" + [guid]::NewGuid())
    New-Item -ItemType Directory -Path $script:Repo | Out-Null
    Push-Location $script:Repo
    git init -q -b main
    git config user.email "test@example.com"
    git config user.name "Test"

    Set-Content -Path "base.pas" -Value "unit Base;"
    git add base.pas
    git commit -q -m "chore: base"

    # Branch de trabalho com commits novos (um sensivel e um com chave)
    git checkout -q -b feature
    Set-Content -Path "Calc.pas" -Value "function Soma(a, b: Integer): Integer;"
    $key = "AIza" + ("Q" * 35)
    Set-Content -Path "keys.ps1" -Value "`$k = '$key'"
    Set-Content -Path ".env" -Value "TOKEN=abc"
    git add -A
    git commit -q -m "feat: soma"
    $env:DIFF_CONTEXT_LINES = "1"
}

AfterAll {
    Pop-Location
    Remove-Item Env:DIFF_CONTEXT_LINES -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $script:Repo -ErrorAction SilentlyContinue
}

Describe "Get-GitDefaultBase" {
    It "encontra a branch main quando nao ha origin" {
        Get-GitDefaultBase | Should -Be "main"
    }
}

Describe "Get-GitReviewDiff" {
    It "mostra apenas os commits novos em relacao a base" {
        $diff = Get-GitReviewDiff -Base "main"
        $diff | Should -Match "Calc.pas"
        $diff | Should -Not -Match "base.pas"
    }

    It "nao inclui arquivos sensiveis" {
        $diff = Get-GitReviewDiff -Base "main"
        $diff | Should -Not -Match "TOKEN=abc"
    }

    It "mascara chaves de API" {
        $diff = Get-GitReviewDiff -Base "main"
        $diff | Should -Not -Match "AIza"
    }

    It "retorna nulo quando a base nao existe" {
        Get-GitReviewDiff -Base "branch-inexistente" | Should -BeNullOrEmpty
    }

    It "respeita o limite de caracteres" {
        $diff = Get-GitReviewDiff -Base "main" -MaxChars 40
        $diff | Should -Match "LIMITE TOTAL"
    }
}

Describe "Prompt de revisao" {
    It "contem os placeholders obrigatorios" {
        $prompt = Get-Content (Join-Path $script:Hub "prompts\code-review.txt") -Raw
        $prompt | Should -Match "\{\{DIFF\}\}"
        $prompt | Should -Match "\{\{BRANCH\}\}"
        $prompt | Should -Match "\{\{AI_CLI\}\}"
    }
}
