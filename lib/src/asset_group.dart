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
// Created Date: February 09, 2020

import 'package:spider/src/utils.dart';

import 'Formatter.dart';

/// Holds group information for assets sub directories
class AssetGroup {
  String className;
  String fileName;
  bool useUnderScores;
  bool useStatic;
  bool useConst;
  String prefix;
  List<String> types;
  List<String> paths;

  AssetGroup({
    this.className,
    this.fileName,
    this.paths,
    this.useUnderScores = false,
    this.useStatic = true,
    this.useConst = true,
    this.prefix = '',
    this.types = const <String>[],
  });

  AssetGroup.fromJson(Map<String, dynamic> json) {
    className = json['class_name'];
    fileName = Formatter.formatFileName(json['file_name'] ?? className);
    prefix = json['prefix'] ?? '';
    useUnderScores = false;
    useStatic = true;
    useConst = true;
    types = <String>[];
    json['types']?.forEach(
        (group) => types.add(formatExtension(group.toString()).toLowerCase()));
    paths = json['paths']?.cast<String>() ??
        (json['path'] != null ? <String>[json['path'].toString()] : null);
  }
}
