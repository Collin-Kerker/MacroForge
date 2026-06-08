class RecipeSummary {
  final String id;
  final String name;
  final String? description;
  final String? mealType;
  final int? prepMinutes;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  RecipeSummary({
    required this.id,
    required this.name,
    this.description,
    this.mealType,
    this.prepMinutes,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory RecipeSummary.fromJson(Map<String, dynamic> json) => RecipeSummary(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        mealType: json['meal_type'],
        prepMinutes: json['prep_minutes'],
        kcal: json['kcal_per_serving'],
        protein: json['protein_g_per_serving'],
        carbs: json['carbs_g_per_serving'],
        fat: json['fat_g_per_serving'],
      );
}

class RecipeIngredient {
  final String item;
  final String amount;
  RecipeIngredient({required this.item, required this.amount});
  factory RecipeIngredient.fromJson(Map<String, dynamic> j) =>
      RecipeIngredient(item: j['item'] ?? '', amount: j['amount'] ?? '');
}

class RecipeDetail {
  final String id;
  final String name;
  final String? description;
  final String? mealType;
  final int servings;
  final int? prepMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;

  RecipeDetail({
    required this.id,
    required this.name,
    this.description,
    this.mealType,
    required this.servings,
    this.prepMinutes,
    required this.ingredients,
    required this.steps,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory RecipeDetail.fromJson(Map<String, dynamic> json) => RecipeDetail(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        mealType: json['meal_type'],
        servings: json['servings'],
        prepMinutes: json['prep_minutes'],
        ingredients: (json['ingredients'] as List)
            .map((e) => RecipeIngredient.fromJson(e))
            .toList(),
        steps: (json['steps'] as List).map((e) => e.toString()).toList(),
        kcal: json['kcal_per_serving'],
        protein: json['protein_g_per_serving'],
        carbs: json['carbs_g_per_serving'],
        fat: json['fat_g_per_serving'],
      );
}