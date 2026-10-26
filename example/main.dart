// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_firebase_functions/otel_firebase_functions.dart';

/// Traces Firebase Functions calls with OpenTelemetry.
///
/// `otel_firebase_functions` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Firebase Functions call in
/// [tracedFirebaseFunctions]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'firebase-functions-example');

  // Wraps a callable Cloud Functions invocation in a CLIENT span.
  final firebaseFunctionsId = await tracedFirebaseFunctions<String>(
    operation: 'create',
    invoke: () async {
      // Make the Firebase Functions call here, then report what it returned.
      const id = 'firebase_functions_8f3a2c';
      return const FirebaseFunctionsCallResult(
          value: id,
          result: FirebaseFunctionsResult(
              region: 'us-central1',
              functionName: 'example',
              callableUrl: 'https://api.example.com/v1/resource',
              requestPayloadSize: 512,
              responsePayloadSize: 512,
              timeoutSec: 1,
              limitedUseAppCheckToken: true,
              appCheckTokenAttached: true,
              authTokenAttached: true,
              fromEmulator: true,
              errorCode: 'cancelled',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedFirebaseFunctions create returned $firebaseFunctionsId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutFirebaseFunctionsInstrumentationAsync.
  await runWithoutFirebaseFunctionsInstrumentationAsync(
    () => tracedFirebaseFunctions<String>(
      operation: 'create',
      invoke: () async {
        const id = 'firebase_functions_8f3a2c';
        return const FirebaseFunctionsCallResult(
            value: id,
            result: FirebaseFunctionsResult(
                region: 'us-central1',
                functionName: 'example',
                callableUrl: 'https://api.example.com/v1/resource',
                requestPayloadSize: 512,
                responsePayloadSize: 512,
                timeoutSec: 1,
                limitedUseAppCheckToken: true,
                appCheckTokenAttached: true,
                authTokenAttached: true,
                fromEmulator: true,
                errorCode: 'cancelled',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
