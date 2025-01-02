import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showActionModal(
    BuildContext context, {
      required String action,
      required int cost,
      required VoidCallback onConfirm,
    }) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Column(
          children: [
            Text(action),
          ],
        ),
        content: Text("$cost 포인트를 사용하여 $action 하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            child: Text("취소"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            child: Text("확인"),
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
          ),
        ],
      );
    },
  );
}

void showInsufficientPointsModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CupertinoAlertDialog(
        title: Text("포인트 부족"),
        content: Text("포인트가 부족합니다."),
        actions: [
          CupertinoDialogAction(
            child: Text("확인"),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

void showLevelUpModal(
    BuildContext context, int currentLevel, Function(int) onLevelUp) {
  showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text("레벨업"),
        content: Text("레벨업 하시겠습니까?"),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              onLevelUp(currentLevel + 1);
            },
            child: Text("레벨업하기"),
          ),
        ],
      );
    },
  );
}

void showCompletionModal(
    BuildContext context, List<String> myCoupons, Function(String) onAddCoupon) {
  showDialog(
    context: context,
    builder: (context) {
      return CupertinoAlertDialog(
        title: Text("축하합니다!"),
        content: Text("모든 레벨을 완료했습니다. 쿠폰을 선택하세요."),
        actions: [
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              onAddCoupon("플라스틱 방앗간 제품 교환권");
            },
            child: Text("플라스틱 방앗간 제품 교환권"),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              onAddCoupon("119REO 제품 교환권");
            },
            child: Text("119REO 제품 교환권"),
          ),
        ],
      );
    },
  );
}

