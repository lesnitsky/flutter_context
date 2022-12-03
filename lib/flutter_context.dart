import 'package:flutter/material.dart';

abstract class ContextTag<T> {
  const ContextTag();
}

class Anonymous<T> extends ContextTag<T> {
  const Anonymous();
}

class TaggedContext<T, K extends ContextTag<T>> extends DataContext<T> {
  TaggedContext(
    K tag, [
    T? value,
  ]) : super._(tag, value);

  @override
  ContextWithHandlers<T, K, U> withHandlers<U extends ContextHandlers<T>>([
    U? handlers,
  ]) {
    return ContextWithHandlers<T, K, U>(
      tag as K,
      defaultValue,
      handlers,
    );
  }
}

class DataContext<T> {
  final ContextTag<T> tag;
  final T? defaultValue;

  Type get key => tag.runtimeType;
  DataContext._(this.tag, [this.defaultValue]);

  // ignore: non_constant_identifier_names
  ContextProvider<T> Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
  }) {
    if (value == null && defaultValue == null) {
      throw Exception('Neither value nor defaultValue is provided');
    }

    return ContextProvider<T>(
      value: value ?? defaultValue!,
      builder: builder,
      context: this,
    );
  }

  // ignore: non_constant_identifier_names
  ContextConsumer<T> Consumer(
    Widget Function(BuildContext context, T value, Widget? child) builder, {
    Widget? child,
  }) {
    return ContextConsumer<T>(
      builder: builder,
      context: this,
      child: child,
    );
  }

  ContextWithHandlers<T, ContextTag<T>, K>
      withHandlers<K extends ContextHandlers<T>>([
    K? handlers,
  ]) {
    return ContextWithHandlers<T, ContextTag<T>, K>(
      tag,
      defaultValue,
      handlers,
    );
  }
}

class ContextWithHandlers<T, K extends ContextTag<T>,
    U extends ContextHandlers<T>> extends TaggedContext<T, K> {
  final U? handlers;

  ContextWithHandlers(super.tag, super.value, this.handlers);

  @override
  // ignore: non_constant_identifier_names
  ContextProvider<T> Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
    U? handlers,
  }) {
    final h = handlers ?? this.handlers!;

    return ContextProvider<T>(
      value: value ?? h.value ?? defaultValue!,
      builder: builder,
      additionalDependencies: {U: handlers ?? this.handlers!},
      context: this,
    );
  }
}

class ContextProvider<T> extends StatefulWidget {
  final DataContext<T> context;
  final WidgetBuilder builder;
  final T value;
  final Map<Type, Object>? additionalDependencies;

  const ContextProvider({
    super.key,
    required this.context,
    required this.builder,
    required this.value,
    this.additionalDependencies,
  });

  @override
  State<ContextProvider<T>> createState() => _ContextProviderState<T>();
}

class _ContextProviderState<T> extends State<ContextProvider<T>> {
  T get value => widget.value ?? widget.context.defaultValue!;
  late final ValueNotifier<T> _notifier = ValueNotifier(value);

  _D? get w => context.dependOnInheritedWidgetOfExactType<_D>();

  late final deps = {
    if (w?.deps != null) ...w!.deps,
    widget.context.key: _notifier,
    if (widget.additionalDependencies != null)
      ...widget.additionalDependencies!,
  };

  @override
  void didUpdateWidget(covariant ContextProvider<T> oldWidget) {
    _notifier.value = value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _D(
      deps: deps,
      child: widget.builder(context),
    );
  }
}

class ContextConsumer<T> extends StatelessWidget {
  final DataContext<T> context;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const ContextConsumer({
    super.key,
    required this.context,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<_D>();

    if (w == null) {
      throw Exception('No provider found for context $context');
    }

    final notifier = w.deps[this.context.key] as ValueNotifier<T>;

    return ValueListenableBuilder<T>(
      key: key,
      valueListenable: notifier,
      child: child,
      builder: (context, value, child) {
        return builder(context, value, child);
      },
    );
  }
}

class _D extends InheritedWidget {
  final Map<Type, Object> deps;

  const _D({
    required super.child,
    required this.deps,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

DataContext<T> createContext<T>({T? value}) {
  return DataContext<T>._(Anonymous<T>(), value);
}

TaggedContext<T, K> createTaggedContext<T, K extends ContextTag<T>,
    U extends ContextHandlers<T>>({
  required K tag,
  T? value,
  U? handlers,
}) {
  return TaggedContext<T, K>(
    tag,
    value,
  );
}

abstract class ContextHandlers<T> {
  T get value;
  const ContextHandlers();
}

abstract class StateContextHandlers<T> extends ContextHandlers<T> {
  set value(T v);

  void setState(void Function() update);
}

K useHandlers<K extends ContextHandlers>(
  BuildContext context,
) {
  final w = context.dependOnInheritedWidgetOfExactType<_D>();

  if (w == null) {
    throw Exception('No provider found');
  }

  final handlers = w.deps[K] as K?;

  if (handlers == null) {
    throw Exception('No $K found');
  }

  return handlers;
}
