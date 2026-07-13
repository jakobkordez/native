// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

/// A single entry of a
/// [Clang JSON Compilation Database](https://clang.llvm.org/docs/JSONCompilationDatabase.html).
class CompileCommand {
  /// The working directory the [arguments] are run from.
  final Uri directory;

  /// The source file this compilation applies to.
  final Uri file;

  /// The compiler invocation, with the compiler executable as the first
  /// element.
  final List<String> arguments;

  /// The object file produced by this compilation.
  final Uri output;

  CompileCommand({
    required this.directory,
    required this.file,
    required this.arguments,
    required this.output,
  });

  Map<String, Object?> toJson() => {
    'directory': directory.toFilePath(),
    'file': file.toFilePath(),
    'arguments': arguments,
    'output': output.toFilePath(),
  };

  static CompileCommand fromJson(Map<String, Object?> json) => CompileCommand(
    directory: Uri.directory(json['directory']! as String),
    file: Uri.file(json['file']! as String),
    arguments: [
      for (final argument in json['arguments']! as List<Object?>)
        argument! as String,
    ],
    output: Uri.file(json['output']! as String),
  );

  /// The key used to deduplicate entries in [writeCompileCommands].
  String get _mergeKey => '${file.toFilePath()}\u0000${output.toFilePath()}';
}

/// Writes [commands] as a `compile_commands.json` file into
/// [outputDirectory].
///
/// If a `compile_commands.json` already exists in [outputDirectory] (for
/// example because multiple builders share the same output directory within
/// a single build hook), its entries are merged with [commands].
/// Entries are deduplicated by their source [CompileCommand.file] and
/// [CompileCommand.output], with [commands] taking precedence over the
/// entries already on disk.
Future<void> writeCompileCommands(
  Uri outputDirectory,
  List<CompileCommand> commands, {
  Logger? logger,
}) async {
  final file = File.fromUri(outputDirectory.resolve('compile_commands.json'));
  final merged = <String, CompileCommand>{};
  if (await file.exists()) {
    try {
      final decoded = jsonDecode(await file.readAsString()) as List<Object?>;
      for (final entry in decoded) {
        final command = CompileCommand.fromJson(
          entry! as Map<String, Object?>,
        );
        merged[command._mergeKey] = command;
      }
    } catch (e) {
      logger?.warning(
        'Failed to parse existing ${file.path}, it will be overwritten: $e',
      );
    }
  }
  for (final command in commands) {
    merged[command._mergeKey] = command;
  }
  const encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(
    encoder.convert([for (final command in merged.values) command.toJson()]),
  );
  logger?.info(
    'Wrote ${merged.length} compile command(s) to ${file.path}.',
  );
}
