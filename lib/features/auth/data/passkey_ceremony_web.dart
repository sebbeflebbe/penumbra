import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import '../domain/passkey_ceremony.dart';

PasskeyCeremony platformPasskeyCeremony() => const WebPasskeyCeremony();

class WebPasskeyCeremony implements PasskeyCeremony {
  const WebPasskeyCeremony();

  @override
  bool get isSupported {
    final host = web.window.location.hostname;
    final protocol = web.window.location.protocol;
    final secure =
        protocol == 'https:' || host == 'localhost' || host == '127.0.0.1';
    if (!secure) return false;
    return web.window.has('PublicKeyCredential');
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> publicKeyOptions) {
    return _run('create', publicKeyOptions);
  }

  @override
  Future<Map<String, dynamic>> get(Map<String, dynamic> publicKeyOptions) {
    return _run('get', publicKeyOptions);
  }

  Future<Map<String, dynamic>> _run(
    String method,
    Map<String, dynamic> publicKeyOptions,
  ) async {
    if (!isSupported) {
      throw UnsupportedError(kPasskeyUnavailableMessage);
    }
    final credentials = web.window.navigator.credentials as JSObject;
    final args = <String, Object?>{'publicKey': publicKeyOptions}.jsify();
    try {
      final promise = credentials.callMethod(method.toJS, args) as JSPromise;
      final credential = await promise.toDart;
      if (credential == null) throw const PasskeyCancelled();
      return _toJson(credential as JSObject);
    } catch (error) {
      if (error is PasskeyCancelled) rethrow;
      final text = error.toString().toLowerCase();
      if (text.contains('notallowed') || text.contains('abort')) {
        throw const PasskeyCancelled();
      }
      if (text.contains('notsupported') || text.contains('security')) {
        throw UnsupportedError(kPasskeyUnavailableMessage);
      }
      rethrow;
    }
  }

  Map<String, dynamic> _toJson(JSObject credential) {
    if (credential.has('toJSON')) {
      final raw = credential.callMethod('toJSON'.toJS);
      final dartified = (raw as JSAny).dartify();
      if (dartified is Map) {
        return Map<String, dynamic>.from(dartified);
      }
    }
    throw UnsupportedError(kPasskeyUnavailableMessage);
  }
}
