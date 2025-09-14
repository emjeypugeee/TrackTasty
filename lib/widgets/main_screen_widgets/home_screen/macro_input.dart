import 'package:flutter/material.dart';

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
    return Expanded(
      child: Padding(
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
                ),
                onChanged: widget.onChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
