BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\PathService.ps1")
    . (Join-Path $script:Hub "lib\ConfigService.ps1")
}

Describe "Get-AppConfig" {
    It "o modelo versionado define PROMPT_FILE (nao depende do settings.txt local)" {
        $example = Join-Path $script:Hub "config\settings.example.txt"
        Get-Content $example -Raw | Should -Match "(?m)^PROMPT_FILE=\S+"
    }

    It "variavel de ambiente tem prioridade sobre o arquivo" {
        $env:GH_TEST_KEY = "do-ambiente"
        try {
            Get-AppConfig "GH_TEST_KEY" | Should -Be "do-ambiente"
        }
        finally {
            Remove-Item Env:GH_TEST_KEY -ErrorAction SilentlyContinue
        }
    }

    It "chave inexistente retorna nulo" {
        Get-AppConfig "CHAVE_QUE_NAO_EXISTE_123" | Should -BeNullOrEmpty
    }

    It "INCLUDE_UNTRACKED e INCLUDE_UNSTAGED padrao sao FALSE no modelo" {
        $example = Join-Path $script:Hub "config\settings.example.txt"
        $content = Get-Content $example -Raw
        $content | Should -Match "(?m)^INCLUDE_UNTRACKED=FALSE"
        $content | Should -Match "(?m)^INCLUDE_UNSTAGED=FALSE"
    }
}
