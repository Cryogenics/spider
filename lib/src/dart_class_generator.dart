/*
 * Copyright © 2020 Birju Vachhani
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Author: Birju Vachhani
// Created Date: February 03, 2020

import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as path;
import 'package:watcher/watcher.dart';

import 'Formatter.dart';
import 'asset_group.dart';
import 'utils.dart';

/// Generates dart class code using given data
class DartClassGenerator {
  final AssetGroup group;
  bool _processing = false;
  static final formatter = DartFormatter();

  DartClassGenerator(this.group);

  /// generates dart class code and returns it as a single string
  void generate(bool watch, bool smartWatch) {
    if (watch) {
      verbose('path ${group.path} is requested to be watched');
      _watchDirectory();
    } else if (smartWatch) {
      verbose('path ${group.path} is requested to be watched smartly');
      _smartWatchDirectory();
    }
    process();
  }

  void process() {
    try {
      info('Processing path: ${group.path}');
      verbose('Creating file map from ${group.path}');
      var properties = createFileMap();
      verbose('File map created for path ${group.path}');
      var properties_strings = properties.keys.map<String>((name) {
        verbose('processing ${path.basename(properties[name])}');
        var str = group.useStatic ? '\tstatic ' : '\t';
        str += group.useConst ? 'const ' : '';
        str +=
            'String ${Formatter.formatName(name)} = \'${Formatter.formatPath(properties[name])}\';';
        return str;
      }).toList();
      verbose('Constructing dart class for ${group.className}');
      var dart_class = '''// Generated by spider on ${DateTime.now()}
    
class ${group.className} {
${properties_strings.join('\n')}
}''';
      verbose('Writing class ${group.className} to file ${group.fileName}');
      writeToFile(
          name: Formatter.formatFileName(group.fileName ?? group.className),
          path: group.package,
          content: formatter.format(dart_class));
      _processing = false;
      success(
          'Processed items for class ${group.className}: ${properties.length}');
    } on Error catch (e) {
      exit_with('Unable to process assets', e.stackTrace);
    }
  }

  /// Creates map from files list of a [dir] where key is the file name without
  /// extension and value is the path of the file
  Map<String, String> createFileMap() {
    try {
      var dir = group.path;
      var files = Directory(dir).listSync().where((file) {
        final valid = _isValidFile(file);
        verbose(
            'Asset - ${path.basename(file.path)} is ${valid ? 'selected' : 'not selected'}');
        return valid;
      }).toList();

      if (files.isEmpty) {
        exit_with('Directory $dir does not contain any assets!');
      }
      return {
        for (var file in files)
          path.basenameWithoutExtension(file.path): file.path
      };
    } on Error catch (e) {
      exit_with('Unable to create file map', e.stackTrace);
      return null;
    }
  }

  /// checks whether the file is valid file to be included or not
  /// 1. must be a file, not a directory
  /// 2. should be from one of the allowed types if specified any
  bool _isValidFile(File file) {
    return FileSystemEntity.isFileSync(file.path) &&
        (group.types.isEmpty ||
            group.types.contains(path.extension(file.path)));
  }

  /// Watches assets dir for file changes and rebuilds dart code
  void _watchDirectory() {
    info('Watching for changes in directory ${group.path}...');
    final watcher = DirectoryWatcher(group.path);

    watcher.events.listen((event) {
      verbose('something changed...');
      if (!_processing) {
        _processing = true;
        Future.delayed(Duration(seconds: 1), () => process());
      }
    });
  }

  /// Smartly watches assets dir for file changes and rebuilds dart code
  void _smartWatchDirectory() {
    info('Watching for changes in directory ${group.path}...');
    final watcher = DirectoryWatcher(group.path);
    watcher.events.listen((event) {
      verbose('something changed...');
      final filename = path.basename(event.path);
      if (event.type == ChangeType.MODIFY) {
        verbose('$filename is modified. '
            '${group.className} class will not be rebuilt');
        return;
      }
      if (!group.types.contains(path.extension(event.path))) {
        verbose('$filename does not have allowed extension for the group '
            '${group.path}. ${group.className} class will not be rebuilt');
        return;
      }
      if (!_processing) {
        _processing = true;
        Future.delayed(Duration(seconds: 1), () => process());
      }
    });
  }
}
