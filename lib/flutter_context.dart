// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

abstract class ContextTag<T> {
  const ContextTag();
}

class Anonymous<T> extends ContextTag<T> {
  const Anonymous();
}

abstract class Mountable {
  Widget Provider({required WidgetBuilder builder});
}

abstract class Context<T, K extends ContextTag<T>> {
  final K tag;

  const Context(this.tag);

  Context<T, K> call(T value);
  Context<T, I> withTag<I extends ContextTag<T>>(I tag);

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

class PendingContext<T, K extends ContextTag<T>> extends Context<T, K> {
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
  PendingContext<T, I> withTag<I extends ContextTag<T>>(I tag) {
    return PendingContext(tag);
  }
}

abstract class ValueContext<T, K extends ContextTag<T>> extends Context<T, K>
    implements Mountable {
  T get value;

  const ValueContext(super.tag);

  @override
  ValueContext<T, K> call(T value) {
    return FinalContext(tag, value);
  }

  @override
  ValueContext<T, I> withTag<I extends ContextTag<T>>(I tag) {
    return FinalContext(tag, value);
  }

  @override
  Widget Provider({
    T? value,
    required WidgetBuilder builder,
  }) {
    return ContextProvider<T, K>(
      value: value ?? this.value,
      builder: builder,
      context: this,
    );
  }
}

class FinalContext<T, K extends ContextTag<T>> extends ValueContext<T, K> {
  @override
  final T value;

  const FinalContext(super.tag, this.value);
}

class ContextProvider<T, K extends ContextTag<T>> extends StatefulWidget {
  final Context<T, K> context;
  final WidgetBuilder builder;

  final T value;

  const ContextProvider({
    super.key,
    required this.context,
    required this.builder,
    required this.value,
  });

  @override
  State<ContextProvider<T, K>> createState() => _ContextProviderState<T, K>();
}

class _ContextProviderState<T, K extends ContextTag<T>>
    extends State<ContextProvider<T, K>> {
  T get value => widget.value;

  late final ValueNotifier<T> _notifier = ValueNotifier(value);
  late final _notifierKey = widget.context.tag;

  _D? get w => context.dependOnInheritedWidgetOfExactType<_D>();

  void _updateValue(T value) {
    _notifier.value = value;
  }

  late final Map<Object, dynamic> deps = {
    if (w?.deps != null) ...w!.deps,
    _notifierKey: _notifier,
  };

  @override
  void didUpdateWidget(covariant ContextProvider<T, K> oldWidget) {
    _updateValue(value);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _D(
      deps: deps,
      child: Builder(builder: widget.builder),
    );
  }
}

class ContextConsumer<T> extends StatelessWidget {
  final ContextTag<T> tag;
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
    ContextTag<T> tag,
  ) {
    final w = context.dependOnInheritedWidgetOfExactType<_D>();

    if (w == null) {
      throw Exception('No provider found for context $tag');
    }

    final notifier = w.deps[tag] as ValueNotifier<T>;
    return notifier;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = getNotifier<T>(context, tag);

    return ValueListenableBuilder<T>(
      key: key,
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

abstract class ConsumerWidget<T> extends Widget {
  final ContextTag<T> tag;
  final Widget? child;

  const ConsumerWidget({
    super.key,
    required this.tag,
    this.child,
  });

  @override
  Element createElement() {
    return ConsumerWidgetElement(this);
  }

  Widget build(BuildContext context, T value, Widget? child);
}

class ConsumerWidgetElement<T> extends ComponentElement {
  ConsumerWidgetElement(ConsumerWidget<T> widget) : super(widget);

  @override
  ConsumerWidget<T> get widget => super.widget as ConsumerWidget<T>;

  @override
  Widget build() {
    return ContextConsumer<T>(
      tag: widget.tag,
      child: widget.child,
      builder: (context, value, child) {
        return widget.build(context, value, child);
      },
    );
  }
}

PendingContext<T, Anonymous<T>> createContext<T>() {
  return PendingContext<T, Anonymous<T>>(Anonymous<T>());
}

class LateInitContext<T, K extends ContextTag<T>> extends PendingContext<T, K>
    implements Mountable {
  final T Function() init;

  LateInitContext(super.tag, this.init);

  @override
  Widget Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
  }) {
    return _LateInitContextProvider<T, K>(
      context: this,
      value: value,
      builder: builder,
    );
  }

  @override
  ValueContext<T, K> call(T value) {
    return FinalContext(tag, value);
  }

  @override
  LateInitContext<T, I> withTag<I extends ContextTag<T>>(I tag) {
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
  final ContextTag<T> tag;

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

extension SinkProvider on BuildContext {
  ContextSink<T>? sink<T>(ContextTag<T> tag) {
    final sink = _ValueNotifierSink<T>(this, tag);
    if (sink._notifier == null) {
      return null;
    }

    return sink;
  }
}

class _LateInitContextProvider<T, K extends ContextTag<T>>
    extends StatefulWidget {
  final LateInitContext<T, K> context;
  final T? value;
  final Widget Function(BuildContext context) builder;

  const _LateInitContextProvider({
    super.key,
    required this.context,
    required this.builder,
    this.value,
  });

  @override
  State<_LateInitContextProvider> createState() =>
      __LateInitContextProviderState<T, K>();
}

class __LateInitContextProviderState<T, K extends ContextTag<T>>
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
    );
  }
}
