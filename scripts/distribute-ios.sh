#!/bin/bash
# Script para build e distribuição iOS via Firebase App Distribution
# Uso: ./scripts/distribute-ios.sh [--groups "group1,group2"] [--notes "Release notes"]
# Nota: Requer macOS e Xcode

set -e

GROUPS=""
NOTES="Build automático via script"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
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

# Verifica se está no macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Este script requer macOS e Xcode"
    exit 1
fi

echo "🚀 Iniciando build e distribuição iOS..."

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

IPA_PATH="build/ios/ipa/self_dojo_mobile.ipa"

echo "🔨 Construindo IPA..."
flutter build ipa

if [ ! -f "$IPA_PATH" ]; then
    echo "❌ IPA não encontrado em: $IPA_PATH"
    exit 1
fi

echo "✅ IPA construído com sucesso!"

# Prepara comando de distribuição
DISTRIBUTE_CMD="firebase appdistribution:distribute \"$IPA_PATH\" --app 1:1055602452052:ios:725ec695964c60ab2d2fc1"

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

