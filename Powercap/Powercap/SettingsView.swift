import SwiftUI

struct SettingsView: View {
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("textCaptureShortcut") private var textCaptureShortcut = "⌘⇧T"
    @AppStorage("imageCaptureShortcut") private var imageCaptureShortcut = "⌘⇧I"
    @AppStorage("translateCaptureShortcut") private var translateCaptureShortcut = "⌘⇧R"
    @AppStorage("translateLanguage") private var translateLanguage = "한국어"
    
    private let languages = ["한국어", "English", "日本語", "中文", "Español", "Français", "Deutsch"]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Powercap 설정")
                .font(.title2)
                .fontWeight(.bold)
            
            Divider()
            
            Toggle("메뉴바에 아이콘 표시", isOn: $showInMenuBar)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("단축키")
                    .font(.headline)
                
                HStack {
                    Text("텍스트 캡처 모드:")
                    Spacer()
                    TextField("", text: $textCaptureShortcut)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("이미지 캡처 모드:")
                    Spacer()
                    TextField("", text: $imageCaptureShortcut)
                        .frame(width: 100)
                }
                
                HStack {
                    Text("번역 캡처 모드:")
                    Spacer()
                    TextField("", text: $translateCaptureShortcut)
                        .frame(width: 100)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("번역 설정")
                    .font(.headline)
                
                HStack {
                    Text("번역 언어:")
                    Spacer()
                    Picker("", selection: $translateLanguage) {
                        ForEach(languages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .frame(width: 100)
                }
                
                Text("선택된 언어로 텍스트가 자동 번역됩니다.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("적용") {
                    NSApp.terminate(nil)
                }
            }
        }
        .padding()
        .frame(minWidth: 300, minHeight: 400)
    }
} 