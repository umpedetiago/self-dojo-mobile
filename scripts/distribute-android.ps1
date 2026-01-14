# Script para build e distribuição Android via Firebase App Distribution
# Uso: .\scripts\distribute-android.ps1 [-Release] [-Groups "group1,group2"] [-Notes "Release notes"]

param(
    [switch]$Release = $false,
    [string]$Groups = "",
    [string]$Notes = "Build automático via script"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando build e distribuição Android..." -ForegroundColor Cyan

# Verifica se Flutter está instalado
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Flutter não encontrado. Instale o Flutter primeiro." -ForegroundColor Red
    exit 1
}

# Verifica se Firebase CLI está instalado
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Firebase CLI não encontrado. Instale com: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

# Verifica se está logado no Firebase
$firebaseUser = firebase login:list 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Você precisa estar logado no Firebase. Execute: firebase login" -ForegroundColor Red
    exit 1
}

# Limpa builds anteriores
Write-Host "🧹 Limpando builds anteriores..." -ForegroundColor Yellow
flutter clean

# Obtém informações da versão
$pubspecContent = Get-Content "pubspec.yaml" -Raw
$versionMatch = $pubspecContent -match "version:\s*(\d+\.\d+\.\d+)\+(\d+)"
if ($versionMatch) {
    $version = $matches[1]
    $buildNumber = $matches[2]
    Write-Host "📦 Versão: $version+$buildNumber" -ForegroundColor Green
} else {
    Write-Host "⚠️  Não foi possível detectar a versão do pubspec.yaml" -ForegroundColor Yellow
    $version = "1.0.0"
    $buildNumber = "1"
}

# Define o tipo de build
$buildType = if ($Release) { "release" } else { "debug" }
$apkPath = "build\app\outputs\flutter-apk\app-$buildType.apk"

Write-Host "🔨 Construindo APK ($buildType)..." -ForegroundColor Yellow
if ($Release) {
    flutter build apk --release
} else {
    flutter build apk --debug
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Erro ao construir o APK" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $apkPath)) {
    Write-Host "❌ APK não encontrado em: $apkPath" -ForegroundColor Red
    exit 1
}

Write-Host "✅ APK construído com sucesso!" -ForegroundColor Green

# Prepara comando de distribuição
$distributeCmd = "firebase appdistribution:distribute `"$apkPath`" --app 1:1055602452052:android:f0a676d51bdded4d2d2fc1"

if ($Groups -ne "") {
    $distributeCmd += " --groups `"$Groups`""
}

if ($Notes -ne "") {
    $distributeCmd += " --release-notes `"$Notes`""
}

Write-Host "📤 Distribuindo via Firebase App Distribution..." -ForegroundColor Yellow
Write-Host "   Comando: $distributeCmd" -ForegroundColor Gray

Invoke-Expression $distributeCmd

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Distribuição concluída com sucesso!" -ForegroundColor Green
    Write-Host "📱 Os testadores receberão um email com o link para download" -ForegroundColor Cyan
} else {
    Write-Host "❌ Erro ao distribuir o app" -ForegroundColor Red
    exit 1
}

