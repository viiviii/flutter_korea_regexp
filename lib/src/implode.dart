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
  final List<List<String>> items4 = divideByHangulBlock(items2);

  return items4.map(assemble).join();
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
List<List<String>> divideByHangulBlock(List<Group> groups) {
  final List<List<String>> result = [];
  groups.forEach((e) {
    final List<String> pre = List.of(e.initials);
    final String initial = pre.isNotEmpty ? pre.removeLast() : '';

    List<String> post = e.finales;
    String finale = '';
    if (post.isNotEmpty && _isFinale(post.first)) {
      finale = post.first;
      post = post.skip(1).toList();
    }

    pre.where((e) => e.isNotEmpty).forEach((e) => result.add([e]));
    result.add([initial, e.medial, finale].where((e) => e.isNotEmpty).toList());
    post.where((e) => e.isNotEmpty).forEach((e) => result.add([e]));
  });
  return result;
}

String assemble(List<String> arr) {
  final startIndex = arr.indexWhere((e) => MEDIALS.indexOf(e) != -1);
  final endIndex = startIndex != -1 &&
          startIndex != arr.length - 1 &&
          MEDIALS.indexOf(arr[startIndex + 1]) != -1
      ? startIndex + 1
      : startIndex;

  // TODO(viiviii)
  if (startIndex == -1 || endIndex == -1) {
    return arr.join();
  }

  String initial = arr.sublist(0, startIndex).join();
  String medial = arr.sublist(startIndex, endIndex + 1).join();
  String finale = arr.sublist(endIndex + 1).join();

  var initialOffset = INITIALS.indexOf(complexDict[initial] ?? initial);
  var medialOffset = MEDIALS.indexOf(complexDict[medial] ?? medial);
  var finaleOffset = FINALES.indexOf(complexDict[finale] ?? finale);

  if (initialOffset != -1 && medialOffset != -1) {
    return String.fromCharCode(BASE +
        initialOffset * (MEDIALS.length * FINALES.length) +
        medialOffset * FINALES.length +
        finaleOffset);
  }

  return arr.join();
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
