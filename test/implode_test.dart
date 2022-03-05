import 'package:flutter_test/flutter_test.dart';
import 'package:korea_regexp/src/implode.dart';

main() {
  group('implode', () {
    [
      ['ㄲㅏㄱㄷㅜㄱㅣ', '깍두기'],
      ['ㅂㅜㄹㄷㅏㄹㄱ', '불닭'],
      ['ㅇㅓㅂㅔㄴㅈㅕㅅㅡ ㅇㅐㄴㄷㅡㄱㅔㅇㅣㅁ', '어벤져스 앤드게임'],
    ].forEach((e) {
      final hints = e[0];
      final text = e[1];
      test('implode $hints → $text', () {
        expect(implode(hints), text);
      });
    });
  });

  group('mixedConsonantLetters', () {
    test('인접한 모음을 복합 모음으로 합친다', () {
      expect(mixedConsonantLetters(['ㅇ', 'ㅜ', 'ㅓ', 'ㄴ']), ['ㅇ', 'ㅝ', 'ㄴ']);
    });
    test('합칠 수 있는 복합 모음이 없는 경우 변경 사항이 없다', () {
      expect(mixedConsonantLetters(['ㅇ', 'ㅣ', 'ㅇ']), ['ㅇ', 'ㅣ', 'ㅇ']);
      expect(mixedConsonantLetters(['ㅇ', 'ㅣ', 'ㅜ']), ['ㅇ', 'ㅣ', 'ㅜ']);
    });
  });
}
