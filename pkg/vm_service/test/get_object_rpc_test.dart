// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable-experiment=records --enable-experiment=class-modifiers --enable-experiment=sealed-class
// @dart=3.0
// ignore_for_file: experiment_not_enabled

library get_object_rpc_test;

import 'dart:collection';
import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/test_helper.dart';

abstract base mixin class _DummyAbstractBaseClass {
  void dummyFunction(int a, [bool b = false]);
}

base class _DummyClass extends _DummyAbstractBaseClass {
  // ignore: unused_field
  static var dummyVar = 11;
  final List<String> dummyList = List<String>.filled(20, '');
  // ignore: unused_field
  static var dummyVarWithInit = foo();
  late String dummyLateVarWithInit = 'bar';
  late String dummyLateVar;
  @override
  void dummyFunction(int a, [bool b = false]) {}
  void dummyGenericFunction<K, V>(K a, {required V param}) {}
  static List foo() => List<String>.filled(20, '');
}

base class _DummyGenericSubClass<T> extends _DummyClass {}

final class _DummyFinalClass extends _DummyClass {}

sealed class _DummySealedClass {}

interface class _DummyInterfaceClass extends _DummySealedClass {}

final mixin _DummyFinalMixin {
  void dummyMethod1() {}
}

sealed mixin _DummySealedMixin {
  void dummyMethod2() {}
}

final class _DummyClassWithMixins with _DummyFinalMixin, _DummySealedMixin {}

void warmup() {
  // Increase the usage count of these methods.
  _DummyClass().dummyFunction(0);
  _DummyClass().dummyGenericFunction<Object, dynamic>(0, param: 0);
}

@pragma("vm:entry-point")
getChattanooga() => "Chattanooga";

@pragma("vm:entry-point")
getList() => [3, 2, 1];

@pragma("vm:entry-point")
getMap() => {"x": 3, "y": 4, "z": 5};

@pragma("vm:entry-point")
getSet() => {6, 7, 8};

@pragma("vm:entry-point")
getUint8List() => Uint8List.fromList([3, 2, 1]);

@pragma("vm:entry-point")
getUint64List() => Uint64List.fromList([3, 2, 1]);

@pragma("vm:entry-point")
getRecord() => (1, x: 2, 3.0, y: 4.0);

@pragma("vm:entry-point")
getDummyClass() => _DummyClass();

@pragma("vm:entry-point")
getDummyFinalClass() => _DummyFinalClass();

@pragma("vm:entry-point")
getDummyGenericSubClass() => _DummyGenericSubClass<Object>();

@pragma("vm:entry-point")
getDummyInterfaceClass() => _DummyInterfaceClass();

@pragma("vm:entry-point")
getDummyClassWithMixins() => _DummyClassWithMixins();

var tests = <IsolateTest>[
  // null object.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'objects/null';
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kNull);
    expect(result.id, equals('objects/null'));
    expect(result.valueAsString, equals('null'));
    expect(result.classRef!.name, equals('Null'));
    expect(result.size, isPositive);
  },

  // bool object.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'objects/bool-true';
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kBool);
    expect(result.id, equals('objects/bool-true'));
    expect(result.valueAsString, equals('true'));
    expect(result.classRef!.name, equals('bool'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
  },

  // int object.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'objects/int-123';
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kInt);
    expect(result.json!['_vmType'], equals('Smi'));
    expect(result.id, equals('objects/int-123'));
    expect(result.valueAsString, equals('123'));
    expect(result.classRef!.name, equals('_Smi'));
    expect(result.size, isZero);
    expect(result.fields, isEmpty);
  },

  // A string
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart String.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getChattanooga', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kString);
    expect(result.json!['_vmType'], equals('String'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, equals('Chattanooga'));
    expect(result.classRef!.name, equals('_OneByteString'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(11));
    expect(result.offset, isNull);
    expect(result.count, isNull);
  },

  // String prefix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart String.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getChattanooga', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result =
        await service.getObject(isolateId, objectId, count: 4) as Instance;
    expect(result.kind, InstanceKind.kString);
    expect(result.json!['_vmType'], equals('String'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, equals('Chat'));
    expect(result.classRef!.name, equals('_OneByteString'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(11));
    expect(result.offset, isNull);
    expect(result.count, equals(4));
  },

  // String subrange.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart String.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getChattanooga', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 4, count: 6) as Instance;
    expect(result.kind, InstanceKind.kString);
    expect(result.json!['_vmType'], equals('String'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, equals('tanoog'));
    expect(result.classRef!.name, equals('_OneByteString'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(11));
    expect(result.offset, equals(4));
    expect(result.count, equals(6));
  },

  // String with wacky offset.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart String.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getChattanooga', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 100, count: 2) as Instance;
    expect(result.kind, InstanceKind.kString);
    expect(result.json!['_vmType'], equals('String'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, equals(''));
    expect(result.classRef!.name, equals('_OneByteString'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(11));
    expect(result.offset, equals(11));
    expect(result.count, equals(0));
  },

  // A built-in List.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getList', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kList);
    expect(result.json!['_vmType'], equals('GrowableObjectArray'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_GrowableList'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, isNull);
    final elements = result.elements!;
    expect(elements.length, equals(3));
    expect(elements[0] is InstanceRef, true);
    expect(elements[0].kind, InstanceKind.kInt);
    expect(elements[0].valueAsString, equals('3'));
    expect(elements[1] is InstanceRef, true);
    expect(elements[1].kind, InstanceKind.kInt);
    expect(elements[1].valueAsString, equals('2'));
    expect(elements[2] is InstanceRef, true);
    expect(elements[2].kind, InstanceKind.kInt);
    expect(elements[2].valueAsString, equals('1'));
  },

  // List prefix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getList', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result =
        await service.getObject(isolateId, objectId, count: 2) as Instance;
    expect(result.kind, InstanceKind.kList);
    expect(result.json!['_vmType'], equals('GrowableObjectArray'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_GrowableList'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, equals(2));
    final elements = result.elements!;
    expect(elements.length, equals(2));
    expect(elements[0] is InstanceRef, true);
    expect(elements[0].kind, InstanceKind.kInt);
    expect(elements[0].valueAsString, equals('3'));
    expect(elements[1] is InstanceRef, true);
    expect(elements[1].kind, InstanceKind.kInt);
    expect(elements[1].valueAsString, equals('2'));
  },

  // List suffix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getList', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 2, count: 2) as Instance;
    expect(result.kind, InstanceKind.kList);
    expect(result.json!['_vmType'], equals('GrowableObjectArray'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_GrowableList'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(2));
    expect(result.count, equals(1));
    final elements = result.elements!;
    expect(elements.length, equals(1));
    expect(elements[0] is InstanceRef, true);
    expect(elements[0].kind, InstanceKind.kInt);
    expect(elements[0].valueAsString, equals('1'));
  },

  // List with wacky offset.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getList', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 100, count: 2) as Instance;
    expect(result.kind, InstanceKind.kList);
    expect(result.json!['_vmType'], equals('GrowableObjectArray'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_GrowableList'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(3));
    expect(result.count, equals(0));
    expect(result.elements, isEmpty);
  },

  // A built-in Map.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart map.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getMap', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kMap);
    expect(result.json!['_vmType'], equals('Map'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Map'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, isNull);
    final associations = result.associations!;
    expect(associations.length, equals(3));
    expect(associations[0].key is InstanceRef, true);
    expect(associations[0].key.kind, InstanceKind.kString);
    expect(associations[0].key.valueAsString, equals('x'));
    expect(associations[0].value is InstanceRef, true);
    expect(associations[0].value.kind, InstanceKind.kInt);
    expect(associations[0].value.valueAsString, equals('3'));
    expect(associations[1].key is InstanceRef, true);
    expect(associations[1].key.kind, InstanceKind.kString);
    expect(associations[1].key.valueAsString, equals('y'));
    expect(associations[1].value is InstanceRef, true);
    expect(associations[1].value.kind, InstanceKind.kInt);
    expect(associations[1].value.valueAsString, equals('4'));
    expect(associations[2].key is InstanceRef, true);
    expect(associations[2].key.kind, InstanceKind.kString);
    expect(associations[2].key.valueAsString, equals('z'));
    expect(associations[2].value is InstanceRef, true);
    expect(associations[2].value.kind, InstanceKind.kInt);
    expect(associations[2].value.valueAsString, equals('5'));
  },

  // Map prefix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart map.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getMap', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result =
        await service.getObject(isolateId, objectId, count: 2) as Instance;
    expect(result.kind, InstanceKind.kMap);
    expect(result.json!['_vmType'], equals('Map'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Map'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, equals(2));
    final associations = result.associations!;
    expect(associations.length, equals(2));
    expect(associations[0].key is InstanceRef, true);
    expect(associations[0].key.kind, InstanceKind.kString);
    expect(associations[0].key.valueAsString, equals('x'));
    expect(associations[0].value is InstanceRef, true);
    expect(associations[0].value.kind, InstanceKind.kInt);
    expect(associations[0].value.valueAsString, equals('3'));
    expect(associations[1].key is InstanceRef, true);
    expect(associations[1].key.kind, InstanceKind.kString);
    expect(associations[1].key.valueAsString, equals('y'));
    expect(associations[1].value is InstanceRef, true);
    expect(associations[1].value.kind, InstanceKind.kInt);
    expect(associations[1].value.valueAsString, equals('4'));
  },

  // Map suffix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart map.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getMap', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 2, count: 2) as Instance;
    expect(result.kind, InstanceKind.kMap);
    expect(result.json!['_vmType'], equals('Map'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Map'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(2));
    expect(result.count, equals(1));
    final associations = result.associations!;
    expect(associations.length, equals(1));
    expect(associations[0].key is InstanceRef, true);
    expect(associations[0].key.kind, InstanceKind.kString);
    expect(associations[0].key.valueAsString, equals('z'));
    expect(associations[0].value is InstanceRef, true);
    expect(associations[0].value.kind, InstanceKind.kInt);
    expect(associations[0].value.valueAsString, equals('5'));
  },

  // Map with wacky offset
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart map.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getMap', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 100, count: 2) as Instance;
    expect(result.kind, InstanceKind.kMap);
    expect(result.json!['_vmType'], equals('Map'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Map'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(3));
    expect(result.count, equals(0));
    expect(result.associations, isEmpty);
  },

  // A built-in Set.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart set.
    final evalResult = await service
        .invoke(isolateId, isolate.rootLib!.id!, 'getSet', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kSet);
    expect(result.json!['_vmType'], equals('Set'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Set'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, isNull);
    final elements = result.elements!;
    expect(elements.length, equals(3));
    expect(elements[0] is InstanceRef, true);
    expect(elements[0].kind, InstanceKind.kInt);
    expect(elements[0].valueAsString, equals('6'));
    expect(elements[1] is InstanceRef, true);
    expect(elements[1].kind, InstanceKind.kInt);
    expect(elements[1].valueAsString, equals('7'));
    expect(elements[2] is InstanceRef, true);
    expect(elements[2].kind, InstanceKind.kInt);
    expect(elements[2].valueAsString, equals('8'));
  },

  // Uint8List.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint8List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kUint8List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint8List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, isNull);
    expect(result.bytes, equals('AwIB'));
    Uint8List bytes = base64Decode(result.bytes!);
    expect(bytes.buffer.asUint8List().toString(), equals('[3, 2, 1]'));
  },

  // Uint8List prefix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint8List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result =
        await service.getObject(isolateId, objectId, count: 2) as Instance;
    expect(result.kind, InstanceKind.kUint8List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint8List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, equals(2));
    expect(result.bytes, equals('AwI='));
    Uint8List bytes = base64Decode(result.bytes!);
    expect(bytes.buffer.asUint8List().toString(), equals('[3, 2]'));
  },

  // Uint8List suffix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint8List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 2, count: 2) as Instance;
    expect(result.kind, InstanceKind.kUint8List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint8List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(2));
    expect(result.count, equals(1));
    expect(result.bytes, equals('AQ=='));
    Uint8List bytes = base64Decode(result.bytes!);
    expect(bytes.buffer.asUint8List().toString(), equals('[1]'));
  },

  // Uint8List with wacky offset.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint8List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 100, count: 2) as Instance;
    expect(result.kind, InstanceKind.kUint8List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint8List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(3));
    expect(result.count, equals(0));
    expect(result.bytes, equals(''));
  },

  // Uint64List.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint64List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kUint64List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint64List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, isNull);
    expect(result.bytes, equals('AwAAAAAAAAACAAAAAAAAAAEAAAAAAAAA'));
    Uint8List bytes = base64Decode(result.bytes!);
    expect(bytes.buffer.asUint64List().toString(), equals('[3, 2, 1]'));
  },

  // Uint64List prefix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint64List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result =
        await service.getObject(isolateId, objectId, count: 2) as Instance;
    expect(result.kind, InstanceKind.kUint64List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint64List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, isNull);
    expect(result.count, equals(2));
    expect(result.bytes, equals('AwAAAAAAAAACAAAAAAAAAA=='));
    Uint8List bytes = base64Decode(result.bytes!);
    expect(bytes.buffer.asUint64List().toString(), equals('[3, 2]'));
  },

  // Uint64List suffix.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint64List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 2, count: 2) as Instance;
    expect(result.kind, InstanceKind.kUint64List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint64List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(2));
    expect(result.count, equals(1));
    expect(result.bytes, equals('AQAAAAAAAAA='));
    Uint8List bytes = base64Decode(result.bytes!);
    expect(bytes.buffer.asUint64List().toString(), equals('[1]'));
  },

  // Uint64List with wacky offset.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart list.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getUint64List', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId,
        offset: 100, count: 2) as Instance;
    expect(result.kind, InstanceKind.kUint64List);
    expect(result.json!['_vmType'], equals('TypedData'));
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, equals('_Uint64List'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.length, equals(3));
    expect(result.offset, equals(3));
    expect(result.count, equals(0));
    expect(result.bytes, equals(''));
  },

  // An expired object.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'objects/99999999';
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got object with bad ID');
    } on SentinelException catch (e) {
      expect(e.sentinel.kind, startsWith('Expired'));
      expect(e.sentinel.valueAsString, equals('<expired>'));
    }
  },

  // A record.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a Dart record.
    final evalResult =
        await service.invoke(isolateId, isolate.rootLib!.id!, 'getRecord', [])
            as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kRecord);
    expect(result.json!['_vmType'], 'Record');
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, '_Record');
    expect(result.size, isPositive);
    expect(result.length, 4);
    final fieldsMap = HashMap.fromEntries(
        result.fields!.map((f) => MapEntry(f.name, f.value)));
    expect(fieldsMap.keys.length, result.length);
    // [BoundField]s have fields with type [dynamic], and such fields have
    // broken [toJson()] in the past. So, we make the following call just to
    // ensure that it doesn't throw.
    result.fields!.first.toJson();
    expect(fieldsMap.containsKey(0), false);
    expect(fieldsMap.containsKey(1), true);
    expect(fieldsMap[1].valueAsString, '1');
    expect(fieldsMap.containsKey("x"), true);
    expect(fieldsMap["x"].valueAsString, '2');
    expect(fieldsMap.containsKey(2), true);
    expect(fieldsMap[2].valueAsString, '3.0');
    expect(fieldsMap.containsKey("y"), true);
    expect(fieldsMap["y"].valueAsString, '4.0');
  },

  // library.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final result =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    expect(result.id, startsWith('libraries/'));
    expect(result.name, equals('get_object_rpc_test'));
    expect(result.uri, startsWith('file:'));
    expect(result.uri, endsWith('get_object_rpc_test.dart'));
    expect(result.debuggable, equals(true));
    expect(result.dependencies!.length, isPositive);
    expect(result.dependencies![0].target, isNotNull);
    expect(result.scripts!.length, isPositive);
    expect(result.variables!.length, isPositive);
    expect(result.functions!.length, isPositive);
    expect(result.classes!.length, isPositive);
  },

  // invalid library.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'libraries/9999999';
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got library with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.message, "Invalid params");
    }
  },

  // script.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Get the library first.
    final libResult =
        await service.getObject(isolateId, isolate.rootLib!.id!) as Library;
    // Get the first script.
    final result =
        await service.getObject(isolateId, libResult.scripts![0].id!) as Script;
    expect(result.id, startsWith('libraries/'));
    expect(result.uri, startsWith('file:'));
    expect(result.uri, endsWith('get_object_rpc_test.dart'));
    expect(result.json!['_kind'], equals('kernel'));
    expect(result.library, isNotNull);
    expect(result.source, startsWith('// Copyright (c)'));
    final tokenPosTable = result.tokenPosTable!;
    expect(tokenPosTable.length, isPositive);
    expect(tokenPosTable[0], isA<List>());
    expect(tokenPosTable[0].length, isPositive);
    expect(tokenPosTable[0][0], isA<int>());
  },

  // invalid script.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'scripts/9999999';
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got script with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.message, "Invalid params");
    }
  },

  // A PlainInstance.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = evalResult.id!;
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kPlainInstance);
    expect(result.id, startsWith('objects/'));
    expect(result.valueAsString, isNull);
    expect(result.classRef!.name, '_DummyClass');
    expect(result.name, isNull);
    expect(result.typeParameters, isNull);
    expect(result.size, isPositive);
    expect(result.length, 3);
    final fieldsMap = HashMap.fromEntries(
        result.fields!.map((f) => MapEntry(f.name, f.value)));
    expect(fieldsMap.keys.length, result.length);
    expect(fieldsMap.containsKey('dummyList'), true);
    expect((fieldsMap['dummyList'] as InstanceRef).kind, InstanceKind.kList);
    expect(fieldsMap.containsKey('dummyLateVarWithInit'), true);
    expect((fieldsMap['dummyLateVarWithInit'] as Sentinel).kind,
        SentinelKind.kNotInitialized);
    expect(fieldsMap.containsKey('dummyLateVar'), true);
    expect((fieldsMap['dummyLateVar'] as Sentinel).kind,
        SentinelKind.kNotInitialized);
  },

  // An abstract base mixin class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyClass].
    final invokeResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final derivedClass =
        await service.getObject(isolateId, invokeResult.classRef!.id!) as Class;
    final baseClassRef = derivedClass.superClass!;
    final result =
        await service.getObject(isolateId, baseClassRef.id!) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, '_DummyAbstractBaseClass');
    expect(result.isAbstract, true);
    expect(result.isConst, false);
    expect(result.isSealed, false);
    expect(result.isMixinClass, true);
    expect(result.isBaseClass, true);
    expect(result.isInterfaceClass, false);
    expect(result.isFinal, false);
    expect(result.typeParameters, isNull);
    expect(result.library, isNotNull);
    expect(result.location, isNotNull);
    expect(result.error, isNull);
    expect(result.traceAllocations!, false);
    expect(result.superClass, isNotNull);
    expect(result.superType, isNotNull);
    expect(result.interfaces!.length, 0);
    expect(result.mixin, isNull);
    expect(result.fields!.length, 0);
    expect(result.functions!.length, 2);
    expect(result.subclasses!.length, 1);
    final json = result.json!;
    expect(json['_vmName'], startsWith('_DummyAbstractBaseClass@'));
    expect(json['_finalized'], true);
    expect(json['_implemented'], false);
    expect(json['_patch'], false);
  },

  // A class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyClass].
    final invokeResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final result =
        await service.getObject(isolateId, invokeResult.classRef!.id!) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, '_DummyClass');
    expect(result.isAbstract, false);
    expect(result.isConst, false);
    expect(result.isSealed, false);
    expect(result.isMixinClass, false);
    expect(result.isBaseClass, true);
    expect(result.isInterfaceClass, false);
    expect(result.isFinal, false);
    expect(result.typeParameters, isNull);
    expect(result.library, isNotNull);
    expect(result.location, isNotNull);
    expect(result.error, isNull);
    expect(result.traceAllocations!, false);
    expect(result.superClass, isNotNull);
    expect(result.superType, isNotNull);
    expect(result.interfaces!.length, 0);
    expect(result.mixin, isNull);
    expect(result.fields!.length, 5);
    expect(result.functions!.length, 10);
    expect(result.subclasses!.length, 2);
    final json = result.json!;
    expect(json['_vmName'], startsWith('_DummyClass@'));
    expect(json['_finalized'], true);
    expect(json['_implemented'], false);
    expect(json['_patch'], false);
  },

  // A generic class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyGenericSubClass].
    final invokeResult = await service.invoke(
            isolateId, isolate.rootLib!.id!, 'getDummyGenericSubClass', [])
        as InstanceRef;
    final result =
        await service.getObject(isolateId, invokeResult.classRef!.id!) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, '_DummyGenericSubClass');
    expect(result.isAbstract, false);
    expect(result.isConst, false);
    expect(result.isSealed, false);
    expect(result.isMixinClass, false);
    expect(result.isBaseClass, true);
    expect(result.isInterfaceClass, false);
    expect(result.isFinal, false);
    expect(result.typeParameters!.length, 1);
    expect(result.library, isNotNull);
    expect(result.location, isNotNull);
    expect(result.error, isNull);
    expect(result.traceAllocations!, false);
    expect(result.superClass, isNotNull);
    expect(result.superType, isNotNull);
    expect(result.interfaces!.length, 0);
    expect(result.mixin, isNull);
    expect(result.fields!.length, 0);
    expect(result.functions!.length, 1);
    expect(result.subclasses!.length, 0);
    final json = result.json!;
    expect(json['_vmName'], startsWith('_DummyGenericSubClass@'));
    expect(json['_finalized'], true);
    expect(json['_implemented'], false);
    expect(json['_patch'], false);
  },

  // A final class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyFinalClass].
    final invokeResult = await service
            .invoke(isolateId, isolate.rootLib!.id!, 'getDummyFinalClass', [])
        as InstanceRef;
    final result =
        await service.getObject(isolateId, invokeResult.classRef!.id!) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, '_DummyFinalClass');
    expect(result.isAbstract, false);
    expect(result.isConst, false);
    expect(result.isSealed, false);
    expect(result.isMixinClass, false);
    expect(result.isBaseClass, false);
    expect(result.isInterfaceClass, false);
    expect(result.isFinal, true);
    expect(result.typeParameters, isNull);
    expect(result.library, isNotNull);
    expect(result.location, isNotNull);
    expect(result.error, isNull);
    expect(result.traceAllocations!, false);
    expect(result.superClass, isNotNull);
    expect(result.superType, isNotNull);
    expect(result.interfaces!.length, 0);
    expect(result.mixin, isNull);
    expect(result.fields!.length, 0);
    expect(result.functions!.length, 1);
    expect(result.subclasses!.length, 0);
    final json = result.json!;
    expect(json['_vmName'], startsWith('_DummyFinalClass@'));
    expect(json['_finalized'], true);
    expect(json['_implemented'], false);
    expect(json['_patch'], false);
  },

  // A sealed class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyInterfaceClass].
    final invokeResult = await service.invoke(
            isolateId, isolate.rootLib!.id!, 'getDummyInterfaceClass', [])
        as InstanceRef;
    final derivedClass =
        await service.getObject(isolateId, invokeResult.classRef!.id!) as Class;
    final baseClassRef = derivedClass.superClass!;
    final result =
        await service.getObject(isolateId, baseClassRef.id!) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, '_DummySealedClass');
    expect(result.isAbstract, true);
    expect(result.isConst, false);
    expect(result.isSealed, true);
    expect(result.isMixinClass, false);
    expect(result.isBaseClass, false);
    expect(result.isInterfaceClass, false);
    expect(result.isFinal, false);
    expect(result.typeParameters, isNull);
    expect(result.library, isNotNull);
    expect(result.location, isNotNull);
    expect(result.error, isNull);
    expect(result.traceAllocations!, false);
    expect(result.superClass, isNotNull);
    expect(result.superType, isNotNull);
    expect(result.interfaces!.length, 0);
    expect(result.mixin, isNull);
    expect(result.fields!.length, 0);
    expect(result.functions!.length, 1);
    expect(result.subclasses!.length, 1);
    final json = result.json!;
    expect(json['_vmName'], startsWith('_DummySealedClass@'));
    expect(json['_finalized'], true);
    expect(json['_implemented'], false);
    expect(json['_patch'], false);
  },

  // An interface class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyInterfaceClass].
    final invokeResult = await service.invoke(
            isolateId, isolate.rootLib!.id!, 'getDummyInterfaceClass', [])
        as InstanceRef;
    final result =
        await service.getObject(isolateId, invokeResult.classRef!.id!) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, '_DummyInterfaceClass');
    expect(result.isAbstract, false);
    expect(result.isConst, false);
    expect(result.isSealed, false);
    expect(result.isMixinClass, false);
    expect(result.isBaseClass, false);
    expect(result.isInterfaceClass, true);
    expect(result.isFinal, false);
    expect(result.typeParameters, isNull);
    expect(result.library, isNotNull);
    expect(result.location, isNotNull);
    expect(result.error, isNull);
    expect(result.traceAllocations!, false);
    expect(result.superClass, isNotNull);
    expect(result.superType, isNotNull);
    expect(result.interfaces!.length, 0);
    expect(result.mixin, isNull);
    expect(result.fields!.length, 0);
    expect(result.functions!.length, 1);
    expect(result.subclasses!.length, 0);
    final json = result.json!;
    expect(json['_vmName'], startsWith('_DummyInterfaceClass@'));
    expect(json['_finalized'], true);
    expect(json['_implemented'], false);
    expect(json['_patch'], false);
  },

  // A class with final and sealed mixins.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Use invoke to get a reference to an instance of [_DummyClassWithMixins].
    final dummyClassInstanceRef = await service.invoke(
            isolateId, isolate.rootLib!.id!, 'getDummyClassWithMixins', [])
        as InstanceRef;
    final dummyClass = await service.getObject(
        isolateId, dummyClassInstanceRef.classRef!.id!) as Class;

    final dummyClassWithTwoMixinsApplied =
        await service.getObject(isolateId, dummyClass.superClass!.id!) as Class;
    expect(dummyClassWithTwoMixinsApplied.id, startsWith('classes/'));
    expect(dummyClassWithTwoMixinsApplied.name,
        '__DummyClassWithMixins&Object&_DummyFinalMixin&_DummySealedMixin');
    expect(dummyClassWithTwoMixinsApplied.isAbstract, true);
    expect(dummyClassWithTwoMixinsApplied.isConst, true);
    expect(dummyClassWithTwoMixinsApplied.isSealed, true);
    expect(dummyClassWithTwoMixinsApplied.isMixinClass, false);
    expect(dummyClassWithTwoMixinsApplied.isBaseClass, false);
    expect(dummyClassWithTwoMixinsApplied.isInterfaceClass, false);
    expect(dummyClassWithTwoMixinsApplied.isFinal, false);
    expect(dummyClassWithTwoMixinsApplied.typeParameters, isNull);
    expect(dummyClassWithTwoMixinsApplied.library, isNotNull);
    expect(dummyClassWithTwoMixinsApplied.location, isNotNull);
    expect(dummyClassWithTwoMixinsApplied.error, isNull);
    expect(dummyClassWithTwoMixinsApplied.traceAllocations!, false);
    expect(dummyClassWithTwoMixinsApplied.superType, isNotNull);
    expect(dummyClassWithTwoMixinsApplied.fields!.length, 0);
    expect(dummyClassWithTwoMixinsApplied.functions!.length, 2);
    expect(dummyClassWithTwoMixinsApplied.subclasses!.length, 1);
    final dummyClassWithTwoMixinsAppliedJson =
        dummyClassWithTwoMixinsApplied.json!;
    expect(
        dummyClassWithTwoMixinsAppliedJson['_vmName'],
        startsWith(
            '__DummyClassWithMixins&Object&_DummyFinalMixin&_DummySealedMixin@'));
    expect(dummyClassWithTwoMixinsAppliedJson['_finalized'], true);
    expect(dummyClassWithTwoMixinsAppliedJson['_implemented'], false);
    expect(dummyClassWithTwoMixinsAppliedJson['_patch'], false);

    expect(dummyClassWithTwoMixinsApplied.interfaces!.length, 1);
    expect(dummyClassWithTwoMixinsApplied.interfaces!.first,
        dummyClassWithTwoMixinsApplied.mixin!);
    final dummySealedMixinType = await service.getObject(
        isolateId, dummyClassWithTwoMixinsApplied.mixin!.id!) as Instance;
    expect(dummySealedMixinType.kind, InstanceKind.kType);
    expect(dummySealedMixinType.id, startsWith('classes/'));
    expect(dummySealedMixinType.name, '_DummySealedMixin');
    final dummySealedMixinClass = await service.getObject(
        isolateId, dummySealedMixinType.typeClass!.id!) as Class;
    expect(dummySealedMixinClass.id, startsWith('classes/'));
    expect(dummySealedMixinClass.name, '_DummySealedMixin');
    expect(dummySealedMixinClass.isAbstract, true);
    expect(dummySealedMixinClass.isConst, false);
    expect(dummySealedMixinClass.isSealed, true);
    expect(dummySealedMixinClass.isMixinClass, false);
    expect(dummySealedMixinClass.isBaseClass, false);
    expect(dummySealedMixinClass.isInterfaceClass, false);
    expect(dummySealedMixinClass.isFinal, false);
    expect(dummySealedMixinClass.typeParameters, isNull);
    expect(dummySealedMixinClass.library, isNotNull);
    expect(dummySealedMixinClass.location, isNotNull);
    expect(dummySealedMixinClass.error, isNull);
    expect(dummySealedMixinClass.traceAllocations!, false);
    expect(dummySealedMixinClass.superType, isNotNull);
    expect(dummySealedMixinClass.fields!.length, 0);
    expect(dummySealedMixinClass.functions!.length, 1);
    expect(dummySealedMixinClass.subclasses!.length, 0);
    expect(dummySealedMixinClass.interfaces!.length, 0);
    expect(dummySealedMixinClass.mixin, isNull);
    final dummySealedMixinClassJson = dummySealedMixinClass.json!;
    expect(
        dummySealedMixinClassJson['_vmName'], startsWith('_DummySealedMixin@'));
    expect(dummySealedMixinClassJson['_finalized'], true);
    expect(dummySealedMixinClassJson['_implemented'], true);
    expect(dummySealedMixinClassJson['_patch'], false);

    final dummyClassWithOneMixinApplied = await service.getObject(
        isolateId, dummyClassWithTwoMixinsApplied.superClass!.id!) as Class;
    expect(dummyClassWithOneMixinApplied.id, startsWith('classes/'));
    expect(dummyClassWithOneMixinApplied.name,
        '__DummyClassWithMixins&Object&_DummyFinalMixin');
    expect(dummyClassWithOneMixinApplied.isAbstract, true);
    expect(dummyClassWithOneMixinApplied.isConst, true);
    expect(dummyClassWithOneMixinApplied.isSealed, false);
    expect(dummyClassWithOneMixinApplied.isMixinClass, false);
    expect(dummyClassWithOneMixinApplied.isBaseClass, false);
    expect(dummyClassWithOneMixinApplied.isInterfaceClass, false);
    expect(dummyClassWithOneMixinApplied.isFinal, true);
    expect(dummyClassWithOneMixinApplied.typeParameters, isNull);
    expect(dummyClassWithOneMixinApplied.library, isNotNull);
    expect(dummyClassWithOneMixinApplied.location, isNotNull);
    expect(dummyClassWithOneMixinApplied.error, isNull);
    expect(dummyClassWithOneMixinApplied.traceAllocations!, false);
    expect(dummyClassWithOneMixinApplied.superType, isNotNull);
    expect(dummyClassWithOneMixinApplied.fields!.length, 0);
    expect(dummyClassWithOneMixinApplied.functions!.length, 2);
    expect(dummyClassWithOneMixinApplied.subclasses!.length, 1);
    final dummyClassWithOneMixinAppliedJson =
        dummyClassWithOneMixinApplied.json!;
    expect(dummyClassWithOneMixinAppliedJson['_vmName'],
        startsWith('__DummyClassWithMixins&Object&_DummyFinalMixin@'));
    expect(dummyClassWithOneMixinAppliedJson['_finalized'], true);
    expect(dummyClassWithOneMixinAppliedJson['_implemented'], false);
    expect(dummyClassWithOneMixinAppliedJson['_patch'], false);

    expect(dummyClassWithOneMixinApplied.interfaces!.length, 1);
    expect(dummyClassWithOneMixinApplied.interfaces!.first,
        dummyClassWithOneMixinApplied.mixin!);
    final dummyFinalMixinType = await service.getObject(
        isolateId, dummyClassWithOneMixinApplied.mixin!.id!) as Instance;
    expect(dummyFinalMixinType.kind, InstanceKind.kType);
    expect(dummyFinalMixinType.id, startsWith('classes/'));
    expect(dummyFinalMixinType.name, '_DummyFinalMixin');
    final dummyFinalMixinClass = await service.getObject(
        isolateId, dummyFinalMixinType.typeClass!.id!) as Class;
    expect(dummyFinalMixinClass.id, startsWith('classes/'));
    expect(dummyFinalMixinClass.name, '_DummyFinalMixin');
    expect(dummyFinalMixinClass.isAbstract, true);
    expect(dummyFinalMixinClass.isConst, false);
    expect(dummyFinalMixinClass.isSealed, false);
    expect(dummyFinalMixinClass.isMixinClass, false);
    expect(dummyFinalMixinClass.isBaseClass, false);
    expect(dummyFinalMixinClass.isInterfaceClass, false);
    expect(dummyFinalMixinClass.isFinal, true);
    expect(dummyFinalMixinClass.typeParameters, isNull);
    expect(dummyFinalMixinClass.library, isNotNull);
    expect(dummyFinalMixinClass.location, isNotNull);
    expect(dummyFinalMixinClass.error, isNull);
    expect(dummyFinalMixinClass.traceAllocations!, false);
    expect(dummyFinalMixinClass.superType, isNotNull);
    expect(dummyFinalMixinClass.fields!.length, 0);
    expect(dummyFinalMixinClass.functions!.length, 1);
    expect(dummyFinalMixinClass.subclasses!.length, 0);
    expect(dummyFinalMixinClass.interfaces!.length, 0);
    expect(dummyFinalMixinClass.mixin, isNull);
    final dummyFinalMixinClassJson = dummyFinalMixinClass.json!;
    expect(
        dummyFinalMixinClassJson['_vmName'], startsWith('_DummyFinalMixin@'));
    expect(dummyFinalMixinClassJson['_finalized'], true);
    expect(dummyFinalMixinClassJson['_implemented'], true);
    expect(dummyFinalMixinClassJson['_patch'], false);
  },

  // invalid class.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'scripts/9999999';
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got class with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.message, "Invalid params");
    }
  },

  // type.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/types/0";
    final result = await service.getObject(isolateId, objectId) as Instance;
    expect(result.kind, InstanceKind.kType);
    expect(result.id, equals(objectId));
    expect(result.classRef!.name, equals('_Type'));
    expect(result.size, isPositive);
    expect(result.fields, isEmpty);
    expect(result.typeClass!.name, equals('_DummyClass'));
  },

  // invalid type.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/types/9999999";
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got type with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.message, "Invalid params");
    }
  },

  // function.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/functions/dummyFunction";
    final result = await service.getObject(isolateId, objectId) as Func;
    expect(result.id, equals(objectId));
    expect(result.name, equals('dummyFunction'));
    expect(result.isStatic, equals(false));
    expect(result.isConst, equals(false));
    expect(result.implicit, equals(false));
    expect(result.isAbstract, equals(false));
    final signature = result.signature!;
    expect(signature.typeParameters, isNull);
    expect(signature.returnType, isNotNull);
    final parameters = signature.parameters!;
    expect(parameters.length, 3);
    expect(parameters[1].parameterType!.name, equals('int'));
    expect(parameters[1].fixed, isTrue);
    expect(parameters[2].parameterType!.name, equals('bool'));
    expect(parameters[2].fixed, isFalse);
    expect(result.location, isNotNull);
    expect(result.code, isNotNull);
    final json = result.json!;
    expect(json['_kind'], equals('RegularFunction'));
    expect(json['_optimizable'], equals(true));
    expect(json['_inlinable'], equals(true));
    expect(json['_usageCounter'], isPositive);
    expect(json['_optimizedCallSiteCount'], isZero);
    expect(json['_deoptimizations'], isZero);
  },

  // generic function.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId =
        "${evalResult.classRef!.id!}/functions/dummyGenericFunction";
    final result = await service.getObject(isolateId, objectId) as Func;
    expect(result.id, equals(objectId));
    expect(result.name, equals('dummyGenericFunction'));
    expect(result.isStatic, equals(false));
    expect(result.isConst, equals(false));
    expect(result.implicit, equals(false));
    expect(result.isAbstract, equals(false));
    final signature = result.signature!;
    expect(signature.typeParameters!.length, 2);
    expect(signature.returnType, isNotNull);
    final parameters = signature.parameters!;
    expect(parameters.length, 3);
    expect(parameters[1].parameterType!.name, isNotNull);
    expect(parameters[1].fixed, isTrue);
    expect(parameters[2].parameterType!.name, isNotNull);
    expect(parameters[2].name, 'param');
    expect(parameters[2].fixed, isFalse);
    expect(parameters[2].required, isTrue);
    expect(result.location, isNotNull);
    expect(result.code, isNotNull);
    final json = result.json!;
    expect(json['_kind'], equals('RegularFunction'));
    expect(json['_optimizable'], equals(true));
    expect(json['_inlinable'], equals(true));
    expect(json['_usageCounter'], isPositive);
    expect(json['_optimizedCallSiteCount'], isZero);
    expect(json['_deoptimizations'], isZero);
  },

  // abstract function.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = evalResult.classRef!.id!;
    final result = await service.getObject(isolateId, objectId) as Class;
    expect(result.id, startsWith('classes/'));
    expect(result.name, equals('_DummyClass'));
    expect(result.isAbstract, equals(false));

    // Get the super class.
    final superClass =
        await service.getObject(isolateId, result.superClass!.id!) as Class;
    expect(superClass.id, startsWith('classes/'));
    expect(superClass.name, equals('_DummyAbstractBaseClass'));
    expect(superClass.isAbstract, equals(true));

    // Find the abstract dummyFunction on the super class.
    final funcId =
        superClass.functions!.firstWhere((f) => f.name == 'dummyFunction').id!;
    final funcResult = await service.getObject(isolateId, funcId) as Func;

    expect(funcResult.id, equals(funcId));
    expect(funcResult.name, equals('dummyFunction'));
    expect(funcResult.isStatic, equals(false));
    expect(funcResult.isConst, equals(false));
    expect(funcResult.implicit, equals(false));
    expect(funcResult.isAbstract, equals(true));
    final signature = funcResult.signature!;
    expect(signature.typeParameters, isNull);
    expect(signature.returnType, isNotNull);
    final parameters = signature.parameters!;
    expect(parameters.length, 3);
    expect(parameters[1].parameterType!.name, equals('int'));
    expect(parameters[1].fixed, isTrue);
    expect(parameters[2].parameterType!.name, equals('bool'));
    expect(parameters[2].fixed, isFalse);
    expect(funcResult.location, isNotNull);
    expect(funcResult.code, isNotNull);
    final json = funcResult.json!;
    expect(json['_kind'], equals('RegularFunction'));
    expect(json['_optimizable'], equals(true));
    expect(json['_inlinable'], equals(true));
    expect(json['_usageCounter'], isZero);
    expect(json['_optimizedCallSiteCount'], isZero);
    expect(json['_deoptimizations'], isZero);
  },

  // invalid function.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/functions/invalid";
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got function with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.message, "Invalid params");
    }
  },

  // field
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/fields/dummyVar";
    final result = await service.getObject(isolateId, objectId) as Field;
    expect(result.id, equals(objectId));
    expect(result.name, equals('dummyVar'));
    expect(result.isConst, equals(false));
    expect(result.isStatic, equals(true));
    expect(result.isFinal, equals(false));
    expect(result.location, isNotNull);
    expect(result.staticValue.valueAsString, equals('11'));
    final json = result.json!;
    expect(json['_guardNullable'], isNotNull);
    expect(json['_guardClass'], isNotNull);
    expect(json['_guardLength'], isNotNull);
  },

  // static field initializer
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/field_inits/dummyVarWithInit";
    final result = await service.getObject(isolateId, objectId) as Func;
    expect(result.id, equals(objectId));
    expect(result.name, equals('dummyVarWithInit'));
    expect(result.isStatic, equals(true));
    expect(result.isConst, equals(false));
    expect(result.implicit, equals(false));
    expect(result.isAbstract, equals(false));
    final signature = result.signature!;
    expect(signature.typeParameters, isNull);
    expect(signature.returnType, isNotNull);
    expect(signature.parameters!.length, 0);
    expect(result.location, isNotNull);
    expect(result.code, isNotNull);
    final json = result.json!;
    expect(json['_kind'], equals('FieldInitializer'));
    expect(json['_optimizable'], equals(true));
    expect(json['_inlinable'], equals(false));
    expect(json['_usageCounter'], isZero);
    expect(json['_optimizedCallSiteCount'], isZero);
    expect(json['_deoptimizations'], isZero);
  },

  // late field initializer
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId =
        "${evalResult.classRef!.id!}/field_inits/dummyLateVarWithInit";
    final result = await service.getObject(isolateId, objectId) as Func;
    expect(result.id, equals(objectId));
    expect(result.name, equals('dummyLateVarWithInit'));
    expect(result.isStatic, equals(false));
    expect(result.isConst, equals(false));
    expect(result.implicit, equals(false));
    expect(result.isAbstract, equals(false));
    final signature = result.signature!;
    expect(signature.typeParameters, isNull);
    expect(signature.returnType, isNotNull);
    expect(signature.parameters!.length, 1);
    expect(result.location, isNotNull);
    expect(result.code, isNotNull);
    final json = result.json!;
    expect(json['_kind'], equals('FieldInitializer'));
    expect(json['_optimizable'], equals(true));
    expect(json['_inlinable'], equals(false));
    expect(json['_usageCounter'], isZero);
    expect(json['_optimizedCallSiteCount'], isZero);
    expect(json['_deoptimizations'], isZero);
  },

  // invalid late field initializer
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/field_inits/dummyLateVar";
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got field initializer with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
    }
  },

  // field with guards
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    final flagList = await service.getFlagList();
    if (!flagList.flags!.any((flag) =>
        flag.name == 'use_field_guards' && flag.valueAsString == 'true')) {
      // Skip the test if guards are not enabled.
      return;
    }

    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/fields/dummyList";
    final result = await service.getObject(isolateId, objectId) as Field;
    expect(result.id, equals(objectId));
    expect(result.name, equals('dummyList'));
    expect(result.isConst, equals(false));
    expect(result.isStatic, equals(false));
    expect(result.isFinal, equals(true));
    expect(result.location, isNotNull);
    final json = result.json!;
    expect(json['_guardNullable'], isNotNull);
    expect(json['_guardClass'], isNotNull);
    expect(json['_guardLength'], equals('20'));
  },

  // invalid field.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/fields/mythicalField";
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got field with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
    }
  },

  // code.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final isolate = await service.getIsolate(isolateId);
    // Call eval to get a class id.
    final evalResult = await service.invoke(
        isolateId, isolate.rootLib!.id!, 'getDummyClass', []) as InstanceRef;
    final objectId = "${evalResult.classRef!.id!}/functions/dummyFunction";
    final funcResult = await service.getObject(isolateId, objectId) as Func;
    final result =
        await service.getObject(isolateId, funcResult.code!.id!) as Code;
    expect(result.name, endsWith('_DummyClass.dummyFunction'));
    expect(result.kind, CodeKind.kDart);
    final json = result.json!;
    expect(json['_vmName'], endsWith('dummyFunction'));
    expect(json['_optimized'], isA<bool>());
    expect(json['function']['type'], equals('@Function'));
    expect(json['_startAddress'], isA<String>());
    expect(json['_endAddress'], isA<String>());
    expect(json['_objectPool'], isNotNull);
    expect(json['_disassembly'], isNotNull);
    expect(json['_descriptors'], isNotNull);
    expect(json['_inlinedFunctions'], anyOf([isNull, isA<List>()]));
    expect(json['_inlinedIntervals'], anyOf([isNull, isA<List>()]));
  },

  // invalid code.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectId = 'code/0';
    try {
      await service.getObject(isolateId, objectId);
      fail('successfully got code with bad ID');
    } on RPCError catch (e) {
      expect(e.code, equals(RPCError.kInvalidParams));
      expect(e.message, "Invalid params");
    }
  },
];

main([args = const <String>[]]) async =>
    runIsolateTests(args, tests, 'get_object_rpc_test.dart',
        testeeBefore: warmup);
