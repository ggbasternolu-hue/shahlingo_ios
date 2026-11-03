import 'dart:math';

import 'course_model.dart';

enum GameEvent {
  start,
  youCapture,
  youCheck,
  mariaCapture,
  mariaCheck,
  quiet,
  youWin,
  youLose,
  draw,
  resign,
}

class Reaction {
  const Reaction(this.who, this.emotion, this.text);

  final Who who;
  final Emotion emotion;
  final Tr text;
}

const Map<GameEvent, List<Reaction>> _pool = {
  GameEvent.start: [
    Reaction(Who.maria, Emotion.smug, Tr('Белыми играешь ты. Не обольщайся — я быстрая.', 'You have White. Don’t get comfy — I’m quick.')),
    Reaction(Who.sergei, Emotion.happy, Tr('Помни про центр и развитие фигур. Удачи!', 'Remember the centre and development. Good luck!')),
  ],
  GameEvent.youCapture: [
    Reaction(Who.maria, Emotion.angry, Tr('Эй! Это была моя фигура!', 'Hey! That was my piece!')),
    Reaction(Who.maria, Emotion.sad, Tr('Ладно, один — ноль. Запомню.', 'Fine, one–nil. I’ll remember.')),
    Reaction(Who.sergei, Emotion.happy, Tr('Хорошее взятие. Только проверь, что защищено.', 'Nice capture. Just check what’s protected.')),
  ],
  GameEvent.youCheck: [
    Reaction(Who.maria, Emotion.angry, Tr('Шах?! Не так быстро.', 'Check?! Not so fast.')),
    Reaction(Who.sergei, Emotion.surprised, Tr('Шах! Мария, внимательнее.', 'Check! Careful, Maria.')),
  ],
  GameEvent.mariaCapture: [
    Reaction(Who.maria, Emotion.happy, Tr('Ам! Вкусная фигура.', 'Nom! Tasty piece.')),
    Reaction(Who.maria, Emotion.smug, Tr('Это называется «бесплатно».', 'That’s called “free”.')),
    Reaction(Who.sergei, Emotion.thinking, Tr('Подумай: не оставил ли ты фигуру без защиты?', 'Did you leave a piece unprotected?')),
  ],
  GameEvent.mariaCheck: [
    Reaction(Who.maria, Emotion.smug, Tr('Шах. Звучит как гонг, правда?', 'Check. Sounds like a gong, right?')),
    Reaction(Who.sergei, Emotion.surprised, Tr('Шах! Уйди королём, закройся или возьми фигуру.', 'Check! Move, block or capture.')),
  ],
  GameEvent.quiet: [
    Reaction(Who.maria, Emotion.thinking, Tr('Хм… интересный ход. Нет, правда.', 'Hm… interesting move. Really.')),
    Reaction(Who.maria, Emotion.neutral, Tr('Я думаю на два хода дальше тебя.', 'I’m thinking two moves ahead of you.')),
    Reaction(Who.sergei, Emotion.neutral, Tr('Сначала развивай фигуры, потом атакуй.', 'Develop first, attack later.')),
    Reaction(Who.sergei, Emotion.thinking, Tr('Перед каждым ходом ищи угрозы соперника.', 'Look for threats before every move.')),
  ],
  GameEvent.youWin: [
    Reaction(Who.maria, Emotion.sad, Tr('Ладно, реванш! Я просто разогревалась.', 'Okay, rematch! I was only warming up.')),
    Reaction(Who.sergei, Emotion.happy, Tr('Мат! Ты нашёл решающий ход. Отличная партия!', 'Checkmate! You found the winning idea. Great game!')),
  ],
  GameEvent.youLose: [
    Reaction(Who.maria, Emotion.happy, Tr('Мат! Реванш?', 'Checkmate! Rematch?')),
    Reaction(Who.sergei, Emotion.thinking, Tr('Не расстраивайся. Каждая партия — урок.', 'Don’t be sad. Every game is a lesson.')),
  ],
  GameEvent.draw: [
    Reaction(Who.maria, Emotion.neutral, Tr('Ничья. Значит, нужен реванш.', 'A draw. So we need a rematch.')),
    Reaction(Who.sergei, Emotion.neutral, Tr('Равная борьба. Хорошая партия.', 'An even fight. A good game.')),
  ],
  GameEvent.resign: [
    Reaction(Who.maria, Emotion.smug, Tr('Сдаёшься? Я запомню этот день.', 'Resigning? I’ll remember this day.')),
    Reaction(Who.sergei, Emotion.thinking, Tr('Иногда сдаться — тоже урок. Разберём ошибки?', 'Sometimes resigning is a lesson too. Review the mistakes?')),
  ],
};

Reaction pickReaction(GameEvent event, Random random, {Who? only}) {
  final all = _pool[event]!;
  final list = only == null ? all : all.where((r) => r.who == only).toList();
  final source = list.isEmpty ? all : list;
  return source[random.nextInt(source.length)];
}

/// Both characters' lines for an end-of-game dialogue.
List<Reaction> endingLines(GameEvent event) => _pool[event]!;
