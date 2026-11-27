import Cocoa
import FinderSync
import UniformTypeIdentifiers

/// Finder sağ tık menüsüne "Yeni Dosya ▸ …", "Terminal ▸ Terminalde Aç / Yolu Kopyala / Yeni Terminal"
/// alt menülerini, "Adrese Git…" ve "Gizli Dosyaları Göster/Gizle" öğelerini ekler.
final class FinderSync: FIFinderSync {

    struct DocType {
        let title: String
        let ext: String
        let template: String   // uzantı paketindeki şablon dosyası
        let symbol: String     // menüdeki tek renk simge (SF Symbol)
    }

    static let baseName = "Yeni Belge"
    static let types: [DocType] = [
        DocType(title: "Metin Belgesi (.txt)",        ext: "txt",  template: "blank.txt",  symbol: "doc.plaintext"),
        DocType(title: "Word 97-2004 Belgesi (.doc)",  ext: "doc",  template: "blank.doc",  symbol: "doc.richtext"),
        DocType(title: "Word Belgesi (.docx)",         ext: "docx", template: "blank.docx", symbol: "doc.richtext"),
        DocType(title: "Excel Çalışma Kitabı (.xlsx)", ext: "xlsx", template: "blank.xlsx", symbol: "tablecells"),
        DocType(title: "Excel 97-2004 Kitabı (.xls)",  ext: "xls",  template: "blank.xls",  symbol: "tablecells"),
    ]

    override init() {
        super.init()
        // Tüm diskler: menü her klasörde görünsün.
        var dirs: Set<URL> = [URL(fileURLWithPath: "/")]
        if let vols = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [.skipHiddenVolumes]) {
            dirs.formUnion(vols)
        }
        FIFinderSyncController.default().directoryURLs = dirs
    }

    // MARK: Menü

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        guard menuKind == .contextualMenuForContainer || menuKind == .contextualMenuForItems else { return nil }

        let sub = NSMenu(title: "Yeni Dosya")
        for (i, t) in Self.types.enumerated() {
            let item = NSMenuItem(title: t.title, action: #selector(createDocument(_:)), keyEquivalent: "")
            item.tag = i
            item.target = self
            item.image = Self.symbol(t.symbol)
            sub.addItem(item)
        }

        let root = NSMenuItem(title: "Yeni Dosya", action: nil, keyEquivalent: "")
        root.image = Self.symbol("doc.badge.plus")
        root.submenu = sub

        let terminal = NSMenuItem(title: "Terminalde Aç", action: #selector(openInTerminal(_:)), keyEquivalent: "")
        terminal.target = self
        terminal.image = Self.symbol("terminal")

        let copyPath = NSMenuItem(title: "Yolu Kopyala", action: #selector(copyPath(_:)), keyEquivalent: "")
        copyPath.target = self
        copyPath.image = Self.symbol("doc.on.clipboard")

        let newTerminal = NSMenuItem(title: "Yeni Terminal", action: #selector(openNewTerminal(_:)), keyEquivalent: "")
        newTerminal.target = self
        newTerminal.image = Self.symbol("plus.rectangle")

        let termSub = NSMenu(title: "Terminal")
        termSub.addItem(terminal)
        termSub.addItem(copyPath)
        termSub.addItem(.separator())
        termSub.addItem(newTerminal)
        let termRoot = NSMenuItem(title: "Terminal", action: nil, keyEquivalent: "")
        termRoot.image = Self.symbol("apple.terminal")
        termRoot.submenu = termSub

        let shown = Self.hiddenFilesShown()
        let hidden = NSMenuItem(title: shown ? "Gizli Dosyaları Gizle" : "Gizli Dosyaları Göster",
                                action: #selector(toggleHiddenFiles(_:)), keyEquivalent: "")
        hidden.target = self
        hidden.image = Self.symbol(shown ? "eye.slash" : "eye")

        let menu = NSMenu(title: "")
        menu.addItem(root)
        menu.addItem(.separator())
        let goTo = NSMenuItem(title: "Adrese Git…", action: #selector(goToAddress(_:)), keyEquivalent: "")
        goTo.target = self
        goTo.image = Self.symbol("arrow.right.circle")

        menu.addItem(termRoot)
        menu.addItem(goTo)
        menu.addItem(hidden)
        return menu
    }

    /// Menü simgesi: Finder uzantı menüsündeki şablon simgeleri renklendirmediği için (koyu gri kalıyor)
    /// sistem simgesini temaya göre boyayıp hazır resim veririz — koyu temada beyaz, açık temada siyah.
    static func symbol(_ name: String) -> NSImage? {
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
        guard let base = (NSImage(systemSymbolName: name, accessibilityDescription: nil)
                          ?? NSImage(systemSymbolName: "doc", accessibilityDescription: nil))?
                .withSymbolConfiguration(cfg) else { return nil }
        let appearance = NSApp?.effectiveAppearance ?? NSAppearance.currentDrawing()
        let dark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let color: NSColor = dark ? .white : .black

        let box = NSSize(width: 16, height: 16), scale: CGFloat = 2
        guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil,
                                         pixelsWide: Int(box.width * scale), pixelsHigh: Int(box.height * scale),
                                         bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                         colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        rep.size = box
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let s = base.size, k = min(box.width / s.width, box.height / s.height, 1)
        let r = NSRect(x: (box.width - s.width * k) / 2, y: (box.height - s.height * k) / 2,
                       width: s.width * k, height: s.height * k)
        base.draw(in: r)
        color.set()
        r.fill(using: .sourceAtop)          // simgenin şekli korunur, rengi boyanır
        NSGraphicsContext.restoreGraphicsState()

        let img = NSImage(size: box)
        img.addRepresentation(rep)
        img.isTemplate = false
        return img
    }

    // MARK: Terminal

    /// Bir klasörün üstüne sağ tıklandıysa o klasörde, aksi halde bulunulan klasörde Terminal açar.
    @objc func openInTerminal(_ sender: NSMenuItem) {
        let c = FIFinderSyncController.default()
        var folder = c.targetedURL()
        if let items = c.selectedItemURLs(), items.count == 1,
           let v = try? items[0].resourceValues(forKeys: [.isDirectoryKey, .isPackageKey]),
           v.isDirectory == true, v.isPackage != true {
            folder = items[0]
        }
        guard let folder else { return }
        Self.openTerminal(at: folder)
    }

    /// Klasörden bağımsız, boş bir Terminal penceresi (kullanıcının ana klasöründe, Terminal'in varsayılanı).
    @objc func openNewTerminal(_ sender: NSMenuItem) {
        // Sandbox'ta homeDirectoryForCurrentUser kapsayıcıyı döndürür; gerçek ana klasör:
        let home = getpwuid(getuid()).flatMap { String(validatingCString: $0.pointee.pw_dir) } ?? "/Users/\(NSUserName())"
        Self.openTerminal(at: URL(fileURLWithPath: home, isDirectory: true))
    }

    static func openTerminal(at folder: URL) {
        guard let terminal = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Terminal") else { return }
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.open([folder], withApplicationAt: terminal, configuration: cfg) { _, error in
            if let error { NSLog("SvS.yenidosya: Terminal açılamadı: \(error)") }
        }
    }

    // MARK: Adrese git

    /// Uzantı penceresi klavyeyi alamadığı için yol sorma işini paketteki yardımcı uygulama
    /// (Contents/Helpers/AdreseGit.app) yapar; kutu boş açılır.
    @objc func goToAddress(_ sender: NSMenuItem) {
        let helper = Bundle.main.bundleURL
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Helpers/AdreseGit.app")
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = true
        NSWorkspace.shared.openApplication(at: helper, configuration: cfg) { _, error in
            if let error { NSLog("SvS.yenidosya: Adrese Git açılamadı: \(error)") }
        }
    }

    // MARK: Gizli dosyalar

    /// Finder'ın "AppleShowAllFiles" ayarı (uzantı bunu yalnızca okuyabilir).
    static func hiddenFilesShown() -> Bool {
        let v = CFPreferencesCopyAppValue("AppleShowAllFiles" as CFString, "com.apple.finder" as CFString)
        if let b = v as? Bool { return b }
        if let s = v as? String { return ["1", "yes", "true"].contains(s.lowercased()) }
        return false
    }

    /// Ayarı değiştirip Finder'ı yeniden başlatmak sandbox dışında olmalı: uygulama paketindeki
    /// küçük yardımcıyı (Contents/Helpers/GizliDosyalar.app) açarız.
    @objc func toggleHiddenFiles(_ sender: NSMenuItem) {
        let helper = Bundle.main.bundleURL            // …/SvS.yenidosya.app/Contents/PlugIns/FinderExtension.appex
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Helpers/GizliDosyalar.app")
        let cfg = NSWorkspace.OpenConfiguration()
        cfg.activates = false
        cfg.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: helper, configuration: cfg) { _, error in
            if let error { NSLog("SvS.yenidosya: gizli dosya yardımcısı açılamadı: \(error)") }
        }
    }

    // MARK: Yol kopyalama

    /// Seçili dosya/klasörlerin (seçim yoksa bulunulan klasörün) yolunu Terminal'e yapıştırılacak
    /// biçimde kopyalar: boşluk ve özel karakterler kaçışlı, birden çok öğe boşlukla ayrılmış.
    @objc func copyPath(_ sender: NSMenuItem) {
        let c = FIFinderSyncController.default()
        var urls = c.selectedItemURLs() ?? []
        if urls.isEmpty, let t = c.targetedURL() { urls = [t] }
        guard !urls.isEmpty else { return }
        let text = urls.map { Self.shellEscaped($0.path) }.joined(separator: " ")
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }

    /// Terminal'e sürükle-bırakta olduğu gibi: güvenli olmayan karakterlerin önüne ters eğik çizgi koyar.
    /// Satır sonu içeren (çok nadir) yollar tek tırnağa alınır.
    static func shellEscaped(_ path: String) -> String {
        if path.contains("\n") || path.contains("\r") {
            return "'" + path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        }
        let safe = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-./,:+@%=")
        var out = ""
        for ch in path {
            if safe.contains(ch) || !ch.isASCII { out.append(ch) }   // ş, ğ, ü… olduğu gibi kalır
            else { out.append("\\"); out.append(ch) }
        }
        return out
    }

    // MARK: Oluşturma

    @objc func createDocument(_ sender: NSMenuItem) {
        guard Self.types.indices.contains(sender.tag),
              let folder = targetFolder() else { return }
        let type = Self.types[sender.tag]

        guard let template = Bundle(for: Self.self).url(forResource: type.template, withExtension: nil) else {
            NSLog("SvS.yenidosya: şablon bulunamadı: \(type.template)")
            return
        }

        let dest = Self.uniqueURL(in: folder, base: Self.baseName, ext: type.ext)
        do {
            try FileManager.default.copyItem(at: template, to: dest)
            // Şablonun tarihi değil, şimdiki zaman görünsün.
            let now = Date()
            try? FileManager.default.setAttributes([.creationDate: now, .modificationDate: now], ofItemAtPath: dest.path)
            NSWorkspace.shared.activateFileViewerSelecting([dest])
        } catch {
            NSLog("SvS.yenidosya: oluşturulamadı \(dest.path): \(error)")
            let alert = NSAlert()
            alert.messageText = "Dosya oluşturulamadı"
            alert.informativeText = "\(folder.path)\n\n\(error.localizedDescription)"
            alert.runModal()
        }
    }

    /// Sağ tıklanan pencerenin/masaüstünün klasörü (bir öğeye tıklandıysa o öğenin bulunduğu klasör).
    private func targetFolder() -> URL? {
        FIFinderSyncController.default().targetedURL()
    }

    /// "Yeni Belge.txt" varsa "Yeni Belge 1.txt", "Yeni Belge 2.txt" … döndürür.
    static func uniqueURL(in folder: URL, base: String, ext: String) -> URL {
        let fm = FileManager.default
        var url = folder.appendingPathComponent("\(base).\(ext)")
        var n = 1
        while fm.fileExists(atPath: url.path) {
            url = folder.appendingPathComponent("\(base) \(n).\(ext)")
            n += 1
        }
        return url
    }
}
