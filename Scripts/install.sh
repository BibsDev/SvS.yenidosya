#!/bin/bash
# SvS.yenidosya kurulumu (sudo gerekmez): Scripts/install.sh
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d build/SvS.yenidosya.app ] || Scripts/build.sh
DEST=/Applications/SvS.yenidosya.app
pkill -x SvS.yenidosya 2>/dev/null || true
rm -rf "$DEST"
cp -R build/SvS.yenidosya.app /Applications/
open "$DEST"                       # uygulama açılınca uzantı sisteme kaydolur
pluginkit -a "$DEST/Contents/PlugIns/FinderExtension.appex"
for i in 1 2 3 4 5 6 7 8 9 10; do    # kayıt tamamlanınca etkinleştir
  pluginkit -m -i com.svs.yenidosya.FinderExtension | grep -q com.svs && break
  sleep 1
done
pluginkit -e use -i com.svs.yenidosya.FinderExtension
killall Finder 2>/dev/null || true
sleep 2
pluginkit -m -i com.svs.yenidosya.FinderExtension
echo "Kurulum tamam. Finder'da sağ tıklayın → Yeni Dosya."
