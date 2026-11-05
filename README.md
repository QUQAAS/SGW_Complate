# SGW Complete - Sönmez Game World Assetto Corsa Plugin Pack

**AssettoServer 0.0.55 preview 44** + **CSP 0.2.12** için yazılmış, internet kafeleri için optimize edilmiş mod paketi.

## Özellikler

### 🎨 Modül 1: CarSwap - Görsel Araç Değiştirme
- Menüden sunucudaki başka bir arabayı seç
- Kendi modelin gizlenir, hedef model yüklenir (slot swap yöntemi)
- Tekerlek yerleştirme otomatik (suspensions.ini + tyres.ini verileri)
- Uyumluluk göstergesi (🟢/🟡/🔴) + ince ayar kaydetme
- Fizik ve motor sesi değişmez, sadece görsel

### 🛞 Modül 2: WheelSwap - Jant Değiştirme
- Python scripti ile tüm araçlardan jant mesh'lerini ayıkla
- Menüden jant seç, 4 tekerleğe tak, online senkron

### 📐 Modül 3: Stance - Kamber/Offset
- Ön/Arka kamber (±5°) ve offset (±5 cm) kaydırıcıları
- Sadece görsel, online senkron, sıfırla butonu

### 🎨 Modül 4: SkinSwap - Kaplama/Renk
- Canlı skin değiştirme (materyal texture swap)
- Python scripti: her araç için SGW marka renklerinde skin klasörleri üret

### 🏁 Modül 5: RacePlugin - Yarış Başlatma
- **Sprint / Uzun / Makas / Drift** yarış türleri
- Davet sistemi (plugin kapalıyken bile kart açılır)
- Otomatik grid dizilme (yan yana, yola göre)
- 3-2-1 geri sayım + araç kilitleme
- Bitiş çizgisi: yerde yeşil çizgi (3D render)
- Sonuç ekranı (sıralama, puan, kombo)

## Teknik Mimari

```
┌─────────────────────────────────────┐
│  Sunucu: SGW.Complete.Server.dll    │  ← Tek C# plugin (NET 11)
│  - CarSwapManager                   │
│  - RaceManager + InviteSystem       │
│  - StanceSync + SkinSwapSync        │
└─────────────────────────────────────┘
                    │ Online Events
                    ▼
┌─────────────────────────────────────┐
│  İstemci: SGW_Complete (Lua App)    │  ← Tek CSP app (her zaman yüklü)
│  - CarSwapModule + Menu             │
│  - WheelSwapModule                  │
│  - StanceModule                     │
│  - SkinSwapModule                   │
│  - RaceModule (HUD, InviteCard)     │
└─────────────────────────────────────┘
```

## Derleme

### GitHub Actions (Önerilen)
1. Repo fork'layın / klonlayın
2. GitHub'a pushlayın
3. Actions → "Build SGW.Complete.Server" → Run workflow
4. Artifacts'tan `SGW.Complete.Server.dll` indirin

### Lokal
```bash
# .NET 11 SDK gerekli
cd src/SGW.Complete.Server
dotnet restore
dotnet build -c Release
dotnet publish -c Release -o ../artifacts
```

### Windows PowerShell
```powershell
.\build.ps1
```

## Kurulum

### Sunucu
```bash
cp artifacts/SGW.Complete.Server.dll /path/to/assettoserver/plugins/
# Sunucuyu yeniden başlat
```

### İstemci (Her oyuncu PC'sinde)
```
apps/lua/SGW_Complete/  ← lua/ klasörünün içeriğini kopyalayın
assets/icon.png         ← apps/lua/SGW_Complete/assets/icon.png
```

### Python Araçları (Opsiyonel - Jant/Skin üretimi için)
```bash
cd python
pip install -r requirements.txt
$env:AC_CARS_PATH = "C:\...\assettocorsa\content\cars"
python extract_wheels.py
python generate_skins.py
```

## Oyun İçi Kullanım

| Tuş | Modül |
|-----|-------|
| **F1** | CarSwap - Görsel Araç Değiştirme |
| **F2** | WheelSwap - Jant Değiştirme |
| **F3** | Stance - Kamber/Offset Ayarı |
| **F4** | SkinSwap - Kaplama/Renk Değiştirme |
| **F5** | Race - Yarış Başlatma |

## Marka
- **İsim:** Sönmez Game World
- **Logo:** Kurt (icon.png)
- **Tema:** Kırmızı/Siyah modern, yazılar beyaz

## Bilinen Kısıtlar

1. **KN5 çalışma anında yüklenemez** → Slot değiştirme (entry_list rezerve slotları) kullanılır
2. **Diğer oyuncuların node'ları değiştirilemez** → Sadece state sync, görsel taklit
3. **Cockpit kamera offset** → CSP 0.2.x'te `ac.setCockpitCameraOffset` varsa çalışır
4. **Gerçek ışınlama** → Sadece sunucu C# plugin ile (`car.Teleport()`)
5. **Materyal texture değiştirme** → `ac.setMaterialTexture` varsa canlı, yoksa slot swap

## Lisans
Özel kullanım - Sönmez Game World