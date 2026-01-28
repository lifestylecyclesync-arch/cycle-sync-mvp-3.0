# Quick Reference: Modular Development Checklist

## 🚀 Before Starting Any Code Change

```
☐ Is this change modular (single responsibility)?
☐ Will this change affect >20 lines of code?
☐ Can this be extracted to a reusable component?
☐ Is this an atomic edit or can it be split?
```

## 📝 The Pattern (Copy-Paste for Any Section Card)

```
1. CREATE COMPONENT (in card_sections.dart)
   ├─ class SectionCard extends StatelessWidget
   ├─ final Widget child
   ├─ return Card(...) with Padding(...)
   └─ Done ✓

2. ADD IMPORT (in target file)
   ├─ import 'package:cycle_sync_mvp_2/presentation/widgets/card_sections.dart';
   └─ Done ✓

3. REPLACE WRAPPER (one section only)
   ├─ OLD: return Padding(padding: ..., child: Column(...));
   ├─ NEW: return SectionCard(child: Column(...));
   └─ Done ✓

4. VALIDATE (run both, both must pass)
   ├─ dart analyze lib/presentation/pages/planner_page.dart
   │  Expected: "X issues found" (0 errors is the key)
   └─ flutter build apk
      Expected: "Built build/app/outputs/..." (successful)
```

## ❌ Red Flags (Stop and Review!)

```
✗ Replacing 200+ lines at once
✗ Nesting depth > 8 levels
✗ dart analyze passes but flutter build fails
✗ "Undefined name" errors after your change
✗ "Can't find ')' to match '('" bracket errors
✗ "Method not found" in const context
✗ Copy-pasting same pattern in multiple places
```

## ✅ Green Flags (Good to Go!)

```
✓ Atomic edit (≤ 20 lines of code change)
✓ Internal content completely untouched
✓ Reusable component created
✓ dart analyze: 0 errors
✓ flutter build: successful
✓ Component documented
✓ Ready to commit
```

## 🔧 Emergency Commands

```bash
# Check file for errors
dart analyze lib/presentation/pages/planner_page.dart

# See errors only (skip warnings)
dart analyze lib/presentation/pages/planner_page.dart 2>&1 | Select-String "error|Error:"

# Build test
flutter build apk

# Fast web test
flutter run -d chrome --web-renderer html

# Revert everything (if build fails)
git checkout lib/presentation/pages/planner_page.dart

# See what changed
git diff lib/presentation/pages/planner_page.dart
```

## 📚 Full Documentation

- For details: Read [DEVELOPMENT_PRACTICES.md](./DEVELOPMENT_PRACTICES.md)
- For implementation: Read [MODULAR_ARCHITECTURE.md](./MODULAR_ARCHITECTURE.md)
- For examples: See [lib/presentation/widgets/card_sections.dart](./lib/presentation/widgets/card_sections.dart)

## 🎯 Remember

> **One Edit → One Validation → Move Forward**

Never chain multiple unrelated changes together. Validate after each logical step.
