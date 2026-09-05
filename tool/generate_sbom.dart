#!/usr/bin/env dart
import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';

/// Emits a CycloneDX 1.5 SBOM from pubspec.lock (CRA-aligned artifact).
void main(List<String> args) {
  final lockFile = File('pubspec.lock');
  if (!lockFile.existsSync()) {
    stderr.writeln('pubspec.lock missing');
    exitCode = 1;
    return;
  }
  final yaml = loadYaml(lockFile.readAsStringSync()) as YamlMap;
  final packages = yaml['packages'] as YamlMap? ?? YamlMap();
  final components = <Map<String, Object?>>[];
  packages.forEach((name, spec) {
    final map = spec as YamlMap;
    components.add({
      'type': 'library',
      'name': name.toString(),
      'version': map['version']?.toString(),
      'purl': 'pkg:pub/$name@${map['version']}',
      'properties': [
        {'name': 'cdx:dart:source', 'value': map['source']?.toString()},
      ],
    });
  });
  final sbom = {
    'bomFormat': 'CycloneDX',
    'specVersion': '1.5',
    'version': 1,
    'metadata': {
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'component': {'type': 'application', 'name': 'penumbra', 'version': '1.0.0'},
    },
    'components': components,
  };
  final out = File(args.isEmpty ? 'build/sbom.cdx.json' : args.first);
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(sbom));
  stdout.writeln('Wrote ${out.path} (${components.length} components)');
}
