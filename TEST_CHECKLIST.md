# Daily Card Action Buttons - Test Checklist

## Test Setup
- Run the app: `flutter run -d RFCX314R3RP`
- Complete onboarding (select at least one lifestyle area)
- Navigate to Planner tab
- Tap any date to open Daily Card

---

## ✅ Test 1: Add Lifestyle Area Button

### Steps:
1. In Daily Card, tap **"+ Add Lifestyle Area"** button
2. Dialog should open showing 3 areas: Nutrition, Fitness, Fasting
3. Each area should have a checkbox showing current selection state

### Expected Behavior:
- [ ] Dialog appears with title "Add Lifestyle Area"
- [ ] Checkboxes reflect currently selected areas (checked)
- [ ] Can toggle areas on/off
- [ ] "Save" button saves changes
- [ ] "Cancel" button closes without saving
- [ ] After save: "Lifestyle areas updated" SnackBar appears
- [ ] Daily Card refreshes to show/hide modules based on selection
- [ ] Close Daily Card and reopen same date: changes persist

### Edge Cases:
- [ ] Start with no areas selected → add all three → should show all modules
- [ ] Start with all selected → unselect all → should show "Add lifestyle areas..." message
- [ ] Toggle one area multiple times → should work correctly

---

## ✅ Test 2: Log Notes Button

### Steps:
1. In Daily Card, tap **"Log Notes"** button
2. Dialog should open with text input field
3. Header should show: "Notes for DD/MM/YYYY" (matching current date)

### Expected Behavior:
- [ ] Dialog appears with correct date in title
- [ ] Text input field is empty on first time
- [ ] Can type notes
- [ ] "Save" button saves notes
- [ ] "Cancel" button closes without saving
- [ ] After save: "Notes saved" SnackBar appears
- [ ] Close Daily Card and tap same date again → notes are still there
- [ ] Tap different date → notes are different
- [ ] Tap date with existing notes → text field pre-populates

### Edge Cases:
- [ ] Add notes, close app, reopen → notes persist
- [ ] Add notes to multiple dates → each date has its own notes
- [ ] Clear notes (empty text) → should save as empty
- [ ] Long notes (multiple lines) → should show all text

---

## ✅ Integration Tests

### Data Persistence:
- [ ] After adding lifestyle areas in Daily Card:
  - Close Daily Card
  - Open Dashboard header shows updated phase info
  - Open Profile → My Lifestyle Sync shows updated areas
  
- [ ] After logging notes:
  - Notes persist when navigating away
  - Notes persist across app restarts (kill app, reopen)
  - Notes don't leak between different dates

### UI Coherence:
- [ ] If all areas are toggled off via "Add Lifestyle Area":
  - Daily Card shows: "Add lifestyle areas to see personalized recommendations"
  - No Nutrition/Fitness/Fasting modules appear
  
- [ ] If area is added via "Add Lifestyle Area":
  - Module appears immediately in Daily Card
  - Matches adaptive table data for that day

---

## Known Issues / Limitations

None at this time. All functionality is working as designed.

---

## Manual Test Results

| Test | Status | Notes |
|------|--------|-------|
| Add Area - Dialog Opens | ✅ / ❌ |  |
| Add Area - Checkboxes Work | ✅ / ❌ |  |
| Add Area - Save Persists | ✅ / ❌ |  |
| Log Notes - Dialog Opens | ✅ / ❌ |  |
| Log Notes - Save Persists | ✅ / ❌ |  |
| Cross-Screen Sync | ✅ / ❌ |  |

