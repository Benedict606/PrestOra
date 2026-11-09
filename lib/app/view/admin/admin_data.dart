import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/firebase/fb.dart';
import 'package:prestora/data/services/session.dart';

// ═══════════════════════════════════════════════════════════════
//  Modèles + dépôt de l'espace Administrateur (Firestore).
//  AdminStore garde la même interface qu'avant (listes + méthodes),
//  mais ses données viennent maintenant de Firestore en temps réel.
// ═══════════════════════════════════════════════════════════════

const kGrades = <String>[
  'Assistant',
  'Chef de Travaux',
  'Professeur Associé',
  'Professeur',
  'Professeur Ordinaire',
];

const kTitres = <String>['Pr', 'Dr', 'M.', 'Mme'];

String fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String fmtTaux(double v) => '${v.toStringAsFixed(v % 1 == 0 ? 0 : 2)} \$/h';

// ───────────────────────── Types de compte ─────────────────────────
enum TypeCompte {
  chefPromotion('Chef de promotion', 'CHEF_PROMOTION'),
  encadreur('Encadreur pédagogique', 'ENCADREUR'),
  enseignant('Enseignant visiteur', 'ENSEIGNANT'),
  secretaire('Secrétaire de faculté', 'SECRETAIRE'),
  doyen('Doyen', 'DOYEN'),
  vra('Vice-recteur académique', 'VRA'),
  recteur('Recteur', 'RECTEUR'),
  ag('Administrateur général', 'AG'),
  comptabilite('Comptabilité', 'COMPTABILITE'),
  administrateur('Administrateur système', 'ADMIN');

  const TypeCompte(this.label, this.code);
  final String label;

  /// Valeur stockée dans Firestore (`type_utilisateur`).
  final String code;

  static TypeCompte? fromCode(String? c) {
    for (final t in TypeCompte.values) {
      if (t.code == c) return t;
    }
    return null;
  }

  /// Rôles globaux : aucune faculté associée.
  bool get isGlobal => const [
    TypeCompte.vra,
    TypeCompte.recteur,
    TypeCompte.ag,
    TypeCompte.comptabilite,
    TypeCompte.administrateur,
  ].contains(this);

  bool get needsFaculte => !isGlobal;
  bool get needsPromotion => this == TypeCompte.chefPromotion;
  bool get isEnseignant => this == TypeCompte.enseignant;
}

// ───────────────────────── Modèles ─────────────────────────
class Compte {
  Compte({
    required this.id,
    required this.nom,
    required this.email,
    required this.type,
    this.titre = '',
    this.telephone = '',
    this.faculte,
    this.promotion,
    this.faculteId,
    this.promotionId,
    this.grade,
    this.institution,
    this.modePaiement,
    this.coordonneesPaiement,
    this.actif = true,
    this.gereAnnees = false,
  });

  final String id; // = uid Firebase Auth
  String nom;
  String email;
  String titre;
  String telephone;
  TypeCompte type;
  String? faculte; // nom (résolu depuis faculteId)
  String? promotion; // nom (résolu depuis promotionId)
  String? faculteId;
  String? promotionId;
  String? grade;
  String? institution;
  String? modePaiement; // « Banque » ou « Mobile Money » (sous-collection)
  String? coordonneesPaiement;
  bool actif;
  bool gereAnnees; // peut_gerer_annees

  String get nomComplet => titre.isEmpty ? nom : '$titre $nom';

  String get initiales {
    final parts = nom.trim().split(RegExp(r'\s+'));
    final a = parts.first.isNotEmpty ? parts.first[0] : '';
    final b = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (a + b).toUpperCase();
  }

  /// Met à jour cet objet depuis un document (identité d'objet conservée).
  void applyMap(Map<String, dynamic> m) {
    nom = (m['nom'] as String?) ?? '';
    email = (m['email'] as String?) ?? '';
    titre = (m['titre'] as String?) ?? '';
    telephone = (m['telephone'] as String?) ?? '';
    type = TypeCompte.fromCode(m['type_utilisateur'] as String?) ?? type;
    faculteId = m['faculte_id'] as String?;
    promotionId = m['promotion_id'] as String?;
    grade = m['grade_statutaire'] as String?;
    institution = m['institution_origine'] as String?;
    actif = m['est_actif'] == true;
    gereAnnees = m['peut_gerer_annees'] == true;
  }

  factory Compte.fromMap(String id, Map<String, dynamic> m) {
    final c = Compte(
      id: id,
      nom: '',
      email: '',
      type:
          TypeCompte.fromCode(m['type_utilisateur'] as String?) ??
          TypeCompte.enseignant,
    );
    c.applyMap(m);
    return c;
  }

  Map<String, dynamic> toMap() => {
    'nom': nom,
    'email': email,
    'titre': titre,
    'telephone': telephone,
    'type_utilisateur': type.code,
    'est_actif': actif,
    'faculte_id': type.needsFaculte ? faculteId : null,
    'promotion_id': type.needsPromotion ? promotionId : null,
    'grade_statutaire': type.isEnseignant ? grade : null,
    'institution_origine': type.isEnseignant ? institution : null,
    'peut_gerer_annees': gereAnnees,
  };
}

class Promotion {
  Promotion({
    this.id = '',
    required this.nom,
    this.chef,
    this.nbCours = 0,
    this.faculteId = '',
    this.departementId = '',
  });
  final String id;
  String nom;
  String? chef;
  int nbCours;
  String faculteId;
  String departementId;
}

class Departement {
  Departement({
    this.id = '',
    required this.nom,
    List<Promotion>? promotions,
    this.faculteId = '',
  }) : promotions = promotions ?? [];
  final String id;
  String nom;
  String faculteId;
  final List<Promotion> promotions;
}

class Faculte {
  Faculte({
    this.id = '',
    required this.nom,
    required this.departements,
    this.doyen,
    this.secretaire,
  });
  final String id;
  String nom;
  String? doyen;
  String? secretaire;
  final List<Departement> departements;

  Iterable<Promotion> get promotions =>
      departements.expand((d) => d.promotions);
}

class Cours {
  Cours({
    this.id = '',
    required this.code,
    required this.intitule,
    required this.faculte,
    required this.promotion,
    required this.credits,
    required this.volume,
    this.affecte = false,
    this.faculteId = '',
    this.promotionId = '',
  });
  final String id;
  String code;
  String intitule;
  String faculte; // nom
  String promotion; // nom
  String faculteId;
  String promotionId;
  int credits;
  int volume;
  bool affecte; // vrai si suivi dans l'année active
}

class Bareme {
  Bareme({required this.grade, required this.taux});
  final String grade;
  double taux;
}

// ───────────────────────── Dépôt Firestore ─────────────────────────
class AdminStore extends ChangeNotifier {
  /// Compte connecté (ne peut pas se désactiver lui-même).
  String get currentUserId => Session.instance.me?.id ?? '';

  double? retenueFiscale; // % : « À définir » tant que null

  final List<String> historiqueBaremes = [];
  final List<Compte> comptes = [];
  final List<Faculte> facultes = [];
  final List<Cours> cours = [];
  final List<Bareme> baremes = [
    for (final g in kGrades) Bareme(grade: g, taux: 0),
  ];

  bool loaded = false;

  // Objets stables (identité conservée entre deux snapshots).
  final _fObj = <String, Faculte>{};
  final _dObj = <String, Departement>{};
  final _pObj = <String, Promotion>{};
  final _cObj = <String, Cours>{};
  final _uObj = <String, Compte>{};

  // Documents bruts du dernier snapshot de chaque collection.
  Map<String, Map<String, dynamic>> _rFac = {};
  Map<String, Map<String, dynamic>> _rDep = {};
  Map<String, Map<String, dynamic>> _rPro = {};
  Map<String, Map<String, dynamic>> _rCou = {};
  Map<String, Map<String, dynamic>> _rUsr = {};
  Map<String, Map<String, dynamic>> _rBar = {};
  final Set<String> _affectes = {};

  final List<StreamSubscription<dynamic>> _subs = [];
  StreamSubscription<dynamic>? _sessSub;
  String? _sessAnnee;
  bool _started = false;

  FirebaseFirestore get _db => Fb.db;

  // ───────────── Cycle de vie ─────────────
  void start() {
    if (_started) return;
    _started = true;

    void listen(
      String col,
      void Function(Map<String, Map<String, dynamic>>) assign,
    ) {
      _subs.add(
        _db
            .collection(col)
            .snapshots()
            .listen(
              (s) {
                assign({for (final d in s.docs) d.id: d.data()});
                _rebuild();
              },
              onError: (Object e) => Notif.erreur('Lecture de $col : $e'),
            ),
      );
    }

    listen(Col.facultes, (m) => _rFac = m);
    listen(Col.departements, (m) => _rDep = m);
    listen(Col.promotions, (m) => _rPro = m);
    listen(Col.cours, (m) => _rCou = m);
    listen(Col.utilisateurs, (m) => _rUsr = m);
    listen(Col.baremes, (m) => _rBar = m);

    _subs.add(
      _db
          .collection(Col.parametres)
          .doc('retenue_fiscale')
          .snapshots()
          .listen((d) {
            retenueFiscale = (d.data()?['pourcentage'] as num?)?.toDouble();
            notifyListeners();
          }, onError: (Object e) => debugPrint('retenue: $e')),
    );

    Session.instance.addListener(_onSession);
    _onSession();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    for (final s in _subs) {
      s.cancel();
    }
    _subs.clear();
    _sessSub?.cancel();
    _sessSub = null;
    _sessAnnee = null;
    Session.instance.removeListener(_onSession);
    comptes.clear();
    facultes.clear();
    cours.clear();
    _fObj.clear();
    _dObj.clear();
    _pObj.clear();
    _cObj.clear();
    _uObj.clear();
    loaded = false;
    notifyListeners();
  }

  void _onSession() {
    final id = Session.instance.active?.id;
    if (id == _sessAnnee) return;
    _sessAnnee = id;
    _sessSub?.cancel();
    _sessSub = null;
    _affectes.clear();
    if (id == null) {
      _rebuild();
      return;
    }
    _sessSub = _db
        .collection(Col.sessions)
        .where('annee_id', isEqualTo: id)
        .snapshots()
        .listen((s) {
          _affectes
            ..clear()
            ..addAll(
              s.docs.map((d) => (d.data()['cours_id'] as String?) ?? ''),
            );
          _rebuild();
        }, onError: (Object e) => debugPrint('sessions: $e'));
  }

  // ───────────── Reconstruction des objets ─────────────
  void _rebuild() {
    // Facultés
    _fObj.removeWhere((id, _) => !_rFac.containsKey(id));
    for (final e in _rFac.entries) {
      final f = _fObj.putIfAbsent(
        e.key,
        () => Faculte(id: e.key, nom: '', departements: []),
      );
      f.nom = (e.value['nom_faculte'] as String?) ?? '';
      f.departements.clear();
    }
    // Départements
    _dObj.removeWhere((id, _) => !_rDep.containsKey(id));
    for (final e in _rDep.entries) {
      final d = _dObj.putIfAbsent(e.key, () => Departement(id: e.key, nom: ''));
      d.nom = (e.value['nom'] as String?) ?? '';
      d.faculteId = (e.value['faculte_id'] as String?) ?? '';
      d.promotions.clear();
    }
    // Promotions
    _pObj.removeWhere((id, _) => !_rPro.containsKey(id));
    for (final e in _rPro.entries) {
      final p = _pObj.putIfAbsent(e.key, () => Promotion(id: e.key, nom: ''));
      p.nom = (e.value['nom'] as String?) ?? '';
      p.faculteId = (e.value['faculte_id'] as String?) ?? '';
      p.departementId = (e.value['departement_id'] as String?) ?? '';
      p.chef = null;
      p.nbCours = 0;
      _dObj[p.departementId]?.promotions.add(p);
    }
    for (final d in _dObj.values) {
      d.promotions.sort((a, b) => a.nom.compareTo(b.nom));
      _fObj[d.faculteId]?.departements.add(d);
    }
    for (final f in _fObj.values) {
      f.departements.sort((a, b) => a.nom.compareTo(b.nom));
      f.doyen = null;
      f.secretaire = null;
    }

    // Comptes
    _uObj.removeWhere((id, _) => !_rUsr.containsKey(id));
    for (final e in _rUsr.entries) {
      final c = _uObj.putIfAbsent(
        e.key,
        () => Compte.fromMap(e.key, e.value),
      );
      c.applyMap(e.value);
      c.faculte = _fObj[c.faculteId]?.nom;
      c.promotion = _pObj[c.promotionId]?.nom;
      if (c.actif) {
        if (c.type == TypeCompte.chefPromotion) {
          _pObj[c.promotionId]?.chef = c.nom;
        } else if (c.type == TypeCompte.doyen) {
          _fObj[c.faculteId]?.doyen = c.nomComplet;
        } else if (c.type == TypeCompte.secretaire) {
          _fObj[c.faculteId]?.secretaire = c.nomComplet;
        }
      }
    }

    // Cours
    _cObj.removeWhere((id, _) => !_rCou.containsKey(id));
    for (final e in _rCou.entries) {
      if (e.value['est_archive'] == true) {
        _cObj.remove(e.key);
        continue;
      }
      final c = _cObj.putIfAbsent(
        e.key,
        () => Cours(
          id: e.key,
          code: '',
          intitule: '',
          faculte: '',
          promotion: '',
          credits: 0,
          volume: 0,
        ),
      );
      c.code = (e.value['code_cours'] as String?) ?? e.key;
      c.intitule = (e.value['intitule_exact'] as String?) ?? '';
      c.credits = (e.value['credits'] as num?)?.toInt() ?? 0;
      c.volume = (e.value['volume_horaire_max'] as num?)?.toInt() ?? 0;
      c.faculteId = (e.value['faculte_id'] as String?) ?? '';
      c.promotionId = (e.value['promotion_id'] as String?) ?? '';
      c.faculte = _fObj[c.faculteId]?.nom ?? '';
      c.promotion = _pObj[c.promotionId]?.nom ?? '';
      c.affecte = _affectes.contains(c.id);
      final p = _pObj[c.promotionId];
      if (p != null) p.nbCours++;
    }

    // Barèmes
    final histo = <(DateTime, String)>[];
    for (final b in baremes) {
      final raw = _rBar[b.grade];
      b.taux = (raw?['taux'] as num?)?.toDouble() ?? 0;
      for (final h in (raw?['historique'] as List?) ?? const []) {
        if (h is Map) {
          histo.add((
            Fb.date(h['date']) ?? DateTime(2000),
            (h['texte'] as String?) ?? '',
          ));
        }
      }
    }
    histo.sort((a, b) => b.$1.compareTo(a.$1));
    historiqueBaremes
      ..clear()
      ..addAll(histo.map((h) => h.$2));

    // Listes publiques triées
    facultes
      ..clear()
      ..addAll(_fObj.values.toList()..sort((a, b) => a.nom.compareTo(b.nom)));
    comptes
      ..clear()
      ..addAll(_uObj.values.toList()..sort((a, b) => a.nom.compareTo(b.nom)));
    cours
      ..clear()
      ..addAll(_cObj.values.toList()..sort((a, b) => a.code.compareTo(b.code)));

    loaded = true;
    notifyListeners();
  }

  // ── Compteurs du hub ──
  int get comptesActifs => comptes.where((c) => c.actif).length;
  int get comptesInactifs => comptes.length - comptesActifs;

  // ── Aides ──
  List<String> promotionsOf(String? faculteNom) {
    final f = facultes.where((f) => f.nom == faculteNom);
    if (f.isEmpty) return [];
    return f.first.promotions.map((p) => p.nom).toList();
  }

  int coursOf(String faculteNom) =>
      cours.where((c) => c.faculte == faculteNom).length;

  Faculte? faculteByNom(String? nom) =>
      facultes.where((f) => f.nom == nom).firstOrNull;

  Promotion? promotionByNom(String? faculteNom, String? nom) =>
      faculteByNom(faculteNom)?.promotions.where((p) => p.nom == nom).firstOrNull;

  // ───────────── Écritures ─────────────
  /// Exécute une écriture ; affiche l'erreur et retourne false en cas d'échec.
  Future<bool> _w(Future<dynamic> Function() f) async {
    try {
      await f();
      return true;
    } catch (e) {
      Notif.erreur(e);
      return false;
    }
  }

  Future<bool> toggleCompte(Compte c) =>
      _w(() => _db.collection(Col.utilisateurs).doc(c.id).update({
            'est_actif': !c.actif,
          }));

  /// Résout faculte/promotion (noms) en identifiants avant l'enregistrement.
  void _resoudreIds(Compte c) {
    c.faculteId = c.type.needsFaculte ? faculteByNom(c.faculte)?.id : null;
    c.promotionId = c.type.needsPromotion
        ? promotionByNom(c.faculte, c.promotion)?.id
        : null;
  }

  /// Crée le profil d'un compte dont l'utilisateur Auth existe déjà.
  Future<bool> createCompte(Compte c) => _w(() async {
        _resoudreIds(c);
        await _db.collection(Col.utilisateurs).doc(c.id).set({
          ...c.toMap(),
          'cree_le': FieldValue.serverTimestamp(),
        });
        await _savePaiement(c);
      });

  Future<bool> saveCompte(Compte c) => _w(() async {
        _resoudreIds(c);
        await _db.collection(Col.utilisateurs).doc(c.id).update(c.toMap());
        await _savePaiement(c);
      });

  Future<void> _savePaiement(Compte c) async {
    final ref = _db
        .collection(Col.utilisateurs)
        .doc(c.id)
        .collection(Col.paiement)
        .doc('infos');
    if (c.type.isEnseignant) {
      await ref.set({
        'mode': c.modePaiement,
        'coordonnees': c.coordonneesPaiement,
      });
    }
  }

  /// Charge les coordonnées de paiement (sous-collection protégée).
  Future<void> chargerPaiement(Compte c) async {
    if (!c.type.isEnseignant) return;
    try {
      final d = await _db
          .collection(Col.utilisateurs)
          .doc(c.id)
          .collection(Col.paiement)
          .doc('infos')
          .get();
      c.modePaiement = d.data()?['mode'] as String?;
      c.coordonneesPaiement = d.data()?['coordonnees'] as String?;
    } catch (e) {
      debugPrint('paiement: $e');
    }
  }

  void touch() => notifyListeners();

  Future<bool> addFaculte(String nom) => _w(
        () => _db.collection(Col.facultes).add({
          'nom_faculte': nom,
          'cree_le': FieldValue.serverTimestamp(),
        }),
      );

  Future<bool> saveFaculte(Faculte f) => _w(
        () => _db.collection(Col.facultes).doc(f.id).update({
          'nom_faculte': f.nom,
        }),
      );

  Future<bool> addDepartement(Faculte f, String nom) => _w(
        () => _db.collection(Col.departements).add({
          'faculte_id': f.id,
          'nom': nom,
        }),
      );

  Future<bool> addPromotion(Departement d, String nom) => _w(
        () => _db.collection(Col.promotions).add({
          'faculte_id': d.faculteId,
          'departement_id': d.id,
          'nom': nom,
        }),
      );

  Map<String, dynamic> _coursMap(Cours c) {
    c.faculteId = faculteByNom(c.faculte)?.id ?? '';
    c.promotionId = promotionByNom(c.faculte, c.promotion)?.id ?? '';
    return {
      'code_cours': c.code,
      'intitule_exact': c.intitule,
      'credits': c.credits,
      'volume_horaire_max': c.volume,
      'faculte_id': c.faculteId,
      'faculte_nom': c.faculte,
      'promotion_id': c.promotionId,
      'promotion_nom': c.promotion,
      'est_archive': false,
    };
  }

  Future<bool> addCours(Cours c) => _w(
        () => _db.collection(Col.cours).doc(slug(c.code)).set({
          ..._coursMap(c),
          'cree_le': FieldValue.serverTimestamp(),
        }),
      );

  Future<bool> saveCours(Cours c) => _w(
        () => _db.collection(Col.cours).doc(c.id).update(_coursMap(c)),
      );

  Future<bool> setTaux(Bareme b, double nouveau, DateTime effet) => _w(() async {
        final avant = b.taux.toStringAsFixed(b.taux % 1 == 0 ? 0 : 2);
        final apres = nouveau.toStringAsFixed(nouveau % 1 == 0 ? 0 : 2);
        final texte = '${fmtDate(effet)} · ${b.grade} : $avant → $apres \$/h';
        await _db.collection(Col.baremes).doc(b.grade).set({
          'grade_statutaire': b.grade,
          'taux': nouveau,
          'date_effet': Fb.ts(effet),
          'historique': FieldValue.arrayUnion([
            {'date': Timestamp.now(), 'texte': texte},
          ]),
        }, SetOptions(merge: true));
      });

  Future<bool> setRetenue(double v) => _w(
        () => _db.collection(Col.parametres).doc('retenue_fiscale').set({
          'pourcentage': v,
          'date_effet': Timestamp.now(),
        }),
      );
}

/// Instance unique.
final AdminStore adminStore = AdminStore();
