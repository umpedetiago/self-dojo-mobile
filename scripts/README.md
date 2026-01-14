# Scripts de Distribuição

Scripts para facilitar a distribuição de builds via Firebase App Distribution.

## Scripts Disponíveis

### Android

#### Windows (PowerShell)
```powershell
.\scripts\distribute-android.ps1 [-Release] [-Groups "group1,group2"] [-Notes "Release notes"]
```

#### Linux/Mac (Bash)
```bash
./scripts/distribute-android.sh [--release] [--groups "group1,group2"] [--notes "Release notes"]
```

### iOS (Mac apenas)
```bash
./scripts/distribute-ios.sh [--groups "group1,group2"] [--notes "Release notes"]
```

## Exemplos de Uso

### Build Debug Android
```powershell
# Windows
.\scripts\distribute-android.ps1

# Linux/Mac
./scripts/distribute-android.sh
```

### Build Release Android com Grupos
```powershell
# Windows
.\scripts\distribute-android.ps1 -Release -Groups "testadores,beta" -Notes "Versão 1.0.0"

# Linux/Mac
./scripts/distribute-android.sh --release --groups "testadores,beta" --notes "Versão 1.0.0"
```

## Pré-requisitos

1. Firebase CLI instalado: `npm install -g firebase-tools`
2. Logado no Firebase: `firebase login`
3. Firebase App Distribution habilitado no projeto

Para mais detalhes, veja [FIREBASE_DISTRIBUTION.md](../docs/FIREBASE_DISTRIBUTION.md).

