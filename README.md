# grocery-budget-planner
# 🛒 Grocery Budget Planner

**Grocery Budget Planner** is the main project developed as part of the BCA final year. It is a full-featured budgeting tool built with **Flutter** and powered by **Firebase**, designed to help users manage their grocery expenses efficiently. The app includes budgeting, tracking, pantry management, shared budget features, AI-driven suggestions, price comparison, and gamification to encourage better savings.

---

## 📌 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Setup & Installation](#setup--installation)
- [Future Enhancements](#future-enhancements)
- [Developer](#developer)

---

## ✨ Features

### 🔐 User Authentication
- New users can **sign up**, existing users can **log in**
- Authentication handled via **Firebase Authentication**

### 👤 User Profile
- View and edit profile details
- Upload profile image

### 💰 Budget Management
- Set a **monthly budget**
- Displays **spent**, **remaining**, and **total budget** per month

### 📉 Expense Tracking
- Log daily or itemized grocery expenses
- Displays list of monthly expenses
- Filter expenses by month
- Delete expenses individually or in bulk
- Download expense report by date

### 🍱 Pantry Management
- Track available pantry items
- Receive **expiry notifications** for food items

### 📝 Shopping List
- Add grocery shopping items to a checklist
- **Mark as bought**, delete, or update items

### 🍽️ Meal Plan Integration
- Basic dynamic meal suggestions currently available
- Future integration with **AI-based meal planning APIs** planned

### 🕹️ Gamification
- Earn **10 points** each month by staying within budget
- Monthly savings streaks unlock hidden **puzzle pieces**
- Get motivational messages, tips, and earn achievement titles

### 🤖 AI Suggestions (Gemini API)
- Integrates **Gemini’s API** to provide personalized tips
- Budget-saving suggestions based on each user’s budget and spending patterns

### 📊 Budget Insight
- Visual representation of:
  - Monthly budget vs. actual spending
  - Remaining budget per category

### 👥 Shared Budget
- Create or join shared budgets with **join codes**
- Collaborators can:
  - Contribute to a common budget
  - Track individual contributions
  - View shared spending history

### 💹 Price Comparison
- Integrated with **PriceAPI**
- Compares grocery prices across stores
- Helps users choose low-cost options before purchasing

---

## 🔧 Tech Stack

| Technology | Description |
|------------|-------------|
| **Flutter** | Frontend framework (Web-first, Mobile-ready) |
| **Firebase** | Backend: Authentication, Firestore, Storage |
| **Gemini API** | AI-powered budget tips |
| **PriceAPI** | Grocery price comparison |
| **Python (optional)** | Gemini/OpenAI proxy server if required |

---

## 🗂️ Project Structure

```
lib/
├── screens/
│   ├── home_screen.dart
│   ├── expense_tracking_screen.dart
│   ├── pantry_screen.dart
│   ├── shopping_list_screen.dart
│   ├── gamification_screen.dart
│   ├── profile_screen.dart
│   └── shared_budget_screen.dart
├── services/
│   ├── firebase_service.dart
│   ├── price_comparison_service.dart
│   └── ai_suggestions_service.dart
assets/
├── images/
└── screenshots/
backend/
└── app.py  # AI proxy server (optional)
```

---

## 🛠️ Setup & Installation

### 🧩 Prerequisites

- Flutter SDK (3.6.0 or above)
- Firebase CLI
- VS Code or Android Studio
- Optional: Python 3.x (for backend AI proxy)

### ⚙️ Installation Steps

1. **Clone the repo**:
```bash
git clone https://github.com/Sreelakshmi-NJ/grocery-budget-planner.git
cd grocery-budget-planner
```

2. **Install dependencies**:
```bash
flutter pub get
```

3. **Firebase setup**:
- Add your `google-services.json` and/or `firebase_options.dart`
- Enable Authentication and Firestore in Firebase Console

4. **Run the app on web**:
```bash
flutter run -d chrome
```

5. *(Optional)* AI proxy setup:
- Create `.env` inside `backend/`:
```env
GEMINI_API_KEY=your_api_key_here
```
- Run the Python backend if used:
```bash
python backend/app.py
```
---

## 🚀 Future Enhancements

- 📱 **Mobile App Release** using same Flutter codebase
- 🧠 **Advanced AI Features**:
  - AI chatbot assistant
  - Smarter budget forecasting
- 🧾 **Invoice Scanning** using OCR to auto-log expenses
- 📊 **Improved visualizations** using charts
- 🔍 **Smarter price comparison** with more APIs & filtering
- 🍽️ **Meal Plan AI**: dynamic meal recommendations based on pantry & budget
- 📡 **Push Notifications** for reminders and expiry alerts

---

## 👩‍💻 Developer

**Sreelakshmi N J**  
BCA Graduate | Aspiring Flutter Developer | Tech Enthusiast  
🔗 [LinkedIn](https://www.linkedin.com/in/sreelakshmi-n-j-016933330/)  

---

