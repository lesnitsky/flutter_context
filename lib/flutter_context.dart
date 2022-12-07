// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';

abstract class ContextTag<T> {
  const ContextTag();
}

class _HandlersTag<T, K extends ContextHandlers<T>, U extends ContextTag<T>> {
  final Context<T, K, U> context;
  const _HandlersTag(this.context);
}

class Anonymous<T> extends ContextTag<T> {
  const Anonymous();
}

class NoopActions<T> extends ContextHandlers<T> {}

abstract class Context<T, K extends ContextHandlers<T>,
    U extends ContextTag<T>> {
  final U tag;
  final K actions;

  const Context(this.tag, this.actions);

  Context<T, K, U> call(T value);
  Context<T, I, U> withHandlers<I extends ContextHandlers<T>>(I handlers);
  Context<T, K, I> withTag<I extends ContextTag<T>>(I tag);

  Widget Consumer(
    Widget Function(BuildContext context, T value, Widget? child) builder, {
    Widget? child,
  }) {
    return ContextConsumer<T>(
      builder: builder,
      context: this,
      child: child,
    );
  }

  HandlersRef<T, K, U> handlers(BuildContext context) {
    final w = context.dependOnInheritedWidgetOfExactType<_D>();

    if (w == null) {
      throw Exception('No provider found for $T');
    }

    final actions = w.deps[_HandlersTag<T, K, U>] as K?;

    if (actions == null) {
      throw Exception('No $K found');
    }

    return BuildContextHandlersRef<T, K, U>(
      actions,
      context,
      tag.runtimeType,
    );
  }
}

class PendingContext<T, K extends ContextHandlers<T>, U extends ContextTag<T>>
    extends Context<T, K, U> {
  const PendingContext(super.tag, super.actions);

  Widget Provider({
    required T value,
    required Widget Function(BuildContext context) builder,
  }) {
    return ContextProvider<T, K, U>(
      value: value,
      builder: builder,
      context: this,
    );
  }

  @override
  ValueContext<T, K, U> call(T value) {
    return ValueContext(tag, actions, value);
  }

  @override
  PendingContext<T, I, U> withHandlers<I extends ContextHandlers<T>>(
    I handlers,
  ) {
    return PendingContext(tag, handlers);
  }

  @override
  PendingContext<T, K, I> withTag<I extends ContextTag<T>>(I tag) {
    return PendingContext(tag, actions);
  }
}

class ValueContext<T, K extends ContextHandlers<T>, U extends ContextTag<T>>
    extends Context<T, K, U> {
  final T value;

  const ValueContext(super.tag, super.handlers, this.value);

  @override
  ValueContext<T, K, U> call(T value) {
    return ValueContext(tag, actions, value);
  }

  @override
  ValueContext<T, I, U> withHandlers<I extends ContextHandlers<T>>(I handlers) {
    return ValueContext(tag, handlers, value);
  }

  @override
  ValueContext<T, K, I> withTag<I extends ContextTag<T>>(I tag) {
    return ValueContext(tag, actions, value);
  }

  Widget Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
  }) {
    return ContextProvider<T, K, U>(
      value: value ?? this.value,
      builder: builder,
      context: this,
    );
  }
}

class ContextProvider<T, K extends ContextHandlers<T>, U extends ContextTag<T>>
    extends StatefulWidget {
  final Context<T, K, U> context;
  final WidgetBuilder builder;
  final T value;

  const ContextProvider({
    super.key,
    required this.context,
    required this.builder,
    required this.value,
  });

  @override
  State<ContextProvider<T, K, U>> createState() =>
      _ContextProviderState<T, K, U>();
}

class _ContextProviderState<T, K extends ContextHandlers<T>,
    U extends ContextTag<T>> extends State<ContextProvider<T, K, U>> {
  T get value => widget.value;

  late final ValueNotifier<T> _notifier = ValueNotifier(value);

  _D? get w => context.dependOnInheritedWidgetOfExactType<_D>();

  late final deps = {
    if (w?.deps != null) ...w!.deps,
    widget.context.tag.runtimeType: _notifier,
    _HandlersTag<T, K, U>: widget.context.actions,
  };

  Widget _defaultWrapper({required Widget child}) => child;

  Widget _actionsWrapper({required Widget child}) {
    return Actions(
      actions: {
        CallHandlerIntent<T, K>: CallHandlerAction<T, K>(widget.context.actions)
      },
      child: child,
    );
  }

  @override
  void didUpdateWidget(covariant ContextProvider<T, K, U> oldWidget) {
    _notifier.value = value;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final wrapper = widget.context.actions is NoopActions
        ? _defaultWrapper
        : _actionsWrapper;

    return _D(
      deps: deps,
      child: wrapper.call(
        child: Builder(builder: (context) {
          return widget.builder(context);
        }),
      ),
    );
  }
}

class ContextConsumer<T> extends StatelessWidget {
  final Context context;
  final Widget Function(BuildContext context, T value, Widget? child) builder;
  final Widget? child;

  const ContextConsumer({
    super.key,
    required this.context,
    required this.builder,
    this.child,
  });

  static ValueNotifier<T> getNotifier<T>(
    BuildContext context,
    Context dataContext,
  ) {
    final w = context.dependOnInheritedWidgetOfExactType<_D>();
    final key = dataContext.tag.runtimeType;

    if (w == null) {
      throw Exception('No provider found for context $key');
    }

    final notifier = w.deps[key] as ValueNotifier<T>;
    return notifier;
  }

  @override
  Widget build(BuildContext context) {
    final notifier = getNotifier<T>(context, this.context);

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

class ValueContextBuilder<T, K extends ContextHandlers<T>,
    U extends ContextTag<T>> {
  final T value;

  ValueContextBuilder(this.value);
}

PendingContext<T, NoopActions<T>, Anonymous<T>> createContext<T>() {
  return PendingContext<T, NoopActions<T>, Anonymous<T>>(
    Anonymous<T>(),
    NoopActions<T>(),
  );
}

const _callerToken = Object();

abstract class ContextHandlers<T> {
  late ValueNotifier<T> _notifier;
  Object? _authorizedCallerToken;

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

class SetStateHandlers<T> extends ContextHandlers<T> {
  void setValue(T value) {
    this.value = value;
  }
}

final setBool = SetStateHandlers<bool>();
final setInt = SetStateHandlers<int>();
final setDouble = SetStateHandlers<double>();
final setNum = SetStateHandlers<num>();
final setString = SetStateHandlers<String>();
final setDate = SetStateHandlers<DateTime>();
final setDuration = SetStateHandlers<Duration>();

class MultiContext extends StatelessWidget {
  final List<ValueContext> contexts;
  final WidgetBuilder builder;

  const MultiContext({
    super.key,
    required this.contexts,
    required this.builder,
  });

  Widget _unwrap(
    BuildContext context,
    List<ValueContext> contexts,
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

abstract class ConsumerWidget<T> extends Widget {
  Context get context;
  final Widget? child;

  const ConsumerWidget({Key? key, this.child}) : super(key: key);

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
      context: widget.context,
      builder: (context, value, child) => widget.build(this, value, child),
    );
  }
}
