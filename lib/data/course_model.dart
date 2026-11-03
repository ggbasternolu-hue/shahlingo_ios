import '../core/tr.dart';

export '../core/tr.dart';

enum Who { sergei, maria }

enum Emotion { neutral, happy, sad, angry, surprised, thinking, smug }

enum MoveGoal { exact, mate, capture, check }

enum LessonKind { steps, game }

/// One spoken line in a dialogue.
class Line {
  const Line(this.who, this.emotion, this.text);

  final Who who;
  final Emotion emotion;
  final Tr text;
}

sealed class LessonStep {
  const LessonStep();
}

/// A short dialogue, optionally next to a board position.
class TalkStep extends LessonStep {
  const TalkStep({
    required this.lines,
    this.fen,
    this.highlight = const [],
  });

  final List<Line> lines;
  final String? fen;
  final List<String> highlight;
}

/// The learner must make a move on the board.
///
/// With [MoveGoal.exact] the first move must be `line[0]` (or one of [accept]);
/// the following entries alternate between scripted replies and further
/// learner moves. The other goals accept any move that mates / captures / checks.
class MoveStep extends LessonStep {
  const MoveStep({
    required this.who,
    required this.emotion,
    required this.prompt,
    required this.fen,
    required this.line,
    required this.accept,
    required this.goal,
    required this.hint,
    required this.hintSquares,
    required this.success,
    this.wrong,
  });

  final Who who;
  final Emotion emotion;
  final Tr prompt;
  final String fen;
  final List<String> line;
  final List<String> accept;
  final MoveGoal goal;
  final Tr hint;
  final List<String> hintSquares;
  final Tr success;
  final Tr? wrong;
}

class QuizStep extends LessonStep {
  const QuizStep({
    required this.who,
    required this.emotion,
    required this.question,
    required this.options,
    required this.correct,
    required this.explain,
    this.fen,
    this.highlight = const [],
  });

  final Who who;
  final Emotion emotion;
  final Tr question;
  final List<Tr> options;
  final int correct;
  final Tr explain;
  final String? fen;
  final List<String> highlight;
}

/// The learner taps squares on the board; the set must match [expected].
class TapStep extends LessonStep {
  const TapStep({
    required this.who,
    required this.emotion,
    required this.prompt,
    required this.fen,
    required this.expected,
    required this.explain,
  });

  final Who who;
  final Emotion emotion;
  final Tr prompt;
  final String fen;
  final List<String> expected;
  final Tr explain;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.kind,
    required this.steps,
  });

  final String id;
  final Tr title;
  final Tr subtitle;

  /// A piece letter ('p','n','b','r','q','k') or a symbolic key.
  final String icon;
  final LessonKind kind;
  final List<LessonStep> steps;
}

class CourseUnit {
  const CourseUnit({
    required this.id,
    required this.title,
    required this.description,
    required this.colorIndex,
    required this.chestAfter,
    required this.lessons,
  });

  final String id;
  final Tr title;
  final Tr description;
  final int colorIndex;

  /// A treasure chest appears after this many lessons of the unit.
  final int chestAfter;
  final List<Lesson> lessons;
}
