// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@OnPlatform({'mac-os': Timeout.factor(2), 'windows': Timeout.factor(10)})
library;

import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';
import 'package:test/test.dart';

import '../helpers.dart';

void main() {
  final targetOS = OS.current;
  final macOSConfig = targetOS == OS.macOS
      ? MacOSCodeConfig(targetVersion: defaultMacOSVersion)
      : null;

  Future<BuildInput> buildInput(Uri tempUri, Uri tempUri2, String name) async {
    final buildInputBuilder = BuildInputBuilder()
      ..setupShared(
        packageName: name,
        packageRoot: tempUri,
        outputFile: tempUri.resolve('output.json'),
        outputDirectoryShared: tempUri2,
      )
      ..config.setupBuild(linkingEnabled: false)
      ..addExtension(
        CodeAssetExtension(
          targetOS: targetOS,
          macOS: macOSConfig,
          targetArchitecture: Architecture.current,
          // Ignored by executables.
          linkModePreference: LinkModePreference.dynamic,
          cCompiler: cCompiler,
        ),
      );
    return buildInputBuilder.build();
  }

  Future<List<Map<String, Object?>>> readCompileCommands(
    BuildInput input,
  ) async {
    final file = File.fromUri(
      input.outputDirectory.resolve('compile_commands.json'),
    );
    final decoded = jsonDecode(await file.readAsString()) as List<Object?>;
    return [for (final entry in decoded) entry! as Map<String, Object?>];
  }

  test('CBuilder does not generate compile_commands.json by default', () async {
    final tempUri = await tempDirForTest();
    final tempUri2 = await tempDirForTest();
    final helloWorldCUri = packageUri.resolve(
      'test/cbuilder/testfiles/hello_world/src/hello_world.c',
    );
    const name = 'hello_world';

    final input = await buildInput(tempUri, tempUri2, name);
    final output = BuildOutputBuilder();

    final cbuilder = CBuilder.executable(
      name: name,
      sources: [helloWorldCUri.toFilePath()],
      buildMode: .release,
    );
    await cbuilder.run(input: input, output: output, logger: logger);

    final compileCommandsFile = File.fromUri(
      input.outputDirectory.resolve('compile_commands.json'),
    );
    expect(await compileCommandsFile.exists(), isFalse);
  });

  test('CBuilder generateCompileCommands for an executable', () async {
    final tempUri = await tempDirForTest();
    final tempUri2 = await tempDirForTest();
    final definesCUri = packageUri.resolve(
      'test/cbuilder/testfiles/defines/src/defines.c',
    );
    final forcedIncludeCUri = packageUri.resolve(
      'test/cbuilder/testfiles/defines/src/forcedInclude.c',
    );
    const name = 'defines';

    final input = await buildInput(tempUri, tempUri2, name);
    final output = BuildOutputBuilder();

    final defineFlag = switch (input.config.code.targetOS) {
      OS.windows => '/DFOO=USER_FLAG',
      _ => '-DFOO=USER_FLAG',
    };
    final compileFlag = switch (input.config.code.targetOS) {
      OS.windows => '/c',
      _ => '-c',
    };

    final cbuilder = CBuilder.executable(
      name: name,
      sources: [definesCUri.toFilePath()],
      forcedIncludes: [forcedIncludeCUri.toFilePath()],
      flags: [defineFlag],
      buildMode: .release,
      generateCompileCommands: true,
    );
    await cbuilder.run(input: input, output: output, logger: logger);

    final entries = await readCompileCommands(input);
    expect(entries, hasLength(1));
    final entry = entries.single;

    expect(entry['file'], definesCUri.toFilePath());
    expect(entry['directory'], input.outputDirectory.toFilePath());

    final arguments = (entry['arguments']! as List<Object?>).cast<String>();
    expect(arguments, contains(compileFlag));
    expect(arguments, contains(defineFlag));
    expect(
      arguments,
      anyElement(contains(forcedIncludeCUri.toFilePath())),
    );
    expect(arguments, contains(definesCUri.toFilePath()));

    final outputUri = Uri.file(entry['output']! as String);
    expect(
      outputUri.pathSegments.last,
      endsWith(Platform.isWindows ? '.obj' : '.o'),
    );
  });

  test('CBuilder generateCompileCommands for a dynamic library', () async {
    final tempUri = await tempDirForTest();
    final tempUri2 = await tempDirForTest();
    final addCUri = packageUri.resolve('test/cbuilder/testfiles/add/src/add.c');
    const name = 'add';

    final input = await buildInput(tempUri, tempUri2, name);
    final output = BuildOutputBuilder();

    final cbuilder = CBuilder.library(
      name: name,
      assetName: name,
      sources: [addCUri.toFilePath()],
      buildMode: .release,
      generateCompileCommands: true,
    );
    await cbuilder.run(input: input, output: output, logger: logger);

    final entries = await readCompileCommands(input);
    expect(entries, hasLength(1));
    expect(entries.single['file'], addCUri.toFilePath());
  });

  test(
    'CBuilder generateCompileCommands has one entry per source for a '
    'static library, matching the real object files',
    () async {
      final tempUri = await tempDirForTest();
      final tempUri2 = await tempDirForTest();
      final addCUri = packageUri.resolve(
        'test/cbuilder/testfiles/add/src/add.c',
      );
      final helloWorldCUri = packageUri.resolve(
        'test/cbuilder/testfiles/hello_world/src/hello_world.c',
      );
      const name = 'static_lib';

      final input = await buildInput(tempUri, tempUri2, name);
      final output = BuildOutputBuilder();

      final cbuilder = CBuilder.library(
        name: name,
        assetName: name,
        sources: [addCUri.toFilePath(), helloWorldCUri.toFilePath()],
        linkModePreference: LinkModePreference.static,
        buildMode: .release,
        generateCompileCommands: true,
      );
      await cbuilder.run(input: input, output: output, logger: logger);

      final entries = await readCompileCommands(input);
      expect(entries, hasLength(2));
      final files = entries.map((e) => e['file']).toSet();
      expect(
        files,
        {addCUri.toFilePath(), helloWorldCUri.toFilePath()},
      );

      // For a static library, each source is really compiled with `-c`/`/c`
      // into the object file listed as `output`, so that file must exist on
      // disk.
      for (final entry in entries) {
        final outputFile = File(entry['output']! as String);
        expect(await outputFile.exists(), isTrue);
      }
    },
  );

  test(
    'CBuilder generateCompileCommands merges with an existing '
    'compile_commands.json in the same output directory',
    () async {
      final tempUri = await tempDirForTest();
      final tempUri2 = await tempDirForTest();
      final addCUri = packageUri.resolve(
        'test/cbuilder/testfiles/add/src/add.c',
      );
      final helloWorldCUri = packageUri.resolve(
        'test/cbuilder/testfiles/hello_world/src/hello_world.c',
      );

      final input = await buildInput(tempUri, tempUri2, 'shared_output');
      final output = BuildOutputBuilder();

      final addBuilder = CBuilder.library(
        name: 'add',
        assetName: 'add',
        sources: [addCUri.toFilePath()],
        buildMode: .release,
        generateCompileCommands: true,
      );
      await addBuilder.run(input: input, output: output, logger: logger);

      final helloWorldBuilder = CBuilder.executable(
        name: 'hello_world',
        sources: [helloWorldCUri.toFilePath()],
        buildMode: .release,
        generateCompileCommands: true,
      );
      await helloWorldBuilder.run(
        input: input,
        output: output,
        logger: logger,
      );

      final entries = await readCompileCommands(input);
      final files = entries.map((e) => e['file']).toSet();
      expect(
        files,
        {addCUri.toFilePath(), helloWorldCUri.toFilePath()},
      );
    },
  );
}
