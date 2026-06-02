class Profile {
  final String? sex;
  final DateTime? birthdate;
  final double? heightCm;
  final double? currentWeightKg;
  final String? activityLevel;
  final String? goal;
  final double? goalRateKgPerWeek;
  final int? targetCalories;
  final int? targetProteinG;
  final int? targetCarbsG;
  final int? targetFatG;
  final String targetSource;
  final bool profileComplete;

  Profile({
    this.sex,
    this.birthdate,
    this.heightCm,
    this.currentWeightKg,
    this.activityLevel,
    this.goal,
    this.goalRateKgPerWeek,
    this.targetCalories,
    this.targetProteinG,
    this.targetCarbsG,
    this.targetFatG,
    this.targetSource = 'formula',
    this.profileComplete = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      sex: json['sex'],
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'])
          : null,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble(),
      activityLevel: json['activity_level'],
      goal: json['goal'],
      goalRateKgPerWeek: (json['goal_rate_kg_per_week'] as num?)?.toDouble(),
      targetCalories: json['target_calories'],
      targetProteinG: json['target_protein_g'],
      targetCarbsG: json['target_carbs_g'],
      targetFatG: json['target_fat_g'],
      targetSource: json['target_source'] ?? 'formula',
      profileComplete: json['profile_complete'] ?? false,
    );
  }
}