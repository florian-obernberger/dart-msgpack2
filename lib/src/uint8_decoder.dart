part of msgpack;

/// This class manages the backing buffer and ByteData of the provided Uint8List
/// and provides methods to unpack the Message Pack data.
class Uint8Decoder {
  Uint8List list;
  ByteData _bd;
  int _offset = 0;

  /// This creates a new instance of the deserializer initialized with the
  /// specified [Uint8List].
  Uint8Decoder(this.list)
      : _bd = ByteData.view(
          list.buffer,
          list.offsetInBytes,
        );

  /// This method will replace the existing buffer and reinitialize the
  /// deserializer with the provided [Uint8List].
  void reset(Uint8List buff) {
    list = buff;
    _bd = ByteData.view(list.buffer, list.offsetInBytes);
    _offset = 0;
  }

  /// decode will read the next byte in the data list and attempt to deserialize
  /// and return the corresponding value. This method may throw an
  /// [ArgumentError] if it is unable to recognize the type to be deserialized.
  /// It may also throw a [StateError] if the MsgPack extension type is unknown.
  /// This is the main method used to deserialize data (as it automatically
  /// detects the correct type).
  dynamic decode() {
    int type = list[_offset++];

    // Negative "fixInt" (last set of data but looks cleaner to check it first)
    if (type >= 0xe0) return type - 0x100;

    // Positive FixInt
    if (type <= 0x7f) return type;
    // Fix Map
    if (type <= 0x8f) {
      _offset -= 1; // Step back to get the offset correct
      return decodeMap(MapType.fromInt(type));
    }
    // Fix List (array)
    if (type <= 0x9f) {
      _offset -= 1;
      return decodeArray(ArrayType.fromInt(type));
    }
    // Fix String
    if (type <= 0xbf) {
      _offset -= 1;
      return decodeString(StringType.fromInt(type));
    }
    // Fix Null
    if (type == 0xc0) return null;
    // c1 is unused
    // false and true
    if (type == 0xc2) return false;
    if (type == 0xc3) return true;

    // Binary data
    if (type <= 0xc6) return decodeBinary(BinaryType.fromInt(type));
    if (type <= 0xc9) return decodeExtension(ExtType.fromInt(type));
    if (type == 0xca) return decodeFloat();
    if (type == 0xcb) return decodeDouble();
    if (type <= 0xd3) return decodeInt(IntType.fromInt(type));
    if (type <= 0xd8) return decodeExtension(ExtType.fromInt(type));
    if (type <= 0xdb) return decodeString(StringType.fromInt(type));
    if (type <= 0xdd) return decodeArray(ArrayType.fromInt(type));
    if (type <= 0xdf) return decodeMap(MapType.fromInt(type));

    throw ArgumentError('Unknown MsgPack type 0x${type.toRadixString(16)}');
  }

  /// This method will unpack a [BinaryType] from the MsgPack format. The
  /// initial type byte must already be read and the offset at the next byte.
  /// It returns the binary data as a ByteData view.
  ByteData decodeBinary(BinaryType type) {
    int count;

    switch (type) {
      case BinaryType.bin8:
        count = list[_offset++];
        break;
      case BinaryType.bin16:
        count = _readBits(list, 16, _offset);
        _offset += 2;
        break;
      case BinaryType.bin32:
        count = _readBits(list, 32, _offset);
        _offset += 4;
        break;
    }

    var result = ByteData.view(list.buffer, _offset, count);
    _offset += count;
    return result;
  }

  /// This method will unpack a Float32 value. The initial type byte must
  /// already be read and the offset at the next byte.
  double decodeFloat() {
    var value = _bd.getFloat32(_offset);
    _offset += 4;
    return value;
  }

  /// This method will unpack a Float64 (double) value. The initial type byte
  /// must already be read and the offset at the next byte.
  double decodeDouble() {
    var value = _bd.getFloat64(_offset);
    _offset += 8;
    return value;
  }

  /// This  will unpack an integer value of size specified by [IntType]. The
  /// initial type byte must already be read and the offset at the next byte.
  int decodeInt(IntType type) {
    int value;
    switch (type) {
      case IntType.uint8:
        value = list[_offset++];
        break;
      case IntType.uint16:
        value = _readBits(list, 16, _offset);
        _offset += 2;
        break;
      case IntType.uint32:
        value = _readBits(list, 32, _offset);
        _offset += 4;
        break;
      case IntType.uint64:
        value = _readBits(list, 64, _offset);
        _offset += 8;
        break;
      case IntType.int8:
        value = list[_offset++];
        value -= 0x100;
        break;
      case IntType.int16:
        value = _readBits(list, 16, _offset);
        value -= 0x10000;
        _offset += 2;
        break;
      case IntType.int32:
        value = _readBits(list, 32, _offset);
        value -= 0x100000000;
        _offset += 4;
        break;
      case IntType.int64:
        value = _bd.getInt64(_offset);
        _offset += 8;
        break;
    }

    return value;
  }

  /// This method will attempt to unpack an Extension type specified by [ExtType]
  /// It will read the appropriate size and type id, however the
  /// initial type byte must already be read and the offset at the next byte.
  dynamic decodeExtension(ExtType type) {
    ExtensionFormat? builder;
    int length;
    if (type.value <= ExtType.ext32.value) {
      switch (type) {
        case ExtType.ext8:
          length = _readBits(list, 8, _offset);
          _offset += 1;
          break;
        case ExtType.ext16:
          length = _readBits(list, 16, _offset);
          _offset += 2;
          break;
        case ExtType.ext32:
          length = _readBits(list, 32, _offset);
          _offset += 4;
          break;
        default:
          throw ArgumentError.value(type, "extType");
      }

      var typeId = _bd.getInt8(_offset++);
      builder = _extCache[typeId];
      if (builder == null) {
        throw StateError('No registered builder for type id: $typeId');
      }
    } else {
      var typeId = _bd.getInt8(_offset++);
      builder = _extCache[typeId];
      if (builder == null) {
        throw StateError('No registered builder for type id: $typeId');
      }

      switch (type) {
        case ExtType.fixExt1:
          length = 1;
          break;
        case ExtType.fixExt2:
          length = 2;
          break;
        case ExtType.fixExt4:
          length = 4;
          break;
        case ExtType.fixExt8:
          length = 8;
          break;
        case ExtType.fixExt16:
          length = 16;
          break;
        default:
          throw ArgumentError.value(type, "extType");
      }
    }
    var unpacker = Uint8Decoder(
        list.buffer.asUint8List(list.offsetInBytes + _offset, length));
    var value = builder.decode(unpacker);
    _offset += length;
    return value;
  }

  /// This  will unpack an String value of specified by [StringType]. The size
  /// of the String will be read by the method. However the
  /// initial type byte must already be read and the offset at the next byte.
  String decodeString(StringType type) {
    int count = 0;

    switch (type) {
      case StringType.fixStr:
        count = list[_offset++] ^ type.value;
        break;
      case StringType.str8:
        count = list[_offset++];
        break;
      case StringType.str16:
        count = _readBits(list, 16, _offset);
        _offset += 2;
        break;
      case StringType.str32:
        count = _readBits(list, 32, _offset);
        _offset += 4;
        break;
    }

    String value = const Utf8Decoder()
        .convert(_bd.buffer.asUint8List(list.offsetInBytes + _offset, count));
    _offset += count;
    return value;
  }

  /// This  will unpack an Array value of specified by [ArrayType]. The size
  /// of the Array will be read by the method. However the
  /// initial type byte must already be read and the offset at the next byte.
  List decodeArray(ArrayType type) {
    int count;

    switch (type) {
      case ArrayType.fixArray:
        count = list[_offset++] ^ type.value;
        break;
      case ArrayType.array16:
        count = _readBits(list, 16, _offset);
        _offset += 2;
        break;
      case ArrayType.array32:
        count = _readBits(list, 32, _offset);
        _offset += 4;
        break;
    }

    return List.generate(count, (_) => decode());
  }

  /// This  will unpack an Map value of specified by [MapType]. The size
  /// of the Map will be read by the method. However the
  /// initial type byte must already be read and the offset at the next byte.
  Map decodeMap(MapType type) {
    int count;

    switch (type) {
      case MapType.fixMap:
        count = list[_offset++] ^ type.value;
        break;
      case MapType.map16:
        count = _readBits(list, 16, _offset);
        _offset += 2;
        break;
      case MapType.map32:
        count = _readBits(list, 32, _offset);
        _offset += 4;
        break;
    }

    Map value = Map();
    for (var i = 0; i < count; i++) {
      value[decode()] = decode();
    }

    return value;
  }

  static int _readBits(Uint8List list, int bits, int ind) {
    var value = 0;
    for (bits -= 8; bits > 0; bits -= 8) {
      value |= list[ind++] << bits;
    }

    value |= list[ind++];

    return value;
  }
}
