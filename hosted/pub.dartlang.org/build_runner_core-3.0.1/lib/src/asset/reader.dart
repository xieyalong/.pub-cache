// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:build/build.dart';
import 'package:crypto/crypto.dart';
import 'package:glob/glob.dart';
import '../asset_graph/graph.dart';
import '../asset_graph/node.dart';
import '../util/async.dart';

/// A [RunnerAssetReader] must implement [MultiPackageAssetReader].
abstract class RunnerAssetReader implements MultiPackageAssetReader {}

/// An [AssetReader] that can provide actual paths to assets on disk.
abstract class PathProvidingAssetReader implements AssetReader {
  String pathTo(AssetId id);
}

/// An [AssetReader] with a lifetime equivalent to that of a single step in a
/// build.
///
/// A step is a single Builder and primary input (or package for package
/// builders) combination.
///
/// Limits reads to the assets which are sources or were generated by previous
/// phases.
///
/// Tracks the assets and globs read during this step for input dependency
/// tracking.
class SingleStepReader implements AssetReader {
  final AssetGraph _assetGraph;
  final AssetReader _delegate;
  final int _phaseNumber;
  final String _primaryPackage;
  final FutureOr<bool> Function(
      AssetNode node, int phaseNum, String fromPackage) _isReadableNode;
  final FutureOr<GlobAssetNode> Function(
      Glob glob, String package, int phaseNum) _getGlobNode;

  /// The assets read during this step.
  final assetsRead = HashSet<AssetId>();

  SingleStepReader(this._delegate, this._assetGraph, this._phaseNumber,
      this._primaryPackage, this._isReadableNode,
      [this._getGlobNode]);

  /// Checks whether [id] can be read by this step - attempting to build the
  /// asset if necessary.
  FutureOr<bool> _isReadable(AssetId id) {
    assetsRead.add(id);
    var node = _assetGraph.get(id);
    if (node == null) {
      _assetGraph.add(SyntheticSourceAssetNode(id));
      return false;
    }
    return _isReadableNode(node, _phaseNumber, _primaryPackage);
  }

  @override
  Future<bool> canRead(AssetId id) {
    return toFuture(doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) return false;
      var node = _assetGraph.get(id);
      FutureOr<bool> _canRead() {
        if (node is GeneratedAssetNode) {
          // Short circut, we know this file exists because its readable and it was
          // output.
          return true;
        } else {
          return _delegate.canRead(id);
        }
      }

      return doAfter(_canRead(), (bool canRead) {
        if (!canRead) return false;
        return doAfter(_ensureDigest(id), (_) => true);
      });
    }));
  }

  @override
  Future<Digest> digest(AssetId id) {
    return toFuture(doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) {
        return Future.error(AssetNotFoundException(id));
      }
      return _ensureDigest(id);
    }));
  }

  @override
  Future<List<int>> readAsBytes(AssetId id) {
    return toFuture(doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) {
        return Future.error(AssetNotFoundException(id));
      }
      return doAfter(_ensureDigest(id), (_) => _delegate.readAsBytes(id));
    }));
  }

  @override
  Future<String> readAsString(AssetId id, {Encoding encoding = utf8}) {
    return toFuture(doAfter(_isReadable(id), (bool isReadable) {
      if (!isReadable) {
        return Future.error(AssetNotFoundException(id));
      }
      return doAfter(_ensureDigest(id),
          (_) => _delegate.readAsString(id, encoding: encoding));
    }));
  }

  @override
  Stream<AssetId> findAssets(Glob glob) {
    var streamCompleter = StreamCompleter<AssetId>();

    doAfter(_getGlobNode(glob, _primaryPackage, _phaseNumber),
        (GlobAssetNode globNode) {
      assetsRead.add(globNode.id);
      streamCompleter.setSourceStream(Stream.fromIterable(globNode.results));
    });
    return streamCompleter.stream;
  }

  FutureOr<Digest> _ensureDigest(AssetId id) {
    var node = _assetGraph.get(id);
    if (node?.lastKnownDigest != null) return node.lastKnownDigest;
    return _delegate.digest(id).then((digest) => node.lastKnownDigest = digest);
  }
}
