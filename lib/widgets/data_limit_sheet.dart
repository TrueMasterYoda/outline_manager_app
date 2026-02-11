import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/access_key.dart';
import '../theme/app_theme.dart';

class DataLimitSheet extends StatefulWidget {
  const DataLimitSheet({super.key, this.initialBytes});

  final int? initialBytes;

  @override
  State<DataLimitSheet> createState() => _DataLimitSheetState();
}

class _DataLimitSheetState extends State<DataLimitSheet> {
  late TextEditingController _controller;
  String _unit = 'GB'; // 'MB' or 'GB'
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.initialBytes != null && widget.initialBytes! > 0) {
      if (widget.initialBytes! >= 1000 * 1000 * 1000) {
        _unit = 'GB';
        _controller = TextEditingController(
            text: (widget.initialBytes! / (1000 * 1000 * 1000))
                .toStringAsFixed(2)
                .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''));
      } else {
        _unit = 'MB';
        _controller = TextEditingController(
            text: (widget.initialBytes! / (1000 * 1000))
                .toStringAsFixed(2)
                .replaceAll(RegExp(r'([.]*0+)(?!.*\d)'), ''));
      }
    } else {
      _controller = TextEditingController();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final value = double.tryParse(_controller.text);
    if (value == null) return;

    int bytes;
    if (_unit == 'GB') {
      bytes = (value * 1000 * 1000 * 1000).round();
    } else {
      bytes = (value * 1000 * 1000).round();
    }

    Navigator.pop(context, bytes);
  }

  void _removeLimit() {
    Navigator.pop(context, -1); // -1 indicates removal
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Set Data Limit',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  if (widget.initialBytes != null)
                    TextButton(
                      onPressed: _removeLimit,
                      style: TextButton.styleFrom(
                          foregroundColor: AppTheme.danger),
                      child: const Text('Remove Limit'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _controller,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Limit Amount',
                        hintText: 'e.g. 5',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final n = double.tryParse(value);
                        if (n == null || n <= 0) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      dropdownColor: AppTheme.bgCardLight,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'MB', child: Text('MB')),
                        DropdownMenuItem(value: 'GB', child: Text('GB')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _unit = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Save Limit',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
