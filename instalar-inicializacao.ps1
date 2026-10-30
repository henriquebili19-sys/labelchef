# Configura o Agente de Impressao para iniciar sozinho (sem janela) toda vez que o Windows ligar.
# Rode este script uma unica vez, depois de preencher o config.json.

$ErrorActionPreference = "Stop"
$pastaAtual = $PSScriptRoot
$vbsPath = Join-Path $pastaAtual "iniciar-oculto.vbs"
$configPath = Join-Path $pastaAtual "config.json"

if (-not (Test-Path $configPath)) {
    Write-Host "AVISO: config.json nao encontrado. Crie o arquivo com o token da empresa antes de continuar." -ForegroundColor Yellow
    Write-Host "Veja config.example.json como modelo." -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path (Join-Path $pastaAtual "node_modules"))) {
    Write-Host "Instalando dependencias..."
    npm install
}

if (-not (Test-Path (Join-Path $pastaAtual "dist\index.js"))) {
    Write-Host "Compilando o agente..."
    npm run build
}

$startupFolder = [Environment]::GetFolderPath("Startup")
$shortcutPath = Join-Path $startupFolder "AgenteImpressaoEtiquetas.lnk"

$wshShell = New-Object -ComObject WScript.Shell
$shortcut = $wshShell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$vbsPath`""
$shortcut.WorkingDirectory = $pastaAtual
$shortcut.Description = "Agente de Impressao - Sistema de Etiquetas"
$shortcut.Save()

Write-Host "Atalho criado em: $shortcutPath" -ForegroundColor Green
Write-Host "O agente vai iniciar sozinho (sem nenhuma janela) toda vez que este usuario entrar no Windows." -ForegroundColor Green

Write-Host "Iniciando o agente agora..."
Start-Process "wscript.exe" -ArgumentList "`"$vbsPath`""

Write-Host "Pronto! Confira o status em agente.log ou no painel Agente de Impressao do sistema." -ForegroundColor Green
