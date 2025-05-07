//
//  Setting.swift
//  Chapro
//
//  Created by そらだい on 2025/04/28.
//

import Foundation

struct Setting: Identifiable, Codable {
    var id: String { key }
    var key: String
    var value: String
}
