import SwiftUI

struct PromptDetailView: View {
    let prompt: PromptItem
    @State private var promptDetail: [String: Any]? = nil
    @State private var variableText: String = ""
    @State private var selectedDropdown: [String:String] = [:]
    @State private var isChecked1: Bool = false
    @State private var checkboxSelected: [String: Set<String>] = [:]
    @State private var textInputs: [String: String] = [:]
    @State private var resultText: String = ""
    @State private var showDialog: Bool = false
    @State private var showTabs: Bool = true
    @State private var selectedTab: Int = 0
    @State private var output : Int = 1
    @State private var outputs: [String] = ["回答1の内容", "回答2の内容", "回答3の内容", "回答4の内容", "回答5の内容"]
    @Environment(\.dismiss) var dismiss
    
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
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 16) {
                        // ① Prompt Name
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading){
                                VStack(alignment: .leading){
                                    
                                    if let title = promptDetail?["title"] as? String {
                                        Text(title)
                                            .font(.title).bold()
                                    }
                                    // ② Description
                                    ScrollView(.vertical) {
                                        VStack(alignment: .leading, spacing: 0) {
                                            if let explanation = promptDetail?["explanation"] as? String {
                                                Text(explanation)
                                                    .font(.system(size:16))
                                                    .padding(4)
                                            }
                                            Spacer(minLength: 0)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .foregroundColor(.gray)
                                        .font(.body)
                                        .cornerRadius(8)
                                        .background(Color(.windowBackgroundColor))
                                    }
                                    .frame(height: 60)
                                    .border(Color.gray.opacity(0.3))
                                }
                                .padding(16)
                            }
                            .border(Color.gray.opacity(0.3))
                            Text("プロンプト名")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .background(Color(.windowBackgroundColor))
                                .padding(.horizontal, 8)
                                .offset(x: 10, y: -8)
                                .zIndex(1)
                        }

                            
                        HStack(spacing: 16) {
                            ZStack(alignment: .topLeading) {
                                VStack {
                                    VStack(alignment: .leading, spacing: 16) {
                                        if let variables = promptDetail?["variables"] as? [[String: Any]] {
                                           ForEach(0..<variables.count, id: \.self) { index in
                                                let variable = variables[index]
                                                let name = variable["name"] as? String ?? "No Name"
                                                let type = variable["type"] as? String ?? ""
                                                let fieldNo = String(variable["fieldNo"] as? Int ?? 0)
                                                VStack(alignment: .leading) {
                                                    Text("【\(name)】")
                                                        .bold()

                                                    switch type {
                                                    case "free":
                                                        TextEditor(text: Binding(
                                                            get: { textInputs[fieldNo, default: ""] },
                                                            set: { textInputs[fieldNo] = $0 }
                                                        ))
                                                        .frame(height: 60)
                                                        .border(Color.gray)

                                                    case "pulldown":
                                                        if let selections = variable["selections"] as? [[String: Any]] {
                                                            Picker("", selection: $selectedDropdown[fieldNo]) {
                                                                ForEach(0..<selections.count, id: \.self) { index in
                                                                    let name = selections[index]["name"] as? String ?? ""
                                                                    Text(name).tag(name)
                                                                }
                                                            }
                                                            .pickerStyle(MenuPickerStyle())
                                                        }

                                                    case "checkbox":
                                                        if let selections = variable["selections"] as? [[String: Any]] {
                                                            ForEach(0..<selections.count, id: \.self) { index in
                                                                let name = selections[index]["name"] as? String ?? ""
                                                                Toggle(name, isOn: Binding(
                                                                    get: {
                                                                        checkboxSelected[fieldNo]?.contains(name) ?? false
                                                                    },
                                                                    set: { newValue in
                                                                        if checkboxSelected[fieldNo] == nil {
                                                                            checkboxSelected[fieldNo] = []
                                                                        }
                                                                        if newValue {
                                                                            checkboxSelected[fieldNo]?.insert(name)
                                                                        } else {
                                                                            checkboxSelected[fieldNo]?.remove(name)
                                                                        }
                                                                    }
                                                                ))
                                                            }
                                                        }

                                                    default:
                                                        Text("未対応の変数タイプ: \(type)")
                                                    }
                                                }
                                            }
                                        }

                                    }
                                    
                                    Spacer()
                                    HStack(spacing: 16) {
                                        Spacer()
                                        Picker("同時出力回数", selection: $output) {
                                            Text("1").tag(1)
                                            Text("2").tag(2)
                                            Text("3").tag(3)
                                            Text("4").tag(4)
                                            Text("5").tag(5)
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(width: 200)
                                        Button("プロンプト実行") {
                                            showDialog = true
                                            print(selectedDropdown)
                                            print(checkboxSelected)
                                            print(textInputs)
                                        }
                                        .buttonStyle(BlueButtonStyle())
                                    }
                                    // ④ プロンプト実行
                                    
                                }
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .border(Color.gray.opacity(0.3))
                                Text("変数一覧")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                                    .background(Color(.windowBackgroundColor))
                                    .padding(.horizontal, 8)
                                    .offset(x: 10, y: -8)
                                    .zIndex(1)
                            }
                            
                            // ⑤ 実行結果
                              ZStack(alignment: .topLeading) {
                            VStack {
                                    VStack(alignment: .leading, spacing: 8) {
                                        if showTabs {
                                            // ⑨ 回答タブ
                                            HStack {
                                                Button("◀") {
                                                    if selectedTab > 0 {
                                                        selectedTab -= 1
                                                    }
                                                }
                                                .disabled(selectedTab == 0)
                                                .buttonStyle(.bordered)

                                                ForEach(0..<output, id: \.self) { idx in
                                                    if selectedTab == idx {
                                                        Button("回答\(idx + 1)") {
                                                            selectedTab = idx
                                                        }
                                                        .buttonStyle(BlueButtonStyle())
                                                    } else {
                                                        Button("回答\(idx + 1)") {
                                                            selectedTab = idx
                                                        }
                                                        .buttonStyle(GrayButtonStyle())
                                                    }
                                                }

                                                Button("▶") {
                                                    if selectedTab < output - 1 {
                                                        selectedTab += 1
                                                    }
                                                }
                                                .disabled(selectedTab == output - 1)
                                                .buttonStyle(.bordered)
                                            }
                                        }
                                        ScrollView(.vertical) {
                                            VStack(alignment: .leading, spacing: 0) {
                                                Text(outputs[selectedTab])
                                                    .padding(4)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundColor(.gray)
                                            .font(.body)
                                            .cornerRadius(8)
                                            .background(Color(.windowBackgroundColor))
                                        }
                                        .border(Color.gray.opacity(0.3))
                                        .frame(maxHeight: .infinity)

                                        Spacer()

                                        HStack {
                                            Spacer()
                                            // ⑥ 全コピー
                                            Button("全コピー") {
                                                let pasteboard = NSPasteboard.general
                                                pasteboard.clearContents()
                                                pasteboard.setString(outputs.joined(separator: "\n"), forType: .string)
                                            }
                                            .buttonStyle(BlueButtonStyle())
                                            // ⑦ コピー
                                            Button("コピー") {
                                                let pasteboard = NSPasteboard.general
                                                pasteboard.clearContents()
                                                pasteboard.setString(outputs[selectedTab], forType: .string)
                                            }
                                            .buttonStyle(BlueButtonStyle())
                                        }
                                    }
                                }
                                    .frame(maxWidth: .infinity)
                                    .padding(10)
                                    .border(Color.gray.opacity(0.3))
                                    Text("実行結果")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                        .background(Color(.windowBackgroundColor))
                                        .padding(.horizontal, 8)
                                        .offset(x: 10, y: -8)
                                        .zIndex(1)
                              }
                        }
                        .frame(maxHeight: .infinity)
                        .navigationTitle("プロンプト実行")
                    
                    }
                    .padding()
                Divider()
                HStack {
                    Spacer()
                    // ⑧ 閉じる
                    Button("閉じる") {
                        dismiss()
                    }
                    .buttonStyle(MainGrayButtonStyle())
                }
            }
            .padding(8)
            // ⑩ プロンプト実行ダイアログ
            .sheet(isPresented: $showDialog) {
                VStack(spacing: 24) {
                    Text("プロンプト実行中...")
                        .font(.headline)
                    ProgressView()
                        .progressViewStyle(LinearProgressViewStyle())
                        .frame(width: 200)
                    Button("キャンセル") {
                        showDialog = false
                    }
                    .buttonStyle(GrayButtonStyle())
                }
                .padding()
                .frame(width: 300, height: 180)
            }
            .onAppear {
                APIClient.request(path: "prompt-detail/\(prompt.id)") { result in
                    switch result {
                    case .success(let data):
                        do {
                            if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                DispatchQueue.main.async {
                                    self.promptDetail = jsonArray
                                }
                            } else {
                                print("Unexpected JSON structure")
                            }
                        } catch {
                           print(error.localizedDescription)
                        }

                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
        .frame(width: 1080, height: 800)
    }
}



#Preview {
    PromptDetailView(prompt: PromptItem(
        id: 143625,
        title: "小説複数カテゴリ_コピー",
        folder: "小説作成", type: "prompt",
        date: "2025-03-13 07:48:40"
    ))
}
