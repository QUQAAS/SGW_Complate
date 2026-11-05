# SGW.Complete.Server - Hızlı Build Scripti
# Yönetici olarak PowerShell'de çalıştırın

Write-Host "=== SGW Complete Server Build ===" -ForegroundColor Cyan

$projectPath = "src\SGW.Complete.Server"
$outputPath = "artifacts"

if (-not (Test-Path $projectPath)) {
    Write-Error "Proje bulunamadı: $projectPath"
    exit 1
}

$dotnetVersion = dotnet --version
if (-not $dotnetVersion.StartsWith("11.")) {
    Write-Warning ".NET 11 bulunamadı. Mevcut: $dotnetVersion"
}

Write-Host "Restoring..." -ForegroundColor Yellow
dotnet restore $projectPath

Write-Host "Building Release..." -ForegroundColor Yellow
dotnet build $projectPath -c Release --no-restore

Write-Host "Publishing..." -ForegroundColor Yellow
dotnet publish $projectPath -c Release -o $outputPath --no-build

Write-Host "=== BUILD TAMAMLANDI ===" -ForegroundColor Green
Write-Host "DLL konumu: $outputPath\SGW.Complete.Server.dll"
Write-Host "Bunu sunucunuzun plugins/ klasörüne kopyalayın."