import re

# Fix CurrencyTextField.swift
with open("Memo/Components/CurrencyTextField.swift", "r") as f:
    content = f.read()

content = content.replace(
    "textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)",
    """textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)"""
)

with open("Memo/Components/CurrencyTextField.swift", "w") as f:
    f.write(content)

# Fix AccountDetailView.swift
with open("Memo/Features/Accounts/AccountDetailView.swift", "r") as f:
    content = f.read()

content = content.replace(
    ".frame(maxWidth: .infinity, minHeight: 32)",
    ".frame(maxWidth: .infinity, minHeight: 32)\n                        .fixedSize(horizontal: false, vertical: true)"
)

with open("Memo/Features/Accounts/AccountDetailView.swift", "w") as f:
    f.write(content)

# Fix TransferView.swift
with open("Memo/Features/Accounts/TransferView.swift", "r") as f:
    content = f.read()

content = content.replace(
    ".frame(maxWidth: .infinity, minHeight: 32)",
    ".frame(maxWidth: .infinity, minHeight: 32)\n                            .fixedSize(horizontal: false, vertical: true)"
)

with open("Memo/Features/Accounts/TransferView.swift", "w") as f:
    f.write(content)
