import 'package:flutter_test/flutter_test.dart';
import 'package:walk/domain/transit/transit_failure.dart';

void main() {
  group('maskTransitKey', () {
    test('masks apiKey query value', () {
      expect(
        maskTransitKey('GET https://a/b?x=1&apiKey=abc%2Bd&y=2'),
        'GET https://a/b?x=1&apiKey=••••&y=2',
      );
      expect(maskTransitKey('apikey=zz end'), 'apikey=•••• end');
    });

    test('masks raw and encoded key value when given', () {
      expect(
        maskTransitKey('k a+b/c= and a%2Bb%2Fc%3D', key: 'a+b/c='),
        'k •••• and ••••',
      );
    });

    test('empty or too short key does not mask plain letters', () {
      expect(maskTransitKey('hello', key: ''), 'hello');
      expect(maskTransitKey('Socket k', key: 'k'), 'Socket k');
    });
  });

  test('describeError prefixes runtime type once', () {
    expect(describeError(StateError('x')), 'StateError: Bad state: x');
    expect(describeError(const FormatException('y')), 'FormatException: y');
    expect(describeError('plain'), 'String: plain');
  });

  test('detail exposes cause per kind', () {
    expect(const TransitFailure.missingKey().detail, '');
    expect(
      const TransitFailure.keyRejected('code 500 · A').detail,
      'code 500 · A',
    );
    expect(const TransitFailure.quotaExceeded('q').detail, 'q');
    expect(const TransitFailure.network('n').detail, 'n');
    expect(const TransitFailure.network().detail, '');
    expect(const TransitFailure.server('s').detail, 's');
    expect(const TransitFailure.unexpected('u').detail, 'u');
  });
}
