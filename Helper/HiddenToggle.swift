import Foundation

/// Finder'da gizli dosyaları (. ile başlayanlar) göster/gizle ayarını tersine çevirir ve Finder'ı
/// yeniden başlatır. Sandbox'taki Finder uzantısı bunu kendisi yapamadığı için bu küçük yardımcıyı açar.
let domain = "com.apple.finder" as CFString
let key = "AppleShowAllFiles" as CFString

func isOn(_ v: CFPropertyList?) -> Bool {
    if let b = v as? Bool { return b }
    if let s = v as? String { return ["1", "yes", "true"].contains(s.lowercased()) }
    return false
}

let show = !isOn(CFPreferencesCopyAppValue(key, domain))
CFPreferencesSetAppValue(key, show as CFBoolean, domain)
CFPreferencesAppSynchronize(domain)

// Finder ayarı ancak yeniden başlayınca okur; açık pencereler geri açılır.
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
p.arguments = ["Finder"]
try? p.run()
p.waitUntilExit()
