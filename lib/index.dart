import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:why_dont_you_eat/restaurant.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  static const boxKey = 'restaurants';
  static const priceLevels = ['低', '平', '普', '貴', '狂'];

  final nameCtrler = TextEditingController();
  final addrCtrler = TextEditingController();
  final priceLevel = ValueNotifier(2);
  final tagsCtrler = TextEditingController();
  final uberCtrler = TextEditingController();

  late BuildContext _context;
  late final Box<Restaurant> box;

  bool initialed = false;
  bool isWannaOutside = false;
  bool isWannaShip = true;
  Widget? searchResult;

  final List<String> tags = [];
  final List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    initAsync();
    priceLevel.addListener(() {
      setState(() {});
    });
  }

  void initAsync() async {
    box = await Hive.openBox(boxKey);
    for (var rest in box.values) {
      for (var tag in rest.tags) {
        if (tags.contains(tag) == false) {
          tags.add(tag);
        }
      }
    }
    setState(() {
      initialed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _context = context;

    if (initialed == false) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('Why Don\'t You Eat?')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Text('今天我想...  '),
                  Checkbox(
                      value: isWannaOutside,
                      onChanged: ((value) {
                        setState(() {
                          isWannaOutside = value!;
                        });
                      })),
                  const Text('出去吃'),
                  Checkbox(
                      value: isWannaShip,
                      onChanged: ((value) {
                        setState(() {
                          isWannaShip = value!;
                        });
                      })),
                  const Text('叫 Uber'),
                ],
              ),
            ),
            Row(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _drawTagFlags(),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _pickup,
              style: ElevatedButton.styleFrom(
                  elevation: 6, padding: const EdgeInsets.all(16)),
              child: const Text(
                '就決定吃你了！',
                style: TextStyle(fontSize: 20),
              ),
            ),
            if (searchResult != null) searchResult!,
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0.0, 2.0), //(x,y)
                      blurRadius: 4.0,
                    ),
                  ]),
              child: Column(
                children: [
                  _inputRow(
                      title: const Text('名稱'),
                      field: SizedBox(
                          width: 120,
                          child: TextField(
                            controller: nameCtrler,
                          ))),
                  _inputRow(
                      title: const Text('地址'),
                      field: Expanded(
                          child: TextField(
                        controller: addrCtrler,
                      ))),
                  _inputRow(
                      title: const Text('價位'),
                      field: SizedBox(
                          width: 72,
                          child: DropdownButtonFormField(
                            onChanged: (value) {
                              if (value == null) return;
                              priceLevel.value = value;
                            },
                            value: priceLevel.value,
                            items: priceLevels
                                .map((e) => DropdownMenuItem(
                                      child: Text(e),
                                      value: priceLevels.indexOf(e),
                                    ))
                                .toList(),
                          ))),
                  _inputRow(
                      title: const Text('標籤'),
                      field: Expanded(
                          child: TextField(
                        controller: tagsCtrler,
                      ))),
                  _inputRow(
                      title: const Text('Uber Eat'),
                      field: Expanded(
                          child: TextField(
                        controller: uberCtrler,
                      ))),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: _onAddnew,
                          child: const Text('新增'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Table(
                children: [
                  const TableRow(children: [
                    Text('名稱'),
                    Text('地址'),
                    Text('價位'),
                    Text('Tags'),
                    Text('Uber Eat')
                  ]),
                  ..._drawTableRows(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _inputRow({required Widget title, required Widget field}) {
    return Row(
      children: [
        ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 72),
            child: DefaultTextStyle(
                style: Theme.of(_context).textTheme.titleMedium!,
                child: title)),
        field,
      ],
    );
  }

  void _onAddnew() async {
    final rest = Restaurant(
      name: nameCtrler.text,
      address: addrCtrler.text,
      price: priceLevel.value,
      tags: tagsCtrler.text.split(' '),
      uber: uberCtrler.text,
    );

    await box.add(rest);
    setState(() {});
  }

  Iterable<TableRow> _drawTableRows() {
    if (initialed == false) return [];
    return box.values.map(
      (r) => TableRow(children: [
        SelectableText(r.name),
        SelectableText(r.address),
        Text(priceLevels[r.price]),
        SelectableText(r.tags.join(' ')),
        r.uber.isNotEmpty && r.uber.startsWith('http')
            ? TextButton(
                onPressed: () {
                  js.context.callMethod('open', [r.uber]);
                },
                child: const Text('Link'))
            : Container(),
      ]),
    );
  }

  List<Widget> _drawTagFlags() {
    const prefix = ' • ';
    const style = TextStyle(
        color: Color(0xFF820000), fontSize: 14, fontWeight: FontWeight.bold);
    const enableOpacity = 1.0;
    const disableOpacity = 0.35;

    final result = [
      AnimatedOpacity(
        opacity: selectedTags.isEmpty ? enableOpacity : disableOpacity,
        duration: const Duration(milliseconds: 250),
        child: GestureDetector(
          onTap: () => setState(() {
            selectedTags.clear();
          }),
          child: Container(
            color: const Color(0xFFE5B3A5),
            padding: const EdgeInsets.all(4),
            child: const Text(
              '$prefix所有',
              style: style,
            ),
          ),
        ),
      )
    ];

    for (var tag in tags) {
      result.add(AnimatedOpacity(
        opacity: selectedTags.contains(tag) ? enableOpacity : disableOpacity,
        duration: const Duration(milliseconds: 250),
        child: GestureDetector(
          onTap: () {
            if (selectedTags.contains(tag)) {
              setState(() {
                selectedTags.remove(tag);
              });
            } else {
              setState(() {
                selectedTags.add(tag);
              });
            }
          },
          child: Container(
            color: const Color(0xFFE5B3A5),
            padding: const EdgeInsets.all(4),
            child: Text(
              '$prefix$tag',
              style: style,
            ),
          ),
        ),
      ));
    }

    return result;
  }

  void _pickup() {
    if ((isWannaOutside || isWannaShip) == false) {
      setState(() {
        searchResult = const Text('你怎麼不吃屎');
      });
      return;
    }

    final list = box.values
        .where((rest) =>
            (isWannaOutside && rest.address.isNotEmpty) ||
            (isWannaShip && rest.uber.startsWith('http')))
        .where((rest) {
      for (var tag in selectedTags) {
        if (rest.tags.contains(tag) == false) return false;
      }
      return true;
    }).toList();

    if (list.isEmpty) {
      setState(() {
        searchResult = const Text('想想還是吃自己好了');
      });
      return;
    }

    list.shuffle();
    final answer = list.first;

    setState(() {
      searchResult = Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(answer.name),
                if (answer.address.isNotEmpty) Text('地點：${answer.address}'),
                Text('價位：${priceLevels[answer.price]}'),
                Text('標籤：${answer.tags.join(' ')}'),
                if (answer.uber.startsWith('http'))
                  TextButton(
                    onPressed: () {
                      js.context.callMethod('open', [answer.uber]);
                    },
                    child: const Text('Uber Eats'),
                  ),
              ],
            ),
          ],
        ),
      );
    });
  }
}
