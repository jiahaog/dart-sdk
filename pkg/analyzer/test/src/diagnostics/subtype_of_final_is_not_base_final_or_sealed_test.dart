// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfFinalIsNotBaseFinalOrSealedTest);
  });
}

@reflectiveTest
class SubtypeOfFinalIsNotBaseFinalOrSealedTest
    extends PubPackageResolutionTest {
  test_class_extends() async {
    await assertErrorsInCode(r'''
final class A {}
class B extends A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_class_implements() async {
    await assertErrorsInCode(r'''
final class A {}
class B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_class_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
class B extends A {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 33, 1),
    ]);
  }

  test_class_outside_on() async {
    newFile('$testPackageLibPath/a.dart', r'''
final mixin A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
mixin B on A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1),
    ]);
  }

  test_class_sealed_extends() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B extends A {}
class C extends B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        51,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_multiple() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B extends A {}
sealed class C extends B {}
class D extends C {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        79,
        1,
        text:
            "The type 'D' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 58, 1,
              text:
                  "The type 'C' is a subtype of 'A', and 'C' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_extends_outside() async {
    // No [SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED] reported outside of
    // library.
    newFile('$testPackageLibPath/a.dart', r'''
final class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B extends A {}
class C extends B {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 40, 1),
    ]);
  }

  test_class_sealed_extends_unordered() async {
    await assertErrorsInCode(r'''
class C extends B {}
sealed class B extends A {}
final class A {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        6,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 34, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_class_sealed_implements() async {
    await assertErrorsInCode(r'''
final class A {}
sealed class B implements A {}
class C implements B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        54,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_implements() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B implements A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_mixin_on() async {
    await assertErrorsInCode(r'''
final class A {}
mixin B on A {}
''', [
      error(CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
          23, 1,
          text:
              "The type 'B' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'."),
    ]);
  }

  test_mixin_sealed_implements() async {
    await assertErrorsInCode(r'''
final class A {}
sealed mixin B implements A {}
mixin C implements B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        54,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }

  test_mixin_sealed_on() async {
    await assertErrorsInCode(r'''
final class A {}
sealed mixin B on A {}
mixin C on B {}
''', [
      error(
        CompileTimeErrorCode.SUBTYPE_OF_FINAL_IS_NOT_BASE_FINAL_OR_SEALED,
        46,
        1,
        text:
            "The type 'C' must be 'base', 'final' or 'sealed' because the supertype 'A' is 'final'.",
        contextMessages: [
          ExpectedContextMessage(testFile.path, 30, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'B' is defined here.")
        ],
      ),
    ]);
  }
}
