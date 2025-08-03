#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Build script to generate Dart classes from FlatBuffer schema files
///
/// This script:
/// 1. Compiles .fbs files to Dart using flatc compiler
/// 2. Generates strongly-typed Dart classes for schema interaction
/// 3. Places generated files in lib/src/schema/generated/
///
/// Usage: dart tool/build_schema.dart

void main() async {
  print('🔧 Building FlatBuffer schema for UserCanal Flutter SDK...\n');

  // Check if flatc is available
  if (!await _checkFlatcAvailable()) {
    print('❌ Error: flatc compiler not found!');
    print('Please install FlatBuffers compiler:');
    print('  macOS: brew install flatbuffers');
    print('  Linux: apt-get install flatbuffers-compiler');
    print('  Windows: Download from https://github.com/google/flatbuffers/releases');
    exit(1);
  }

  final schemaDir = Directory('schema');
  final outputDir = Directory('lib/src/schema/generated');

  // Create output directory
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  // Clean existing generated files
  await _cleanGeneratedFiles(outputDir);

  // Schema files to compile
  final schemaFiles = [
    'common.fbs',
    'event.fbs',
    'log.fbs',
  ];

  bool allSuccess = true;

  for (final schemaFile in schemaFiles) {
    final file = File('${schemaDir.path}/$schemaFile');

    if (!await file.exists()) {
      print('❌ Schema file not found: $schemaFile');
      allSuccess = false;
      continue;
    }

    print('📄 Compiling $schemaFile...');

    final success = await _compileFlatBufferSchema(
      schemaFile: file.path,
      outputDir: outputDir.path,
    );

    if (success) {
      print('✅ $schemaFile compiled successfully');
    } else {
      print('❌ Failed to compile $schemaFile');
      allSuccess = false;
    }
  }

  if (allSuccess) {
    print('\n🎉 All schema files compiled successfully!');
    print('📁 Generated files are in: ${outputDir.path}');

    // Generate index file
    await _generateIndexFile(outputDir);
    print('📄 Generated index.dart file');

    print('\n✨ Schema generation complete!');
  } else {
    print('\n❌ Some schema files failed to compile');
    exit(1);
  }
}

/// Check if flatc compiler is available
Future<bool> _checkFlatcAvailable() async {
  try {
    final result = await Process.run('flatc', ['--version']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

/// Clean existing generated files
Future<void> _cleanGeneratedFiles(Directory outputDir) async {
  if (!await outputDir.exists()) return;

  await for (final entity in outputDir.list()) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await entity.delete();
    }
  }
}

/// Compile a FlatBuffer schema file to Dart
Future<bool> _compileFlatBufferSchema({
  required String schemaFile,
  required String outputDir,
}) async {
  try {
    final result = await Process.run('flatc', [
      '--dart',           // Generate Dart code
      '--gen-object-api', // Generate object API
      '--reflect-types',  // Generate reflection info
      '--reflect-names',  // Generate reflection names
      '-o', outputDir,    // Output directory
      schemaFile,         // Input schema file
    ]);

    if (result.exitCode != 0) {
      print('flatc stderr: ${result.stderr}');
      print('flatc stdout: ${result.stdout}');
      return false;
    }

    return true;
  } catch (e) {
    print('Error running flatc: $e');
    return false;
  }
}

/// Generate index.dart file that exports all generated files
Future<void> _generateIndexFile(Directory outputDir) async {
  final indexFile = File('${outputDir.path}/index.dart');
  final exports = <String>[];

  // Find all generated .dart files
  await for (final entity in outputDir.list()) {
    if (entity is File &&
        entity.path.endsWith('.dart') &&
        !entity.path.endsWith('index.dart')) {
      final fileName = entity.path.split('/').last;
      exports.add("export '$fileName';");
    }
  }

  // Sort exports for consistency
  exports.sort();

  final content = '''
// Generated file - DO NOT EDIT
// This file exports all FlatBuffer generated classes
//
// Generated on: ${DateTime.now().toIso8601String()}

${exports.join('\n')}
''';

  await indexFile.writeAsString(content);
}
