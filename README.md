# Pet Pal Health 🐾

A premium, local-first mobile application for managing your pet's health and wellness. Built with Flutter and Supabase, Pet Pal Health ensures your pet's data is always with you, even when offline.

## ✨ Features

- **Local-First Architecture**: All data is stored locally using **Isar**, providing lightning-fast performance and offline-first capabilities.
- **Real-time Sync**: Seamless synchronization with **Supabase** in the background.
- **Premium UI**: A beautiful, modern interface with a "Forest Green" color palette and smooth animations.
- **Pet Management**: Add, view, and manage detailed profiles for your pets.
- **Authentication**: Secure sign-in with email/password and Google.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (stable)
- Dart SDK
- Supabase Account (URL/Key configured in `.env`)

### Setup

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Environment Setup**
   Ensure you have a `.env` file in the root directory with your Supabase credentials:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

4. **Code Generation**
   Run the build runner to generate necessary code for Isar and Riverpod:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

## 📁 Project Structure

```text
lib/
├── core/             # Cross-cutting concerns (Constants, Theme, Utils)
├── data/             # Data Layer (Local Isar, Remote Supabase, DTOs)
├── domain/           # Business Layer (Entities and Interfaces)
├── features/         # Logic by feature (Auth, PetMgmt, Schedules)
└── presentation/     # UI Layer (Routing, Common Widgets)
assets/               # Images and Lottie animations
docs/                 # PRD, Architecture, and Plans
```

## 🛠 Key Commands

| Action | Command |
|--------|---------|
| **Install Deps** | `flutter pub get` |
| **Gen Code** | `flutter pub run build_runner build --delete-conflicting-outputs` |
| **Watch Code** | `flutter pub run build_runner watch --delete-conflicting-outputs` |
| **Lint Check** | `flutter analyze` |
| **Run Tests** | `flutter test` |
| **Build APK** | `flutter build apk --release` |

## 📝 Conventions

- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat:`, `fix:`, `chore:`, `docs:`).
- **Naming**: `lower_snake_case` for files/folders, `UpperCamelCase` for classes, `lowerCamelCase` for variables.
- **Clean Code**: Keep functions under 40 lines. Use descriptive names.

## ✅ Definition of Done

Before submitting any change, verify:
- [ ] `flutter analyze` returns no issues.
- [ ] Any required code generation (`build_runner`) was executed.
- [ ] Changes do not break existing features.
- [ ] Conventional Commit message used.
- [ ] `.env` was NOT accidentally committed.
- [ ] New UI adheres to the premium Forest Green theme.
