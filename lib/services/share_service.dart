import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config.dart';
import '../models/quote.dart';

class ShareService {
  ShareService._();

  /// Card ko 1080x1080 PNG image bana ke share sheet kholta hai
  /// (WhatsApp, Telegram, Facebook ... sab dikhenge).
  static Future<void> shareCardImage(GlobalKey boundaryKey, Quote quote) async {
    final boundary =
        boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final pixelRatio = 1080 / boundary.size.width;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/spruch_${quote.id}.png');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

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

  static Future<void> copyText(Quote quote) =>
      Clipboard.setData(ClipboardData(text: quote.shareText));
}
