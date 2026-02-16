# Implementation Plan: Supabase-to-Local Data Sync

The goal is to resolve the data discrepancy where Supabase has more pets than the local Isar database (4 vs 3) by implementing a "Pull" sync from Supabase on application load.

## Phase 1: Repository Enhancements
Update `PetRepository` to handle fetching data from Supabase and persisting it locally.

### 1.1 Add `fetchPetsFromRemote` to `PetRepository`
- **Location**: `lib/features/pet_management/pet_repository.dart`
- **Logic**:
    - Fetch all pets from Supabase where `owner_id` is the current user and `is_deleted` is false.
    - Loop through remote results.
    - Check if a pet with the same `supabaseId` exists in Isar.
    - If it doesn't exist, create a new `Pet` record locally.
    - If it does exist, optionally update local fields (name, photo, etc.) to ensure parity.

### 1.2 Add `pullAllSchedulesFromRemote` (Optional but Recommended)
- Since pets have health schedules, we should also pull schedules from Supabase to ensure the "Timeline" is complete.

## Phase 2: Orchestration
Ensure the sync is triggered at the right time.

### 2.1 Update `syncAllUnsynced`
- Rename or expand `syncAllUnsynced` in `PetRepository` to a more comprehensive `performFullSync()` that does both:
    1. **Pull**: Fetch from remote to local.
    2. **Push**: Sync any local changes created while offline.

### 2.2 Trigger Sync in UI
- **Location**: `lib/features/pet_management/pet_dashboard_screen.dart`
- **Trigger**: Call `ref.read(petManagementProvider).performFullSync()` within the `build` method (using a `useEffect`-like pattern with `ref.listen` or a dedicated initialization state) or simply when the sync button is pressed.
- **Auto-Sync**: Add a check in `main.dart` or the Home screen to trigger a background sync on app start.

## Phase 3: Verification
- Log in and verify that the 4th pet appears in the "My Pet Family" selector.
- Check that the pet details (photo, species, breed) are correctly mapped.

## File Changes:
- `lib/features/pet_management/pet_repository.dart`: Add `fetchPetsFromRemote`.
- `lib/features/pet_management/pet_dashboard_screen.dart`: Trigger the sync.

## Risk Assessment:
- **ID Collisions**: Isar uses auto-incrementing integers, while Supabase uses UUIDs as `id`. We must always map `supabaseId` carefully.
- **Race Conditions**: Ensure that multiple sync calls don't create duplicate records.
