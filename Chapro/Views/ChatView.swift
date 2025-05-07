import SwiftUI

struct ChatHeaderView: View {
    var body: some View {
        HStack {
            Image("ダウンロード")
                .resizable()
                .frame(width: 150, height: 32)
            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 56)
        .background(Color.blue.opacity(0.3))
        .foregroundColor(.white)
    }
}

struct ThreadListView: View {
    @Binding var threads: [ChatThread]
    @Binding var selectedThread: ChatThread?
    @Binding var messages: [ChatMessage]
    var onAddThread: () -> Void
    var onDeleteThread: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("スレッド作成") {
                    onAddThread()
                }
                .buttonStyle(BlueButtonStyle())
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
                .padding(.top, 8)
            }
            
            List(selection: $selectedThread) {
                ForEach(threads) { thread in
                    HStack {
                        Text(thread.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tag(thread as ChatThread?)
                    .listRowBackground(selectedThread?.id == thread.id ? Color.blue : Color.clear)
                    .foregroundColor(selectedThread?.id == thread.id ? .white : .primary)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedThread = thread
                        messages = DatabaseManager.shared.getChatMessages(threadId: thread.id)
                    }
                }
            }
            .border(Color.gray.opacity(0.3))
            .listStyle(PlainListStyle())
            .frame(minWidth: 180, maxWidth: 220)
            
            HStack {
                Spacer()
                Button("スレッド削除") {
                    onDeleteThread()
                }
                .buttonStyle(RedButtonStyle())
                .padding(.top, 8)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
        .frame(width: 220)
        .padding(4)
        .border(Color(Color.gray.opacity(0.4)), width: 1)
    }
}

struct ChatMessagesView: View {
    let messages: [ChatMessage]
    let currentAnswers: [String]
    @Binding var selectedAnswerIndex: Int
    var onAnswerSelected: (String) -> Void
    var threadAnswerCounts: [Int: Int]
    
    @State private var selectedAnswers: [Int: Int] = [:]
    @State private var showAnswerAlert: Bool = false
    @State private var answerToShow: String = ""
    @State private var showAnswersModal: Bool = false
    @State private var modalAnswers: [ChatMessage] = []
    @State private var modalSelectedIndex: Int = 0
    
    func getAnswersForQuestion(_ message: ChatMessage) -> [ChatMessage] {
        guard let messageIndex = messages.firstIndex(where: { $0.id == message.id }) else {
            return []
        }
        
        let remainingMessages = Array(messages.suffix(from: messageIndex + 1))
        let nextQuestionIndex = remainingMessages.firstIndex(where: { $0.type == "user" }) ?? remainingMessages.count
        
        return remainingMessages.prefix(nextQuestionIndex).filter { $0.type == "ai" }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(messages.filter { $0.type == "user" }, id: \.id) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(question.message)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        HStack(spacing: 10) {
                            Spacer()
                            Text("文字数 : \(question.message.count)")
                            .font(.caption)
                        }
                        let answers = getAnswersForQuestion(question)
                        let selectedIndex = selectedAnswers[question.id] ?? 0
                        if !answers.isEmpty {
                            HStack(spacing: 2) {
                                Button(action: {
                                    if selectedIndex > 0 {
                                        selectedAnswers[question.id] = selectedIndex - 1
                                    }
                                }) {
                                    Text("◀")
                                        .padding(8)
                                        .foregroundColor(selectedIndex > 0 ? .blue : .gray)
                                        .cornerRadius(8)
                                }
                                .disabled(selectedIndex == 0)

                                ForEach(0..<answers.count, id: \.self) { i in
                                    Button(action: {
                                        selectedAnswers[question.id] = i
                                    }) {
                                        Text("回答\(i+1)")
                                            .padding(8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedIndex == i ? Color.blue : Color.gray.opacity(0.2))
                                            .foregroundColor(selectedIndex == i ? Color.white : Color.gray)
                                            .cornerRadius(8)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }

                                Button(action: {
                                    if selectedIndex < answers.count - 1 {
                                        selectedAnswers[question.id] = selectedIndex + 1
                                    }
                                }) {
                                    Text("▶")
                                        .padding(8)
                                        .foregroundColor(selectedIndex < answers.count - 1 ? .blue : .gray)
                                        .cornerRadius(8)
                                }
                                .disabled(selectedIndex == answers.count - 1)
                            }
                            .frame(maxWidth: .infinity)
                            
                            if selectedIndex < answers.count {
                                HStack {
                                    Text(answers[selectedIndex].message)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .background(Color.gray.opacity(0.3))
                                .cornerRadius(4)
                                .padding(4)
                                
                                HStack(spacing: 10) {
                                    Spacer()
                                    Button("表示") {
                                        modalAnswers = answers
                                        modalSelectedIndex = 0
                                        showAnswersModal = true
                                    }
                                    .buttonStyle(BlueButtonStyle())
                                    Button("全コピー") {
                                        let allAnswers = answers.map { $0.message }.joined(separator: "\n\n")
                                        #if os(macOS)
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(allAnswers, forType: .string)
                                        #endif
                                    }
                                    .buttonStyle(BlueButtonStyle())
                                    Button("コピー") {
                                        let answer = answers[selectedIndex].message
                                        #if os(macOS)
                                        let pasteboard = NSPasteboard.general
                                        pasteboard.clearContents()
                                        pasteboard.setString(answer, forType: .string)
                                        #endif
                                    }
                                    .buttonStyle(BlueButtonStyle())
                                    Text("文字数 : \(answers[selectedIndex].message.count)")
                                    .font(.caption)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .onAppear {
                        if selectedAnswers[question.id] == nil {
                            selectedAnswers[question.id] = 0
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
         NavigationLink(
            destination: ChatDetailView(modalAnswers: $modalAnswers, modalSelectedIndex: $modalSelectedIndex),
            isActive: $showAnswersModal
        ) {
            EmptyView()
        }
        .hidden()
    }
}

struct ChatInputView: View {
    @Binding var inputText: String
    @Binding var simultaneousOutputCount: Int
    var onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                TextEditor(text: $inputText)
                    .frame(height: .infinity)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.gray, lineWidth: 1)
                    )
            }
            .frame(width: .infinity)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("同時出力回数")
                    .font(.caption)
                HStack {
                    Picker("", selection: $simultaneousOutputCount) {
                        ForEach(1...10, id: \.self) { number in
                            Text("\(number)").tag(number)
                        }
                    }
                    .frame(width: .infinity)
                    Text("回")
                        .font(.caption)
                }
                .frame(width: 100)
                HStack {
                    Spacer()
                    Button("送信") {
                        onSend()
                    }
                    .buttonStyle(BlueButtonStyle())
                    .disabled(inputText.isEmpty)
                }
            }
            .frame(width: 100)
        }
        .padding(10)
        .frame(height: 100)
    }
}

struct ChatView: View {
    @State private var threads: [ChatThread] = DatabaseManager.shared.getChatThreads()
    @State private var selectedThread: ChatThread? = nil
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var simultaneousOutputCount: Int = 1
    @State private var showAlert = false
    @State private var newThreadName = "新規スレッド"
    @State private var aiAnswers: [[ChatMessage]] = []
    @State private var selectedAnswerIndex: Int = 0
    @State private var showModal: Bool = false
    @State private var currentAnswers: [String] = []
    @State private var messageAnswerCounts: [Int: Int] = [:]
    @Environment(\.dismiss) var dismiss
    @State private var showDialog = false

    private func generateRandomAnswer(for question: String, index: Int) -> String {
        let templates = [
            "これは\(index + 1)番目の回答です。\(question)について、新しい視点から考えてみましょう。",
            "\(index + 1)番目の回答として、\(question)について異なるアプローチを提案します。",
            "\(question)について、\(index + 1)番目の回答を考えてみました。",
            "\(index + 1)番目の回答です。\(question)について、別の角度から分析してみましょう。",
            "\(question)について、\(index + 1)番目の回答を提示します。"
        ]
        return templates[index % templates.count]
    }

    private func nextThreadName() -> String {
        let base = "新規スレッド"
        let numbers = threads.compactMap { thread -> Int? in
            if thread.name.hasPrefix(base) {
                let suffix = thread.name.dropFirst(base.count)
                return Int(suffix)
            }
            return nil
        }
        let next = (numbers.max() ?? 0) + 1
        return "\(base)\(next)"
    }

    private func addThread() {
        let name = nextThreadName()
        if let id = DatabaseManager.shared.addChatThread(name: name) {
            threads = DatabaseManager.shared.getChatThreads()
            if let newThread = threads.first(where: { $0.id == id }) {
                selectedThread = newThread
                messages = DatabaseManager.shared.getChatMessages(threadId: newThread.id)
                currentAnswers = []
                selectedAnswerIndex = 0
            }
        }
    }

    private func deleteThread() {
        guard let thread = selectedThread else { return }
        DatabaseManager.shared.deleteChatThread(id: thread.id)
        messageAnswerCounts = messageAnswerCounts.filter { $0.key != thread.id }
        threads = DatabaseManager.shared.getChatThreads()
        if let first = threads.first {
            selectedThread = first
            messages = DatabaseManager.shared.getChatMessages(threadId: first.id)
            currentAnswers = []
            selectedAnswerIndex = 0
        } else {
            selectedThread = nil
            messages = []
            currentAnswers = []
            selectedAnswerIndex = 0
        }
    }

    private func saveSelectedAnswer(_ answer: String) {
        guard let thread = selectedThread else { return }
        
        let messageId = DatabaseManager.shared.getNextMessageId(threadId: thread.id)
        let aiMessage = ChatMessage(
            id: messageId,
            threadId: thread.id,
            seq: selectedAnswerIndex + 1,
            type: "ai",
            message: answer,
            createAt: Date()
        )
        
        if DatabaseManager.shared.addChatMessage(
            threadId: thread.id,
            id: messageId,
            seq: selectedAnswerIndex + 1,
            type: "ai",
            message: answer,
            createAt: Date()
        ) {
            messages.append(aiMessage)
            currentAnswers = []
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        showDialog = true // Show dialog when send is pressed

        if let thread = selectedThread {
            let questionId = DatabaseManager.shared.getNextMessageId(threadId: thread.id)
            let userMessage = ChatMessage(
                id: questionId,
                threadId: thread.id,
                seq: 1,
                type: "user",
                message: inputText,
                createAt: Date()
            )
            
            if DatabaseManager.shared.addChatMessage(
                threadId: thread.id,
                id: questionId,
                seq: 1,
                type: "user",
                message: inputText,
                createAt: Date()
            ) {
                messages.append(userMessage)
                
                for i in 0..<simultaneousOutputCount {
                    let answerId = DatabaseManager.shared.getNextMessageId(threadId: thread.id)
                    let answer = generateRandomAnswer(for: inputText, index: i)
                    
                    let aiMessage = ChatMessage(
                        id: answerId,
                        threadId: thread.id,
                        seq: i + 1,
                        type: "ai",
                        message: answer,
                        createAt: Date()
                    )
                    
                    if DatabaseManager.shared.addChatMessage(
                        threadId: thread.id,
                        id: answerId,
                        seq: i + 1,
                        type: "ai",
                        message: answer,
                        createAt: Date()
                    ) {
                        messages.append(aiMessage)
                    }
                }
                
                inputText = ""
                selectedAnswerIndex = 0
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ChatHeaderView()
            
            HStack(spacing: 0) {
                ZStack(alignment: .topLeading) {
                    ThreadListView(
                        threads: $threads,
                        selectedThread: $selectedThread,
                        messages: $messages,
                        onAddThread: addThread,
                        onDeleteThread: deleteThread
                    )

                    Text("スレッドエリア")
                    .font(.caption)
                    .background(Color(.windowBackgroundColor))
                    .offset(x: 10, y: -5)
                    .zIndex(1)
                }
                .padding(10)
                
                
                VStack(spacing: 8) {
                    VStack {
                        ChatMessagesView(
                            messages: messages,
                            currentAnswers: currentAnswers,
                            selectedAnswerIndex: $selectedAnswerIndex,
                            onAnswerSelected: saveSelectedAnswer,
                            threadAnswerCounts: messageAnswerCounts
                        )
                    }
                    .border(.gray)
                    
                    ZStack(alignment: .leading){
                        VStack {
                            ChatInputView(
                                inputText: $inputText,
                                simultaneousOutputCount: $simultaneousOutputCount,
                                onSend: sendMessage
                            )
                            
                        }
                        .border(.gray)

                        Text("入力エリア")
                        .font(.caption)
                        .background(Color(.windowBackgroundColor))
                        .offset(x: 10, y: -50)
                        .zIndex(1)
                    }
                }
                .padding(8)
                .border(Color.gray.opacity(0.4), width: 1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
                .padding(.top, 10)
            
            HStack {
                Spacer()
                Button("閉じる") {
                    dismiss()
                }
                .buttonStyle(MainGrayButtonStyle())
                .padding(8)
            }
        }
        .navigationTitle("AIチャット")
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
    }
}

#Preview {
    ChatView()
}
