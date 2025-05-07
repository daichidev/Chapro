//
//  PromptListView.swift
//  Chapro
//
//  Created by admin on 4/25/25.
//

import SwiftUI

struct PromptListView: View {

    var promptList: [[String: Any]]
    
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedFilter: String? = nil
    @State private var sortOption: String = "作成日（降順）"
    @State private var prompts: [PromptItem] = []
    @State private var filters: [String] = []
    @State private var selectedPrompt: PromptItem?
    @State private var showDetail = false

    init(promptList: [[String: Any]]) {
        self.promptList = promptList
        
        let promptItems = promptList.compactMap { dict -> PromptItem? in
            guard let id = dict["id"] as? Int,
                let title = dict["name"] as? String,
                let folder = dict["folder"] as? String,
                let dateString = dict["created_at"] as? String,
                let type = dict["type"] as? String
            else {
                return nil
            }

            let inputFormatter = DateFormatter()
            inputFormatter.locale = Locale(identifier: "en_US_POSIX")
            inputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            guard let date = inputFormatter.date(from: dateString) else {
                return nil
            }

            let outputFormatter = DateFormatter()
            outputFormatter.locale = Locale(identifier: "en_US_POSIX")
            outputFormatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = outputFormatter.string(from: date)

            return PromptItem(id: id, title: title, folder: folder, type: type, date: formattedDate)
        }
        
        let folderSet = Set(promptItems.map { $0.folder })
        _prompts = State(initialValue: promptItems)
        _filters = State(initialValue: ["すべて"] + folderSet.sorted())
    }
        
    var filteredPrompts: [PromptItem] {
        var result = prompts
        if selectedFilter != "すべて" {
            result = result.filter { $0.folder == selectedFilter }
        }

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.folder.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOption {
        case "名前（昇順）":
            result = result.sorted { $0.title < $1.title }
        case "名前（降順）":
            result = result.sorted { $0.title > $1.title }
        case "作成日（昇順）":
            result = result.sorted { $0.date < $1.date }
        default:
            result = result.sorted { $0.date > $1.date }
        }

        return result
    }
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
                // 左：フィルターリスト
            GeometryReader { geometry in
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filters, id: \.self) { filter in
                                    Text(filter)
                                        .font(.system(size: 16))
                                        .foregroundColor(selectedFilter == filter ? .white : .primary)
                                        .padding(10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(
                                            Group {
                                                if selectedFilter == filter {
                                                    Color.blue
                                                } else {
                                                    Color(NSColor.textBackgroundColor)
                                                }
                                            }
                                        )
                                        .cornerRadius(6)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            selectedFilter = filter
                                        }
                                }
                                Spacer()
                            }
                        }
                        .padding(10)
                        .background(Color(NSColor.textBackgroundColor))
                    }
                    .border(Color.gray.opacity(0.2))
                    .padding(10)
                    .frame(width: geometry.size.width * 0.3)



                    // 右：メイン
                    VStack(spacing: 0) {
                        // 右上：検索・ソート・新規
                        HStack {
                        ZStack(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 8) {
                                    Text("プロンプト名/制作者の検索")
                                        .font(.system(size:14))
                                        .foregroundColor(.gray)
                                        .background(Color(.windowBackgroundColor))
                                        .padding(.horizontal, 8)
                                        .offset(x: 10, y: 15)
                                        .zIndex(1)

                                    VStack {
                                        HStack(spacing: 8) {
                                            TextField("", text: $searchText)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                            
                                            Button("検索") {
                                            }
                                            .buttonStyle(BlueButtonStyle())
                                        }
                                        .padding(8)
                                    }
                                    .background(RoundedRectangle(cornerRadius: 4).stroke(Color.gray.opacity(0.5)))
                                }
                                .padding()
                                
                            }
                            Picker("", selection: $sortOption) {
                                Text("名前（昇順）").tag("名前（昇順）")
                                Text("名前（降順）").tag("名前（降順）")
                                Text("作成日（昇順）").tag("作成日（昇順）")
                                Text("作成日（降順）").tag("作成日（降順）")
                            }
                            .frame(width: 140)
                            .padding(.top, 40)
                            .pickerStyle(MenuPickerStyle())
                            Spacer()
                        }
                        
                        // プロンプト一覧（テーブル風）
                        TableHeaderView()
                        .padding([.leading, .trailing])
                        
                        List(filteredPrompts) { item in
                            HStack {
                                Text(item.title)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .font(.system(size: 16))
                                Text(item.date)
                                    .frame(width: 200)
                                    .font(.system(size: 16))
                                Button("表示") {
                                    selectedPrompt = item
                                    showDetail = true
                                }
                                .buttonStyle(BlueButtonStyle())
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture(count: 2) {
                                selectedPrompt = item
                                showDetail = true
                            }
                        }
                        .padding([.leading, .trailing])
                        .listStyle(PlainListStyle())
                        .navigationDestination(isPresented: $showDetail) {
                            if let selectedPrompt = selectedPrompt {
                                PromptDetailView(prompt: selectedPrompt)
                            }
                        }
                        Spacer()
                        // 下部：閉じるボタン
                        HStack {
                            Spacer()
                            Button("閉じる") {
                                dismiss()
                            }
                            .buttonStyle(MainGrayButtonStyle())
                            .padding()
                        }
                    }
                    .border(Color.gray.opacity(0.2))
                    .padding(10)
                    .frame(width: geometry.size.width * 0.7)
                }
            }
        }
        .navigationTitle("プロンプト一覧")
    }
}

struct PromptItem: Identifiable, Hashable {
    let id : Int
    let title: String
    let folder: String
    let type: String
    let date: String
}

struct TableHeaderView: View {
    var body: some View {
        HStack {
            Text("プロンプト名")
                .font(.system(size: 18)).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("作成日")
                .font(.system(size: 18)).bold()
                .frame(width: 200)
            Text("")
                .frame(width: 60)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.4))
    }
}
