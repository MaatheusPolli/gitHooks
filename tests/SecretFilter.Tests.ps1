BeforeAll {
    . (Join-Path $PSScriptRoot "..\lib\SecretFilter.ps1")
}

Describe "Test-SensitiveFile" {
    It "detecta arquivos de ambiente e chaves" {
        Test-SensitiveFile "src/.env" | Should -BeTrue
        Test-SensitiveFile "config/.env.local" | Should -BeTrue
        Test-SensitiveFile "certs/server.pem" | Should -BeTrue
        Test-SensitiveFile "certs/cert.PFX" | Should -BeTrue
        Test-SensitiveFile "web/appsettings.Production.json" | Should -BeTrue
    }

    It "nao bloqueia arquivos comuns" {
        Test-SensitiveFile "src/Unit1.pas" | Should -BeFalse
        Test-SensitiveFile "lib/GitService.ps1" | Should -BeFalse
        Test-SensitiveFile "docs/envio.md" | Should -BeFalse
    }
}

Describe "Remove-SecretsFromText" {
    It "mascara chave do Google (AIza)" {
        $key = "AIza" + ("A" * 35)
        $result = Remove-SecretsFromText "const k = '$key';"
        $result | Should -Not -Match "AIza"
        $result | Should -Match "\[REDACTED\]"
    }

    It "mascara token do GitHub e chave sk-" {
        $gh = "ghp_" + ("a" * 36)
        $sk = "sk-" + ("b" * 30)
        $result = Remove-SecretsFromText "$gh and $sk"
        $result | Should -Not -Match "ghp_"
        $result | Should -Not -Match "sk-"
    }

    It "mantem a chave da atribuicao e troca apenas o valor" {
        $result = Remove-SecretsFromText 'password=hunter2'
        $result | Should -Be 'password=[REDACTED]'
    }

    It "mascara atribuicoes com aspas" {
        $result = Remove-SecretsFromText 'api_key: "abc123"'
        $result | Should -Not -Match "abc123"
    }

    It "nao altera texto sem segredos" {
        $text = "+ procedure Foo; begin end;"
        Remove-SecretsFromText $text | Should -Be $text
    }

    It "aceita texto vazio" {
        Remove-SecretsFromText "" | Should -Be ""
    }
}
