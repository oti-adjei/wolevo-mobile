import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';

/// One password rule, as worded on the web signup form.
class PasswordRule {
  const PasswordRule(this.label, this.test);

  final String label;
  final bool Function(String) test;
}

/// The four rules the web app renders under the password field the moment the
/// user starts typing (discovery-notes.md § "Password requirements").
const passwordRules = <PasswordRule>[
  PasswordRule('At least 8 characters', _atLeast8),
  PasswordRule('One uppercase letter (A-Z)', _hasUpper),
  PasswordRule('One digit (0-9)', _hasDigit),
  PasswordRule(r'One special character (@#$%^&+=!)', _hasSpecial),
];

bool _atLeast8(String v) => v.length >= 8;
bool _hasUpper(String v) => RegExp(r'[A-Z]').hasMatch(v);
bool _hasDigit(String v) => RegExp(r'[0-9]').hasMatch(v);
bool _hasSpecial(String v) => RegExp(r'[@#$%^&+=!]').hasMatch(v);

/// True when every rule passes. The web form only hard-blocks on the 8-char
/// rule, so callers decide how strict to be.
bool passwordMeetsAllRules(String value) =>
    passwordRules.every((r) => r.test(value));

/// Live checklist. Satisfied rules turn green and swap their bullet for a check.
class PasswordChecklist extends StatelessWidget {
  const PasswordChecklist({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface6,
        borderRadius: AppRadius.rInput,
        border: Border.all(color: AppColors.surface4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rule in passwordRules)
            _RuleRow(label: rule.label, satisfied: rule.test(password)),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.label, required this.satisfied});

  final String label;
  final bool satisfied;

  @override
  Widget build(BuildContext context) {
    final color = satisfied ? AppColors.success2 : AppColors.neutral1;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: satisfied
                ? const Icon(Icons.check, size: 14, color: AppColors.success2)
                : Text('•', style: AppText.caption.copyWith(color: color)),
          ),
          Expanded(
            child: Text(
              label,
              style: (satisfied ? AppText.captionSemibold : AppText.caption)
                  .copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
