# TüpKafa (T.V.-80) — Dört Slotlu Robot Mimarisi

Bu klasör, mevcut canlı oyundan bağımsız hazırlanan yeni cartoon robot temelidir.
`ModularRobotDemo.tscn` sahnesi doğrudan çalıştırılarak test edilebilir.

## Sorumlulukların ayrılması

- `Player.gd`: Hareket, fareye bakma, sağlık, panik ve ölüm durumları.
- `WeaponManager.gd`: 12 silahlık veritabanı, slot kuralları ve envanter.
- `Weapon.gd`: Bütün silahların ortak istatistikleri ve Timer cooldown sistemi.
- `DatabaseWeapon.gd`: Veritabanı silahları için geçici mermi üretme davranışı.
- `Projectile.gd`: Dünya uzayında hareket eden temel mermi.

## Player Node hiyerarşisi

```text
Player (CharacterBody2D) [Player.gd]
├── Shadow
├── AimPivot                         # look_at(mouse) uygulanan düğüm
│   ├── TupKafaSprite (AnimatedSprite2D)
│   └── Hardpoints
│       ├── Marker2D_RightArm        # SLOT 1 — Ana silah
│       ├── Marker2D_LeftArm         # SLOT 2 — Yakın/alan
│       ├── Marker2D_Shoulders       # SLOT 3 — Taktiksel
│       └── Marker2D_Back            # SLOT 4 — Ağır/bitirici
├── CollisionShape2D
├── PanicTimer
└── WeaponManager [WeaponManager.gd]
```

Oyuncu kökü dönmez. Yalnızca `AimPivot.look_at(get_global_mouse_position())`
çağrılır. Cartoon robot sprite'ı ve dört silah Marker2D noktası pivotun altında
olduğu için aynı hedef yönünü paylaşır; çarpışma şekli sabit kalır.

## TüpKafa durumları

- Başlangıç canı: `120`
- Normal hız: `240 px/sn`
- Hasar sonrası panik süresi: `3 saniye`
- Panik hızı: `240 × 1.30 = 312 px/sn`
- Normal animasyon: `tough_idle`
- Panik/hasar animasyonu: `crying_hurt`
- Ölüm animasyonu: `no_signal_death`

Yeni hasar panik Timer'ını yeniden başlatır. Böylece son hasardan itibaren üç
saniye boyunca panik devam eder. Ölüm, hareketi ve otomatik ateşi kapatır.

## Slot ve envanter kuralı

`WeaponManager.inventory`, slot numarasını aktif `Weapon` örneğine eşler:

```gdscript
{
    1: pixel_peashooter_instance,
    2: mixtape_shotgun_instance,
    3: rewind_laser_instance,
    4: plot_twist_launcher_instance,
}
```

Her slot yalnızca bir silah taşıyabilir. Aynı slota yeni silah takıldığında eski
silah kaldırılır. Silahın veritabanındaki kategorisi istenen slotla uyuşmuyorsa
takma işlemi reddedilir.

Godot'taki doğru fonksiyon adı `add_child()` şeklindedir. Manager içindeki temel
takma adımı şudur:

```gdscript
var weapon: Weapon = database_weapon_scene.instantiate() as Weapon
weapon.apply_definition(definition)
marker.add_child(weapon)
weapon.position = Vector2.ZERO
weapon.rotation = 0.0
inventory[slot] = weapon
```

Player üzerinden silah değiştirme örneği:

```gdscript
player.equip_weapon(
    WeaponManager.WeaponSlot.MAIN,
    "w_flash_sync_smg"
)
```

## 12 silahlık veritabanı

| Slot | Silahlar |
| --- | --- |
| 1 — Main | Pixel Peashooter, Flash-Sync SMG, Render Beam |
| 2 — Area | Mixtape Shotgun, Battery Acid, Antenna Arc |
| 3 — Tactical | Rewind Laser, Scale Mines, Homing Drones |
| 4 — Heavy | Plot Twist Launcher, Acoustic Mic-Drop, CRT Overload Cannon |

Silahların değişken alanları aynı Dictionary içinde tutulur. Örneğin SMG
`accuracy`, Shotgun `projectiles`, Render Beam `tick_rate`, CRT Cannon ise
`charge_time` alanını kullanır. `Weapon.apply_definition()` bu farklı alanları
ortak çalışma değerlerine dönüştürür.

## Aynı anda otomatik ateş

Player her fizik karesinde tek bir Manager çağrısı yapar:

```gdscript
if auto_fire:
    weapon_manager.shoot_all()
```

Manager slotları sırayla dolaşır:

```gdscript
for slot in range(WeaponSlot.MAIN, WeaponSlot.HEAVY + 1):
    var weapon: Weapon = inventory.get(slot) as Weapon
    if is_instance_valid(weapon):
        weapon.shoot()
```

Her silahın kendi Timer'ı vardır. Bu nedenle dört silah aynı karede `shoot()`
çağrısı alsa bile yalnızca kendi cooldown süresi biten silah ateş eder.

## Mermi katmanı

Mermi silahın çocuğu yapılmaz. `Projectiles` isimli dünya katmanına eklenir ve
namlunun ateş anındaki `global_position` ile `global_rotation` değerlerini alır.
Robot sonradan dönse bile havadaki mermi yön değiştirmez.

## Sonraki geliştirme aşaması

Mevcut `DatabaseWeapon` temel mermi/spread davranışını test etmek içindir.
`dot_puddle`, `chain_lightning`, `returning`, `tracking`, `aoe_pull`, `knockback`
ve gerçek `charge` davranışları ayrı Weapon alt sınıfları olarak uygulanmalıdır.
Bu sınıflar hazırlandığında `Player.gd` veya slot sistemi değişmeyecek; Manager
ilgili silah kimliği için doğru PackedScene'i oluşturacaktır.
