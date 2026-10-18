BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\AIService.ps1")

    # Stubs de CLI: funcoes tem prioridade sobre executaveis, entao os testes rodam sem claude/gh instalados
    function global:claude {
        param([switch]$p, [Parameter(ValueFromPipeline = $true)]$inputObject)
        begin { $captured = @() }
        process { $captured += $inputObject }
        end {
            $global:CapturedClaudeInput = $captured -join "`n"
            if ($global:StubClaudeFail) { $global:LASTEXITCODE = 2; return }
            $global:LASTEXITCODE = 0
            "Resposta do stub claude"
        }
    }

    function global:gh {
        $global:LASTEXITCODE = 0
        "Resposta do stub gh"
    }
}

AfterAll {
    Remove-Item Function:\claude -ErrorAction SilentlyContinue
    Remove-Item Function:\gh -ErrorAction SilentlyContinue
    Remove-Variable StubClaudeFail, CapturedClaudeInput -Scope Global -ErrorAction SilentlyContinue
}

Describe "Invoke-Claude" {
    BeforeEach { $global:StubClaudeFail = $false }

    It "envia o prompt pelo stdin em modo -p e devolve a resposta" {
        $result = Invoke-Claude "Analise este diff"
        $result | Should -Be "Resposta do stub claude"
        $global:CapturedClaudeInput | Should -Be "Analise este diff"
    }

    It "preserva aspas no prompt" {
        Invoke-Claude 'valor "entre aspas"' | Out-Null
        $global:CapturedClaudeInput | Should -Be 'valor "entre aspas"'
    }

    It "lanca erro quando o CLI sai com codigo diferente de zero" {
        $global:StubClaudeFail = $true
        { Invoke-Claude "x" } | Should -Throw "*Claude CLI saiu*"
    }
}

Describe "Invoke-Copilot" {
    It "devolve a saida do gh" {
        Invoke-Copilot "teste" | Should -Be "Resposta do stub gh"
    }
}

Describe "Get-AISuggestion (roteamento)" {
    BeforeEach { $global:StubClaudeFail = $false }

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
        $global:StubClaudeFail = $true
        { Get-AISuggestion -prompt "oi" -provider "Claude" } | Should -Throw "*Erro no motor de IA (Claude)*"
    }
}
