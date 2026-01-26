import 'package:flutter/widgets.dart';

class _FastingModalState extends InheritedWidget {
  final bool isAdvanced;
  final double customHours;

  _FastingModalState({
    required this.isAdvanced,
    required this.customHours,
    required super.child,
  });

  @override
  bool updateShouldNotify(_FastingModalState oldWidget) {
    return isAdvanced != oldWidget.isAdvanced || customHours != oldWidget.customHours;
  }
}