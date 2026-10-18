import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';
import '../models/quote.dart';

enum ShareResultKind { whatsapp, sheet, failed }

class ShareService {
  ShareService._();

  static const MethodChannel _channel = MethodChannel('zitatecke/whatsapp');

  /// Card ko 1080x1080 PNG banata hai (cache folder mein).
  static Future<File?> _renderCard(GlobalKey boundaryKey, Quote quote) async {
    final ctx = boundaryKey.currentContext;
    if (ctx == null) return null;
    // Pending paint (jaise abhi load hui photo) poora hone do.
    await WidgetsBinding.instance.endOfFrame;
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final pixelRatio = 1080 / boundary.size.width;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return null;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/zitatecke_${quote.id}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file;
  }

  /// Seedha WhatsApp kholta hai. WhatsApp na ho to normal share sheet.
  static Future<ShareResultKind> shareToWhatsApp(GlobalKey key, Quote quote) async {
    HapticFeedback.mediumImpact();
    final file = await _renderCard(key, quote);
    if (file == null) return ShareResultKind.failed;
    try {
      final ok = await _channel.invokeMethod<bool>('shareImage', {
        'path': file.path,
        'text': kPlayStoreLink.isEmpty ? null : kPlayStoreLink,
      });
      if (ok == true) return ShareResultKind.whatsapp;
    } catch (_) {
      // Native channel nahi mila – neeche share sheet.
    }
    await _sheet(file);
    return ShareResultKind.sheet;
  }

  /// Share sheet (Telegram, Facebook, Signal, E-Mail ...).
  static Future<ShareResultKind> shareCardImage(GlobalKey key, Quote quote) async {
    HapticFeedback.mediumImpact();
    final file = await _renderCard(key, quote);
    if (file == null) return ShareResultKind.failed;
    await _sheet(file);
    return ShareResultKind.sheet;
  }

  static Future<void> _sheet(File file) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: kPlayStoreLink.isEmpty ? null : kPlayStoreLink,
      ),
    );
  }

  static Future<void> shareText(Quote quote) async {
    final text = kPlayStoreLink.isEmpty
        ? quote.shareText
        : '${quote.shareText}\n\n$kPlayStoreLink';
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static Future<void> copyText(Quote quote) {
    HapticFeedback.selectionClick();
    return Clipboard.setData(ClipboardData(text: quote.shareText));
  }
}
