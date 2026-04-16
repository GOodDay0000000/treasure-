// lib/services/hymn_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive_io.dart';

class HymnService {
  static const String _downloadUrl =
      'https://github.com/GOodDay0000000/bible-hymns/releases/download/v1.0/default.zip';

  static const int totalHymns = 645;

  // 찬송가 저장 디렉토리
  static Future<Directory> getHymnDir() async {
    final appDir  = await getApplicationDocumentsDirectory();
    final hymnDir = Directory('${appDir.path}/hymns');
    if (!await hymnDir.exists()) {
      await hymnDir.create(recursive: true);
    }
    return hymnDir;
  }

  // 다운로드 완료 여부 확인 (jpg, png 모두 체크)
  static Future<bool> isDownloaded() async {
    final dir = await getHymnDir();
    final prefix = '001';
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
      final file = File('${dir.path}/$prefix$ext');
      if (await file.exists()) return true;
    }
    return false;
  }

  // 특정 찬송가 이미지 파일 경로 (jpg, png 모두 지원)
  static Future<String?> getHymnPath(int number) async {
    final dir    = await getHymnDir();
    final prefix = number.toString().padLeft(3, '0');
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
      final file = File('${dir.path}/$prefix$ext');
      if (await file.exists()) return file.path;
    }
    return null;
  }

  // 이미지 파일 여부 확인
  static bool _isImageFile(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  // 다운로드 + 압축 해제
  static Future<void> downloadAndExtract({
    required void Function(double progress, String status) onProgress,
  }) async {
    final dir     = await getHymnDir();
    final zipFile = File('${dir.path}/hymns.zip');

    try {
      // 1. 다운로드
      onProgress(0.0, '다운로드 준비 중...');
      final request  = http.Request('GET', Uri.parse(_downloadUrl));
      final response = await request.send();

      final contentLength = response.contentLength ?? 0;
      int received = 0;

      final sink = zipFile.openWrite();
      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (contentLength > 0) {
            final progress = received / contentLength * 0.7;
            final mb    = (received / 1024 / 1024).toStringAsFixed(1);
            final total = (contentLength / 1024 / 1024).toStringAsFixed(1);
            onProgress(progress, '다운로드 중... $mb MB / $total MB');
          }
        },
        onDone: () async {
          await sink.close();
        },
        onError: (e) async {
          await sink.close();
          throw Exception('다운로드 실패: $e');
        },
        cancelOnError: true,
      ).asFuture();

      // 2. 압축 해제 (jpg, png, webp 모두 지원)
      onProgress(0.7, '압축 해제 중...');
      await Future.delayed(const Duration(milliseconds: 100));

      final bytes   = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      int extracted = 0;
      for (final file in archive) {
        final fileName = file.name.split('/').last;
        if (file.isFile && _isImageFile(fileName)) {
          final outFile = File('${dir.path}/$fileName');
          await outFile.writeAsBytes(file.content as List<int>);
          extracted++;
          final progress = 0.7 + (extracted / archive.length * 0.3);
          onProgress(progress, '압축 해제 중... $extracted / ${archive.length}');
        }
      }

      // 3. zip 삭제
      if (await zipFile.exists()) await zipFile.delete();

      onProgress(1.0, '완료!');
    } catch (e) {
      if (await zipFile.exists()) await zipFile.delete();
      rethrow;
    }
  }

  // 다운로드된 찬송가 삭제
  static Future<void> deleteAll() async {
    final dir = await getHymnDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
