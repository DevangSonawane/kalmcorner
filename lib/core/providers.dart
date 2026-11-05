import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calmcorner/core/audio/audio_service.dart';
import 'package:calmcorner/core/haptics/haptic_service.dart';
import 'package:calmcorner/core/persistence/prefs_store.dart';
import 'package:calmcorner/core/analytics/analytics_service.dart';
import 'package:calmcorner/core/monetization/ads_service.dart';
import 'package:calmcorner/core/monetization/purchase_service.dart';

final prefsStoreProvider = Provider<PrefsStore>(
  (ref) => throw UnimplementedError(),
);
final audioServiceProvider = Provider<AudioService>(
  (ref) => throw UnimplementedError(),
);
final hapticServiceProvider = Provider<HapticService>(
  (ref) => throw UnimplementedError(),
);
final analyticsProvider = Provider<AnalyticsService>(
  (ref) => throw UnimplementedError(),
);
final adsProvider = Provider<AdsService>((ref) => throw UnimplementedError());
final purchaseProvider = Provider<PurchaseService>(
  (ref) => throw UnimplementedError(),
);
final entitlementProvider = StreamProvider<Entitlement>(
  (ref) => throw UnimplementedError(),
);

/// Completes when slow start-up work (audio loading etc.) is finished.
/// The splash screen waits for it. Tests get an already-finished future.
final bootProvider = Provider<Future<void>>((ref) => Future<void>.value());
