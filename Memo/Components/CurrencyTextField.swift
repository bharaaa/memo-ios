//
//  CurrencyTextField.swift
//  Memo
//

import SwiftUI
import UIKit

struct CurrencyTextField: UIViewRepresentable {
    var placeholder: String
    @Binding var text: String
    var font: UIFont = UIFont.preferredFont(forTextStyle: .body)
    var textColor: UIColor = UIColor.label
    var textAlignment: NSTextAlignment = .right
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = .decimalPad
        textField.textAlignment = textAlignment
        textField.delegate = context.coordinator
        
        textField.font = font
        textField.textColor = textColor
        
        // Add a toolbar with a "Done" button to dismiss keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        // Initial text
        textField.text = formatCurrency(text)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        let formatted = formatCurrency(text)
        if uiView.text != formatted {
            uiView.text = formatted
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func formatCurrency(_ value: String) -> String {
        let numericString = value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard let number = Int(numericString) else { return value }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        
        return formatter.string(from: NSNumber(value: number)) ?? value
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyTextField
        
        init(_ parent: CurrencyTextField) {
            self.parent = parent
        }
        
        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            guard let currentText = textField.text as NSString? else { return true }
            
            let updatedText = currentText.replacingCharacters(in: range, with: string)
            let numericString = updatedText.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            
            if numericString.isEmpty {
                textField.text = ""
                parent.text = ""
                return false
            }
            
            guard let number = Int(numericString) else { return false }
            
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.groupingSeparator = "."
            formatter.decimalSeparator = ","
            
            if let formatted = formatter.string(from: NSNumber(value: number)) {
                textField.text = formatted
                parent.text = formatted
            }
            
            return false
        }
    }
}
