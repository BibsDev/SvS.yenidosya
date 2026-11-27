#!/bin/bash
# SvS.yenidosya.app (+ Finder uzantısı) derler -> build/
set -euo pipefail
cd "$(dirname "$0")/.."
for f in txt doc docx xlsx xls; do
  [ -f "Resources/Templates/blank.$f" ] || { echo "Eksik şablon: Resources/Templates/blank.$f"; exit 1; }
done

APP=build/SvS.yenidosya.app
EXT="$APP/Contents/PlugIns/FinderExtension.appex"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$EXT/Contents/MacOS" "$EXT/Contents/Resources"

# Uzantı
cp Resources/Extension-Info.plist "$EXT/Contents/Info.plist"
cp Resources/Templates/blank.* "$EXT/Contents/Resources/"
swiftc -O -swift-version 5 -module-name FinderExtension -parse-as-library -application-extension \
  Extension/FinderSync.swift -framework FinderSync \
  -Xlinker -e -Xlinker _NSExtensionMain -o "$EXT/Contents/MacOS/FinderExtension"

# Ana uygulama
cp Resources/App-Info.plist "$APP/Contents/Info.plist"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
swiftc -O -swift-version 5 -parse-as-library App/App.swift -framework FinderSync -o "$APP/Contents/MacOS/SvS.yenidosya"

# Gizli dosyalar yardımcısı (sandbox dışı; Finder ayarını değiştirip Finder'ı yeniden başlatır)
HLP="$APP/Contents/Helpers/GizliDosyalar.app"
mkdir -p "$HLP/Contents/MacOS"
cp Resources/Helper-Info.plist "$HLP/Contents/Info.plist"
swiftc -O -swift-version 5 Helper/HiddenToggle.swift -o "$HLP/Contents/MacOS/GizliDosyalar"

# "Adrese Git…" yardımcısı (uzantı penceresi klavye alamadığı için yol sorma işini bu yapar)
GTO="$APP/Contents/Helpers/AdreseGit.app"
mkdir -p "$GTO/Contents/MacOS"
cp Resources/AdreseGit-Info.plist "$GTO/Contents/Info.plist"
swiftc -O -swift-version 5 Helper/AdreseGit.swift -o "$GTO/Contents/MacOS/AdreseGit"

# İmza (ad-hoc): önce yardımcılar ve uzantı, sonra uygulama
codesign --force -s - "$HLP"
codesign --force -s - "$GTO"
codesign --force -s - --entitlements Resources/Extension.entitlements "$EXT"
codesign --force -s - "$APP"
echo "Derleme tamam: $APP"
