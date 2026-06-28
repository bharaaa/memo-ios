//
//  L10n.swift
//  Memo
//
//  Strongly typed localization keys.
//  Use these instead of string literals to avoid typos and ensure
//  all strings are translated.
//

import SwiftUI

struct L10n {
    
    // MARK: - General
    static let save = LocalizedStringKey("save")
    static let cancel = LocalizedStringKey("cancel")
    static let edit = LocalizedStringKey("edit")
    static let delete = LocalizedStringKey("delete")
    static let done = LocalizedStringKey("done")
    static let search = LocalizedStringKey("search")
    static let importKey = LocalizedStringKey("import")
    static let exportKey = LocalizedStringKey("export")
    
    // MARK: - Finance
    static let balance = LocalizedStringKey("balance")
    static let income = LocalizedStringKey("income")
    static let expense = LocalizedStringKey("expense")
    static let transfer = LocalizedStringKey("transfer")
    
    // MARK: - Sections
    static let accounts = LocalizedStringKey("accounts")
    static let categories = LocalizedStringKey("categories")
    static let addAccount = LocalizedStringKey("add_account")
    
    // MARK: - Tabs
    static let tabHome = LocalizedStringKey("tab_home")
    static let tabMemories = LocalizedStringKey("tab_memories")
    static let tabSettings = LocalizedStringKey("tab_settings")
    
    // MARK: - Settings
    static let preferences = LocalizedStringKey("preferences")
    static let appearance = LocalizedStringKey("appearance")
    static let currency = LocalizedStringKey("currency")
    static let notifications = LocalizedStringKey("notifications")
    static let language = LocalizedStringKey("language")
    static let languageSelection = LocalizedStringKey("language_selection")
    static let systemLanguageDescription = LocalizedStringKey("system_language_description")
}
