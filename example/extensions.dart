import 'package:msgpack/msgpack.dart';

class Example implements ExtensionFormat {
  final typeId = 1;

  String data;
  int number;

  Example(this.data, this.number);

  void encode(Uint8Encoder encoder) {
    encoder.encodeString(data);
    encoder.encodeInt(number);
  }

  Example decode(Uint8Decoder decoder) {
    // Must unpack in same order as packing.
    var dt = decoder.decode();
    var nm = decoder.decode();
    return Example(dt, nm);
  }

  String toString() => '#$number - $data';
}

class OtherExample {
  String data;
  int number;

  OtherExample(this.data, this.number);
  String toString() => '#$number - $data';
}

class ExampleBuilder implements ExtensionFormat {
  final typeId = 2;
  final OtherExample example;

  ExampleBuilder(this.example);

  void encode(Uint8Encoder encoder) {
    encoder.encodeString(example.data);
    encoder.encodeInt(example.number);
  }

  OtherExample decode(Uint8Decoder decoder) {
    var data = decoder.decode();
    var number = decoder.decode();

    return OtherExample(data, number);
  }

  String toString() => 'You Should never see this';
}

void main() {
  var example1 = Example("The first example", 10000);
  registerExtension(example1);
  var encoded = serialize(example1);
  print('Encoded data: $encoded');
  var decoded = deserialize(encoded);
  print('Decoded data: $decoded');

  var example2 = OtherExample('Second example', 2);
  // We don't need to supply example data in the builder when registering.
  var builder = ExampleBuilder(null);
  registerExtension(builder);
  // We must wrap the type in the builder when packing.
  encoded = serialize(ExampleBuilder(example2));
  print('Encoded data: $encoded');
  decoded = deserialize(encoded);
  print('Decoded data: $decoded');
}
