# 💸 Payment Reminder

A Flutter app to track and remind you of upcoming bill payments and loans — all stored locally on your device using SQLite. No account or internet connection required.

---

## 📱 Screenshots

> _Add screenshots here after running the app._

---

## ✨ Features

### 🏠 Home Screen
- Displays **current month's upcoming bills** at a glance
- Summary card showing **total due**, **total paid**, and **remaining amount** with a progress bar
- **Overdue badge** on unpaid bills that have passed their due date
- **Mark bills as paid** with a single tap
- Navigate between months (past and upcoming)
- Active loans due this month are shown below the bills section

### 🧾 Bills
- Add recurring or one-time bills with a **category**, **amount**, and **due day of month**
- Categories: Electricity, Water, Internet, Rent, Phone, Insurance, Subscription, Other
- Bills are **grouped by category** for easy scanning
- **Activate / Deactivate** bills without deleting them
- Edit or delete bills at any time
- Stats row showing active bill count and monthly total

### 🏦 Loans
- Track temporary loans with a **start date**, **end date**, and **monthly payment**
- Record the **lender name** and optional **interest rate**
- Visual **progress bar** showing paid vs. remaining months
- **Active** and **Completed** loan tabs
- Mark each month as paid to update progress
- Warning badge for loans **expiring within 30 days**
- Summary card with total remaining amount and monthly due total

---

## 🗄️ Data Storage

All data is stored **locally on the device** using [sqflite](https://pub.dev/packages/sqflite) (SQLite).

| Table | Purpose |
|---|---|
| `payments` | Stores all bill definitions (title, amount, due day, category) |
| `payment_status` | Tracks paid/unpaid status per bill per month |
| `loans` | Stores loan records with dates, amounts, and paid months count |

No data is sent to any server.

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart 3.7+) |
| Database | SQLite via `sqflite ^2.4.1` |
| Date formatting | `intl ^0.19.0` |
| Path resolution | `path ^1.9.0` |
| Theme | Material 3 — Dark |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.7.2`
- Android Studio / Xcode (for emulator or device)
- Java 17+ (required for Gradle 8.6)

### Run the app

```bash
# Clone the repository
git clone https://github.com/your-username/payment-reminder.git
cd payment-reminder

# Get dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

### Build a release APK

```bash
flutter build apk --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                   # App entry point + dark theme configuration
├── models/
│   ├── payment.dart            # Payment model, BillCategory enum, MonthlyPaymentStatus
│   └── loan.dart               # Loan model with progress & status helpers
├── database/
│   └── database_helper.dart    # SQLite singleton — all CRUD operations
├── screens/
│   ├── home_screen.dart        # Home tab with monthly overview
│   ├── bills_screen.dart       # Bills list grouped by category
│   ├── loans_screen.dart       # Loans with Active / Completed tabs
│   ├── add_bill_screen.dart    # Add & Edit bill form
│   └── add_loan_screen.dart    # Add & Edit loan form
└── widgets/
    ├── payment_card.dart       # Bill card (home view + list view variants)
    └── loan_card.dart          # Loan card with progress bar and amount chips
```

---

## 🎨 Theme

The app uses a **Material 3 dark theme** with the following colour palette:

| Role | Colour |
|---|---|
| Background | `#121212` |
| Surface | `#1E1E1E` |
| Card | `#2C2C2C` |
| Primary (purple) | `#BB86FC` |
| Secondary (teal) | `#03DAC6` |
| Error (pink) | `#CF6679` |

---

## 🔧 Android Build Notes

This project requires the following Android setup:

| Setting | Value |
|---|---|
| Gradle | 8.6 |
| Android Gradle Plugin | 8.3.0 |
| Kotlin | 1.9.22 |
| Java | 17 |
| `coreLibraryDesugaring` | Enabled |
| Min SDK | Flutter default |
| Compile SDK | Flutter default |

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE).
