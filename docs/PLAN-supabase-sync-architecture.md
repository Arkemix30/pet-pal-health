# Project Plan: Local-First, Remote-Always Data Architecture

## 1. Context
Current State: The app uses Isar (local DB) for reactivity and Supabase (remote DB) for persistence. Some screens fail to show data initially because they rely only on the empty local DB without triggering a sync.
Objective: Ensure Supabase is the primary source of truth while maintaining local-first responsiveness. Data should be fetched aggressively on screen load.

## 2. Proposed Architecture
**"Sync-Active Stream" Pattern** across all providers.

1. **Provider Initialization**:
   - `StreamProvider` immediately yields local data (fast, instant UI).
   - Simultaneously, triggers a background fetch from Supabase.
   - On fetch success -> Update local DB -> Stream emits new data automatically.

2. **Aggressive Sync Triggers**:
   - **On App Start**: Sync User Settings & Profile.
   - **On Dashboard Load**: Sync Pets & active schedules.
   - **On Feature Access**: specific `sync()` calls for specific screens (Vets, Timeline).
   - **On Pull-to-Refresh**: Manual re-sync (already implemented).

## 3. Implementation Steps

### Phase 1: Provider Standardization
- [x] **Pets**: `petsStreamProvider` updated to sync on init.
- [x] **Vets**: `vetsStreamProvider` updated to sync on init.
- [ ] **Schedules**: Update `allSchedulesProvider` to sync on init.
- [ ] **Profile**: Ensure `userSettingsProvider` syncs on init.

### Phase 2: Repository Robustness
- [ ] **Error Handling**: Consolidate sync error logging (avoid silent failures).
- [ ] **Conflict Resolution**: (Future) Handle timestamp conflicts if editing offline (User Wins or Server Wins strategy). currently "Last Writer Wins".

### Phase 3: Global Sync Manager
- [ ] Create a `GlobalSyncService` to coordinate all repository syncs.
- [ ] Add a global "Syncing..." indicator (optional UX).

## 4. Verification Checklist
- [ ] Vet Directory loads remote data on first install.
- [ ] Dashboard shows pets on first login without manual refresh.
- [ ] Timeline shows history on first load.
- [ ] Offline edits sync correctly when back online.
