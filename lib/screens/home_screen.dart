import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Water Monitor"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Text(
              "Welcome to Water Monitor",
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Track groundwater levels, visualize data with charts, "
              "and learn about your local water stations.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Navigation Buttons
            CustomButton(
              label: "View Stations",
              onTap: () => Navigator.pushNamed(context, '/stations'),
            ),
            CustomButton(
              label: "View Charts",
              onTap: () => Navigator.pushNamed(context, '/charts'),
            ),
            CustomButton(
              label: "View Charts",
              onTap: () => Navigator.pushNamed(context, '/charts'),
            ),

            CustomButton(
              label: "About Project",
              onTap: () => Navigator.pushNamed(context, '/about'),
            )
          ],
        ),
      ),
    );
  }
}
