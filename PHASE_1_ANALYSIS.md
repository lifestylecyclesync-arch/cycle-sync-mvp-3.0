# PHASE 1: Analysis & Planning - Code Structure Assessment

## 1. CURRENT CODE STRUCTURE MAPPING

### Screen Locations (planner_page.dart)
- **Hormonal Screen**: Lines 191-354
- **Fitness Screen**: Lines 355-887  
- **Diet Screen**: Lines 888-1435
- **Fasting Screen**: Lines 1436-1823
- **FAB Buttons**: Lines 1846-1983
- **Bottom Navigation Bar**: Lines 1986-2068

### Total File Size: 4,943 lines

---

## 2. DUPLICATED CODE ANALYSIS

### 2.1 CALENDAR GRID CODE (CRITICAL DUPLICATION)
Appears **3 times** (Fitness, Diet, Fasting screens):

**Duplicated Structure:**
```
Month Header (Padding + Row with chevrons) 
  → Day Names Header (GridView of 7 items)
    → Calendar Grid (GridView with phase color or indicators)
      → GestureDetector for date selection
        → cyclePhaseProvider watch for color
          → Container with styling
```

**Specific Duplications:**
1. **Fitness Calendar** (Lines 355-654): ~300 lines
   - Uses phase color text + green completion circle overlay
   - Has selection border logic
   
2. **Diet Calendar** (Lines 930-1191): ~260 lines
   - Uses phase color text only (no indicators)
   - Similar selection logic
   
3. **Fasting Calendar** (Lines 1470-1731): ~260 lines
   - Uses phase color text only (no indicators)
   - Similar selection logic

**Duplication Summary:**
- Grid delegate configs: Repeated 5+ times
- Day name rendering: Repeated 3 times
- Day number rendering: Repeated 3+ times
- Phase color extraction: Repeated 6+ times
- Selection detection: Repeated 3+ times

### 2.2 HEADER STRUCTURE (MONTH/DAY)
**Duplicated in:** Fitness (lines 891-928), Diet (lines 891-928), Fasting (1439-1476)

**Code Pattern:**
```dart
if (_selectedFilter == 'Hormonal' || _selectedFilter == 'Fitness' || ...)
  Padding(
    child: Row(
      children: [IconButton (prev), Text (month/year), IconButton (next)]
    )
  )
```

**Issue**: Same month/year header appears 3+ times with exact same conditional

### 2.3 CONTENT BUILDER PATTERN
**Used in all 4 screens** (Hormonal, Fitness, Diet, Fasting):

Each screen has identical pattern:
```dart
Expanded(
  SingleChildScrollView(
    ref.watch(cyclePhaseProvider(_selectedDate)).when(
      data: (phaseInfo) {
        return ref.watch(phaseRecommendationsProvider(...)).when(
          data: (phaseData) {
            // Extract items and build content
            ...
          }
        )
      }
    )
  )
)
```

---

## 3. CONTENT DIFFERENCES BETWEEN SCREENS

### Hormonal Screen (Lines 191-354)
**Components:**
1. Calendar with colored circles (phase color background + border)
2. Cycle Info Card (full-width) - Shows:
   - Day of cycle
   - Lifestyle phase
   - Cycle phase name (Menstrual/Follicular/Ovulation/Luteal)
   - Day range (X-Y)

**Content displayed:** ❌ None (only calendar + card in this section)

**FAB:** Purple (Cycle Input Modal)

**Today's Plan:** ❌ Not shown

---

### Fitness Screen (Lines 355-887)
**Components:**
1. Calendar with:
   - Phase color text
   - Blue selection border
   - Green completion circle overlay (if workouts logged)
2. Content Section shows:
   - "Fitness" title
   - Workout mode (clickable → modal)
   - Today's Plan: Lists selected workouts with 4 action buttons each
     - Edit (disabled)
     - Swap workout
     - Log completion
     - Delete

**Content displayed:** ✅ Workouts only

**FAB:** Blue (Workout Selection Modal)

**Today's Plan:** ✅ Shows selected workouts + 4 action buttons per item

---

### Diet Screen (Lines 888-1435)
**Components:**
1. Calendar with:
   - Phase color text only
   - Blue selection border
   - ❌ NO completion indicators
2. Content Section shows:
   - "Diet" title
   - Food vibe (clickable → shows recipe list)
   - Today's Plan: Lists selected recipes
     - ✅ Edit button (functional modal)
     - ✅ Swap button
     - ✅ Log button
     - ✅ Delete button

**Content displayed:** ✅ Recipes only

**FAB:** Green (Recipe Selection Modal)

**Today's Plan:** ✅ Shows selected recipes + 4 action buttons per item

---

### Fasting Screen (Lines 1436-1823)
**Components:**
1. Calendar with:
   - Phase color text only
   - Blue selection border
   - ❌ NO completion indicators
2. Content Section shows:
   - "Fasting" title
   - Fasting recommendation (clickable → hours toggle + slider)
   - Today's Plan: Shows:
     - Selected fasting hours
     - Edit button (opens full modal)
     - Log button
     - Delete button

**Content displayed:** ✅ Fasting setup only

**FAB:** Orange (Fasting Type Modal with toggle/slider)

**Today's Plan:** ✅ Shows fasting hours + 3 action buttons

---

## 4. VISUAL INCONSISTENCIES

### Calendar Display
| Feature | Hormonal | Fitness | Diet | Fasting |
|---------|----------|---------|------|---------|
| Phase colors | Dots w/ circles | Text | Text | Text |
| Today highlight | Border + background | Border | Border | Border |
| Completion indicator | ❌ | Green circle | ❌ | ❌ |
| Selection styling | Different | Blue border | Blue border | Blue border |

### Phase Info Display
| Feature | Hormonal | Fitness | Diet | Fasting |
|---------|----------|---------|------|---------|
| Shows phase card | ✅ Yes | ❌ No | ❌ No | ❌ No |
| Shows all lifecycle info | ✅ Complete | ❌ | ❌ | ❌ |

### Content Coverage
| Lifestyle Area | Hormonal | Fitness | Diet | Fasting |
|----------------|----------|---------|------|---------|
| Shows Nutrition | ✅ In Daily Card | ❌ | Only recipes | ❌ |
| Shows Fitness | ✅ In Daily Card | ✅ Full | ❌ | ❌ |
| Shows Diet | ✅ In Daily Card | ❌ | ✅ Full | ❌ |
| Shows Fasting | ✅ In Daily Card | ✅ Limited | ❌ | ✅ Full |

---

## 5. EXTRACTION OPPORTUNITIES

### High Priority (Most Duplicated)

#### 1. **Calendar Grid Widget** 
**Estimated Lines to Extract:** 150-200 lines
**Current Locations:** 3 screens (Fitness, Diet, Fasting)
**Usage:** Would replace all calendar rendering

**Parameters Needed:**
- `days: List<DateTime>` - Days to display
- `selectedDate: DateTime` - Current selection
- `showCompletionIndicator: bool` - Show green circle (Fitness only)
- `onDateSelected: Function(DateTime)` - Selection callback
- `colorProvider: Function(DateTime) -> Color` - Get phase color

**Duplicate Code Reduction:** ~600 lines → ~150 lines

---

#### 2. **Month/Year Header**
**Estimated Lines to Extract:** 20-30 lines
**Current Locations:** 4 times in conditional blocks
**Usage:** Shared by all screens except Hormonal

**Parameters:**
- `currentMonth: DateTime`
- `onPreviousMonth: VoidCallback`
- `onNextMonth: VoidCallback`

**Duplicate Code Reduction:** ~80 lines → ~25 lines

---

#### 3. **Cycle Info Card Component**
**Estimated Lines to Extract:** 40-60 lines
**Current Locations:** Hormonal screen only
**Usage:** Should appear on all 4 screens

**Parameters:**
- `date: DateTime`
- `phaseInfo: PhaseInfo`

**Impact:** Currently missing from 3 screens

---

#### 4. **Today's Plan Summary Component**
**Estimated Lines to Extract:** 80-120 lines
**Current Locations:** Partially in Fitness screen
**Usage:** Needed for all 4 screens with different counters

**Parameters:**
- `selectedCount: int` - Items planned
- `completedCount: int` - Items done
- `itemType: String` - "workouts" / "recipes" / "fasting hours"

**Impact:** Currently only in Fitness; needed in Diet & Fasting

---

### Medium Priority (Code Patterns)

#### 5. **Content Section Wrapper**
**Pattern:** Expanded(SingleChildScrollView(Padding(...)))
**Locations:** All 4 screens
**Reduction:** ~20 lines per screen

---

#### 6. **Modal Template**
**Pattern:** All modals follow same structure (heading + scrollable list + selection)
**Locations:** Used 6+ times
**Reduction:** Could extract generic modal builder

---

## 6. WIDGET EXTRACTION PLAN

### Create Files:
1. `lib/presentation/widgets/cycle_calendar_widget.dart`
   - Handles all calendar grid rendering
   - Supports phase colors
   - Optional completion indicators
   
2. `lib/presentation/widgets/cycle_info_card.dart`
   - Reusable phase info display
   
3. `lib/presentation/widgets/todays_plan_summary.dart`
   - Generic progress/summary widget
   - Works with any selection type
   
4. `lib/presentation/widgets/month_selector_header.dart`
   - Month/year header with navigation

### Refactor in planner_page.dart:
1. Remove calendar grid code from 3 screens
2. Remove month header duplications
3. Import and use extracted widgets
4. Add cycle info card to all screens
5. Add today's plan summary to Fitness/Diet/Fasting

---

## 7. REFACTORING IMPACT SUMMARY

### Before
- **Planner Page Size:** 4,943 lines
- **Duplicated Calendar Code:** ~700 lines (3 copies)
- **Duplicated Header Code:** ~80 lines (4 copies)
- **Missing Components:** Cycle card on 3 screens, Today's Plan on 2 screens

### After (Estimated)
- **Planner Page Size:** ~3,200 lines (-35% reduction)
- **New Widget Files:** 4 files (~400 lines total)
- **All Calendars Unified:** Single source of truth
- **Complete Feature Parity:** All screens have same components
- **Maintainability:** Changes to calendar affect all screens automatically

### Lines Saved:
- Calendar duplication: -600 lines
- Header duplication: -60 lines  
- Better organization: -1,100 lines (logical grouping)
- **Total: ~1,800 lines reduction**

---

## 8. IMPLEMENTATION ROADMAP

### Step 1.1: ✅ MAPPING COMPLETE
- Hormonal: Calendar + Info Card (no content section)
- Fitness: Calendar + Content (workouts) + Today's Plan
- Diet: Calendar + Content (recipes) + Today's Plan
- Fasting: Calendar + Content (fasting) + Today's Plan

### Step 1.2: ✅ DUPLICATION IDENTIFIED
- Calendar grid: 3 copies
- Month header: 4 instances
- Content structure: 4 implementations
- Info display: 1 instance (needs to be on all 4)

### Step 1.3: ✅ CONTENT DIFFERENCES DOCUMENTED
- Each screen shows only its lifestyle area
- Different visual treatments for completion
- Different Today's Plan complexity

### Step 1.4: ✅ EXTRACTION PLAN CREATED
- Priority 1: Calendar grid (~150 lines saved)
- Priority 2: Info card + headers (~80 lines saved)
- Priority 3: Today's Plan widget (~100 lines saved)
- Priority 4: Content pattern improvements

---

## 9. KEY INSIGHTS

### Why Separate Screens Became Duplicated:
1. Started with just Hormonal screen
2. Fitness/Diet/Fasting added by copying Hormonal structure
3. Each customized independently without refactoring
4. Code diverged significantly

### Why Full Refactor is Important:
1. **Maintainability**: Bug fix in calendar applies to all screens
2. **Consistency**: Ensures visual/UX parity across all tabs
3. **Scalability**: Adding new lifestyle area becomes trivial
4. **Performance**: Reduce component tree complexity

### Why Current Structure Works But Is Fragile:
- Users can't easily tell if they completed items on other tabs
- Calendar styling differs (inconsistent visual language)
- Phase info only shown on Hormonal screen
- Today's Plan missing from 2 screens

---

## NEXT STEP: Phase 2
Begin extracting `CycleCalendarWidget` as the foundation for all calendar rendering.

