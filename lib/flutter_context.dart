// ignore_for_file: non_constant_identifier_names

import 'package:flutter/widgets.dart';

typedef ConsumerBuilder = Widget Function(
  BuildContext context,
  dynamic value,
  Widget? child,
);

abstract class Context<T> {
  const Context();

  Context<T> call(T value);

  Widget Consumer(
    ConsumerBuilder builder, {
    Widget? child,
    Key? key,
  }) {
    return ContextConsumer<T>(
      context: this,
      builder: builder,
      child: child,
    );
  }
}

class PendingContext<T> extends Context<T> {
  const PendingContext();

  Widget Provider({
    required T value,
    WidgetBuilder? builder,
    Widget? child,
  }) {
    return ContextProvider<T>(
      value: value,
      builder: builder,
      context: this,
      child: child,
    );
  }

  Widget bind({
    required T value,
    required ConsumerBuilder builder,
    Widget? child,
  }) {
    return Provider(
      value: value,
      child: child,
      builder: (context) {
        return Consumer((context, value, child) {
          return builder(context, value, child);
        });
      },
    );
  }

  @override
  ValueContext<T> call(T value) {
    return FinalContext(value);
  }
}

abstract class ValueContext<T> extends Context<T> {
  T get value;

  const ValueContext();

  @override
  ValueContext<T> call(T value) {
    return FinalContext(value);
  }

  Widget Provider({
    Key? key,
    T? value,
    WidgetBuilder? builder,
    Widget? child,
  }) {
    return ContextProvider<T>(
      key: key,
      value: value ?? this.value,
      builder: builder,
      context: this,
      child: child,
    );
  }

  Widget bind({
    T? value,
    required ConsumerBuilder builder,
    Widget? child,
  }) {
    return Provider(
      value: value ?? this.value,
      builder: (context) {
        return Consumer((context, value, child) {
          return builder(context, value, child);
        });
      },
      child: child,
    );
  }
}

class FinalContext<T> extends ValueContext<T> {
  @override
  final T value;

  const FinalContext(this.value);
}

class ContextProvider<T> extends StatefulWidget {
  final Context<T> context;
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
  State<ContextProvider<T>> createState() => _ContextProviderState<T>();
}

class _ContextProviderState<T> extends State<ContextProvider<T>> {
  T get value => widget.value;

  late final ValueNotifier<T> _notifier = ValueNotifier(value);
  late final _notifierKey = widget.context;

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
  void didUpdateWidget(covariant ContextProvider<T> oldWidget) {
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
  final Context<T> context;
  final ConsumerBuilder builder;
  final Widget? child;

  const ContextConsumer({
    super.key,
    required this.context,
    required this.builder,
    this.child,
  });

  static ValueNotifier<T> getNotifier<T>(
    BuildContext context,
    Context<T> dataContext,
  ) {
    final w = context.dependOnInheritedWidgetOfExactType<_D>();

    if (w == null) {
      throw Exception('No provider found for $dataContext');
    }

    final notifier = w.deps[dataContext] as ValueNotifier<T>?;

    if (notifier == null) {
      throw Exception('No value found for $dataContext');
    }

    return notifier;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = getNotifier<T>(context, this.context);

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

PendingContext<T> createContext<T>() {
  return PendingContext<T>();
}

class LateInitContext<T> extends PendingContext<T> {
  final T Function() init;

  LateInitContext(this.init);

  @override
  Widget Provider({
    T? value,
    WidgetBuilder? builder,
    Widget? child,
  }) {
    return _LateInitContextProvider<T>(
      context: this,
      value: value,
      builder: builder,
      child: child,
    );
  }

  @override
  ValueContext<T> call(T value) {
    return FinalContext(value);
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
  final Context<T> dataContext;

  late ValueNotifier<T>? _notifier;

  _ValueNotifierSink(this.context, this.dataContext) {
    try {
      _notifier = ContextConsumer.getNotifier<T>(context, dataContext);
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
  ContextSink<T>? sink<T>(Context<T> context) {
    final sink = _ValueNotifierSink<T>(this, context);
    if (sink._notifier == null) {
      return null;
    }

    return sink;
  }
}

extension BuildContextExtensions on BuildContext {
  void Function(T value)? setValue<T>(Context<T> context) {
    final s = sink<T>(context);
    if (s == null) return null;

    return (value) {
      s.add(value);
    };
  }

  void Function(T Function(T currentValue))? updateValue<T>(
    Context<T> context,
  ) {
    final s = sink<T>(context);
    if (s == null) return null;

    return (update) {
      s.update(update);
    };
  }

  T? read<T>(Context<T> context) {
    final notifier = ContextConsumer.getNotifier<T>(this, context);
    return notifier.value;
  }
}

class _LateInitContextProvider<T> extends StatefulWidget {
  final LateInitContext<T> context;
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
      __LateInitContextProviderState<T>();
}

class __LateInitContextProviderState<T>
    extends State<_LateInitContextProvider<T>> {
  late T value;

  @override
  void initState() {
    super.initState();
    value = widget.context.init();
  }

  @override
  void didUpdateWidget(covariant _LateInitContextProvider<T> oldWidget) {
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

class ContextListener<T> extends ProxyWidget {
  final Context<T> context;
  final void Function(T value) onValue;

  const ContextListener({
    super.key,
    required super.child,
    required this.context,
    required this.onValue,
  });

  @override
  Element createElement() {
    return ContextListenerElement<T>(this);
  }
}

class ContextListenerElement<T> extends ProxyElement {
  ContextListenerElement(super.widget);

  @override
  ContextListener<T> get widget => super.widget as ContextListener<T>;

  late ValueNotifier<T> notifier;
  bool _reassemble = false;

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);

    notifier = ContextConsumer.getNotifier(this, widget.context);
    notifier.addListener(_notifyListener);
  }

  void _notifyListener() {
    widget.onValue(notifier.value);
  }

  @override
  void reassemble() {
    super.reassemble();
    _reassemble = true;
  }

  @override
  void update(ContextListener<T> newWidget) {
    super.update(newWidget);

    if (_reassemble) {
      _reassemble = false;
      return;
    }

    if (newWidget.context != widget.context) {
      notifier.removeListener(_notifyListener);
      notifier = ContextConsumer.getNotifier(this, newWidget.context);
      notifier.addListener(_notifyListener);
    } else if (newWidget.onValue != widget.onValue) {
      notifier.removeListener(_notifyListener);
      notifier.addListener(_notifyListener);
    }
  }

  @override
  void unmount() {
    super.unmount();
    notifier.removeListener(_notifyListener);
  }

  @override
  void notifyClients(covariant ProxyWidget oldWidget) {}
}
