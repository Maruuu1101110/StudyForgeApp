import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodeWrapperWidget extends StatefulWidget {
  final Widget child;
  final String text;

  const CodeWrapperWidget({Key? key, required this.child, required this.text})
    : super(key: key);

  @override
  State<CodeWrapperWidget> createState() => _CodeWrapperWidgetState();
}

class _CodeWrapperWidgetState extends State<CodeWrapperWidget> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(padding: const EdgeInsets.only(top: 40), child: widget.child),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () async {
              if (_copied) return;
              await Clipboard.setData(ClipboardData(text: widget.text));
              setState(() => _copied = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _copied = false);
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                _copied ? Icons.check : Icons.copy,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
