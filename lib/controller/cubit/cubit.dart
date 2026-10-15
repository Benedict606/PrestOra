// ignore_for_file: deprecated_member_use

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainCubit extends Cubit<MainState> {
  MainCubit() : super(InitialState());

  static MainCubit get(context) => BlocProvider.of(context);

  bool isDark = false;

  void changeThemeMode({bool? darkMode}) async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (darkMode != null) {
      isDark = darkMode;
    } else {
      isDark = !isDark;
      sharedPreferences.setBool('isDark', isDark);
    }
    emit(ChangeThemeModeState());
  }
}
