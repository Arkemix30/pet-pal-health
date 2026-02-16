# Pet Pal Health 🐾

A premium, local-first mobile application for managing your pet's health and wellness. Built with Flutter and Supabase, Pet Pal Health ensures your pet's data is always with you, even when offline.

## Overview

Pet Pal Health consolidates all pet health data into a single source of truth and proactively reminds users until actions are confirmed. It prevents missed health actions (vaccines, medications, deworming, vet appointments) that can harm or endanger pets, reducing mental load for pet owners.

---

## ✨ Features Implemented

### Core Features

| Feature | Status | Description |
|---------|--------|-------------|
| **Local-First Architecture** | ✅ | All data stored locally using **Isar** (NoSQL) for offline-first capabilities |
| **Real-time Sync** | ✅ | Bi-directional sync with **Supabase** backend |
| **Authentication** | ✅ | Email/password sign-in, sign-up, password recovery, Google OAuth |
| **Pet Management** | ✅ | Full CRUD for pet profiles (name, species, breed, age, weight, photo) |
| **Health Schedules** | ✅ | Create schedules for vaccines, medications, deworming, vet appointments |
| **Recurring Schedules** | ✅ | One-time, daily, weekly, monthly frequency options |
| **Reminder System** | ✅ | Push notifications via `flutter_local_notifications` with persistent reminders |
| **Health History** | ✅ | Chronological timeline of completed health actions |
| **Family Sharing** | ✅ | Invite family/caretakers by email with shared pet access |
| **Premium UI** | ✅ | Forest Green theme (`0xFF2D6A4F`) with smooth animations |

---

## 🏗 Architecture

### Clean Architecture Layers

```
lib/
├── core/                    # Cross-cutting concerns
│   ├── constants/           # App constants
│   ├── theme/               # Forest Green theme
│   ├── services/            # Notification, Storage services
│   └── providers/           # Global Riverpod providers
├── data/                    # Data Layer
│   ├── local/              # Isar schemas & repositories
│   └── models/             # DTOs and mappings
├── domain/                  # Business Layer (Entities, Interfaces)
├── features/                # Feature modules
│   ├── auth/               # Authentication (sign-in, sign-up, OAuth)
│   ├── pet_management/     # Pet CRUD, dashboard, profiles
│   ├── health_schedules/   # Schedules, reminders, timeline
│   ├── timeline/           # Health history tracking
│   └── sharing/            # Family sharing & invitations
└── presentation/            # UI Layer
    ├── common_widgets/      # Reusable UI components
    └── routing/            # go_router navigation
```

### Data Models (Isar Collections)

- **Profile**: User profile with Supabase ID, full name, avatar
- **Pet**: Pet entity with name, species, breed, birth date, weight, photo
- **HealthSchedule**: Health events with title, type (vaccine/medication/deworming/appointment), start date, frequency, completion status

---

## 🔔 Use Cases

### Authentication
- Email/password sign-in and sign-up
- Password recovery via email
- Google OAuth integration
- Session persistence with Supabase

### Pet Management
- Create, read, update, delete pet profiles
- Support for multiple pets per account
- Pet dashboard with health overview

### Health Scheduling
- Create health schedules (vaccines, meds, deworming, appointments)
- Set recurring schedules (one-time, daily, weekly, monthly)
- Mark schedules as completed
- View schedule history

### Notifications
- Schedule local push notifications
- Timezone-aware scheduling
- Cancel individual or all notifications
- Persistent reminders until confirmed

### Sharing
- Invite family members by email
- Manage shared access to pet profiles
- Revoke sharing permissions

---

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| **Framework** | Flutter 3.x |
| **State Management** | `flutter_riverpod` + `riverpod_generator` |
| **Local Database** | `isar` (NoSQL, offline-first) |
| **Backend** | `supabase_flutter` (Auth, Database, Storage) |
| **Notifications** | `flutter_local_notifications` |
| **Routing** | `go_router` |
| **Timezones** | `timezone` + `flutter_timezone` |

---

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

3. **Run Code Generation**
   Generate Isar and Riverpod code:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

---

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

---

## 🧪 Key Commands

| Action | Command |
|--------|---------|
| **Install Deps** | `flutter pub get` |
| **Gen Code** | `flutter pub run build_runner build --delete-conflicting-outputs` |
| **Watch Code** | `flutter pub run build_runner watch --delete-conflicting-outputs` |
| **Lint Check** | `flutter analyze` |
| **Run Tests** | `flutter test` |
| **Build APK** | `flutter build apk --release` |

---

## ✅ Implementation Status

All phases from `docs/PLAN-petcare-flutter.md` are **complete**:

| Phase | Tasks | Status |
|-------|-------|--------|
| **Phase 1: Foundation** | Supabase Setup, Flutter Scaffold, Isar Setup | ✅ Done |
| **Phase 2: Core Components** | Authentication, Pet Management, Local-First Sync | ✅ Done |
| **Phase 3: Reminders** | Health Schedule Logic, Notification System | ✅ Done |
| **Phase 4: Sharing & History** | Family Sharing, Health History & Export, Premium UI, Bi-directional Sync | ✅ Done |

---

## 📝 Conventions

- **Commits**: Use [Conventional Commits](https://www.conventionalcommits.org/) (e.g., `feat:`, `fix:`, `chore:`, `docs:`).
- **Naming**: `lower_snake_case` for files/folders, `UpperCamelCase` for classes, `lowerCamelCase` for variables.
- **Clean Code**: Keep functions under 40 lines. Use descriptive names.

---

## ⚠️ Medical Disclaimer

This app does not replace professional veterinary care. Always consult a veterinarian for medical advice.

---

## ✅ Definition of Done

Before submitting any change, verify:
- [ ] `flutter analyze` returns no issues.
- [ ] Any required code generation (`build_runner`) was executed.
- [ ] Changes do not break existing features.
- [ ] Conventional Commit message used.
- [ ] `.env` was NOT accidentally committed.
- [ ] New UI adheres to the premium Forest Green theme.
