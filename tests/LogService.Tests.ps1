BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\PathService.ps1")
    . (Join-Path $script:Hub "lib\ConfigService.ps1")
    . (Join-Path $script:Hub "lib\LogService.ps1")

    $script:LogDir = Join-Path ([System.IO.Path]::GetTempPath()) ("gh-log-" + [guid]::NewGuid())
    $script:LogFile = Join-Path $script:LogDir "debug.log"
    $env:LOG_PATH = $script:LogFile
}

AfterAll {
    Remove-Item Env:LOG_PATH -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $script:LogDir -ErrorAction SilentlyContinue
}

Describe "Write-Log" {
    It "cria o arquivo e a pasta de log quando nao existem" {
        Write-Log "primeira linha" -Clear
        Test-Path $script:LogFile | Should -BeTrue
    }

    It "limpa o log com -Clear" {
        Write-Log "antiga"
        Write-Log "nova" -Clear
        $content = Get-Content $script:LogFile -Raw
        $content | Should -Match "nova"
        $content | Should -Not -Match "antiga"
    }

    It "acumula linhas sem -Clear" {
        Write-Log "um" -Clear
        Write-Log "dois"
        $lines = @(Get-Content $script:LogFile)
        $lines.Count | Should -Be 2
        $lines[1] | Should -Match "\] dois$"
    }

    It "inclui timestamp no formato yyyy-MM-dd HH:mm:ss" {
        Write-Log "com data" -Clear
        Get-Content $script:LogFile -Raw | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] com data"
    }
}
