import 'package:flutter/widgets.dart';

import '../core/tr.dart';
import 'player_progress.dart';

export 'player_progress.dart';

/// Gives every widget access to [PlayerProgress] without passing it around.
class AppScope extends InheritedNotifier<PlayerProgress> {
  const AppScope({
    required PlayerProgress progress,
    required super.child,
    super.key,
  }) : super(notifier: progress);

  /// Subscribes the caller: it rebuilds when the progress changes.
  static PlayerProgress of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!.notifier!;
  }

  /// Reads without subscribing (use inside callbacks).
  static PlayerProgress read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope is missing above this widget.');
    return scope!.notifier!;
  }
}

extension AppContext on BuildContext {
  PlayerProgress get progress => AppScope.of(this);

  bool get isEnglish => AppScope.of(this).english;

  /// Picks the Russian or English text.
  String t(String ru, String en) => isEnglish ? en : ru;

  String tr(Tr text) => text.of(isEnglish);
}
