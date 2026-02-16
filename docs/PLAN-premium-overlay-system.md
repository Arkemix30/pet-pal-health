# PLAN: Premium UI/UX Overlay System

## 🎯 Goal
Implement a state-of-the-art, high-fidelity overlay system for notifications, success states, and errors. This will replace the standard SnackBar/Dialogs with a custom "Premium Dark Glass" aesthetic inspired by the Stitch designs.

## 🏗️ Architecture & Requirements
- **Theme**: Forced Premium Dark Glass (Backdrop Blur + Rich Greens/Reds).
- **Global Management**: `OverlayService` providing context-independent triggers.
- **Micro-Animations**: Custom slide, fade, and scale-up transitions using `flutter_animate`.
- **Sensory**: Integrated `HapticFeedback` for all interactions.

---

## 📅 Task Breakdown

### Phase 1: Core Systems (The Foundation)
1.  **Overlay Logic**: Create `lib/core/ui/overlays/overlay_manager.dart`.
    - Handle `OverlayEntry` management for floating toasts.
    - Implement `PremiumModal` base using `showGeneralDialog`.
2.  **Design Tokens**: Update `lib/core/theme/app_theme.dart` with premium overlay colors.
    - `overlayBackground`: `#1A2E1F` (Dark Forest Green).
    - `overlayBorder`: `primary.withOpacity(0.2)`.
    - `successGlow`: `primary.withOpacity(0.4)`.

### Phase 2: Success & Confirmation Modals
1.  **`PremiumSuccessModal`**: Implementation based on Stitch ID `998b268d2a624a2999253d62591547bc`.
    - Features: Layered success icon, Backdrop blur, Manrope typography, High-contrast primary button.
2.  **`PremiumConfirmDialog`**: Custom replacement for the deletion confirmation.
    - Aesthetic: Glassmorphic card, red accented destructive actions.

### Phase 3: Floating Notifications (Toasts)
1.  **`PremiumToast`**: Implementation based on Stitch ID `3121e4955d39452eb15a3458602aec75`.
    - **Error Toast**: Top-floating, red left-border, custom "error" glyph.
    - **Sync Toast**: Bottom Snackbar replacement with "Ping" animation for connectivity.
2.  **Integration**: Replace all `ScaffoldMessenger.showSnackBar` calls with `OverlayManager.showToast`.

### Phase 4: Refinement & Reflow
1.  **Haptics**: Add `HapticFeedback.mediumImpact()` to success modals and `HapticFeedback.vibrate()` to error toasts.
2.  **Global Refactoring**: 
    - Update `PetFormScreen` to use `PremiumSuccessModal` on save/delete.
    - Update `PetDetailsScreen` to use premium error states if sync fails.

---

## 🧪 Verification Checklist

### Aesthetics
- [ ] Verify Backdrop Blur (10.0 sigma) is active behind all modals.
- [ ] Check `Manrope` font weighting (800 for titles, 500 for body).

### Persistence & Flow
- [ ] Trigger a success modal and navigate away. Verify the modal stays centered.
- [ ] Verify toasts don't block user interaction (pointer-events set correctly).

### Error Handling
- [ ] Turn off internet. Trigger a sync error. Verify the "Ping" animation appears in the status toast.

### Haptics
- [ ] Test on a physical device to confirm haptic feedback intensity.

---

## 🤖 Agent Assignments
- **Mobile iOS/Android Design**: Ensure identical premium feel across both platforms (Glassmorphism consistency).
- **Backend Specialist**: Integrate sync-error triggers into the `PremiumToast` system.
- **Mobile Developer**: Build the `OverlayManager` and custom micro-animations.
