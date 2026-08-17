# NEONFALL Wave System — Web Performanslı Dalga ve Boss Mimarisi

`WaveSystemDemo.tscn` yeni TüpKafa Player, dört normal düşman, EnemyPool,
WaveManager, sekiz kenar spawn noktası ve Boss Health UI içeren bağımsız test
sahnesidir. Mevcut canlı ana sahne henüz bu modüle geçirilmemiştir.

## Node hiyerarşisi

```text
WaveSystemDemo (Node2D)
├── Background
├── Projectiles
├── EnemyPool (Node2D) [EnemyPool.gd]
├── SpawnPoints (Node2D)
│   ├── NorthWest / North / NorthEast
│   ├── East / West
│   └── SouthWest / South / SouthEast
├── ArenaCenter (Marker2D)
├── Player (TüpKafa)
├── WaveManager (Node) [WaveManager.gd]
└── BossHealthUI (CanvasLayer) [BossHealthUI.gd]
```

## Dalga kuralları

- Normal dalga düşman sayısı: `8 + wave × 3`.
- Her dokuzuncu dalga: toplam sayı iki katına çıkar.
- Swarm düşmanları daha düşük canlı fakat %16 daha hızlı başlar.
- Her onuncu dalga: normal spawn kuyruğu oluşturulmaz, yalnızca Boss doğar.
- Bir sayı hem 9'a hem 10'a bölünüyorsa Boss kuralı önceliklidir. Örneğin Wave
  90 bir Boss dalgasıdır.
- Boss sırası: Mega-Monitor → Kaset-Kral → UFO-Ana Gemisi → tekrar başa dönüş.
- İlk üç Boss sırasıyla 800, 1000 ve 1200 temel canla gelir. Can artışı ancak
  üçlü rotasyon tamamlanıp aynı Boss ikinci kez göründüğünde uygulanır.

Wave 9 örneği:

```text
Normal temel: 8 + 9 × 3 = 35
Swarm toplamı: 35 × 2 = 70
```

Wave 18'de toplam 124 hedef vardır fakat aynı anda en fazla 72 aktif düşman
bulunur. Bir düşman havuza döndükçe sıradaki düşman doğar.

## Web performansı

### Object Pooling

`EnemyPool`, her normal düşman türünden 18 örneği başlangıçta hazırlar. Ölen
düşmana `queue_free()` uygulanmaz:

```text
active enemy
→ take_damage
→ defeated signal
→ EnemyPool.release
→ görünmez + physics process kapalı
→ available[type] havuzuna geri eklenir
```

Sonraki spawn aynı Node örneğini tekrar etkinleştirir. Böylece yoğun dalgalarda
sürekli Node oluşturma, script başlatma ve bellek temizleme sıçramaları azalır.

### Spawn bütçesi

Bir fizik karesinde en fazla üç düşman etkinleştirilir. Swarm kuyruğu hızlıdır
fakat bütün düşmanlar tek karede oluşturulmaz. Varsayılan aktif düşman tavanı
72'dir.

### Fizik maliyeti

Düşman kökü `CharacterBody2D` olarak kalır; mermiler bu gövdeye çarpabilir.
Ancak her düşmanda her kare `move_and_slide()` çalıştırılmaz. Sürü hareketi
doğrudan konum güncellemesiyle, oyuncu teması ise yarıçap mesafesiyle hesaplanır.
Düşman-düşman fizik maskesi kapalıdır; yüzlerce gövde birbirini itmeye çalışmaz.

## Normal düşman davranışları

- `blobby`: Oyuncuya yaklaşır, görsel olarak zıplayıp esner.
- `ufo_head`: Oyuncunun çevresinde teğetsel hareket eder; artık ışın saldırısı kullanmaz.
- `laser_lemon`: Oyuncu 330 px yakına gelince %42 hızlanır.
- `space_donkey`: Yavaş tanktır; temasta yüksek hasar ve 540 birim knockback verir.

## Boss davranışları

- `mega_monitor`: Uzaklığı korur, periyodik lazer halkası saldırısı yapar.
- `mixtape_mech`: Ses dalgasıyla hasar ve knockback uygular.
- `mother_disk`: Savaş boyunca havuzdan Blobby çağırır.

Boss, `ArenaCenter` Marker2D noktasında doğar. `boss_spawned` sinyali UI panelini
açar ve ProgressBar maksimum değerini ayarlar. Boss her hasar aldığında
`boss_health_changed` sinyali barı günceller; ölünce panel kapanır.

```gdscript
wave_manager.boss_spawned.connect(_on_boss_spawned)
wave_manager.boss_health_changed.connect(_on_boss_health_changed)
wave_manager.boss_defeated.connect(_on_boss_defeated)
```

## Ana oyuna bağlama

Ana haritaya `EnemyPool`, `WaveManager`, kenar `Marker2D` noktaları ve
`BossHealthUI` eklenir. WaveManager Inspector alanlarında Player, EnemyPool,
SpawnPoints ve ArenaCenter NodePath değerleri atanır. Bu işlem tamamlanmadan
canlı Godot/Web ana sahnesi değiştirilmemelidir.
