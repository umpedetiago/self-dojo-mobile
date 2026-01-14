#!/bin/bash
# Script para build e distribuição Android via Firebase App Distribution
# Uso: ./scripts/distribute-android.sh [--release] [--groups "group1,group2"] [--notes "Release notes"]

set -e

RELEASE=false
GROUPS=""
NOTES="Build automático via script"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --release)
            RELEASE=true
            shift
            ;;
        --groups)
            GROUPS="$2"
            shift 2
            ;;
        --notes)
            NOTES="$2"
            shift 2
            ;;
        *)
            echo "Opção desconhecida: $1"
            exit 1
            ;;
    esac
done

echo "🚀 Iniciando build e distribuição Android..."

# Verifica se Flutter está instalado
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter não encontrado. Instale o Flutter primeiro."
    exit 1
fi

# Verifica se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrado. Instale com: npm install -g firebase-tools"
    exit 1
fi

# Verifica se está logado no Firebase
if ! firebase login:list &> /dev/null; then
    echo "❌ Você precisa estar logado no Firebase. Execute: firebase login"
    exit 1
fi

# Limpa builds anteriores
echo "🧹 Limpando builds anteriores..."
flutter clean

# Obtém informações da versão
VERSION=$(grep -E "^version:" pubspec.yaml | sed -E 's/version: +([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)/\1+\2/')
if [ -z "$VERSION" ]; then
    echo "⚠️  Não foi possível detectar a versão do pubspec.yaml"
    VERSION="1.0.0+1"
fi

echo "📦 Versão: $VERSION"

# Define o tipo de build
BUILD_TYPE="debug"
if [ "$RELEASE" = true ]; then
    BUILD_TYPE="release"
fi

APK_PATH="build/app/outputs/flutter-apk/app-$BUILD_TYPE.apk"

echo "🔨 Construindo APK ($BUILD_TYPE)..."
if [ "$RELEASE" = true ]; then
    flutter build apk --release
else
    flutter build apk --debug
fi

if [ ! -f "$APK_PATH" ]; then
    echo "❌ APK não encontrado em: $APK_PATH"
    exit 1
fi

echo "✅ APK construído com sucesso!"

# Prepara comando de distribuição
DISTRIBUTE_CMD="firebase appdistribution:distribute \"$APK_PATH\" --app 1:1055602452052:android:f0a676d51bdded4d2d2fc1"

if [ -n "$GROUPS" ]; then
    DISTRIBUTE_CMD="$DISTRIBUTE_CMD --groups \"$GROUPS\""
fi

if [ -n "$NOTES" ]; then
    DISTRIBUTE_CMD="$DISTRIBUTE_CMD --release-notes \"$NOTES\""
fi

echo "📤 Distribuindo via Firebase App Distribution..."
echo "   Comando: $DISTRIBUTE_CMD"

eval $DISTRIBUTE_CMD

if [ $? -eq 0 ]; then
    echo "✅ Distribuição concluída com sucesso!"
    echo "📱 Os testadores receberão um email com o link para download"
else
    echo "❌ Erro ao distribuir o app"
    exit 1
fi

