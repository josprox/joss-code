import 'dart:io';

import 'package:path/path.dart' as p;

class PathGuard {
  const PathGuard();

  String normalize(String rawPath) => p.normalize(p.absolute(rawPath));

  bool isWithin(String childPath, String parentPath) {
    final child = normalize(childPath);
    final parent = normalize(parentPath);
    return p.equals(child, parent) || p.isWithin(parent, child);
  }

  void assertWithinWorkspace(String path, String workspacePath) {
    if (!isWithin(path, workspacePath)) {
      throw FileSystemException('Path traversal blocked', path);
    }
  }

  String safeJoin(String workspacePath, String relativePath) {
    if (p.isAbsolute(relativePath)) {
      throw FileSystemException('Expected a relative path', relativePath);
    }
    final joined = normalize(p.join(workspacePath, relativePath));
    assertWithinWorkspace(joined, workspacePath);
    return joined;
  }
}
