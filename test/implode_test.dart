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

  // TODO(viiviii): 최선인가?
  group('makeGroupsUsingVowelLetters', () {
    test('모음을 기준으로 Group 리스트를 만든다', () {
      final groups =
          makeGroupsUsingVowelLetters(['ㅂ', 'ㅜ', 'ㄹ', 'ㄷ', 'ㅏ', 'ㄱ']);
      final group1 = groups[0];
      expect(group1.initials, []);
      expect(group1.medial, null);
      expect(group1.finales, ['ㅂ']);
      final group2 = groups[1];
      expect(group2.initials, []);
      expect(group2.medial, 'ㅜ');
      expect(group2.finales, ['ㄹ', 'ㄷ']);
      final group3 = groups[2];
      expect(group3.initials, []);
      expect(group3.medial, 'ㅏ');
      expect(group3.finales, ['ㄱ']);
    });
  });

  group('mixedVowelLettersAndReplaceTheRemainingFinalesToInitials', () {
    // [Group([], null, [ㄱ, ㄱ]), Group([], ㅏ, [ㄱ, ㄷ]), Group([], ㅜ, [ㄱ]), Group([], ㅣ, [])]
    final before =
        makeGroupsUsingVowelLetters(['ㄱ', 'ㄱ', 'ㅏ', 'ㄱ', 'ㄷ', 'ㅜ', 'ㄱ', 'ㅣ']);
    test('각 그룹을 순회하면서 복합자음을 정리하고, 앞 그룹에서 종성으로 사용하고 남은 자음들을 초성으로 가져온다.', () {
      final groups =
          mixedVowelLettersAndReplaceTheRemainingFinalesToInitials(before);
      final group1 = groups[0];
      expect(group1.initials, []);
      expect(group1.medial, null);
      expect(group1.finales, []);
      final group2 = groups[1];
      expect(group2.initials, ['ㄱ', 'ㄱ']); // TODO(viiivii) - 이거 왜 정리 안됨?(ㄲ)
      expect(group2.medial, 'ㅏ');
      expect(group2.finales, ['ㄱ']);
      final group3 = groups[2];
      expect(group3.initials, ['ㄷ']);
      expect(group3.medial, 'ㅜ');
      expect(group3.finales, []);
      final group4 = groups[3];
      expect(group4.initials, ['ㄱ']);
      expect(group4.medial, 'ㅣ');
      expect(group4.finales, []);
    });
  });
}
