BeforeAll {
    . (Join-Path $PSScriptRoot "..\lib\CommitFormat.ps1")
}

Describe "Test-ConventionalCommit" {
    It "aceita tipos validos" {
        Test-ConventionalCommit "feat: adiciona filtro de segredos" | Should -BeTrue
        Test-ConventionalCommit "fix(parser): corrige truncamento" | Should -BeTrue
        Test-ConventionalCommit "refactor!: remove API antiga" | Should -BeTrue
    }

    It "rejeita texto livre" {
        Test-ConventionalCommit "ajustes" | Should -BeFalse
        Test-ConventionalCommit "Corrige bug no parser" | Should -BeFalse
    }

    It "rejeita tipo desconhecido e descricao vazia" {
        Test-ConventionalCommit "feature: algo" | Should -BeFalse
        Test-ConventionalCommit "fix: " | Should -BeFalse
    }

    It "valida apenas a primeira linha" {
        Test-ConventionalCommit "docs: atualiza README`n`nCorpo do commit" | Should -BeTrue
    }

    It "rejeita vazio" {
        Test-ConventionalCommit "" | Should -BeFalse
    }
}
