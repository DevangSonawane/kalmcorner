import 'dart:async';

enum Entitlement { none, premium }

abstract class PurchaseService {
  Future<void> init();
  Stream<Entitlement> get entitlement;
  Future<void> buyPremium();
  Future<void> restore();
}

class FakePurchases implements PurchaseService {
  FakePurchases() : _controller = StreamController.broadcast() {
    _controller.add(_entitlement);
  }

  Entitlement _entitlement = Entitlement.none;
  final StreamController<Entitlement> _controller;

  @override
  Future<void> init() async {}

  @override
  Stream<Entitlement> get entitlement => _controller.stream;

  @override
  Future<void> buyPremium() async {
    _entitlement = Entitlement.premium;
    _controller.add(_entitlement);
  }

  @override
  Future<void> restore() async {
    _controller.add(_entitlement);
  }

  void setDebugEntitlement(Entitlement e) {
    _entitlement = e;
    _controller.add(e);
  }

  void dispose() {
    _controller.close();
  }
}
