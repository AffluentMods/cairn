// SPDX-License-Identifier: GPL-3.0-or-later
import 'package:cairn/domain/usecases/edit_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('undo and redo walk the timeline', () {
    final h = EditHistory<String>();
    expect(h.canUndo, isFalse);
    expect(h.canRedo, isFalse);
    h.push('a'); // state was "a", now "b"
    h.push('b'); // now "c"
    expect(h.undo('c'), 'b');
    expect(h.canRedo, isTrue);
    expect(h.undo('b'), 'a');
    expect(h.undo('a'), isNull);
    expect(h.redo('a'), 'b');
    expect(h.redo('b'), 'c');
    expect(h.redo('c'), isNull);
    expect(h.canUndo, isTrue);
  });

  test('a new edit after undo drops the redo branch', () {
    final h = EditHistory<int>();
    h.push(1);
    h.push(2);
    expect(h.undo(3), 2);
    h.push(2); // new edit from state 2
    expect(h.canRedo, isFalse);
    expect(h.undo(4), 2);
  });

  test('the undo stack is capped', () {
    final h = EditHistory<int>(capacity: 3);
    for (var i = 0; i < 10; i++) {
      h.push(i);
    }
    expect(h.undo(10), 9);
    expect(h.undo(9), 8);
    expect(h.undo(8), 7);
    expect(h.undo(7), isNull);
  });

  test('clear forgets both stacks', () {
    final h = EditHistory<int>();
    h.push(1);
    h.undo(2);
    h.clear();
    expect(h.canUndo, isFalse);
    expect(h.canRedo, isFalse);
  });
}
