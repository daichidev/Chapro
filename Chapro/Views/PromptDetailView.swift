import SwiftUI

struct PromptDetailView: View {
    let prompt: PromptItem
    @State private var promptDetail: [String: Any]? = nil
    @State private var textNum: [String: Int] = [:]
    @State private var selectNum: [String: Int] = [:]
    @State private var checkboxNum: [String: Int] = [:]
    @State private var selectedDropdown: [String:[String]] = [:]
    @State private var checkboxSelected: [String: [Set<String>]] = [:]
    @State private var textInputs: [String: [String]] = [:]
    @State private var showDialog: Bool = false
    @State private var showTabs: Bool = true
    @State private var selectedTab: Int = 0
    @State private var outputCount : Int = 0
    @State private var sendMessageCount : Int = 1
    @State private var outputs: [String] = []
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
                                    .background(Color(NSColor.windowBackgroundColor))
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
                            .background(Color(NSColor.windowBackgroundColor))
                            .padding(.horizontal, 8)
                            .offset(x: 10, y: -8)
                            .zIndex(1)
                    }
                    
                    HStack(spacing: 16) {
                        ZStack(alignment: .topLeading) {
                            VStack(alignment: .leading, spacing: 16) {
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 16) {
                                        if let variables = promptDetail?["variables"] as? [[String: Any]] {
                                            ForEach(0..<variables.count, id: \.self) { index in
                                                let variable = variables[index]
                                                let name = variable["name"] as? String ?? "No Name"
                                                let type = variable["type"] as? String ?? ""
                                                let chainType = String(variable["chainValueType"] as? Int ?? 0)
                                                let fieldNo = String(variable["fieldNo"] as? Int ?? 0)
                                                VStack(alignment: .leading) {
                                                    Text("【\(name)】")
                                                        .bold()
                                                    
                                                    switch type {
                                                    case "free":
                                                        let count = textNum[fieldNo] ?? 1
                                                        ForEach(0..<count, id: \.self) { idx in
                                                            TextEditor(text: Binding(
                                                                get: {
                                                                    if let list = textInputs[fieldNo], list.indices.contains(idx) {
                                                                        return list[idx]
                                                                    } else {
                                                                        return ""
                                                                    }
                                                                },
                                                                set: { newValue in
                                                                    if textInputs[fieldNo] == nil {
                                                                        textInputs[fieldNo] = Array(repeating: "", count: count)
                                                                    }
                                                                    if var list = textInputs[fieldNo] {
                                                                        if idx < list.count {
                                                                            list[idx] = newValue
                                                                        } else {
                                                                            list.append(contentsOf: Array(repeating: "", count: idx - list.count + 1))
                                                                            list[idx] = newValue
                                                                        }
                                                                        textInputs[fieldNo] = list
                                                                    }
                                                                }
                                                            ))
                                                            .frame(height: 60)
                                                            .border(Color.gray)
                                                        }
                                                        
                                                        if chainType == "2" {
                                                            HStack {
                                                                Button("項目追加") {
                                                                    textNum[fieldNo] = (textNum[fieldNo] ?? 1) + 1
                                                                    if textInputs[fieldNo] == nil {
                                                                        textInputs[fieldNo] = Array(repeating: "", count: textNum[fieldNo]!)
                                                                    } else {
                                                                        textInputs[fieldNo]!.append("")
                                                                    }
                                                                }
                                                                .buttonStyle(BlueButtonStyle())
                                                                
                                                                Spacer()
                                                                
                                                                if (textNum[fieldNo] ?? 1) > 1 {
                                                                    Button("項目削除") {
                                                                        textNum[fieldNo] = max((textNum[fieldNo] ?? 1) - 1, 1)
                                                                        if var list = textInputs[fieldNo], list.count > 1 {
                                                                            list.removeLast()
                                                                            textInputs[fieldNo] = list
                                                                        }
                                                                    }
                                                                    .buttonStyle(RedButtonStyle())
                                                                }
                                                            }
                                                        }
                                                    case "pulldown":
                                                        let count = selectNum[fieldNo] ?? 1
                                                        ForEach(0..<count, id: \.self) { idx in
                                                            if let selections = variable["selections"] as? [[String: Any]] {
                                                                Picker("", selection: Binding(
                                                                    get: {
                                                                        if let list = selectedDropdown[fieldNo], list.indices.contains(idx) {
                                                                            return list[idx]
                                                                        }
                                                                        return selections.first?["name"] as? String ?? ""
                                                                    },
                                                                    set: { newValue in
                                                                        if selectedDropdown[fieldNo] == nil {
                                                                            selectedDropdown[fieldNo] = Array(repeating: "", count: count)
                                                                        }
                                                                        if var list = selectedDropdown[fieldNo] {
                                                                            if idx < list.count {
                                                                                list[idx] = newValue
                                                                            } else {
                                                                                list.append(contentsOf: Array(repeating: "", count: idx - list.count + 1))
                                                                                list[idx] = newValue
                                                                            }
                                                                            selectedDropdown[fieldNo] = list
                                                                        }
                                                                    }
                                                                )) {
                                                                    ForEach(0..<selections.count, id: \.self) { i in
                                                                        let name = selections[i]["name"] as? String ?? ""
                                                                        Text(name).tag(name)
                                                                    }
                                                                }
                                                                .pickerStyle(MenuPickerStyle())
                                                            }
                                                        }
                                                        
                                                        if chainType == "2" {
                                                            HStack {
                                                                Button("項目追加") {
                                                                    selectNum[fieldNo] = (selectNum[fieldNo] ?? 1) + 1
                                                                    if selectedDropdown[fieldNo] == nil {
                                                                        selectedDropdown[fieldNo] = Array(repeating: "", count: selectNum[fieldNo]!)
                                                                    } else {
                                                                        selectedDropdown[fieldNo]!.append("")
                                                                    }
                                                                }
                                                                .buttonStyle(BlueButtonStyle())
                                                                
                                                                Spacer()
                                                                
                                                                if (selectNum[fieldNo] ?? 1) > 1 {
                                                                    Button("項目削除") {
                                                                        selectNum[fieldNo] = max((selectNum[fieldNo] ?? 1) - 1, 1)
                                                                        if var list = selectedDropdown[fieldNo], list.count > 1 {
                                                                            list.removeLast()
                                                                            selectedDropdown[fieldNo] = list
                                                                        }
                                                                    }
                                                                    .buttonStyle(RedButtonStyle())
                                                                }
                                                            }
                                                        }
                                                        
                                                    case "checkbox":
                                                        let count = checkboxNum[fieldNo] ?? 1
                                                        
                                                        VStack {
                                                            ForEach(0..<count, id: \.self) { idx in
                                                                if let selections = variable["selections"] as? [[String: Any]] {
                                                                    ForEach(0..<selections.count, id: \.self) { i in
                                                                        let selectionName = selections[i]["name"] as? String ?? ""
                                                                        Toggle(selectionName, isOn: Binding(
                                                                            get: {
                                                                                guard let selectionsArray = checkboxSelected[fieldNo],
                                                                                    selectionsArray.indices.contains(idx) else {
                                                                                    return false
                                                                                }
                                                                                return selectionsArray[idx].contains(selectionName)
                                                                            },
                                                                            set: { newValue in
                                                                                if checkboxSelected[fieldNo] == nil {
                                                                                    checkboxSelected[fieldNo] = Array(repeating: Set<String>(), count: idx + 1)
                                                                                }
                                                                                
                                                                                if checkboxSelected[fieldNo]!.count <= idx {
                                                                                    let padding = Array(repeating: Set<String>(), count: idx - checkboxSelected[fieldNo]!.count + 1)
                                                                                    checkboxSelected[fieldNo]! += padding
                                                                                }
                                                                                
                                                                                if newValue {
                                                                                    checkboxSelected[fieldNo]![idx].insert(selectionName)
                                                                                } else {
                                                                                    checkboxSelected[fieldNo]![idx].remove(selectionName)
                                                                                }
                                                                            }
                                                                        ))
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        .onAppear {
                                                            if checkboxSelected[fieldNo] == nil {
                                                                checkboxSelected[fieldNo] = Array(repeating: Set<String>(), count: count)
                                                            } else if checkboxSelected[fieldNo]!.count < count {
                                                                let additional = Array(repeating: Set<String>(), count: count - checkboxSelected[fieldNo]!.count)
                                                                checkboxSelected[fieldNo]! += additional
                                                            }
                                                        }
                                                        
                                                        if chainType == "2" {
                                                            HStack {
                                                                Button("項目追加") {
                                                                    checkboxNum[fieldNo] = (checkboxNum[fieldNo] ?? 1) + 1
                                                                    if checkboxSelected[fieldNo] == nil {
                                                                        checkboxSelected[fieldNo] = Array(repeating: Set<String>(), count: checkboxNum[fieldNo]!)
                                                                    } else {
                                                                        checkboxSelected[fieldNo]!.append(Set<String>())
                                                                    }
                                                                }
                                                                .buttonStyle(BlueButtonStyle())
                                                                
                                                                Spacer()
                                                                
                                                                if (checkboxNum[fieldNo] ?? 1) > 1 {
                                                                    Button("項目削除") {
                                                                        checkboxNum[fieldNo] = max((checkboxNum[fieldNo] ?? 1) - 1, 1)
                                                                        if var list = checkboxSelected[fieldNo], list.count > 1 {
                                                                            list.removeLast()
                                                                            checkboxSelected[fieldNo] = list
                                                                        }
                                                                    }
                                                                    .buttonStyle(RedButtonStyle())
                                                                }
                                                            }
                                                        }
                                                        
                                                    default:
                                                        Text("未対応の変数タイプ: \(type)")
                                                    }
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                                
                                Spacer()
                                HStack(spacing: 16) {
                                    Spacer()
                                    Picker("同時出力回数", selection: $sendMessageCount) {
                                        Text("1").tag(1)
                                        Text("2").tag(2)
                                        Text("3").tag(3)
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .frame(width: 200)
                                    Button("プロンプト実行") {
                                        executePrompt()
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
                                .background(Color(NSColor.windowBackgroundColor))
                                .padding(.horizontal, 8)
                                .offset(x: 10, y: -8)
                                .zIndex(1)
                        }
                        
                        // ⑤ 実行結果
                        ZStack(alignment: .topLeading) {
                            VStack {
                                if outputCount > 0 {
                                    VStack(alignment: .leading, spacing: 8) {
                                        // ⑨ 回答タブ
                                        HStack {
                                            Button("◀") {
                                                if selectedTab > 0 {
                                                    selectedTab -= 1
                                                }
                                            }
                                            .disabled(selectedTab == 0)
                                            .buttonStyle(.bordered)
                                            
                                            ForEach(0..<outputCount, id: \.self) { idx in
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
                                                if selectedTab < outputCount - 1 {
                                                    selectedTab += 1
                                                }
                                            }
                                            .disabled(selectedTab == outputCount - 1)
                                            .buttonStyle(.bordered)
                                        }
                                        ScrollView(.vertical) {
                                            VStack(alignment: .leading, spacing: 0) {
                                                if outputs.indices.contains(selectedTab) {
                                                    Text(outputs[selectedTab])
                                                        .padding(4)
                                                } else {
                                                    Text("")
                                                        .padding(4)
                                                }
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundColor(.gray)
                                            .font(.body)
                                            .cornerRadius(8)
                                            .background(Color(NSColor.windowBackgroundColor))
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
                                                if outputs.indices.contains(selectedTab) {
                                                    pasteboard.setString(outputs[selectedTab], forType: .string)
                                                }
                                            }
                                            .buttonStyle(BlueButtonStyle())
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(10)
                            .border(Color.gray.opacity(0.3))
                            Text("実行結果")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                                .background(Color(NSColor.windowBackgroundColor))
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
            .onAppear(perform: loadPromptDetail)
        }
        .frame(width: 1080, height: 800)
    }
    
    private func loadPromptDetail() {
        APIClient.request(path: "prompt-detail/\(prompt.id)") { result in
            switch result {
            case .success(let data):
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        DispatchQueue.main.async {
                            self.promptDetail = jsonArray
                            // Initialize counts on load
                            if let variables = jsonArray["variables"] as? [[String: Any]] {
                                for variable in variables {
                                    let fieldNo = String(variable["fieldNo"] as? Int ?? 0)
                                    let type = variable["type"] as? String ?? ""
                                    let chainType = String(variable["chainValueType"] as? Int ?? 0)
                                    // Setup initial counts depending on type
                                    switch type {
                                    case "free":
                                        textNum[fieldNo] = 1
                                        textInputs[fieldNo] = [""]
                                    case "pulldown":
                                        selectNum[fieldNo] = 1
                                        if let selections = variable["selections"] as? [[String: Any]], let firstName = selections.first?["name"] as? String {
                                            selectedDropdown[fieldNo] = [firstName]
                                        } else {
                                            selectedDropdown[fieldNo] = [""]
                                        }
                                    case "checkbox":
                                        checkboxNum[fieldNo] = 1
                                        checkboxSelected[fieldNo] = [Set<String>()]
                                    default:
                                        break
                                    }
                                }
                            }
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
    
    private func executePrompt() {
        showDialog = true
        selectedTab = 0
        var tempValues: [String: String] = [:]
        var isChain : Bool = false
        var body:[String:Any] = [:]
        let selectedDropdownAny = selectedDropdown.mapValues { $0 as Any }
        let checkboxSelectedAny = checkboxSelected.mapValues { value in
            value.map { set in
                set.joined(separator: ", ")
            }
        }
        let textInputsAny = textInputs.mapValues { $0 as Any }
        let merged = selectedDropdownAny
            .merging(checkboxSelectedAny) { _, new in new }
            .merging(textInputsAny) { _, new in new }
        
        if let variables = promptDetail?["variables"] as? [[String: Any]] {
            for variable in variables {
                let fieldNo = String(variable["fieldNo"] as? Int ?? 0)
                let chainType = String(variable["chainValueType"] as? Int ?? 0)
                if chainType != "0" {
                    isChain = true
                }
                tempValues[fieldNo] = chainType
            }
        }
        
        let result: [[String: Any]] = merged.compactMap { (key, value) in
            if let intKey = Int(key),
               let chainValue = tempValues[key],
               let intChainValue = Int(chainValue) {
                return [
                    "fieldNo": intKey,
                    "chainValueType": intChainValue,
                    "contentsList": value
                ]
            }
            return nil
        }
        
        if let id = promptDetail?["id"] as? Int {
            body["id"] = id
            body["variables"] = result
        }
        
        do {
            let bodyData = try JSONSerialization.data(withJSONObject: body, options: [])
            let path = isChain ? "chain-prompt-execute" : "prompt-execute"
            
            outputCount = sendMessageCount
            outputs = Array(repeating: "", count: sendMessageCount)
            
            for number in 0..<sendMessageCount {
                APIClient.request(path: path, method: "POST", body: bodyData) { result in
                    switch result {
                    case .success(let data):
                        do {
                            if let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                if isChain, let executeCode = jsonDict["execute_code"] as? Int {
                                    DispatchQueue.main.async {
                                        // poll for chain prompt result
                                        pollChainResult(executeCode: executeCode, responseNumber: number)
                                    }
                                } else {
                                    DispatchQueue.main.async {
                                        self.showDialog = false
                                        if let message = jsonDict["message"] as? String {
                                            if outputs.indices.contains(number) {
                                                outputs[number] = message
                                            }
                                        } else {
                                            print("No 'message' in non-chain response")
                                        }
                                    }
                                }
                            } else {
                                print("Invalid JSON root object.")
                            }
                        } catch {
                            print("JSON parse error: \(error.localizedDescription)")
                        }
                    case .failure(let error):
                        print("Initial request failed: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            self.showDialog = false
                        }
                    }
                }
            }
        } catch {
            print("Error serializing body: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.showDialog = false
            }
        }
    }
    
    private func pollChainResult(executeCode: Int, responseNumber: Int) {
        var timer: Timer?
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            APIClient.request(path: "chain-prompt-result/\(executeCode)") { result in
                switch result {
                case .success(let data):
                    do {
                        if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                           let status = jsonArray["status"] as? String, status != "executing" {
                            timer?.invalidate()
                            timer = nil
                            DispatchQueue.main.async {
                                self.showDialog = false
                                if let message = jsonArray["message"] as? String {
                                    if self.outputs.indices.contains(responseNumber) {
                                        self.outputs[responseNumber] = message
                                    }
                                } else {
                                    print("No 'message' in chain response")
                                }
                            }
                        }
                    } catch {
                        print("Error parsing chain result: \(error.localizedDescription)")
                    }
                case .failure(let error):
                    print("Chain poll failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// Preview
struct PromptDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PromptDetailView(prompt: PromptItem(
            id: 143625,
            title: "小説複数カテゴリ_コピー",
            folder: "小説作成",
            type: "prompt",
            date: "2025-03-13 07:48:40"
        ))
        .frame(width: 1080, height: 800)
    }
}

