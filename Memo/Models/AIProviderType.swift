//
//  AIProviderType.swift
//  Memo
//
//  Enum representing the available AI providers in the app.
//

import Foundation

enum AIProviderType: String, CaseIterable, Identifiable, Codable {
    case appleFoundation
    case externalAPI
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .appleFoundation:
            return "Apple Foundation Models"
        case .externalAPI:
            return "OpenAI Compatible API"
        }
    }
    
    var description: String {
        switch self {
        case .appleFoundation:
            return "Runs completely on your iPhone using Apple Intelligence.\nNo data leaves your device."
        case .externalAPI:
            return "Use any compatible external provider."
        }
    }
    
    var activeBannerText: String {
        switch self {
        case .appleFoundation:
            return "Using Apple Foundation Models"
        case .externalAPI:
            return "Using External API"
        }
    }
    
    var activeBannerSubtext: String {
        switch self {
        case .appleFoundation:
            return "Runs entirely on-device."
        case .externalAPI:
            return "Requests are sent to your configured endpoint."
        }
    }
    
    var statusLabel: String {
        switch self {
        case .appleFoundation:
            return "Running on-device"
        case .externalAPI:
            return "Using External AI"
        }
    }
}
