BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\AIService.ps1")

    # Shim de CLI: um claude.cmd no PATH recebe os argumentos e a entrada reais do PowerShell.
    # Um stub em funcao nao serve: o PowerShell nao liga o pipeline a argumentos como --tools=""
    $script:ShimDir = Join-Path ([System.IO.Path]::GetTempPath()) "gh-test-shim-$PID"
    New-Item -ItemType Directory -Force -Path $script:ShimDir | Out-Null
    $shimLines = @(
        '@echo off',
        'if "%STUB_CLAUDE_FAIL%"=="1" exit /b 2',
        'more > "%~dp0last-stdin.txt"',
        'echo %* > "%~dp0last-args.txt"',
        'echo Resposta do stub claude'
    )
    Set-Content -Path (Join-Path $script:ShimDir "claude.cmd") -Value $shimLines -Encoding ASCII
    $script:OldPath = $env:PATH
    $env:PATH = "$script:ShimDir;$env:PATH"

    # Stub de gh: funcoes tem prioridade sobre executaveis, entao os testes rodam sem gh instalado
    function global:gh {
        $global:LASTEXITCODE = 0
        "Resposta do stub gh"
    }
}

AfterAll {
    $env:PATH = $script:OldPath
    Remove-Item Function:\gh -ErrorAction SilentlyContinue
    Remove-Item Env:STUB_CLAUDE_FAIL -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $script:ShimDir -ErrorAction SilentlyContinue
}

Describe "Invoke-Claude" {
    BeforeEach { $env:STUB_CLAUDE_FAIL = "0" }

    It "envia o prompt pelo stdin em modo -p e devolve a resposta" {
        $result = Invoke-Claude "Analise este diff"
        $result | Should -Be "Resposta do stub claude"
        (Get-Content (Join-Path $script:ShimDir "last-stdin.txt") -Raw).Trim() | Should -Be "Analise este diff"
    }

    It "preserva aspas no prompt" {
        Invoke-Claude 'valor "entre aspas"' | Out-Null
        (Get-Content (Join-Path $script:ShimDir "last-stdin.txt") -Raw).Trim() | Should -Be 'valor "entre aspas"'
    }

    It "desativa as ferramentas do CLI (nao le arquivos do repositorio sozinho)" {
        Invoke-Claude "qualquer" | Out-Null
        (Get-Content (Join-Path $script:ShimDir "last-args.txt") -Raw) | Should -Match "-p --tools="
    }

    It "lanca erro quando o CLI sai com codigo diferente de zero" {
        $env:STUB_CLAUDE_FAIL = "1"
        { Invoke-Claude "x" } | Should -Throw "*Claude CLI saiu*"
    }
}

Describe "Invoke-Copilot" {
    It "devolve a saida do gh" {
        Invoke-Copilot "teste" | Should -Be "Resposta do stub gh"
    }
}

Describe "Get-AISuggestion (roteamento)" {
    BeforeEach { $env:STUB_CLAUDE_FAIL = "0" }

    It "roteia Claude para o provedor Claude" {
        Get-AISuggestion -prompt "oi" -provider "Claude" | Should -Be "Resposta do stub claude"
    }

    It "roteia Copilot para o provedor Copilot" {
        Get-AISuggestion -prompt "oi" -provider "Copilot" | Should -Be "Resposta do stub gh"
    }

    It "provedor desconhecido gera erro claro" {
        { Get-AISuggestion -prompt "oi" -provider "Inexistente" } | Should -Throw "*nao reconhecido*"
    }

    It "encapsula falha do provedor com o nome do motor" {
        $env:STUB_CLAUDE_FAIL = "1"
        { Get-AISuggestion -prompt "oi" -provider "Claude" } | Should -Throw "*Erro no motor de IA (Claude)*"
    }
}
