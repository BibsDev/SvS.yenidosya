import SwiftUI
import FinderSync
import Combine

/// Ana uygulama: yalnızca Finder uzantısını taşır ve etkinleştirmeyi kolaylaştırır.
@main
struct SvSYeniDosyaApp: App {
    var body: some Scene {
        WindowGroup("SvS.yenidosya") {
            ContentView()
        }
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @State private var enabled = FIFinderSyncController.isExtensionEnabled
    private let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable().frame(width: 96, height: 96)
            Text("SvS.yenidosya").font(.title2.bold())
            Text("Finder'da sağ tıklayın → **Yeni Dosya** → türü seçin.\n\"Yeni Belge\" adıyla oluşturulur; aynı isim varsa sonuna 1, 2, 3… eklenir.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Image(systemName: enabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(enabled ? .green : .orange)
                Text(enabled ? "Finder uzantısı etkin" : "Finder uzantısı kapalı")
                    .bold()
            }
            .padding(.vertical, 8).padding(.horizontal, 14)
            .background(Capsule().fill(Color.secondary.opacity(0.12)))

            if !enabled {
                Button("Finder Uzantısını Etkinleştir…") {
                    FIFinderSyncController.showExtensionManagementInterface()
                }
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                Text("Açılan ayarlarda \"SvS.yenidosya\" seçeneğini işaretleyin.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(28)
        .frame(width: 380)
        .onReceive(timer) { _ in enabled = FIFinderSyncController.isExtensionEnabled }
    }
}
