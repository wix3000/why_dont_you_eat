import 'package:hive/hive.dart';

part 'restaurant.g.dart';

@HiveType(typeId: 1)
class Restaurant {
  Restaurant({
    this.name = '',
    this.address = '',
    this.price = 2,
    this.tags = const [],
    this.uber = '',
  });

  @HiveField(0)
  String name;
  @HiveField(1)
  String address;
  @HiveField(2)
  int price;
  @HiveField(3)
  List<String> tags;
  @HiveField(4)
  String uber;
}
