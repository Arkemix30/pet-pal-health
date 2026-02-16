# PLAN: Pet Deletion Feature (Soft Delete)

## 🎯 Goal
Implement a secure, owner-only soft-deletion flow for pet profiles. This ensures that data remains in the database (archived) but is no longer visible to users in the app.

## 🏗️ Architecture & Requirements
- **Strategy**: Soft Delete (setting `is_deleted = true`).
- **Owner-Only**: Only the original creator (owner_id) can perform the deletion.
- **Cascading**: Associated data (schedules, records) will be preserved in the archive but hidden from active views.
- **Local-First**: The change must be recorded locally in Isar and then synced to Supabase.

---

## 📅 Task Breakdown

### Phase 1: Storage & Repository (The Foundation)
1.  **Repository Method**: Implement `softDeletePet(Pet pet)` in `PetRepository`.
    -   Update local Isar object: `isDeleted = true`, `isSynced = false`.
    -   Invoke `_syncPetToRemote`.
2.  **Sync Logic**: Ensure `_syncPetToRemote` correctly pushes the `is_deleted` flag to Supabase.
3.  **Filtration Verification**: Verify that existing `watchPets()` and `fetchPetsFromRemote()` methods in `PetRepository` correctly filter by `is_deleted = false`.

### Phase 2: UI & User Experience
1.  **Confirmation Dialog**: Create a reusable `DeletionConfirmationDialog` (or use a standard Material dialog) to prevent accidental data loss.
2.  **Edit Screen Update**: Add a "Delete Profile" button at the bottom of the `PetFormScreen` (only when in **Edit** mode).
3.  **Navigation Logic**: 
    -   Trigger the deletion method.
    -   On success, show a SnackBar.
    -   Pop the navigation stack multiple times or redirect to the Main Dashboard.

### Phase 3: Security & Backend Verification
1.  **RLS Policy Audit**: Verify that the Supabase `pets` table RLS for `UPDATE` is strictly limited to `owner_id = auth.uid()`.
2.  **SQL Patch**: Create `docs/SCHEMA-verify-delete-policy.sql` to ensure the owner-only restriction is enforced.

---

## 🧪 Verification Checklist

### Local Persistence
- [ ] Set a pet to deleted while offline. Verify Isar `isDeleted` is true.
- [ ] Verify the pet disappears from the Dashboard immediately.

### Remote Sync
- [ ] Go online. Verify Supabase `pets` table shows `is_deleted = true` for the record.
- [ ] Verify `updated_at` on Supabase is refreshed.

### Security
- [ ] Attempt to delete a pet shared with an "Editor" account. Verify the UI/API prevents the action.

### Navigation
- [ ] Ensure that after deletion, the user is not left on a stale "Pet Details" screen for the deleted pet.

---

## 🤖 Agent Assignments
- **Mobile Developer**: Create the UI button and Confirmation Dialog.
- **Backend Specialist**: Audit RLS policies and handle repository updates.
- **Antigravity (Orchestrator)**: Manage the navigation flow and sync verification.
