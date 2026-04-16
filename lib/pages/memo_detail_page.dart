// lib/pages/memo_detail_page.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/memo.dart';
import '../models/verse_ref.dart';
import '../services/memo_service.dart';
import '../services/bookmark_service.dart';

class MemoDetailPage extends StatefulWidget {
  final Memo? existingMemo;
  final VerseRef? initialVerse;

  const MemoDetailPage({super.key, this.existingMemo, this.initialVerse});

  @override
  State<MemoDetailPage> createState() => _MemoDetailPageState();
}

class _MemoDetailPageState extends State<MemoDetailPage> {
  static const _uuid = Uuid();

  late TextEditingController _titleCtrl;
  late quill.QuillController _quillCtrl;
  final FocusNode _editorFocus = FocusNode();
  final ScrollController _editorScroll = ScrollController();

  // 이미지 저장소
  final Map<String, Uint8List> _imageBytes = {}; // 웹
  final Map<String, String> _imagePaths = {};    // 모바일

  // 구절 블록
  List<VerseRef> _verses = [];

  // 드로잉
  bool _isDrawingMode = false;
  List<_Stroke> _strokes = [];
  List<Offset> _currentStroke = [];
  Color _penColor = Colors.black;
  double _penWidth = 2.5;
  bool _isEraser = false;

  // 중복 저장 방지
  bool _didSave = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingMemo != null) {
      final m = widget.existingMemo!;
      _titleCtrl = TextEditingController(text: m.title);

      if (m.quillDelta != null && m.quillDelta!.isNotEmpty) {
        try {
          final doc = quill.Document.fromJson(jsonDecode(m.quillDelta!));
          _quillCtrl = quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } catch (_) {
          _quillCtrl = quill.QuillController.basic();
        }
      } else {
        final plainText = m.content;
        if (plainText.isNotEmpty) {
          final doc = quill.Document()..insert(0, plainText);
          _quillCtrl = quill.QuillController(
            document: doc,
            selection: const TextSelection.collapsed(offset: 0),
          );
        } else {
          _quillCtrl = quill.QuillController.basic();
        }
      }

      _verses = m.verses.map((b) => b.verseRef!).toList();

      for (final block in m.blocks) {
        if (block.type == MemoBlockType.text &&
            block.textContent.startsWith('__IMAGE__:')) {
          final parts = block.textContent.split(':');
          if (parts.length >= 3) {
            final id = parts[1];
            final path = parts.sublist(2).join(':');
            _imagePaths[id] = path;
          }
        }
      }

      _strokes = m.blocks
          .where((b) => b.type == MemoBlockType.drawing)
          .expand((b) => b.strokes)
          .map((s) => _Stroke(
                points: List.from(s.points),
                color: s.color,
                width: s.width,
              ))
          .toList();
    } else {
      _titleCtrl = TextEditingController();
      _quillCtrl = quill.QuillController.basic();
      if (widget.initialVerse != null) {
        _verses.add(widget.initialVerse!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _quillCtrl.dispose();
    _editorFocus.dispose();
    _editorScroll.dispose();
    super.dispose();
  }

  // ── 저장 (중복 방지)
  Future<void> _save() async {
    if (_didSave) return;
    _didSave = true;

    final title = _titleCtrl.text.trim();
    final deltaJson = jsonEncode(_quillCtrl.document.toDelta().toJson());
    final plainText = _quillCtrl.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty && _verses.isEmpty &&
        _strokes.isEmpty) {
      _didSave = false;
      return;
    }

    final blocks = <MemoBlock>[];

    for (final ref in _verses) {
      blocks.add(MemoBlock(
        id: _uuid.v4(),
        type: MemoBlockType.verse,
        verseRef: ref,
      ));
    }

    for (final entry in _imagePaths.entries) {
      blocks.add(MemoBlock(
        id: _uuid.v4(),
        type: MemoBlockType.text,
        textContent: '__IMAGE__:${entry.key}:${entry.value}',
      ));
    }

    if (_strokes.isNotEmpty) {
      final drawBlock = MemoBlock(id: _uuid.v4(), type: MemoBlockType.drawing);
      for (final s in _strokes) {
        drawBlock.strokes.add(DrawStroke(
          points: s.points,
          colorValue: s.color.value,
          width: s.width,
        ));
      }
      blocks.add(drawBlock);
    }

    final memo = widget.existingMemo != null
        ? widget.existingMemo!.copyWith(
            title: title,
            blocks: blocks,
            quillDelta: deltaJson,
            updatedAt: DateTime.now(),
          )
        : Memo(
            id: _uuid.v4(),
            title: title,
            blocks: blocks,
            quillDelta: deltaJson,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

    await MemoService.save(memo);
  }

  // ── 이미지 선택 → QuillEditor 커서 위치에 삽입
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 80);
      if (picked == null) return;

      final id = _uuid.v4();

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        _imageBytes[id] = bytes;
      } else {
        _imagePaths[id] = picked.path;
      }

      // 커서 위치에 이미지 embed 삽입
      final index = _quillCtrl.selection.baseOffset;
      final length = _quillCtrl.selection.extentOffset - index;
      _quillCtrl.replaceText(
        index,
        length,
        quill.BlockEmbed.image(id),
        TextSelection.collapsed(offset: index + 1),
      );

      // 이미지 아래 줄바꿈 추가 → 이미지 아래 텍스트 입력 가능
      Future.delayed(const Duration(milliseconds: 150), () {
        final newIndex = _quillCtrl.selection.baseOffset;
        _quillCtrl.replaceText(
          newIndex,
          0,
          '\n',
          TextSelection.collapsed(offset: newIndex + 1),
        );
        _editorFocus.requestFocus();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('이미지를 불러오지 못했어요'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ── 구절 시트
  void _showVerseSheet(bool isDark) {
    final bookmarks = BookmarkService.getAll();
    final primary = Theme.of(context).colorScheme.primary;
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final secondary = const Color(0xFF8E8E93);
    final divider = isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: secondary, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            Text('북마크에서 구절 추가',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
            const SizedBox(height: 4),
            Text('탭하면 구절이 추가돼요',
                style: TextStyle(fontSize: 12, color: secondary)),
            const SizedBox(height: 12),
            Expanded(
              child: bookmarks.isEmpty
                  ? Center(
                      child: Text('저장된 북마크가 없어요',
                          style: TextStyle(color: secondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: bookmarks.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: divider),
                      itemBuilder: (ctx2, i) {
                        final bm = bookmarks[i];
                        final already =
                            _verses.any((v) => v.key == bm.verseRef.key);
                        return GestureDetector(
                          onTap: already
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  setState(() => _verses.add(bm.verseRef));
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(bm.verseRef.label,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: already ? secondary : primary)),
                                      Text(bm.verseRef.verseText,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 13, color: secondary)),
                                    ],
                                  ),
                                ),
                                Icon(
                                  already
                                      ? Icons.check_circle_rounded
                                      : Icons.add_circle_outline_rounded,
                                  color: already ? secondary : primary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleDrawMode() {
    setState(() {
      _isDrawingMode = !_isDrawingMode;
      if (_isDrawingMode) _editorFocus.unfocus();
    });
  }

  // ── 구절 카드 복사
  void _copyVerse(VerseRef ref) {
    Clipboard.setData(ClipboardData(text: '${ref.label}\n${ref.verseText}'));
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${ref.label} 복사됐어요'),
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _formattedDate() {
    final now = widget.existingMemo?.updatedAt ?? DateTime.now();
    const months = ['1월','2월','3월','4월','5월','6월',
                    '7월','8월','9월','10월','11월','12월'];
    final h = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final ampm = now.hour >= 12 ? '오후' : '오전';
    return '${now.year}년 ${months[now.month - 1]} ${now.day}일 $ampm $h:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondary = const Color(0xFF8E8E93);
    final primary = Theme.of(context).colorScheme.primary;
    final dividerColor =
        isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA);

    final imageEmbedBuilder = _ImageEmbedBuilder(
      imageBytes: _imageBytes,
      imagePaths: _imagePaths,
      isDark: isDark,
    );

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        if (!_didSave) await _save();
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: bg,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: primary, size: 20),
            onPressed: () async {
              await _save();
              if (mounted) Navigator.pop(context);
            },
          ),
          actions: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: _isDrawingMode
                    ? primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  _isDrawingMode ? Icons.draw_rounded : Icons.draw_outlined,
                  color: _isDrawingMode ? primary : secondary,
                  size: 22,
                ),
                onPressed: _toggleDrawMode,
              ),
            ),
            TextButton(
              onPressed: () async {
                await _save();
                if (mounted) Navigator.pop(context);
              },
              child: Text('완료',
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
            ),
            const SizedBox(width: 4),
          ],
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 제목 + 날짜
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleCtrl,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _editorFocus.requestFocus(),
                    decoration: InputDecoration(
                      hintText: '제목',
                      hintStyle: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: secondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                  Text(_formattedDate(),
                      style: TextStyle(fontSize: 12, color: secondary)),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            Divider(height: 1, color: dividerColor),

            // ── 툴바
            if (!_isDrawingMode)
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFF9F9F9),
                  border: Border(
                      bottom: BorderSide(color: dividerColor, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: quill.QuillSimpleToolbar(
                        controller: _quillCtrl,
                        config: quill.QuillSimpleToolbarConfig(
                          multiRowsDisplay: false,
                          showBoldButton: true,
                          showUnderLineButton: true,
                          showItalicButton: false,
                          showStrikeThrough: false,
                          showFontSize: true,
                          showFontFamily: false,
                          showColorButton: false,
                          showBackgroundColorButton: false,
                          showClearFormat: true,
                          showHeaderStyle: false,
                          showListNumbers: false,
                          showListBullets: false,
                          showListCheck: false,
                          showCodeBlock: false,
                          showQuote: false,
                          showIndent: false,
                          showLink: false,
                          showSearchButton: false,
                          showSubscript: false,
                          showSuperscript: false,
                          showAlignmentButtons: false,
                          showDividers: true,
                          showInlineCode: false,
                          showClipboardCopy: false,
                          showClipboardCut: false,
                          showClipboardPaste: false,
                        ),
                      ),
                    ),
                    _ToolBtn(
                      icon: Icons.bookmark_rounded,
                      color: Colors.amber.shade600,
                      onTap: () => _showVerseSheet(isDark),
                    ),
                    _ToolBtn(
                      icon: Icons.image_rounded,
                      color: secondary,
                      onTap: _pickImage,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
              ),

            // ── 구절 카드 (탭하면 복사)
            if (_verses.isNotEmpty) ...[
              Container(
                constraints: const BoxConstraints(maxHeight: 160),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    children: _verses.map((ref) {
                      final verseBg = isDark
                          ? const Color(0xFF1C1C1E)
                          : const Color(0xFFF2F2F7);
                      return GestureDetector(
                        onTap: () => _copyVerse(ref), // 탭 → 복사
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          decoration: BoxDecoration(
                            color: verseBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border(
                                left: BorderSide(color: primary, width: 3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 구절 라벨 + 복사 아이콘
                                    Row(
                                      children: [
                                        Text(ref.label,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: primary)),
                                        const SizedBox(width: 4),
                                        Icon(Icons.copy_rounded,
                                            size: 10,
                                            color: primary.withOpacity(0.5)),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(ref.verseText,
                                        style: TextStyle(
                                            fontSize: 13,
                                            height: 1.5,
                                            color: textColor),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                              // X 버튼 (삭제)
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _verses.remove(ref)),
                                child: const Padding(
                                  padding: EdgeInsets.all(4),
                                  child: Icon(Icons.close_rounded,
                                      size: 14, color: Color(0xFF8E8E93)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Divider(height: 1, color: dividerColor),
            ],

            // ── 에디터 + 드로잉
            Expanded(
              child: Stack(
                children: [
                  AbsorbPointer(
                    absorbing: _isDrawingMode,
                    child: quill.QuillEditor(
                      controller: _quillCtrl,
                      focusNode: _editorFocus,
                      scrollController: _editorScroll,
                      config: quill.QuillEditorConfig(
                        placeholder: '내용을 입력하세요...',
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        autoFocus: widget.existingMemo == null &&
                            widget.initialVerse == null,
                        expands: false,
                        embedBuilders: [imageEmbedBuilder],
                      ),
                    ),
                  ),

                  if (_strokes.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _CanvasPainter(
                            strokes: _strokes,
                            current: [],
                            currentColor: Colors.transparent,
                            currentWidth: 0,
                          ),
                        ),
                      ),
                    ),

                  if (_isDrawingMode)
                    Positioned.fill(
                      child: Builder(builder: (ctx) {
                        return GestureDetector(
                          onPanStart: (d) {
                            final box = ctx.findRenderObject() as RenderBox;
                            setState(() => _currentStroke = [
                                  box.globalToLocal(d.globalPosition)
                                ]);
                          },
                          onPanUpdate: (d) {
                            final box = ctx.findRenderObject() as RenderBox;
                            setState(() => _currentStroke.add(
                                box.globalToLocal(d.globalPosition)));
                          },
                          onPanEnd: (d) {
                            if (_currentStroke.length > 1) {
                              setState(() {
                                if (_isEraser) {
                                  _strokes.removeWhere((s) =>
                                      s.points.any((p) => _currentStroke
                                          .any((e) =>
                                              (e - p).distance < 20)));
                                } else {
                                  _strokes.add(_Stroke(
                                    points: List.from(_currentStroke),
                                    color: _penColor,
                                    width: _penWidth,
                                  ));
                                }
                                _currentStroke = [];
                              });
                            } else {
                              setState(() => _currentStroke = []);
                            }
                          },
                          child: CustomPaint(
                            painter: _CanvasPainter(
                              strokes: const [],
                              current: _currentStroke,
                              currentColor: _isEraser
                                  ? (isDark ? Colors.black : Colors.white)
                                  : _penColor,
                              currentWidth: _isEraser ? 24 : _penWidth,
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
            ),

            if (_isDrawingMode)
              _DrawingToolBar(
                isDark: isDark,
                penColor: _penColor,
                penWidth: _penWidth,
                isEraser: _isEraser,
                primaryColor: primary,
                onColorChanged: (c) => setState(() {
                  _penColor = c;
                  _isEraser = false;
                }),
                onWidthChanged: () => setState(() {
                  _penWidth = _penWidth == 2.5 ? 5.0 : 2.5;
                  _isEraser = false;
                }),
                onEraserToggled: () =>
                    setState(() => _isEraser = !_isEraser),
                onUndo: () {
                  if (_strokes.isNotEmpty) setState(() => _strokes.removeLast());
                },
                onClear: () => setState(() => _strokes.clear()),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 이미지 embed 빌더
class _ImageEmbedBuilder extends quill.EmbedBuilder {
  final Map<String, Uint8List> imageBytes;
  final Map<String, String> imagePaths;
  final bool isDark;

  _ImageEmbedBuilder({
    required this.imageBytes,
    required this.imagePaths,
    required this.isDark,
  });

  @override
  String get key => quill.BlockEmbed.imageType;

  @override
  bool get expanded => false;

  @override
  Widget build(BuildContext context, quill.EmbedContext embedContext) {
    final imageId = embedContext.node.value.data as String;

    Widget imageWidget;
    if (kIsWeb && imageBytes.containsKey(imageId)) {
      imageWidget = Image.memory(
        imageBytes[imageId]!,
        fit: BoxFit.cover,
      );
    } else if (!kIsWeb && imagePaths.containsKey(imageId)) {
      imageWidget = Image.file(
        File(imagePaths[imageId]!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _brokenImage(),
      );
    } else {
      imageWidget = _brokenImage();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageWidget,
      ),
    );
  }

  Widget _brokenImage() => Container(
        height: 120,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2E) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(Icons.broken_image_rounded,
              color: Colors.grey.shade400, size: 40),
        ),
      );
}

// ── 툴바 버튼
class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ToolBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Icon(icon, color: color, size: 22),
        ),
      );
}

// ── 캔버스 페인터
class _CanvasPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final List<Offset> current;
  final Color currentColor;
  final double currentWidth;

  _CanvasPainter({
    required this.strokes, required this.current,
    required this.currentColor, required this.currentWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.length < 2) continue;
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points[0].dx, s.points[0].dy);
      for (int i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
    if (current.length >= 2) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(current[0].dx, current[0].dy);
      for (int i = 1; i < current.length; i++) {
        path.lineTo(current[i].dx, current[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter old) => true;
}

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke({required this.points, required this.color, required this.width});
}

// ── 그리기 도구 바
class _DrawingToolBar extends StatelessWidget {
  final bool isDark;
  final Color penColor;
  final double penWidth;
  final bool isEraser;
  final Color primaryColor;
  final ValueChanged<Color> onColorChanged;
  final VoidCallback onWidthChanged;
  final VoidCallback onEraserToggled;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  const _DrawingToolBar({
    required this.isDark, required this.penColor,
    required this.penWidth, required this.isEraser,
    required this.primaryColor, required this.onColorChanged,
    required this.onWidthChanged, required this.onEraserToggled,
    required this.onUndo, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? const Color(0xFF1C1C1E).withOpacity(0.97)
        : Colors.white.withOpacity(0.97);
    final penColors = [
      isDark ? Colors.white : Colors.black,
      primaryColor,
      Colors.red.shade400,
      Colors.green.shade500,
      Colors.orange.shade500,
      Colors.purple.shade400,
    ];

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 12, offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ...penColors.map((c) {
                final selected = penColor == c && !isEraser;
                return GestureDetector(
                  onTap: () => onColorChanged(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 130),
                    margin: const EdgeInsets.only(right: 8),
                    width: selected ? 28 : 22,
                    height: selected ? 28 : 22,
                    decoration: BoxDecoration(
                      color: c, shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.grey.shade400 : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }),
              const Spacer(),
              _DBtn(icon: penWidth > 3 ? Icons.line_weight : Icons.edit_rounded,
                  isDark: isDark, isActive: false, onTap: onWidthChanged),
              const SizedBox(width: 8),
              _DBtn(icon: Icons.auto_fix_normal_rounded,
                  isDark: isDark, isActive: isEraser,
                  activeColor: primaryColor, onTap: onEraserToggled),
              const SizedBox(width: 8),
              _DBtn(icon: Icons.undo_rounded,
                  isDark: isDark, isActive: false, onTap: onUndo),
              const SizedBox(width: 8),
              _DBtn(icon: Icons.delete_sweep_rounded,
                  isDark: isDark, isActive: false, onTap: onClear),
            ],
          ),
        ),
      ),
    );
  }
}

class _DBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback onTap;

  const _DBtn({
    required this.icon, required this.isDark,
    required this.isActive, this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? (activeColor ?? Colors.blue).withOpacity(0.15)
        : (isDark ? const Color(0xFF3A3A3C) : Colors.grey.shade100);
    final iconColor = isActive
        ? (activeColor ?? Colors.blue)
        : (isDark ? Colors.white70 : Colors.black54);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: activeColor ?? Colors.blue, width: 1.5)
              : null,
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
