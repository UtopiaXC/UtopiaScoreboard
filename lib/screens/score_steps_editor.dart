import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Editor for customizing the score step values.
class ScoreStepsEditor extends StatefulWidget {
  const ScoreStepsEditor({super.key});

  @override
  State<ScoreStepsEditor> createState() => _ScoreStepsEditorState();
}

class _ScoreStepsEditorState extends State<ScoreStepsEditor> {
  List<int> _steps = [1, 2, 4, 8, 16, 32, 64, 128];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSteps();
  }

  Future<void> _loadSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final stepsJson = prefs.getString('global_score_steps');
    if (stepsJson != null) {
      _steps = (jsonDecode(stepsJson) as List<dynamic>).cast<int>();
    }
    setState(() => _loaded = true);
  }

  Future<void> _saveSteps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_score_steps', jsonEncode(_steps));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A202C),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('分数控制',
            style: GoogleFonts.notoSansSc(fontWeight: FontWeight.w600)),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _steps = [1, 2, 4, 8, 16, 32, 64, 128]);
              _saveSteps();
            },
            child: Text('重置默认',
                style: GoogleFonts.notoSansSc(color: Colors.white54)),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('当前分数步长',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('点击数字可编辑，长按可删除，点击 + 添加新步长',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 12)),
                  const SizedBox(height: 16),
                  _StepChips(
                    steps: _steps,
                    onEdit: _editStep,
                    onRemove: (index) {
                      setState(() => _steps.removeAt(index));
                      _saveSteps();
                    },
                    onAdd: _addStep,
                  ),
                  const SizedBox(height: 24),
                  Text('预览',
                      style: GoogleFonts.notoSansSc(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  _StepPreview(steps: _steps),
                ],
              ),
            ),
    );
  }

  void _editStep(int index) {
    final ctrl = TextEditingController(text: '${_steps[index]}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A202C),
        title:
            Text('编辑步长', style: GoogleFonts.notoSansSc(color: Colors.white)),
        content: _stepInput(ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: GoogleFonts.notoSansSc(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) {
                setState(() => _steps[index] = v);
                _saveSteps();
              }
              Navigator.pop(ctx);
            },
            child: Text('确认',
                style: GoogleFonts.notoSansSc(
                    color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );
  }

  void _addStep() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A202C),
        title:
            Text('添加步长', style: GoogleFonts.notoSansSc(color: Colors.white)),
        content: _stepInput(ctrl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('取消',
                style: GoogleFonts.notoSansSc(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) {
                setState(() {
                  _steps.add(v);
                  _steps.sort();
                });
                _saveSteps();
              }
              Navigator.pop(ctx);
            },
            child: Text('添加',
                style: GoogleFonts.notoSansSc(
                    color: const Color(0xFF667EEA))),
          ),
        ],
      ),
    );
  }

  Widget _stepInput(TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      autofocus: true,
      keyboardType: TextInputType.number,
      style: GoogleFonts.notoSansSc(color: Colors.white),
      decoration: InputDecoration(
        hintText: '输入数字',
        hintStyle: GoogleFonts.notoSansSc(color: Colors.white30),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _StepChips extends StatelessWidget {
  final List<int> steps;
  final void Function(int index) onEdit;
  final void Function(int index) onRemove;
  final VoidCallback onAdd;

  const _StepChips({
    required this.steps,
    required this.onEdit,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...steps.asMap().entries.map((entry) {
          return GestureDetector(
            onTap: () => onEdit(entry.key),
            onLongPress: () => onRemove(entry.key),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF667EEA).withOpacity(0.3)),
              ),
              child: Text('${entry.value}',
                  style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
            ),
          );
        }),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child:
                Icon(Icons.add, color: Colors.white.withOpacity(0.5), size: 20),
          ),
        ),
      ],
    );
  }
}

class _StepPreview extends StatelessWidget {
  final List<int> steps;
  const _StepPreview({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: steps
              .map((step) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$step',
                          style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 13)),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

