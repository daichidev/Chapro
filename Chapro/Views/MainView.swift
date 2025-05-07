//
//  MainView.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import SwiftUI
import Foundation

struct MainView: View {
    @State private var notification: String = ""
    @State private var showSettings = false
    @State private var path: [String] = []
    @State private var promptList: [[String: Any]] = []
    var body: some View {
        NavigationStack(path: $path) {
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
                
                VStack(spacing: 20) {
                    HStack(spacing: 10) {
                       MainButton(title: "プロンプト一覧") {
                            path.append("promptList")
                        }
                       .disabled(promptList.isEmpty)
                        
                        MainButton(title: "AIチャット") {
                            path.append("chatView")
                        }
                    }
                    .padding(.top)
                    
                    ZStack(alignment: .topLeading) {
                        VStack(alignment: .leading) {
                            ScrollView {
                                Text(notification)
                                    .multilineTextAlignment(.leading)
                                    .font(.system(size: 18))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(6)
                            .frame(maxWidth: .infinity)
                            .border(Color.gray.opacity(0.3))
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.windowBackgroundColor))
                        .border(Color.gray.opacity(0.3))
                        
                        Text("お知らせ")
                            .font(.system(size: 16))
                            .padding(.horizontal, 10)
                            .background(Color(.windowBackgroundColor))
                            .offset(x: 30, y: -10)
                    }
                    
                    HStack {
                        Spacer()
                        Button("設定") {
                            path.append("settings")
                        }
                        .buttonStyle(MainBlueButtonStyle())
                        
                        Button("閉じる") {
                            NSApplication.shared.terminate(nil)
                        }
                        .buttonStyle(MainGrayButtonStyle())
                    }
                    .padding(4)
                }
                .padding()
            }
            .navigationDestination(for: String.self) { value in
                
                switch value {
                case "promptList":
                    PromptListView(promptList: self.promptList)
                case "chatView":
                    ChatView()
                case "settings":
                    SettingsView()
                default:
                    EmptyView()
                }
            }
            .onAppear {
                if let code = DatabaseManager.shared.getSetting(key: "chapro") {
                    showSettings = code.count == 0 ? true : false
                }
                if showSettings == false {
                    APIClient.request(path: "info"){ result in
                        switch result {
                        case .success(let data):
                            do{
                                if let json = try JSONSerialization.jsonObject(with: data, options:[]) as? [String: Any],
                                   let information = json["information"] as? [[String:Any]] {
                                    let title = information[0]["title"] as? String ?? ""
                                    let content = information[0]["content"] as? String ?? ""
                                    let formattedNotification = """
                                                                        
                                    【\(title)】
                                    \(content)                                    
                                    
                                    """
                                    DispatchQueue.main.async {
                                        self.notification = formattedNotification
                                    }
                                }
                            } catch {
                                print("JSON parsing error: \(error.localizedDescription)")
                            }
                            
                        case .failure(let error):
                            self.notification = error.localizedDescription
                        }
                    }
                    APIClient.request(path: "prompt-list") { result in
                        switch result {
                        case .success(let data):
                            do {
                                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                                    DispatchQueue.main.async {
                                        self.promptList = jsonArray
                                    }
                                } else {
                                    print("Unexpected JSON structure")
                                }
                            } catch {
                                self.notification = error.localizedDescription
                            }

                        case .failure(let error):
                            self.notification = error.localizedDescription
                        }
                    }
                }
                
            }
            .navigationTitle("チャプロ")
            // .sheet(isPresented: $showSettings) {
            //     SettingsView()
            // }
        }
    }
}

#Preview {
    MainView()
}
