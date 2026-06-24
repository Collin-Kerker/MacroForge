class PrepItem {
  final String recipeId;
  final String name;
  final double totalServings;
  final String category;
  PrepItem({required this.recipeId, required this.name,
            required this.totalServings, required this.category});
  factory PrepItem.fromJson(Map<String, dynamic> j) => PrepItem(
        recipeId: j['recipe_id'] ?? '',
        name: j['name'] ?? '',
        totalServings: (j['total_servings'] as num?)?.toDouble() ?? 0,
        category: j['category'] ?? '',
      );
}

class PrepGroup {
  final String category;
  final String label;
  final List<PrepItem> items;
  PrepGroup({required this.category, required this.label, required this.items});
  factory PrepGroup.fromJson(Map<String, dynamic> j) => PrepGroup(
        category: j['category'] ?? '',
        label: j['label'] ?? '',
        items: (j['items'] as List? ?? []).map((e) => PrepItem.fromJson(e)).toList(),
      );
}

class PrepMeal {
  final String recipeId;
  final String name;
  final double servings;
  final String slot;
  PrepMeal({required this.recipeId, required this.name,
            required this.servings, required this.slot});
  factory PrepMeal.fromJson(Map<String, dynamic> j) => PrepMeal(
        recipeId: j['recipe_id'] ?? '',
        name: j['name'] ?? '',
        servings: (j['servings'] as num?)?.toDouble() ?? 1,
        slot: j['slot'] ?? '',
      );
}

class PrepDay {
  final String day;
  final List<PrepMeal> meals;
  PrepDay({required this.day, required this.meals});
  factory PrepDay.fromJson(Map<String, dynamic> j) => PrepDay(
        day: j['day'] ?? '',
        meals: (j['meals'] as List? ?? []).map((e) => PrepMeal.fromJson(e)).toList(),
      );
}

class PrepPlan {
  final String cadence;          // 'batch' | 'rolling'
  final int? prepDay;            // batch only
  final List<PrepGroup> groups; // batch
  final List<PrepDay> days;     // rolling
  PrepPlan({required this.cadence, this.prepDay,
            this.groups = const [], this.days = const []});
  factory PrepPlan.fromJson(Map<String, dynamic> json) => PrepPlan(
        cadence: json['cadence'] ?? 'batch',
        prepDay: json['prep_day'],
        groups: (json['groups'] as List? ?? []).map((e) => PrepGroup.fromJson(e)).toList(),
        days: (json['days'] as List? ?? []).map((e) => PrepDay.fromJson(e)).toList(),
      );
}