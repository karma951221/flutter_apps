import 'package:flutter/material.dart';

import 'core/app.dart';
import 'core/di/injection.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const WalkApp());
}
