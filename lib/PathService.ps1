function Get-ProjectRoot {
    # Retorna o caminho raiz do projeto baseado na localização deste script
    return Split-Path -Parent $PSScriptRoot
}


