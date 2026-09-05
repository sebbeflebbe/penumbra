import 'package:flutter_test/flutter_test.dart';
import 'package:penumbra/core/config.dart';

void main() {
  test('neither env var uses the in-memory studio', () {
    expect(
      resolveStudioMode(supabaseUrl: '', supabaseAnonKey: ''),
      StudioMode.memory,
    );
    expect(
      resolveStudioMode(supabaseUrl: '  ', supabaseAnonKey: ''),
      StudioMode.memory,
    );
  });

  test('both env vars select Supabase', () {
    expect(
      resolveStudioMode(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
      ),
      StudioMode.supabase,
    );
  });

  test('half-set config fails closed', () {
    expect(
      () => resolveStudioMode(
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: '',
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => resolveStudioMode(supabaseUrl: '', supabaseAnonKey: 'anon-key'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
