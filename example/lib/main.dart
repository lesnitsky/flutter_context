import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

final Counter = createContext<int>()(0);
final DeltaModifier = createContext<bool?>()(false);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    return Counter.Provider(
      child: DeltaModifier.Provider(
        child: const MaterialApp(
          title: 'Flutter Demo',
          home: Home(title: 'Flutter Demo Home Page'),
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  final String title;
  const Home({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('You have pushed the button this many times:'),
            SizedBox(height: 16),
            CounterText(),
            SizedBox(
              width: 200,
              child: DeltaModifierCheckbox(),
            ),
          ],
        ),
      ),
      floatingActionButton: const IncrementButton(),
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({super.key});

  int Function(int value) increment(bool? delta) {
    return (v) => v + (delta ?? false ? 10 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return DeltaModifier.Consumer((context, value, child) {
      final update = context.updateValue(Counter.tag);

      return FloatingActionButton(
        onPressed: () {
          update?.call(increment(value));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      );
    });
  }
}

class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headline4;

    return Counter.Consumer((context, value, child) {
      return Text(value.toString(), style: headlineStyle);
    });
  }
}

class DeltaModifierCheckbox extends StatelessWidget {
  const DeltaModifierCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    return DeltaModifier.Consumer((context, value, child) {
      final setBool = context.setValue(DeltaModifier.tag);

      return CheckboxListTile(
        value: value,
        onChanged: setBool,
        title: const Text('Increment by 10'),
      );
    });
  }
}
