# Shahlingo

Шахматное приложение в стиле Duolingo: уроки с персонажами Сергеем и Марией, партии с компьютером, игра вдвоём и онлайн (Firebase).

## Запуск

```bash
flutter pub get
flutter test        # проверяет все позиции уроков библиотекой chess
flutter run
```

Онлайн-рейтинг начинается с 0 Elo и меняется по формуле Elo с коэффициентом K=32;
после первых пяти онлайн-партий рейтинг выходит из калибровки.

## Сборки

```bash
flutter build apk --release
flutter build windows --release
flutter build web --release --base-href /shahlingo_ios/
```

Web-сборка публикуется на GitHub Pages через GitHub Actions при push в `main`.

## Структура `lib/`

| Папка | Что внутри |
|---|---|
| `core/` | тема и палитра (`theme.dart`), двуязычные строки (`tr.dart`) |
| `data/` | модель курса, **`course_data.dart` (генерируется)**, реплики персонажей в партиях |
| `state/` | `PlayerProgress` (XP, серия дней, самоцветы, уроки, история), `AppScope` |
| `services/` | Firebase, ИИ Марии (`chess_ai.dart`, работает в isolate) |
| `chess/` | векторные фигуры, доска с анимацией, утилиты |
| `widgets/` | кнопка `DuoButton`, персонаж с эмоциями, пузыри, прогресс-бар, конфетти |
| `features/` | `onboarding`, `shell`, `learn`, `lesson`, `play`, `league`, `profile` |

## Курс

6 разделов, 19 уроков. Типы шагов: диалог, ход на доске, тест, отметка клеток.
Курс описан в `tools/course.py`; там же независимая проверка (легальность ходов, мат, взятия,
вилки, связки). Чтобы изменить урок, правьте `tools/course.py` и запустите `python3 tools/gen_dart.py`.

## Шрифт

В `lib/core/theme.dart` есть константа `kFontFamily`. Добавьте шрифт (например Nunito) в
`pubspec.yaml` → `flutter: fonts:` и укажите его имя — внешний вид станет ещё ближе к Duolingo.

## Персонажи

Эмоции вырезаны из листов спрайтов (`design_sources/`) в `assets/characters/`.
Нет грустного Сергея и удивлённой Марии — для них автоматически берётся ближайшая эмоция
(`characterAsset` в `widgets/character.dart`).
