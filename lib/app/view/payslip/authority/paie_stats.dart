import 'package:flutter/material.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';

import 'paie_data.dart';
import 'paie_widgets.dart' show PaieKpi;

// ═══════════════════════════════════════════════════════════════
//  COM-07 · Tableau de bord statistique
//  Partagé par le Doyen, le VRA, le Recteur, l'AG.
//  [faculteFixe] : le Doyen est limité à sa faculté.
// ═══════════════════════════════════════════════════════════════
class StatsView extends StatefulWidget {
  const StatsView({super.key, this.faculteFixe});
  final String? faculteFixe;

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  int _jours = 365;
  String? _fac;

  static const _paliers = [
    'Secrétaire',
    'Doyen',
    'VRA',
    'Recteur',
    'AG',
    'Comptabilité',
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final fixe = widget.faculteFixe;
        final list = paieStore.dossiers.where((d) {
          final okFac = fixe != null
              ? d.faculte == fixe
              : (_fac == null || d.faculte == _fac);
          final okPeriode = kMaintenant.difference(d.dateInit).inDays <= _jours;
          return okFac && okPeriode;
        }).toList();

        final heures = list.fold(0.0, (s, d) => s + d.heures);
        final attente = list.where((d) => d.enCirculation).toList();
        final payes = list
            .where((d) => d.statut == StatutDossier.paye)
            .toList();
        final rejetes = list
            .where((d) => d.statut == StatutDossier.rejete)
            .toList();
        final initialises = list
            .where((d) => d.statut == StatutDossier.initialise)
            .length;
        final montantAttente = attente.fold(0.0, (s, d) => s + d.net);
        final montantPaye = payes.fold(0.0, (s, d) => s + d.net);

        // Délais moyens par palier (jours entre deux étapes consécutives)
        final delais = <double>[];
        for (var p = 2; p <= 6; p++) {
          final diffs = [
            for (final d in list)
              if (d.dates.containsKey(p) && d.dates.containsKey(p - 1))
                d.dates[p]!.difference(d.dates[p - 1]!).inDays,
          ];
          delais.add(
            diffs.isEmpty ? 0 : diffs.reduce((a, b) => a + b) / diffs.length,
          );
        }
        final delaiMoyen = delais.where((v) => v > 0).isEmpty
            ? 0.0
            : delais.where((v) => v > 0).reduce((a, b) => a + b) /
                  delais.where((v) => v > 0).length;
        final delaiMax = delais.fold(0.0, (m, v) => v > m ? v : m);

        final plusAnciens = [...attente.where((d) => d.palierCourant >= 2)]
          ..sort((a, b) => b.ancienneteJours.compareTo(a.ancienneteJours));

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Statistiques', style: t.displaySmall),
            const SizedBox(height: 20),

            // ── Filtres ──
            PillRow(
              children: [
                FilterPill(
                  label: 'Ce mois',
                  selected: _jours == 30,
                  onTap: () => setState(() => _jours = 30),
                ),
                FilterPill(
                  label: 'Trimestre',
                  selected: _jours == 90,
                  onTap: () => setState(() => _jours = 90),
                ),
                FilterPill(
                  label: 'Année',
                  selected: _jours == 365,
                  onTap: () => setState(() => _jours = 365),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (fixe != null)
              Align(
                alignment: Alignment.centerLeft,
                child: StatusPill('Faculté $fixe', tone: PillTone.brand),
              )
            else
              PillRow(
                children: [
                  FilterPill(
                    label: 'Toutes les facultés',
                    selected: _fac == null,
                    onTap: () => setState(() => _fac = null),
                  ),
                  for (final f in paieStore.facultes)
                    FilterPill(
                      label: f,
                      selected: _fac == f,
                      onTap: () => setState(() => _fac = f),
                    ),
                ],
              ),
            const SizedBox(height: 30),

            // ── KPI ──
            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.schedule_outlined,
                    value: fmtH(heures),
                    label: 'Heures \nprestées',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.timelapse,
                    value:
                        '${delaiMoyen.toStringAsFixed(1).replaceAll('.', ',')} j',
                    label: 'Délai moyen \npar palier',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.hourglass_top_outlined,
                    value: fmtMontant(montantAttente),
                    label: 'Montant en \nattente',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.verified_outlined,
                    value: fmtMontant(montantPaye),
                    label: 'Montant \npayé',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Dossiers par statut ──
            _Panel(
              title: 'Dossiers par statut',
              child: Column(
                children: [
                  _BarRow(
                    label: 'Initialisés',
                    value: initialises.toDouble(),
                    max: list.length.toDouble(),
                    text: '$initialises',
                    color: scheme.outline,
                  ),
                  _BarRow(
                    label: 'En attente',
                    value: (attente.length - initialises).toDouble(),
                    max: list.length.toDouble(),
                    text: '${attente.length - initialises}',
                    color: scheme.primary.withValues(alpha: 0.45),
                  ),
                  _BarRow(
                    label: 'Payés',
                    value: payes.length.toDouble(),
                    max: list.length.toDouble(),
                    text: '${payes.length}',
                    color: scheme.primary,
                  ),
                  _BarRow(
                    label: 'Rejetés',
                    value: rejetes.length.toDouble(),
                    max: list.length.toDouble(),
                    text: '${rejetes.length}',
                    color: scheme.error,
                  ),
                ],
              ),
            ),

            // ── Montants par faculté ──
            if (fixe == null && _fac == null) ...[
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final totaux = {
                    for (final f in paieStore.facultes)
                      f: (
                        list
                            .where((d) => d.faculte == f && d.enCirculation)
                            .fold(0.0, (s, d) => s + d.net),
                        list
                            .where(
                              (d) =>
                                  d.faculte == f &&
                                  d.statut == StatutDossier.paye,
                            )
                            .fold(0.0, (s, d) => s + d.net),
                      ),
                  };
                  final max = totaux.values.fold(
                    0.0,
                    (m, v) => [m, v.$1, v.$2].reduce((a, b) => a > b ? a : b),
                  );
                  return _Panel(
                    title: 'Montants par faculté',
                    legend: [
                      ('En attente', scheme.primary.withValues(alpha: 0.45)),
                      ('Payé', scheme.primary),
                    ],
                    child: Column(
                      children: [
                        for (final e in totaux.entries) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(e.key, style: t.titleSmall),
                          ),
                          const SizedBox(height: 6),
                          _BarRow(
                            label: '',
                            value: e.value.$1,
                            max: max,
                            text: fmtMontant(e.value.$1),
                            color: scheme.primary.withValues(alpha: 0.45),
                            labelWidth: 0,
                            textWidth: 84,
                          ),
                          _BarRow(
                            label: '',
                            value: e.value.$2,
                            max: max,
                            text: fmtMontant(e.value.$2),
                            color: scheme.primary,
                            labelWidth: 0,
                            textWidth: 84,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            // ── Délais par palier ──
            const SizedBox(height: 12),
            _Panel(
              title: 'Délai moyen par palier (jours)',
              subtitle: 'Repérez les goulets d\'étranglement du circuit.',
              child: Column(
                children: [
                  for (var i = 0; i < delais.length; i++)
                    _BarRow(
                      label: _paliers[i + 1],
                      value: delais[i],
                      max: delaiMax == 0 ? 1 : delaiMax,
                      text:
                          '${delais[i].toStringAsFixed(1).replaceAll('.', ',')} j',
                      color: (delais[i] == delaiMax && delaiMax > 0)
                          ? scheme.error
                          : scheme.primary,
                    ),
                ],
              ),
            ),

            // ── Dossiers les plus anciens ──
            const SizedBox(height: 12),
            _Panel(
              title: 'Dossiers en attente depuis le plus longtemps',
              child: plusAnciens.isEmpty
                  ? Text('Aucun dossier en attente.', style: t.bodySmall)
                  : Column(
                      children: [
                        for (final d in plusAnciens.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        d.intitule,
                                        style: t.titleSmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${d.niveau} · ${d.faculte}',
                                        style: t.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusPill(
                                  '${d.ancienneteJours} j',
                                  tone: d.ancienneteJours >= 5
                                      ? PillTone.danger
                                      : PillTone.neutral,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.child,
    this.subtitle,
    this.legend,
  });
  final String title;
  final String? subtitle;
  final List<(String, Color)>? legend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.headlineSmall),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: t.bodySmall),
            ],
            if (legend != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  for (final (label, color) in legend!)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(label, style: t.bodySmall),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
    required this.text,
    required this.color,
    this.labelWidth = 84,
    this.textWidth = 40,
  });

  final String label;
  final double value;
  final double max;
  final String text;
  final Color color;
  final double labelWidth;
  final double textWidth;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final fraction = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (labelWidth > 0)
            SizedBox(
              width: labelWidth,
              child: Text(label, style: t.bodySmall),
            ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: scheme.outline.withValues(alpha: 0.35),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(height: 8, color: color),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: textWidth,
            child: Text(text, textAlign: TextAlign.right, style: t.titleSmall),
          ),
        ],
      ),
    );
  }
}
