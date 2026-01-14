# Firebase App Distribution - Guia Rápido

## 🚀 Setup Inicial (Uma vez)

1. **Instalar Firebase CLI**
   ```bash
   npm install -g firebase-tools
   ```

2. **Login no Firebase**
   ```bash
   firebase login
   ```

3. **Habilitar App Distribution no Firebase Console**
   - Acesse: https://console.firebase.google.com/
   - Projeto: `self-dojo-mobile`
   - Menu: **App Distribution**
   - Siga as instruções para habilitar

## 📱 Distribuir Build

### Android (Windows)
```powershell
.\scripts\distribute-android.ps1 -Release -Groups "testadores" -Notes "Nova versão"
```

### Android (Linux/Mac)
```bash
chmod +x scripts/distribute-android.sh
./scripts/distribute-android.sh --release --groups "testadores" --notes "Nova versão"
```

### iOS (Mac)
```bash
chmod +x scripts/distribute-ios.sh
./scripts/distribute-ios.sh --groups "testadores" --notes "Nova versão"
```

## 👥 Criar Grupos de Testadores

1. Firebase Console > **App Distribution** > **Testers & Groups**
2. **Add group** > Nome: `testadores`
3. **Add testers** > Adicionar emails

## 🤖 CI/CD (Opcional)

1. Obter Service Account JSON do Firebase
2. GitHub > Settings > Secrets > `FIREBASE_SERVICE_ACCOUNT`
3. Actions > **Firebase App Distribution** > **Run workflow**

---

📚 **Documentação completa**: [FIREBASE_DISTRIBUTION.md](FIREBASE_DISTRIBUTION.md)

