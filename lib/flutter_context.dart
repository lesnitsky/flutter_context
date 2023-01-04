// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

abstract class ContextTag<T> {
  const ContextTag();
}

final _typeTags = <Type, ContextTag>{};

class TypeTag<T> extends ContextTag<T> {
  factory TypeTag() {
    return (_typeTags[T] ??= TypeTag<T>._()) as TypeTag<T>;
  }

  const TypeTag._();
}

abstract class Mountable {
  Widget mount({required WidgetBuilder builder});
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
  Widget mount({required WidgetBuilder builder}) {
    return Provider(builder: builder);
  }

  Widget Provider({
    T? value,
    required WidgetBuilder builder,
  }) {
    return ContextProvider<T, K>(
      key: ValueKey(value),
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
      child: Builder(builder: widget.builder),
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
      throw Exception('No provider found for context ${tag.runtimeType}');
    }

    final notifier = w.deps[tag] as ValueNotifier<T>?;

    if (notifier == null) {
      throw Exception('No provider found for context ${tag.runtimeType}');
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

abstract class ConsumerWidget<T> extends Widget {
  ContextTag<T> get tag => TypeTag<T>();

  const ConsumerWidget({
    super.key,
  });

  @override
  Element createElement() {
    return ConsumerWidgetElement(this);
  }

  Widget build(BuildContext context, T value);
}

class ConsumerWidgetElement<T> extends ComponentElement {
  ConsumerWidgetElement(ConsumerWidget<T> widget) : super(widget);

  @override
  ConsumerWidget<T> get widget => super.widget as ConsumerWidget<T>;

  @override
  Widget build() {
    return ContextConsumer<T>(
      tag: widget.tag,
      builder: (context, value, child) {
        return widget.build(context, value);
      },
    );
  }
}

PendingContext<T, ContextTag<T>> createContext<T>() {
  return PendingContext<T, ContextTag<T>>(TypeTag<T>());
}

class LateInitContext<T, K extends ContextTag<T>> extends PendingContext<T, K>
    implements Mountable {
  final T Function() init;

  LateInitContext(super.tag, this.init);

  @override
  Widget mount({required WidgetBuilder builder}) {
    return Provider(builder: builder);
  }

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

extension ContextSinkExtension on BuildContext {
  ContextSink<T>? sink<T>([ContextTag<T>? tag]) {
    final sink = _ValueNotifierSink<T>(this, tag ?? TypeTag<T>());
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

extension MountExtension on BuildContext {
  Widget mount({required List<Mountable> children, required Widget child}) {
    return _Mount(
      children: children,
      child: child,
    );
  }
}

class MountableChild implements Mountable {
  final Widget child;

  const MountableChild(this.child);

  @override
  Widget mount({required WidgetBuilder builder}) {
    return child;
  }
}

class _Mount extends StatelessWidget {
  final List<Mountable> children;
  final Widget child;

  const _Mount({
    required this.children,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return [MountableChild(child), ...children.reversed].fold<Widget>(
      child,
      (child, mountable) {
        return mountable.mount(builder: (context) => child);
      },
    );
  }
}
