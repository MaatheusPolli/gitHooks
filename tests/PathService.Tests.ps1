BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\PathService.ps1")
}

Describe "Get-ProjectRoot" {
    It "retorna a raiz do hub (pai da pasta lib)" {
        Get-ProjectRoot | Should -Be $script:Hub
    }

    It "retorna um caminho que existe" {
        Test-Path (Get-ProjectRoot) | Should -BeTrue
    }
}
