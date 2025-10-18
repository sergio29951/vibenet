
# VibeNet (stable HUD build)

Questa è la versione stabile approvata di **VibeNet** con:
- ✅ Login Firebase funzionante
- ✅ Stanze vocali (Realtime Database)
- ✅ Comando vocale **"ping"** che mostra l'HUD **NetPulse** in basso a destra
- ✅ HUD gamer con Ping/Loss/Bitrate reali (sincronizzati via Firestore/RTDB)

## Setup rapido

1. Assicurati di avere Flutter installato.
2. Nella root del progetto:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```

## Deploy GitHub Pages

Se il repository si chiama `VibeNetv2`:

```bash
flutter build web --base-href '/VibeNetv2/'
git add build/web -f
git commit -m "Deploy web"
git push origin main
```

Su GitHub → **Settings → Pages**:
- Source: **Deploy from a branch**
- Branch: `main`
- Folder: `/ (root)`
