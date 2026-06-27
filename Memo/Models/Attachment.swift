//
//  Attachment.swift
//  Memo
//
//  Stores raw file data (images, PDFs) linked to a transaction.
//  Kept in SwiftData so attachments are always local and private —
//  no third-party storage required.
//

import Foundation
import SwiftData

@Model
final class Attachment: Identifiable {
    var id: UUID
    var fileData: Data
    var mimeType: String   // e.g. "image/jpeg", "application/pdf"
    var fileName: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.attachments)
    var transaction: Transaction?

    init(fileData: Data, mimeType: String, fileName: String) {
        self.id = UUID()
        self.fileData = fileData
        self.mimeType = mimeType
        self.fileName = fileName
        self.createdAt = Date()
    }
}
