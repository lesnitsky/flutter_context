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
  TaggedContext<T, K> call(T value) {
    return TaggedContext(tag as K, value);
  }

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
  T? defaultValue;

  Type get key => tag.runtimeType;
  DataContext._(this.tag, [this.defaultValue]);

  DataContext<T> call(T value) {
    return DataContext._(tag, value);
  }

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
  final U? _handlers;

  ContextWithHandlers(super.tag, super.value, this._handlers);

  @override
  ContextWithHandlers<T, K, U> call(T value) {
    return ContextWithHandlers(tag as K, value, _handlers);
  }

  @override
  // ignore: non_constant_identifier_names
  ContextProvider<T> Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
    U? handlers,
  }) {
    final h = handlers ?? _handlers!;

    return ContextProvider<T>(
      value: value ?? defaultValue!,
      builder: builder,
      additionalDependencies: {U: h},
      wrapper: ({required Widget child}) {
        return Actions(
          actions: {
            CallHandlerIntent<T, U>: CallHandlerAction<T, U>(h),
          },
          child: child,
        );
      },
      context: this,
    );
  }

  HandlersRef<T, U, K> handlers(BuildContext context) {
    return _useHandlers<T, U, K>(context, key);
  }
}

class ContextProvider<T> extends StatefulWidget {
  final DataContext<T> context;
  final WidgetBuilder builder;
  final T value;
  final Map<Type, Object>? additionalDependencies;
  final Widget Function({required Widget child})? wrapper;

  const ContextProvider({
    super.key,
    required this.context,
    required this.builder,
    required this.value,
    this.additionalDependencies,
    this.wrapper,
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

  Widget _defaultWrapper({required Widget child}) => child;

  @override
  void didUpdateWidget(covariant ContextProvider<T> oldWidget) {
    _notifier.value = value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return _D(
      deps: deps,
      child: (widget.wrapper ?? _defaultWrapper).call(
        child: widget.builder(context),
      ),
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

DataContext<T> createContext<T>([T? value]) {
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

const _callerToken = Object();

abstract class ContextHandlers<T> {
  late ValueNotifier<T> _notifier;
  Object? _authorizedCallerToken;
  Object? _arg;

  T get value {
    if (_authorizedCallerToken != _callerToken) {
      throw Exception('Unauthorized access to value');
    }

    return _notifier.value;
  }

  set value(T value) {
    if (_authorizedCallerToken != _callerToken) {
      throw Exception("Calling handler directly is not allowed");
    }

    _notifier.value = value;
  }

  Set<Function> get disabledActions => const {};
}

class CallHandlerIntent<T, K extends ContextHandlers<T>> extends Intent {
  final Function action;

  const CallHandlerIntent(this.action);
}

final _argsForIntent = {};

class CallHandlerAction<T, K extends ContextHandlers<T>>
    extends Action<CallHandlerIntent<T, K>> {
  final K _handlers;

  CallHandlerAction(this._handlers);

  @override
  bool isEnabled(CallHandlerIntent<T, K> intent) {
    _handlers._authorizedCallerToken = _callerToken;
    final disabledActions = _handlers.disabledActions;

    _handlers._authorizedCallerToken = null;

    return !disabledActions.contains(intent.action);
  }

  @override
  void invoke(CallHandlerIntent<T, K> intent) {
    _handlers._authorizedCallerToken = _callerToken;
    final arg = _argsForIntent[intent];

    if (arg == null) {
      intent.action.call();
    } else {
      intent.action.call(arg);
    }

    _handlers._authorizedCallerToken = null;
  }
}

extension _TypeWrapper<T> on void Function(T) {
  typeWrapper(void Function() inner, Intent intent, [Object? outerArg]) {
    if (this is void Function([T])) {
      return ([T? arg]) {
        _argsForIntent[intent] = arg ?? outerArg;
        inner();
        _argsForIntent.remove(intent);
      };
    } else if (this is void Function(T?)) {
      return ([T? arg]) {
        _argsForIntent[intent] = arg ?? outerArg;
        inner();
        _argsForIntent.remove(intent);
      };
    }

    throw Exception('Unsupported type $runtimeType');
  }
}

extension NullableArg<T> on void Function(T) {
  void Function(T? arg) argNullable() {
    return (T? arg) {
      this.call(arg as T);
    };
  }
}

abstract class HandlersRef<T, K extends ContextHandlers<T>,
    U extends ContextTag<T>> {
  K get actions;
  BuildContext get context;
  Type get contextKey;

  late CallHandlerIntent<T, K> intent;

  void invoke() {
    actions._authorizedCallerToken = _callerToken;
    final prevValue = actions.value;

    Actions.invoke(context, intent);

    actions._authorizedCallerToken = _callerToken;
    final newValue = actions.value;

    if (prevValue != newValue && context is Element) {
      (context as Element).markNeedsBuild();
    }
    actions._authorizedCallerToken = null;
  }

  I? call<I extends Function>(I action, [Object? arg]) {
    intent = CallHandlerIntent<T, K>(action);

    final a = Actions.maybeFind(context, intent: intent);

    if (a == null) {
      return null;
    }

    final value = context.dependOnInheritedWidgetOfExactType<_D>();
    final deps = value?.deps;

    if (deps == null) {
      throw Exception('No provider found for context $context');
    }

    final n = deps[contextKey];

    actions._notifier = n as ValueNotifier<T>;

    if (a.isEnabled(intent)) {
      if (action is Function(T)) return action.typeWrapper(invoke, intent, arg);
      if (action is Function([T?])) {
        return action.typeWrapper(invoke, intent, arg);
      }

      if (action is void Function()) return invoke as I;
    }

    return null;
  }
}

class BuildContextHandlersRef<T, K extends ContextHandlers<T>,
    U extends ContextTag<T>> extends HandlersRef<T, K, U> {
  @override
  final K actions;

  @override
  final BuildContext context;

  @override
  Type contextKey;

  BuildContextHandlersRef(this.actions, this.context, this.contextKey);
}

HandlersRef<T, K, U>
    _useHandlers<T, K extends ContextHandlers<T>, U extends ContextTag<T>>(
  BuildContext context,
  Type contextKey,
) {
  final w = context.dependOnInheritedWidgetOfExactType<_D>();

  if (w == null) {
    throw Exception('No provider found');
  }

  final actions = w.deps[K] as K?;

  if (actions == null) {
    throw Exception('No $K found');
  }

  return BuildContextHandlersRef<T, K, U>(
    actions,
    context,
    contextKey,
  );
}

class SetStateHandlers<T> extends ContextHandlers<T> {
  void setValue(T value) {
    this.value = value;
  }
}

final setBool = SetStateHandlers<bool>();

class MultiContext extends StatelessWidget {
  final List<DataContext> contexts;
  final WidgetBuilder builder;

  const MultiContext({
    super.key,
    required this.contexts,
    required this.builder,
  });

  Widget _unwrap(
    BuildContext context,
    List<DataContext> contexts,
    WidgetBuilder builder,
  ) {
    if (contexts.isEmpty) {
      return builder(context);
    }

    return contexts.first.Provider(
      builder: (context) => _unwrap(
        context,
        contexts.sublist(1),
        builder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _unwrap(context, contexts, builder);
  }
}
