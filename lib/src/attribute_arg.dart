import 'dart:convert';

class AttributeArg {
  final String? name;
  final String? value;

  const AttributeArg({this.name, this.value});

  String toString() {
    var attributes = toJson();
    var encoded = json.encode(attributes);
    return encoded.toString();
  }

  Map<String, String?> toJson() {
    return {
      'Name': name,
      'Value': value,
    };
  }
}
