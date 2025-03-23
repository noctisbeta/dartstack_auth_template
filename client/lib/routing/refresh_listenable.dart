import 'dart:async';

import 'package:flutter/foundation.dart';

class RefreshListenable extends ChangeNotifier {
  RefreshListenable({required Stream<void> stream}) {
    notifyListenerSubscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<void> notifyListenerSubscription;

  @override
  void dispose() {
    unawaited(notifyListenerSubscription.cancel());
    super.dispose();
  }
}
