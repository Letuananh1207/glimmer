import 'package:flutter/widgets.dart';

/// Tạo ViewModel **một lần** khi màn vào cây và `dispose()` khi rời — dùng trong builder của route:
///
/// ```dart
/// builder: (_, s) => ViewModelHost(
///   create: (c) => CartViewModel(cart: c.read(), catalog: c.read()),
///   builder: (_, vm) => CartScreen(viewModel: vm),
/// ),
/// ```
///
/// go_router dựng lại builder của route nhiều lần (đổi trạng thái app, quay lại màn) — ViewModel vẫn giữ nguyên.
class ViewModelHost<T extends ChangeNotifier> extends StatefulWidget {
  const ViewModelHost({super.key, required this.create, required this.builder});

  /// Gọi một lần; [BuildContext] chỉ để `read()` phụ thuộc, không `watch()`.
  final T Function(BuildContext context) create;

  final Widget Function(BuildContext context, T viewModel) builder;

  @override
  State<ViewModelHost<T>> createState() => _ViewModelHostState<T>();
}

class _ViewModelHostState<T extends ChangeNotifier>
    extends State<ViewModelHost<T>> {
  late final T _viewModel = widget.create(context);

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _viewModel);
}
