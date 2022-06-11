import 'dart:html';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mine_sweeper/card_model.dart';
import 'package:mine_sweeper/game_config.dart';

void main() {
  window.document.onContextMenu.listen((evt) => evt.preventDefault());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mine Sweeper',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GameBoardConfig gameBoardConfig = const GameBoardConfig();
  late final List<CardModel> cards = List.filled(
    gameBoardConfig.totalCount,
    const CardModel(),
    growable: true,
  );

  bool hasBomb = false;

  int get notOpenedCardCount => cards.where((e) => !e.isOpened).length;

  Iterable<int> getIndexesWithCenter(int centerIndex) {
    final bool isFirstColumn = centerIndex % gameBoardConfig.xCount == 0;
    final bool isLastColumn =
        centerIndex % gameBoardConfig.xCount == gameBoardConfig.xCount - 1;
    return <int>[
      centerIndex + gameBoardConfig.xCount,
      centerIndex - gameBoardConfig.xCount,
      if (!isFirstColumn) ...<int>[
        centerIndex - 1,
        centerIndex - 1 + gameBoardConfig.xCount,
        centerIndex - 1 - gameBoardConfig.xCount,
      ],
      if (!isLastColumn) ...<int>[
        centerIndex + 1,
        centerIndex + 1 + gameBoardConfig.xCount,
        centerIndex + 1 - gameBoardConfig.xCount,
      ],
    ].where((int index) => index >= 0 && index < gameBoardConfig.totalCount);
  }

  void replaceIndexedCard(int index, CardModel newModel) {
    cards.replaceRange(
      index,
      index + 1,
      <CardModel>[newModel],
    );
  }

  void initBomb(int clickIndex) {
    hasBomb = true;
    final List<int> allIndexes = List.generate(cards.length, (index) => index);
    final List<int> noBombIndexes = <int>[
      ...getIndexesWithCenter(clickIndex),
      clickIndex,
    ];
    allIndexes.removeWhere((e) => noBombIndexes.contains(e));

    //<index,炸弹数量>
    final Map<int, int> cardBombCountMap = <int, int>{};
    // 循环设置所有炸弹,处理[cardBombCountMap]
    for (int i = 0; i < gameBoardConfig.bombCount; i++) {
      final int randomIndex = math.Random().nextInt(allIndexes.length - 1);
      // 得到炸弹index
      final int bombIndex = allIndexes[randomIndex];
      // 设置为炸弹
      replaceIndexedCard(bombIndex, const CardModel(isBomb: true));
      final Iterable<int> areaIndexes = getIndexesWithCenter(bombIndex);
      for (final int index in areaIndexes) {
        if (cardBombCountMap.containsKey(index)) {
          cardBombCountMap[index] = cardBombCountMap[index]! + 1;
        } else {
          cardBombCountMap[index] = 1;
        }
      }
      allIndexes.removeAt(randomIndex);
    }
    // 设置card数量
    cardBombCountMap.forEach((int index, int count) {
      if (!cards[index].isBomb) {
        replaceIndexedCard(index, cards[index].copyWith(num: count));
      }
    });
  }

  void openCard(int index) {
    replaceIndexedCard(index, cards[index].copyWith(isOpened: true));
  }

  void openEmptyCard(int index) {
    openCard(index);
    final Iterable<int> areaIndexes = getIndexesWithCenter(index);
    for (final int i in areaIndexes) {
      if (!cards[i].isOpened) {
        if (cards[i].num == 0) {
          openEmptyCard(i);
        } else {
          openCard(i);
        }
      }
    }
  }

  void openAllCard() {
    for (int i = 0; i < cards.length; i++) {
      if (!cards[i].isOpened) {
        openCard(i);
      }
    }
  }

  Future<void> onCardTap(int index) async {
    final CardModel model = cards[index];
    if (!model.isOpened) {
      if (!hasBomb) {
        initBomb(index);
      }
      if (model.isBomb) {
        setState(openAllCard);
        return showDialog(
          context: context,
          builder: (c) {
            return const AlertDialog(
              title: Text('失败'),
            );
          },
        );
      }
      if (model.num == 0) {
        openEmptyCard(index);
      } else {
        openCard(index);
      }
      if (notOpenedCardCount == gameBoardConfig.bombCount) {
        setState(openAllCard);
        return showDialog(
          context: context,
          builder: (c) {
            return const AlertDialog(
              title: Text('成功'),
            );
          },
        );
      } else {
        setState(() {});
      }
    }
  }

  void onSetFlag(int index) {
    if (!cards[index].isOpened) {
      setState(
        () {
          replaceIndexedCard(
              index, cards[index].copyWith(isFlag: !cards[index].isFlag));
        },
      );
    }
  }

  Widget cardItem(BuildContext context, int index) {
    final CardModel model = cards[index];
    return GestureDetector(
      onTap: () => onCardTap(index),
      onLongPress: () => onSetFlag(index),
      onSecondaryTap: () => onSetFlag(index),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: gameBoardConfig.cardSize / 2),
        child: AnimatedContainer(
          width: gameBoardConfig.cardSize,
          height: gameBoardConfig.cardSize,
          duration: kThemeChangeDuration,
          decoration: BoxDecoration(
            color: model.isOpened
                ? model.num == 0
                    ? Colors.grey.shade200
                    : Colors.white
                : Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 1,
                spreadRadius: 1,
              )
            ],
          ),
          child: model.isOpened
              ? Center(child: model.openedChild)
              : Center(child: model.notOpenedChild),
        ),
      ),
    );
  }

  Widget gameBoard(BuildContext context) {
    return SizedBox(
      width: gameBoardConfig.boardWidth,
      child: Wrap(
        spacing: gameBoardConfig.xSpacing,
        runSpacing: gameBoardConfig.ySpacing,
        children: List.generate(
          cards.length,
          (int index) => cardItem(context, index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: <Widget>[
            const Expanded(
              child: Center(
                child: Text(
                  '操作：\n'
                  '1.点击翻面\n'
                  '2.右键/长按插旗\n'
                  '3.重启重开游戏\n',
                  style: TextStyle(color: Colors.blue, fontSize: 30),
                ),
              ),
            ),
            gameBoard(context),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
