import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacroInput extends StatefulWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final Function(String)? onChanged;
  final bool allowDecimals;

  const MacroInput({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    this.onChanged,
    this.allowDecimals = false,
  });

  @override
  State<MacroInput> createState() => _MacroInputState();
}

class _MacroInputState extends State<MacroInput> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Icon(widget.icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 36,
            child: TextFormField(
              controller: widget.controller,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.allowDecimals),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
                LengthLimitingTextInputFormatter(7),
                _MacroInputFormatter(),
              ],
              decoration: InputDecoration(
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                errorStyle: const TextStyle(fontSize: 10, height: 0.8),
              ),
              onChanged: widget.onChanged,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Allow empty field
                }

                // Validate format: 1-4 digits, optional decimal, 0-2 decimal digits
                final regex = RegExp(r'^\d{1,4}(\.\d{0,2})?$');
                if (!regex.hasMatch(value)) {
                  return 'Invalid format';
                }

                // Validate total length
                if (value.length > 7) {
                  return 'Max 7 chars';
                }

                return null;
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroInputFormatter extends TextInputFormatter {
  final RegExp _validFormat = RegExp(r'^\d{0,4}(\.\d{0,2})?$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty value
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Check if the new value matches our valid format
    if (_validFormat.hasMatch(newValue.text)) {
      return newValue;
    }

    // If not valid, return the old value
    return oldValue;
  }
}
