import 'course_data.dart';
import 'course_model.dart';

export 'course_data.dart';
export 'course_model.dart';

/// All lessons in the order they unlock.
final List<Lesson> allLessons = [
  for (final unit in courseUnits) ...unit.lessons,
];

int lessonIndex(String id) => allLessons.indexWhere((lesson) => lesson.id == id);

CourseUnit unitOf(Lesson lesson) =>
    courseUnits.firstWhere((unit) => unit.lessons.contains(lesson));

String chestId(CourseUnit unit) => 'chest_${unit.id}';
