import 'dart:async';
import 'dart:math';

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../chess/board_utils.dart';
import '../../chess/board_view.dart';
import '../../core/theme.dart';
import '../../data/banter.dart';
import '../../data/course_model.dart';
import '../../services/chess_ai.dart';
import '../../state/app_scope.dart';
import '../../state/game_record.dart';
import '../../widgets/duo_button.dart';
import 'game_widgets.dart';

enum GameMode { maria, friend }

/// A full game against Maria (computer) or a friend on the same device.
class GameScreen extends StatefulWidget {
  const GameScreen({
    this.mode = GameMode.maria,
    this.level = 2,
    this.lessonId,
    super.key,
  });

  final GameMode mode;

  /// Maria's strength, 1 (easy) to 3 (hard).
  final int level;

  /// When started from the course, finishing the game completes this lesson.
  final String? lessonId;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _random = Random();
  late chess.Chess _game;
  final List<String> _moves = [];
  String? _lastMove;
  bool _thinking = false;
  bool _over = false;
  int _seconds = 0;
  Timer? _clock;
  late Reaction _say;
  GameEvent? _ending;
  String _endTitle = '';
  int _endXp = 0;

  bool get _vsMaria => widget.mode == GameMode.maria;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _clock?.cancel();
    _game = chess.Chess();
    _moves.clear();
    _lastMove = null;
    _thinking = false;
    _over = false;
    _ending = null;
    _seconds = 0;
    _say = pickReaction(GameEvent.start, _random);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_over) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  void _afterMove(
    String from,
    String to, {
    required bool byPlayer,
    required bool capture,
  }) {
    _moves.add('$from$to');
    _lastMove = '$from$to';
    if (_game.game_over) {
      _finish();
      return;
    }
    final event = _game.in_check
        ? (byPlayer ? GameEvent.youCheck : GameEvent.mariaCheck)
        : capture
        ? (byPlayer ? GameEvent.youCapture : GameEvent.mariaCapture)
        : GameEvent.quiet;
    if (!_vsMaria) {
      if (event != GameEvent.quiet) {
        _say = pickReaction(event, _random, only: Who.sergei);
      }
      return;
    }
    if (byPlayer && event == GameEvent.quiet) return;
    _say = pickReaction(event, _random);
  }

  void _onMove(String from, String to) {
    if (_over || _thinking) return;
    if (_vsMaria && _game.turn != chess.Color.WHITE) return;
    final capture = isCaptureMove(_game, from, to);
    if (!playMove(_game, from, to)) return;
    setState(() => _afterMove(from, to, byPlayer: true, capture: capture));
    if (_vsMaria && !_over) _mariaTurn();
  }

  Future<void> _mariaTurn() async {
    setState(() => _thinking = true);
    final started = DateTime.now();
    final uci = await pickAiMove(_game.fen, widget.level);
    final elapsed = DateTime.now().difference(started);
    if (elapsed < const Duration(milliseconds: 650)) {
      await Future<void>.delayed(const Duration(milliseconds: 650) - elapsed);
    }
    if (!mounted || _over) return;
    final legalMoves = _game.generate_moves();
    if (legalMoves.isEmpty) {
      setState(() {
        _thinking = false;
        _finish();
      });
      return;
    }
    chess.Move? selectedMove;
    if (uci != null) {
      for (final candidate in legalMoves) {
        if (candidate.fromAlgebraic == uciFrom(uci) &&
            candidate.toAlgebraic == uciTo(uci)) {
          selectedMove = candidate;
          break;
        }
      }
    }
    if (selectedMove == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.t(
              'ИИ Марии не ответил; сделан случайный допустимый ход.',
              'Maria’s AI did not respond; a random legal move was made.',
            ),
          ),
        ),
      );
    }
    final move = selectedMove ?? legalMoves[_random.nextInt(legalMoves.length)];
    final from = move.fromAlgebraic;
    final to = move.toAlgebraic;
    final capture = isCaptureMove(_game, from, to);
    if (!playMove(_game, from, to)) {
      throw StateError('Maria returned an illegal chess move: $uci');
    }
    setState(() {
      _thinking = false;
      _afterMove(from, to, byPlayer: false, capture: capture);
    });
  }

  void _finish({bool resigned = false}) {
    _over = true;
    _clock?.cancel();
    GameResult result;
    if (resigned) {
      result = GameResult.loss;
    } else if (_game.in_checkmate) {
      final whiteWon = _game.turn == chess.Color.BLACK;
      result = _vsMaria
          ? (whiteWon ? GameResult.win : GameResult.loss)
          : GameResult.win;
    } else {
      result = GameResult.draw;
    }
    final event = switch (result) {
      GameResult.win => GameEvent.youWin,
      GameResult.draw => GameEvent.draw,
      GameResult.loss => resigned ? GameEvent.resign : GameEvent.youLose,
    };
    _ending = event;
    final english = context.isEnglish;
    if (!_vsMaria) {
      final whiteWon = _game.turn == chess.Color.BLACK;
      _endTitle = result == GameResult.draw
          ? (english ? 'Draw' : 'Ничья')
          : (whiteWon
                ? (english ? 'White wins!' : 'Победа белых!')
                : (english ? 'Black wins!' : 'Победа чёрных!'));
    } else {
      _endTitle = switch (result) {
        GameResult.win => english ? 'You won!' : 'Победа!',
        GameResult.draw => english ? 'Draw' : 'Ничья',
        GameResult.loss => english ? 'You lost' : 'Поражение',
      };
    }
    _endXp = switch (result) {
      GameResult.win => 30,
      GameResult.draw => 15,
      GameResult.loss => 10,
    };
    final progress = AppScope.read(context);
    unawaited(
      progress.recordGame(
        GameRecord(
          opponent: _vsMaria
              ? (english ? 'Maria' : 'Мария')
              : (english ? 'Friend' : 'Друг'),
          result: result,
          moves: List.of(_moves),
          playedAtMs: DateTime.now().millisecondsSinceEpoch,
          playerWhite: true,
        ),
        gainedXp: _endXp,
      ),
    );
    final lessonId = widget.lessonId;
    if (lessonId != null) {
      unawaited(
        progress.completeLesson(
          lessonId,
          earnedStars: result == GameResult.win
              ? 3
              : (result == GameResult.draw ? 2 : 1),
        ),
      );
    }
  }

  void _undo() {
    if (_thinking || _over || _moves.length < 2) return;
    setState(() {
      _moves.removeLast();
      _moves.removeLast();
      _game = gameFromMoves(_moves);
      _lastMove = _moves.isEmpty ? null : _moves.last;
    });
  }

  Future<void> _confirmExit() async {
    if (_over || _moves.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Сдаться?', 'Resign?'), style: DuoText.h2),
        content: Text(
          context.t(
            'Партия будет засчитана как поражение.',
            'The game will count as a loss.',
          ),
          style: DuoText.body,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsOverflowDirection: VerticalDirection.down,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          DuoButton(
            label: context.t('Продолжить игру', 'Keep playing'),
            onPressed: () => Navigator.pop(context, false),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              context.t('СДАТЬСЯ', 'RESIGN'),
              style: const TextStyle(
                color: DuoColors.red,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      setState(() => _finish(resigned: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = materialBalance(_game);
    final turnText = _over
        ? ''
        : _thinking
        ? context.t('Мария думает…', 'Maria is thinking…')
        : _game.turn == chess.Color.WHITE
        ? (_vsMaria
              ? context.t('Твой ход', 'Your move')
              : context.t('Ход белых', 'White to move'))
        : (_vsMaria ? '' : context.t('Ход чёрных', 'Black to move'));
    return PopScope(
      canPop: _over || _moves.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GameTopBar(
                      onClose: _confirmExit,
                      balance: _vsMaria ? balance : balance,
                      seconds: _seconds,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.t('СЫГРАЕМ В ШАХМАТЫ', 'LET’S PLAY CHESS'),
                      textAlign: TextAlign.center,
                      style: DuoText.h2.copyWith(letterSpacing: 0.6),
                    ),
                    const SizedBox(height: 10),
                    GameSpeaker(reaction: _say),
                    const SizedBox(height: 8),
                    ChessBoardView(
                      game: _game,
                      enabled: !_over && !_thinking,
                      lastMove: _lastMove,
                      onMove: _onMove,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 56,
                      child: _over
                          ? const SizedBox.shrink()
                          : Row(
                              children: [
                                _RoundIcon(
                                  icon: Icons.undo_rounded,
                                  tooltip: context.t('Отменить ход', 'Undo'),
                                  onTap:
                                      _vsMaria &&
                                          !_thinking &&
                                          _moves.length >= 2
                                      ? _undo
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                _RoundIcon(
                                  icon: Icons.flag_outlined,
                                  tooltip: context.t('Сдаться', 'Resign'),
                                  onTap: _moves.isEmpty ? null : _confirmExit,
                                ),
                                Expanded(
                                  child: Text(
                                    turnText,
                                    textAlign: TextAlign.right,
                                    style: DuoText.small.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                    if (_over && _ending != null)
                      GameResultPanel(
                        event: _ending!,
                        title: _endTitle,
                        xp: _endXp,
                        onRematch: widget.lessonId == null
                            ? () => setState(_newGame)
                            : null,
                        onExit: () => Navigator.pop(context, true),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: onTap == null
                ? DuoColors.border.withValues(alpha: 0.5)
                : DuoColors.border,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: onTap == null ? DuoColors.border : DuoColors.muted,
          size: 26,
        ),
      ),
    ),
  );
}
