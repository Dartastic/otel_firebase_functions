// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_firebase_functions/otel_firebase_functions.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_firebase_functions-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('call records region + function name + app check', () async {
    await tracedFirebaseFunctions<String>(
      operation: 'call',
      invoke: () async => const FirebaseFunctionsCallResult(
        value: 'ok',
        result: FirebaseFunctionsResult(
          region: 'us-central1',
          functionName: 'processCheckout',
          appCheckTokenAttached: true,
          authTokenAttached: true,
          requestPayloadSize: 512,
          responsePayloadSize: 1200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('firebase_functions call')!);
    expect(a['firebase_functions.region'], 'us-central1');
    expect(a['firebase_functions.app_check.attached'], true);
  });

  test('permission-denied sets span error', () async {
    await tracedFirebaseFunctions<String>(
      operation: 'call',
      invoke: () async => const FirebaseFunctionsCallResult(
        value: 'ok',
        result: FirebaseFunctionsResult(errorCode: 'permission-denied'),
      ),
    );
    expect(
      spans.findSpanByName('firebase_functions call')!.status,
      SpanStatusCode.Error,
    );
  });

  test('cancelled does NOT set span error', () async {
    await tracedFirebaseFunctions<String>(
      operation: 'call',
      invoke: () async => const FirebaseFunctionsCallResult(
        value: 'ok',
        result: FirebaseFunctionsResult(errorCode: 'cancelled'),
      ),
    );
    expect(
      spans.findSpanByName('firebase_functions call')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutFirebaseFunctionsInstrumentationAsync(() async {
      await tracedFirebaseFunctions<String>(
        operation: 'useEmulator',
        invoke: () async => const FirebaseFunctionsCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('firebase_functions '), isEmpty);
  });
}
