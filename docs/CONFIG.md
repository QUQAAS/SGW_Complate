# SGW Complete - Yapılandırma

## Config Dosyası
Konum: `Documents/Assetto Corsa/cfg/SGW_Complete.json`

## Temel Ayarlar

### Tema Renkleri
```json
{
  "theme": {
    "primary": [0.85, 0.15, 0.15, 1.0],      // Ana kırmızı
    "background": [0.08, 0.08, 0.09, 0.98],   // Arka plan
    "panel": [0.12, 0.12, 0.13, 1.0],         // Panel arka plan
    "text": [1.0, 1.0, 1.0, 1.0],             // Beyaz yazı
    "textDim": [0.7, 0.7, 0.7, 1.0],          // Soluk yazı
    "success": [0.2, 0.85, 0.3, 1.0],         // Yeşil (başarı)
    "warning": [1.0, 0.85, 0.15, 1.0],        // Sarı (uyarı)
    "danger": [0.9, 0.2, 0.2, 1.0]            // Kırmızı (tehlike)
  }
}
```

### Tuş Atamaları (Virtual Key Codes)
```json
{
  "keybinds": {
    "openMainMenu": 112,    // F1 - CarSwap
    "openWheelMenu": 113,   // F2 - WheelSwap
    "openStanceMenu": 114,  // F3 - Stance
    "openSkinMenu": 115,    // F4 - SkinSwap
    "openRaceMenu": 116     // F5 - Race
  }
}
```

### Modül Ayarları
```json
{
  "carswap": {
    "autoApplyFineTune": true,
    "showCompatibilityIndicators": true,
    "maxScaleDeviation": 0.05
  },
  "wheelswap": {
    "previewRotationSpeed": 1.0
  },
  "stance": {
    "maxCamber": 5.0,
    "maxOffset": 5.0
  },
  "race": {
    "inviteTimeout": 15,
    "countdownDuration": 3,
    "showGreenLine": true,
    "greenLineWidth": 12.0
  }
}
```

## Sunucu Yapılandırması

### entry_list.ini
Plugin otomatik olarak her model için 3 rezerve slot ekler (`sgw_reserved` skin'i ile). Manuel müdahale gerekmez.

### Fine-tune Kaydetme
Oyuncu ince ayar yapıp "Kaydet" dediğinde:
`plugins/SGW_Complete/finetunes/{sourceModel}_{targetModel}.json`

## Log Seviyeleri
Plugin `IPluginLogger` kullanır:
- `LogInformation` - Genel bilgi
- `LogWarning` - Uyarılar
- `LogError` - Hatalar