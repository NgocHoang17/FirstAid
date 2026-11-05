import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/mobile_shell.dart';
import 'core/network/app_services.dart';
import 'core/storage/snapshot_store.dart';

class MyApp extends StatelessWidget {
  const MyApp({this.api, this.store, super.key});
  final PublicApi? api;
  final SnapshotStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FirstAid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: MobileShell(api: api, store: store),
    );
  }
}
