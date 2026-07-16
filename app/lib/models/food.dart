class FoodItem {
  final int id;
  final String description;
  final double? kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;

  FoodItem({
    required this.id,
    required this.description,
    this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => FoodItem(
        id: json['id'],
        description: json['description'],
        kcalPer100g: (json['kcal_per_100g'] as num?)?.toDouble(),
        proteinPer100g: (json['protein_per_100g'] as num?)?.toDouble(),
        carbsPer100g: (json['carbs_per_100g'] as num?)?.toDouble(),
        fatPer100g: (json['fat_per_100g'] as num?)?.toDouble(),
      );
}

class FoodLogEntry {
  final String id;
  final int? foodItemId;
  final String? recipeId;
  final String source;
  final double? grams;
  final String description;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  FoodLogEntry({
    required this.id,
    this.foodItemId,
    this.recipeId,
    this.source = 'usda',
    this.grams,
    required this.description,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  factory FoodLogEntry.fromJson(Map<String, dynamic> j) => FoodLogEntry(
        id: j['id'],
        foodItemId: j['food_item_id'],
        recipeId: j['recipe_id'],
        source: j['source'] ?? 'usda',
        grams: (j['grams'] as num?)?.toDouble(),
        description: j['description'],
        kcal: (j['kcal'] as num).toDouble(),
        proteinG: (j['protein_g'] as num).toDouble(),
        carbsG: (j['carbs_g'] as num).toDouble(),
        fatG: (j['fat_g'] as num).toDouble(),
      );
}

class DayLog {
  final DateTime logDate;
  final List<FoodLogEntry> entries;
  final double totalKcal;
  final double totalProteinG;
  final double totalCarbsG;
  final double totalFatG;

  DayLog({
    required this.logDate,
    required this.entries,
    required this.totalKcal,
    required this.totalProteinG,
    required this.totalCarbsG,
    required this.totalFatG,
  });

  factory DayLog.fromJson(Map<String, dynamic> json) => DayLog(
        logDate: DateTime.parse(json['log_date']),
        entries: (json['entries'] as List)
            .map((e) => FoodLogEntry.fromJson(e))
            .toList(),
        totalKcal: (json['total_kcal'] as num).toDouble(),
        totalProteinG: (json['total_protein_g'] as num).toDouble(),
        totalCarbsG: (json['total_carbs_g'] as num).toDouble(),
        totalFatG: (json['total_fat_g'] as num).toDouble(),
      );
}