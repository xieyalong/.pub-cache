// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N slash_for_doc_comments`

/** lib */ //LINT
library test.rules.slash_for_doc_comments;

/** My class */ //LINT
class A {}

/// OK
class B {

  /** B */ //LINT
  B();

  /** x */ //LINT
  var x;

  /** y */ //LINT
  y() => null;
}

/** G */ //LINT
enum G {
  /** A */ //LINT
  A,
  B
}

/** f */ //LINT
typedef bool F();

/** z */ //LINT
z() => null;

/* meh */ //OK
class C {}

/** D */ //LINT
var D = String;

/** Z */ //LINT
class Z = B with C;
