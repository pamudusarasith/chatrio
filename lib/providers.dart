import 'package:chatrio/database/database_manager.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'repositories/user_repository.dart';

List<SingleChildWidget> get providers {
  return [
    Provider(create: (context) => DatabaseManager()),
    Provider(create: (context) => UserRepository()),
  ];
}
