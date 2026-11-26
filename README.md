# SvS.yenidosya

Finder'ın sağ tık menüsüne, Windows'taki gibi **Yeni Dosya** ve **Terminal** kısayolları ekleyen küçük bir macOS uygulaması (Finder Sync uzantısı).

```
Yeni Dosya ▸   Metin Belgesi (.txt)
               Word 97-2004 Belgesi (.doc)
               Word Belgesi (.docx)
               Excel Çalışma Kitabı (.xlsx)
               Excel 97-2004 Kitabı (.xls)
─────────────
Terminal ▸     Terminalde Aç
               Yolu Kopyala
               ─────────────
               Yeni Terminal
```

## Özellikler

- **Yeni Dosya** — Bulunulan klasörde boş bir `Yeni Belge.<uzantı>` oluşturur. Aynı adda dosya varsa `Yeni Belge 1`, `Yeni Belge 2` … diye numaralandırır ve yeni dosyayı Finder'da seçer.
- **Terminalde Aç** — Sağ tıklanan klasörde (ya da bulunulan klasörde) Terminal penceresi açar.
- **Yolu Kopyala** — Seçili dosya/klasörlerin yolunu, Terminal'e yapıştırılabilecek biçimde kopyalar (boşluk ve özel karakterler `\` ile kaçışlı, birden çok öğe boşlukla ayrılmış):
  `/Users/ben/Desktop/Yeni\ Belge\ \(1\).txt`
- **Yeni Terminal** — Klasörden bağımsız, ana klasörde boş bir Terminal penceresi açar.
- Menü simgeleri temaya uyar (koyu temada beyaz).

## Gereksinimler

- macOS 13 veya üstü
- Xcode Komut Satırı Araçları (`xcode-select --install`) — Xcode projesi gerekmez, `swiftc` ile derlenir.

## Kurulum

```bash
git clone https://github.com/BibsDev/SvS.yenidosya.git
cd SvS.yenidosya
Scripts/build.sh      # build/SvS.yenidosya.app
Scripts/install.sh    # /Applications'a kopyalar, uzantıyı kaydeder ve etkinleştirir, Finder'ı yeniden başlatır
```

`sudo` gerekmez. Menü görünmezse: SvS.yenidosya uygulamasını açıp penceredeki düğmeyle uzantı ayarlarına gidin ve *SvS.yenidosya* Finder uzantısını etkinleştirin.

## Kaldırma

```bash
Scripts/uninstall.sh
```

## Yapı

| Yol | İçerik |
|---|---|
| `Extension/FinderSync.swift` | Finder Sync uzantısı: menü, dosya oluşturma, Terminal, yol kopyalama |
| `App/App.swift` | Uzantının durumunu gösteren küçük ana uygulama |
| `Resources/Templates/` | Boş belge şablonları |
| `Scripts/make_xls.py` | Boş `.xls` (BIFF8 + OLE2) şablonunu üretir |
| `Scripts/make_icon.swift` | Uygulama simgesini çizer |

Uygulama ad-hoc imzalıdır (Apple geliştirici sertifikası yok); bu yüzden kendi Mac'inizde kaynaktan derleyerek kurmanız önerilir.
