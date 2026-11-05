# SGW Complete - Kurulum Rehberi

## Sunucu Tarafı (C# Plugin)

### Gereksinimler
- .NET 11 SDK
- AssettoServer 0.0.55 preview 44

### Derleme (GitHub Actions ile otomatik)
1. Repoyu GitHub'a pushlayın
2. Actions sekmesinden "Build SGW.Complete.Server" workflow'unu çalıştırın
3. Artifacts'tan `SGW.Complete.Server.dll` indirin

### Manuel Derleme
```bash
cd src/SGW.Complete.Server
dotnet restore
dotnet build -c Release
dotnet publish -c Release -o ./publish
```

### Yükleme
```bash
# Linux
cp ./publish/SGW.Complete.Server.dll /home/assettoserver/plugins/

# Windows
copy .\publish\SGW.Complete.Server.dll "C:\AssettoServer\plugins\"
```

### Sunucuyu Yeniden Başlat
Plugin loglarında şunu görmelisiniz:
```
╔══════════════════════════════════════╗
║   SÖNMEZ GAME WORLD - COMPLETE PLUGIN ║
║   Version: 1.0.0                    ║
╚══════════════════════════════════════╝
All modules initialized successfully
```

## İstemci Tarafı (CSP Lua App)

### Gereksinimler
- Assetto Corsa CSP 0.2.12+

### Kurulum
```bash
# Windows
# Şu klasöre kopyalayın:
# C:\Program Files (x86)\Steam\steamapps\common\assettocorsa\apps\lua\SGW_Complete\

# Linux (Steam Proton)
# ~/.steam/steam/steamapps/common/assettocorsa/apps/lua/SGW_Complete/
```

### Klasör Yapısı
```
apps/lua/SGW_Complete/
├── manifest.json
├── main.lua
├── shared/
├── carswap/
├── wheelswap/
├── stance/
├── skinswap/
└── race/
```

### icon.png
`assets/icon.png` dosyasını `apps/lua/SGW_Complete/assets/icon.png` konumuna kopyalayın.

## Python Araçları (Jant/Skin Üretimi)

```bash
cd python
pip install -r requirements.txt

# AC cars yolunu ayarlayın
# Windows PowerShell:
$env:AC_CARS_PATH = "C:\Program Files (x86)\Steam\steamapps\common\assettocorsa\content\cars"

# Linux/Mac:
export AC_CARS_PATH="/path/to/assettocorsa/content/cars"

# Jantları ayıkla
python extract_wheels.py
# Çıktı: python/output/wheels_index.json

# Skinleri üret
python generate_skins.py
# Her araç için skins/SGW_* klasörleri oluşur
```

## Kullanım (Oyun İçi)

| Tuş | Modül |
|-----|-------|
| **F1** | CarSwap - Görsel Araç Değiştirme |
| **F2** | WheelSwap - Jant Değiştirme |
| **F3** | Stance - Kamber/Offset Ayarı |
| **F4** | SkinSwap - Kaplama/Renk Değiştirme |
| **F5** | Race - Yarış Başlatma |

## Bilinen Kısıtlar

1. **KN5 çalışma anında yüklenemez** → Slot değiştirme (entry_list rezerve slotları) kullanılır
2. **Diğer oyuncuların node'ları değiştirilemez** → Sadece state sync, görsel taklit
3. **Cockpit kamera offset** → CSP 0.2.x'te `ac.setCockpitCameraOffset` varsa çalışır
4. **Gerçek ışınlama** → Sadece sunucu C# plugin ile (`car.Teleport()`)
5. **Materyal texture değiştirme** → `ac.setMaterialTexture` varsa canlı, yoksa slot swap