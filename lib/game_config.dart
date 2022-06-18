import 'package:flutter/material.dart';

@immutable
class GameBoardConfig {
  const GameBoardConfig({
    this.bombCount = 10,
    this.xCount = 9,
    this.yCount = 9,
    this.cardSize = 80.0,
    this.xSpacing = 8.0,
    this.ySpacing = 8.0,
  });

  final int bombCount;
  final int xCount;
  final int yCount;
  final double cardSize;
  final double xSpacing;
  final double ySpacing;

  int get totalCount => xCount * yCount;

  double get boardWidth => xCount * cardSize + (xCount - 1) * xSpacing;

  GameBoardConfig copyWith({
    int? bombCount,
    int? xCount,
    int? yCount,
    double? cardSize,
    double? xSpacing,
    double? ySpacing,
  }) {
    return GameBoardConfig(
      bombCount: bombCount ?? this.bombCount,
      xCount: xCount ?? this.xCount,
      yCount: yCount ?? this.yCount,
      cardSize: cardSize ?? this.cardSize,
      xSpacing: xSpacing ?? this.xSpacing,
      ySpacing: ySpacing ?? this.ySpacing,
    );
  }
}
