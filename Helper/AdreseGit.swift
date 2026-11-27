import AppKit

/// "Adrese Git…": bir yol sorar; dosyaysa varsayılan uygulamasıyla, klasörse Finder'da açar.
/// Kutu boş açılır; göreli yollar ana klasöre göre çözülür.
///
/// macOS 14+ uygulamaların kendini zorla öne almasına izin vermiyor; bu yüzden Spotlight gibi
/// "etkinleştirmeyen" bir panel kullanılır: Finder önde kalır ama klavye bu panele gelir.
final class KeyPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override func cancelOperation(_ sender: Any?) { NSApp.terminate(nil) }   // Esc
}

final class Delegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    var base: URL?
    var panel: KeyPanel?
    let field = NSTextField()
    let errorLabel = NSTextField(labelWithString: "")

    func application(_ sender: NSApplication, open urls: [URL]) {
        base = urls.first
        show()
    }

    func applicationDidFinishLaunching(_ n: Notification) {
        if let arg = CommandLine.arguments.dropFirst().first(where: { $0.hasPrefix("/") }) {
            base = URL(fileURLWithPath: arg)
        }
        // Belge gelmediyse (doğrudan açıldıysa) kısa bir beklemeden sonra göster.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.show() }
    }

    func show() {
        if let panel {                       // zaten açık: yalnızca öne getir
            panel.makeKeyAndOrderFront(nil)
            return
        }
        let p = KeyPanel(contentRect: NSRect(x: 0, y: 0, width: 460, height: 150),
                         styleMask: [.titled, .closable, .nonactivatingPanel],
                         backing: .buffered, defer: false)
        p.title = "Adrese Git"
        p.level = .floating
        p.isFloatingPanel = true
        p.hidesOnDeactivate = false
        p.becomesKeyOnlyIfNeeded = false
        p.delegate = self

        let info = NSTextField(wrappingLabelWithString:
            "Dosya veya klasör yolu girin (ör. ~/Desktop, /etc/hosts). Terminal biçimindeki (\\ kaçışlı) ya da tırnaklı yollar da olur.")
        info.font = .systemFont(ofSize: 12)
        info.textColor = .secondaryLabelColor

        field.stringValue = ""
        field.placeholderString = "/Users/…"
        field.lineBreakMode = .byTruncatingHead
        field.target = self
        field.action = #selector(go)          // Enter

        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 12)
        errorLabel.lineBreakMode = .byTruncatingMiddle
        errorLabel.isHidden = true

        let cancel = NSButton(title: "Vazgeç", target: NSApp, action: #selector(NSApplication.terminate(_:)))
        cancel.keyEquivalent = "\u{1b}"
        let ok = NSButton(title: "Git", target: self, action: #selector(go))
        ok.keyEquivalent = "\r"
        let buttons = NSStackView(views: [NSView(), cancel, ok])
        buttons.orientation = .horizontal

        let stack = NSStackView(views: [info, field, errorLabel, buttons])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8
        stack.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        stack.translatesAutoresizingMaskIntoConstraints = false
        p.contentView = stack
        for v in [info, field, buttons] {
            v.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -32).isActive = true
        }
        errorLabel.widthAnchor.constraint(lessThanOrEqualTo: stack.widthAnchor, constant: -32).isActive = true

        p.center()
        panel = p
        NSApp.activate(ignoringOtherApps: true)
        p.makeKeyAndOrderFront(nil)
        p.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
        if CommandLine.arguments.contains("--debug") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                FileHandle.standardError.write("panel key=\(p.isKeyWindow) visible=\(p.isVisible) appActive=\(NSApp.isActive) firstResponder=\(String(describing: p.firstResponder))\n".data(using: .utf8)!)
            }
        }
    }

    @objc func go() {
        let home = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
        guard let url = Self.resolvePath(field.stringValue, relativeTo: base ?? home) else { return }
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.open(url)       // klasör → Finder penceresi, dosya → varsayılan uygulama
            NSApp.terminate(nil)
        } else {
            errorLabel.stringValue = "Bulunamadı: \(url.path)"
            errorLabel.isHidden = false
        }
    }

    func windowWillClose(_ notification: Notification) { NSApp.terminate(nil) }

    /// Girilen metni yola çevirir: tırnak/ters eğik çizgi kaçışı, ~, file:// ve göreli yollar.
    static func resolvePath(_ raw: String, relativeTo base: URL?) -> URL? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }
        if s.hasPrefix("file://"), let u = URL(string: s), u.isFileURL { return u.standardizedFileURL }
        if s.count >= 2, let f = s.first, f == s.last, f == "'" || f == "\"" {
            s = String(s.dropFirst().dropLast())
        } else if s.contains("\\") {
            var out = "", esc = false
            for ch in s {
                if esc { out.append(ch); esc = false }
                else if ch == "\\" { esc = true }
                else { out.append(ch) }
            }
            s = out
        }
        if s == "~" || s.hasPrefix("~/") {
            // Kullanıcının gerçek ana klasörü:
            let home = getpwuid(getuid()).flatMap { String(validatingCString: $0.pointee.pw_dir) } ?? "/Users/\(NSUserName())"
            s = home + s.dropFirst()
        }
        if s.hasPrefix("/") { return URL(fileURLWithPath: s).standardizedFileURL }
        guard let base else { return nil }
        return base.appendingPathComponent(s).standardizedFileURL
    }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let delegate = Delegate()
app.delegate = delegate
app.run()
