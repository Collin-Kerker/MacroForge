import 'solved_day.dart';

class GeneratedDay {
  final bool feasible;
  final bool empty;
  final List<SolvedSlot> slots;
  final Map<String, dynamic>? totals;
  final Map<String, dynamic>? targets;
  final Map<String, dynamic>? deviation;

  GeneratedDay({
    required this.feasible,
    this.empty = false,
    this.slots = const [],
    this.totals,
    this.targets,
    this.deviation,
  });

  factory GeneratedDay.fromJson(Map<String, dynamic> j) => GeneratedDay(
        feasible: j['feasible'] ?? false,
        empty: j['empty'] ?? false,
        slots: (j['slots'] as List? ?? [])
            .map((e) => SolvedSlot.fromJson(e))
            .toList(),
        totals: j['totals'],
        targets: j['targets'],
        deviation: j['deviation'],
      );
}

class GeneratedPlan {
  // day-key -> solved day, in mon..sun order via kDayOrder
  final Map<String, GeneratedDay> days;
  final Map<String, dynamic>? weekTotals;
  final DateTime? generatedAt;

  GeneratedPlan({required this.days, this.weekTotals, this.generatedAt});

  factory GeneratedPlan.fromJson(Map<String, dynamic> json) {
    final week = json['week'] as Map<String, dynamic>;
    final rawDays = (week['days'] as Map<String, dynamic>? ?? {});
    final days = <String, GeneratedDay>{};
    for (final entry in rawDays.entries) {
      days[entry.key] = GeneratedDay.fromJson(entry.value as Map<String, dynamic>);
    }
    return GeneratedPlan(
      days: days,
      weekTotals: week['week_totals'] as Map<String, dynamic>?,
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'])
          : null,
    );
  }
}