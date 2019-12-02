import 'dart:convert';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'random_string_helper.dart';

final String initN = 'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1' +
    '29024E088A67CC74020BBEA63B139B22514A08798E3404DD' +
    'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245' +
    'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED' +
    'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D' +
    'C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F' +
    '83655D23DCA3AD961C62F356208552BB9ED529077096966D' +
    '670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B' +
    'E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9' +
    'DE2BCBF6955817183995497CEA956AE515D2261898FA0510' +
    '15728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64' +
    'ECFB850458DBEF0A8AEA71575D060C7DB3970F85A6E1E4C7' +
    'ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6B' +
    'F12FFA06D98A0864D87602733EC86A64521F2B18177B200C' +
    'BBE117577A615D6C770988C0BAD946E208E24FA074E5AB31' +
    '43DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF';

final String _newPasswordRequiredChallengeUserAttributePrefix =
    'userAttributes.';

class AuthenticationHelper {
  String poolName;
  BigInt N;
  BigInt g;
  BigInt k;
  List<int> _infoBits;
  BigInt _smallAValue;
  BigInt _largeAValue;
  String _uHexHash;
  BigInt _uValue;
  String _randomPassword;
  String _saltToHashDevices;
  String _verifierDevices;
  AuthenticationHelper(this.poolName) {
    this.N = BigInt.parse(initN, radix: 16);
    this.g = BigInt.parse('2', radix: 16);
    this.k = BigInt.parse(
      this.hexHash('00${this.N.toRadixString(16)}0${this.g.toRadixString(16)}'),
      radix: 16,
    );
    this._smallAValue = this.generateRandomSmallA();
    this.getLargeAValue();
    this._infoBits = utf8.encode('Caldera Derived Key');
  }

  BigInt getSmallAValue() {
    return _smallAValue;
  }

  BigInt getLargeAValue() {
    if (_largeAValue != null) {
      return _largeAValue;
    }
    _largeAValue = calculateA(_smallAValue);
    return _largeAValue;
  }

  String getRandomPassword() {
    return _randomPassword;
  }

  String getSaltDevices() {
    return _saltToHashDevices;
  }

  String getVerifierDevices() {
    return _verifierDevices;
  }

  /// Return constant newPasswordRequiredChallengeUserAttributePrefix
  String getNewPasswordRequiredChallengeUserAttributePrefix() {
    return _newPasswordRequiredChallengeUserAttributePrefix;
  }

  /// Calculates the final hkdf based on computed S value, and computed U value and the key
  List<int> getPasswordAuthenticationKey(
      String username, String password, BigInt serverBValue, BigInt salt) {
    if (serverBValue % N == BigInt.zero) {
      throw new ArgumentError('B cannot be zero.');
    }
    _uValue = calculateU(_largeAValue, serverBValue);
    if (_uValue == BigInt.zero) {
      throw new ArgumentError('U cannot be zero.');
    }

    final String usernamePassword = '${this.poolName}${username}:${password}';
    final String usernamePasswordHash = hash(utf8.encode(usernamePassword));
    final xValue =
        BigInt.parse(hexHash(padHex(salt) + usernamePasswordHash), radix: 16);

    final sValue = calculateS(xValue, serverBValue);

    List<int> hkdf =
        computehkdf(hex.decode(padHex(sValue)), hex.decode(padHex(_uValue)));

    return hkdf;
  }

  /// helper function to generate a random big integer
  BigInt generateRandomSmallA() {
    final String hexRandom = new RandomString().generate(length: 128);

    final BigInt randomBigInt = BigInt.parse(hexRandom, radix: 16);

    final smallABigInt = randomBigInt % N;

    return smallABigInt;
  }

  /// helper function to generate a random string
  String generateRandomString() {
    return new RandomString().generate(length: 40);
  }

  /// Generate salts and compute verifier.
  void generateHashDevice(String deviceGroupKey, String username) {
    _randomPassword = this.generateRandomString();
    final String combinedString =
        '`$deviceGroupKey$username:${this._randomPassword}';
    final String hashedString = this.hash(utf8.encode(combinedString));

    final String hexRandom = new RandomString().generate(length: 16);

    _saltToHashDevices = this.padHex(BigInt.parse(hexRandom, radix: 16));

    final verifierDevicesNotPadded = modPow(
      this.g,
      BigInt.parse(this.hexHash(_saltToHashDevices + hashedString), radix: 16),
      this.N,
    );

    _verifierDevices = this.padHex(verifierDevicesNotPadded);
  }

  /// Calculate a hash from a bitArray
  String hash(List<int> buf) {
    final String hashHex = sha256.convert(buf).toString();
    return (new List(64 - hashHex.length).join('0')) + hashHex;
  }

  /// Calculate a hash from a hex string
  String hexHash(String hexStr) {
    return this.hash(hex.decode(hexStr));
  }

  /// Calculate the client's public value A = g^a%N
  /// with the generated random number a
  BigInt calculateA(BigInt a) {
    final A = modPow(this.g, a, N);
    if ((A % this.N) == BigInt.zero) {
      throw new Exception('Illegal paramater. A mod N cannot be 0.');
    }
    return A;
  }

  /// Calculate the client's value U which is the hash of A and B
  BigInt calculateU(BigInt a, BigInt b) {
    _uHexHash = hexHash(padHex(a) + padHex(b));
    return BigInt.parse(_uHexHash, radix: 16);
  }

  /// Calculates the S value used in getPasswordAuthenticationKey
  BigInt calculateS(BigInt xValue, BigInt serverBValue) {
    final gModPowXN = modPow(this.g, xValue, N);
    final intValue2 = serverBValue - (this.k * gModPowXN);
    final result = modPow(
      intValue2,
      _smallAValue + (_uValue * xValue),
      N,
    );
    return result % N;
  }

  /// Temporary workaround to BigInt.modPow's bug
  /// Based on https://github.com/dart-lang/googleapis_auth/blob/master/lib/src/crypto/rsa.dart
  BigInt modPow(BigInt b, BigInt e, BigInt m) {
    if (e < BigInt.one) {
      return BigInt.one;
    }
    if (b < BigInt.zero || b > m) {
      b = b % m;
    }
    var r = BigInt.one;
    while (e > BigInt.zero) {
      if ((e & BigInt.one) > BigInt.zero) {
        r = (r * b) % m;
      }
      e >>= 1;
      b = (b * b) % m;
    }
    return r;
  }

  /// Standard hkdf algorithm
  List<int> computehkdf(List<int> ikm, List<int> salt) {
    Hmac hmac1 = new Hmac(sha256, salt);
    Digest prk = hmac1.convert(ikm);
    List<int> infoBitsUpdate = new List.from(_infoBits)
      ..addAll(utf8.encode(String.fromCharCode(1)));
    Hmac hmac2 = new Hmac(sha256, prk.bytes);
    Digest dig = hmac2.convert(infoBitsUpdate);
    return dig.bytes.getRange(0, 16).toList();
  }

  /// Converts a BigInteger to hex format padded with zeroes for hashing
  String padHex(BigInt bigInt) {
    var hashStr = bigInt.toRadixString(16);
    if (hashStr.length % 2 == 1) {
      hashStr = '0$hashStr';
    } else if ('89ABCDEFabcdef'.indexOf(hashStr[0]) != -1) {
      hashStr = '00$hashStr';
    }
    return hashStr;
  }

  /// Converts a signed and possibly unpadded salt of 128 bits to unsigned and padded
  String toUnsignedHex(String input) {
    String output;
    bool negative = false;
    /// Detect negative and remove from string
    if(input[0] == '-') {
      negative = true;
      output = input.substring(1); // remove negative sign
    }
    else {
      output = input;
    }
    /// Pad string to 32 hex digits (128 bits total)
    while(output.length < 32) {
      output = '0' + output;
    }
    /// OR in a 1 to the top bit if the original string was negative
    if(negative) {
      String toReplace = output[0];
      output = output.substring(1);
      String updatedLeadingDigit = (int.parse(toReplace) | 0x8).toRadixString(16);
      output = updatedLeadingDigit + output;
    }
    return output;
  }
}
