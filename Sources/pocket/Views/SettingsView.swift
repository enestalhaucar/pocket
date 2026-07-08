import SwiftUI
import Carbon.HIToolbox

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
                ShortcutRecorder()
            }
        }
        .formStyle(.grouped)
        .fontDesign(.rounded)
        .frame(width: 400, height: 440)
    }
}

/// Records a new global hotkey by capturing the next key combo.
struct ShortcutRecorder: View {
    @State private var shortcut = Shortcut.load()
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        HStack {
            Text("Global kısayol")
            Spacer()
            Button {
                recording ? stop() : start()
            } label: {
                Text(recording ? "Tuşlara bas…  (⎋ iptal)" : shortcut.display)
                    .monospaced()
                    .frame(minWidth: 90)
            }
            .buttonStyle(.bordered)
            .tint(recording ? .red : .accentColor)
        }
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == UInt16(kVK_Escape) {
                stop()
                return nil
            }
            if let s = Shortcut.from(event: event) {
                shortcut = s
                s.save()
                stop()
            }
            return nil // consume the event while recording
        }
    }

    private func stop() {
        recording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }
}
