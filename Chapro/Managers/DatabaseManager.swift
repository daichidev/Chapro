//
//  DatabaseManager.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//


import Foundation
import SQLite3

class DatabaseManager {
    static let shared = DatabaseManager()
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        let fileManager = FileManager.default
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent("chapro.db").path
        
        if sqlite3_open(dbPath, &db) == SQLITE_OK {
            createTables()
        } else {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
        }
    }
    
    private func createTables() {
        let createChatThreadTable = """
        CREATE TABLE IF NOT EXISTS chat_thread (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL
        );
        """
        
        let createChatMessageTable = """
        CREATE TABLE IF NOT EXISTS chat_message (
            thread_id INTEGER NOT NULL,
            id INTEGER NOT NULL,
            seq INTEGER NOT NULL,
            type TEXT NOT NULL,
            message TEXT NOT NULL,
            create_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (thread_id, id, seq),
            FOREIGN KEY (thread_id) REFERENCES chat_thread(id)
        );
        """
        
        let createSettingsTable = """
        CREATE TABLE IF NOT EXISTS settings (
            key TEXT PRIMARY KEY NOT NULL,
            value TEXT
        );
        """
        
        executeQuery(createChatThreadTable)
        executeQuery(createChatMessageTable)
        executeQuery(createSettingsTable)
        addSetting(key: "default_model", value: "gpt-4")
        addSetting(key: "theme", value: "dark")
    }
    
    private func executeQuery(_ query: String) {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) != SQLITE_DONE {
                let errorCode = sqlite3_errcode(db)
                if errorCode != SQLITE_OK && errorCode != SQLITE_DONE && errorCode != SQLITE_CONSTRAINT {
                    print("Error executing query [\(query)]: \(String(cString: sqlite3_errmsg(db)))")
                }
            }
        } else {
            print("Error preparing query [\(query)]: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
    }
    
    private func dateFromString(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    private func stringFromDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    func addChatThread(name: String) -> Int? {
        let query = "INSERT INTO chat_thread (name) VALUES (?);"
        var statement: OpaquePointer?
        var threadId: Int?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (name as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                threadId = Int(sqlite3_last_insert_rowid(db))
            } else {
                print("Error adding chat thread: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing add chat thread: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return threadId
    }

    func getChatThreads() -> [ChatThread] {
        var threads: [ChatThread] = []
        let query = "SELECT id, name FROM chat_thread ORDER BY id DESC;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let name = String(cString: sqlite3_column_text(statement, 1))
                threads.append(ChatThread(id: id, name: name))
            }
        } else {
            print("Error getting chat threads: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return threads
    }
    
    func deleteChatThread(id: Int) {
        let deleteMessagesQuery = "DELETE FROM chat_message WHERE thread_id = ?;"
        var deleteMessagesStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteMessagesQuery, -1, &deleteMessagesStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteMessagesStatement, 1, Int32(id))
            if sqlite3_step(deleteMessagesStatement) != SQLITE_DONE {
                print("Error deleting messages for thread \(id): \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing delete messages for thread \(id): \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(deleteMessagesStatement)

        let deleteThreadQuery = "DELETE FROM chat_thread WHERE id = ?;"
        var deleteThreadStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteThreadQuery, -1, &deleteThreadStatement, nil) == SQLITE_OK {
            sqlite3_bind_int(deleteThreadStatement, 1, Int32(id))
            if sqlite3_step(deleteThreadStatement) != SQLITE_DONE {
                print("Error deleting thread \(id): \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing delete thread \(id): \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(deleteThreadStatement)
    }

    func addChatMessage(threadId: Int, id: Int, seq: Int, type: String, message: String, createAt: Date) -> Bool {
        let query = "INSERT INTO chat_message (thread_id, id, seq, type, message, create_at) VALUES (?, ?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        var success = false

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(threadId))
            sqlite3_bind_int(statement, 2, Int32(id))
            sqlite3_bind_int(statement, 3, Int32(seq))
            sqlite3_bind_text(statement, 4, (type as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 5, (message as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 6, (stringFromDate(createAt) as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_DONE {
                success = true
            } else {
                print("Error adding chat message: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing add chat message: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return success
    }
    
    func getNextMessageId(threadId: Int) -> Int {
        let query = "SELECT MAX(id) FROM chat_message WHERE thread_id = ?;"
        var statement: OpaquePointer?
        var maxId = 0
        
        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(threadId))
            if sqlite3_step(statement) == SQLITE_ROW {
                if sqlite3_column_type(statement, 0) != SQLITE_NULL {
                    maxId = Int(sqlite3_column_int(statement, 0))
                }
            }
        } else {
            print("Error getting max message id for thread \(threadId): \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return maxId + 1
    }

    func getChatMessages(threadId: Int) -> [ChatMessage] {
        var messages: [ChatMessage] = []
        let query = "SELECT id, seq, type, message, create_at FROM chat_message WHERE thread_id = ? ORDER BY id, seq;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_int(statement, 1, Int32(threadId))

            while sqlite3_step(statement) == SQLITE_ROW {
                let id = Int(sqlite3_column_int(statement, 0))
                let seq = Int(sqlite3_column_int(statement, 1))
                let type = String(cString: sqlite3_column_text(statement, 2))
                let message = String(cString: sqlite3_column_text(statement, 3))
                let createAtString = String(cString: sqlite3_column_text(statement, 4))
                let createAt = dateFromString(createAtString) ?? Date()

                messages.append(ChatMessage(id: id, threadId: threadId, seq: seq, type: type, message: message, createAt: createAt))
            }
        } else {
            print("Error getting chat messages for thread \(threadId): \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return messages
    }

    func addSetting(key: String, value: String) {
        let query = "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?);"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (value as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) != SQLITE_DONE {
                print("Error adding/updating setting [\(key)]: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing add/update setting [\(key)]: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
    }

    func getSetting(key: String) -> String? {
        let query = "SELECT value FROM settings WHERE key = ?;"
        var statement: OpaquePointer?
        var value: String?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (key as NSString).utf8String, -1, nil)

            if sqlite3_step(statement) == SQLITE_ROW {
                if sqlite3_column_type(statement, 0) != SQLITE_NULL {
                    value = String(cString: sqlite3_column_text(statement, 0))
                }
            }
        } else {
            print("Error getting setting [\(key)]: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return value
    }

    func getAllSettings() -> [Setting] {
        var settings: [Setting] = []
        let query = "SELECT key, value FROM settings;"
        var statement: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                let key = String(cString: sqlite3_column_text(statement, 0))
                let value = sqlite3_column_type(statement, 1) != SQLITE_NULL ? String(cString: sqlite3_column_text(statement, 1)) : ""
                settings.append(Setting(key: key, value: value))
            }
        } else {
            print("Error getting all settings: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(statement)
        return settings
    }

    deinit {
        sqlite3_close(db)
    }
}
