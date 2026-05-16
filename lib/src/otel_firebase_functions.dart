// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_firebase_functions_suppression.dart';

const _tracerName = 'dartastic_otel_libs_firebase_functions';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class FirebaseFunctionsResult {
  const FirebaseFunctionsResult({
    this.region,
    this.functionName,
    this.callableUrl,
    this.requestPayloadSize,
    this.responsePayloadSize,
    this.timeoutSec,
    this.limitedUseAppCheckToken,
    this.appCheckTokenAttached,
    this.authTokenAttached,
    this.fromEmulator,
    this.errorCode,
    this.errorMessage,
  });

  /// Function region (`us-central1`, `europe-west1`, ...).
  final String? region;

  /// Function name as invoked.
  final String? functionName;

  /// Resolved callable URL.
  final String? callableUrl;

  final int? requestPayloadSize;
  final int? responsePayloadSize;

  /// Callable timeout in seconds.
  final int? timeoutSec;

  /// Limited-use App Check token (callable replay protection).
  final bool? limitedUseAppCheckToken;

  /// `X-Firebase-AppCheck` attached to the request.
  final bool? appCheckTokenAttached;

  /// `Authorization: Bearer <id-token>` attached.
  final bool? authTokenAttached;

  /// Request routed to local Functions emulator.
  final bool? fromEmulator;

  /// Callable HttpsError code: `cancelled`, `unknown`, `invalid-argument`,
  /// `deadline-exceeded`, `not-found`, `already-exists`,
  /// `permission-denied`, `unauthenticated`, `resource-exhausted`,
  /// `failed-precondition`, `aborted`, `out-of-range`, `unimplemented`,
  /// `internal`, `unavailable`, `data-loss`.
  final String? errorCode;
  final String? errorMessage;
}

class FirebaseFunctionsCallResult<T> {
  const FirebaseFunctionsCallResult({required this.value, this.result});
  final T value;
  final FirebaseFunctionsResult? result;
}

/// Wraps a callable Cloud Functions invocation in a CLIENT span.
/// [operation] is one of `call`, `stream`, `useEmulator`,
/// `setTimeout`, `setLimitedUseAppCheckTokens`.
Future<T> tracedFirebaseFunctions<T>({
  required String operation,
  required Future<FirebaseFunctionsCallResult<T>> Function() invoke,
}) async {
  if (firebaseFunctionsInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'firebase_functions',
    'rpc.method': operation,
    'firebase_functions.operation': operation,
  };

  final span = _tracer().startSpan(
    'firebase_functions $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.region != null) {
        extras.add(OTel.attributeString(
          'firebase_functions.region',
          res.region!,
        ));
      }
      if (res.functionName != null) {
        extras.add(OTel.attributeString(
          'firebase_functions.function.name',
          res.functionName!,
        ));
      }
      if (res.callableUrl != null) {
        extras.add(OTel.attributeString(
          'firebase_functions.callable.url',
          res.callableUrl!,
        ));
      }
      if (res.requestPayloadSize != null) {
        extras.add(OTel.attributeInt(
          'firebase_functions.request.payload_size',
          res.requestPayloadSize!,
        ));
      }
      if (res.responsePayloadSize != null) {
        extras.add(OTel.attributeInt(
          'firebase_functions.response.payload_size',
          res.responsePayloadSize!,
        ));
      }
      if (res.timeoutSec != null) {
        extras.add(OTel.attributeInt(
          'firebase_functions.timeout_sec',
          res.timeoutSec!,
        ));
      }
      if (res.limitedUseAppCheckToken != null) {
        extras.add(OTel.attributeBool(
          'firebase_functions.app_check.limited_use',
          res.limitedUseAppCheckToken!,
        ));
      }
      if (res.appCheckTokenAttached != null) {
        extras.add(OTel.attributeBool(
          'firebase_functions.app_check.attached',
          res.appCheckTokenAttached!,
        ));
      }
      if (res.authTokenAttached != null) {
        extras.add(OTel.attributeBool(
          'firebase_functions.auth_token.attached',
          res.authTokenAttached!,
        ));
      }
      if (res.fromEmulator != null) {
        extras.add(OTel.attributeBool(
          'firebase_functions.emulator',
          res.fromEmulator!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTel.attributeString(
          'firebase_functions.error.code',
          res.errorCode!,
        ));
        if (res.errorCode != 'cancelled') {
          span.setStatus(
            SpanStatusCode.Error,
            'Firebase Functions ${res.errorCode}',
          );
        }
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'firebase_functions.error.message',
          res.errorMessage!,
        ));
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
