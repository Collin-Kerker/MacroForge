// The recurring weekly meal structure: 7 days, each an ordered list of meal-type slots.
class MealPlan {
  // {"mon": ["breakfast","lunch","dinner"], ...}
  final Map<String, List<String>> structure;

  MealPlan({required this.structure});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final raw = json['structure'] as Map<String, dynamic>;
    final structure = <String, List<String>>{};
    for (final entry in raw.entries) {
      structure[entry.key] = (entry.value as List).map((e) => e.toString()).toList();
    }
    return MealPlan(structure: structure);
  }

  Map<String, dynamic> toJson() => {'structure': structure};

  // deep copy so edits don't mutate the loaded state in place
  MealPlan copy() => MealPlan(
        structure: {for (final e in structure.entries) e.key: List<String>.from(e.value)},
      );
}

// Display order + labels
const kDayOrder = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const kDayLabels = {
  'mon': 'Monday',
  'tue': 'Tuesday',
  'wed': 'Wednesday',
  'thu': 'Thursday',
  'fri': 'Friday',
  'sat': 'Saturday',
  'sun': 'Sunday',
};

// The meal types available in the palette
const kMealTypes = ['breakfast', 'lunch', 'dinner', 'snack', 'dessert'];