import 'package:flutter/material.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/prestation/student/etudiant_modules.dart';

// Widgets partagés (Admin / Étudiant). À déplacer dans un dossier commun plus tard.

import 'encadreur_data.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Pastille de statut d'un cours côté encadreur.
class EncStatutPill extends StatelessWidget {
  const EncStatutPill(this.statut, {super.key});
  final StatutEnc statut;

  @override
  Widget build(BuildContext context) => StatusPill(
    statut.label,
    tone: switch (statut) {
      StatutEnc.nonAffecte => PillTone.danger,
      StatutEnc.enCours || StatutEnc.valideParEnseignant => PillTone.brand,
      StatutEnc.cloture => PillTone.neutral,
    },
  );
}

/// Valide (clôture) un cours après confirmation. Partagé par ENC-02 et ENC-04.
Future<void> cloturerCours(BuildContext context, CoursEnc c) async {
  final ok = await confirmDialog(
    context,
    title: 'Valider le cours ?',
    message:
        '${c.code} sera clôturé et verrouillé. Le dossier est envoyé au secrétaire de la faculté.',
    confirmLabel: 'Valider le cours',
  );
  if (!ok || !context.mounted) return;
  encadreurStore.cloturer(c);
  _snack(context, 'Cours clôturé. Le secrétaire de la faculté a été notifié.');
}

/// Affiche la feuille d'affectation (ENC-03).
void affecterCours(BuildContext context, CoursEnc c, PromotionEnc p) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AffecterSheet(cours: c, promotion: p),
  );
}

// ═══════════════════════════════════════════════════════════════
//  ENC-02 · Détail d'une promotion : liste des cours
// ═══════════════════════════════════════════════════════════════
enum _Filtre { tous, nonAffectes, enCours, aCloturer, clotures }

class PromotionDetailPage extends StatefulWidget {
  const PromotionDetailPage({super.key, required this.promotion});
  final PromotionEnc promotion;

  @override
  State<PromotionDetailPage> createState() => _PromotionDetailPageState();
}

class _PromotionDetailPageState extends State<PromotionDetailPage> {
  _Filtre _f = _Filtre.tous;

  bool _match(CoursEnc c) => switch (_f) {
    _Filtre.tous => true,
    _Filtre.nonAffectes => c.statut == StatutEnc.nonAffecte,
    _Filtre.enCours => c.statut == StatutEnc.enCours,
    _Filtre.aCloturer => c.statut == StatutEnc.valideParEnseignant,
    _Filtre.clotures => c.statut == StatutEnc.cloture,
  };

  @override
  Widget build(BuildContext context) {
    final p = widget.promotion;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return AdminScaffold(
      title: p.nom,
      body: ListenableBuilder(
        listenable: encadreurStore,
        builder: (context, _) {
          final list = p.cours.where(_match).toList();
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── En-tête de la promotion ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nom, style: t.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        'Faculté ${encadreurStore.faculte} · Département ${p.departement}',
                        style: t.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Text('Chef de promotion : ', style: t.bodySmall),
                          Text(
                            p.chef ?? 'non assigné',
                            style: t.titleSmall?.copyWith(
                              color: p.chef == null ? scheme.error : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill('${p.cours.length} cours'),
                          StatusPill(
                            '${p.nonSuivis} à affecter',
                            tone: p.nonSuivis > 0
                                ? PillTone.danger
                                : PillTone.neutral,
                          ),
                          StatusPill(
                            '${p.aCloturer} à clôturer',
                            tone: p.aCloturer > 0
                                ? PillTone.brand
                                : PillTone.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PillRow(
                children: [
                  FilterPill(
                    label: 'Tous',
                    selected: _f == _Filtre.tous,
                    onTap: () => setState(() => _f = _Filtre.tous),
                  ),
                  FilterPill(
                    label: 'Non affectés',
                    selected: _f == _Filtre.nonAffectes,
                    onTap: () => setState(() => _f = _Filtre.nonAffectes),
                  ),
                  FilterPill(
                    label: 'En cours',
                    selected: _f == _Filtre.enCours,
                    onTap: () => setState(() => _f = _Filtre.enCours),
                  ),
                  FilterPill(
                    label: 'À clôturer',
                    selected: _f == _Filtre.aCloturer,
                    onTap: () => setState(() => _f = _Filtre.aCloturer),
                  ),
                  FilterPill(
                    label: 'Clôturés',
                    selected: _f == _Filtre.clotures,
                    onTap: () => setState(() => _f = _Filtre.clotures),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const EmptyState(message: 'Aucun cours dans cette catégorie.')
              else
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CoursEncCard(
                      cours: c,
                      onTap: c.suivi == null
                          ? () => _snack(
                              context,
                              "Affectez d'abord un enseignant à ce cours.",
                            )
                          : () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    CoursEncPage(cours: c, promotion: p),
                              ),
                            ),
                      onAffecter: () => affecterCours(context, c, p),
                      onValider: () => cloturerCours(context, c),
                    ),
                  ),
              SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }
}

class _CoursEncCard extends StatelessWidget {
  const _CoursEncCard({
    required this.cours,
    required this.onTap,
    required this.onAffecter,
    required this.onValider,
  });
  final CoursEnc cours;
  final VoidCallback onTap;
  final VoidCallback onAffecter;
  final VoidCallback onValider;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = cours.suivi;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    cours.code,
                    style: t.titleSmall?.copyWith(color: scheme.primary),
                  ),
                  const Spacer(),
                  EncStatutPill(cours.statut),
                ],
              ),
              const SizedBox(height: 6),
              Text(cours.intitule, style: t.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${s?.enseignant ?? 'Aucun enseignant'} · ${cours.credits} crédits · ${cours.volume} h',
                style: t.bodySmall,
              ),
              if (s != null) ...[
                const SizedBox(height: 16),
                HeuresProgress(cours: s),
              ],
              if (cours.statut == StatutEnc.nonAffecte) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAffecter,
                    icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                    label: const Text('Affecter à un enseignant'),
                  ),
                ),
              ],
              if (cours.statut == StatutEnc.valideParEnseignant) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onValider,
                    icon: const Icon(Icons.task_alt, size: 18),
                    label: const Text('Valider le cours'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ENC-03 · Affecter un cours à un enseignant (feuille modale)
// ═══════════════════════════════════════════════════════════════
class AffecterSheet extends StatefulWidget {
  const AffecterSheet({
    super.key,
    required this.cours,
    required this.promotion,
  });
  final CoursEnc cours;
  final PromotionEnc promotion;

  @override
  State<AffecterSheet> createState() => _AffecterSheetState();
}

class _AffecterSheetState extends State<AffecterSheet> {
  String _q = '';
  EnseignantFictif? _choisi;

  void _affecter() {
    final e = _choisi;
    if (e == null) return;
    final messenger = ScaffoldMessenger.of(context);
    encadreurStore.affecter(widget.cours, e);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          "${widget.cours.code} affecté à ${e.nom}. L'enseignant et le chef de promotion sont notifiés.",
        ),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = widget.cours;
    final q = _q.toLowerCase();
    final liste = encadreurStore.enseignants
        .where(
          (e) =>
              q.isEmpty ||
              e.nom.toLowerCase().contains(q) ||
              e.email.toLowerCase().contains(q),
        )
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Affecter le cours', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text('${c.code} · ${c.intitule}', style: t.bodySmall),
            const SizedBox(height: 20),

            Text('ENSEIGNANT VISITEUR', style: t.labelSmall),
            const SizedBox(height: 8),
            SearchBox(
              hint: 'Rechercher un nom ou un email',
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 12),
            if (liste.isEmpty)
              const EmptyState(message: 'Aucun enseignant trouvé.')
            else
              for (final e in liste)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: _choisi == e
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _choisi == e ? scheme.primary : scheme.outline,
                      ),
                    ),
                    child: InkWell(
                      customBorder: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () => setState(() => _choisi = e),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.nom, style: t.titleSmall),
                                  Text(e.email, style: t.bodySmall),
                                  const SizedBox(height: 6),
                                  StatusPill(e.grade),
                                ],
                              ),
                            ),
                            if (_choisi == e)
                              Icon(Icons.check_circle, color: scheme.primary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Info('Charge horaire', '${c.volume} h (volume du cours)'),
                    const Divider(height: 20),
                    _Info(
                      'Chef de promotion',
                      widget.promotion.chef ?? 'non assigné',
                    ),
                    const Divider(height: 20),
                    _Info('Année académique', encadreurStore.anneeAcademique),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _choisi == null
                    ? null
                    : _affecter, // désactivé tant qu'aucun enseignant n'est choisi
                child: const Text('Affecter'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 130, child: Text(label, style: t.bodySmall)),
        Expanded(child: Text(value, style: t.titleSmall)),
      ],
    );
  }
}

class SeanceCard extends StatelessWidget {
  const SeanceCard({
    super.key,
    required this.seance,
    required this.editable,
    required this.onEdit,
    required this.onDelete,
  });

  final Seance seance;
  final bool editable;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fmtJour(seance.date), style: t.titleSmall),
                  const SizedBox(height: 4),
                  Text('${fmtH(seance.heures)} prestées', style: t.bodySmall),
                  const SizedBox(height: 8),
                  StatusPill(
                    seance.validee ? 'Validée' : 'En attente',
                    tone: seance.validee ? PillTone.brand : PillTone.neutral,
                  ),
                ],
              ),
            ),
            if (editable) ...[
              IconButton(
                tooltip: 'Modifier',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: onDelete,
                color: scheme.error,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ENC-04 · Détail d'un cours : séances et clôture
// ═══════════════════════════════════════════════════════════════
class CoursEncPage extends StatelessWidget {
  const CoursEncPage({super.key, required this.cours, required this.promotion});
  final CoursEnc cours;
  final PromotionEnc promotion;

  void _editSeance(BuildContext context, Seance seance) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SeanceForm(cours: cours.suivi!, seance: seance),
    );
  }

  Future<void> _deleteSeance(BuildContext context, Seance seance) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer la séance ?',
      message:
          'La séance du ${fmtJour(seance.date)} (${fmtH(seance.heures)}) sera supprimée.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (ok) encadreurStore.deleteSeance(cours, seance);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: encadreurStore,
      builder: (context, _) {
        final s = cours.suivi!;
        final seances = [...s.seances]
          ..sort((a, b) => b.date.compareTo(a.date));
        final lecture = s.cloture;
        final peutValider = cours.statut == StatutEnc.valideParEnseignant;

        // Pourquoi le bouton est désactivé
        String? raison;
        if (!peutValider && !lecture) {
          if (s.heuresPrestees < s.volume) {
            raison =
                'Volume horaire non atteint : il reste ${fmtH(s.heuresRestantes)} sur ${s.volume} h.';
          } else {
            raison =
                "${s.nbEncodees} séance(s) pas encore validée(s) par l'enseignant.";
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(cours.code),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
          ),
          // Bouton principal fixe en bas
          bottomNavigationBar: lecture
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (raison != null) ...[
                          Text(
                            raison,
                            style: t.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: peutValider
                                ? () => cloturerCours(context, cours)
                                : null,
                            icon: const Icon(Icons.task_alt, size: 18),
                            label: const Text('Valider le cours'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── En-tête ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                cours.code,
                                style: t.titleSmall?.copyWith(
                                  color: scheme.primary,
                                ),
                              ),
                              const Spacer(),
                              EncStatutPill(cours.statut),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(cours.intitule, style: t.headlineLarge),
                          const SizedBox(height: 12),
                          _Info('Enseignant', '${s.enseignant} · ${s.grade}'),
                          const SizedBox(height: 8),
                          _Info(
                            'Chef de promotion',
                            promotion.chef ?? 'non assigné',
                          ),
                          const SizedBox(height: 8),
                          _Info('Promotion', promotion.nom),
                          const SizedBox(height: 16),
                          HeuresProgress(cours: s),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              StatusPill('${s.seances.length} encodée(s)'),
                              StatusPill(
                                '${s.nbValidees} validée(s)',
                                tone: PillTone.brand,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (lecture) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: scheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Cours clôturé : le dossier a été transmis au secrétaire de la faculté.',
                                style: t.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  Text('Séances (${seances.length})', style: t.headlineMedium),
                  const SizedBox(height: 12),

                  if (seances.isEmpty)
                    const EmptyState(
                      message:
                          "Aucune séance encodée pour l'instant par le chef de promotion.",
                    ),

                  for (final seance in seances)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SeanceCard(
                        seance: seance,
                        editable:
                            !seance.validee &&
                            !lecture, // modifiable tant que l'enseignant n'a pas validé
                        onEdit: () => _editSeance(context, seance),
                        onDelete: () => _deleteSeance(context, seance),
                      ),
                    ),

                  // ── Outil de démo (à supprimer) ──
                  if (!lecture && s.nbEncodees > 0) ...[
                    const SizedBox(height: 20),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('OUTIL DE DÉMO', style: t.labelSmall),
                            const SizedBox(height: 8),
                            Text(
                              "Simule la validation de toutes les séances par l'enseignant.",
                              style: t.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                encadreurStore.simulerValidation(cours);
                                _snack(
                                  context,
                                  "L'enseignant a validé toutes les séances.",
                                );
                              },
                              icon: const Icon(
                                Icons.fact_check_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                "Simuler la validation de l'enseignant",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
