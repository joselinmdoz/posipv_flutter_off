import 'dart:convert';
import 'dart:io';

import 'package:posipv/core/licensing/license_models.dart';
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  final Map<String, String> options = _parseArgs(args);
  if (options.containsKey('help') ||
      !options.containsKey('request-code') ||
      !options.containsKey('private-key')) {
    _printUsage();
    exitCode = 64;
    return;
  }

  final String requestCode = options['request-code']!.trim();
  final String privateKeyPath = options['private-key']!.trim();
  final String customer = (options['customer'] ?? '').trim();

  final File privateKeyFile = File(privateKeyPath);
  if (!privateKeyFile.existsSync()) {
    stderr.writeln('No existe la llave privada: $privateKeyPath');
    exitCode = 66;
    return;
  }

  final Map<String, Object?> request = decodeRequestCode(requestCode);
  final String deviceFingerprint = (request['device'] ?? '').toString().trim();
  if (deviceFingerprint.isEmpty) {
    stderr.writeln(
        'El codigo de solicitud no contiene la huella del dispositivo.');
    exitCode = 65;
    return;
  }

  final DateTime now = DateTime.now();
  late final DateTime expiresAt;
  try {
    expiresAt = _resolveExpiry(
      options: options,
      request: request,
      now: now,
    );
  } on FormatException {
    return;
  }
  final Map<String, Object?> payload = <String, Object?>{
    'ver': 1,
    'licenseId': const Uuid().v4(),
    'customer': customer.isEmpty ? null : customer,
    'device': deviceFingerprint,
    'iat': now.millisecondsSinceEpoch ~/ 1000,
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
  };
  final String payloadSegment = _base64UrlEncode(jsonEncode(payload));
  final String signatureSegment =
      await _signPayloadSegment(payloadSegment, privateKeyFile.path);

  stdout.writeln('POSIPV1.$payloadSegment.$signatureSegment');
}

DateTime _resolveExpiry({
  required Map<String, String> options,
  required Map<String, Object?> request,
  required DateTime now,
}) {
  final String rawExpiresAt = (options['expires-at'] ?? '').trim();
  if (rawExpiresAt.isNotEmpty) {
    final DateTime? parsed = DateTime.tryParse(rawExpiresAt);
    if (parsed == null) {
      stderr.writeln(
        'El valor de --expires-at no es valido. Usa el formato YYYY-MM-DD.',
      );
      exitCode = 64;
      throw const FormatException('Fecha de expiracion invalida.');
    }
    return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
  }

  final DateTime? requestedExpiry = readRequestedExpiryFromRequest(request);
  if (requestedExpiry != null) {
    return DateTime(
      requestedExpiry.year,
      requestedExpiry.month,
      requestedExpiry.day,
      23,
      59,
      59,
    );
  }

  final int validityDays = int.tryParse(options['days'] ?? '365') ?? 365;
  if (validityDays < 1) {
    stderr.writeln('El valor de --days debe ser mayor que 0.');
    exitCode = 64;
    throw const FormatException('Dias de vigencia invalidos.');
  }
  return now.add(Duration(days: validityDays));
}

Map<String, String> _parseArgs(List<String> args) {
  final Map<String, String> result = <String, String>{};
  for (int index = 0; index < args.length; index += 1) {
    final String arg = args[index];
    if (arg == '--help' || arg == '-h') {
      result['help'] = '1';
      continue;
    }
    if (!arg.startsWith('--')) {
      continue;
    }
    final String key = arg.substring(2);
    if (index + 1 >= args.length) {
      result[key] = '';
      continue;
    }
    result[key] = args[index + 1];
    index += 1;
  }
  return result;
}

Future<String> _signPayloadSegment(
  String payloadSegment,
  String privateKeyPath,
) async {
  final Directory tempDir =
      await Directory.systemTemp.createTemp('posipv-license-');
  try {
    final File payloadFile = File('${tempDir.path}/payload.txt');
    final File signatureFile = File('${tempDir.path}/signature.bin');
    await payloadFile.writeAsString(payloadSegment, flush: true);

    final ProcessResult result = await Process.run(
      'openssl',
      <String>[
        'dgst',
        '-sha256',
        '-sign',
        privateKeyPath,
        '-out',
        signatureFile.path,
        payloadFile.path,
      ],
    );
    if (result.exitCode != 0) {
      throw ProcessException(
        'openssl',
        <String>[
          'dgst',
          '-sha256',
          '-sign',
          privateKeyPath,
        ],
        result.stderr.toString(),
        result.exitCode,
      );
    }

    final List<int> signatureBytes = await signatureFile.readAsBytes();
    return _base64UrlEncodeBytes(signatureBytes);
  } finally {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  }
}

String _base64UrlEncode(String value) {
  return _base64UrlEncodeBytes(utf8.encode(value));
}

String _base64UrlEncodeBytes(List<int> bytes) {
  return base64Url.encode(bytes).replaceAll('=', '');
}

void _printUsage() {
  stdout.writeln(
    'Uso:\n'
    '  dart run tool/license/generate_license.dart '
    '--request-code "POSREQ1..." '
    '--private-key secrets/offline_license_private.pem '
    '[--expires-at 2027-12-31] '
    '[--days 365] '
    '[--customer "Cliente"]',
  );
}
