import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: Store
    @State private var launchAtLogin = LoginItem.isEnabled

    var body: some View {
        Form {
            Section("Kasa") {
                Picker("Otomatik kilit", selection: $store.autoLockMinutes) {
                    Text("Kapalı").tag(0)
                    Text("1 dakika").tag(1)
                    Text("5 dakika").tag(5)
                    Text("15 dakika").tag(15)
                    Text("30 dakika").tag(30)
                }
                Text("Bu süre boyunca kullanılmazsa ya da Mac uyursa kasa tekrar kilitlenir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Pano") {
                Toggle("Kopyaladıklarımı geçmişte tut", isOn: $store.captureClipboard)
                Text("Şifre yöneticilerinden gelen gizli kopyalar yakalanmaz.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Menü çubuğu") {
                Toggle("Öğe sayısı rozetini göster", isOn: $store.showBadge)
            }

            Section("Genel") {
                Toggle("Girişte otomatik başlat", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        LoginItem.setEnabled(newValue)
                        launchAtLogin = LoginItem.isEnabled
                    }
                Text("Global kısayol: ⌘⇧Space")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 420)
    }
}
