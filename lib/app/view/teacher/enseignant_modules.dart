import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/prestation/student/etudiant_modules.dart';

// Widgets partagés (Admin / Étudiant). À déplacer dans un dossier commun plus tard.
import '../admin/admin_modules.dart'
    show AdminScaffold, EmptyState, PillTone, StatusPill;

import 'enseignant_data.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Pastille du niveau actuel d'un dossier (ex. « Chez le Doyen »).
class DossierPill extends StatelessWidget {
  const DossierPill(this.dossier, {super.key});
  final DossierPaie dossier;

  @override
  Widget build(BuildContext context) => StatusPill(
    dossier.niveau,
    tone: switch (dossier.statut) {
      StatutDossier.paye => PillTone.brand,
      StatutDossier.rejete => PillTone.danger,
      StatutDossier.enAttente => PillTone.brand,
      StatutDossier.initialise => PillTone.neutral,
    },
  );
}

// ═══════════════════════════════════════════════════════════════
//  ENS-02 · Détail d'un cours : valider les séances
// ═══════════════════════════════════════════════════════════════
class CoursEnsPage extends StatelessWidget {
  const CoursEnsPage({super.key, required this.cours});
  final CoursEns cours;

  /// Exécute une action de validation puis prévient si le cours est complet.
  void _run(BuildContext context, VoidCallback action) {
    final s = cours.suivi;
    final avant = s.statut;
    action();
    if (avant != StatutCours.valideParEnseignant &&
        s.statut == StatutCours.valideParEnseignant) {
      _snack(
        context,
        "Toutes les séances sont validées : l'encadreur est notifié.",
      );
    }
  }

  void _voirPreuve(BuildContext context, String fichier) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photo du registre', style: t.headlineMedium),
              const SizedBox(height: 12),
              Container(
                height: 220,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scheme.outline),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text('$fichier · aperçu simulé', style: t.bodySmall),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: enseignantStore,
      builder: (context, _) {
        final s = cours.suivi;
        final seances = [...s.seances]
          ..sort((a, b) => b.date.compareTo(a.date));
        final lecture = s.cloture;

        return AdminScaffold(
          title: s.code,
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── En-tête du cours ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.code,
                            style: t.titleSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const Spacer(),
                          CoursStatutPill(s.statut),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(s.intitule, style: t.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${cours.promotion} · ${s.credits} crédits',
                        style: t.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      HeuresProgress(cours: s),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            '${s.nbValidees} validée(s)',
                            tone: PillTone.brand,
                          ),
                          StatusPill(
                            '${s.nbEncodees} à valider',
                            tone: s.nbEncodees > 0
                                ? PillTone.danger
                                : PillTone.neutral,
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
                            "Cours clôturé par l'encadreur : plus aucune modification possible.",
                            style: t.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Séances (${seances.length})',
                      style: t.headlineMedium,
                    ),
                  ),
                  if (!lecture && s.nbEncodees > 0)
                    FilledButton.icon(
                      onPressed: () => _run(
                        context,
                        () => enseignantStore.toutValider(cours),
                      ),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Tout valider'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (seances.isEmpty)
                const EmptyState(
                  message:
                      "Aucune séance encodée pour l'instant par le chef de promotion.",
                ),

              for (final seance in seances)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SeanceValidationCard(
                    seance: seance,
                    lecture: lecture,
                    onValider: () =>
                        _run(context, () => enseignantStore.valider(seance)),
                    onDevalider: () => enseignantStore.devalider(seance),
                    onPreuve: seance.preuve == null
                        ? null
                        : () => _voirPreuve(context, seance.preuve!),
                  ),
                ),
              SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }
}

class _SeanceValidationCard extends StatelessWidget {
  const _SeanceValidationCard({
    required this.seance,
    required this.lecture,
    required this.onValider,
    required this.onDevalider,
    this.onPreuve,
  });

  final Seance seance;
  final bool lecture;
  final VoidCallback onValider;
  final VoidCallback onDevalider;
  final VoidCallback? onPreuve;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(fmtJour(seance.date), style: t.titleMedium),
                ),
                StatusPill(
                  seance.validee ? 'Validée' : 'À valider',
                  tone: seance.validee ? PillTone.brand : PillTone.danger,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${seance.tranche} · ${fmtH(seance.heures)}',
                  style: t.bodySmall,
                ),
                const SizedBox(width: 8),
                StatusPill(seance.type.label),
              ],
            ),
            const SizedBox(height: 10),
            Text(seance.chapitre, style: t.bodyMedium),
            if (onPreuve != null) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: onPreuve,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_outlined,
                        size: 16,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        seance.preuve!,
                        style: t.bodySmall?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (!lecture) ...[
              const Divider(height: 24),
              SizedBox(
                width: double.infinity,
                child: seance.validee
                    ? OutlinedButton.icon(
                        onPressed: onDevalider,
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Dévalider'),
                      )
                    : FilledButton.icon(
                        onPressed: onValider,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Valider cette séance'),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Mini-timeline (6 segments) pour les cartes de la liste
// ═══════════════════════════════════════════════════════════════
class MiniTimeline extends StatelessWidget {
  const MiniTimeline({super.key, required this.dossier});
  final DossierPaie dossier;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var p = 1; p <= 6; p++) ...[
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: switch (dossier.etat(p)) {
                  EtatEtape.fait => scheme.primary,
                  EtatEtape.enCours => scheme.primary.withValues(alpha: 0.35),
                  EtatEtape.rejete => scheme.error,
                  EtatEtape.aVenir => scheme.outline,
                },
              ),
            ),
          ),
          if (p < 6) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Timeline verticale (« schéma de la position »)
// ═══════════════════════════════════════════════════════════════
class DossierTimeline extends StatelessWidget {
  const DossierTimeline({super.key, required this.dossier});
  final DossierPaie dossier;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var p = 1; p <= 6; p++)
          _TimelineRow(dossier: dossier, palier: p, last: p == 6),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.dossier,
    required this.palier,
    required this.last,
  });
  final DossierPaie dossier;
  final int palier;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final etat = dossier.etat(palier);
    final date = dossier.dateEtape(palier);
    final signature = dossier.signature(palier);

    final (Color fill, Color border, Widget icon) = switch (etat) {
      EtatEtape.fait => (
        scheme.primary,
        scheme.primary,
        Icon(Icons.check, size: 16, color: scheme.onPrimary),
      ),
      EtatEtape.enCours => (
        scheme.primaryContainer,
        scheme.primary,
        Icon(Icons.more_horiz, size: 16, color: scheme.primary),
      ),
      EtatEtape.rejete => (
        scheme.error,
        scheme.error,
        Icon(Icons.close, size: 16, color: scheme.onError),
      ),
      EtatEtape.aVenir => (
        scheme.surfaceContainerHigh,
        scheme.outline,
        const SizedBox.shrink(),
      ),
    };

    final String statutTexte = switch (etat) {
      EtatEtape.fait => 'Fait le ${fmtDateCourte(date!)}',
      EtatEtape.enCours => 'En cours de traitement',
      EtatEtape.rejete => 'Rejeté le ${fmtDateCourte(date!)}',
      EtatEtape.aVenir => 'À venir',
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fill,
                    border: Border.all(color: border, width: 1.5),
                  ),
                  child: icon,
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: etat == EtatEtape.fait
                          ? scheme.primary
                          : scheme.outline,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kActeurs[palier - 1],
                    style: t.titleSmall?.copyWith(
                      color: etat == EtatEtape.aVenir
                          ? scheme.onSurfaceVariant
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(kActions[palier - 1], style: t.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    statutTexte,
                    style: t.bodySmall?.copyWith(
                      color: etat == EtatEtape.rejete
                          ? scheme.error
                          : (etat == EtatEtape.enCours ? scheme.primary : null),
                    ),
                  ),
                  if (signature != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Signature : $signature',
                      style: t.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COM-05 · Détail d'un dossier de paie (vue Enseignant : lecture seule)
// ═══════════════════════════════════════════════════════════════
class DossierDetailPage extends StatelessWidget {
  const DossierDetailPage({super.key, required this.dossier});
  final DossierPaie dossier;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = dossier;
    final s = enseignantStore;

    return AdminScaffold(
      title: 'Fiche de paie',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── En-tête : référence, statut, net ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('N° DE RÉFÉRENCE UCB', style: t.labelSmall),
                            const SizedBox(height: 2),
                            Text(d.reference, style: t.headlineSmall),
                          ],
                        ),
                      ),
                      DossierPill(d),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Net à payer', style: t.bodySmall),
                  const SizedBox(height: 2),
                  Text(
                    fmtUsd(d.net),
                    style: t.displayMedium?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ),
          ),

          // ── Dossier rejeté : encadré rouge avec le motif ──
          if (d.statut == StatutDossier.rejete) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: scheme.error.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: scheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Rejeté par le ${kActeursCourts[d.palierRejet! - 1]} le ${fmtDateCourte(d.dateEtape(d.palierRejet!)!)}',
                          style: t.titleSmall?.copyWith(color: scheme.error),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(d.motifRejet ?? '', style: t.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Le secrétaire de la faculté a été notifié et doit corriger le dossier.',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ],

          // ── Paiement effectué ──
          if (d.statut == StatutDossier.paye) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_outlined, color: scheme.primary),
                        const SizedBox(width: 8),
                        Text('Paiement effectué', style: t.headlineSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Row('Date de paiement', fmtDateCourte(d.datePaiement!)),
                    const SizedBox(height: 8),
                    _Row('Référence', d.referencePaiement ?? '—'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _snack(
                          context,
                          'Quittance PDF : téléchargement simulé.',
                        ),
                        icon: const Icon(Icons.receipt_long_outlined, size: 18),
                        label: const Text('Télécharger la quittance (PDF)'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          _Section('Prestataire', [
            _Row('Nom', s.nom),
            _Row('Grade', s.grade),
            _Row("Institution d'origine", s.institution),
            _Row('Faculté', s.faculte),
          ]),
          const SizedBox(height: 12),
          _Section('Cours', [
            _Row('Code', d.code),
            _Row('Intitulé', d.intitule),
            _Row('Promotion', d.promotion),
            _Row('Crédits', '${d.credits}'),
            _Row('Volume horaire', '${d.volume} h'),
            _Row('Heures prestées', fmtH(d.heures)),
          ]),
          const SizedBox(height: 12),
          _Section(
            'Calcul de la paie',
            [
              _Row('Heures prestées', fmtH(d.heures)),
              _Row(
                'Taux horaire (${s.grade})',
                '${d.taux.toStringAsFixed(0)} \$/h',
              ),
              _Row('Montant brut', fmtUsd(d.brut)),
              _Row(
                'Retenues fiscales (${kRetenueDemo.toStringAsFixed(0)} %)',
                '− ${fmtUsd(d.retenues)}',
              ),
              _Row('Net à payer', fmtUsd(d.net), strong: true),
            ],
            footer:
                'Taux de retenue fictif (démo). Montants figés à l\'initialisation du dossier.',
          ),
          const SizedBox(height: 12),
          _Section('Paiement', [
            _Row('Mode', d.modePaiement),
            _Row("Date d'initialisation", fmtDateCourte(d.dateInit)),
          ]),

          // ── Timeline ──
          const SizedBox(height: 24),
          Text('Position du dossier', style: t.headlineMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DossierTimeline(dossier: d),
            ),
          ),

          // ── Séances ──
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              shape: const Border(),
              collapsedShape: const Border(),
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Séances validées (${d.seances.length})',
                style: t.titleMedium,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                for (final seance in d.seances)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fmtJour(seance.date), style: t.titleSmall),
                              Text(seance.chapitre, style: t.bodySmall),
                            ],
                          ),
                        ),
                        Text(fmtH(seance.heures), style: t.titleSmall),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Téléchargement ──
          const SizedBox(height: 24),
          Text('Télécharger la fiche', style: t.headlineMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final f in const ['PDF', 'Excel', 'Word']) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _snack(context, 'Fiche $f : téléchargement simulé.'),
                    child: Text(f),
                  ),
                ),
                if (f != 'Word') const SizedBox(width: 12),
              ],
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.rows, {this.footer});
  final String title;
  final List<Widget> rows;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: t.labelSmall),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              rows[i],
            ],
            if (footer != null) ...[
              const SizedBox(height: 12),
              Text(footer!, style: t.bodySmall?.copyWith(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: Text(label, style: t.bodySmall)),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: strong
                ? t.titleMedium?.copyWith(color: scheme.primary)
                : t.titleSmall,
          ),
        ),
      ],
    );
  }
}
