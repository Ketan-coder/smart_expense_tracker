import 'package:expense_tracker/screens/widgets/bottom_sheet.dart'
    show BottomSheetUtil;
import 'package:expense_tracker/screens/widgets/snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'dart:ui';
import '../../core/app_constants.dart';
import '../../core/helpers.dart';
import '../../data/model/wallet.dart';
import 'package:expense_tracker/screens/widgets/privacy_overlay_widget.dart';

import '../../services/privacy/privacy_manager.dart';

class StackedWalletCards extends StatefulWidget {
  final List<Wallet> wallets;
  final String currency;
  final bool isPrivate;
  final Function(Wallet, int) onWalletTap;
  final VoidCallback onAddWallet;

  const StackedWalletCards({
    super.key,
    required this.wallets,
    required this.currency,
    required this.isPrivate,
    required this.onWalletTap,
    required this.onAddWallet,
  });

  @override
  State<StackedWalletCards> createState() => _StackedWalletCardsState();
}

class _StackedWalletCardsState extends State<StackedWalletCards>
    with TickerProviderStateMixin {
  late List<AnimationController> _staggerControllers;

  @override
  void initState() {
    super.initState();
    _staggerControllers = [];
    for (int i = 0; i < widget.wallets.length; i++) {
      _staggerControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(StackedWalletCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wallets.length != widget.wallets.length) {
      _staggerControllers.clear();
      for (int i = 0; i < widget.wallets.length; i++) {
        _staggerControllers.add(
          AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 300),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _staggerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showExpandedWallets() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withAlpha(128),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const _ExpandedWalletsDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
              ),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    ).then((_) {
      // Reverse animation not needed as dialog dismisses with its own animation
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: _showExpandedWallets,
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Back Card (if exists)
            if (widget.wallets.length > 1)
              Positioned(
                top: 20,
                left: 16,
                right: 16,
                child: Transform.scale(
                  scale: 0.95,
                  child: _buildTranslucentCard(
                    wallet: widget.wallets[1],
                    index: 1,
                    theme: theme,
                    colorScheme: colorScheme,
                    isFront: false,
                  ),
                ),
              ),

            // Front Card
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTranslucentCard(
                wallet: widget.wallets.isNotEmpty ? widget.wallets[0] : null,
                index: 0,
                theme: theme,
                colorScheme: colorScheme,
                isFront: true,
              ),
            ),

            // Tap indicator
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(204),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to expand',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslucentCard({
    required Wallet? wallet,
    required int index,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isFront,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GestureDetector(
          onTap: () {
            if (wallet == null) {
              widget.onAddWallet();
            } else if (isFront) {
              widget.onWalletTap(wallet, index);
            }
          },
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(isFront ? 51 : 25),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withAlpha(isFront ? 102 : 51),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: wallet == null
                  ? null
                  : LinearGradient(
                      colors: _getGradientColors(index, colorScheme),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: wallet == null
                ? _buildAddCardContent(theme, colorScheme)
                : _buildWalletCardContent(wallet, index, theme, colorScheme),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletCardContent(
    Wallet wallet,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _getWalletIcon(wallet.type, Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  wallet.type.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              PrivacyCurrency(
                amount:
                    '${widget.currency} ${wallet.balance.toStringAsFixed(2)}',
                isPrivacyActive: widget.isPrivate,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddCardContent(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_card, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Add Your First Wallet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<Color> _getGradientColors(int index, ColorScheme colorScheme) {
    final gradients = [
      [colorScheme.primary, colorScheme.secondary],
      [colorScheme.tertiary, colorScheme.primary],
      [colorScheme.secondary, colorScheme.tertiary],
      [colorScheme.primaryContainer, colorScheme.secondaryContainer],
    ];
    return gradients[index % gradients.length];
  }

  Icon _getWalletIcon(String type, Color color) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'cash':
        iconData = Icons.money_rounded;
        break;
      case 'bank':
        iconData = Icons.account_balance_rounded;
        break;
      case 'card':
        iconData = Icons.credit_card_rounded;
        break;
      case 'upi':
        iconData = Icons.qr_code_rounded;
        break;
      case 'credit':
        iconData = Icons.credit_score_rounded;
        break;
      default:
        iconData = Icons.wallet_rounded;
    }
    return Icon(iconData, color: color, size: 20);
  }
}

class _ExpandedWalletsDialog extends StatefulWidget {
  const _ExpandedWalletsDialog();

  @override
  State<_ExpandedWalletsDialog> createState() => _ExpandedWalletsDialogState();
}

class _ExpandedWalletsDialogState extends State<_ExpandedWalletsDialog>
    with TickerProviderStateMixin {
  late List<AnimationController> _staggerControllers;
  final PrivacyManager _privacyManager = PrivacyManager();
  String currency = '';

  @override
  void initState() {
    super.initState();
    // Get wallets from navigator or pass as param, but for simplicity, assume global or callback
    // To make it work, we need to pass wallets to the dialog, but since it's static, use Builder or pass via constructor
    // For this, we'll assume the widget has access, but to fix, use a static or provider, but for code, use Hive directly
    final wallets = Hive.box<Wallet>(
      AppConstants.wallets,
    ).values.toList(); // Assume import
    _staggerControllers = [];
    for (int i = 0; i < wallets.length; i++) {
      _staggerControllers.add(
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        ),
      );
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _staggerControllers.length; i++) {
        Future.delayed(Duration(milliseconds: 100 * i), () {
          if (mounted) _staggerControllers[i].forward();
        });
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    for (var controller in _staggerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    currency = await Helpers().getCurrentCurrency() ?? 'INR';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final currency = currency ?? 'INR'; // Get from context or param
    final isPrivate = _privacyManager.shouldHideSensitiveData();
    final wallets = Hive.box<Wallet>(
      AppConstants.wallets,
    ).values.toList(); // Need to pass or use provider

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Blurred Background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withAlpha(128)),
          ),

          SafeArea(
            child: Column(
              children: [
                // Title Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Wallets',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showAddEditWalletSheet();
                        },
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                // Cards List (Vertical Scroll)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: wallets.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _staggerControllers[index],
                        builder: (context, child) {
                          final animationValue =
                              _staggerControllers[index].value;
                          return Transform.translate(
                            offset: Offset(0, 50 * (1 - animationValue)),
                            child: Transform.scale(
                              scale: 0.9 + (0.1 * animationValue),
                              child: Opacity(
                                opacity: animationValue,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildTranslucentCardDialog(
                                    wallet: wallets[index],
                                    index: index,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                    isPrivate: isPrivate,
                                    currency: currency,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Close Button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.white.withAlpha(204),
              foregroundColor: Colors.black87,
              elevation: 0,
              icon: const Icon(Icons.close),
              label: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslucentCardDialog({
    required Wallet wallet,
    required int index,
    required ThemeData theme,
    required ColorScheme colorScheme,
    required bool isPrivate,
    required String currency,
  }) {
    final walletBox = Hive.box<Wallet>(AppConstants.wallets);
    final key = walletBox.keyAt(index);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: GestureDetector(
          onTap: () {
            // Call onWalletTap, but since dialog, Navigator.pop then call
            Navigator.pop(context);
            _showAddEditWalletSheet(key: key as int, wallet: wallet);

            // Assume callback
          },
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withAlpha(102), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
              gradient: LinearGradient(
                colors: _getGradientColors(index, colorScheme),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _buildWalletCardContent(
              wallet,
              index,
              theme,
              colorScheme,
              isPrivate,
              currency,
            ),
          ),
        ),
      ),
    );
  }

  // Reuse the _buildWalletCardContent from above
  Widget _buildWalletCardContent(
    Wallet wallet,
    int index,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isPrivate,
    String currency,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _getWalletIcon(wallet.type, Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  wallet.type.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wallet.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              PrivacyCurrency(
                amount: '$currency ${wallet.balance.toStringAsFixed(2)}',
                isPrivacyActive: isPrivate,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Reuse _getGradientColors and _getWalletIcon from above
  List<Color> _getGradientColors(int index, ColorScheme colorScheme) {
    final gradients = [
      [colorScheme.primary, colorScheme.secondary],
      [colorScheme.tertiary, colorScheme.primary],
      [colorScheme.secondary, colorScheme.tertiary],
      [colorScheme.primaryContainer, colorScheme.secondaryContainer],
    ];
    return gradients[index % gradients.length];
  }

  Icon _getWalletIcon(String type, Color color) {
    IconData iconData;
    switch (type.toLowerCase()) {
      case 'cash':
        iconData = Icons.money_rounded;
        break;
      case 'bank':
        iconData = Icons.account_balance_rounded;
        break;
      case 'card':
        iconData = Icons.credit_card_rounded;
        break;
      case 'upi':
        iconData = Icons.qr_code_rounded;
        break;
      case 'credit':
        iconData = Icons.credit_score_rounded;
        break;
      default:
        iconData = Icons.wallet_rounded;
    }
    return Icon(iconData, color: color, size: 20);
  }

  void _showAddEditWalletSheet({int? key, Wallet? wallet}) {
    final isEditing = key != null && wallet != null;
    final nameController = TextEditingController(
      text: isEditing ? wallet.name : '',
    );
    final balanceController = TextEditingController(
      text: isEditing ? wallet.balance.toString() : '',
    );
    String selectedType = isEditing ? wallet.type.toLowerCase() : 'cash';
    BottomSheetUtil.show(
      context: context,
      title: isEditing ? 'Edit Wallet' : 'Add Wallet',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: InputDecoration(
                  labelText: 'Balance',
                  border: OutlineInputBorder(),
                  prefixText: '$currency ',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cash', child: Text('Cash')),
                  DropdownMenuItem(value: 'bank', child: Text('Bank')),
                  DropdownMenuItem(value: 'card', child: Text('Card')),
                  DropdownMenuItem(value: 'upi', child: Text('UPI')),
                  DropdownMenuItem(value: 'credit', child: Text('Credit Card')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () async {
                  final balance =
                      double.tryParse(balanceController.text) ?? 0.0;
                  if (nameController.text.trim().isEmpty) {
                    Navigator.pop(context);
                    SnackBars.show(
                      context,
                      message: 'Please enter wallet name',
                      type: SnackBarType.error,
                    );
                    return;
                  }
                  final walletBox = Hive.box<Wallet>(AppConstants.wallets);
                  final newWallet = Wallet(
                    name: nameController.text.trim(),
                    balance: balance,
                    type: selectedType,
                    createdAt: isEditing ? wallet.createdAt : DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  if (isEditing) {
                    await walletBox.put(key, newWallet);
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: 'Wallet updated',
                        type: SnackBarType.success,
                      );
                    }
                  } else {
                    await walletBox.add(newWallet);
                    if (context.mounted) {
                      Navigator.pop(context);
                      SnackBars.show(
                        context,
                        message: 'Wallet added',
                        type: SnackBarType.success,
                      );
                    }
                  }
                  _loadData();
                },
                child: Text(isEditing ? 'Update Wallet' : 'Add Wallet'),
              ),
            ],
          );
        },
      ),
    );
  }
}
