import 'package:flutter/material.dart';

import '../config/app_theme.dart';

class MemberCountField extends StatelessWidget {
  const MemberCountField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<int>(
          initialValue: value,
          decoration: const InputDecoration(),
          items: [
            for (var count = 2; count <= 30; count++)
              DropdownMenuItem(value: count, child: Text('$count orang')),
          ],
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ],
    );
  }
}
