import 'package:flutter/widgets.dart';

class MyButton extends StatelessWidget {
  final GestureTapCallback onPressed;
  final String text;
  final bool selected;

  MyButton({
    @required this.onPressed,
    @required this.text,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2),
      child: GestureDetector(
        //behavior: HitTestBehavior.translucent,
        onTap: this.onPressed,
        child: Container(
          padding: EdgeInsets.all(5),
          color: this.selected ? Color(0xffff5555) : Color(0xff555555),
          child: Text(
            this.text,
            style: TextStyle(color: Color(0xffffffff),
          ),
        ),
      ),
    ),);
  }
}