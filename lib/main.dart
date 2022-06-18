import 'dart:html';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mine_sweeper/card_model.dart';
import 'package:mine_sweeper/game_config.dart';

void main() {
  if (kIsWeb) {
    window.document.onContextMenu.listen((evt) => evt.preventDefault());
  }
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

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<GameBoardConfig> gameBoardConfigNotifier =
      ValueNotifier<GameBoardConfig>(const GameBoardConfig());

  GameBoardConfig get gameBoardConfig => gameBoardConfigNotifier.value;

  late List<CardModel> cards = List.filled(
    gameBoardConfig.totalCount,
    const CardModel(),
    growable: true,
  );

  bool hasBomb = false;

  /// 点击第一个卡片的时间，用来计算游戏耗时
  DateTime? startTime;

  final ValueNotifier<Duration> durationFromStart =
      ValueNotifier<Duration>(Duration.zero);
  late final Ticker ticker = createTicker(_onTick);

  /// 未开启的卡片的数量，未开启卡片数量等于炸弹数游戏成功
  int get notOpenedCardCount => cards.where((e) => !e.isOpened).length;

  @override
  void initState() {
    super.initState();
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  ///[ticker]将会触发的回调
  void _onTick(_) {
    if (startTime != null) {
      final DateTime now = DateTime.now();
      durationFromStart.value = now.difference(startTime!);
    }
  }

  /// 返回以[centerIndex]为中心的九宫格的index列表
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
    cards[index] = newModel;
  }

  /// 初始化炸弹位置
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

  /// 开启空格子会自动开启[index]为中心的九宫格内其他所有格子
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
        startTime = DateTime.now();
        initBomb(index);
      }
      if (model.isBomb) {
        startTime = null;
        setState(openAllCard);
        return showDialog(
          context: context,
          builder: (c) {
            return AlertDialog(
              title: Text('😵 失败,用时 '
                  '${durationFromStart.value.toStringAsMyFormat()}'),
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
        startTime = null;
        setState(openAllCard);
        return showDialog(
          context: context,
          builder: (c) {
            return AlertDialog(
              title: Text('🎉 成功,用时 '
                  '${durationFromStart.value.toStringAsMyFormat()}'),
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
            BoxShadow(color: Colors.black26, blurRadius: 1, spreadRadius: 1)
          ],
        ),
        child: model.isOpened
            ? Center(child: model.openedChild)
            : Center(child: model.notOpenedChild),
      ),
    );
  }

  Widget gameBoard(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: gameBoardConfigNotifier,
      builder: (BuildContext c, GameBoardConfig config, Widget? child) {
        // 重新生成cards
        if (config.totalCount != cards.length) {
          cards = List.filled(
            gameBoardConfig.totalCount,
            const CardModel(),
            growable: true,
          );
        }
        return DefaultTextStyle(
          style: TextStyle(fontSize: config.cardSize / 2),
          child: SizedBox(
            width: config.boardWidth,
            child: Wrap(
              spacing: config.xSpacing,
              runSpacing: config.ySpacing,
              children: List.generate(
                cards.length,
                (int index) => cardItem(context, index),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 调整配置信息
  Widget configWidget(BuildContext context) {
    return DefaultTextStyle.merge(
      style: const TextStyle(height: 1),
      child: ValueListenableBuilder(
        valueListenable: gameBoardConfigNotifier,
        builder: (BuildContext c, GameBoardConfig value, Widget? child) {
          return Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Text(
                    '炸弹数量：',
                  ),
                  Slider(
                    value: value.bombCount.toDouble(),
                    onChanged: (double v) {
                      gameBoardConfigNotifier.value =
                          value.copyWith(bombCount: v.round());
                    },
                    divisions: 50,
                    min: 1,
                    max: 50,
                  ),
                  Text(value.bombCount.toString().padLeft(2, '0')),
                ],
              ),
              Row(
                children: <Widget>[
                  const Text('横向数量：'),
                  Slider(
                    value: value.xCount.toDouble(),
                    onChanged: (double v) {
                      gameBoardConfigNotifier.value =
                          value.copyWith(xCount: v.round());
                    },
                    divisions: 18,
                    min: 6,
                    max: 18,
                  ),
                  Text(value.xCount.toString().padLeft(2, '0')),
                ],
              ),
              Row(
                children: <Widget>[
                  const Text('竖向数量：'),
                  Slider(
                    value: value.yCount.toDouble(),
                    onChanged: (double v) {
                      gameBoardConfigNotifier.value =
                          value.copyWith(yCount: v.round());
                    },
                    divisions: 12,
                    min: 6,
                    max: 12,
                  ),
                  Text(value.yCount.toString().padLeft(2, '0')),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget gameDuration(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: durationFromStart,
      builder: (BuildContext context, Duration value, _) {
        return Text('用时：${value.toStringAsMyFormat()}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: DefaultTextStyle(
          style: TextStyle(fontSize: 30, color: Theme.of(context).primaryColor),
          child: Row(
            children: <Widget>[
              const Spacer(),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    configWidget(context),
                    const SizedBox(width: 200, child: Divider(height: 30)),
                    gameDuration(context),
                    const SizedBox(width: 200, child: Divider(height: 30)),
                    const Text(
                      '操作：\n'
                      '1.点击翻面\n'
                      '2.右键/长按插旗\n'
                      '3.重启重开游戏\n',
                      style: TextStyle(color: Colors.green),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              gameBoard(context),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

extension DurationExtension on Duration {
  String toStringAsMyFormat() {
    String res = toString();
    res = res.substring(0, res.length - 4);
    int hour = inHours;
    if (hour == 0) {
      res = res.substring(2);
    } else if (hour < 10) {
      res = '0$res';
    }
    return res;
  }
}
