import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

final counterContext = createContext<int>()(0);
final deltaContext = createContext<bool>()(false);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    const title = 'Flutter Context Demo';

    return MultiContextProvider(
      contexts: [
        counterContext,
        deltaContext,
      ],
      child: MaterialApp(
        title: title,
        theme: ThemeData(useMaterial3: true),
        home: const Home(title: title),
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
            SizedBox(height: 16),
            DeltaModifierCheckbox()
          ],
        ),
      ),
      floatingActionButton: const IncrementButton(),
    );
  }
}

class IncrementButton extends StatelessWidget {
  const IncrementButton({super.key});

  VoidCallback increment(BuildContext context) {
    final update = context.updateValue(counterContext)!;

    return () {
      final delta = context.read(deltaContext);

      update((currentValue) {
        return currentValue + (delta ? 10 : 1);
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: increment(context),
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    final value = context.watch(counterContext);
    final titleStyle = Theme.of(context).textTheme.headlineMedium;

    return Text(value.toString(), style: titleStyle);
  }
}

class DeltaModifierCheckbox extends StatelessWidget {
  const DeltaModifierCheckbox({super.key});

  @override
  Widget build(BuildContext context) {
    final setValue = context.setValue(deltaContext);
    final value = context.watch(deltaContext);

    return TextButton.icon(
      icon: Icon(value ? Icons.check_box : Icons.check_box_outline_blank),
      onPressed: () => setValue(!value),
      label: const Text('Increment by 10'),
    );
  }
}
