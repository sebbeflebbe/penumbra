import 'passkey_ceremony_stub.dart'
    if (dart.library.js_interop) 'passkey_ceremony_web.dart';

import '../domain/passkey_ceremony.dart';

PasskeyCeremony createPasskeyCeremony() => platformPasskeyCeremony();
