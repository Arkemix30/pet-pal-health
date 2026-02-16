# 🤖 AGENTS.md - Operational Guide

This document is the primary source of truth for AI agents and human contributors to understand, operate, and maintain the **Pet Pal Health** repository.

---

## 🎯 Purpose
Pet Pal Health is a mobile-first Flutter application (Local-First) designed to track pet health (vaccines, meds, schedules). It uses **Isar** for local storage and **Supabase** for real-time cloud synchronization.

---

## 🚀 Quick Start
### Prerequisites
- Flutter SDK (stable)
- Dart SDK
- Supabase Account (URL/Key configured in `.env`)

### Setup Environment
```bash
# Install dependencies
flutter pub get

# Setup environment variables
# Ensure .env exists with SUPABASE_URL and SUPABASE_ANON_KEY
```

### Run Locally
```bash
# Run the app
flutter run

# Run code generation (Isar/Riverpod)
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 🛠 Key Commands
| Action | Command |
|--------|---------|
| **Install Deps** | `flutter pub get` |
| **Gen Code** | `flutter pub run build_runner build --delete-conflicting-outputs` |
| **Watch Code** | `flutter pub run build_runner watch --delete-conflicting-outputs` |
| **Lint Check** | `flutter analyze` |
| **Run All Tests** | `flutter test` |
| **Run Single Test** | `flutter test test/path/to/file_test.dart` |
| **Run Tests Matching** | `flutter test --name "test_name_pattern"` |
| **Build APK** | `flutter build apk --release` |
| **Build iOS** | `flutter build ios --release` |

---

## 📁 Folder Structure
```text
lib/
├── core/                  # Cross-cutting concerns (Constants, Theme, Utils)
│   ├── theme/             # App theming (app_theme.dart)
│   └── services/          # Global services (notifications, storage)
├── data/                  # Data Layer
│   ├── local/             # Isar models and database service
│   └── remote/            # Supabase client setup
├── domain/                # Business Layer (Entities and Interfaces)
├── features/              # Logic by feature (Auth, PetMgmt, Schedules)
│   ├── auth/              # Authentication (providers, screens, services)
│   ├── pet_management/    # Pet CRUD (dashboard, form, repository, provider)
│   ├── health_schedules/  # Schedules (add, details, repository, provider)
│   ├── timeline/          # Activity timeline
│   └── sharing/           # Pet sharing features
├── presentation/          # UI Layer (Routing, Common Widgets)
test/                      # Test files (mirrors lib/ structure)
  └── features/
      └── auth/
          └── auth_provider_test.dart
assets/                    # Images and Lottie animations
docs/                      # PRD, Architecture, and Plans
```

---

## 🎨 Code Style Guidelines

### Imports
- **Order**: Flutter SDK → External packages → Internal packages (relative paths)
- **Grouping**: Separate with blank lines between groups
- **Relative vs Absolute**: Use relative imports for same-package files (`../core/...`), package imports for external

```dart
// Correct import order
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../data/local/isar_models.dart';
import '../../core/services/storage_service.dart';
```

### Naming Conventions
| Type | Convention | Example |
|------|------------|---------|
| Files/Folders | `lower_snake_case` | `pet_repository.dart`, `auth_provider.dart` |
| Classes | `UpperCamelCase` | `PetRepository`, `AuthNotifier` |
| Functions/Variables | `lowerCamelCase` | `savePet()`, `currentIndex` |
| Constants | `lowerCamelCase` (k prefix optional) | `maxRetries`, `kDefaultTimeout` |
| Private Members | `_prefix` | `_isar`, `_syncPetToRemote()` |
| Providers | `Provider/Suffix` | `petRepositoryProvider`, `authStateProvider` |

### Type Annotations
- **Always** use explicit return types for public functions
- Use `late` for late-initialized fields
- Prefer `final` over `var`
- Use `String?` for nullable types, not `String|Null`

```dart
// Good
final User? user = ref.watch(userProvider);
Future<void> savePet(Pet pet) async { ... }

// Avoid
var user = ref.watch(userProvider);
Future savePet(pet) async { ... }
```

### Error Handling
- Use try-catch blocks for async operations that can fail
- Log errors using the `logger` package
- Provide fallback UI for error states in async providers

```dart
try {
  await _isar.writeTxn(() async {
    await _isar.pets.put(pet);
  });
} catch (e) {
  logger.e('Failed to save pet: $e');
}
```

### UI Patterns
- Use `const` constructors wherever possible
- Prefer `ConsumerWidget`/`ConsumerStatefulWidget` for Riverpod integration
- Use `withValues(alpha: x)` instead of `withOpacity(x)` (modern Flutter)
- Follow Material Design 3 with Forest Green theme

```dart
// Good
class PetDashboardScreen extends ConsumerWidget {
  const PetDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

---

## ☢️ Rules & Restrictions

1. **Never edit `*.g.dart` files**: These are generated by `build_runner`. Modify the source model or provider instead.
2. **Environment Security**: Never commit `.env` or hardcode API keys. Use `dotenv.env['KEY']`.
3. **Database Consistency**: Isar schemas in `lib/data/local/isar_models.dart` must match the remote Supabase structure for sync to work.
4. **State Management**: Use **Riverpod**. Avoid `setState` for global state or complex logic.
5. **UI Colors**: Respect the **Forest Green** palette (`0xFF2D6A4F`). Do not use violet/purple unless explicitly requested.
6. **Generated Code**: Always run `build_runner` after modifying Isar models or Riverpod providers.
7. **Repository Pattern**: All data access should go through repositories (e.g., `PetRepository`, `ScheduleRepository`).

---

## 🧪 Testing & Quality

### Test Organization
- Place tests in `test/` mirroring the `lib/` structure
- Test files must end in `_test.dart`
- Use AAA pattern: **Arrange**, **Act**, **Assert**

### Test Commands
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/features/auth/auth_provider_test.dart

# Run tests matching name
flutter test --name "OnboardingNotifier"

# Run with coverage
flutter test --coverage
```

### Testing Best Practices
- Mock external dependencies (Isar, Supabase) using mocktail
- Test providers by overriding with mock implementations
- Group related tests using `group()` from flutter_test

---

## 📝 Conventions

### Commit Messages
Use [Conventional Commits](https://www.conventionalcommits.org/):
- `feat:` - New feature
- `fix:` - Bug fix
- `chore:` - Maintenance tasks
- `docs:` - Documentation
- `refactor:` - Code restructuring
- `style:` - Formatting changes

### Clean Code
- Keep functions under **40 lines**
- Use descriptive names
- Extract复用 logic into separate methods
- Avoid magic numbers; use constants

### Async Patterns
- Use `AsyncNotifier` for async Riverpod providers
- Return `AsyncValue<T>` for async state
- Handle loading/error/data states explicitly

---

## ✅ Definition of Done (Checklist)

Before submitting any change, verify:
- [ ] `flutter analyze` returns no issues
- [ ] Any required code generation (`build_runner`) was executed
- [ ] Changes do not break existing features
- [ ] Conventional Commit message used
- [ ] `.env` was NOT accidentally committed
- [ ] New UI adheres to the premium Forest Green theme
- [ ] Tests pass: `flutter test`

---

## 🔧 Tech Stack

| Category | Technology |
|----------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod + Riverpod Generator |
| Local Database | Isar |
| Remote Backend | Supabase |
| Notifications | flutter_local_notifications |
| Routing | go_router |
| Theming | flex_color_scheme + google_fonts |
| Logging | logger |
| Animations | flutter_animate + lottie |

---

## 📚 Additional Resources

- [Isar Documentation](https://isar.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Flutter SDK](https://supabase.com/docs/guides/getting-started/quick-start/flutter)
- [Flutter Material 3](https://m3.material.io/)
