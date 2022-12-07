import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

final Counter = createContext<int>().withHandlers(CounterHandlers());
final DeltaModifier = createContext<bool>().withHandlers(setBool);

class CounterHandlers extends ContextHandlers<int> {
  @override
  Set<Function> get disabledActions {
    return {
      if (value >= 15) increment,
    };
  }

  void increment([int delta = 1]) {
    value += delta;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    return MultiContext(
      contexts: [
        DeltaModifier(false),
        Counter(0),
      ],
      builder: (_) => MaterialApp(
        title: 'Flutter Context Demo Page',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const Home(title: 'Flutter Context Demo Page'),
      ),
    );
  }
}

class Home extends ConsumerWidget<bool> {
  final String title;
  const Home({super.key, required this.title});

  @override
  Context get context => DeltaModifier;

  @override
  Widget build(BuildContext context, bool value, Widget? child) {
    final h = Counter.handlers(context);
    final increment = h(h.actions.increment, value ? 10 : null);

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
      floatingActionButton: increment != null
          ? FloatingActionButton(
              onPressed: increment,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class CounterText extends ConsumerWidget<int> {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context, int value, Widget? child) {
    return Text(
      '$value',
      style: Theme.of(context).textTheme.headline4,
    );
  }

  @override
  Context get context => Counter;
}

class DeltaModifierCheckbox extends ConsumerWidget<bool> {
  const DeltaModifierCheckbox({super.key});

  @override
  Context get context => DeltaModifier;

  @override
  Widget build(BuildContext context, bool value, Widget? child) {
    final d = DeltaModifier.handlers(context);

    return CheckboxListTile(
      value: value,
      onChanged: d(d.actions.setValue)?.argNullable(),
      title: const Text('Increment by 10'),
    );
  }
}
