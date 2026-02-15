# Plan: PetCare Brain (Flutter Implementation)

## Overview
PetCare Brain is a mobile-first application designed to help pet owners track and manage their pets' health needs. This plan details the implementation of the MVP using Flutter, following a local-first architecture with Supabase for real-time synchronization and cloud backup.

**Project Type:** MOBILE (Flutter)

---

## Technical Stack
- **Framework:** Flutter (version 3.x)
- **State Management:** `flutter_riverpod` + `riverpod_generator`
- **Local Database:** `isar` (NoSQL, high performance, offline-first)
- **Backend:** `supabase_flutter` (Auth, Real-time DB, Storage)
- **Notifications:** `flutter_local_notifications` (Immediate/Persistent) + `firebase_messaging` (Cloud Push)
- **Testing:** `flutter_test`, `patrol` (E2E/Integration)

---

## File Structure
```text
lib/
├── core/
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── providers/ (Global providers)
├── data/
│   ├── local/ (Isar schemas and repositories)
│   ├── remote/ (Supabase services)
│   └── models/ (DTOs and Mappings)
├── domain/ (Entities and interfaces)
├── features/
│   ├── auth/ (Login/Signup/Social)
│   ├── pet_management/ (CRUD profiles)
│   ├── health_schedules/ (Reminders logic)
│   ├── timeline/ (History tracking)
│   ├── sharing/ (Family invites)
│   └── vet_directory/ (Info listing)
└── presentation/
    ├── common_widgets/ (Atomic UI)
    └── routing/ (go_router)
```

---

## Task Breakdown

### Phase 1: Foundation (P0)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT→OUTPUT→VERIFY |
|---------|------|-------|--------|----------|--------------|----------------------|
| F-001 | Supabase Project Setup | `database-architect` | supabase, db-design | P0 | None | Requirements → Tables (pets, schedules, profiles) + RLS policies → Verify via Supabase Dashboard queries. |
| F-002 | Flutter Project Scaffold | `mobile-developer` | clean-code | P0 | None | `flutter create` → Project with folder structure + `pubspec.yaml` dependencies → `flutter pub get` success. |
| F-003 | Local Database (Isar) Setup | `mobile-developer` | database-design | P0 | F-002 | Isar schemas → Isar singleton + DB initialization logic → Test local write/read. |

### Phase 2: Core Components (P1)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT→OUTPUT→VERIFY |
|---------|------|-------|--------|----------|--------------|----------------------|
| C-001 | Authentication (Supabase) | `mobile-developer` | auth | P1 | F-001, F-002 | Supabase Auth integration (Email/Social) → Login/Signup screens → Successful session persistence on app restart. |
| C-002 | Pet Profile Management | `mobile-developer` | mobile-design | P1 | F-003 | CRUD Logic (Riverpod) → Create/Edit screens → Verify data reflects in Isar and syncs to Supabase. |
| C-003 | Local-First Sync Engine | `database-architect` | performance | P1 | F-001, F-003 | Sync logic (Isar ↔ Supabase) → Background sync worker → Verify offline changes propagate when reconnecting. |

### Phase 3: Reminders & Notifications (P1)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT→OUTPUT→VERIFY |
|---------|------|-------|--------|----------|--------------|----------------------|
| R-001 | Health Schedule Logic | `mobile-developer` | clean-code | P1 | C-002 | Schedule models + Logic → Schedule creation form → Verify schedule objects persist in local DB. |
| R-002 | Notification System | `mobile-developer` | mobile-design | P1 | R-001 | `flutter_local_notifications` setup → Trigger notifications based on schedules → Verify notification appears on device/emulator. |

### Phase 4: Sharing & Polish (P2)
| Task ID | Name | Agent | Skills | Priority | Dependencies | INPUT→OUTPUT→VERIFY |
|---------|------|-------|--------|----------|--------------|----------------------|
| S-001 | Family Sharing | `database-architect` | supabase | P2 | F-001 | RLS logic for shared profiles → Invitation UI → Verify User B can see/edit Pet A updated by User A. |
| S-002 | Health History & Export | `mobile-developer` | mobile-design | P2 | R-001 | Timeline view + PDF Export (using `pdf` package) → History screen → Verify PDF generation and sharing. |

---

## Phase X: Verification Checklist
- [ ] **Security:** Supabase RLS policies verified for private/shared pet data.
- [ ] **Performance:** Isar queries indexed; UI remains 60fps during sync.
- [ ] **Offline:** App remains functional without internet; sync resolves conflicts on reconnect.
- [ ] **UX:** Touch targets ≥ 48px; contrast ratios compliant.
- [ ] **Tests:** Unit tests for schedule recurrence logic; widget tests for forms.

## ✅ Phase X Completion Criteria
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] Successful Debug/Release build for Android and iOS.
- [ ] All mandatory documentation (README, API docs) complete.
