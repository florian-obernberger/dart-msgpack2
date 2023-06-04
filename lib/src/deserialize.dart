part of msgpack;

/// This is a convenience function that will try to deserialize a list of bytes
/// in MsgPack format. If the provided input value is a [TypedData], then it
/// will generate a new Uint8List based on the buffer of the provided typeddata.
/// If the input is a List<int> then it will create a copy of the data rather
/// than reusing the underlying buffer.
dynamic deserialize(dynamic input) {
  Uint8List buffer;

  if (input is TypedData) {
    buffer = input.buffer.asUint8List(input.offsetInBytes);
  } else if (input is List<int>) {
    buffer = Uint8List.fromList(input);
  } else {
    throw ArgumentError.value(input, "input", "Not a byte source");
  }

  _uInt8Unpacker ??= Uint8Decoder(buffer);
  _uInt8Unpacker!.reset(buffer);
  return _uInt8Unpacker!.decode();
}

Uint8Decoder? _uInt8Unpacker;
