import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../../chess/board_utils.dart';
import '../../chess/board_view.dart';
import '../../core/theme.dart';
import '../../state/app_scope.dart';
import '../../state/game_record.dart';
import '../../widgets/duo_button.dart';

/// Step through a finished game move by move.
class ReplayPage extends StatefulWidget {
  const ReplayPage({required this.record, super.key});

  final GameRecord record;

  @override
  State<ReplayPage> createState() => _ReplayPageState();
}

class _ReplayPageState extends State<ReplayPage> {
  int _ply = 0;

  List<String> get _moves => widget.record.moves;

  void _go(int ply) => setState(() => _ply = ply.clamp(0, _moves.length));

  @override
  Widget build(BuildContext context) {
    final game = gameFromMoves(_moves, _ply);
    final last = _ply == 0 ? null : _moves[_ply - 1];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: DuoColors.bg,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '${context.t('Партия', 'Game')} · ${widget.record.opponent}',
          style: DuoText.h2,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _moves.isEmpty
                  ? Center(
                      child: Text(
                        context.t(
                          'Для этой партии не сохранены ходы.',
                          'No moves were saved for this game.',
                        ),
                        style: DuoText.body,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: ChessBoardView(
                            game: game,
                            enabled: false,
                            flipped: !widget.record.playerWhite,
                            lastMove: last,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          context.t(
                            'Ход $_ply из ${_moves.length}',
                            'Move $_ply of ${_moves.length}',
                          ),
                          style: DuoText.small.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DuoButton(
                                label: '',
                                icon: Icons.first_page_rounded,
                                kind: DuoButtonKind.outline,
                                onPressed: _ply == 0 ? null : () => _go(0),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DuoButton(
                                label: '',
                                icon: Icons.chevron_left_rounded,
                                kind: DuoButtonKind.outline,
                                onPressed: _ply == 0 ? null : () => _go(_ply - 1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DuoButton(
                                label: '',
                                icon: Icons.chevron_right_rounded,
                                onPressed: _ply == _moves.length ? null : () => _go(_ply + 1),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DuoButton(
                                label: '',
                                icon: Icons.last_page_rounded,
                                kind: DuoButtonKind.outline,
                                onPressed: _ply == _moves.length ? null : () => _go(_moves.length),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
