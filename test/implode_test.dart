import 'package:flutter_test/flutter_test.dart';
import 'package:korea_regexp/src/implode.dart';

main() {
  group('implode', () {
    [
      ['ㄲㅏㄱㄷㅜㄱㅣ', '깍두기'],
      ['ㄱㄱㅏㄱㄷㅜㄱㅣ', 'ㄱ각두기'], // TODO(viiviii): 초성 ㄱㄱ는 안합치고 종성 ㄱㄱ은 합쳐짐
      ['ㄲㅏㄱㄱㄷㅜㄱㅣ', '깎두기'],
      ['ㅂㅜㄹㄷㅏㄹㄱ', '불닭'],
      ['ㅂㅜㄹㄷㅏㄹㄱㅇㅡㄴ', '불닭은'],
      ['ㅇㅓㅂㅔㄴㅈㅕㅅㅡ ㅇㅐㄴㄷㅡㄱㅔㅇㅣㅁ', '어벤져스 앤드게임'],
    ].forEach((e) {
      final hints = e.first;
      final text = e.last;
      test('implode $hints → $text', () {
        expect(implode(hints), text);
      });
    });
  });

  group('mixMedial', () {
    test('ㅗㅏ -> ㅘ', () {
      expect(mixMedial(['ㅇ', 'ㅗ', 'ㅏ']), ['ㅇ', 'ㅘ']);
    });
    test('합칠 수 있는 복합 모음이 없는 경우 변경 사항이 없다', () {
      expect(mixMedial(['ㅇ', 'ㅣ', 'ㅇ']), ['ㅇ', 'ㅣ', 'ㅇ']);
      expect(mixMedial(['ㅇ', 'ㅣ', 'ㅜ']), ['ㅇ', 'ㅣ', 'ㅜ']);
    });
  });

  group('createGroupsByMedial', () {
    test('ㄱ, ㅡ , ㄹ, ㅐ -> [ㄱ], [ㅡ, ㄹ], [ㅐ]', () {
      final groups = createGroupsByMedial(['ㄱ', 'ㅡ', 'ㄹ', 'ㅐ']);

      final group1 = groups[0];
      expect(group1.finales, ['ㄱ']);
      final group2 = groups[1];
      expect(group2.medial, 'ㅡ');
      expect(group2.finales, ['ㄹ']);
      final group3 = groups[2];
      expect(group3.medial, 'ㅐ');
    });
  });

  // TODO(viiviii)
  group('mixFinaleAndReplaceTheRemainingFinalesToInitials', () {
    test('앞 그룹에 중성이 없는 경우', () {
      //given
      const previousFinales = ['ㄱ', 'ㄱ'];

      final previous = Group.from(finales: previousFinales);
      final current = Group.from(medial: 'ㅏ');

      //when
      final groups =
          mixFinaleAndReplaceTheRemainingFinalesToInitials([previous, current]);

      //then
      final previousActual = groups.first;
      final currentActual = groups.last;
      expect(previousActual.finales, isEmpty);
      expect(currentActual.initials, previousFinales);
    });

    test('앞 그룹에 중성이 있고, 종성이 없는 경우', () {
      //given
      const previousMedial = 'ㅗ';

      final previous = Group.from(medial: previousMedial);
      final current = Group.from(medial: 'ㅏ');

      //when
      final groups =
          mixFinaleAndReplaceTheRemainingFinalesToInitials([previous, current]);

      //then
      final previousActual = groups.first;
      final currentActual = groups.last;
      expect(previousActual.finales, isEmpty);
      expect(currentActual.initials, isEmpty);
    });
  });

  test('앞 그룹에 중성이 있고, 종성이 1개인 경우', () {
    //given
    const previousMedial = 'ㅗ';
    const previousFinales = ['ㄱ'];

    final previous = Group.of([], previousMedial, previousFinales);
    final current = Group.from(medial: 'ㅏ');

    //when
    final groups =
        mixFinaleAndReplaceTheRemainingFinalesToInitials([previous, current]);

    //then
    final previousActual = groups.first;
    final currentActual = groups.last;
    expect(previousActual.finales, isEmpty);
    expect(currentActual.initials, previousFinales);
  });

  test('앞 그룹에 중성이 있고, 종성이 여러개인 경우', () {
    //given
    const previousMedial = 'ㅗ';
    const previousFinales = ['ㄱ', 'ㄱ'];

    final previous = Group.of([], previousMedial, previousFinales);
    final current = Group.from(medial: 'ㅏ');

    //when
    final groups =
        mixFinaleAndReplaceTheRemainingFinalesToInitials([previous, current]);

    //then
    final previousActual = groups.first;
    final currentActual = groups.last;

    expect(previousActual.finales, [previousFinales.first]);
    expect(currentActual.initials, [previousFinales.last]);
  });

  group('divideByHangulBlocks', () {
    test('[ㄲ], ㅗ, [ㅊ] -> [ㄲ, ㅗ, ㅊ]', () {
      final group = Group.of(['ㄲ'], 'ㅗ', ['ㅊ']);
      expect(divideByHangulBlocks(group), [
        ['ㄲ', 'ㅗ', 'ㅊ']
      ]);
    });
    test('빈 값인 경우 값이 추가되지 않는다', () {
      final group = Group.empty();
      expect(divideByHangulBlocks(group), [[]]);
    });
    test('빈 문자열인 경우 값이 추가되지 않는다', () {
      final group = Group.from(initials: [''], finales: ['']);
      expect(divideByHangulBlocks(group), [[]]);
    });
    test('`initials`의 마지막 글자는 초성으로 나머지는 분리된다', () {
      final group = Group.of(['ㅇ', 'ㄲ'], 'ㅗ', ['ㅊ']);
      expect(divideByHangulBlocks(group), [
        ['ㅇ'],
        ['ㄲ', 'ㅗ', 'ㅊ']
      ]);
    });
    test('`finales`의 첫번째 글자는 종성으로 나머지는 분리된다', () {
      final group = Group.of(['ㄲ'], 'ㅗ', ['ㅊ', 'ㅇ']);
      expect(divideByHangulBlocks(group), [
        ['ㄲ', 'ㅗ', 'ㅊ'],
        ['ㅇ']
      ]);
    });
    test('`finales`의 첫번째 글자가 올바른 종성이 아니면 모두 분리된다', () {
      final group = Group.of(['ㄲ'], 'ㅗ', ['s', 'ㅊ']);
      expect(divideByHangulBlocks(group), [
        ['ㄲ', 'ㅗ'],
        ['s'],
        ['ㅊ']
      ]);
    });
    // TODO(viiviii): 초성의 유효성 검사는 여기서 실행되지 않음
    test('초성은 유효성 검사를 하지 않는다', () {
      final group = Group.of(['ㄲ', 's'], 'ㅗ', ['ㅊ']);
      expect(divideByHangulBlocks(group), [
        ['ㄲ'],
        ['s', 'ㅗ', 'ㅊ']
      ]);
    });
  });

  group('assemble', () {
    test('[ㄲ, ㅗ, ㅊ] -> 꽃', () {
      expect(assemble(['ㄲ', 'ㅗ', 'ㅊ']), '꽃');
    });
    test('종성이 없는 경우 연결된 문자열을 리턴한다', () {
      expect(assemble(['ㅇ', 'ㅇ', 'ㅇ']), 'ㅇㅇㅇ');
    });
    test('유효한 형식이 아닌 경우 - 종성이 초성에 있음', () {
      expect(assemble(['ㄽ', 'ㅗ', 'ㅇ']), 'ㄽㅗㅇ');
    });
    test('유효한 형식이 아닌 경우 - 중성이 없음', () {
      expect(assemble(['ㅇ', 'ㅇ', 'ㅇ']), 'ㅇㅇㅇ');
    });

    // TODO(viiviii): 왜죠
    test('복합 자모인 경우', () {
      expect(assemble(['ㅇ', 'ㅜ', 'ㅣ']), '위');
      expect(assemble(['ㅇ', 'ㅗ', 'ㅏ']), '와');
    });
  });

  group('divide', () {
    test('올바른 음절 블럭에서 초성, 중성, 종성을 분리한다', () {
      final block = divide(['ㄲ', 'ㅗ', 'ㅊ']);
      expect(block.initial, 'ㄲ');
      expect(block.medial, 'ㅗ');
      expect(block.finale, 'ㅊ');
    });
    // TODO(viiviii)
    test('중성이 2글자 이상이어도 2글자만 중성으로 분리된다', () {
      final block = divide(['ㅇ', 'ㅜ', 'ㅣ', 'ㅜ', 'ㅣ']);
      expect(block.initial, 'ㅇ');
      expect(block.medial, 'ㅜㅣ');
      expect(block.finale, 'ㅜㅣ');
    });
  });

  group('SyllableOffsets', () {
    test('초성이 유효하지 않으면 isValid는 false를 리턴한다', () {
      final offsets = SyllableOffsets.from('ㄽ', 'ㅗ', 'ㅇ');
      expect(offsets.isValid, false);
    });
    test('중성이 유효하지 않으면 isValid는 false를 리턴한다', () {
      final offsets = SyllableOffsets.from('ㄹ', 'ㄹ', 'ㅇ');
      expect(offsets.isValid, false);
    });
    test('올바른 자모일 경우 한글 음절을 리턴한다', () {
      final offsets = SyllableOffsets.from('ㄲ', 'ㅗ', 'ㅊ');
      expect(offsets.toSyllable(), '꽃');
    });

    // TODO(viiviii): 1. 유효하지 않는 종성일 경우 의도치 않게 동작
    // TODO(viiviii): 2. 초성, 중성, 종성에서 MIXED를 사용하여 복합 자모를 한번 더 합치는데 MIXED는 중성+종성 복합자모이므로 초성이 빠져있는 듯 함(ㅃ, ㄸ)
    test('종성은 isValid에서 유효성 검사를 하지 않는다', () {
      final offsets = SyllableOffsets.from('ㄹ', 'ㅗ', 'ㅗ');
      expect(offsets.isValid, isNot(false));
    });
    test('복합 초성를 한번 더 합친다', () {
      final offsets = SyllableOffsets.from('ㄱㄱ', 'ㅗ', 'ㅊ');
      expect(offsets.toSyllable(), '꽃');
    });
    test('복합 중성를 한번 더 합친다', () {
      final offsets = SyllableOffsets.from('ㅇ', 'ㅜㅣ', '');
      expect(offsets.toSyllable(), '위');
    });
    test('복합 종성를 한번 더 합친다', () {
      final offsets = SyllableOffsets.from('ㅇ', 'ㅣ', 'ㅅㅅ');
      expect(offsets.toSyllable(), '있');
    });
    test('하지만 초성에서 ㄸ, ㅃ와 같은 복합 자모는 합치지 못한다', () {
      final offsets = SyllableOffsets.from('ㄷㄷ', 'ㅣ', '');
      expect(offsets.toSyllable(), isNot('띠'));
    });
  });
}
