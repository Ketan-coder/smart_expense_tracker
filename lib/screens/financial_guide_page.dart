import 'package:flutter/material.dart';

import '../services/langs/localzation_extension.dart';

class FinancialGuidePage extends StatelessWidget {
  const FinancialGuidePage({super.key});

  static const _sections = [
    ('guide_transactions_title', 'guide_transactions_body'),
    ('guide_wallets_title', 'guide_wallets_body'),
    ('guide_loans_title', 'guide_loans_body'),
    ('guide_goals_title', 'guide_goals_body'),
    ('guide_recurring_sms_title', 'guide_recurring_sms_body'),
    ('guide_reports_title', 'guide_reports_body'),
    ('guide_profiles_title', 'guide_profiles_body'),
    ('guide_limits_title', 'guide_limits_body'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('financial_guide'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.t('financial_guide_intro'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final (titleKey, bodyKey) in _sections)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                title: Text(context.t(titleKey)),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t(bodyKey),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
