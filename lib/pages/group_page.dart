// lib/pages/group_page.dart
//
// 그룹 — UI만, 백엔드 추후

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D1B2A) : const Color(0xFFF7F9FC);
    final cardBg = isDark ? const Color(0xFF1B2D3F) : Colors.white;
    final text = isDark ? const Color(0xFFE8E3D8) : const Color(0xFF1A1A1A);
    final sub = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final primary = Theme.of(context).colorScheme.primary;
    const gold = Color(0xFFC9A84C);

    // 샘플 그룹 코드 (실제로는 서버에서 발급)
    const sampleCode = 'TRSR-A8F2';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('그룹',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          // ── 히어로 ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gold.withOpacity(isDark ? 0.18 : 0.1),
                  gold.withOpacity(isDark ? 0.06 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: gold.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.anchor_rounded, color: gold, size: 40),
                const SizedBox(height: 12),
                Text('함께 항해할 동료를 찾아요',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: text)),
                const SizedBox(height: 6),
                Text(
                  '성경 읽기 플랜을 함께 진행하고\n묵상과 기도 제목을 나눠요',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: sub, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── 그룹 만들기 ─────────────────────────────────
          _ActionCard(
            isDark: isDark,
            cardBg: cardBg,
            text: text,
            sub: sub,
            gold: gold,
            icon: Icons.add_circle_outline_rounded,
            title: '그룹 만들기',
            desc: '새 항해를 시작해요. 그룹 코드가 발급됩니다',
            actionLabel: '만들기',
            onTap: () {
              _showCreateDialog(sampleCode);
            },
          ),
          const SizedBox(height: 10),
          _ActionCard(
            isDark: isDark,
            cardBg: cardBg,
            text: text,
            sub: sub,
            gold: gold,
            icon: Icons.login_rounded,
            title: '그룹 참여',
            desc: '친구에게 받은 그룹 코드로 참여해요',
            actionLabel: '참여',
            onTap: _showJoinDialog,
          ),

          const SizedBox(height: 20),

          // ── 함께 읽는 플랜 (데모) ────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text('함께 읽는 플랜',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: sub)),
          ),
          _PlanChip(
            emoji: '📖',
            title: '30일 신약 완독',
            subtitle: '12명 참여 중 · D-18',
            isDark: isDark,
            cardBg: cardBg,
            text: text,
            sub: sub,
          ),
          const SizedBox(height: 8),
          _PlanChip(
            emoji: '🙏',
            title: '한 달 기도회',
            subtitle: '7명 참여 중 · D-5',
            isDark: isDark,
            cardBg: cardBg,
            text: text,
            sub: sub,
          ),

          const SizedBox(height: 24),
          Center(
            child: Text('백엔드 연동은 이후 버전에서 활성화됩니다',
                style: TextStyle(fontSize: 11, color: sub)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(String code) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2D3F) : Colors.white,
        title: const Text('그룹 코드'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('아래 코드를 친구와 공유하세요',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFC9A84C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFC9A84C).withOpacity(0.4)),
              ),
              child: Text(code,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: Color(0xFFC9A84C))),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('코드를 복사했어요'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('복사'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('닫기')),
        ],
      ),
    );
  }

  void _showJoinDialog() {
    _codeCtrl.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2D3F) : Colors.white,
        title: const Text('그룹 코드 입력'),
        content: TextField(
          controller: _codeCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'TRSR-XXXX',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('그룹 참여는 서버 연동 후 지원됩니다'),
                behavior: SnackBarBehavior.floating,
              ));
            },
            child: const Text('참여'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg, text, sub, gold;
  final IconData icon;
  final String title, desc, actionLabel;
  final VoidCallback onTap;
  const _ActionCard({
    required this.isDark,
    required this.cardBg,
    required this.text,
    required this.sub,
    required this.gold,
    required this.icon,
    required this.title,
    required this.desc,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: text)),
                const SizedBox(height: 2),
                Text(desc,
                    style: TextStyle(fontSize: 12, color: sub)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: gold.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(actionLabel,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFC9A84C))),
          ),
        ]),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String emoji, title, subtitle;
  final bool isDark;
  final Color cardBg, text, sub;
  const _PlanChip({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.cardBg,
    required this.text,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: text)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(fontSize: 11, color: sub)),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: sub, size: 18),
      ]),
    );
  }
}
