import 'package:korea_regexp/src/constant.dart';

final complexDict = MIXED.map((k, v) => MapEntry(v.join(''), k));

// TODO(viiviii): 변수명
String implode(String input) {
  /// 인접한 모음을 하나의 복합 모음으로 합친다.
  final chars = mixedConsonantLetters(input.split(''));

  /// 모음으로 시작하는 그룹들을 만든다.
  final items = makeGroupsUsingVowelLetters(chars);

  /// 각 그룹을 순회하면서 복합자음을 정리하고, 앞 그룹에서 종성으로 사용하고 남은 자음들을 초성으로 가져온다.
  final items2 = mixFinalesAndReplaceTheRemainingFinalesToInitials(items);

  /// 각 글자에 해당하는 블록 단위로 나눈다.
  final List<List<String>> items4 = groupsJoining(items2);

  return items4.map(assemble).join('');
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
    return arr.join('');
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

// TODO(viiviii): immutable하게 변경할 수 있을까?
class Group {
  List<String> initials = [];
  final String? medial;
  List<String> finales = [];

  Group.empty() : medial = null;

  Group.fromMedial(this.medial);

  Group.of(this.initials, this.medial, this.finales);

  bool get hasMedial => medial?.isNotEmpty ?? false;

  List<String> get usedFinale => finales.take(1).toList();
  List<String> get unusedFinales => finales.skip(1).toList();

  /// 종성에서 인접한 자음을 하나의 복합 종성으로 합친다.
  void mixFinalesTheFirstTwoLetters() {
    final a = this.finales[0];
    final b = this.finales[1];
    final mix = complexDict['$a$b'];
    if (mix != null) {
      final rest = this.finales.skip(2);
      this.finales = [mix, ...rest];
    }
  }

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
bool isMedial(String? text) => MEDIALS.contains(text);

/// 해당 글자가 종성인지
bool isFinale(String? text) => FINALES.contains(text);

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

/// 각 그룹을 순회하면서 복합자음을 정리하고, 앞 그룹에서 종성으로 사용하고 남은 자음들을 초성으로 가져온다.
List<Group> mixFinalesAndReplaceTheRemainingFinalesToInitials(
    List<Group> groups) {
  final items = List.of(groups);
  items.forEachFromNext((prev, curr) {
    if (!prev.hasMedial || prev.finales.length == 1) {
      curr.initials = prev.finales;
      prev.finales = [];
    } else {
      curr.initials = prev.unusedFinales;
      prev.finales = prev.usedFinale;
    }

    /// TODO(viiviii): 왜 종성이 세 글자이거나 마지막 글자의 종성일 때만 합칠까? 그냥 2개 이상이면 합치면 안되나?
    if (curr.finales.length > 2 ||
        (curr == items.last && curr.finales.length > 1)) {
      curr.mixFinalesTheFirstTwoLetters();
    }
  });
  return items;
}

/// 각 글자에 해당하는 블록 단위로 나눈다.
List<List<String>> groupsJoining(List<Group> groups) {
  final List<List<String>> result = [];
  groups.forEach((e) {
    final medial = e.medial ?? '';

    List<String> pre = e.initials;
    List<String> post = e.finales;

    String initial = '';
    String finale = '';

    if (pre.isNotEmpty) {
      initial = pre.last;
      pre = pre.sublist(0, pre.length - 1);
    }

    if (post.isNotEmpty && isFinale(post.first)) {
      finale = post.first;
      post = post.skip(1).toList();
    }

    pre.where((e) => e.isNotEmpty).forEach((e) => result.add([e]));
    result.add([initial, medial, finale].where((e) => e.isNotEmpty).toList());
    post.where((e) => e.isNotEmpty).forEach((e) => result.add([e]));
  });
  return result;
}
