import 'package:flutter/material.dart';

abstract class ContextTag<T> {
  const ContextTag();
}

class Anonymous<T> extends ContextTag<T> {
  const Anonymous();
}

class TaggedContext<T, K extends ContextTag<T>> extends FlutterContext<T> {
  TaggedContext(K tag, [T? value]) : super._(tag, value);
}

class FlutterContext<T> {
  final ContextTag<T> tag;
  late final ValueNotifier<T> _notifier;
  final T? defaultValue;

  Type get key => tag.runtimeType;

  FlutterContext._(this.tag, [this.defaultValue]);

  // ignore: non_constant_identifier_names
  ContextProvider<T> Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
  }) {
    if (value == null && defaultValue == null) {
      throw Exception('Neither value nor defaultValue is provided');
    }

    return ContextProvider<T>(
      key: ValueKey(key),
      initialValue: value ?? defaultValue!,
      builder: builder,
      context: this,
    );
  }

  // ignore: non_constant_identifier_names
  ContextConsumer<T> Consumer(
    Widget Function(BuildContext context, T value) builder,
  ) {
    return ContextConsumer<T>(
      builder: builder,
      context: this,
    );
  }

  T update(BuildContext context, T Function(T value) update) {
    final newValue = update(_notifier.value);
    _notifier.value = newValue;
    return newValue;
  }
}

class ContextProvider<T> extends StatefulWidget {
  final FlutterContext<T> context;
  final WidgetBuilder builder;
  final T initialValue;

  const ContextProvider({
    super.key,
    required this.context,
    required this.builder,
    required this.initialValue,
  });

  @override
  State<ContextProvider<T>> createState() => _ContextProviderState<T>();
}

class _ContextProviderState<T> extends State<ContextProvider<T>> {
  @override
  void initState() {
    widget.context._notifier = ValueNotifier<T>(widget.initialValue);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<DepsProvider>();

    return DepsProvider(
      deps: {
        if (w?.deps != null) ...w!.deps,
        widget.context.key: widget.context,
      },
      child: Builder(
        builder: (context) {
          return widget.builder(context);
        },
      ),
    );
  }
}

class ContextConsumer<T> extends StatelessWidget {
  final FlutterContext<T> context;
  final Widget Function(BuildContext context, T value) builder;

  const ContextConsumer({
    super.key,
    required this.context,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<DepsProvider>();

    if (w == null) {
      throw Exception('No provider found for context $context');
    }

    final notifier = (w.deps[this.context.key] as FlutterContext<T>)._notifier;

    return ValueListenableBuilder<T>(
      key: key,
      valueListenable: notifier,
      builder: (context, value, child) {
        return builder(context, value);
      },
    );
  }
}

class DepsProvider extends InheritedWidget {
  final Map<Type, FlutterContext> deps;

  const DepsProvider({
    super.key,
    required super.child,
    required this.deps,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

FlutterContext<T> createContext<T>([T? defaultValue]) {
  return FlutterContext<T>._(Anonymous<T>(), defaultValue);
}

TaggedContext<T, K> createTaggedContext<T, K extends ContextTag<T>>({
  required K tag,
  T? defaultValue,
}) {
  return TaggedContext<T, K>(tag, defaultValue);
}
