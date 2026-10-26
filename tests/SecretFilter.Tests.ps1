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

    It "detecta credenciais de outros formatos" {
        Test-SensitiveFile "keys/id_ed25519" | Should -BeTrue
        Test-SensitiveFile ".npmrc" | Should -BeTrue
        Test-SensitiveFile "store/app.jks" | Should -BeTrue
        Test-SensitiveFile "web/web.config" | Should -BeTrue
        Test-SensitiveFile "infra/prod.tfvars" | Should -BeTrue
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

    It "mascara valor de chave JSON com aspas" {
        $result = Remove-SecretsFromText '"password": "hunter2"'
        $result | Should -Not -Match "hunter2"
    }

    It "mascara valor de atributo XML (key/value)" {
        $result = Remove-SecretsFromText '<add key="Password" value="s3cr3t"/>'
        $result | Should -Not -Match "s3cr3t"
    }

    It "mascara Bearer e JWT" {
        $jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV"
        $result = Remove-SecretsFromText "Authorization: Bearer abcdefghijklmnopqrstuvwx"
        $result | Should -Not -Match "abcdefghijklmnopqrstuvwx"
        (Remove-SecretsFromText $jwt) | Should -Not -Match "eyJhbGciOiJIUzI1NiIs"
    }

    It "mascara bloco PEM inline" {
        $pem = "-----BEGIN RSA PRIVATE KEY-----`nMIIEabc123`n-----END RSA PRIVATE KEY-----"
        (Remove-SecretsFromText $pem) | Should -Not -Match "MIIEabc123"
    }

    It "mascara tokens Slack e GitHub PAT" {
        $slack = "xoxb-" + ("1234567890" * 2)
        $pat = "github_pat_" + ("A" * 30)
        $result = Remove-SecretsFromText "$slack $pat"
        $result | Should -Not -Match "xoxb-"
        $result | Should -Not -Match "github_pat_"
    }

    It "mascara valor com espaco ate o fim da linha" {
        $result = Remove-SecretsFromText 'Password=P@ss w0rd'
        $result | Should -Not -Match "w0rd"
    }

    It "nao mascara codigo Pascal comum" {
        $text = "  Key := 1;"
        Remove-SecretsFromText $text | Should -Be $text
    }
}
