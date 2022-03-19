import 'package:korea_regexp/src/constant.dart';

final complexDict = MIXED.map((k, v) => MapEntry(v.join(), k));

// TODO(viiviii): 변수명
String implode(String input) {
  /// 인접한 모음을 하나의 복합 모음으로 합친다.
  final chars = mixMedial(input.split(''));

  /// 모음으로 시작하는 그룹들을 만든다.
  final items = createGroupsByMedial(chars);

  /// 각 그룹을 순회하면서 복합자음을 정리하고, 앞 그룹에서 종성으로 사용하고 남은 자음들을 초성으로 가져온다.
  final items2 = mixFinaleAndReplaceTheRemainingFinalesToInitials(items);

  /// 각 글자에 해당하는 블록 단위로 나눈다.
  final blocks = items2.fold<List<List<String>>>(
      [], (acc, group) => acc..addAll(divideByHangulBlocks(group)));

  return blocks.map(assemble).join();
}

/// 인접한 모음을 하나의 복합 모음으로 합친다.
// TODO(viiviii): MIXED 상수를 자음, 모음 분리해서 바로 찾는게 좋지 않을까?
List<String> mixMedial(List<String> inputs) {
  final chars = [inputs.first];
  inputs.forEachFromNext((previous, current) {
    final mixedLetter = _mix(previous, current);
    if (_isMedial(previous) && _isMedial(current) && mixedLetter != null) {
      chars.last = mixedLetter;
    } else {
      chars.add(current);
    }
  });
  return chars;
}

/// 모음으로 시작하는 그룹들을 만든다.
List<Group> createGroupsByMedial(List<String> chars) {
  Group cursor = Group.empty();
  final items = [cursor];
  chars.forEach((e) {
    if (_isMedial(e)) {
      cursor = Group.from(medial: e);
      items.add(cursor);
    } else {
      cursor.finales.add(e);
    }
  });
  return items;
}

/// 각 그룹을 순회하면서 복합자음을 정리하고, 앞 그룹에서 종성으로 사용하고 남은 자음들을 초성으로 가져온다.
List<Group> mixFinaleAndReplaceTheRemainingFinalesToInitials(
    List<Group> groups) {
  final items = List.of(groups);
  items.forEachFromNext((prev, curr) {
    if (!prev.hasMedial || prev.finales.length == 1) {
      curr.initials = prev.finales;
      prev.finales = [];
    } else {
      curr.initials = prev.finales.skip(1).toList();
      prev.finales = prev.finales.take(1).toList();
    }

    const MIX_LETTERS_LENGTH = 2;
    const NEXT_INITIAL_LENGTH = 1;
    if (curr.finales.length >= MIX_LETTERS_LENGTH + NEXT_INITIAL_LENGTH ||
        (curr == items.last && curr.finales.length >= MIX_LETTERS_LENGTH)) {
      final letters = curr.finales.take(MIX_LETTERS_LENGTH);
      final rest = curr.finales.skip(MIX_LETTERS_LENGTH);
      final mixedLetter = _mix(letters.first, letters.last);
      if (mixedLetter != null) {
        curr.finales = [mixedLetter, ...rest];
      }
    }
  });
  return items;
}

/// 각 글자에 해당하는 블록 단위로 나눈다.
List<List<String>> divideByHangulBlocks(Group group) {
  final pre = List.of(group.initials);
  final initial = pre.isNotEmpty ? pre.removeLast() : '';

  var post = group.finales;
  var finale = '';
  if (post.isNotEmpty && _isFinale(post.first)) {
    finale = post.first;
    post = post.skip(1).toList();
  }

  final blocks = <List<String>>[];
  blocks.addAll(pre.where((e) => e.isNotEmpty).map((e) => [e]).toList());
  blocks
      .add([initial, group.medial, finale].where((e) => e.isNotEmpty).toList());
  blocks.addAll(post.where((e) => e.isNotEmpty).map((e) => [e]).toList());
  return blocks;
}

/// 올바른 음절 형식일 경우 합치고, 아닌 경우 문자열을 연결하여 리턴한다.
String assemble(List<String> block) {
  if (!block.any(_isMedial)) {
    return block.join();
  }
  final syllableForm = createSyllableFormByMedial(block);
  final composition = Composition.from(syllableForm);
  if (!composition.isValid) {
    return block.join();
  }
  return composition.toSyllable();
}

// TODO(viiviii): 유효성 검증 로직 한곳으로, 중복된 기능
/// 중성(최대 2개)을 기준으로 초성, 중성, 종성을 분리한다
SyllableForm createSyllableFormByMedial(List<String> block) {
  assert(block.any(_isMedial));
  final medialIndex = block.indexWhere(_isMedial);
  final isMedialNext =
      medialIndex != block.length - 1 && _isMedial(block[medialIndex + 1]);
  final nextMedialIndex = isMedialNext ? medialIndex + 1 : medialIndex;
  final finaleIndex = nextMedialIndex + 1;

  final initial = block.sublist(0, medialIndex).join();
  final medial = block.sublist(medialIndex, finaleIndex).join();
  final finale = block.sublist(finaleIndex).join();
  return SyllableForm(initial, medial, finale);
}

/// 해당 글자가 중성인지
bool _isMedial(String? char) => MEDIALS.contains(char);

/// 해당 글자가 종성인지
bool _isFinale(String? char) => FINALES.contains(char);

/// 복합 자모일 경우 합친 글자를 리턴한다
String? _mix(String first, String last) => complexDict['$first$last'];

class Group {
  List<String> initials;
  final String medial;
  List<String> finales;

  Group.empty() : this.from();

  Group.from({List<String>? initials, String? medial, List<String>? finales})
      : this.of(initials ?? [], medial ?? '', finales ?? []);

  Group.of(this.initials, this.medial, this.finales);

  bool get hasMedial => medial.isNotEmpty;

  @override
  String toString() => '$runtimeType($initials, $medial, $finales)';
}

class SyllableForm {
  final String initial;
  final String medial;
  final String finale;

  SyllableForm(this.initial, this.medial, this.finale);
}

/// 올바른 초성, 중성, 종성일 경우 하나의 한글 음절을 구할 수 있다.
///
/// 자모는 [INITIALS], [MEDIALS], [FINALES] 리스트에 알고리즘적으로 매핑되어 있다.
/// 이 클래스의 필드 값은 이 상수 리스트에서 얻은 값이며 한글 음절을 구하는 계산식에 사용된다.
///
/// for Example,
/// ```dart
/// var composition = Composition('ㅎ', 'ㅏ', 'ㄴ');
/// var syllable = composition.toSyllable(); // 한
/// ```
/// 내부적으로 다음과 같이 계산된다.
/// - 한 = ㅎ(18), ㅏ(0), ㄴ(4) = 44032 + [18 × 588 + 0 × 28 + 4] = 54620
class Composition {
  final int initial;
  final int medial;
  final int finale;

  Composition.from(SyllableForm syllableForm)
      : this._(syllableForm.initial, syllableForm.medial, syllableForm.finale);

  Composition._(String initial, String medial, String finale)
      : initial = INITIALS.indexOf(complexDict[initial] ?? initial),
        medial = MEDIALS.indexOf(complexDict[medial] ?? medial),
        finale = FINALES.indexOf(complexDict[finale] ?? finale);

  bool get isValid => initial != -1 && medial != -1;

  String toSyllable() => String.fromCharCode(_syllableCharCode());

  /// 필드 값으로 하나의 한글 음절 유니코드 코드포인트를 구한다.
  int _syllableCharCode() {
    return BASE +
        initial * (MEDIALS.length * FINALES.length) +
        medial * FINALES.length +
        finale;
  }
}

extension _<E> on List<E> {
  void forEachFromNext(void f(E previousValue, E element)) {
    if (this.isEmpty) return;
    var previousValue = this.first;
    this.skip(1).forEach((element) {
      f(previousValue, element);
      previousValue = element;
    });
  }
}
