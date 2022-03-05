import 'package:flutter_test/flutter_test.dart';
import 'package:korea_regexp/src/implode.dart';

main() {
  group('implode', () {
    [
      ['ㄲㅏㄱㄷㅜㄱㅣ', '깍두기'],
      ['ㄱㄱㅏㄱㄷㅜㄱㅣ', 'ㄱ각두기'],
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

  group('mixedFinales', () {
    test('각 그룹을 순회하면서 종성의 복합자음을 정리한다', () {
      //given
      final initials = ['ㅇ'];
      final medial = 'ㅡ';
      final finales = ['ㅅ', 'ㅅ'];

      //when
      final actual = mixedFinales([Group.of(initials, medial, finales)]).first;

      //then
      expect(actual.initials, initials);
      expect(actual.medial, medial);
      expect(actual.finales, ['ㅆ']);
    });
  });

  // TODO(viiviii): 이최선인가?
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

  group('replaceTheRemainingFinalesToInitials', () {
    test('앞 그룹에 중성이 없는 경우', () {
      //given
      const previousMedial = null;
      const previousFinales = ['ㄱ', 'ㄱ'];

      final previous = Group.of([], previousMedial, previousFinales);
      final current = Group.of([], 'ㅏ', []);

      //when
      final groups = replaceTheRemainingFinalesToInitials([previous, current]);

      //then
      final previousActual = groups.first;
      final currentActual = groups.last;
      expect(previousActual.finales, []);
      expect(currentActual.initials, previousFinales);
    });

    test('앞 그룹에 중성이 있고, 종성이 없는 경우', () {
      //given
      const previousMedial = 'ㅗ';
      const previousFinales = <String>[];

      final previous = Group.of([], previousMedial, previousFinales);
      final current = Group.of([], 'ㅏ', []);

      //when
      final groups = replaceTheRemainingFinalesToInitials([previous, current]);

      //then
      final previousActual = groups.first;
      final currentActual = groups.last;
      expect(previousActual.finales, []);
      expect(currentActual.initials, previousFinales);
    });
  });

  test('앞 그룹에 중성이 있고, 종성이 1개인 경우', () {
    //given
    const previousMedial = 'ㅗ';
    const previousFinales = ['ㄱ'];

    final previous = Group.of([], previousMedial, previousFinales);
    final current = Group.of([], 'ㅏ', []);

    //when
    final groups = replaceTheRemainingFinalesToInitials([previous, current]);

    //then
    final previousActual = groups.first;
    final currentActual = groups.last;
    expect(previousActual.finales, []);
    expect(currentActual.initials, previousFinales);
  });

  // TODO(viiviii): 이 케이스를 제외하고는 모두 같다 -> 해당 메서드 분기 수정
  test('앞 그룹에 중성이 있고, 종성이 여러개인 경우', () {
    //given
    const previousMedial = 'ㅗ';
    const previousFinales = ['ㄱ', 'ㄱ'];

    final previous = Group.of([], previousMedial, previousFinales);
    final current = Group.of([], 'ㅏ', []);

    //when
    final groups = replaceTheRemainingFinalesToInitials([previous, current]);

    //then
    final previousActual = groups.first;
    final currentActual = groups.last;

    expect(previousActual.finales, [previousFinales.first]);
    expect(currentActual.initials, [previousFinales.last]);
  });

  group('groupsJoining', () {
    test('ㄱㄱㅗㅊ -> ㄱ곷', () {
      final group = Group.of(['ㄱ', 'ㄱ'], 'ㅗ', ['ㅊ']);
      expect(groupsJoining([group]), 'ㄱ곷');
    });
    test('ㄲㅗㅊ -> 꽃', () {
      final group = Group.of(['ㄲ'], 'ㅗ', ['ㅊ']);
      expect(groupsJoining([group]), '꽃');
    });
    test('종성 리스트의 첫번째 값이 유효한 종성이 아닌 경우', () {
      final group = Group.of(['ㄲ'], 'ㅗ', ['sㅊ']);
      expect(groupsJoining([group]), '꼬sㅊ');
    });
  });
}
