import 'package:flutter/material.dart';

class ContextToken {}

class FlutterContext<T> {
  final ContextToken token;
  late final ValueNotifier<T> _notifier;
  final T? defaultValue;

  FlutterContext._(this.token, [this.defaultValue]);

  // ignore: non_constant_identifier_names
  ContextProvider<T> Provider({
    T? value,
    required Widget Function(BuildContext context) builder,
  }) {
    if (value == null && defaultValue == null) {
      throw Exception('Neither value nor defaultValue is provided');
    }

    _notifier = ValueNotifier<T>(value ?? defaultValue!);

    return ContextProvider<T>(
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
    final provider = _getProviderElement(context)?.widget as _Provider<T>?;

    final notifier = provider?.context._notifier ?? _notifier;

    final value = update(notifier.value);
    notifier.value = value;
    return value;
  }

  InheritedElement? _getProviderElement(BuildContext context) {
    while (true) {
      final nearestContextElement =
          context.getElementForInheritedWidgetOfExactType<_Provider<T>>();

      if (nearestContextElement == null) {
        return null;
      }

      final w = nearestContextElement.widget as _Provider<T>?;

      if (w?.context.token != token) {
        context = nearestContextElement;
        continue;
      } else {
        return nearestContextElement;
      }
    }
  }
}

class _Provider<T> extends InheritedWidget {
  final T value;
  final FlutterContext<T> context;

  const _Provider({
    required this.value,
    required this.context,
    required super.child,
  });

  @override
  bool updateShouldNotify(_Provider<T> oldWidget) {
    return value != oldWidget.value;
  }
}

class ContextProvider<T> extends StatelessWidget {
  final FlutterContext<T> context;
  final WidgetBuilder builder;

  const ContextProvider({
    super.key,
    required this.context,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: this.context._notifier,
      builder: (context, value, child) {
        return _Provider<T>(
          context: this.context,
          value: value,
          child: Builder(
            builder: (context) {
              return builder(context);
            },
          ),
        );
      },
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
    final providerElement = this.context._getProviderElement(context);

    if (providerElement == null) {
      throw Exception(
        'No provider for type $T found in the widget tree.'
        'You must wrap your widget tree with a ContextProvider<$T>.',
      );
    }

    context.dependOnInheritedElement(providerElement);

    return builder(context, (providerElement.widget as _Provider<T>).value);
  }
}

FlutterContext<T> createContext<T>([T? defaultValue]) {
  return FlutterContext<T>._(ContextToken(), defaultValue);
}
