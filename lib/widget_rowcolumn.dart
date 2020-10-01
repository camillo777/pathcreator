import 'package:flutter/widgets.dart';

class RowColumn extends StatelessWidget {
  final double width;
  final double height;
  final List<Widget> children;

  RowColumn({
    Key key,
    @required this.width,
    @required this.height,
    @required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return width < height
        ? Column(children: children)
        : Row(children: children);
  }
}