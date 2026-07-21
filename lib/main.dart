import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'features/projects/providers/project_provider.dart';
import 'features/acts/providers/act_provider.dart';
import 'features/characters/providers/character_provider.dart';
import 'features/locations/providers/location_provider.dart';
import 'features/scenes/providers/scene_provider.dart';
import 'features/production/providers/production_provider.dart';

import 'features/auth/providers/auth_provider.dart';

import 'features/notifications/providers/notification_provider.dart';
import 'core/connectivity/network_status_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => ActProvider()),
        ChangeNotifierProvider(create: (_) => CharacterProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => SceneProvider()),
        ChangeNotifierProvider(create: (_) => ProductionProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => NetworkStatusProvider()),
      ],
      child: const CineXApp(),
    ),
  );
}
