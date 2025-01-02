const int initialPoints = 5000;
const int maxPoints = 2160;
const List<int> levelPoints = [80, 240, 720, 2160];
const String initialTreeState = "씨앗";
const String initialMessage = "응애 나 씨앗";
const String initialTreeImage = 'assets/seed.png';

String getTreeState(int level) {
  switch (level) {
    case 1:
      return "새싹";
    case 2:
      return "나뭇가지";
    case 3:
      return "나무";
    case 4:
      return "꽃";
    default:
      return "씨앗";
  }
}

String getTreeMessage(int level) {
  switch (level) {
    case 1:
      return "응애 나 새싹";
    case 2:
      return "ㅎㅇ 난 나뭇가지";
    case 3:
      return "후훗 난 나무";
    case 4:
      return "짜잔 난 꽃";
    default:
      return "응애 나 씨앗";
  }
}

String getTreeImage(int level) {
  switch (level) {
    case 1:
      return 'assets/sprout.png';
    case 2:
      return 'assets/branch.png';
    case 3:
      return 'assets/tree.png';
    case 4:
      return 'assets/flower.png';
    default:
      return 'assets/seed.png';
  }
}
