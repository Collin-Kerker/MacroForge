class SolvedSlot {
  final int slotIndex;
  final String slot;
  final String recipeId;
  final String name;
  final double servings;
  final int kcal;
  final int protein;
  final int carbs;
  final int fat;
  final bool locked;
  final bool cooked;

  SolvedSlot({
    required this.slotIndex,
    required this.slot,
    required this.recipeId,
    required this.name,
    required this.servings,
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.locked = false,
    this.cooked = false,
  });

  factory SolvedSlot.fromJson(Map<String, dynamic> j) => SolvedSlot(
        slotIndex: j['slot_index'] ?? 0,
        slot: j['slot'],
        recipeId: j['recipe_id'],
        name: j['name'],
        servings: (j['servings'] as num).toDouble(),
        kcal: j['kcal'],
        protein: j['protein'],
        carbs: j['carbs'],
        fat: j['fat'],
        locked: j['locked'] ?? false,
        cooked: j['cooked'] ?? false,
      );
}

class SolvedDay {
  final bool feasible;
  final String? reason;
  final List<SolvedSlot> slots;
  final Map<String, dynamic>? totals;
  final Map<String, dynamic>? targets;
  final Map<String, dynamic>? deviation;

  SolvedDay({
    required this.feasible,
    this.reason,
    this.slots = const [],
    this.totals,
    this.targets,
    this.deviation,
  });

  factory SolvedDay.fromJson(Map<String, dynamic> j) => SolvedDay(
        feasible: j['feasible'] ?? false,
        reason: j['reason'],
        slots: (j['slots'] as List? ?? []).map((e) => SolvedSlot.fromJson(e)).toList(),
        totals: j['totals'],
        targets: j['targets'],
        deviation: j['deviation'],
      );
}