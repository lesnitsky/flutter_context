import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

final Counter = createContext<int>();
final DeltaModifier = createContext<bool?>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    return context.mount(
      children: [
        Counter(0),
        DeltaModifier(false),
      ],
      child: const MaterialApp(
        title: 'Flutter Demo',
        home: Home(title: 'Flutter Demo Home Page'),
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

class IncrementButton extends ConsumerWidget<bool?> {
  const IncrementButton({super.key});

  int Function(int value) increment(bool? delta) {
    return (v) => v + (delta ?? false ? 10 : 1);
  }

  @override
  Widget build(BuildContext context, bool? value) {
    return FloatingActionButton(
      onPressed: () {
        context.sink<int>()?.update(increment(value));
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

class CounterText extends ConsumerWidget<int> {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context, int value) {
    final headlineStyle = Theme.of(context).textTheme.headline4;
    return Text(value.toString(), style: headlineStyle);
  }
}

class DeltaModifierCheckbox extends ConsumerWidget<bool?> {
  const DeltaModifierCheckbox({super.key});

  @override
  Widget build(BuildContext context, bool? value) {
    return CheckboxListTile(
      value: value,
      onChanged: context.sink<bool?>()?.add,
      title: const Text('Increment by 10'),
    );
  }
}
