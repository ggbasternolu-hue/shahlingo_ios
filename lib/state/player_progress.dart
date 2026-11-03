import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/course.dart';
import '../services/firebase_service.dart';
import 'game_record.dart';

/// Everything the app remembers about the player.
///
/// Stored locally with shared_preferences; the rating and XP are mirrored to
/// Firebase when it is reachable. Lessons unlock one after another.
class PlayerProgress extends ChangeNotifier {
  static const _p = 'shahlingo_v3_';
  static const _legacy = 'shahlingo_v2_';

  int xp = 0;
  int gems = 0;
  int elo = 0;
  int ratedGames = 0;
  int streak = 0;
  String lastActiveDay = '';
  final Set<String> completed = {};
  final Map<String, int> stars = {};
  final Set<String> openedChests = {};
  List<GameRecord> history = [];
  bool english = false;
  bool onboardingComplete = false;
  String name = 'Игрок';
  String avatar = 'sergei';
  String chessExperience = 'new';
  String? cloudError;
  bool firebaseReady = false;
  bool _loaded = false;

  bool get loaded => _loaded;
  bool get ratingEstablished => ratedGames >= 5;
  int get level => max(1, xp ~/ 100 + 1);
  int get levelProgress => xp % 100;
  int get wins => history.where((g) => g.result == GameResult.win).length;
  int get losses => history.where((g) => g.result == GameResult.loss).length;
  int get draws => history.where((g) => g.result == GameResult.draw).length;
  int get lessonsCompleted => completed.length;

  String get rank {
    if (!ratingEstablished) return english ? 'Calibrating' : 'Калибровка';
    return rankFor(elo, english);
  }

  static String rankFor(int rating, bool english) {
    if (rating >= 1800) return english ? 'Master' : 'Мастер';
    if (rating >= 1400) return english ? 'Expert' : 'Эксперт';
    if (rating >= 1100) return english ? 'Tactician' : 'Тактик';
    if (rating >= 900) return english ? 'Strategist' : 'Стратег';
    return english ? 'Beginner' : 'Новичок';
  }

  // ───────────────────────── lessons ─────────────────────────

  bool isDone(String lessonId) => completed.contains(lessonId);

  bool isUnlocked(String lessonId) {
    final index = lessonIndex(lessonId);
    if (index <= 0) return index == 0;
    return completed.contains(allLessons[index - 1].id);
  }

  /// First lesson that is not completed yet, or null when the course is done.
  Lesson? get currentLesson {
    for (final lesson in allLessons) {
      if (!completed.contains(lesson.id)) return lesson;
    }
    return null;
  }

  int starsFor(String lessonId) => stars[lessonId] ?? 0;

  bool isChestOpen(String id) => openedChests.contains(id);

  /// Returns the XP that was awarded.
  Future<int> completeLesson(
    String lessonId, {
    required int earnedStars,
  }) async {
    final firstTime = !completed.contains(lessonId);
    final bonus = earnedStars >= 3 ? 10 : 0;
    final gained = firstTime ? 20 + bonus : 5;
    xp += gained;
    if (firstTime) gems += 3 + earnedStars;
    completed.add(lessonId);
    stars[lessonId] = max(starsFor(lessonId), earnedStars);
    _touchStreak();
    await _save();
    notifyListeners();
    unawaited(_publishQuietly());
    return gained;
  }

  Future<void> openChest(String id) async {
    if (!openedChests.add(id)) return;
    gems += 15;
    await _save();
    notifyListeners();
  }

  // ───────────────────────── games ─────────────────────────

  Future<void> recordGame(
    GameRecord record, {
    required int gainedXp,
    int? opponentElo,
  }) async {
    if (opponentElo != null) {
      final score = switch (record.result) {
        GameResult.win => 1.0,
        GameResult.draw => 0.5,
        GameResult.loss => 0.0,
      };
      _applyRating(score: score, opponentElo: opponentElo);
    }
    history = [record, ...history].take(30).toList();
    xp += gainedXp;
    _touchStreak();
    await _save();
    notifyListeners();
    unawaited(_publishQuietly());
  }

  static int calculateEloChange({
    required int rating,
    required int opponentRating,
    required double score,
  }) {
    final expected = 1 / (1 + pow(10, (opponentRating - rating) / 400));
    return (32 * (score - expected)).round();
  }

  void _applyRating({required double score, required int opponentElo}) {
    elo =
        (elo +
                calculateEloChange(
                  rating: elo,
                  opponentRating: opponentElo,
                  score: score,
                ))
            .clamp(0, 5000)
            .toInt();
    ratedGames++;
  }

  void finishOnlineRound({
    required bool? won,
    required int opponentElo,
    required GameRecord record,
  }) {
    final score = won == null ? 0.5 : (won ? 1.0 : 0.0);
    _applyRating(score: score, opponentElo: opponentElo);
    xp += won == true ? 20 : 8;
    history = [record, ...history].take(30).toList();
    _touchStreak();
    unawaited(_save());
    notifyListeners();
    unawaited(_publishQuietly());
  }

  // ───────────────────────── streak ─────────────────────────

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _touchStreak() {
    final now = DateTime.now();
    final today = _dayKey(now);
    if (lastActiveDay == today) return;
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    streak = lastActiveDay == yesterday ? streak + 1 : 1;
    lastActiveDay = today;
  }

  void _expireStreak() {
    final now = DateTime.now();
    final today = _dayKey(now);
    final yesterday = _dayKey(now.subtract(const Duration(days: 1)));
    if (lastActiveDay != today && lastActiveDay != yesterday) streak = 0;
  }

  // ───────────────────────── persistence ─────────────────────────

  int _int(SharedPreferences prefs, String key, int fallback) =>
      prefs.getInt('$_p$key') ?? prefs.getInt('$_legacy$key') ?? fallback;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    xp = _int(prefs, 'xp', 0);
    gems = prefs.getInt('${_p}gems') ?? 0;
    ratedGames =
        prefs.getInt('${_p}rated_games') ??
        prefs.getInt('${_legacy}rated_games') ??
        0;
    elo = _int(prefs, 'elo', 0);
    if (ratedGames == 0 && elo == 800) elo = 0;
    streak = prefs.getInt('${_p}streak') ?? 0;
    lastActiveDay = prefs.getString('${_p}last_day') ?? '';
    completed
      ..clear()
      ..addAll(prefs.getStringList('${_p}completed') ?? const []);
    stars.clear();
    for (final entry in prefs.getStringList('${_p}stars') ?? const <String>[]) {
      final parts = entry.split(':');
      if (parts.length == 2) stars[parts[0]] = int.tryParse(parts[1]) ?? 0;
    }
    openedChests
      ..clear()
      ..addAll(prefs.getStringList('${_p}chests') ?? const []);
    history = [
      for (final raw in prefs.getStringList('${_p}history') ?? const <String>[])
        if (GameRecord.decode(raw) case final record?) record,
    ];
    english =
        prefs.getBool('${_p}english') ??
        prefs.getBool('${_legacy}english') ??
        false;
    name =
        prefs.getString('${_p}name') ??
        prefs.getString('${_legacy}name') ??
        'Игрок';
    avatar = prefs.getString('${_p}avatar') ?? 'sergei';
    chessExperience =
        prefs.getString('${_p}experience') ??
        prefs.getString('${_legacy}experience') ??
        'new';
    onboardingComplete =
        prefs.getBool('${_p}onboarding') ??
        prefs.getBool('${_legacy}onboarding_complete') ??
        name.trim() != 'Игрок';
    _expireStreak();
    _loaded = true;
    notifyListeners();
    await _connectFirebase();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_p}xp', xp);
    await prefs.setInt('${_p}gems', gems);
    await prefs.setInt('${_p}elo', elo);
    await prefs.setInt('${_p}rated_games', ratedGames);
    await prefs.setInt('${_p}streak', streak);
    await prefs.setString('${_p}last_day', lastActiveDay);
    await prefs.setStringList('${_p}completed', completed.toList());
    await prefs.setStringList('${_p}stars', [
      for (final entry in stars.entries) '${entry.key}:${entry.value}',
    ]);
    await prefs.setStringList('${_p}chests', openedChests.toList());
    await prefs.setStringList('${_p}history', [
      for (final record in history) record.encode(),
    ]);
    await prefs.setBool('${_p}english', english);
    await prefs.setString('${_p}name', name);
    await prefs.setString('${_p}avatar', avatar);
    await prefs.setString('${_p}experience', chessExperience);
    await prefs.setBool('${_p}onboarding', onboardingComplete);
  }

  // ───────────────────────── profile ─────────────────────────

  Future<void> updateName(String value) async {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    name = trimmed.length > 20 ? trimmed.substring(0, 20) : trimmed;
    await _save();
    notifyListeners();
    unawaited(_publishQuietly());
  }

  Future<void> setAvatar(String value) async {
    avatar = value;
    await _save();
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    english = !english;
    await _save();
    notifyListeners();
  }

  Future<void> finishOnboarding({
    required String playerName,
    required String experience,
  }) async {
    final cleaned = playerName.trim();
    if (cleaned.isEmpty || cleaned.length > 20) {
      throw ArgumentError.value(playerName, 'playerName', 'Некорректное имя.');
    }
    name = cleaned;
    chessExperience = experience;
    onboardingComplete = true;
    await _save();
    notifyListeners();
  }

  // ───────────────────────── firebase ─────────────────────────

  Future<void> _connectFirebase() async {
    try {
      await FirebaseService.instance.initialize();
      final profile = await FirebaseService.instance.loadMyProfile();
      if (profile != null && ratedGames == 0 && profile.ratedGames > 0) {
        elo = profile.elo;
        ratedGames = profile.ratedGames;
        xp = max(xp, profile.xp);
        await _save();
      } else if (profile != null &&
          (profile.elo != elo || profile.ratedGames != ratedGames)) {
        await FirebaseService.instance.publishProfile(
          name: name,
          elo: elo,
          xp: xp,
          ratedGames: ratedGames,
        );
      }
      firebaseReady = true;
      cloudError = null;
    } catch (error) {
      firebaseReady = false;
      cloudError = describeFirebaseError(error);
    }
    notifyListeners();
  }

  Future<void> retryFirebase() async {
    cloudError = null;
    firebaseReady = false;
    notifyListeners();
    await _connectFirebase();
  }

  Future<void> _publishQuietly() async {
    if (!firebaseReady) return;
    try {
      await FirebaseService.instance.publishProfile(
        name: name,
        elo: elo,
        xp: xp,
        ratedGames: ratedGames,
      );
      cloudError = null;
    } catch (error) {
      cloudError = describeFirebaseError(error);
      firebaseReady = false;
      notifyListeners();
    }
  }

  static String describeFirebaseError(Object error) {
    if (error is! FirebaseException) {
      return 'Облачный сервис недоступен: $error';
    }
    return switch (error.code) {
      'configuration-not-found' || 'operation-not-allowed' =>
        'В Firebase Console включите Authentication → Sign-in method → Anonymous. '
            'Для веб-версии проверьте также список Authorized domains.',
      'app-not-authorized' => 'Добавьте адрес этого приложения в Firebase Authentication → Settings → Authorized domains.',
      'permission-denied' || 'PERMISSION_DENIED' =>
        'Firebase отклонил запрос. Проверьте правила базы данных и вход.',
      'network-request-failed' =>
        'Нет связи с Firebase. Проверьте интернет-подключение.',
      _ =>
        'Ошибка Firebase (${error.code}): ${error.message ?? 'без описания'}',
    };
  }
}
