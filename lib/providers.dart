import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'database/database_helper.dart';
import 'repositories/user_repository.dart';

List<SingleChildWidget> get providers {
  return [
    Provider(create: (context) => DatabaseHelper()),
    Provider(create: (context) => UserRepository(context.read())),
  ];
}
