import 'package:flutter/material.dart';
import 'package:inkstamp/app/theme/gallery_tokens.dart';

abstract final class EditorialColors {
  static const Color canvas = GalleryTokens.canvas;
  static const Color paper = GalleryTokens.surface;
  static const Color ink = GalleryTokens.text;
  static const Color muted = GalleryTokens.secondaryText;
  static const Color line = GalleryTokens.line;
}

abstract final class EditorialAssets {
  static const String camera = 'assets/design/camera.jpg';
  static const String street = 'assets/design/friends.jpg';
  static const String cafeFriends = 'assets/design/cafe_friends.jpg';
  static const String portrait = 'assets/design/portrait.jpg';
  static const String tea = 'assets/design/tea.jpg';
  static const String preview = 'assets/design/preview_stamp.jpg';
}

class EditorialHeader extends StatelessWidget {
  const EditorialHeader({
    required this.title,
    this.dark = false,
    this.trailing,
    super.key,
  });

  final String title;
  final bool dark;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final Color primary = dark ? Colors.white : EditorialColors.ink;
    final Color secondary = dark ? Colors.white70 : EditorialColors.muted;
    return SizedBox(
      height: 48,
      child: Row(
        children: <Widget>[
          Text(
            'INKSTAMP',
            style: TextStyle(
              color: secondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.25,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            child: Text(
              '/',
              style: TextStyle(color: secondary.withValues(alpha: 0.6)),
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary,
                fontSize: 19,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.35,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class EditorialAvatar extends StatelessWidget {
  const EditorialAvatar({this.size = 32, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        EditorialAssets.portrait,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}

class TechnicalText extends StatelessWidget {
  const TechnicalText(
    this.data, {
    this.color = EditorialColors.muted,
    this.fontSize = 10,
    this.weight = FontWeight.w600,
    this.letterSpacing = 1,
    this.maxLines,
    this.textAlign,
    super.key,
  });

  final String data;
  final Color color;
  final double fontSize;
  final FontWeight weight;
  final double letterSpacing;
  final int? maxLines;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      maxLines: maxLines,
      overflow: maxLines == null ? null : TextOverflow.ellipsis,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: weight,
        height: 1.4,
        letterSpacing: letterSpacing,
      ),
    );
  }
}
