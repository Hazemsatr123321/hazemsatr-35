import 'package:flutter/cupertino.dart';

class CupertinoListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  const CupertinoListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.padding,
  });

  @override
  State<CupertinoListTile> createState() => _CupertinoListTileState();
}

class _CupertinoListTileState extends State<CupertinoListTile> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = true;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = false;
      });
      widget.onTap!();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null) {
      setState(() {
        _isPressed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _isPressed
        ? CupertinoColors.systemGrey4.resolveFrom(context)
        : CupertinoColors.transparent;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: backgroundColor,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            if (widget.leading != null) ...[
              widget.leading!,
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.title != null)
                    DefaultTextStyle(
                      style: CupertinoTheme.of(context).textTheme.textStyle,
                      child: widget.title!,
                    ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 2.0),
                    DefaultTextStyle(
                      style: CupertinoTheme.of(context).textTheme.tabLabelTextStyle,
                      child: widget.subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            if (widget.trailing != null) ...[
              const SizedBox(width: 16.0),
              widget.trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class CupertinoListTileChevron extends StatelessWidget {
  const CupertinoListTileChevron({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      CupertinoIcons.forward,
      color: CupertinoColors.systemGrey2,
      size: 20,
    );
  }
}
