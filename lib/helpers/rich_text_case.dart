import 'package:waste_genie/helpers/rich_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';

import 'package:stack_board/stack_board.dart';

/// 默认文本样式
const TextStyle _defaultStyle = TextStyle(fontSize: 20);

/// 自适应文本外壳
class RichTextCase extends StatefulWidget {
  const RichTextCase({
    Key? key,
    required this.adaptiveText,
    this.onDel,
    this.onTap,
    this.onComplete,
    this.onFocusing,
    this.operatState,
  }) : super(key: key);

  @override
  State<RichTextCase> createState() => _RichTextCaseState();

  /// 自适应文本对象
  final RichTextItem adaptiveText;

  /// 移除拦截
  final void Function()? onDel;

  /// 点击回调
  final void Function()? onTap;

  // complete edit callback
  final void Function()? onComplete;

  final void Function(TextStyle style, dynamic styleCallback)? onFocusing;

  /// 操作状态
  final OperatState? operatState;
}

class _RichTextCaseState extends State<RichTextCase>
    with SafeState<RichTextCase> {
  /// 是否正在编辑
  bool _isEditing = false;

  /// 文本内容
  late String _text = widget.adaptiveText.data;

  /// 输入框宽度
  double _textFieldWidth = 100;

  /// 文本样式
  late TextStyle _style = widget.adaptiveText.style ?? _defaultStyle;

  /// 计算文本大小
  Size _textSize(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  void setStyle(TextStyle style) {
    safeSetState(() {
      _style = style;
    });
  }

  bool? onOperatStateChanged(OperatState s) {
    if (s != OperatState.editing && _isEditing) {
      safeSetState(() => _isEditing = false);
    } else if (s == OperatState.editing && !_isEditing) {
      safeSetState(() => _isEditing = true);
    }

    if (s == OperatState.complate) {
      widget.onComplete!();
    } else {
      widget.onFocusing!(_style, setStyle);
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return ItemCase(
      isCenter: false,
      canEdit: true,
      onTap: widget.onTap,
      tapToEdit: widget.adaptiveText.tapToEdit,
      onDel: widget.onDel,
      operatState: widget.operatState,
      caseStyle: widget.adaptiveText.caseStyle,
      // tools: FontPanel(text: widget.adaptiveText),
      onOperatStateChanged: onOperatStateChanged,
      onSizeChanged: (Size s) {
        final Size size = _textSize(_text, _style);
        _textFieldWidth = size.width + 8;

        return;
      },
      child: _isEditing ? _buildEditingBox : _buildTextBox,
    );
  }

  /// 仅文本
  Widget get _buildTextBox {
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          _text,
          style: _style,
          textAlign: widget.adaptiveText.textAlign,
          textDirection: widget.adaptiveText.textDirection,
          locale: widget.adaptiveText.locale,
          softWrap: widget.adaptiveText.softWrap,
          overflow: widget.adaptiveText.overflow,
          textScaleFactor: widget.adaptiveText.textScaleFactor,
          maxLines: widget.adaptiveText.maxLines,
          semanticsLabel: widget.adaptiveText.semanticsLabel,
        ),
      ),
    );
  }

  /// 正在编辑
  Widget get _buildEditingBox {
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          width: _textFieldWidth,
          child: TextFormField(
            autofocus: true,
            initialValue: _text,
            onChanged: (String v) => _text = v,
            style: _style,
            textAlign: widget.adaptiveText.textAlign ?? TextAlign.start,
            textDirection: widget.adaptiveText.textDirection,
            maxLines: widget.adaptiveText.maxLines,
          ),
        ),
      ),
    );
  }
}
