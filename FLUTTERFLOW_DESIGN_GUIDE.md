# Cycle Sync MVP 2 - Complete FlutterFlow Design Guide

**Last Updated:** January 28, 2026  
**Framework:** Flutter 3.38.5 | Dart 3.10.4 | Riverpod 3.1.0  
**Build Status:** ✅ 0 Compilation Errors | Ready for FlutterFlow

---

## 📋 Table of Contents

1. [Global Design System](#global-design-system)
2. [Screen 1: Hormonal Tab (Calendar)](#screen-1-hormonal-tab-calendar)
3. [Screen 2: Fitness Tab (Learn/Plan)](#screen-2-fitness-tab-learnplan)
4. [Screen 3: Diet Tab (Learn/Plan)](#screen-3-diet-tab-learnplan)
5. [Screen 4: Fasting Tab (Learn/Plan)](#screen-4-fasting-tab-learnplan)
6. [Screen 5: Report Tab (Placeholder)](#screen-5-report-tab-placeholder)
7. [Navigation & FAB](#navigation--fab)
8. [Component Library](#component-library)
9. [Modal Dialogs](#modal-dialogs)
10. [State Management](#state-management)
11. [Implementation Checklist](#implementation-checklist)

---

## Global Design System

### Color Palette

#### Theme Colors (Tab-Specific)
```
Hormonal Tab:
  - Primary: Purple #A37FCE
  - FAB Color: #A37FCE
  - Icon: calendar_today

Fitness Tab:
  - Primary: Blue #42A5F5
  - FAB Color: #42A5F5
  - Icon: fitness_center

Diet Tab:
  - Primary: Green #66BB6A
  - FAB Color: #66BB6A
  - Icon: restaurant

Fasting Tab:
  - Primary: Orange #FFA726
  - FAB Color: #FFA726
  - Icon: schedule
```

#### Cycle Phase Colors (Inside Cards)
```
Follicular Phase: #42A5F5 (Blue)
Ovulation Phase: #FF5252 (Red)
Luteal Phase: #66BB6A (Green)
Menstrual Phase: #A37FCE (Purple)
```

#### Neutral Palette
```
White: #FFFFFF (Card backgrounds)
Light Gray: #F3F3F3 (Backgrounds)
Medium Gray: #E0E0E0 (Dividers)
Text Primary: #212121 (Main text)
Text Secondary: #757575 (Secondary text)
Text Tertiary: #9E9E9E (Hints/Disabled)
```

### Typography System

```
Headline (Modal Titles):
  Font: Roboto
  Size: 20px
  Weight: 600 (Semi-bold)
  Usage: Modal titles, section headers

Title (Card Titles - deprecated):
  Font: Roboto
  Size: 18px
  Weight: 600 (Semi-bold)
  Usage: Was used for "Fitness", "Diet", "Fasting" - NOW REMOVED

Body Medium (Main Content):
  Font: Roboto
  Size: 16px
  Weight: 400 (Regular)
  Usage: Interactive elements, list items, main text

Body Small (Secondary Content):
  Font: Roboto
  Size: 14px
  Weight: 400 (Regular)
  Usage: Helper text, hints, secondary info

Label (Tab Labels):
  Font: Roboto
  Size: 12px
  Weight: 500 (Medium)
  Usage: Navigation labels, badges
```

### Spacing System

```
spacingSm:  8px    - Small gaps, icon buttons
spacingMd:  16px   - Standard gap (BETWEEN CARDS)
spacingLg:  24px   - Large section spacing
spacingXl:  32px   - Extra large spacing
```

### Component Styling

#### Card Standard
```
Background: White (#FFFFFF)
Border Radius: 12px
Padding: 16px all sides
Elevation: 2
Shadow: offset(0, 2), blur(8), opacity(0.3)
Margin Bottom: 16px (between cards)
```

#### Icon Button Standard
```
Size: 48x48 logical pixels
Icon Size: 24px
Color: Gray #9E9E9E
Ripple: Material default
Hover: Slightly darker shade
```

#### FAB Standard
```
Shape: Circle (56x56)
Icon: Icons.add (28px, white)
Elevation: 8
Shadow: 8px blur, offset(0, 4)
Position: bottom: 70, right: 16 (Positioned widget)
```

---

## Screen 1: Hormonal Tab (Calendar)

### Visual Layout

```
╔═══════════════════════════════════╗
║  < JANUARY 2024 >                 ║  AppBar with month navigation
╚═══════════════════════════════════╝

╔═══════════════════════════════════╗
║  M  T  W  T  F  S  S             ║
║  -  -  1  2  3  4  5             ║
║  6  7  8  9  10 11 12            ║  Calendar Grid (7 columns)
║  13 14 15 16 17 18 19            ║  Colored circles by phase
║  ...                             ║
╚═══════════════════════════════════╝

╔═══════════════════════════════════╗
║  Day 7 • Follicular Phase        ║  Cycle Info Card
║  Follicular Phase (Days 1-7)     ║
║  [Description/recommendations]   ║
╚═══════════════════════════════════╝

                                    [+] FAB (Purple)
[Hormonal] [Fitness] [Diet] [Fasting]
```

### Components

#### Calendar Grid
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 7,
    crossAxisSpacing: 2,
    mainAxisSpacing: 2,
    childAspectRatio: 1.5,
  ),
  itemCount: 35, // 5 weeks
  itemBuilder: (context, index) {
    bool isCurrentMonth = /* check logic */;
    bool isCurrentDay = /* check logic */;
    Color phaseColor = getPhaseColor(date);
    
    if (isCurrentMonth) {
      return CircleAvatar(
        backgroundColor: phaseColor,
        child: Text(
          '$dayNumber',
          style: TextStyle(
            fontSize: isCurrentDay ? 16 : 14,
            fontWeight: isCurrentDay ? FontWeight.w700 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return Center(
        child: Text(
          '$dayNumber',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }
  },
)
```

**Styling:**
- Cell Shape: Circle with solid fill (current month)
- Cell Text: White, bold for current day
- Other Months: Light gray text, no background
- Grid Spacing: 2px between cells
- Aspect Ratio: 1.5 (taller than wide)

#### Cycle Info Card
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Day 7 • Follicular Phase',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: phaseColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Follicular Phase (Days 1-7)\n[Description]',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  ),
)
```

**Styling:**
- Background: White
- Title Color: Phase-specific (changes with cycle)
- Title Weight: Semi-bold (w600)
- Description: Body Small, gray
- Padding: 16px all sides
- Radius: 12px

### State Management

```dart
final cyclePhaseProvider = FutureProvider<String>((ref) async {
  // Returns: 'follicular', 'ovulation', 'luteal', 'menstrual'
  // Based on selected date
});

final phaseRecommendationsProvider = FutureProvider<PhaseData>((ref) async {
  // Returns: {
  //   name: phase name,
  //   displayName: "Follicular Phase",
  //   description: "...",
  //   workouts: [...],
  //   recipes: [...],
  //   recommendedFastingHours: 13
  // }
});

// Local state:
late DateTime _selectedDate;
late DateTime _currentMonth;
```

### Data Structures

```dart
class CycleInfo {
  final String currentDay; // "Day 7"
  final String phaseName; // "Follicular Phase"
  final String phaseDescription;
  final int dayInPhase;
  final int totalDaysInPhase;
  final Color phaseColor;
}
```

### FAB Behavior

- **Trigger:** Tap floating action button
- **Action:** Show date picker or navigation menu
- **Color:** Purple (#A37FCE)

### Responsive Behavior

```
Mobile (< 600px):
  - Full width calendar
  - Padding: 16px
  - Card: Full width

Tablet (≥ 600px):
  - Calendar: Centered, max 500px width
  - Card: Centered, same width
```

---

## Screen 2: Fitness Tab (Learn/Plan)

### Visual Layout

```
╔═══════════════════════════════════╗
║  < Jan 15, 2024 >                 ║  Date Selector
╚═══════════════════════════════════╝

╔═══════════════════════════════════╗
║  LEARN CARD                       ║
║                                   ║
║  ► [Light Intensity] ➜           ║  Tappable selector
║    Tap to change                  ║
║                                   ║
╚═══════════════════════════════════╝

                [16px spacer]

╔═══════════════════════════════════╗
║  PLAN CARD                        ║
║                                   ║
║  Today's Workouts:               ║
║  • Yoga              [✎][⇄][✓][🗑]║
║  • Walking           [✎][⇄][✓][🗑]║
║  • Stretching        [✎][⇄][✓][🗑]║
║                                   ║
║  (or hint if empty)               ║
╚═══════════════════════════════════╝

                                    [+] FAB (Blue)
[Hormonal] [Fitness] [Diet] [Fasting]
```

### Component: Learn Card (PlannerCard)

```dart
PlannerCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => showWorkoutModal(context),
        child: Row(
          children: [
            Icon(Icons.arrow_forward, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Light Intensity',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.blue),
          ],
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Tap to change workout mode',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    ],
  ),
)
```

**Styling:**
- Container: PlannerCard (white, 12px radius, elevation: 2)
- Text Color: Blue (#42A5F5)
- Text Decoration: Underline
- Icon: Material forward arrow
- Ripple: Material default on tap
- Padding: 16px (inside card)

### Component: Plan Card (PlannerCard)

```dart
PlannerCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Today\'s Workouts',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 12),
      ref.watch(dailyWorkoutsProvider).when(
        data: (workouts) => workouts.isEmpty
          ? Text(
              'Tap "Light Intensity" to add workouts to today\'s plan',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: workouts.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return WorkoutRow(
                  workout: workout,
                  onEdit: () => editWorkout(context, workout),
                  onSwap: () => swapWorkout(context, workout),
                  onLog: () => logWorkout(context, workout),
                  onDelete: () => deleteWorkout(workout),
                );
              },
            ),
        loading: () => CircularProgressIndicator(),
        error: (err, st) => Text('Error loading workouts'),
      ),
    ],
  ),
)
```

**Styling:**
- Container: PlannerCard
- Title: Body Medium, Semi-bold (w600)
- List: Separated by 8px vertical space
- Empty State: Body Small, gray text
- Loading: Center spinner
- Error: Body Small, error text

### Component: Workout Row

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        workout.name,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit),
          iconSize: 20,
          onPressed: onEdit,
          tooltip: 'Edit workout',
        ),
        IconButton(
          icon: Icon(Icons.swap_horiz),
          iconSize: 20,
          onPressed: onSwap,
          tooltip: 'Swap workout',
        ),
        IconButton(
          icon: Icon(Icons.check_circle_outline),
          iconSize: 20,
          onPressed: onLog,
          tooltip: 'Log workout',
        ),
        IconButton(
          icon: Icon(Icons.delete_outline),
          iconSize: 20,
          onPressed: onDelete,
          tooltip: 'Delete workout',
        ),
      ],
    ),
  ],
)
```

**Styling:**
- Name: Body Medium, truncated if long
- Buttons: 4 icons in row
- Icon Color: Gray (#9E9E9E)
- Icon Size: 20px
- Button Size: 48x48 (touch target)
- Ripple: Material default

### Spacing

```
Learn Card (top):    16px horizontal margin
                     16px padding inside card
                     
Between Cards:       16px (SizedBox)

Plan Card (bottom):  16px horizontal margin
                     16px padding inside card
                     8px between workout items
                     12px after title
```

### Modals

**Modal: Workout Selection**
- Trigger: Tap "Light Intensity" in Learn card
- Title: "Select Workout"
- Type: Bottom sheet, 60% screen height
- Content: Scrollable list with checkboxes
- Actions: Multiple selection, close button

**Modal: Add/Edit Workout**
- Trigger: Tap Edit icon in Plan card
- Content: Form fields
- Actions: Save/Cancel buttons

### State Management

```dart
final dailyWorkoutsProvider = FutureProvider.family<
  List<Workout>,
  DateTime
>((ref, date) async {
  final userId = ref.watch(userIdProvider);
  // Fetch workouts for date
});

// Local state:
late String _workoutMode; // 'Light Intensity', etc.
```

### FAB Behavior

- **Color:** Blue (#42A5F5)
- **Action:** Open add workout dialog
- **Tooltip:** "Add workout"

---

## Screen 3: Diet Tab (Learn/Plan)

### Visual Layout

```
╔═══════════════════════════════════╗
║  < Jan 15, 2024 >                 ║  Date Selector
╚═══════════════════════════════════╝

╔═══════════════════════════════════╗
║  LEARN CARD                       ║
║                                   ║
║  ► [Balanced] ➜                  ║  Tappable selector
║    Tap to change                  ║
║                                   ║
╚═══════════════════════════════════╝

                [16px spacer]

╔═══════════════════════════════════╗
║  PLAN CARD                        ║
║                                   ║
║  Today's Recipes:                ║
║  • Grilled Chicken     [✎][⇄][✓][🗑]║
║  • Quinoa Bowl         [✎][⇄][✓][🗑]║
║  • Green Salad         [✎][⇄][✓][🗑]║
║                                   ║
║  (or hint if empty)               ║
╚═══════════════════════════════════╝

                                    [+] FAB (Green)
[Hormonal] [Fitness] [Diet] [Fasting]
```

### Component: Learn Card (DietCard)

```dart
DietCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => showFoodVibeModal(context),
        child: Row(
          children: [
            Icon(Icons.arrow_forward, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Balanced',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.green),
          ],
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Tap to change food preference',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    ],
  ),
)
```

**Styling:**
- Container: DietCard (white, 12px radius, elevation: 2)
- Text Color: Green (#66BB6A)
- Text Decoration: Underline
- Icon: Material forward arrow
- Padding: 16px (inside card)

### Component: Plan Card (DietCard)

```dart
DietCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Today\'s Recipes',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 12),
      ref.watch(dailyRecipesProvider).when(
        data: (recipes) => recipes.isEmpty
          ? Text(
              'Tap "Balanced" to add recipes to today\'s plan',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: recipes.length,
              separatorBuilder: (_, __) => SizedBox(height: 8),
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return RecipeRow(
                  recipe: recipe,
                  onEdit: () => editRecipe(context, recipe),
                  onSwap: () => swapRecipe(context, recipe),
                  onLog: () => logRecipe(context, recipe),
                  onDelete: () => deleteRecipe(recipe),
                );
              },
            ),
        loading: () => CircularProgressIndicator(),
        error: (err, st) => Text('Error loading recipes'),
      ),
    ],
  ),
)
```

**Styling:**
- Same as Fitness Plan Card
- Color: Green instead of Blue
- Content: Recipes instead of workouts

### Component: Recipe Row

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: Text(
        recipe.name,
        style: Theme.of(context).textTheme.bodyMedium,
        overflow: TextOverflow.ellipsis,
      ),
    ),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(icon: Icon(Icons.edit), onPressed: onEdit),
        IconButton(icon: Icon(Icons.swap_horiz), onPressed: onSwap),
        IconButton(icon: Icon(Icons.check_circle_outline), onPressed: onLog),
        IconButton(icon: Icon(Icons.delete_outline), onPressed: onDelete),
      ],
    ),
  ],
)
```

### Modals

**Modal: Food Vibe Selection**
- Trigger: Tap "Balanced" in Learn card
- Title: "Select Food Preference"
- Options: Balanced, Light, Heavy, Protein-Rich, Vegetarian
- Type: Bottom sheet with checkboxes

**Modal: Add/Edit Recipe**
- Trigger: Tap Edit icon in Plan card
- Content: Recipe form

### State Management

```dart
final dailyRecipesProvider = FutureProvider.family<
  List<Recipe>,
  DateTime
>((ref, date) async {
  final userId = ref.watch(userIdProvider);
  // Fetch recipes for date
});

// Local state:
late String _foodVibe; // 'Balanced', 'Light', etc.
```

### FAB Behavior

- **Color:** Green (#66BB6A)
- **Action:** Open add recipe dialog

---

## Screen 4: Fasting Tab (Learn/Plan)

### Visual Layout

```
╔═══════════════════════════════════╗
║  < Jan 15, 2024 >                 ║  Date Selector
╚═══════════════════════════════════╝

╔═══════════════════════════════════╗
║  LEARN CARD                       ║
║                                   ║
║  ► [13h (Beginner)] ➜            ║  Tappable selector
║    Based on cycle phase            ║
║                                   ║
╚═══════════════════════════════════╝

                [16px spacer]

╔═══════════════════════════════════╗
║  PLAN CARD                        ║
║                                   ║
║  Today's Fasting:                ║
║  Goal: 13 hours                  ║
║  Progress: 8h 30m / 13h          ║
║                                   ║
║  [Start Fasting]  [Log Hours]    ║
║                                   ║
╚═══════════════════════════════════╝

                                    [+] FAB (Orange)
[Hormonal] [Fitness] [Diet] [Fasting]
```

### Component: Learn Card (FastingCard)

```dart
FastingCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => showFastingPreferenceModal(context),
        child: Row(
          children: [
            Icon(Icons.arrow_forward, color: Colors.orange),
            SizedBox(width: 8),
            Text(
              '13h (Beginner)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.orange,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.orange),
          ],
        ),
      ),
      SizedBox(height: 8),
      Text(
        'Based on your cycle phase',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade600,
        ),
      ),
    ],
  ),
)
```

**Styling:**
- Container: FastingCard (white, 12px radius, elevation: 2)
- Text Color: Orange (#FFA726)
- Text Decoration: Underline
- Padding: 16px (inside card)

### Component: Plan Card (FastingCard)

```dart
FastingCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Today\'s Fasting',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 12),
      ref.watch(dailyFastingProvider).when(
        data: (fasting) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Goal: ${fasting.goalHours} hours'),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: fasting.currentHours / fasting.goalHours,
              minHeight: 8,
            ),
            SizedBox(height: 8),
            Text('${fasting.currentHours.toStringAsFixed(1)}h / ${fasting.goalHours}h'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.timer),
                  label: Text('Start Fasting'),
                  onPressed: () => startFasting(context),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.edit),
                  label: Text('Log Hours'),
                  onPressed: () => logFastingHours(context),
                ),
              ],
            ),
          ],
        ),
        loading: () => CircularProgressIndicator(),
        error: (err, st) => Text('Error loading fasting data'),
      ),
    ],
  ),
)
```

**Styling:**
- Title: Body Medium, Semi-bold
- Progress Bar: Orange color, 8px height
- Buttons: Elevated buttons with icons
- Spacing: 8-16px between elements

### Modals

**Modal: Fasting Preference Selection**
- Trigger: Tap "13h (Beginner)" in Learn card
- Title: "Fasting Preference"
- Options:
  - 13h (Beginner)
  - 16h (Intermediate)
  - 18h (Advanced)
  - 20h (Expert)
- Type: Bottom sheet with radio buttons

**Modal: Log Fasting Hours**
- Trigger: Tap "Log Hours" button
- Content: Time picker or text field
- Default: Current fasting progress

### State Management

```dart
final dailyFastingProvider = FutureProvider.family<
  FastingData,
  DateTime
>((ref, date) async {
  final userId = ref.watch(userIdProvider);
  // Fetch fasting data for date
});

class FastingData {
  final int goalHours;
  final double currentHours;
  final DateTime? startTime;
  final DateTime? endTime;
}
```

### FAB Behavior

- **Color:** Orange (#FFA726)
- **Action:** Open log fasting session dialog

---

## Screen 5: Report Tab (Placeholder)

### Visual Layout

```
╔═══════════════════════════════════╗
║  REPORTS                          ║
╚═══════════════════════════════════╝

╔═══════════════════════════════════╗
║                                   ║
║  Report content coming soon...    ║
║                                   ║
║  (Placeholder for future feature) ║
║                                   ║
╚═══════════════════════════════════╝


[Hormonal] [Fitness] [Diet] [Fasting]
```

### Component: Placeholder

```dart
Center(
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.analytics,
          size: 64,
          color: Colors.grey.shade400,
        ),
        SizedBox(height: 16),
        Text(
          'Report content coming soon',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'We\'re preparing comprehensive reports on your cycle data',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    ),
  ),
)
```

**Styling:**
- Icon: Gray, 64px size
- Title: Headline Small, gray
- Subtitle: Body Small, gray
- Centered on screen

### Future Implementation

- Weekly activity summary
- Phase-based recommendations performance
- Fitness achievements
- Dietary logs
- Fasting statistics
- Cycle patterns

---

## Navigation & FAB

### Bottom Navigation Bar

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Hormonal',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.fitness_center),
      label: 'Fitness',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.restaurant),
      label: 'Diet',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.schedule),
      label: 'Fasting',
    ),
  ],
  currentIndex: _currentIndex,
  onTap: (index) => setState(() => _currentIndex = index),
  type: BottomNavigationBarType.fixed,
  backgroundColor: Colors.white,
  elevation: 8,
  selectedItemColor: Colors.blue,
  unselectedItemColor: Colors.grey.shade600,
)
```

**Styling:**
- Background: White
- Height: ~70px (including safe area)
- Shadow: Elevation 8
- Icon Size: 24px
- Label Size: 12px
- Selected Color: Tab-specific (blue for Fitness, etc.)
- Unselected Color: Gray

### Floating Action Button

```dart
Positioned(
  bottom: 70, // Above nav bar
  right: 16,
  child: FloatingActionButton(
    onPressed: () => handleFABTap(context, _currentIndex),
    backgroundColor: tabColors[_currentIndex],
    shape: CircleBorder(),
    elevation: 8,
    child: Icon(
      Icons.add,
      size: 28,
      color: Colors.white,
    ),
  ),
)
```

**Tab-Specific FAB Colors:**
```dart
const Map<int, Color> tabColors = {
  0: Color(0xFFA37FCE), // Hormonal - Purple
  1: Color(0xFF42A5F5), // Fitness - Blue
  2: Color(0xFF66BB6A), // Diet - Green
  3: Color(0xFFFFA726), // Fasting - Orange
  4: Color(0xFF42A5F5), // Report - Blue (fallback)
};
```

**FAB Actions by Tab:**
- Hormonal: Show date/month picker
- Fitness: Add new workout
- Diet: Add new recipe
- Fasting: Start fasting session
- Report: (No action or info)

### Navigation Flow

```
App Start
  ↓
IndexedStack (main container)
  ├─ [0] HormonalScreen
  ├─ [1] FitnessScreen
  │   ├─ WorkoutSelectionModal (on Learn card tap)
  │   ├─ AddWorkoutDialog (on FAB tap)
  │   └─ EditWorkoutDialog (on Edit icon tap)
  ├─ [2] DietScreen
  │   ├─ FoodVibeModal (on Learn card tap)
  │   ├─ AddRecipeDialog (on FAB tap)
  │   └─ EditRecipeDialog (on Edit icon tap)
  ├─ [3] FastingScreen
  │   ├─ FastingPreferenceModal (on Learn card tap)
  │   ├─ LogFastingDialog (on Log button tap)
  │   └─ StartFastingDialog (on Start button tap)
  └─ [4] ReportScreen (not visible in nav, hidden)
```

---

## Component Library

### PlannerCard (Fitness)

**File:** `lib/presentation/widgets/card_sections.dart`

**Usage:** Learn & Plan sections in Fitness tab

```dart
class PlannerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double elevation;

  const PlannerCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
```

### DietCard

**File:** `lib/presentation/widgets/card_sections.dart`

**Usage:** Learn & Plan sections in Diet tab

```dart
class DietCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double elevation;

  const DietCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
```

### FastingCard

**File:** `lib/presentation/widgets/card_sections.dart`

**Usage:** Learn & Plan sections in Fasting tab

```dart
class FastingCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double elevation;

  const FastingCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.elevation = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
```

---

## Modal Dialogs

### 1. Workout Selection Modal

**File:** `lib/presentation/pages/planner_page.dart` (embedded)

**Trigger:** Tap "Light Intensity" text in Learn card

**Structure:**

```dart
showModalBottomSheet(
  context: context,
  builder: (context) => StatefulBuilder(
    builder: (context, setState) => Container(
      padding: EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Workout',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: suggestedWorkouts.length,
              itemBuilder: (context, index) {
                final workout = suggestedWorkouts[index];
                return CheckboxListTile(
                  title: Text(workout.name),
                  value: selectedWorkouts.contains(workout.id),
                  onChanged: (value) {
                    setState(() {
                      if (value ?? false) {
                        selectedWorkouts.add(workout.id);
                      } else {
                        selectedWorkouts.remove(workout.id);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  saveWorkoutSelection(selectedWorkouts);
                  Navigator.pop(context);
                },
                child: Text('Save'),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
)
```

**Styling:**
- Height: 60% of screen
- Title: Headline Small (20px, w600)
- Items: Checkbox list tiles
- Divider: Medium gray
- Buttons: Text & Elevated button

**Data:**
- Suggested workouts from `phaseRecommendationsProvider`
- Suggested based on current cycle phase
- Multiple selection via checkboxes

### 2. Food Vibe Selection Modal

**Similar structure to Workout Modal**

**Trigger:** Tap "Balanced" text in Learn card

**Options:**
- Balanced
- Light & Fresh
- Heavy & Comforting
- Protein-Rich
- Vegetarian

### 3. Fasting Preference Modal

**Similar structure with radio buttons**

**Trigger:** Tap "13h (Beginner)" text in Learn card

**Options:**
- 13h (Beginner)
- 16h (Intermediate)
- 18h (Advanced)
- 20h (Expert)

### 4. Add/Edit Item Dialogs

**Type:** AlertDialog or Modal

**Fields Vary:**
- Workout: Name, duration, intensity
- Recipe: Name, ingredients, calories
- Fasting: Start time, duration, notes

---

## State Management

### Riverpod Providers

```dart
// Current cycle phase (based on selected date)
final cyclePhaseProvider = FutureProvider.family<String, DateTime>((ref, date) async {
  final userId = ref.watch(userIdProvider).value ?? '';
  final supabase = Supabase.instance.client;
  // Fetch phase for date
  return phase;
});

// Phase recommendations (workouts, recipes, fasting hours)
final phaseRecommendationsProvider = FutureProvider.family<PhaseData, String>((ref, phase) async {
  // Fetch recommendations based on phase
  return recommendations;
});

// Daily selections (user's selections for specific date)
final dailySelectionsProvider = FutureProvider.family<DailySelection, DateTime>((ref, date) async {
  final userId = ref.watch(userIdProvider).value ?? '';
  // Fetch selections for date
  return selections;
});

// Current user ID
final userIdProvider = FutureProvider<String>((ref) async {
  final auth = Supabase.instance.client.auth;
  return auth.currentUser?.id ?? '';
});

// User profile
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final userId = ref.watch(userIdProvider).value ?? '';
  // Fetch user profile
  return profile;
});

// Daily workouts for specific date
final dailyWorkoutsProvider = FutureProvider.family<List<Workout>, DateTime>((ref, date) async {
  final selection = ref.watch(dailySelectionsProvider(date));
  return selection.when(
    data: (sel) => fetchWorkouts(sel.workoutIds),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Daily recipes for specific date
final dailyRecipesProvider = FutureProvider.family<List<Recipe>, DateTime>((ref, date) async {
  final selection = ref.watch(dailySelectionsProvider(date));
  return selection.when(
    data: (sel) => fetchRecipes(sel.recipeIds),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Daily fasting data for specific date
final dailyFastingProvider = FutureProvider.family<FastingData, DateTime>((ref, date) async {
  final selection = ref.watch(dailySelectionsProvider(date));
  return selection.when(
    data: (sel) => FastingData(
      goalHours: sel.fastingHours,
      currentHours: calculateFastingHours(sel),
      startTime: sel.fastingStartTime,
      endTime: sel.fastingEndTime,
    ),
    loading: () => FastingData.empty(),
    error: (_, __) => FastingData.empty(),
  );
});
```

### Data Structures

```dart
class PhaseData {
  final String name;
  final String displayName;
  final List<Workout> suggestedWorkouts;
  final List<Recipe> suggestedRecipes;
  final int recommendedFastingHours;
  final String description;
}

class DailySelection {
  final DateTime date;
  final List<String> workoutIds;
  final List<String> recipeIds;
  final int fastingHours;
  final String workoutMode;
  final String foodVibe;
  final DateTime? fastingStartTime;
  final DateTime? fastingEndTime;
}

class UserProfile {
  final String userId;
  final String preferredWorkoutIntensity;
  final String dietaryPreference;
  final int preferredFastingHours;
}

class Workout {
  final String id;
  final String name;
  final int duration; // minutes
  final String intensity;
}

class Recipe {
  final String id;
  final String name;
  final int calories;
  final List<String> ingredients;
}

class FastingData {
  final int goalHours;
  final double currentHours;
  final DateTime? startTime;
  final DateTime? endTime;
}
```

### Local State (in ConsumerStatefulWidget)

```dart
late DateTime _selectedDate;
late DateTime _currentMonth;
late int _currentIndex; // Tab index
late String _selectedFilter; // For modals

@override
void initState() {
  super.initState();
  _selectedDate = DateTime.now();
  _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  _currentIndex = 0;
  _selectedFilter = '';
}
```

---

## Implementation Checklist

### Phase 1: Core Layout
- [ ] Create 5 screen components (Hormonal, Fitness, Diet, Fasting, Report)
- [ ] Implement bottom navigation bar with 4 visible tabs
- [ ] Create IndexedStack for tab switching
- [ ] Implement floating action button with color changing per tab
- [ ] Set up basic routing and navigation

### Phase 2: Hormonal Tab
- [ ] Create calendar grid (7 columns)
- [ ] Implement calendar navigation (prev/next month)
- [ ] Add cycle phase coloring for calendar dates
- [ ] Create cycle info card
- [ ] Connect to cyclePhaseProvider

### Phase 3: Fitness Tab
- [ ] Create Learn Card (PlannerCard wrapper)
- [ ] Create Plan Card (PlannerCard wrapper)
- [ ] Implement workout selector modal
- [ ] Create workout list with action buttons
- [ ] Connect to dailyWorkoutsProvider
- [ ] Implement add/edit workout dialogs

### Phase 4: Diet Tab
- [ ] Create Learn Card (DietCard wrapper)
- [ ] Create Plan Card (DietCard wrapper)
- [ ] Implement food vibe selector modal
- [ ] Create recipe list with action buttons
- [ ] Connect to dailyRecipesProvider
- [ ] Implement add/edit recipe dialogs

### Phase 5: Fasting Tab
- [ ] Create Learn Card (FastingCard wrapper)
- [ ] Create Plan Card (FastingCard wrapper)
- [ ] Implement fasting preference modal
- [ ] Create progress indicator
- [ ] Create action buttons (Start, Log)
- [ ] Connect to dailyFastingProvider

### Phase 6: Modals & Dialogs
- [ ] Workout selection modal
- [ ] Food vibe selection modal
- [ ] Fasting preference modal
- [ ] Add workout dialog
- [ ] Add recipe dialog
- [ ] Add/edit fasting dialog
- [ ] Date picker (for navigation)

### Phase 7: State Management
- [ ] Implement all Riverpod providers
- [ ] Connect Supabase backend
- [ ] Test provider data flow
- [ ] Implement error handling
- [ ] Add loading states

### Phase 8: Styling & Polish
- [ ] Apply color system
- [ ] Apply typography system
- [ ] Apply spacing system
- [ ] Test on multiple screen sizes
- [ ] Responsive design adjustments
- [ ] Animation & transitions

### Phase 9: Testing
- [ ] Unit tests for providers
- [ ] Widget tests for components
- [ ] Integration tests for navigation
- [ ] Manual testing on devices
- [ ] Performance testing

### Phase 10: Accessibility
- [ ] Add semantics labels
- [ ] Test with screen readers
- [ ] Verify color contrast
- [ ] Test touch target sizes
- [ ] Test keyboard navigation

---

## Export Notes for FlutterFlow

### Required Custom Code
- `PlannerCard` component (in card_sections.dart)
- `DietCard` component (in card_sections.dart)
- `FastingCard` component (in card_sections.dart)
- Calendar grid custom widget (if FlutterFlow doesn't have native support)

### FlutterFlow Configuration

**Theme Settings:**
```
Material 3: Enabled
Seed Color: #42A5F5 (Blue)
Brightness: Light
Font Family: Roboto (or system default)

Card Theme:
  - Elevation: 2
  - Border Radius: 12px
  - Color: White

Button Theme:
  - Border Radius: 8px
  - Elevation: 1

FAB Theme:
  - Size: 56x56
  - Elevation: 8
```

**Navigation:**
- Bottom Navigation with 4 visible items
- 5th item (Report) can be added later
- Use IndexedStack for tab switching

**Pages to Create:**
1. PlannerPage (main container)
   - HormonalScreen
   - FitnessScreen
   - DietScreen
   - FastingScreen
   - ReportScreen

**Modals/Dialogs:**
1. WorkoutSelectionModal
2. FoodVibeSelectionModal
3. FastingPreferenceModal
4. AddWorkoutDialog
5. EditWorkoutDialog
6. AddRecipeDialog
7. EditRecipeDialog
8. LogFastingDialog

**Provider Integration:**
- Connect Supabase as backend
- Set up all providers shown in State Management section
- Use `.when()` for loading/error states
- Implement error handling UI

---

## Visual Specifications Summary

```
SPACING
├─ Between Cards: 16px (SizedBox height)
├─ Card Padding: 16px (all sides)
├─ Item Separation: 8px
├─ Section Gap: 12px (title to content)
└─ Screen Margins: 16px

COLORS
├─ Card Background: White (#FFFFFF)
├─ Card Shadow: 0,2 offset, 8px blur
├─ Primary Text: #212121
├─ Secondary Text: #757575
├─ Tab Colors:
│  ├─ Hormonal: Purple #A37FCE
│  ├─ Fitness: Blue #42A5F5
│  ├─ Diet: Green #66BB6A
│  └─ Fasting: Orange #FFA726
└─ Interactive: Tab-specific color (underline, buttons)

TYPOGRAPHY
├─ Headlines: 20px, w600 (modals)
├─ Body Medium: 16px, w400 (main)
├─ Body Small: 14px, w400 (secondary)
└─ Labels: 12px, w500 (nav tabs)

BORDERS & SHAPES
├─ Card Radius: 12px
├─ Button Radius: 8px
├─ FAB Shape: Circle 56x56
├─ Calendar Cell: Circle (current), square (other)
└─ Dividers: Medium gray, 1px

ELEVATION
├─ Cards: 2
├─ FAB: 8
├─ Navigation: 8
└─ Modals: 24 (system default)
```

---

**End of FlutterFlow Design Guide**  
*Ready for implementation in FlutterFlow*  
*All screens documented with complete specifications*
