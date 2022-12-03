import 'package:flutter/material.dart';
import 'package:flutter_context/flutter_context.dart';

void main() {
  runApp(const MyApp());
}

// ignore: non_constant_identifier_names
final CounterContext = createContext().withHandlers<CounterHandlers>();

abstract class CounterHandlers extends ContextHandlers<int> {
  void increment();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements CounterHandlers {
  @override
  int value = 0;

  @override
  increment() {
    setState(() {
      value++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CounterContext.Provider(
      handlers: this,
      builder: (_) => MaterialApp(
        title: 'Flutter Context Demo Page',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
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
    final handlers = useHandlers<CounterHandlers>(context);

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
      floatingActionButton: FloatingActionButton(
        onPressed: handlers.increment,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
