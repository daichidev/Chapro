//
//  MainView.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import SwiftUI
import Foundation

class ReloadManager: ObservableObject {
    @Published var shouldReload = false
}

struct MainView: View {
    @State private var notification: String = ""
    @State private var serverHost: String = ""
    @StateObject var reloadManager = ReloadManager()
    @State private var checkCount: Int = 0
    @State private var checkValue: Int = 0
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
                        // .disabled(serverHost.isEmpty)
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
                    SettingsView(reloadManager: reloadManager)
                default:
                    EmptyView()
                }
            }
            .onAppear {
                if let code = DatabaseManager.shared.getSetting(key: "chapro") {
                    showSettings = code.count == 0 ? true : false
                }
                if showSettings == false {
                    fetchAPI()
                }
            }
            .navigationTitle("チャプロ")
            
            .sheet(isPresented: $showSettings) {
                SettingsView(reloadManager: reloadManager)
            }
        }
        .onChange(of: reloadManager.shouldReload) { newValue in
            if newValue {
                reloadData()
                reloadManager.shouldReload = false
            }
        }
    }
    func reloadData() {
        if let code = DatabaseManager.shared.getSetting(key: "chapro") {
            if code.count == 0 {
                NSApplication.shared.terminate(nil)
            }
            showSettings = code.count == 0 ? true : false
        }
        fetchAPI()
    }
    func fetchAPI(){
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
                            if let serverHost = json["security_check_server_host"] as? String {
                            
                            DispatchQueue.main.async {
                                self.serverHost = serverHost
                            }
                            }
                            if let checkCount = json["security_check_count"] as? Int {
                                
                                DispatchQueue.main.async {
                                    self.checkCount = checkCount
                                }
                            }
                            if let checkValue = json["security_check_value"] as? Int {
                                
                                DispatchQueue.main.async {
                                    self.checkValue = checkValue
                                }
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
}

#Preview {
    MainView()
}
