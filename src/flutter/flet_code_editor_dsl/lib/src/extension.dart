import 'package:flet/flet.dart';
import 'package:flutter/widgets.dart';
import 'code_editor.dart';

class Extension extends FletExtension {
  @override
  Widget? createWidget(Key? key, Control control) {
    if (control.type == 'flet_code_editor_dsl') {
      return FletCodeEditorControl(key: key, control: control);
    }
    return null;
  }
}
