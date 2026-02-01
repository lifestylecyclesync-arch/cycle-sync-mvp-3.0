import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cycle_sync_mvp_2/data/models/learn_template_model.dart';
import 'package:cycle_sync_mvp_2/data/repositories/templates_repository.dart';

// Repository provider
final templatesRepositoryProvider = Provider((ref) {
  return TemplatesRepository();
});

/// Fetch all active templates for a category
/// Usage: watch(templatesByCategoryProvider('Fitness'))
final templatesByCategoryProvider =
    FutureProvider.autoDispose.family<List<LearnTemplate>, String>((ref, category) {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getTemplatesByCategory(category);
});

/// Get a specific template by ID
/// Usage: watch(templateByIdProvider('template-uuid'))
final templateByIdProvider =
    FutureProvider.autoDispose.family<LearnTemplate?, String>((ref, id) {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getTemplateById(id);
});

/// Get template by category and order (for deterministic selection)
/// Usage: watch(templateByCategoryAndOrderProvider(('Fitness', 3)))
final templateByCategoryAndOrderProvider = FutureProvider.autoDispose
    .family<LearnTemplate?, (String, int)>((ref, params) {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getTemplateByCategoryAndOrder(params.$1, params.$2);
});

/// Get all templates (admin/reference)
/// Usage: watch(allTemplatesProvider)
final allTemplatesProvider =
    FutureProvider.autoDispose<List<LearnTemplate>>((ref) {
  final repository = ref.watch(templatesRepositoryProvider);
  return repository.getAllTemplates();
});

/// Get a template for a specific day with deterministic randomization
/// This ensures the same template is shown for a given category on the same date
/// Usage: watch(dailyTemplateProvider(('Fitness', DateTime.now())))
final dailyTemplateProvider = FutureProvider.autoDispose
    .family<LearnTemplate?, (String, DateTime)>((ref, params) async {
  final repository = ref.watch(templatesRepositoryProvider);
  final category = params.$1;
  final date = params.$2;

  // Get all templates for this category
  final templates = await repository.getTemplatesByCategory(category);
  if (templates.isEmpty) return null;

  // Deterministic random selection based on date
  final seed = date.year * 10000 + date.month * 100 + date.day;
  final index = seed % templates.length;

  return templates[index];
});
