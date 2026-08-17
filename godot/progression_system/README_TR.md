# TüpKafa — Komple koşu mimarisi

Ana test sahnesi: `res://progression_system/CompleteSystemDemo.tscn`

Bu klasör, mevcut `modular_robot` ve `wave_system` modüllerini koşu içi EXP/buff katmanıyla birleştirir. Web performansı için düşmanlar, mermiler ve EXP kristalleri havuzlanır; buff'lar temel Resource/veritabanı değerlerini değiştirmez.

## Node hiyerarşisi

```text
CompleteSystemDemo (Node2D)
├── Arena (WaveSystemDemo)
│   ├── Projectiles (ProjectilePool, 128 ön-üretim / 320 aktif tavan)
│   ├── EnemyPool (Node2D)
│   ├── SpawnPoints (Node2D + 8 Marker2D)
│   ├── ArenaCenter (Marker2D)
│   ├── Player (CharacterBody2D)
│   │   ├── AimPivot (Node2D)
│   │   │   ├── TüpKafaSprite (AnimatedSprite2D)
│   │   │   └── Hardpoints (Node2D)
│   │   │       ├── Marker2D_RightArm   [Slot 1]
│   │   │       ├── Marker2D_LeftArm    [Slot 2]
│   │   │       ├── Marker2D_Shoulders  [Slot 3]
│   │   │       └── Marker2D_Back       [Slot 4]
│   │   ├── CollisionShape2D
│   │   ├── PanicTimer
│   │   └── WeaponManager
│   ├── WaveManager
│   └── BossHealthUI (CanvasLayer)
├── ExpOrbPool (96 kristal önceden hazırlanır)
├── ExpManager (level, cap, EXP eğrisi)
├── BuffSystem (seed, rarity, teklifler, koşu çarpanları)
├── LevelUpUI (CanvasLayer, pause sırasında ALWAYS)
│   └── Overlay / Center / Cards / 4 × LevelUpCard
├── RunProgression (sistemler arası koordinatör)
└── RunHUD (HP, EXP, Level, Wave)
```

## Sorumluluk ayrımı

- `Player.gd`: WASD/ok tuşları, fareye bakış, 120 HP, 240 hız ve 3 saniyelik `%30` Panik Modu. Silah türlerini bilmez.
- `WeaponManager.gd`: Dört slotu, 12 silahlık veritabanını ve koşu çarpanlarının takılı silahlara dağıtılmasını yönetir.
- `WaveManager.gd`: Normal, 9'un katı swarm ve 10'un katı boss kurallarını yürütür. Üç Boss'u seed'li, rastgele bir torbadan seçer; aynı Boss arka arkaya gelmez.
- `EnemyPool.gd`: Düşmanı silmek/yeniden üretmek yerine pasifleştirip havuza döndürür; ölüm konumu ile EXP değerini yayınlar.
- `ExpManager.gd`: EXP eğrisi ve `level_cap=60`. Ölümde seviye 1'e döner.
- `BuffSystem.gd`: `%60/%30/%10` rarity, Luck etkisi, dört teklif, seçim doğrulaması ve yalnızca mevcut koşuya ait modifier'lar.
- `RunProgression.gd`: Level sinyalinde oyunu durduran UI'ı açar; seçimi Player/Weapon/EXP katmanlarına uygular ve ölümde hepsini sıfırlar.

## Buff dengesi ve leaderboard güvenliği

Temel rarity oranları Common `%60`, Rare `%30`, Epic `%10` olarak korunur. Luck nadir kart olasılığını sınırlı biçimde artırır. Lifesteal toplam `%4` ve saniyede `4 HP` ile sınırlandırılmıştır; yüksek atış hızının ölümsüzlük üretmesi engellenir.

Her teklif `offer_id`, `level`, `buff_id` ve `rarity` taşır. `BuffSystem.apply_choice()` yalnızca son sunulan dört karttan birini bir kez kabul eder. `get_verification_payload()` koşu seed'i ile seçim geçmişini verir. Gerçek leaderboard güvenliği için sunucu; seed'i kendisi üretmeli, skor gönderildiğinde dalga/süre/öldürme/teklif geçmişini yeniden doğrulamalıdır. İstemci kodu tek başına hileyi kesin olarak engelleyemez.

## Akış

1. Düşman ölür; `EnemyPool.enemy_defeated` konum ve EXP yayınlar.
2. `ExpManager` havuzdan kristal alır.
3. Kristal mıknatıs alanına girer ve oyuncuya akar.
4. Level yükselince `RunProgression` dört deterministik kart üretir.
5. `LevelUpUI` `SceneTree.paused=true` yapar; UI `PROCESS_MODE_ALWAYS` olduğu için seçilebilir kalır.
6. Seçim doğrulanır, modifier'lar uygulanır, oyun devam eder.
7. Oyuncu ölünce EXP, kartlar, seçim geçmişi ve tüm koşu modifier'ları sıfırlanır.
