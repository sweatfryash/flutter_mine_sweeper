import 'package:flutter/material.dart';

@immutable
class CardModel {
  const CardModel({
    this.isBomb = false,
    this.num = 0,
    this.isOpened = false,
    this.isFlag = false,
  });

  final bool isBomb;
  final int num;
  final bool isOpened;
  final bool isFlag;

  CardModel copyWith({
    bool? isBomb,
    int? num,
    bool? isOpened,
    bool? isFlag,
  }) {
    return CardModel(
      isBomb: isBomb ?? this.isBomb,
      num: num ?? this.num,
      isOpened: isOpened ?? this.isOpened,
      isFlag: isFlag ?? this.isFlag,
    );
  }

  Widget? get notOpenedChild => isFlag ? const Text('🚩') : null;

  Widget? get openedChild => isBomb
      ? const Text('💣')
      : num == 0
          ? null
          : Text('$num', style: TextStyle(color: color));

  Color get color{
    switch (num){
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
    }
    return Colors.red;
  }
}
