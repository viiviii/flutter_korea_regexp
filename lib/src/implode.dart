import 'package:collection/collection.dart' show IterableNullableExtension;
import 'package:korea_regexp/src/constant.dart';

final complexDict = MIXED.map((k, v) => MapEntry(v.join(''), k));

// TODO(viiviii): 파라미터로 string[]이 오는 경우
String implode(String input) {
  /// 인접한 모음을 하나의 복합 모음으로 합친다.
  final chars = mixedConsonantLetters(input.split(''));

  /// 모음으로 시작하는 그룹들을 만든다.
  final items = makeGroupsUsingVowelLetters(chars);

  /// 각 그룹을 순회하면서 복합자음을 정리하고, 앞 그룹에서 종성으로 사용하고 남은 자음들을 초성으로 가져온다.
  final groups =
      mixedVowelLettersAndReplaceTheRemainingFinalesToInitials(items);

  /// 각 글자에 해당하는 블록 단위로 나눈 후 조합한다.
  return groupsJoining(groups);
}

String assemble(List<String> arr) {
  final startIndex = arr.indexWhere((e) => MEDIALS.indexOf(e) != -1);
  final endIndex =
      startIndex != -1 && MEDIALS.indexOf(arr[startIndex + 1]) != -1
          ? startIndex + 1
          : startIndex;

  // TODO(viiviii)
  if (startIndex == -1 || endIndex == -1) {
    return arr.first;
  }

  String initial = arr.sublist(0, startIndex).join('');
  String medial = arr.sublist(startIndex, endIndex + 1).join('');
  String finale = arr.sublist(endIndex + 1).join('');

  var initialOffset = INITIALS.indexOf(complexDict[initial] ?? initial);
  var medialOffset = MEDIALS.indexOf(complexDict[medial] ?? medial);
  var finaleOffset = FINALES.indexOf(complexDict[finale] ?? finale);

  if (initialOffset != -1 && medialOffset != -1) {
    return String.fromCharCode(BASE +
        initialOffset * (MEDIALS.length * FINALES.length) +
        medialOffset * FINALES.length +
        finaleOffset);
  }

  return arr.join('');
}

class Group {
  List<String> initials = [];
  final String? medial;
  List<String> finales = [];

  Group.empty() : medial = null;

  Group.fromMedial(this.medial);

  Group.of(this.initials, this.medial, this.finales);

  @override
  String toString() => '$runtimeType($initials, $medial, $finales)';
}

extension _<E> on List<E> {
  void forEachWithIndex(void action(E element, int index, List<E> array)) {
    final array = List<E>.unmodifiable(this);
    for (int index = 0; index < length; index++) {
      var element = this[index];
      action(element, index, array);
    }
  }

  void forEachFromNext(void f(E previousValue, E element)) {
    if (this.isEmpty) return;
    var previousValue = this.first;
    this.skip(1).forEach((element) {
      f(previousValue, element);
      previousValue = element;
    });
  }
}

/// 인접한 모음을 하나의 복합 모음으로 합친다.
// TODO(viiviii): MIXED 상수를 자음, 모음 분리해서 바로 찾는게 좋지 않을까?
List<String> mixedConsonantLetters(List<String> inputs) {
  final chars = [inputs.first];
  inputs.forEachFromNext((previous, current) {
    if (isMedial(previous) &&
        isMedial(current) &&
        complexDict['$previous$current'] != null) {
      chars.last = complexDict['$previous$current']!;
    } else {
      chars.add(current);
    }
  });
  return chars;
}

/// 해당 글자가 중성인지
bool isMedial(String text) => MEDIALS.contains(text);

/// 모음으로 시작하는 그룹들을 만든다.
List<Group> makeGroupsUsingVowelLetters(List<String> chars) {
  Group cursor = Group.empty();
  final items = [cursor];
  chars.forEach((char) {
    if (isMedial(char)) {
      cursor = Group.fromMedial(char);
      items.add(cursor);
    } else {
      cursor.finales.add(char);
    }
  });
  return items;
}

List<Group> mixedVowelLettersAndReplaceTheRemainingFinalesToInitials(
    List<Group> inputs) {
  final items = List.of(inputs);
  items.forEachWithIndex((curr, i, arr) {
    if (i > 0) {
      final prev = arr[i - 1];
      if (prev.medial == null || prev.finales.length == 1) {
        curr.initials = prev.finales;
        prev.finales = [];
      } else {
        final finale = prev.finales.isNotEmpty ? prev.finales.first : null;
        final initials = prev.finales.skip(1).toList();
        curr.initials = initials;
        prev.finales = finale != null ? [finale] : [];
      }
    }
  });

  final result = mixedFinales(items);
  return result;
}

/// TODO(viiviii): 나중에 mixedConsonantLetters()와 쌍으로 맞출 수 있을까?
/// 종성에서 인접한 자음을 하나의 복합 종성으로 합친다.
List<Group> mixedFinales(List<Group> inputs) {
  final items = List.of(inputs);
  items.forEachWithIndex((curr, i, arr) {
    if (curr.finales.length > 2 ||
        (i == items.length - 1 && curr.finales.length > 1)) {
      final a = curr.finales.first;
      final b = curr.finales.elementAt(1);
      final rest = curr.finales.skip(2);
      final complex = complexDict['$a$b'];
      if (complex != null) {
        curr.finales = [complex, ...rest];
      }
    }
  });
  return items;
}

/// 각 글자에 해당하는 블록 단위로 나눈 후 조합한다.
String groupsJoining(List<Group> items) {
  final List<List<String>> groups = [];
  items.forEach((e) {
    final initials = e.initials;
    final medial = e.medial;
    final finales = e.finales;

    final List<String> pre = List.of(initials);
    final String? initial = pre.isNotEmpty ? pre.removeLast() : null;
    String? finale = finales.isNotEmpty ? finales.first : null;
    List<String?> post = finales.skip(1).toList();

    if (finale == null || FINALES.indexOf(finale) == -1) {
      post = [finale, ...post];
      finale = '';
    }
    pre.whereNotNull().forEach((e) => groups.add([e]));
    groups.add([initial, medial, finale].whereNotNull().toList());
    post.whereNotNull().forEach((e) => groups.add([e]));
  });

  return groups.map(assemble).join('');
}
