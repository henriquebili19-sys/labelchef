# Encerra o Agente de Impressao que esta rodando escondido em segundo plano.
# Uso: precisa disso antes de atualizar o codigo do agente, por exemplo.

$processos = Get-CimInstance Win32_Process -Filter "Name = 'node.exe'" |
    Where-Object { $_.CommandLine -and $_.CommandLine -like "*dist\index.js*" }

if (-not $processos) {
    Write-Host "Nenhum Agente de Impressao rodando no momento." -ForegroundColor Yellow
    exit 0
}

foreach ($p in $processos) {
    Stop-Process -Id $p.ProcessId -Force
    Write-Host "Agente encerrado (PID $($p.ProcessId))." -ForegroundColor Green
}
