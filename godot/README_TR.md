# NEONFALL: XENO HUNT — Godot 4.7

Bu sürüm Godot 4.7 için hazırlanmış, dış görsel veya ses dosyasına ihtiyaç duymayan oynanabilir prototiptir.

## Çalıştırma

1. Godot Project Manager içinde `project.godot` dosyasını içe aktarın.
2. Projeyi açın ve `F6` veya sağ üstteki çalıştır düğmesine basın.

## Kontroller

- `WASD` / ok tuşları: hareket
- Fare: nişan
- Sol tık: ateş
- `Space`: faz jetpack atılması
- `M`: prosedürel müziği aç/kapat

## Bu sürümde

- Dört uzaylı sınıfı ve elit varyantlar
- Her beşinci dalgada üç farklı boss savaş gemisi
- Boss başına farklı radial, spiral ve nişanlı salvo paternleri
- Dalga sonu üç karttan geliştirme seçimi
- Sert saniyelik sınırı bulunan dengeli lifesteal
- Artan düşman canı, hızı, hasarı ve doğma temposu
- Skor, yerel en iyi skor, boss can göstergesi ve ekran sarsıntısı
- Kodla üretilen telifsiz synth müzik ve ses efektleri
- Standart, nadir ve efsanevi geliştirme kartları
- Arşiv rütbesine bağlı yeniden çevirme hakları
- Void Railgun, Nova Protokolü ve Faz İzi silah evrimleri
- Günlük protokoller ve her gün değişen görevler
- Elit ve boss avlarından kalıcı Void parçası kazanımı
- Sürü ve zırhlı sürü dalga mutasyonları
- Refleks, aşırı yük ve kriyo güçlendirme düşürmeleri
- Kombo tabanlı skor çarpanı ve duraklatma ekranı
- 8 seviyeli Akıllı Füze Bataryası
- 8 seviyeli Prizma Işın Dizisi
- 8 seviyeli Aegis Kalkan Uyduları
- 20 seviyeli Sistem Gücü ve 15 seviyeli Sistem Hızı
- 12 seviyeli Çekim Alanı
- Toplam geliştirme havuzu 30 seçim sınırının çok üzerine çıkarıldı
- Tek iş parçacıklı Godot Web export ayarı

## Evrimler

- `Plazma Çekirdeği 3 + Zayıf Nokta 2` → kritik mermiler delen Void Railgun'a dönüşür.
- `Hızlı Tetik 3 + Çatallı Atış 2` → her dokuzuncu atışta Nova dalgası çıkar.
- `Jetpack Takviyesi 2 + Faz Jetpack 2` → atılma çevredeki uzaylılara hasar verir.

Ana oyun dengesi `scripts/main.gd`, görsel modeller `scripts/visual_factory.gd`, müzik ve efektler `scripts/neon_audio.gd` içindedir.

## Tarayıcı güncelleme düzeni

`export_presets.cfg` içinde Web profili hazırdır. Godot export templates kurulduktan sonra `web/index.html` hedefiyle export alınabilir. Web sürümü tek iş parçacıklı çalışır; prosedürel ses için oynatım tipi Stream olarak zorlanmıştır.
