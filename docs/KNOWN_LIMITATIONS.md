# Bilinen Kısıtlar ve Çözümler

## 1. KN5 Çalışma Anında Yüklenemez
**Sorun:** CSP Lua SDK'da `ac.loadKN5` fonksiyonu yok. KN5 dosyaları oyun başlangıcında yüklenir.

**Çözüm:** Slot değiştirme (Entry List rezerve slotları)
- Sunucu her model için 3 rezerve slot tutar
- Oyuncu araç değiştirdiğinde sunucu o slotu oyuncunun skin/ismiyle doldurur
- Client tarafında model otomatik yenilenir (kısa loading ekranı olur)

**Etki:** Model değiştirmede ~1-2 saniyelik geçiş gecikmesi olur.

## 2. Diğer Oyuncuların Node'ları Değiştirilemez
**Sorun:** CSP'de `ac.findNode`/`ac.setNodePosition` sadece kendi aracınız (focused car) için çalışır.

**Çözüm:** State broadcast + görsel taklit
- Sunucu swap yapılan oyuncunun verilerini (model, wheel fit) herkese broadcast eder
- Diğer client'larda o aracın görseli değiştirilemez, sadece bilgi alınır
- Yarış modülünde bitiş çizgisi ve HUD herkesde kendi client'ında çizilir

**Etki:** Diğer oyuncuların araç değişimini göremezsiniz (sadece kendi ekranınızda olur).

## 3. Cockpit Kamera Offset
**Sorun:** `ac.getCockpitCameraOffset` / `ac.setCockpitCameraOffset` CSP 0.2.x'te eklenmiş olabilir, garantili değil.

**Durum:** Kodda `hasCockpitOffsetApi` kontrolü var, yoksa graceful degrade eder.

**Yedek:** Manuel ayar butonu eklenebilir (Settings menüsünde).

## 4. Gerçek Işınlama (Teleport)
**Sorun:** `ac.setCarPosition` / `ac.teleportCar` sadece client-side görsel etkisi yapar, fizik motoru ezber.

**Çözüm:** Sunucu C# plugin'de `car.Teleport()` / `car.SetPosition()` kullanılır.
- Race modülünde grid dizilme sunucu yapar
- CarSwap'te slot değiştirme sunucu yapar (entry list güncelleme)

## 5. Materyal Texture Değiştirme
**Sorun:** `ac.setMaterialTexture` CSP 0.2.x'te varsa canlı skin swap çalışır, yoksa çalışmaz.

**Durum:** Kodda kontrol var, yoksa log yazar.

**Yedek:** Slot değiştirme (skin değiştirip reconnect) - CarSwap mantığıyla aynı.

## 6. Jant Mesh Değiştirme
**Sorun:** `ac.setNodeMesh` CSP'de mevcut mu belirsiz.

**Durum:** WheelApplier placeholder olarak yazıldı, API yoksa log yazar.

**Çözüm:** Python scripti ile jant mesh'lerini ayıklayıp ayrı KN5 olarak kaydetmek gerekebilir (ileri sürüm).

## 7. Yarış Modülü - Puan Hesaplama
**Sorun:** Makas/Drift yarışlarda "yakın geçiş" ve "drift açısı" hesaplaması sunucuda `car.Position`, `car.Velocity`, `car.Rotation` erişimine bağlı.

**Mevcut Durum:** Temel iskelet hazır, `UpdateRacerPositions` mesafe takibi yapıyor. Detaylı puan mantığı RaceManager'da genişletilebilir.

## 8. Çoklu Sunucu (140 Sunucu)
**Sorun:** Her sunucu ayrı process, plugin her sunucuda ayrı yüklenir.

**Çözüm:** Plugin durum tutmaz (stateless), entry_list'te rezerve slotlar sunucuya özgüdür. Fine-tune dosyaları `plugins/SGW_Complete/finetunes/` altına sunucu bazında kaydedilir.

## 9. CSP Sürüm Farkları
**Minimum:** CSP 0.2.12
- `ac.draw3DLine`, `ac.onRender3D` → 0.2.x'te eklendi
- `ac.setCockpitCameraOffset` → 0.2.x'te eklenmiş olabilir
- `ac.sendClientEvent` → Client-to-client event için

**Test:** Farklı CSP sürümlerinde test edilmeli.

## 10. Performans
- **CarSwap:** Her frame `WheelFitter.applyFit` çağrılır (4 node position set)
- **Race:** Her 100ms bir `RaceUpdate` broadcast edilir
- **Stance:** Sadece değer değişince broadcast edilir
- **5 oyuncu/sunucu** için performans sorunu yok

## Çözüm Yol Haritası

| Özellik | v1.0 | v1.1 | v1.2 |
|---------|------|------|------|
| CarSwap (slot swap) | ✅ | - | - |
| WheelSwap (mesh swap) | ⚠️ Partial | ✅ | - |
| Stance | ✅ | - | - |
| SkinSwap (texture) | ⚠️ Partial | ✅ | - |
| Race (Sprint/Endurance) | ✅ | - | - |
| Race (Cannonball/Drift) | ⚠️ Basic | ✅ | - |
| Fine-tune persist | ✅ | - | - |
| Multi-server config | ✅ | - | - |

⚠️ = Temel iskelet var, API kullanılabilirliğine bağlı tam çalışır