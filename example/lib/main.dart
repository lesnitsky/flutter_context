import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

class CounterTag extends ContextTag<int> {
  const CounterTag();
}

final Counter = createContext<int>().withTag(const CounterTag());

class DeltaTag extends ContextTag<bool?> {
  const DeltaTag();
}

final DeltaModifier = createContext<bool?>().withTag(const DeltaTag());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    return DeltaModifier(false).Provider(
      builder: (_) => Counter(0).Provider(
        builder: (_) => const MaterialApp(
          title: 'Counter',
          home: Home(title: 'Counter Home Page'),
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

class IncrementButton extends ConsumerWidget<bool?> {
  const IncrementButton({super.key, super.tag = const DeltaTag()});

  int Function(int value) increment(bool? delta) {
    return (v) => v + (delta ?? false ? 10 : 1);
  }

  @override
  Widget build(BuildContext context, bool? value, Widget? child) {
    return FloatingActionButton(
      onPressed: () {
        context.sink(const CounterTag())?.update(increment(value));
      },
      tooltip: 'Increment',
      child: const Icon(Icons.add),
    );
  }
}

class CounterText extends ConsumerWidget<int> {
  const CounterText({super.key, super.tag = const CounterTag()});

  @override
  Widget build(BuildContext context, int value, Widget? child) {
    final headlineStyle = Theme.of(context).textTheme.headline4;
    return Text(value.toString(), style: headlineStyle);
  }
}

class DeltaModifierCheckbox extends ConsumerWidget<bool?> {
  const DeltaModifierCheckbox({super.key, super.tag = const DeltaTag()});

  @override
  Widget build(BuildContext context, bool? value, Widget? child) {
    return CheckboxListTile(
      value: value,
      onChanged: context.sink(tag)?.add,
      title: const Text('Increment by 10'),
    );
  }
}
