import 'package:flutter/material.dart';

class ChartsScreen extends StatelessWidget {
  const ChartsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Charts")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Charts Coming Soon",
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 20),
            const Text("Here you will see groundwater level visualizations."),
          ],
        ),
      ),
    );
  }
}
