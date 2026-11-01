BeforeAll {
    $script:Hub = Split-Path -Parent $PSScriptRoot
    . (Join-Path $script:Hub "lib\ProcessService.ps1")
}

Describe "Invoke-CliWithTimeout" {
    It "envia o texto pelo stdin e devolve a saida" {
        $script = '$x = [Console]::In.ReadToEnd(); Write-Output ("eco:" + $x)'
        $result = Invoke-CliWithTimeout -Command "powershell.exe" -Arguments @("-NoProfile", "-Command", $script) -InputText "ola" -Name "Eco" -TimeoutSeconds 60
        $result | Should -Match "eco:ola"
    }

    It "encerra o processo no timeout e nao espera o fim da execucao" {
        $start = Get-Date
        { Invoke-CliWithTimeout -Command "powershell.exe" -Arguments @("-NoProfile", "-Command", "Start-Sleep -Seconds 60") -InputText "" -Name "Travado" -TimeoutSeconds 3 } | Should -Throw "*excedeu 3 s*"
        ((Get-Date) - $start).TotalSeconds | Should -BeLessThan 30
    }

    It "informa claramente quando o executavel nao existe" {
        { Invoke-CliWithTimeout -Command "comando-que-nao-existe-123" -InputText "x" -Name "Fantasma" } | Should -Throw "*nao encontrado no PATH*"
    }
}
