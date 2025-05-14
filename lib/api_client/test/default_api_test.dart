import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for DefaultApi
void main() {
  final instance = Openapi().getDefaultApi();

  group(DefaultApi, () {
    // Get cost-saving tips and discounts.
    //
    //Future<BuiltList<DiscountsGet200ResponseInner>> discountsGet({ String location }) async
    test('test discountsGet', () async {
      // TODO
    });

  });
}
