import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/models.dart';
import '../theme/app_theme.dart';

Color toneColor(TileTone tone) {
  switch (tone) {
    case TileTone.mint:
      return AppColors.mint;
    case TileTone.sage:
      return AppColors.sage;
    case TileTone.gold:
      return AppColors.gold;
    case TileTone.green:
      return AppColors.green;
    case TileTone.red:
      return AppColors.red;
  }
}

Color toneText(TileTone tone) {
  switch (tone) {
    case TileTone.mint:
    case TileTone.sage:
      return AppColors.pine;
    default:
      return Colors.white;
  }
}

/// Cream top bar: menu icon, pine logo chip, wordmark, language bubble.
class TawasulTopBar extends StatelessWidget {
  const TawasulTopBar({super.key, required this.title, required this.subtitle, this.onMenu});

  final String title;
  final String subtitle;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final strings = L10n.of(context);
    final scope = LocaleScope.of(context);
    return Container(
      color: AppColors.cream,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (onMenu != null)
              IconButton(
                onPressed: onMenu,
                tooltip: strings.menu,
                icon: const Icon(Icons.menu, color: AppColors.pine, size: 26),
              )
            else
              const SizedBox(width: 48),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.pine, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.school_rounded, color: AppColors.cream, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: AppColors.pine, fontSize: 19, fontWeight: FontWeight.w900, height: 1.1)),
                  Text(subtitle.toUpperCase(),
                      style: const TextStyle(color: AppColors.muted, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
                ],
              ),
            ),
            InkWell(
              onTap: scope.toggle,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(strings.language,
                    style: const TextStyle(color: AppColors.pine, fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eyebrow + oversized page title, as in the new design ("MY CHILDREN / Parent portal").
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.eyebrow, required this.title});

  final String eyebrow;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow.toUpperCase(),
              style: const TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 2.4)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(color: AppColors.pine, fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
        ],
      ),
    );
  }
}

class OfflineRibbon extends StatelessWidget {
  const OfflineRibbon({super.key, required this.isOffline, required this.pendingDrafts});

  final bool isOffline;
  final int pendingDrafts;

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingDrafts == 0) return const SizedBox.shrink();
    final strings = L10n.of(context);
    final text = isOffline ? strings.offlineBanner : strings.pendingDrafts(pendingDrafts);
    return Container(
      width: double.infinity,
      color: AppColors.gold,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(text, style: const TextStyle(color: AppColors.pine, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}

/// Pine hero card decorated with terracotta and gold circles.
class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.greeting, required this.name, required this.subtitle});

  final String greeting;
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(color: AppColors.pine, borderRadius: BorderRadius.circular(30)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -46,
              end: -30,
              child: _circle(150, AppColors.red),
            ),
            PositionedDirectional(
              bottom: -34,
              end: 64,
              child: _circle(96, AppColors.gold),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (greeting.isNotEmpty)
                    Text(greeting,
                        style: const TextStyle(color: AppColors.mintText, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.4)),
                  if (greeting.isNotEmpty) const SizedBox(height: 6),
                  Text(name,
                      style: const TextStyle(color: AppColors.cream, fontSize: 26, fontWeight: FontWeight.w900, height: 1.15)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(subtitle, style: const TextStyle(color: AppColors.mintText, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circle(double size, Color color) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.metrics});

  final List<MetricTileData> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
        children: metrics.map((metric) => MetricTile(data: metric)).toList(),
      ),
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({super.key, required this.data});

  final MetricTileData data;

  @override
  Widget build(BuildContext context) {
    final color = toneColor(data.tone);
    final text = toneText(data.tone);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(data.title, style: TextStyle(color: text.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w700)),
          Text(data.value, style: TextStyle(color: text, fontSize: 34, fontWeight: FontWeight.w900, height: 1.05)),
          if (data.hint.isNotEmpty)
            Text(data.hint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: text.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class WhitePanel extends StatelessWidget {
  const WhitePanel({super.key, required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(color: AppColors.pine, fontSize: 21, fontWeight: FontWeight.w900)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message ?? L10n.of(context).noData, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Round colored avatar derived from the title, like the roster circles.
class AvatarCircle extends StatelessWidget {
  const AvatarCircle({super.key, required this.label, this.size = 48});

  final String label;
  final double size;

  static const _palette = [AppColors.gold, AppColors.red, AppColors.green, AppColors.pine, AppColors.sage];

  @override
  Widget build(BuildContext context) {
    final color = _palette[label.hashCode.abs() % _palette.length];
    final dark = color == AppColors.gold || color == AppColors.sage;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(label,
          style: TextStyle(color: dark ? AppColors.pine : Colors.white, fontSize: size * 0.3, fontWeight: FontWeight.w800)),
    );
  }
}

class RowTile extends StatelessWidget {
  const RowTile({super.key, required this.leading, required this.title, this.subtitle = '', this.trailing = '', this.trailingColor});

  final String leading;
  final String title;
  final String subtitle;
  final String trailing;
  final Color? trailingColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarCircle(label: leading),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          if (trailing.isNotEmpty)
            Text(trailing, style: TextStyle(color: trailingColor ?? AppColors.pine, fontSize: 14, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Small pill used for statuses (Present / Late / Overdue / Paid ...).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color, this.darkText = false});

  final String label;
  final Color color;
  final bool darkText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(color: darkText ? AppColors.pine : Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
    );
  }
}

class LessonList extends StatelessWidget {
  const LessonList({super.key, required this.lessons, this.emptyMessage});

  final List<LessonItem> lessons;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) return EmptyState(message: emptyMessage);
    return Column(
      children: lessons
          .map((lesson) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(16)),
                      child: Text(lesson.time.isEmpty ? '—' : lesson.time.split(' ').first,
                          style: const TextStyle(color: AppColors.pine, fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(lesson.subject,
                              style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w700)),
                          if ([lesson.group, lesson.date].any((p) => p.isNotEmpty))
                            Text([lesson.group, lesson.date].where((p) => p.isNotEmpty).join(' · '),
                                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class StudentList extends StatelessWidget {
  const StudentList({super.key, required this.students, this.emptyMessage, this.onTap});

  final List<StudentItem> students;
  final String? emptyMessage;
  final void Function(StudentItem student)? onTap;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) return EmptyState(message: emptyMessage);
    return Column(
      children: students
          .map((student) => InkWell(
                onTap: onTap == null ? null : () => onTap!(student),
                child: RowTile(
                  leading: student.initials,
                  title: student.name,
                  subtitle: student.group,
                  trailing: student.attendance,
                ),
              ))
          .toList(),
    );
  }
}

class HomeworkList extends StatelessWidget {
  const HomeworkList({super.key, required this.items});

  final List<HomeworkItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const EmptyState();
    final strings = L10n.of(context);
    return Column(
      children: items
          .map((item) {
            final color = AppColors.subjectColor(item.subject);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 6),
                    Text(item.title, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
                  ]),
                  if (item.subject.isNotEmpty)
                    Text(item.subject, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.description, style: const TextStyle(color: AppColors.ink, fontSize: 13)),
                  ],
                  if (item.dueDate.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('${strings.dueDate}: ${item.dueDate}',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            );
          }).toList(),
    );
  }
}

class AttendanceList extends StatelessWidget {
  const AttendanceList({super.key, required this.records, this.showName = false});

  final List<AttendanceRecord> records;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const EmptyState();
    return Column(
      children: records.map((record) {
        final status = record.status.toLowerCase();
        final present = status.startsWith('present');
        final late = status.startsWith('late');
        final color = present ? AppColors.green : (late ? AppColors.gold : AppColors.red);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(showName && record.note.isNotEmpty ? record.note : record.date,
                        style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                    if ((showName ? record.date : record.context).isNotEmpty)
                      Text(showName ? record.date : record.context,
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              ),
              StatusPill(label: record.status, color: color, darkText: late),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class NoticeList extends StatelessWidget {
  const NoticeList({super.key, required this.notices});

  final List<NoticeItem> notices;

  @override
  Widget build(BuildContext context) {
    if (notices.isEmpty) return const EmptyState();
    return Column(
      children: notices
          .map((notice) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notice.title,
                              style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w700)),
                          Text([notice.kind, notice.date].where((part) => part.isNotEmpty).join(' · '),
                              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.pine,
          foregroundColor: AppColors.cream,
          shape: const StadiumBorder(),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.pine,
          side: const BorderSide(color: AppColors.line, width: 1.5),
          backgroundColor: Colors.white,
          shape: const StadiumBorder(),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
      ),
    );
  }
}

class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.controller, this.hint = '', this.maxLines = 1, this.obscure = false});

  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: obscure ? 1 : maxLines,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: AppColors.pine, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
