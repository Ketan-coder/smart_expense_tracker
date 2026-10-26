import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/langs/localzation_extension.dart';
import '../services/profile_service.dart';

Uri financialGuideReportUri({required String subject, required String body}) =>
    Uri.parse(
      'mailto:ketanv288@gmail.com'
      '?subject=${Uri.encodeComponent(subject)}'
      '&body=${Uri.encodeComponent(body)}',
    );

class FinancialGuidePage extends StatelessWidget {
  const FinancialGuidePage({super.key});

  static const _sections = [
    ('guide_transactions_title', 'guide_transactions_body', Icons.swap_horiz),
    ('guide_wallets_title', 'guide_wallets_body', Icons.account_balance_wallet),
    ('guide_loans_title', 'guide_loans_body', Icons.handshake_outlined),
    ('guide_goals_title', 'guide_goals_body', Icons.flag_outlined),
    ('guide_recurring_sms_title', 'guide_recurring_sms_body', Icons.autorenew),
    ('guide_reports_title', 'guide_reports_body', Icons.bar_chart),
    ('guide_check_title', 'guide_check_body', Icons.fact_check_outlined),
    ('guide_profiles_title', 'guide_profiles_body', Icons.people_alt_outlined),
    ('guide_limits_title', 'guide_limits_body', Icons.info_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final profile = ProfileService.instance.activeProfile;

    return Scaffold(
      appBar: AppBar(title: Text(context.t('financial_guide'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            context.t('financial_guide_intro'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          _MoneyFlowExample(
            colors: colors,
            currencyCode: profile.currencyCode,
            currencySymbol: profile.currencySymbol,
          ),
          const SizedBox(height: 24),
          Text(
            context.t('guide_how_it_works'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < _sections.length; index++)
            _GuideSectionCard(
              title: context.t(_sections[index].$1),
              body: context.t(_sections[index].$2),
              icon: _sections[index].$3,
              color: _sectionColor(colors, index),
            ),
          const SizedBox(height: 20),
          _ReportIssueCard(colors: colors),
        ],
      ),
    );
  }

  Color _sectionColor(ColorScheme colors, int index) => switch (index % 4) {
    0 => colors.primary,
    1 => colors.tertiary,
    2 => colors.secondary,
    _ => colors.error,
  };
}

class _MoneyFlowExample extends StatelessWidget {
  const _MoneyFlowExample({
    required this.colors,
    required this.currencyCode,
    required this.currencySymbol,
  });

  final ColorScheme colors;
  final String currencyCode;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Card(
      color: colors.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('guide_example_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  currencyCode,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _MoneyFlowRow(
              label: context.t('guide_example_opening'),
              amount: '${currencySymbol}50,000',
              color: colors.secondary,
            ),
            const SizedBox(height: 8),
            _MoneyFlowRow(
              label: context.t('income'),
              amount: '+ ${currencySymbol}55,000',
              color: Colors.green.shade700,
            ),
            const SizedBox(height: 8),
            _MoneyFlowRow(
              label: context.t('expense'),
              amount: '− ${currencySymbol}35,000',
              color: colors.error,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1),
            ),
            _MoneyFlowRow(
              label: context.t('guide_example_wallet_now'),
              amount: '${currencySymbol}70,000',
              color: colors.primary,
              emphasize: true,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context
                    .t('guide_example_reports')
                    .replaceAll('{income}', '${currencySymbol}55,000')
                    .replaceAll('{expense}', '${currencySymbol}35,000'),
                style: textStyle?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.t('guide_example_note'),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyFlowRow extends StatelessWidget {
  const _MoneyFlowRow({
    required this.label,
    required this.amount,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String amount;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.bold : null,
            ),
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.14),
              foregroundColor: color,
              child: Icon(icon, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    body,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportIssueCard extends StatelessWidget {
  const _ReportIssueCard({required this.colors});

  final ColorScheme colors;

  Future<void> _reportIssue(BuildContext context) async {
    final uri = financialGuideReportUri(
      subject: context.t('guide_report_subject'),
      body: context.t('guide_report_body'),
    );
    final launched = await launchUrl(uri);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.t('guide_report_failed'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline, color: colors.onSecondaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.t('guide_report_issue'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.t('guide_report_subtitle'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _reportIssue(context),
              icon: const Icon(Icons.outgoing_mail),
              label: Text(context.t('guide_report_button')),
            ),
          ],
        ),
      ),
    );
  }
}
