import 'dart:async';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../chess/board_utils.dart';
import '../../chess/board_view.dart';
import '../../core/theme.dart';
import '../../data/banter.dart';
import '../../data/course_model.dart';
import '../../services/firebase_service.dart';
import '../../state/app_scope.dart';
import '../../state/game_record.dart';
import '../../widgets/character.dart';
import '../../widgets/duo_button.dart';
import 'game_widgets.dart';

/// Matchmaking + an online game through Firebase.
class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key});

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  String? _matchId;
  String? _error;
  bool _searching = false;
  bool _saved = false;
  int _seconds = 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (_searching || _matchId != null)) {
        setState(() => _seconds++);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _clock?.cancel();
    if (_searching)
      unawaited(FirebaseService.instance.cancelSearch().catchError((_) {}));
    super.dispose();
  }

  Future<void> _search() async {
    final progress = AppScope.read(context);
    if (!progress.firebaseReady) {
      setState(
        () => _error = progress.cloudError ?? 'Firebase не настроен. Проверьте подключение и правила базы данных.',
      );
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
      _seconds = 0;
    });
    try {
      final id = await FirebaseService.instance.findMatch(
        name: progress.name,
        elo: progress.elo,
      );
      if (!mounted) return;
      setState(() {
        _matchId = id;
        _searching = false;
        _seconds = 0;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _error = context.t(
          'Соперник пока не найден. Попробуй ещё раз чуть позже.',
          'No opponent found yet. Try again in a moment.',
        );
      });
    } catch (error) {
      if (!mounted || !_searching) return;
      setState(() {
        _searching = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _cancel() async {
    try {
      await FirebaseService.instance.cancelSearch();
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  void _saveResult(OnlineGame online, bool? won) {
    if (_saved || online.status != 'finished') return;
    _saved = true;
    final uid = FirebaseService.instance.userId ?? '';
    final isWhite = online.whiteUid == uid;
    final opponent = isWhite ? online.blackName : online.whiteName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.read(context).finishOnlineRound(
        won: won,
        opponentElo: isWhite ? online.blackElo : online.whiteElo,
        record: GameRecord(
          opponent: opponent,
          result: won == null
              ? GameResult.draw
              : (won ? GameResult.win : GameResult.loss),
          moves: const [],
          playedAtMs: DateTime.now().millisecondsSinceEpoch,
          playerWhite: isWhite,
        ),
      );
    });
  }

  Future<void> _sendMove(String matchId, String from, String to) async {
    try {
      await FirebaseService.instance.playOnlineMove(
        matchId: matchId,
        from: from,
        to: to,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchId = _matchId;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: matchId == null
                ? _buildSearch(context)
                : _buildGame(context, matchId),
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _cancel,
              icon: const Icon(
                Icons.close_rounded,
                color: DuoColors.muted,
                size: 30,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Radar(active: _searching),
                  const SizedBox(height: 28),
                  Text(
                    _error != null
                        ? context.t('Не получилось', 'Couldn’t connect')
                        : context.t(
                            'Ищем соперника…',
                            'Looking for an opponent…',
                          ),
                    style: DuoText.h1,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error ??
                        context.t(
                          'Обычно это занимает меньше минуты. Прошло: $_seconds с',
                          'Usually under a minute. Elapsed: $_seconds s',
                        ),
                    style: DuoText.small,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            DuoButton(
              label: context.t('Попробовать снова', 'Try again'),
              onPressed: () async {
                await AppScope.read(context).retryFirebase();
                if (mounted) _search();
              },
            )
          else
            DuoButton(
              label: context.t('Отмена', 'Cancel'),
              kind: DuoButtonKind.outline,
              onPressed: _cancel,
            ),
        ],
      ),
    );
  }

  Widget _buildGame(BuildContext context, String matchId) {
    return StreamBuilder<OnlineGame>(
      stream: FirebaseService.instance.watchGame(matchId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('${snapshot.error}', style: DuoText.body),
            ),
          );
        }
        final online = snapshot.data;
        if (online == null) {
          return const Center(
            child: CircularProgressIndicator(color: DuoColors.green),
          );
        }
        final uid = FirebaseService.instance.userId ?? '';
        final isWhite = online.whiteUid == uid;
        final game = chess.Chess.fromFEN(online.fen);
        final myTurn =
            (online.fen.split(' ').elementAtOrNull(1) ?? 'w') ==
            (isWhite ? 'w' : 'b');
        final finished = online.status == 'finished';
        final opponent = isWhite ? online.blackName : online.whiteName;
        final bool? won = finished && game.game_over && !game.in_draw
            ? (game.turn == chess.Color.BLACK ? isWhite : !isWhite)
            : null;
        if (finished) _saveResult(online, won);
        final event = won == true
            ? GameEvent.youWin
            : (won == false ? GameEvent.youLose : GameEvent.draw);
        final title = won == true
            ? context.t('Победа!', 'You won!')
            : (won == false
                  ? context.t('Поражение', 'You lost')
                  : context.t('Ничья', 'Draw'));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GameTopBar(
                onClose: () => Navigator.pop(context),
                balance: isWhite
                    ? materialBalance(game)
                    : -materialBalance(game),
                seconds: _seconds,
              ),
              const SizedBox(height: 6),
              _PlayerRow(
                name: opponent.isEmpty
                    ? context.t('Соперник', 'Opponent')
                    : opponent,
                caption: context.t('Соперник', 'Opponent'),
                active: !finished && !myTurn,
              ),
              const SizedBox(height: 10),
              ChessBoardView(
                game: game,
                flipped: !isWhite,
                lastMove: online.lastMove,
                enabled: online.status == 'active' && myTurn,
                onMove: (from, to) => _sendMove(matchId, from, to),
              ),
              const SizedBox(height: 10),
              _PlayerRow(
                name: AppScope.of(context).name,
                caption: context.t('Ты', 'You'),
                active: !finished && myTurn,
                avatar: AppScope.of(context).avatar,
              ),
              const SizedBox(height: 14),
              if (finished)
                GameResultPanel(
                  event: event,
                  title: title,
                  xp: won == true ? 20 : 8,
                  onRematch: null,
                  onExit: () => Navigator.pop(context),
                )
              else
                Center(
                  child: Text(
                    myTurn
                        ? context.t('Твой ход', 'Your move')
                        : context.t('Ход соперника…', 'Waiting for opponent…'),
                    style: DuoText.h2.copyWith(
                      color: myTurn ? DuoColors.green : DuoColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.name,
    required this.caption,
    required this.active,
    this.avatar,
  });

  final String name;
  final String caption;
  final bool active;
  final String? avatar;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: active ? DuoColors.green : DuoColors.border,
        width: 2,
      ),
    ),
    child: Row(
      children: [
        avatar != null
            ? PlayerAvatar(avatar: avatar!, name: name, size: 38)
            : InitialAvatar(name: name, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: DuoText.body.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(caption, style: DuoText.small.copyWith(fontSize: 12)),
            ],
          ),
        ),
        if (active)
          const Icon(
            Icons.hourglass_top_rounded,
            color: DuoColors.green,
            size: 22,
          ),
      ],
    ),
  );
}

class _Radar extends StatefulWidget {
  const _Radar({required this.active});

  final bool active;

  @override
  State<_Radar> createState() => _RadarState();
}

class _RadarState extends State<_Radar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _Radar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    height: 220,
    child: Stack(
      alignment: Alignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = (_controller.value + i / 3) % 1;
              return Opacity(
                opacity: widget.active ? (1 - t) * 0.6 : 0.15,
                child: Container(
                  width: 70 + 150 * t,
                  height: 70 + 150 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: DuoColors.blue, width: 3),
                  ),
                ),
              );
            },
          ),
        const CharacterBust(
          who: Who.maria,
          emotion: Emotion.thinking,
          height: 90,
        ),
      ],
    ),
  );
}
