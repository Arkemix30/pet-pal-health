# PLAN: Pet CRUD & Image Support

This plan covers the implementation of full CRUD capabilities for pets, including image selection, Supabase Storage integration with local caching, and soft deletion.

## 🟢 Context & Strategy
- **Tech Stack**: Flutter, Isar, Supabase, Riverpod.
- **Image Strategy**: We will use `image_picker` for selection and `cached_network_image` for the "A+B" strategy (Remote storage + Local disk caching).
- **Soft Delete**: Pets will be marked as `isDeleted` and hidden from the UI instead of immediate removal.
- **UI Architecture**: Refactor `AddPetScreen` into a unified `PetFormScreen` to handle both Creation and Editing.

---

## 🛠 Phase 1: Storage & Models
- [x] Add `image_picker` and `cached_network_image` to `pubspec.yaml`.
- [x] Update `Pet` model in `lib/data/local/isar_models.dart`:
    - Add `bool isDeleted = false;`.
- [x] Run `build_runner` to regenerate Isar schemas.
- [x] Create `StorageService` in `lib/core/services/storage_service.dart` to handle Supabase Storage bucket operations.

## 🛠 Phase 2: Repository Enhancements
- [x] Update `PetRepository` (`lib/features/pet_management/pet_repository.dart`):
    - Implement `updatePet` logic (syncing metadata to Supabase).
    - Implement `softDeletePet` (updating local and remote `is_deleted` flag).
    - Integrate `StorageService` to upload profile photos before saving the Pet record.
    - Update `watchPets` stream to filter out `isDeleted == true`.

## 🛠 Phase 3: Unified Form UI
- [x] Refactor `lib/features/pet_management/add_pet_screen.dart` to `lib/features/pet_management/pet_form_screen.dart`.
- [x] Add `Pet? initialPet` constructor parameter.
- [x] Implement Image Selection widget using `image_picker`.
- [x] UI Support for "Edit Mode" (Auto-filling fields, changing Save button text).
- [x] Add "Delete Pet" button in the edit view (with confirmation dialog).

## 🛠 Phase 4: Polish & Performance
- [x] Implement image caching using `CachedNetworkImage` in `PetDashboardScreen` and `PetDetailsScreen`.
- [x] Add loading states for image uploads.
- [x] Verification: ensure image persists across sessions and is accessible offline after initial load.

---

## 🎭 Agent Assignments
- **`database-architect`**: Schema updates and Supabase Storage bucket setup.
- **`mobile-developer`**: UI refactoring, `image_picker` integration, and repository logic.

---

## ✅ Verification Checklist
- [x] User can add a pet with a photo from Gallery or Camera.
- [x] Pet photo appears in Dashboard and Details screen.
- [x] User can edit pet details (name, breed, etc.) and update the photo.
- [x] User can "Delete" a pet (record remains in DB but disappears from view).
- [x] Application works offline with last loaded images.
