import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var integrationCode: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                    Image("ダウンロード")
                        .resizable()
                        .frame(width: 200, height: 48)
                    
                    Spacer()
            }
            .padding()
            .background(Color.blue.opacity(0.6))
            .foregroundColor(.white)
            
            Spacer()
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 6, height: 6)
                    Text("下記の項目設定後、登録ボタンを押してください。")
                        .font(.system(size: 20))
                }
                .padding(.top)
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("チャプロ連携コード")
                        .font(.system(size: 20))
                    
                    TextField("", text: $integrationCode)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(8)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                }
                .frame(width: 500)
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("登録") {
                        saveSettings()
                    }
                    .buttonStyle(MainBlueButtonStyle())
                    .padding(.trailing, 10)
                    
                    Button("閉じる") {
                        dismiss()
                    }
                    .buttonStyle(MainGrayButtonStyle())
                }
            }
            .padding()
        }
        .font(.system(size: 18))
        .onAppear {
            loadSettings()
        }
        .navigationTitle("設定")
    }
    
    private func loadSettings() {
        if let code = DatabaseManager.shared.getSetting(key: "chapro") {
            integrationCode = code
        }
    }
    
    private func saveSettings() {
        DatabaseManager.shared.addSetting(key: "chapro", value: integrationCode)
        dismiss()
    }
}


#Preview {
    SettingsView()
}
