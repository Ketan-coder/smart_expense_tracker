import 'package:expense_tracker/screens/widgets/bottom_sheet.dart';
import 'package:flutter/material.dart';

import '../../core/helpers.dart';
import '../widgets/custom_app_bar.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SimpleCustomAppBar(
        title: "Settings",
        hasContent: true,
        expandedHeight: MediaQuery.of(context).size.height * 0.35,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              BottomSheetUtil.show(
                  context: context,
                  child: Container(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Search",
                        prefixIcon: Icon(Icons.search),
                      )

                    ),
                  )
              );
            },
            icon: const Icon(Icons.search),
          ),
        ],
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Helpers().isLightMode(context) ? Colors.white : Colors.black,
          ),
          child: Center(
            child: Text(
              "Settings Page",
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
      ),
    );
  }
}
