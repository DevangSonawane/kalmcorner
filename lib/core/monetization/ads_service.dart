abstract class AdsService {
  Future<void> init();
  Future<void> maybeShowAfterCompletion();
  bool get enabled;
}

class NoopAds implements AdsService {
  @override
  Future<void> init() async {}

  @override
  Future<void> maybeShowAfterCompletion() async {}

  @override
  bool get enabled => false;
}
