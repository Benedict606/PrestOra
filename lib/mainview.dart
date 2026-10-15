import 'package:flutter/material.dart';
import 'package:prestora/app/view/home/modelUI.dart';

class Mainview extends StatelessWidget {
  static const route = '/mainview';
  Mainview({super.key});

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.dark);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ThemeShowcasePage(themeMode: themeMode),
                  ),
                );
              },
              child: const Text('Aller sur la page suivante'),
            ),
          ],
        ),
      ),
    );
  }
}
