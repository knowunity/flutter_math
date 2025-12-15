import '../widgets/exception.dart';

class EncoderException implements FlutterMathException {
  const EncoderException(this.message, [this.token]);
  @override
  final String message;
  final dynamic token;

  @override
  String get messageWithType => 'Encoder Exception: $message';
}
