import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

// ignore: non_constant_identifier_names
final CounterContext = createContext<int>().withHandlers(CounterHandlers());

class CounterHandlers extends ContextHandlers<int> {
  @override
  Set<Function> get disabledActions {
    return {
      if (value >= 5) increment,
    };
  }

  void increment() {
    value++;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(context) {
    return CounterContext.Provider(
      value: 0,
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
    final increment = h(h.actions.increment);

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
