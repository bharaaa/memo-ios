import json
import sys

def update_xcstrings(filepath, keys):
    with open(filepath, 'r') as f:
        data = json.load(f)
    
    strings = data.get("strings", {})
    
    for key, en_val, id_val in keys:
        if key not in strings:
            strings[key] = {
                "extractionState": "manual",
                "localizations": {}
            }
        strings[key]["localizations"]["en"] = {
            "stringUnit": {
                "state": "translated",
                "value": en_val
            }
        }
        strings[key]["localizations"]["id"] = {
            "stringUnit": {
                "state": "translated",
                "value": id_val
            }
        }
        
    data["strings"] = strings
    
    with open(filepath, 'w') as f:
        json.dump(data, f, indent=2)

keys_to_add = [
    ("accounts", "Accounts", "Akun"),
    ("categories", "Categories", "Kategori"),
    ("add_account", "Add Account", "Tambah Akun"),
    ("import", "Import", "Impor"),
    ("export", "Export", "Ekspor"),
    ("balance", "Balance", "Saldo"),
    ("income", "Income", "Pemasukan"),
    ("expense", "Expense", "Pengeluaran"),
    ("transfer", "Transfer", "Transfer"),
    ("preferences", "Preferences", "Preferensi"),
    ("appearance", "Appearance", "Tampilan"),
    ("currency", "Currency", "Mata Uang"),
    ("notifications", "Notifications", "Notifikasi")
]

update_xcstrings("Memo/Localization/Localizable.xcstrings", keys_to_add)
print("Updated Localizable.xcstrings")
