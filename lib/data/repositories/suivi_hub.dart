import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';

/// Synchronise en temps réel un ensemble de sessions de suivi (cours suivis)
/// et leurs séances. Les objets [CoursSuivi] / [Seance] gardent leur identité
/// d'un snapshot à l'autre : les pages qui les détiennent restent à jour.
class SuiviHub {
  SuiviHub({required this.onChange});
  final VoidCallback onChange;

  final Map<String, CoursSuivi> _cours = {};
  final Map<String, Map<String, Seance>> _seances = {};
  final Map<String, StreamSubscription<dynamic>> _seanceSubs = {};
  StreamSubscription<dynamic>? _sessionsSub;

  List<CoursSuivi> get cours {
    final l = _cours.values.toList()..sort((a, b) => a.code.compareTo(b.code));
    return l;
  }

  CoursSuivi? parCours(String coursId) {
    for (final c in _cours.values) {
      if (c.coursId == coursId) return c;
    }
    return null;
  }

  void watch(Query<Map<String, dynamic>> q) {
    stop(notify: false);
    _sessionsSub = q.snapshots().listen(
      (snap) {
        final ids = snap.docs.map((d) => d.id).toSet();
        for (final id in _cours.keys.where((k) => !ids.contains(k)).toList()) {
          _cours.remove(id);
          _seances.remove(id);
          _seanceSubs.remove(id)?.cancel();
        }
        for (final d in snap.docs) {
          final c = _cours.putIfAbsent(
            d.id,
            () => CoursSuivi(
              code: '',
              intitule: '',
              enseignant: '',
              grade: '',
              credits: 0,
              volume: 0,
            ),
          );
          c.applyMap(d.id, d.data());
          _seanceSubs.putIfAbsent(
            d.id,
            () => d.reference
                .collection(Col.seances)
                .snapshots()
                .listen(
                  (ss) => _syncSeances(d.id, ss),
                  onError: (Object e) => debugPrint('séances ${d.id}: $e'),
                ),
          );
        }
        onChange();
      },
      onError: (Object e) {
        Notif.erreur('Lecture du suivi : $e');
      },
    );
  }

  void _syncSeances(String sessionId, QuerySnapshot<Map<String, dynamic>> ss) {
    final c = _cours[sessionId];
    if (c == null) return;
    final objs = _seances.putIfAbsent(sessionId, () => {});
    final ids = ss.docs.map((d) => d.id).toSet();
    objs.removeWhere((id, _) => !ids.contains(id));
    for (final d in ss.docs) {
      final s = objs.putIfAbsent(
        d.id,
        () => Seance(
          id: d.id,
          date: DateTime.now(),
          debut: const TimeOfDay(hour: 8, minute: 0),
          fin: const TimeOfDay(hour: 9, minute: 0),
          chapitre: '',
        ),
      );
      s.applyMap(d.data());
    }
    c.seances
      ..clear()
      ..addAll(
        objs.values.toList()..sort((a, b) {
          final x = a.date.compareTo(b.date);
          return x != 0 ? x : minutesOf(a.debut).compareTo(minutesOf(b.debut));
        }),
      );
    onChange();
  }

  void stop({bool notify = true}) {
    _sessionsSub?.cancel();
    _sessionsSub = null;
    for (final s in _seanceSubs.values) {
      s.cancel();
    }
    _seanceSubs.clear();
    _cours.clear();
    _seances.clear();
    if (notify) onChange();
  }
}
