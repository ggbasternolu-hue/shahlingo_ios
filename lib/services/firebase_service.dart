import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase_options.dart';

class OnlinePlayer {
  const OnlinePlayer({
    required this.uid,
    required this.name,
    required this.elo,
    required this.xp,
    this.ratedGames = 0,
  });

  final String uid;
  final String name;
  final int elo;
  final int xp;
  final int ratedGames;
}

class OnlineGame {
  const OnlineGame({
    required this.id,
    required this.whiteUid,
    required this.blackUid,
    required this.whiteName,
    required this.blackName,
    required this.fen,
    required this.status,
    required this.lastMove,
    this.whiteElo = 0,
    this.blackElo = 0,
  });

  final String id;
  final String whiteUid;
  final String blackUid;
  final String whiteName;
  final String blackName;
  final String fen;
  final String status;
  final String? lastMove;
  final int whiteElo;
  final int blackElo;

  String opponentUid(String uid) => uid == whiteUid ? blackUid : whiteUid;
  String playerColor(String uid) => uid == whiteUid ? 'w' : 'b';

  factory OnlineGame.fromSnapshot(String id, Object? value) {
    if (value is! Map) {
      throw const FormatException('Повреждены данные онлайн-матча.');
    }
    return OnlineGame(
      id: id,
      whiteUid: value['whiteUid'] as String? ?? '',
      blackUid: value['blackUid'] as String? ?? '',
      whiteName: value['whiteName'] as String? ?? 'Игрок',
      blackName: value['blackName'] as String? ?? 'Игрок',
      fen: value['fen'] as String? ?? chess.Chess.DEFAULT_POSITION,
      status: value['status'] as String? ?? 'waiting',
      lastMove: value['lastMove'] as String?,
      whiteElo: (value['whiteElo'] as num?)?.toInt() ?? 0,
      blackElo: (value['blackElo'] as num?)?.toInt() ?? 0,
    );
  }
}

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  FirebaseApp? _app;
  FirebaseDatabase? _database;
  FirebaseAuth? _auth;

  bool get isReady => _database != null && _auth != null;
  String? get userId => _auth?.currentUser?.uid;

  Future<void> initialize() async {
    if (isReady) return;
    _app = Firebase.apps.isNotEmpty
        ? Firebase.app()
        : await Firebase.initializeApp(
            options: ShahlingoFirebaseOptions.currentPlatform,
          );
    _auth = FirebaseAuth.instanceFor(app: _app!);
    _database = FirebaseDatabase.instanceFor(
      app: _app!,
      databaseURL: ShahlingoFirebaseOptions.currentPlatform.databaseURL,
    );
  }

  Future<String> signIn() async {
    await initialize();
    final current = _auth!.currentUser;
    if (current != null) return current.uid;
    final credential = await _auth!.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase не вернул пользователя.');
    }
    return user.uid;
  }

  Stream<List<OnlinePlayer>> leaderboard() {
    final query = _database!
        .ref('leaderboard')
        .orderByChild('elo')
        .limitToLast(25);
    return query.onValue.map((event) {
      final value = event.snapshot.value;
      if (value == null) return const <OnlinePlayer>[];
      if (value is! Map) {
        throw const FormatException('Некорректная таблица лидеров.');
      }
      final players = <OnlinePlayer>[];
      for (final entry in value.entries) {
        final row = entry.value;
        if (row is! Map) continue;
        final ratedGames = (row['ratedGames'] as num?)?.toInt() ?? 0;
        final rating = (row['elo'] as num?)?.toInt() ?? 0;
        players.add(
          OnlinePlayer(
            uid: entry.key.toString(),
            name: row['name'] as String? ?? 'Игрок',
            elo: ratedGames == 0 && rating == 800 ? 0 : rating,
            xp: (row['xp'] as num?)?.toInt() ?? 0,
            ratedGames: ratedGames,
          ),
        );
      }
      players.sort((a, b) => b.elo.compareTo(a.elo));
      return players;
    });
  }

  Future<void> publishProfile({
    required String name,
    required int elo,
    required int xp,
    required int ratedGames,
  }) async {
    final uid = await signIn();
    await _database!.ref('leaderboard/$uid').update({
      'name': name,
      'elo': elo,
      'xp': xp,
      'ratedGames': ratedGames,
      'updatedAt': ServerValue.timestamp,
    });
  }

  Future<OnlinePlayer?> loadMyProfile() async {
    final uid = await signIn();
    final snapshot = await _database!.ref('leaderboard/$uid').get();
    final value = snapshot.value;
    if (value == null) return null;
    if (value is! Map) {
      throw const FormatException('Повреждены данные профиля Firebase.');
    }
    final name = value['name'];
    final elo = value['elo'];
    final xp = value['xp'];
    final ratedGames = value['ratedGames'];
    if (name is! String || elo is! num || xp is! num) {
      throw const FormatException('Некорректные данные профиля Firebase.');
    }
    final games = (ratedGames as num?)?.toInt() ?? 0;
    final rating = elo.toInt();
    return OnlinePlayer(
      uid: uid,
      name: name,
      elo: games == 0 && rating == 800 ? 0 : rating,
      xp: xp.toInt(),
      ratedGames: games,
    );
  }

  Future<String> findMatch({required String name, required int elo}) async {
    final uid = await signIn();
    final lobby = _database!.ref('matchmaking/lobby');
    final result = await lobby.runTransaction((current) {
      final root = current is Map
          ? Map<String, dynamic>.from(current)
          : <String, dynamic>{};
      final waiting = root['waiting'] is Map
          ? Map<String, dynamic>.from(root['waiting'] as Map)
          : <String, dynamic>{};
      final existing = waiting[uid];
      if (existing is Map && existing['status'] == 'matched') {
        return Transaction.success(root);
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      String? opponentUid;
      String? opponentName;
      var opponentElo = 0;
      for (final entry in waiting.entries.toList()) {
        if (entry.key == uid || entry.value is! Map) continue;
        final candidate = Map<String, dynamic>.from(entry.value as Map);
        final joinedAt = candidate['joinedAt'];
        if (candidate['status'] != 'waiting') continue;
        if (joinedAt is! num ||
            now - joinedAt > const Duration(minutes: 2).inMilliseconds) {
          waiting.remove(entry.key);
          continue;
        }
        opponentUid = entry.key;
        opponentName = candidate['name'] as String? ?? 'Игрок';
        opponentElo = (candidate['elo'] as num?)?.toInt() ?? 0;
        break;
      }

      if (opponentUid == null) {
        waiting[uid] = {
          'name': name,
          'elo': elo,
          'status': 'waiting',
          'joinedAt': now,
        };
        root['waiting'] = waiting;
        return Transaction.success(root);
      }

      final participants = [uid, opponentUid]..sort();
      final matchId =
          '${participants[0]}_${participants[1]}_$now-${Random.secure().nextInt(1 << 32)}';
      final random = Random.secure();
      final whiteUid = random.nextBool() ? uid : opponentUid;
      final matchDetails = {
        'matchId': matchId,
        'whiteUid': whiteUid,
        'blackUid': whiteUid == uid ? opponentUid : uid,
        'whiteName': whiteUid == uid ? name : opponentName,
        'blackName': whiteUid == uid ? opponentName : name,
        'whiteElo': whiteUid == uid ? elo : opponentElo,
        'blackElo': whiteUid == uid ? opponentElo : elo,
        'createdAt': now,
      };
      waiting[uid] = {
        'name': name,
        'elo': elo,
        'status': 'matched',
        ...matchDetails,
        'joinedAt': now,
      };
      waiting[opponentUid] = {
        'name': opponentName,
        'elo': opponentElo,
        'status': 'matched',
        ...matchDetails,
        'joinedAt': now,
      };
      root['waiting'] = waiting;
      return Transaction.success(root);
    });

    if (!result.committed) {
      throw StateError('Не удалось зарезервировать место в очереди.');
    }
    final lobbyData = result.snapshot.value;
    if (lobbyData is! Map) {
      throw const FormatException('Очередь онлайн-матчей недоступна.');
    }
    final waiting = lobbyData['waiting'];
    if (waiting is! Map || waiting[uid] is! Map) {
      throw const FormatException('Игрок пропал из очереди.');
    }
    final ownTicket = waiting[uid] as Map;
    if (ownTicket['status'] == 'matched') {
      final matchId = ownTicket['matchId'] as String?;
      if (matchId == null) {
        throw const FormatException('В очереди отсутствует номер матча.');
      }
      await _createMatchIfNeeded(matchId, ownTicket);
      return matchId;
    }

    final deadline = DateTime.now().add(const Duration(minutes: 2));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));
      final snapshot = await lobby.get();
      final data = snapshot.value;
      if (data is! Map || data['waiting'] is! Map) {
        throw StateError('Поиск соперника отменён.');
      }
      final ticket = (data['waiting'] as Map)[uid];
      if (ticket is! Map) throw StateError('Поиск соперника отменён.');
      if (ticket['status'] == 'matched') {
        final matchId = ticket['matchId'] as String?;
        if (matchId == null) {
          throw const FormatException('В очереди отсутствует номер матча.');
        }
        await _createMatchIfNeeded(matchId, ticket);
        return matchId;
      }
    }
    await _removeQueueTicket(uid);
    throw TimeoutException('Соперник пока не найден.');
  }

  Future<void> _createMatchIfNeeded(String matchId, Object? pairValue) async {
    final match = _database!.ref('matches/$matchId');
    final existing = await match.get();
    if (existing.exists) return;
    if (pairValue is! Map || pairValue['matchId'] != matchId) {
      throw const FormatException('Не удалось определить игроков матча.');
    }
    final createdAt =
        (pairValue['createdAt'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    await match.runTransaction((current) {
      if (current != null) return Transaction.abort();
      return Transaction.success({
        'whiteUid': pairValue['whiteUid'],
        'blackUid': pairValue['blackUid'],
        'whiteName': pairValue['whiteName'],
        'blackName': pairValue['blackName'],
        'whiteElo': pairValue['whiteElo'],
        'blackElo': pairValue['blackElo'],
        'fen': chess.Chess.DEFAULT_POSITION,
        'status': 'active',
        'createdAt': createdAt,
        'lastMove': null,
        'updatedAt': createdAt,
      });
    });
  }

  Future<void> cancelSearch() async {
    final uid = userId;
    if (uid != null) await _removeQueueTicket(uid);
  }

  Future<void> _removeQueueTicket(String uid) async {
    final ref = _database!.ref('matchmaking/lobby/waiting/$uid');
    final snapshot = await ref.get();
    if (snapshot.value is Map &&
        (snapshot.value as Map)['status'] == 'waiting') {
      await ref.remove();
    }
  }

  Stream<OnlineGame> watchGame(String matchId) {
    return _database!
        .ref('matches/$matchId')
        .onValue
        .map((event) => OnlineGame.fromSnapshot(matchId, event.snapshot.value));
  }

  Future<void> playOnlineMove({
    required String matchId,
    required String from,
    required String to,
  }) async {
    final uid = await signIn();
    final gameRef = _database!.ref('matches/$matchId');
    final result = await gameRef.runTransaction((current) {
      if (current is! Map) return Transaction.abort();
      final data = Map<String, dynamic>.from(current);
      if (data['status'] != 'active') return Transaction.abort();
      final whiteUid = data['whiteUid'];
      final blackUid = data['blackUid'];
      final fen = data['fen'];
      if (fen is! String || (uid != whiteUid && uid != blackUid)) {
        return Transaction.abort();
      }
      final game = chess.Chess.fromFEN(fen);
      final expectedUid = game.turn == chess.Color.WHITE ? whiteUid : blackUid;
      if (uid != expectedUid ||
          !game.move({'from': from, 'to': to, 'promotion': 'q'})) {
        return Transaction.abort();
      }
      final history = data['history'] is List
          ? List<dynamic>.from(data['history'] as List)
          : <dynamic>[];
      history.add({'from': from, 'to': to, 'uid': uid});
      data['history'] = history;
      data['fen'] = game.fen;
      data['lastMove'] = '$from$to';
      data['status'] = game.game_over ? 'finished' : 'active';
      data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      return Transaction.success(data);
    });

    if (!result.committed) {
      throw StateError(
        'Ход отклонён: сейчас ход соперника или позиция уже изменилась.',
      );
    }
  }
}
