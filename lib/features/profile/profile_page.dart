import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../state/app_scope.dart';
import '../../widgets/character.dart';
import '../../widgets/common.dart';
import '../../widgets/duo_button.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _editName(BuildContext context) async {
    final progress = AppScope.read(context);
    final controller = TextEditingController(text: progress.name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t('Твоё имя', 'Your name'), style: DuoText.h2),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          style: DuoText.body,
          decoration: InputDecoration(
            filled: true,
            fillColor: DuoColors.bg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DuoColors.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: DuoColors.blue, width: 2),
            ),
          ),
          onSubmitted: (text) => Navigator.pop(context, text),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          DuoButton(
            label: context.t('Сохранить', 'Save'),
            onPressed: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await progress.updateName(value);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.progress;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Center(
              child: PlayerAvatar(avatar: p.avatar, name: p.name, size: 112),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DuoText.h1,
                  ),
                ),
                IconButton(
                  tooltip: context.t('Изменить имя', 'Edit name'),
                  onPressed: () => _editName(context),
                  icon: const Icon(Icons.edit_rounded, color: DuoColors.muted, size: 22),
                ),
              ],
            ),
            Text(
              '${p.rank} · ${context.t('уровень', 'level')} ${p.level}',
              textAlign: TextAlign.center,
              style: DuoText.small,
            ),
            const SizedBox(height: 22),
            Text(context.t('АВАТАР', 'AVATAR'), style: DuoText.label),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final option in const ['sergei', 'maria', 'initial']) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () => p.setAvatar(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: p.avatar == option ? DuoColors.blue : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: PlayerAvatar(avatar: option, name: p.name, size: 56),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 22),
            Text(context.t('СТАТИСТИКА', 'STATISTICS'), style: DuoText.label),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.6,
              children: [
                _Stat(Icons.local_fire_department_rounded, DuoColors.orange, '${p.streak}', context.t('дней подряд', 'day streak')),
                _Stat(Icons.bolt_rounded, DuoColors.yellow, '${p.xp}', context.t('всего опыта', 'total XP')),
                _Stat(Icons.diamond_rounded, DuoColors.blue, '${p.gems}', context.t('самоцветов', 'gems')),
                _Stat(Icons.show_chart_rounded, DuoColors.teal, '${p.elo}', context.t('рейтинг ЭЛО', 'ELO rating')),
                _Stat(Icons.school_rounded, DuoColors.purple, '${p.lessonsCompleted}', context.t('уроков пройдено', 'lessons done')),
                _Stat(Icons.emoji_events_rounded, DuoColors.green, '${p.wins}', context.t('побед', 'wins')),
              ],
            ),
            const SizedBox(height: 22),
            Text(context.t('НАСТРОЙКИ', 'SETTINGS'), style: DuoText.label),
            const SizedBox(height: 10),
            DuoPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.translate_rounded,
                    title: context.t('Язык', 'Language'),
                    trailing: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: false, label: Text('RU')),
                        ButtonSegment(value: true, label: Text('EN')),
                      ],
                      selected: {p.english},
                      onSelectionChanged: (_) => p.toggleLanguage(),
                    ),
                  ),
                  const Divider(height: 1),
                  _SettingRow(
                    icon: p.firebaseReady ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    color: p.firebaseReady ? DuoColors.green : DuoColors.orange,
                    title: p.firebaseReady
                        ? context.t('Облако подключено', 'Cloud connected')
                        : context.t('Облако недоступно', 'Cloud unavailable'),
                    subtitle: p.firebaseReady ? null : p.cloudError,
                    trailing: p.firebaseReady
                        ? null
                        : TextButton(
                            onPressed: p.retryFirebase,
                            child: Text(context.t('Повторить', 'Retry')),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.color, this.value, this.label);

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: DuoColors.border, width: 2),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: DuoColors.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DuoText.small.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.color = DuoColors.muted,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: DuoText.body.copyWith(fontWeight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!, style: DuoText.small.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}
