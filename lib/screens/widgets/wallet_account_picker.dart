import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';

import '../../core/app_constants.dart';
import '../../data/model/wallet.dart';

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
      return const Text(
        'Add an account in Manage wallets before recording this transaction.',
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
