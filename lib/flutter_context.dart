// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

abstract class Tag<T> {
  const Tag();

  @override
  String toString() => runtimeType.toString();
}

class TypeTag<T> extends Tag<T> {
  static final _typeTags = <Type, Tag>{};
  factory TypeTag() {
    return (_typeTags[T] ??= TypeTag<T>._()) as TypeTag<T>;
  }

  const TypeTag._();

  @override
  String toString() => T.toString();
}

class ValueTag<T> extends Tag<T> {
  static final _tags = <dynamic, ValueTag>{};

  final T _value;

  factory ValueTag(T value) {
    final tag = _tags[value] ??= ValueTag<T>._(value);
    return tag as ValueTag<T>;
  }

  const ValueTag._(this._value);

  @override
  String toString() => '$runtimeType($_value)';
}

abstract class Context<T, K extends Tag<T>> {
  final K tag;

  const Context(this.tag);

  Context<T, K> call(T value);
  Context<T, I> withTag<I extends Tag<T>>(I tag);

  Widget Consumer(
    Widget Function(BuildContext context, T value, Widget? child) builder, {
    Widget? child,
  }) {
    return ContextConsumer<T>(
      builder: builder,
      tag: tag,
      child: child,
    );
  }
}

class PendingContext<T, K extends Tag<T>> extends Context<T, K> {
  const PendingContext(super.tag);

  Widget Provider({
    required T value,
    required Widget Function(BuildContext context) builder,
  }) {
    return ContextProvider<T, K>(
      value: value,
      builder: builder,
      context: this,
    );
  }

  @override
  ValueContext<T, K> call(T value) {
    return FinalContext(tag, value);
  }

  @override
  PendingContext<T, I> withTag<I extends Tag<T>>(I tag) {
    return PendingContext(tag);
  }
}

abstract class ValueContext<T, K extends Tag<T>> extends Context<T, K> {
  T get value;

  const ValueContext(super.tag);

  @override
  ValueContext<T, K> call(T value) {
    return FinalContext(tag, value);
  }

  @override
  ValueContext<T, I> withTag<I extends Tag<T>>(I tag) {
    return FinalContext(tag, value);
  }

  Widget Provider({
    T? value,
    WidgetBuilder? builder,
    Widget? child,
  }) {
    return ContextProvider<T, K>(
      key: ValueKey(value),
      value: value ?? this.value,
      builder: builder,
      context: this,
      child: child,
    );
  }
}

class FinalContext<T, K extends Tag<T>> extends ValueContext<T, K> {
  @override
  final T value;

  const FinalContext(super.tag, this.value);
}

class ContextProvider<T, K extends Tag<T>> extends StatefulWidget {
  final Context<T, K> context;
  final WidgetBuilder? builder;
  final Widget? child;

  final T value;

  const ContextProvider({
    super.key,
    required this.context,
    required this.value,
    this.builder,
    this.child,
  });

  @override
  State<ContextProvider<T, K>> createState() => _ContextProviderState<T, K>();
}

class _ContextProviderState<T, K extends Tag<T>>
    extends State<ContextProvider<T, K>> {
  T get value => widget.value;

  late final ValueNotifier<T> _notifier = ValueNotifier(value);
  late final _notifierKey = widget.context.tag;

  bool _reassemble = false;

  _D? get w => context.dependOnInheritedWidgetOfExactType<_D>();

  late final Map<Object, dynamic> deps = {
    if (w?.deps != null) ...w!.deps,
    _notifierKey: _notifier,
  };

  @override
  Widget build(BuildContext context) {
    return _D(
      deps: deps,
      child: widget.child ?? Builder(builder: widget.builder!),
    );
  }

  @override
  void didUpdateWidget(covariant ContextProvider<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_reassemble) {
      _reassemble = false;
      return;
    }

    if (oldWidget.context != widget.context) {
      _notifier.value = widget.value;
    } else {
      _notifier.value = value;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    _reassemble = true;
  }
}

class ContextConsumer<T> extends StatelessWidget {
  final Tag<T> tag;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const ContextConsumer({
    super.key,
    required this.tag,
    required this.builder,
    this.child,
  });

  static ValueNotifier<T> getNotifier<T>(
    BuildContext context,
    Tag<T> tag,
  ) {
    final w = context.dependOnInheritedWidgetOfExactType<_D>();

    if (w == null) {
      throw Exception('No provider found for $tag');
    }

    final notifier = w.deps[tag] as ValueNotifier<T>?;

    if (notifier == null) {
      throw Exception('No value found for $tag');
    }

    return notifier;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = getNotifier<T>(context, tag);

    return ValueListenableBuilder<T>(
      valueListenable: notifier,
      child: child,
      builder: (context, value, child) {
        return builder(
          context,
          value,
          child,
        );
      },
    );
  }
}

class _D extends InheritedWidget {
  final Map<Object, dynamic> deps;

  const _D({
    required super.child,
    required this.deps,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

PendingContext<T, Tag<T>> createContext<T>() {
  return PendingContext<T, Tag<T>>(TypeTag<T>());
}

class LateInitContext<T, K extends Tag<T>> extends PendingContext<T, K> {
  final T Function() init;

  LateInitContext(super.tag, this.init);

  @override
  Widget Provider({
    T? value,
    WidgetBuilder? builder,
    Widget? child,
  }) {
    return _LateInitContextProvider<T, K>(
      context: this,
      value: value,
      builder: builder,
      child: child,
    );
  }

  @override
  ValueContext<T, K> call(T value) {
    return FinalContext(tag, value);
  }

  @override
  LateInitContext<T, I> withTag<I extends Tag<T>>(I tag) {
    return LateInitContext<T, I>(tag, init);
  }
}

abstract class ContextSink<T> extends Sink<T> {
  @override
  void add(T data);

  @override
  close() {}

  void update(T Function(T currentValue) update);
}

class _ValueNotifierSink<T> extends ContextSink<T> {
  final BuildContext context;
  final Tag<T> tag;

  late ValueNotifier<T>? _notifier;

  _ValueNotifierSink(this.context, this.tag) {
    try {
      _notifier = ContextConsumer.getNotifier<T>(context, tag);
    } catch (e) {
      _notifier = null;
    }
  }

  @override
  void add(T data) {
    _notifier!.value = data;
  }

  @override
  void update(T Function(T currentValue) update) {
    add(update(_notifier!.value));
  }
}

extension on BuildContext {
  ContextSink<T>? sink<T>([Tag<T>? tag]) {
    final sink = _ValueNotifierSink<T>(this, tag ?? TypeTag<T>());
    if (sink._notifier == null) {
      return null;
    }

    return sink;
  }
}

extension UpdateContextValueExtension on BuildContext {
  void Function(T value)? setValue<T>([Tag<T>? tag]) {
    final s = sink<T>(tag ?? TypeTag<T>());
    if (s == null) return null;

    return (value) {
      s.add(value);
    };
  }

  void Function(T Function(T currentValue))? updateValue<T>([
    Tag<T>? tag,
  ]) {
    final s = sink<T>(tag ?? TypeTag<T>());
    if (s == null) return null;

    return (update) {
      s.update(update);
    };
  }
}

class _LateInitContextProvider<T, K extends Tag<T>> extends StatefulWidget {
  final LateInitContext<T, K> context;
  final T? value;
  final WidgetBuilder? builder;
  final Widget? child;

  const _LateInitContextProvider({
    super.key,
    required this.context,
    this.builder,
    this.child,
    this.value,
  });

  @override
  State<_LateInitContextProvider> createState() =>
      __LateInitContextProviderState<T, K>();
}

class __LateInitContextProviderState<T, K extends Tag<T>>
    extends State<_LateInitContextProvider<T, K>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.context.init();
  }

  @override
  void didUpdateWidget(covariant _LateInitContextProvider<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.context == widget.context) {
      if (oldWidget.value != widget.value && widget.value != null) {
        value = widget.value as T;
      }
    } else {
      value = widget.context.init();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContextProvider(
      context: widget.context,
      value: value,
      builder: widget.builder,
      child: widget.child,
    );
  }
}
