# Development Best Practices - Cycle Sync MVP 2

## Core Principles: Modular & Scalable Code

### ❌ Anti-Patterns (What Not To Do)

1. **Large Multi-Line String Replacements**
   - ❌ Replacing 200+ lines at once
   - ❌ Changing deeply nested structures with single operations
   - Risk: Bracket mismatches, scope violations, const expression conflicts
   - Why it fails: `dart analyze` passes but `flutter build` fails - syntax vs semantic gap

2. **Deep Nesting (8+ Levels)**
   - ❌ Card → Padding → Column → SingleChildScrollView → Column → ListView → Container → Text
   - Risk: Variable scope issues, const context violations
   - Result: "Undefined name" errors in nested contexts

3. **Monolithic Widget Files**
   - ❌ All styling logic inline with business logic
   - ❌ Repetitive Card + Padding + Margin patterns
   - Risk: Code duplication, maintenance burden, error-prone edits

### ✅ Best Practices (What To Do)

1. **Widget Extraction Pattern**
   ```dart
   // ✅ GOOD: Reusable component encapsulates styling
   class PlannerCard extends StatelessWidget {
     final Widget child;
     final double elevation;
     final double borderRadius;
     final EdgeInsets padding;
     
     const PlannerCard({
       Key? key,
       required this.child,
       this.elevation = 2,
       this.borderRadius = 12,
       this.padding = const EdgeInsets.all(16),
     }) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Card(
         elevation: elevation,
         shape: RoundedRectangleBorder(
           borderRadius: BorderRadius.circular(borderRadius),
         ),
         child: Padding(
           padding: padding,
           child: child,
         ),
       );
     }
   }
   ```

2. **Atomic Edits (Surgical Changes)**
   - Only modify the **outer wrapper layer**
   - Leave all internal content completely untouched
   - Example:
     ```dart
     // ❌ DON'T: Replace entire section
     OLD: return Padding(...) { Card(...) { Column(...) { 200+ lines } } }
     
     // ✅ DO: Replace only wrapper
     OLD: return Padding(padding: ..., child: Column(
     NEW: return PlannerCard(child: Column(
     ```

3. **Modular File Organization**
   - `card_sections.dart`: All reusable Card wrapper components
   - `planner_page.dart`: Business logic only
   - `widgets/`: Common UI components
   - Benefit: Clear separation of concerns, easy to locate styling code

4. **Single Responsibility Per Edit**
   - Import component (1 edit)
   - Replace wrapper (1 edit)
   - Test (2 validation steps: `dart analyze` + `flutter build`)
   - Never chain unrelated changes in one edit session

5. **Validation Strategy**
   ```bash
   # Step 1: Syntax check (catches bracket/import errors)
   dart analyze lib/presentation/pages/planner_page.dart
   
   # Step 2: Semantic check (catches scope/type errors)
   flutter build apk  # or flutter run -d chrome
   ```
   **Important:** Both must pass. `dart analyze` alone is insufficient.

## Workflow Template

### For Adding Card Styling to Any Section:

```
1. Create reusable widget in card_sections.dart
   └─ New class extending StatelessWidget
   └─ Configure elevation, borderRadius, padding
   └─ Test in isolation (read the file, verify syntax)

2. Add import to target file
   └─ Single line: import 'package:cycle_sync_mvp_2/presentation/widgets/card_sections.dart';
   └─ Use multi_replace_string_in_file (1 operation)

3. Replace outer wrapper only
   └─ Identify Padding/Container opening line
   └─ Replace with new Card component
   └─ Keep all internal content (100+ lines) untouched
   └─ Use multi_replace_string_in_file (1 operation)

4. Validate
   └─ dart analyze (should show 0 errors)
   └─ flutter build (should complete successfully)
```

## Applied Examples

### ✅ Fitness Section (DONE)
- **Component:** `PlannerCard` in `card_sections.dart`
- **Wrapper:** Line 507 - Replaced `Padding(...)` with `PlannerCard(...)`
- **Internal Content:** Lines 511-880 (370 lines) - **COMPLETELY UNTOUCHED**
- **Status:** ✅ Compiles, 0 errors

### Planned: Diet Section
- **Component:** `PlannerCard` (reuse existing)
- **Wrapper:** ~Line 920 - Replace Diet section Padding
- **Internal Content:** 300+ lines - **KEEP UNTOUCHED**

### Planned: Fasting Section
- **Component:** `PlannerCard` (reuse existing)
- **Wrapper:** ~Line 1300 - Replace Fasting section Padding
- **Internal Content:** 300+ lines - **KEEP UNTOUCHED**

## Code Review Checklist

Before committing changes:

- [ ] No edit touches more than 20 lines of actual code change
- [ ] Reusable widgets extracted to `widgets/` or `card_sections.dart`
- [ ] Only wrapper layer modified, internal content untouched
- [ ] `dart analyze` shows 0 errors (warnings okay)
- [ ] `flutter build` completes successfully
- [ ] Tested on at least one platform (APK or web)
- [ ] Related edits grouped in single session, then tested together

## Performance Impact

**Before Modular Approach:**
- Large string replacements: High risk of introducing errors
- Compilation failures: 100-500+ errors requiring full reverts
- Iteration time: 10-20 minutes per failed attempt

**After Modular Approach:**
- Atomic edits: Minimal risk surface
- Compilation success: 0 errors on first attempt
- Iteration time: 2-3 minutes per feature

## Scalability Considerations

1. **Component Libraries**
   - Build a collection of reusable card/section wrappers
   - Future sections (Reports, History, Settings) reuse same patterns
   - No need to reinvent styling for each screen

2. **Testing Strategy**
   - Each reusable widget independently validatable
   - Integration tests after wrapper replacement
   - Faster debugging with isolated components

3. **Maintenance**
   - Styling changes in one place (`card_sections.dart`)
   - Ripple effect across all using screens
   - No need to find and update 10 different sections

## Emergency Procedures

**If compilation fails after your changes:**

1. Revert immediately: `git checkout lib/presentation/pages/planner_page.dart`
2. Check what changed: `git diff lib/presentation/pages/planner_page.dart`
3. Identify the problematic edit (usually 200+ line changes)
4. Redo with atomic approach (1 small edit at a time)
5. Validate after each edit

**If `dart analyze` passes but `flutter build` fails:**

- This indicates a semantic issue, not syntax
- The edit likely created scope/const violations
- Solution: Use widget extraction instead of nested wrapping
- Root cause: Variables pushed outside their accessible scope

## Tools & Commands

```bash
# Syntax validation
dart analyze lib/presentation/pages/planner_page.dart

# Full compilation check
flutter build apk --verbose

# Web testing (faster iteration)
flutter run -d chrome --web-renderer html

# Check file for errors
dart analyze lib/presentation/pages/planner_page.dart 2>&1 | Select-String "error|Error:"

# Git recovery
git checkout lib/presentation/pages/planner_page.dart
git diff lib/presentation/pages/planner_page.dart
```

## Summary

**Modular Approach = Reliability + Scalability + Maintainability**

- Extract reusable components
- Make atomic (small) edits
- Validate with both tools
- Test early and often
- Document the pattern
- Reuse across screens

This approach prevents the 500+ error cascades we experienced earlier and scales to larger codebases.
