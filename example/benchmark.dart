import "dart:convert";

import "package:msgpack/msgpack.dart";
import "dart:io";

const int TIMES = 10000;

gcd(num a, num b) => b != 0 ? gcd(b, a % b) : a;

class Fraction {
  final num numerator;
  final num denominator;

  Fraction(this.numerator, this.denominator);

  Fraction reduce() {
    var cd = gcd(numerator, denominator);
    return new Fraction(numerator / cd, denominator / cd);
  }

  Fraction cross(Fraction other) => new Fraction(
      other.denominator * numerator, other.numerator * denominator);

  @override
  String toString() => "${numerator}/${denominator}";

  String toRatioString() => "${numerator}:${denominator}";
}

main(List<String> args) async {
  print("Warming Up...");
  for (var i = 0; i < TIMES; i++) {
    var jsonStr = json.encode({"hello": "world"});
    var newPacked = serialize({"hello": "world"});

    json.decode(jsonStr);
    deserialize(newPacked);
  }

  if (args.contains("--savings")) {
    var numbers = [];
    for (var i = 1; i <= 100000; i++) {
      numbers.add(i);
    }

    var jsonBytes = utf8.encode(json.encode(numbers)).length;
    var msgpackBytes = serialize(numbers).length;
    var fract = new Fraction(jsonBytes, msgpackBytes);
    fract = fract.reduce();
    print("MsgPack: ${msgpackBytes} bytes");
    print("JSON: ${jsonBytes} bytes");
    print("Ratio: ${fract.toRatioString()}");
    exit(0);
  }

  var objects = {
    "One": 1,
    "Five Hundred Thousand": 500000,
    "List of Small Integers": [1, 2, 3],
    "Simple Map": {"hello": "world"},
    "5.02817472928": 5.02817472928,
    "Multiple Type Map": {
      "String": "Hello World",
      "Integer": 1,
      "Double": 2.0154,
      "Array": const [1, 2, 3, "Hello"]
    },
    "Medium Data": {
      "/downstream/wemo/CoffeeMaker-1_0-221421S0000731/Brew_Age": [
        [1440366101049, -123881],
        [1440366102047, -123882],
        [1440366103049, -123883],
        [1440366104046, -123884],
        [1440366105062, -123885],
        [1440366106050, -123886],
        [1440366107046, -123887],
        [1440366108045, -123888],
        [1440366109036, -123889],
        [1440366110048, -123890],
        [1440366111047, -123891],
        [1440366112037, -123892],
        [1440366113048, -123893],
        [1440366114048, -123894],
        [1440366115046, -123895],
        [1440366116044, -123896],
        [1440366117045, -123897],
        [1440366118049, -123898],
        [1440366119046, -123899],
        [1440366120042, -123900],
        [1440366121047, -123901],
        [1440366122048, -123902],
        [1440366123046, -123903],
        [1440366124055, -123904],
        [1440366126059, -123906],
        [1440366127054, -123907],
        [1440366128047, -123908],
        [1440366129051, -123909],
        [1440366130051, -123910],
        [1440366131048, -123911],
        [1440366132050, -123912],
        [1440366133032, -123913],
        [1440366134045, -123914],
        [1440366135050, -123915],
        [1440366136049, -123916]
      ]
    }
  };

  bool markdown = false;
  if (args.contains("-m")) markdown = true;

  if (args.contains("-u")) {
    if (markdown) {
      print("Deserialize\n===");
    } else {
      print("=== Deserialize ===");
    }

    for (var key in objects.keys) {
      testObjectDecode(key, objects[key], markdown);
    }
  } else if (args.contains("-a")) {
    if (markdown) {
      print("Serialize\n===");
    } else {
      print("=== Serialize ===");
    }
    for (var key in objects.keys) {
      testObjectEncode(key, objects[key], markdown);
    }
    if (markdown) {
      print("Deserialize\n===");
    } else {
      print("=== Deserialize ===");
    }
    for (var key in objects.keys) {
      testObjectDecode(key, objects[key], markdown);
    }
  } else {
    if (markdown) {
      print("Serialize\n===");
    } else {
      print("=== Serialize ===");
    }

    for (var key in objects.keys) {
      testObjectEncode(key, objects[key], markdown);
    }
  }
}

testObjectDecode(String desc, input, bool markdown) {
  if (markdown) {
    print('$desc\n---');
  } else {
    print("${desc}:");
  }
  var packedJson = json.encode(input);
  var newPacked = serialize(input);

  var watch = new Stopwatch();
  var times = [];
  for (var i = 1; i <= TIMES; i++) {
    watch.reset();
    watch.start();
    json.decode(packedJson);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  var totalTime = times.reduce((a, b) => a + b);
  var avgTime = totalTime / TIMES;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print("  JSON:");
    print("    Total Time: $totalTime microseconds (${totalTime / 1000}ms)");
    print("    Average Time: $avgTime microseconds (${avgTime / 1000}ms)");
    print(
        "    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)");
    print(
        "    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)");
  }
  var jTotal = totalTime;
  var jAvg = avgTime;
  var jLong = times.last;
  var jShort = times.first;

  watch.reset();
  times.clear();
  for (var i = 1; i <= TIMES; i++) {
    watch.reset();
    watch.start();
    deserialize(newPacked);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  watch.stop();
  totalTime = times.reduce((a, b) => a + b);
  avgTime = totalTime / TIMES;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print("  MsgPack2:");
    print("    Total Time: ${totalTime} microseconds (${totalTime / 1000}ms)");
    print("    Average Time: ${avgTime} microseconds (${avgTime / 1000}ms)");
    print(
        "    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)");
    print(
        "    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)");
  }
  var nTotal = totalTime;
  var nAvg = avgTime;
  var nLong = times.last;
  var nShort = times.first;

  if (markdown) {
    print("Time | JSON | MsgPack2");
    print("-----|------|---------");
    print("Total | $jTotal μs (${jTotal / 1000}ms) | " +
        "$nTotal μs (${nTotal / 1000}ms)");
    print("Average | $jAvg μs (${jAvg / 1000}ms) | " +
        "$nAvg μs (${nAvg / 1000}ms)");
    print("Longest | $jLong μs (${jLong / 1000}ms) | " +
        "$nLong μs (${nLong / 1000}ms)");
    print("Shortest | $jShort μs (${jShort / 1000}ms) | " +
        "$nShort μs (${nShort / 1000}ms)");
  }

  if (nAvg <= jAvg) {
    if (markdown) {
      print("Fastest | MsgPack2\n");
    } else {
      print("  MsgPack2 was fastest");
    }
  } else {
    if (markdown) {
      print("Fastest | JSON\n");
    } else {
      print("  JSON was faster.");
    }
  }
}

testObjectEncode(String desc, input, bool markdown) {
  if (markdown) {
    print("$desc\n---");
  } else {
    print("${desc}:");
  }
  var watch = new Stopwatch();
  var times = [];

  int size = utf8.encode(json.encode(input)).length;
  for (var i = 1; i <= TIMES; i++) {
    watch.reset();
    watch.start();
    json.encode(input);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  var totalTime = times.reduce((a, b) => a + b);
  var avgTime = totalTime / TIMES;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print("  JSON:");
    print("    Total Time: $totalTime microseconds (${totalTime / 1000}ms)");
    print("    Average Time: $avgTime microseconds (${avgTime / 1000}ms)");
    print(
        "    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)");
    print(
        "    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)");
    print("    Size: ${size} bytes");
  }
  var jTotal = totalTime;
  var jAvg = avgTime;
  var jLong = times.last;
  var jShort = times.first;
  var jSize = size;

  watch.reset();
  size = serialize(input).length;
  times.clear();
  for (var i = 1; i <= TIMES; i++) {
    watch.reset();
    watch.start();
    serialize(input);
    watch.stop();
    times.add(watch.elapsedMicroseconds);
  }
  watch.stop();
  totalTime = times.reduce((a, b) => a + b);
  avgTime = totalTime / TIMES;
  times.sort((a, b) => a.compareTo(b));
  if (!markdown) {
    print("  MsgPack2:");
    print("    Total Time: ${totalTime} microseconds (${totalTime / 1000}ms)");
    print("    Average Time: ${avgTime} microseconds (${avgTime / 1000}ms)");
    print(
        "    Longest Time: ${times.last} microseconds (${times.last / 1000}ms)");
    print(
        "    Shortest Time: ${times.first} microseconds (${times.first / 1000}ms)");
    print("    Size: ${size} bytes");
  }
  var nTotal = totalTime;
  var nAvg = avgTime;
  var nLong = times.last;
  var nShort = times.first;
  var nSize = size;

  if (markdown) {
    print("Time | JSON | MsgPack | New MsgPack");
    print("-----|------|---------|------------");
    print("Total | $jTotal μs (${jTotal / 1000}ms) | " +
        "$nTotal μs (${nTotal / 1000}ms)");
    print("Average | $jAvg μs (${jAvg / 1000}ms) | " +
        "$nAvg μs (${nAvg / 1000}ms)");
    print("Longest | $jLong μs (${jLong / 1000}ms) | " +
        "$nLong μs (${nLong / 1000}ms)");
    print("Shortest | $jShort μs (${jShort / 1000}ms) | " +
        "$nShort μs (${nShort / 1000}ms)");
    print("Size | $jSize bytes | " + "$nSize bytes ");
  }

  if (nAvg <= jAvg) {
    if (markdown) {
      print("Fastest | MsgPack2\n");
    } else {
      print("  MsgPack2 was fastest");
    }
  } else {
    if (markdown) {
      print("Fastest | JSON\n");
    } else {
      print("  JSON was faster.");
    }
  }
}
