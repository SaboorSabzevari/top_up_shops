
import 'app_notifier.dart';
import 'internet_chek.dart';

Future<T?> runGuarded<T>(
    Future<T> Function() action, {
      String? loadingText,
      String? successMessage,
      bool checkInternet = true,
    }) async {
  if (checkInternet) {
    final hasInternet = await checkInternetConnection();
    if (!hasInternet) {
      AppToast.error('اتصال اینترنت برقرار نیست. لطفاً دوباره تلاش کنید.');
      return null;
    }
  }

  AppLoader.show(loadingText);
  try {
    final result = await action();
    if (successMessage != null) {
      AppToast.success(successMessage);
    }
    return result;
  } catch (e) {
    AppToast.error(_friendlyError(e));
    return null;
  } finally {
    AppLoader.hide();
  }
}

String _friendlyError(Object e) {
  final msg = e.toString().replaceFirst('Exception: ', '');
  if (msg.length > 160) {
    return '${msg.substring(0, 160)}...';
  }
  return msg;
}