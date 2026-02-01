import 'package:cycle_sync_mvp_2/core/config/supabase_config.dart';
import 'package:cycle_sync_mvp_2/data/models/learn_template_model.dart';
import 'package:logger/logger.dart';

class TemplatesRepository {
  final Logger _logger = Logger();

  /// Fetch all active templates for a category
  /// Categories: 'Fitness', 'Diet', 'Fasting'
  Future<List<LearnTemplate>> getTemplatesByCategory(String category) async {
    try {
      final response = await SupabaseConfig.client
          .from('learn_templates')
          .select()
          .eq('category', category)
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (response.isEmpty) {
        _logger.w('No templates found for category: $category');
        return [];
      }

      return List<LearnTemplate>.from(
        response.map((item) => LearnTemplate.fromMap(item)),
      );
    } catch (e) {
      _logger.e('Error fetching templates for $category: $e');
      return [];
    }
  }

  /// Get a template by its ID
  Future<LearnTemplate?> getTemplateById(String id) async {
    try {
      final response = await SupabaseConfig.client
          .from('learn_templates')
          .select()
          .eq('id', id)
          .single();

      return LearnTemplate.fromMap(response);
    } catch (e) {
      _logger.e('Error fetching template by ID: $e');
      return null;
    }
  }

  /// Get a template by category and sort_order (useful for deterministic selection)
  Future<LearnTemplate?> getTemplateByCategoryAndOrder(
    String category,
    int sortOrder,
  ) async {
    try {
      final response = await SupabaseConfig.client
          .from('learn_templates')
          .select()
          .eq('category', category)
          .eq('sort_order', sortOrder)
          .single();

      return LearnTemplate.fromMap(response);
    } catch (e) {
      _logger.e('Error fetching template by category and order: $e');
      return null;
    }
  }

  /// Get all templates (admin/reference only)
  Future<List<LearnTemplate>> getAllTemplates() async {
    try {
      final response = await SupabaseConfig.client
          .from('learn_templates')
          .select()
          .order('category', ascending: true)
          .order('sort_order', ascending: true);

      if (response.isEmpty) {
        _logger.w('No templates found');
        return [];
      }

      return List<LearnTemplate>.from(
        response.map((item) => LearnTemplate.fromMap(item)),
      );
    } catch (e) {
      _logger.e('Error fetching all templates: $e');
      return [];
    }
  }

  /// Create a new template (admin only - in real app, would need auth check)
  Future<LearnTemplate?> createTemplate(LearnTemplate template) async {
    try {
      final response = await SupabaseConfig.client
          .from('learn_templates')
          .insert(template.toMap())
          .select()
          .single();

      _logger.i('Template created: ${template.id}');
      return LearnTemplate.fromMap(response);
    } catch (e) {
      _logger.e('Error creating template: $e');
      return null;
    }
  }

  /// Update an existing template (admin only - in real app, would need auth check)
  Future<LearnTemplate?> updateTemplate(LearnTemplate template) async {
    try {
      final response = await SupabaseConfig.client
          .from('learn_templates')
          .update(template.toMap())
          .eq('id', template.id)
          .select()
          .single();

      _logger.i('Template updated: ${template.id}');
      return LearnTemplate.fromMap(response);
    } catch (e) {
      _logger.e('Error updating template: $e');
      return null;
    }
  }

  /// Delete a template (admin only - in real app, would need auth check)
  Future<void> deleteTemplate(String id) async {
    try {
      await SupabaseConfig.client
          .from('learn_templates')
          .delete()
          .eq('id', id);

      _logger.i('Template deleted: $id');
    } catch (e) {
      _logger.e('Error deleting template: $e');
    }
  }
}
