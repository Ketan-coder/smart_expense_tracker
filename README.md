# 💸 SmartSpend – Intelligent Expense Tracker

**SmartSpend** is a privacy-first Flutter mobile app that automatically tracks your income and expenses by reading transaction SMS messages. No manual entry needed—just let the app work in the background while you focus on your spending.

> ⚠️ **Alpha Release**: This is an early preview. Expect bugs and incomplete features. Your feedback is invaluable!

---

## ✨ What Does It Do?

SmartSpend monitors your SMS inbox for transaction notifications (like UPI payments, bank alerts, etc.), automatically extracts the important details, and logs them for you. Everything stays **100% on your device**—no cloud uploads, no data sharing.

### Key Features

- 📱 **Automatic SMS Parsing** – Detects and logs transactions from SMS without manual input
- 🏷️ **Smart Categorization** – Classifies payments by type (UPI, Cash, Card) and spending category
- 🔄 **Recurring Payments** – Identifies and tracks repeated transactions (subscriptions, bills)
- 📊 **Visual Analytics** – Charts and dashboards to understand your spending patterns
- 🔒 **Privacy-First** – All data stored locally on your device using Hive database
- 👍 **One-Handed UI** – Designed for easy, thumb-friendly navigation

---

## 🎯 Why SmartSpend?

- **Zero Manual Entry**: Forget about typing in every expense
- **Complete Privacy**: Your financial data never leaves your phone
- **Works Offline**: No internet required after installation
- **Free & Open Source**: Community-driven development

---

## 📱 Requirements

- **Platform**: Android (iOS support planned)
- **Permissions Required**: SMS read access (to parse transaction messages)
- **Flutter Version**: 3.0+ recommended
- **Dart SDK**: 3.0+

---

## 🚀 Getting Started

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/<your-username>/smartspend.git
   cd smartspend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### First Launch Setup

1. Grant SMS read permission when prompted
2. The app will scan existing transaction messages
3. Review and confirm categorizations
4. Start tracking automatically!

---

## 🏗️ How It Works

```
📩 SMS Received → 🔍 Parse Transaction → 🏷️ Categorize → 💾 Store in Hive → 📊 Display Analytics
```

1. **SMS Listener**: Monitors incoming messages for transaction keywords
2. **Parser**: Extracts amount, merchant, date, and payment method
3. **Categorizer**: Assigns category (Food, Transport, Shopping, etc.)
4. **Storage**: Saves to local Hive database
5. **Analytics**: Generates insights, charts, and spending summaries
6. **Manual Override**: Edit or add transactions anytime

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter |
| Language | Dart |
| Database | Hive (local NoSQL) |
| State Management | Provider *(planned)* |
| Charts | *[Add your chart library]* |

---

## 🐛 Known Issues (Alpha)

- [ ] SMS parsing accuracy needs improvement for some bank formats
- [ ] Limited category customization
- [ ] No data export feature yet
- [ ] Analytics limited to basic views
- [ ] Provider state management not yet implemented

See [Issues](https://github.com/<your-username>/smartspend/issues) for the full list.

---

## 🗺️ Roadmap

- [ ] Enhanced SMS parsing with ML-based detection
- [ ] Custom categories and tags
- [ ] Budget setting and alerts
- [ ] Data export (CSV, JSON)
- [ ] Multi-account support
- [ ] iOS version
- [ ] Optional cloud backup (encrypted)

---

## 🤝 Contributing

We welcome contributions! Whether you're fixing bugs, adding features, or improving documentation, your help is appreciated.

### How to Contribute

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas We Need Help

- Improving SMS parsing accuracy across different banks
- UI/UX design improvements
- Testing on various Android devices
- Documentation and tutorials

---

## 📄 License

[Add your license here - e.g., MIT, Apache 2.0, GPL]

---

## 📧 Contact

**Developer**: Ketan  
💼 LinkedIn: [Add your LinkedIn]  
📧 Email: ketanv288@gmail.com
🐛 Issues: [GitHub Issues](https://github.com/<your-username>/smartspend/issues)

---

## 🙏 Acknowledgments

Thanks to all alpha testers and contributors who help make SmartSpend better!

---

**⭐ If you find SmartSpend useful, please star this repo!**