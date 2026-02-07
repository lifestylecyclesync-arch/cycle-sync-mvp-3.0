# Multi-Screen Onboarding Flow - Complete Implementation

## Overview
Redesigned the onboarding from a single screen to a beautiful 3-screen progressive flow that guides users through:
1. Welcome screen
2. Cycle data input
3. Lifestyle area selection

## Screen-by-Screen Breakdown

### **Screen 1: Welcome**
**Purpose**: First impression and entry point

**UI Components**:
- App name: "Cycle Sync" (peach colored)
- Tagline: "Sync your lifestyle with your cycle."
- Heart icon (peach, 80px)
- **"Get Started"** button (primary)
- **"Sign In"** button (outlined)
- **"Sign Up"** button (outlined)

**Actions**:
- "Get Started" → Proceed to Screen 2
- "Sign In" → Navigate to /signin (for existing users)
- "Sign Up" → Navigate to /signup (for new users)

**Notes**:
- Clean, minimal design
- Heart icon placeholder (can be replaced with custom illustration)
- No back button visible on this screen

---

### **Screen 2: Cycle Data Input**
**Purpose**: Collect baseline cycle information

**Header**:
- Title: "Tell us about your cycle"
- Subtitle: "This helps us personalize your experience"

**Fields**:

1. **First date of your last period**
   - Calendar picker (date selector)
   - Default: 14 days ago
   - Range: Up to 365 days in the past
   - Display format: "MMMM dd, yyyy" (e.g., "January 20, 2026")

2. **Average cycle length**
   - Slider: 21-35 days (default 28)
   - Badge showing current value
   - Min/Max labels at bottom
   - 14 divisions for 1-day increments

3. **Average menstrual flow length**
   - Slider: 2-10 days (default 5)
   - Badge showing current value
   - **Warning if >10 days**:
     ```
     "Most cycles range between 2–10 days. If your period is 
     consistently longer, please consult a healthcare provider."
     ```
     - Orange background
     - Non-blocking (user can still save)

**Validation**:
- Cycle length: 21-35 days
- Menstrual length: 2-10 days
- Error messages in SnackBar
- Date: Cannot be in the future

**Actions**:
- Back button → Return to Screen 1
- "Continue" button → Proceed to Screen 3

---

### **Screen 3: Lifestyle Area Selection**
**Purpose**: Customize dashboard modules

**Header**:
- Title: "What areas interest you?"
- Subtitle: "Select at least one to customize your dashboard"

**Chip Options** (multi-select):
- Nutrition
- Fitness
- Fasting

**Chip Behavior**:
- Default: None selected
- Selected: Peach background (30% opacity), peach text, bold
- Unselected: Grey background, black text
- Toggleable: Click to select/deselect

**Actions**:
- Back button → Return to Screen 2
- "Complete Setup" button:
  - Disabled if no areas selected
  - Saves onboarding with selected areas
- "Skip for now" button:
  - Saves onboarding with empty lifestyle_areas
  - User will be prompted later
  - Lighter color (grey text)

**After Completion**:
- If "Complete Setup" → Navigate to /home
- If "Skip for now" → Navigate to /home (with empty areas for later)

---

## Data Flow

```
User Opens App
    ↓
AuthWrapper checks:
  - Is authenticated?
  - Has completed onboarding?
    ↓
Screen 1 (Welcome)
  ├─ "Get Started" → Screen 2
  ├─ "Sign In" → /signin
  └─ "Sign Up" → /signup
    ↓
Screen 2 (Cycle Data)
  ├─ Validate cycle_length (21-35)
  ├─ Validate menstrual_length (2-10)
  ├─ Validate last_period_date (not future)
  └─ Back or Continue
    ↓
Screen 3 (Lifestyle)
  ├─ Select ≥1 area or skip
  ├─ completeOnboardingProvider called
  └─ Save: last_period_date, cycle_length, menstrual_length, lifestyle_areas
    ↓
/home (Main App)
```

## Database Updates

**user_profiles table**:
```sql
lifestyle_areas TEXT[] DEFAULT '{}' -- Stored as array
onboarding_completed BOOLEAN DEFAULT FALSE
onboarding_completed_at TIMESTAMP WITH TIME ZONE
```

## Implementation Details

### Files Modified:

1. **`onboarding_screen.dart`**
   - Single ConsumerStatefulWidget managing 3 screens via `_currentStep` (0, 1, 2)
   - State variables:
     - `_currentStep`: Current screen index
     - `_lastPeriodDate`: Date from picker
     - `_cycleLength`: Slider value (21-35)
     - `_menstrualLength`: Slider value (2-10)
     - `_showMenstrualWarning`: Boolean for >10 warning
     - `_selectedLifestyleAreas`: Set<String> for chips
     - `_isLoading`: For loading state during save
   
2. **`onboarding_provider.dart`**
   - Updated `completeOnboardingProvider` to accept `lifestyleAreas` parameter
   - Saves all fields to `user_profiles` table
   - Sets `onboarding_completed=true` and `onboarding_completed_at`

### Key Features:

✅ **Multi-step progression** with back navigation
✅ **Progressive validation** at each step
✅ **Gentle warnings** (menstrual >10 days but still allows saving)
✅ **Skip option** for lifestyle selection (user can be prompted later)
✅ **Date picker** with 365-day range
✅ **Sliders** with visual feedback and min/max labels
✅ **Multi-select chips** with visual selected state
✅ **Error handling** with SnackBar messages
✅ **Loading state** during save
✅ **Accessible navigation** with back button
✅ **Responsive** layout using SingleChildScrollView

### Widget Builders:

- `_buildWelcomeScreen()` - Screen 1
- `_buildCycleDataScreen()` - Screen 2
- `_buildLifestyleSelectionScreen()` - Screen 3
- `_buildDatePickerCard()` - Reusable date picker
- `_buildNumericInput()` - Reusable slider + value display

---

## User Experience Improvements

| Aspect | Old | New |
|--------|-----|-----|
| **Screens** | 1 large screen | 3 focused screens |
| **Cognitive Load** | High (all info at once) | Low (progressive steps) |
| **Visual Hierarchy** | Crowded | Clean, prioritized |
| **Navigation** | None | Back button for exploration |
| **Skip Option** | None | "Skip for now" on lifestyle |
| **Warnings** | Hard error | Gentle, non-blocking |
| **Illustration** | None | Heart icon placeholder |

---

## Edge Cases Handled

1. **Date in future** → Not selectable in picker
2. **Menstrual >10 days** → Warning shown but allowed
3. **No lifestyle selected** → Button disabled, skip available
4. **Save fails** → SnackBar error message, can retry
5. **Back from Screen 2** → Returns to welcome (data preserved)
6. **Skip lifestyle** → User can be prompted in settings later

---

## Next Steps

1. ✅ Schema supports lifestyle_areas
2. ✅ Onboarding screen redesigned (3 screens)
3. ✅ Provider updated to save lifestyle_areas
4. ⏳ Deploy schema to Supabase
5. ⏳ Test complete onboarding flow
6. ⏳ Add routes for /signin and /signup if not exists
7. Optional: Add illustration for welcome screen
8. Optional: Add animation between screens

