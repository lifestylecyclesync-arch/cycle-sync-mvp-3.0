import 'package:flutter/widgets.dart';

class _FastingModalState extends InheritedWidget {
  bool isAdvanced;
  double customHours;

  _FastingModalState({
    required this.isAdvanced,
    required this.customHours,
    required Widget child,
  }) : super(child: child);

  static _FastingModalState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_FastingModalState>();
  }

  @override
  bool updateShouldNotify(_FastingModalState oldWidget) {
    return isAdvanced != oldWidget.isAdvanced || customHours != oldWidget.customHours;
  }
}

class _FastingModalStateProvider extends StatelessWidget {
  final _FastingModalState state;
  final Widget child;
  const _FastingModalStateProvider({required this.state, required this.child});
  @override
  Widget build(BuildContext context) => state;
}