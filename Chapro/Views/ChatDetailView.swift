//
//  ChatDetailView.swift
//  Chapro
//
//  Created by そらだい on 2025/05/02.
//
import SwiftUI
struct ChatDetailView: View {
    @Binding var modalAnswers: [ChatMessage]
    @Binding var modalSelectedIndex: Int
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 16) {
                HStack{
                  Image("ダウンロード")
                        .resizable()
                        .frame(width: 200, height: 48)
                    
                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.3))
                .foregroundColor(.white)
                VStack{
                    HStack(spacing: 2) {
                        Button(action: {
                            if modalSelectedIndex > 0 {
                                modalSelectedIndex -= 1
                            }
                        }) {
                            Text("◀")
                                .padding(8)
                                .foregroundColor(modalSelectedIndex > 0 ? .blue : .gray)
                                .cornerRadius(8)
                        }
                        .disabled(modalSelectedIndex == 0)

                        ForEach(0..<modalAnswers.count, id: \.self) { i in
                            Button(action: {
                                modalSelectedIndex = i
                            }) {
                                Text("回答\(i+1)")
                                    .padding(8)
                                    .frame(maxWidth: .infinity)
                                    .background(modalSelectedIndex == i ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(modalSelectedIndex == i ? Color.white : Color.gray)
                                    .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        Button(action: {
                            if modalSelectedIndex < modalAnswers.count - 1 {
                                modalSelectedIndex += 1
                            }
                        }) {
                            Text("▶")
                                .padding(8)
                                .foregroundColor(modalSelectedIndex < modalAnswers.count - 1 ? .blue : .gray)
                                .cornerRadius(8)
                        }
                        .disabled(modalSelectedIndex == modalAnswers.count - 1)
                    }
                    .padding(.bottom, 8)
                    VStack(alignment: .leading){
                        if !modalAnswers.isEmpty && modalSelectedIndex < modalAnswers.count {
                            Text(modalAnswers[modalSelectedIndex].message)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .cornerRadius(8)
                        } else {
                            Text("回答がありません")
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .frame(maxHeight: .infinity)
                    .padding(10)
                    .border(.gray)
                    .background(Color.gray.opacity(0.2))
                    
                    HStack{
                        Button("全コピー") {
                            let allAnswers = modalAnswers.map { $0.message }.joined(separator: "\n\n")
                            #if os(macOS)
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(allAnswers, forType: .string)
                            #endif
                        }
                        .buttonStyle(BlueButtonStyle())
                        Text("平均文字数: \(modalAnswers.isEmpty ? 0 : modalAnswers.map { $0.message.count }.reduce(0, +) / modalAnswers.count)")
                            .font(.system(size: 16))
                        Spacer()
                        Button("回答コピー") {
                            if !modalAnswers.isEmpty && modalSelectedIndex < modalAnswers.count {
                                let answer = modalAnswers[modalSelectedIndex].message
                                #if os(macOS)
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(answer, forType: .string)
                                #endif
                            }
                        }
                        .buttonStyle(BlueButtonStyle())
                        Text("文字数 : \(modalAnswers.isEmpty || modalSelectedIndex >= modalAnswers.count ? 0 : modalAnswers[modalSelectedIndex].message.count)")
                            .font(.system(size: 16))
                    }
                    Spacer()
                   Button("閉じる") {
                        dismiss()
                    }
                    .buttonStyle(MainGrayButtonStyle())
                    .padding(.top, 8)
                }
                .padding()
                
            }
        .navigationTitle("質問")
    }
}
