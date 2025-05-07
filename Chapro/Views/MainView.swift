//
//  MainView.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import SwiftUI
import Foundation

struct MainView: View {
    let samplePrompts: [[String: Any]] = [
        [
            "id": 128095,
            "type": "prompt",
            "folder": "カテゴリー名",
            "name": "通常プロンプトデスクトップテスト",
            "created_at": "2025-02-21 16:07:58"
        ],
        [
            "id": 128098,
            "type": "chain-prompt",
            "folder": "カテゴリー名",
            "name": "チェーンプロンプトデスクトップテスト",
            "created_at": "2025-02-21 16:08:29"
        ],
        [
            "id": 143623,
            "type": "prompt",
            "folder": "小説作成",
            "name": "小説_コピー",
            "created_at": "2025-03-13 07:48:40"
        ],
        [
            "id": 143624,
            "type": "prompt",
            "folder": "小説作成",
            "name": "小説_コピー",
            "created_at": "2025-03-13 07:48:40"
        ],
        [
            "id": 143625,
            "type": "prompt",
            "folder": "小説作成",
            "name": "小説複数カテゴリ_コピー",
            "created_at": "2025-03-13 07:48:40"
        ],
        [
            "id": 143626,
            "type": "chain-prompt",
            "folder": "小説作成",
            "name": "小説作成_デスクトップチェーン",
            "created_at": "2025-03-13 07:48:40"
        ],
        [
            "id": 143627,
            "type": "prompt",
            "folder": "画像作成",
            "name": "画像作成通常プロンプト_コピー",
            "created_at": "2025-03-13 07:48:44"
        ],
        [
            "id": 143628,
            "type": "chain-prompt",
            "folder": "画像作成",
            "name": "画像作成チェーン_コピー",
            "created_at": "2025-03-13 07:48:44"
        ],
        [
            "id": 147678,
            "type": "chain-prompt",
            "folder": "合体変数チェーンプロンプト",
            "name": "合体テスト２",
            "created_at": "2025-03-18 07:57:26"
        ],
        [
            "id": 147679,
            "type": "chain-prompt",
            "folder": "合体変数チェーンプロンプト",
            "name": "合体テスト１",
            "created_at": "2025-03-18 07:57:26"
        ]
    ]
    @State private var notification: String = """
【新機能「共有フォルダ機能」追加のお知らせ】
ご利用者の皆様

いつもクラウドメモ帳サービス「Notes Hub」をご利用いただき、誠にありがとうございます。
株式会社ドキュメントソリューションズです。

この度、Notes Hubに新機能「共有フォルダ機能」が追加されましたことをお知らせいたします。

▼ 追加された機能
共有フォルダ機能：フォルダ単位で他のユーザーとメモを共有できるようになりました。

この機能により、チームでの情報共有や共同編集がよりスムーズになります。

新機能は、ログイン後、フォルダ一覧画面の右上の「新規作成」メニューから「共有フォルダを作成」を選択することでご利用いただけます。

詳しい使い方は、以下のヘルプページをご覧ください。
https://notes-hub.example.com/help/shared-folder

ぜひこの機会に新機能をお試しいただき、Notes Hubをより便利にご活用ください。

今後ともNotes Hubをよろしくお願いいたします。

--------------------------------------------------
株式会社ドキュメントソリューションズ
クラウドメモ帳サービス「Notes Hub」運営チーム

サービスサイト： https://notes-hub.example.com
お問い合わせフォーム： https://notes-hub.example.com/support
メール： support@notes-hub.example.com
--------------------------------------------------
"""
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
                    PromptListView(promptList: samplePrompts)
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
