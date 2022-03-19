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

      final previous = Group.empty()..finales = previousFinales;
      final current = Group.fromMedial('ㅏ');

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

      final previous = Group.fromMedial(previousMedial);
      final current = Group.fromMedial('ㅏ');

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

    final previous = Group.fromMedial(previousMedial)
      ..finales = previousFinales;
    final current = Group.fromMedial('ㅏ');

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

    final previous = Group.fromMedial(previousMedial)
      ..finales = previousFinales;
    final current = Group.fromMedial('ㅏ');

    //when
    final groups =
        mixFinaleAndReplaceTheRemainingFinalesToInitials([previous, current]);

    //then
    final previousActual = groups.first;
    final currentActual = groups.last;

    expect(previousActual.finales, [previousFinales.first]);
    expect(currentActual.initials, [previousFinales.last]);
  });

  group('divideByBlock', () {
    test('`Group initials`의 마지막 글자만 초성으로 남긴다', () {
      final group = Group.fromMedial('ㅗ')
        ..initials = ['ㅇ', 'ㄲ']
        ..finales = ['ㅊ'];
      expect(divideByBlock(group), [
        ['ㅇ'],
        ['ㄲ', 'ㅗ', 'ㅊ']
      ]);
    });
    test('`Group finales`의 첫번째 글자만 종성으로 남긴다', () {
      final group = Group.fromMedial('ㅗ')
        ..initials = ['ㄲ']
        ..finales = ['ㅊ', 'ㅇ'];
      expect(divideByBlock(group), [
        ['ㄲ', 'ㅗ', 'ㅊ'],
        ['ㅇ']
      ]);
    });
    test('`Group finales`의 첫번째 글자가 유효하지 않으면 종성으로 사용되지 않는다', () {
      final group = Group.fromMedial('ㅗ')
        ..initials = ['ㄲ']
        ..finales = ['s', 'ㅊ'];
      expect(divideByBlock(group), [
        ['ㄲ', 'ㅗ'],
        ['s'],
        ['ㅊ']
      ]);
    });
    test('빈 값인 경우 빈 배열을 리턴한다', () {
      final group = Group.empty();
      expect(divideByBlock(group), [[]]);
    });
    test('빈 문자열인 경우 빈 배열을 리턴한다', () {
      final group = Group.empty()
        ..initials = ['']
        ..finales = [''];
      expect(divideByBlock(group), [[]]);
    });
    // TODO(viiviii): 초성의 유효성 검사는 여기서 실행되지 않음
    test('초성은 유효성 검사를 하지 않고 사용된다', () {
      final group = Group.fromMedial('ㅗ')
        ..initials = ['ㄲ', 's']
        ..finales = ['ㅊ'];
      expect(divideByBlock(group), [
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
    test('올바른 음절 형식이 아닌 경우 연결된 문자열을 리턴한다', () {
      expect(assemble(['ㄽ', 'ㅗ', 'ㅇ']), 'ㄽㅗㅇ');
    });
  });

  group('createSyllableFormByMedial', () {
    test('문자열에서 초성, 중성, 종성을 분리한다', () {
      final block = createSyllableFormByMedial(['ㄲ', 'ㅗ', 'ㅊ']);
      expect(block.initial, 'ㄲ');
      expect(block.medial, 'ㅗ');
      expect(block.finale, 'ㅊ');
    });
    // TODO(viiviii)
    test('중성이 2글자 이상이어도 2글자만 중성으로 분리된다', () {
      final block = createSyllableFormByMedial(['ㅇ', 'ㅜ', 'ㅣ', 'ㅜ', 'ㅣ']);
      expect(block.initial, 'ㅇ');
      expect(block.medial, 'ㅜㅣ');
      expect(block.finale, 'ㅜㅣ');
    });
  });

  group('Composition', () {
    test('ㄲㅗㅊ -> 꽃', () {
      final form = SyllableForm('ㄲ', 'ㅗ', 'ㅊ');
      expect(Composition.from(form).toSyllable(), '꽃');
    });
    test('초성이 유효하지 않으면 isValid는 false를 리턴한다', () {
      final form = SyllableForm('ㄽ', 'ㅗ', 'ㅇ');
      expect(Composition.from(form).isValid, false);
    });
    test('중성이 유효하지 않으면 isValid는 false를 리턴한다', () {
      final form = SyllableForm('ㄹ', 'ㄹ', 'ㅇ');
      expect(Composition.from(form).isValid, false);
    });

    // TODO(viiviii)
    // 1. 유효하지 않는 종성일 경우 의도치 않게 동작
    // 2. 초성, 중성, 종성에서 MIXED를 사용하여 복합 자모를 한번 더 합침
    // 3. 이때 MIXED는 중성+종성 복합 자모이므로 초성이 빠져있어 (ㅃ, ㄸ, ..)는 제외됨
    test('종성은 isValid에서 유효성 검사를 하지 않는다', () {
      final form = SyllableForm('ㄹ', 'ㅗ', 'ㅗ');
      expect(Composition.from(form).isValid, isNot(false));
    });
    test('복합 초성를 한번 더 합친다', () {
      final form = SyllableForm('ㄱㄱ', 'ㅗ', 'ㅊ');
      expect(Composition.from(form).toSyllable(), '꽃');
    });
    test('복합 중성를 한번 더 합친다', () {
      final form = SyllableForm('ㅇ', 'ㅜㅣ', '');
      expect(Composition.from(form).toSyllable(), '위');
    });
    test('복합 종성를 한번 더 합친다', () {
      final form = SyllableForm('ㅇ', 'ㅣ', 'ㅅㅅ');
      expect(Composition.from(form).toSyllable(), '있');
    });
    test('하지만 초성에서 ㄸ, ㅃ와 같은 복합 자모는 합치지 못한다', () {
      final form = SyllableForm('ㄷㄷ', 'ㅣ', '');
      expect(Composition.from(form).toSyllable(), isNot('띠'));
    });
  });
}
