// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

final CounterContext = createContext<int>().withHandlers(CounterHandlers());
final DeltaContext = createContext(false).withHandlers(setBool);

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
        DeltaContext(false),
        CounterContext(0),
      ],
      builder: (_) => MaterialApp(
        title: 'Flutter Context Demo Page',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: const Home(title: 'Flutter Context Demo Page'),
      ),
    );
  }
}

class Home extends StatelessWidget {
  final String title;
  const Home({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final h = CounterContext.handlers(context);
    final d = DeltaContext.handlers(context);

    return DeltaContext.Consumer((context, value, child) {
      final increment = h(h.actions.increment, value ? 10 : null);

      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              const SizedBox(height: 16),
              CounterContext.Consumer(
                (context, value, _) => Text(
                  '$value',
                  style: Theme.of(context).textTheme.headline4,
                ),
              ),
              SizedBox(
                width: 200,
                child: CheckboxListTile(
                  value: value,
                  onChanged: d(d.actions.setValue)?.argNullable(),
                  title: const Text('Increment by 10'),
                ),
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
    });
  }
}
