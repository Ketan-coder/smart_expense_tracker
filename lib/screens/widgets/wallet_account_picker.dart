import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/app_constants.dart';
import '../../data/model/wallet.dart';
import '../../services/langs/localzation_extension.dart';

enum WalletSelectionProblem { walletRequired, walletSelectionRequired }

int? resolveWalletSelection({int? walletKey}) {
  final box = Hive.box<Wallet>(AppConstants.wallets);
  if (walletKey != null) return walletKey;
  final keys = box.keys.whereType<int>().toList();
  return keys.length == 1 ? keys.single : null;
}

WalletSelectionProblem? walletSelectionProblem({int? walletKey}) {
  final box = Hive.box<Wallet>(AppConstants.wallets);
  if (box.isEmpty) return WalletSelectionProblem.walletRequired;
  final selectedKey = resolveWalletSelection(walletKey: walletKey);
  if (selectedKey == null || box.get(selectedKey) == null) {
    return WalletSelectionProblem.walletSelectionRequired;
  }
  return null;
}

String walletSelectionProblemMessage(
  BuildContext context,
  WalletSelectionProblem problem,
) => context.t(
  problem == WalletSelectionProblem.walletRequired
      ? 'transaction_wallet_required'
      : 'transaction_wallet_select',
);

class WalletAccountPicker extends StatelessWidget {
  const WalletAccountPicker({
    required this.walletKey,
    required this.onChanged,
    super.key,
  });

  final int? walletKey;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Wallet>(AppConstants.wallets);
    final accounts = box.keys
        .whereType<int>()
        .map((key) => MapEntry(key, box.get(key)!))
        .toList();
    final selectedKey = accounts.any((entry) => entry.key == walletKey)
        ? walletKey
        : accounts.length == 1
        ? accounts.single.key
        : null;

    if (accounts.isEmpty) {
      return Text(
        context.t('transaction_wallet_required'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: selectedKey,
      decoration: const InputDecoration(
        labelText: 'Account',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Choose account'),
      items: accounts
          .map(
            (entry) => DropdownMenuItem<int>(
              value: entry.key,
              child: Text('${entry.value.name} (${entry.value.type})'),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? 'Select an account' : null,
    );
  }
}
