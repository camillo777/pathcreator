import 'dart:ui';

String now() {
  DateTime dt = DateTime.now();
  //return DateFormat('kk:mm:ss \n EEE d MMM').format(DateTime.now());
  return "${dt.hour}:${dt.minute}:${dt.second}.${dt.millisecond}";
}

//void prnow(String s) => print("${now()} $s");
void prnow(String tag, String s) => print("[$tag] ${now()} $s");

abs(double d) => d >= 0 ? d : -d;

double offDistance(Offset o1, Offset o2) {
  return (o2 - o1).distance;
}