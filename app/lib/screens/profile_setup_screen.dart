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
  bool _imperial = true; // US audience defaults to imperial

  String _sex = 'male';
  String _activity = 'moderate';
  String _goal = 'maintain';
  DateTime? _birthdate;

  // metric controllers
  final _heightCmCtrl = TextEditingController();
  final _weightKgCtrl = TextEditingController();
  // imperial controllers
  final _heightFtCtrl = TextEditingController();
  final _heightInCtrl = TextEditingController();
  final _weightLbCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _heightCmCtrl.dispose();
    _weightKgCtrl.dispose();
    _heightFtCtrl.dispose();
    _heightInCtrl.dispose();
    _weightLbCtrl.dispose();
    super.dispose();
  }

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
      if (lb == null) return null;
      return lb * 0.45359237;
    }
    return double.tryParse(_weightKgCtrl.text);
  }

  Future<void> _submit() async {
    final heightCm = _resolveHeightCm();
    final weightKg = _resolveWeightKg();

    if (_birthdate == null) {
      setState(() => _error = 'Please select your birthdate.');
      return;
    }
    if (heightCm == null || heightCm <= 0) {
      setState(() => _error = 'Please enter a valid height.');
      return;
    }
    if (weightKg == null || weightKg <= 0) {
      setState(() => _error = 'Please enter a valid weight.');
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
          activityLevel: _activity,
          goal: _goal,
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
    } else {
      context.go('/'); // profile complete -> home
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
                // unit toggle
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Imperial')),
                    ButtonSegment(value: false, label: Text('Metric')),
                  ],
                  selected: {_imperial},
                  onSelectionChanged: (s) => setState(() => _imperial = s.first),
                ),
                const SizedBox(height: 20),

                // sex
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

                // birthdate
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

                // weight
                TextField(
                  controller: _imperial ? _weightLbCtrl : _weightKgCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _imperial ? 'Weight (lb)' : 'Weight (kg)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // activity
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
                const SizedBox(height: 16),

                // goal
                DropdownButtonFormField<String>(
                  initialValue: _goal,
                  decoration: const InputDecoration(labelText: 'Goal', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'cut', child: Text('Lose weight')),
                    DropdownMenuItem(value: 'maintain', child: Text('Maintain')),
                    DropdownMenuItem(value: 'bulk', child: Text('Gain weight')),
                  ],
                  onChanged: (v) => setState(() => _goal = v!),
                ),

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