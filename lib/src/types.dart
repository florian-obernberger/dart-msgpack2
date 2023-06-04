part of msgpack;

class Float {
  final double value;

  Float(this.value);

  @override
  String toString() => value.toString();
}

abstract class MsgType {
  int get value;
}

enum IntType implements MsgType {
  uint8(0xcc),
  uint16(0xcd),
  uint32(0xce),
  uint64(0xcf),
  int8(0xd0),
  int16(0xd1),
  int32(0xd2),
  int64(0xd3);

  const IntType(this.value);
  final int value;

  factory IntType.fromInt(int value) {
    if (value == uint8.value) return uint8;
    if (value == uint16.value) return uint16;
    if (value == uint32.value) return uint32;
    if (value == uint64.value) return uint64;
    if (value == int8.value) return int8;
    if (value == int16.value) return int16;
    if (value == int32.value) return int32;
    if (value == int64.value) return int64;
    throw ArgumentError('Invalid IntType: 0x${value.toRadixString(16)}');
  }
}

enum FloatType implements MsgType {
  float32(0xca),
  float64(0xcb);

  const FloatType(this.value);
  final int value;

  factory FloatType.fromInt(int value) {
    if (value == float32.value) return float32;
    if (value == float64.value) return float64;

    throw ArgumentError('Invalid FloatType 0x${value.toRadixString(16)}');
  }
}

enum StringType implements MsgType {
  fixStr(0xa0),
  str8(0xd9),
  str16(0xda),
  str32(0xdb);

  const StringType(this.value);
  final int value;

  factory StringType.fromInt(int value) {
    if (value & 0xa0 == 0xa0) return fixStr;
    if (value == str8.value) return str8;
    if (value == str16.value) return str16;
    if (value == str32.value) return str32;
    throw ArgumentError('Invalid StringType 0x${value.toRadixString(16)}');
  }
}

enum BinaryType implements MsgType {
  bin8(0xc4),
  bin16(0xc5),
  bin32(0xc6);

  const BinaryType(this.value);
  final int value;

  factory BinaryType.fromInt(int value) {
    if (value == bin8.value) return bin8;
    if (value == bin16.value) return bin16;
    if (value == bin32.value) return bin32;

    throw ArgumentError('Invalid BinaryType 0x${value.toRadixString(16)}');
  }
}

enum ArrayType implements MsgType {
  fixArray(0x90),
  array16(0xdc),
  array32(0xdd);

  const ArrayType(this.value);
  final int value;

  factory ArrayType.fromInt(int value) {
    if (value & fixArray.value == fixArray.value) return fixArray;
    if (value == array16.value) return array16;
    if (value == array32.value) return array32;

    throw ArgumentError('Invalid ArrayType 0x${value.toRadixString(16)}');
  }
}

enum MapType implements MsgType {
  fixMap(0x80),
  map16(0xde),
  map32(0xdf);

  const MapType(this.value);
  final int value;

  factory MapType.fromInt(int value) {
    if (value & fixMap.value == fixMap.value) return fixMap;
    if (value == map16.value) return map16;
    if (value == map32.value) return map32;

    throw ArgumentError('Invalid MapType 0x${value.toRadixString(16)}');
  }
}

enum ExtType implements MsgType {
  fixExt1(0xd4),
  fixExt2(0xd5),
  fixExt4(0xd6),
  fixExt8(0xd7),
  fixExt16(0xd8),
  ext8(0xc7),
  ext16(0xc8),
  ext32(0xc9);

  const ExtType(this.value);
  final int value;

  factory ExtType.fromInt(int value) {
    if (value == fixExt1.value) return fixExt1;
    if (value == fixExt2.value) return fixExt2;
    if (value == fixExt4.value) return fixExt4;
    if (value == fixExt8.value) return fixExt8;
    if (value == fixExt16.value) return fixExt16;
    if (value == ext8.value) return ext8;
    if (value == ext16.value) return ext16;
    if (value == ext32.value) return ext32;

    throw ArgumentError('Invalid ExtType 0x${value.toRadixString(16)}');
  }
}
