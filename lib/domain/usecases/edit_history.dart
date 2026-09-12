// SPDX-License-Identifier: GPL-3.0-or-later

/// Undo and redo stacks for the route editor (spec Phase 3: undo stack of 20,
/// Addendum A4.3: Undo and Redo on the edit toolbar). Snapshots are whole
/// waypoint lists; [T] stays opaque here so this is a pure, testable value.
class EditHistory<T> {
  EditHistory({this.capacity = 20});

  final int capacity;
  final _undo = <T>[];
  final _redo = <T>[];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Records [snapshot] (the state before a change) and drops any redo
  /// history, since a new edit forks the timeline.
  void push(T snapshot) {
    _undo.add(snapshot);
    if (_undo.length > capacity) _undo.removeAt(0);
    _redo.clear();
  }

  /// Returns the state to restore, remembering [current] for redo; null when
  /// there is nothing to undo.
  T? undo(T current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  /// Returns the state to restore, remembering [current] for undo; null when
  /// there is nothing to redo.
  T? redo(T current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    if (_undo.length > capacity) _undo.removeAt(0);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
