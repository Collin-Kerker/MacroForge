import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  bool _imperial = true;

  String _sex = 'male';
  String _activity = 'moderate';
  DateTime? _birthdate;

  // metric controllers
  final _heightCmCtrl = TextEditingController();
  final _weightKgCtrl = TextEditingController();
  final _goalWeightKgCtrl = TextEditingController();
  // imperial controllers
  final _heightFtCtrl = TextEditingController();
  final _heightInCtrl = TextEditingController();
  final _weightLbCtrl = TextEditingController();
  final _goalWeightLbCtrl = TextEditingController();

  // rate slider: stored internally as kg/week magnitude
  double _rateKgPerWeek = 0.5;
  // recomp protein slider: stored internally as g/kg
  double _recompProteinGPerKg = 2.2; // 1.0 g/lb default

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // recompute "is recomp" when weights change
    _weightLbCtrl.addListener(_onWeightsChanged);
    _goalWeightLbCtrl.addListener(_onWeightsChanged);
    _weightKgCtrl.addListener(_onWeightsChanged);
    _goalWeightKgCtrl.addListener(_onWeightsChanged);
  }

  @override
  void dispose() {
    _heightCmCtrl.dispose();
    _weightKgCtrl.dispose();
    _goalWeightKgCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();
    _weightLbCtrl.dispose();
    _goalWeightLbCtrl.dispose();
    super.dispose();
  }

  void _onWeightsChanged() => setState(() {});

  // ── conversion helpers ──
  double? _resolveHeightCm() {
    if (_imperial) {
      final ft = double.tryParse(_heightFtCtrl.text);
      final inch = double.tryParse(_heightInCtrl.text) ?? 0;
      if (ft == null) return null;
      return (ft * 12 + inch) * 2.54;
    }
    return double.tryParse(_heightCmCtrl.text);
  }

  double? _resolveWeightKg() {
    if (_imperial) {
      final lb = double.tryParse(_weightLbCtrl.text);
      return lb == null ? null : lb * 0.45359237;
    }
    return double.tryParse(_weightKgCtrl.text);
  }

  double? _resolveGoalWeightKg() {
    if (_imperial) {
      final lb = double.tryParse(_goalWeightLbCtrl.text);
      return lb == null ? null : lb * 0.45359237;
    }
    return double.tryParse(_goalWeightKgCtrl.text);
  }

  // is this a recomp case? (current weight == goal weight, both entered)
  bool get _isRecomp {
    final cur = _resolveWeightKg();
    final goal = _resolveGoalWeightKg();
    if (cur == null || goal == null) return false;
    return (cur - goal).abs() < 0.05; // within ~50g = "same"
  }

  String get _direction {
    final cur = _resolveWeightKg();
    final goal = _resolveGoalWeightKg();
    if (cur == null || goal == null) return '';
    if (_isRecomp) return 'Recomposition';
    return goal < cur ? 'Losing weight' : 'Gaining weight';
  }

  // recomp protein band label
  String _proteinBandLabel(double gPerKg) {
    if (gPerKg < 2.0) return 'Maintenance (standard protein)';
    if (gPerKg < 2.4) return 'Low-protein recomp';
    if (gPerKg < 2.8) return 'High-protein recomp';
    return 'Maximum-protein recomp';
  }

  Future<void> _submit() async {
    final heightCm = _resolveHeightCm();
    final weightKg = _resolveWeightKg();
    final goalWeightKg = _resolveGoalWeightKg();

    if (_birthdate == null) {
      setState(() => _error = 'Please select your birthdate.');
      return;
    }
    if (heightCm == null || heightCm <= 0) {
      setState(() => _error = 'Please enter a valid height.');
      return;
    }
    if (weightKg == null || weightKg <= 0) {
      setState(() => _error = 'Please enter a valid current weight.');
      return;
    }
    if (goalWeightKg == null || goalWeightKg <= 0) {
      setState(() => _error = 'Please enter a valid goal weight.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await ref.read(profileProvider.notifier).save(
          sex: _sex,
          birthdate: _birthdate!,
          heightCm: heightCm,
          weightKg: weightKg,
          goalWeightKg: goalWeightKg,
          activityLevel: _activity,
          rateKgPerWeek: _isRecomp ? 0.0 : _rateKgPerWeek,
          recompProteinGPerKg: _isRecomp ? _recompProteinGPerKg : null,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
    } else {
      context.go('/');
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  @override
  Widget build(BuildContext context) {
    // rate slider display: convert kg->lb for imperial
    final rateDisplay = _imperial
        ? '${(_rateKgPerWeek / 0.45359237).toStringAsFixed(2)} lb/week'
        : '${_rateKgPerWeek.toStringAsFixed(2)} kg/week';

    // protein slider display: g/kg -> g/lb for imperial
    final proteinDisplay = _imperial
        ? '${(_recompProteinGPerKg * 0.45359237).toStringAsFixed(2)} g/lb'
        : '${_recompProteinGPerKg.toStringAsFixed(2)} g/kg';

    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Your Profile')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Imperial')),
                    ButtonSegment(value: false, label: Text('Metric')),
                  ],
                  selected: {_imperial},
                  onSelectionChanged: (s) => setState(() => _imperial = s.first),
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  initialValue: _sex,
                  decoration: const InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                    DropdownMenuItem(value: 'unspecified', child: Text('Prefer not to say')),
                  ],
                  onChanged: (v) => setState(() => _sex = v!),
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _pickBirthdate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Birthdate', border: OutlineInputBorder()),
                    child: Text(
                      _birthdate == null
                          ? 'Tap to select'
                          : '${_birthdate!.year}-${_birthdate!.month.toString().padLeft(2, '0')}-${_birthdate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // height
                if (_imperial)
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _heightFtCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height (ft)', border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextField(
                      controller: _heightInCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height (in)', border: OutlineInputBorder()),
                    )),
                  ])
                else
                  TextField(
                    controller: _heightCmCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                  ),
                const SizedBox(height: 16),

                // current weight
                TextField(
                  controller: _imperial ? _weightLbCtrl : _weightKgCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _imperial ? 'Current Weight (lb)' : 'Current Weight (kg)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // goal weight
                TextField(
                  controller: _imperial ? _goalWeightLbCtrl : _goalWeightKgCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _imperial ? 'Goal Weight (lb)' : 'Goal Weight (kg)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),

                // direction indicator
                if (_direction.isNotEmpty)
                  Text(_direction, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _activity,
                  decoration: const InputDecoration(labelText: 'Activity Level', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'sedentary', child: Text('Sedentary')),
                    DropdownMenuItem(value: 'light', child: Text('Lightly active')),
                    DropdownMenuItem(value: 'moderate', child: Text('Moderately active')),
                    DropdownMenuItem(value: 'active', child: Text('Very active')),
                    DropdownMenuItem(value: 'very_active', child: Text('Extremely active')),
                  ],
                  onChanged: (v) => setState(() => _activity = v!),
                ),
                const SizedBox(height: 24),

                // RATE slider — hidden for recomp (rate is meaningless at maintenance)
                if (!_isRecomp) ...[
                  Text('Target rate: $rateDisplay'),
                  Slider(
                    value: _rateKgPerWeek,
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    label: rateDisplay,
                    onChanged: (v) => setState(() => _rateKgPerWeek = v),
                  ),
                ],

                // RECOMP protein slider — only when current == goal weight
                if (_isRecomp) ...[
                  const SizedBox(height: 8),
                  Text('Protein: $proteinDisplay', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_proteinBandLabel(_recompProteinGPerKg),
                       style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                  Slider(
                    value: _recompProteinGPerKg,
                    min: 1.8,
                    max: 3.0,
                    divisions: 24,
                    label: proteinDisplay,
                    onChanged: (v) => setState(() => _recompProteinGPerKg = v),
                  ),
                ],

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Calculate My Targets'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}