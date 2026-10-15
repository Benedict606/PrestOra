import 'package:flutter/material.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_modules.dart';

import 'paie_data.dart';

void paieSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

// ═══════════════════════════════════════════════════════════════
//  Carte KPI
// ═══════════════════════════════════════════════════════════════
class PaieKpi extends StatelessWidget {
  const PaieKpi({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.danger = false,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final color = danger ? scheme.error : scheme.primary;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: danger
                      ? scheme.error.withValues(alpha: 0.12)
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: t.displaySmall?.copyWith(
                    color: danger ? scheme.error : null,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Carte dossier de paie (CMP-02)
// ═══════════════════════════════════════════════════════════════
class DossierCard extends StatelessWidget {
  const DossierCard({
    super.key,
    required this.dossier,
    required this.onTap,
    this.showFaculte = false,
    this.badge,
    this.footer,
  });

  final DossierWf dossier;
  final VoidCallback onTap;
  final bool showFaculte;
  final Widget? badge; // ex. pastille d'ancienneté ou de décision
  final Widget? footer; // ex. bouton d'action

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = dossier;
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
                    d.code,
                    style: t.titleSmall?.copyWith(color: scheme.primary),
                  ),
                  const Spacer(),
                  DossierPill(d.snapshot),
                ],
              ),
              const SizedBox(height: 6),
              Text(d.intitule, style: t.headlineSmall),
              const SizedBox(height: 2),
              Text('${d.enseignant} · ${d.grade}', style: t.bodySmall),
              Text(
                showFaculte
                    ? '${d.faculte} · ${d.promotion}'
                    : '${d.promotion} · ${d.reference}',
                style: t.bodySmall,
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Net à payer', style: t.bodySmall),
                        Text(
                          fmtMontant(d.net),
                          style: t.headlineMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (badge != null) badge!,
                ],
              ),
              const SizedBox(height: 12),
              MiniTimeline(dossier: d.snapshot),
              if (footer != null) ...[const SizedBox(height: 14), footer!],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  COM-05 · Détail d'un dossier de paie (avec barre d'actions selon le rôle)
// ═══════════════════════════════════════════════════════════════
class DossierPage extends StatelessWidget {
  const DossierPage({super.key, required this.dossier, this.bottomBar});

  final DossierWf dossier;

  /// Barre d'actions fixe en bas (null = lecture seule). Reconstruite après chaque action.
  final Widget? Function(BuildContext context, DossierWf d)? bottomBar;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = dossier;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final bar = bottomBar?.call(context, d);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Fiche de paie'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
          ),
          bottomNavigationBar: bar == null
              ? null
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                      child: bar,
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'N° DE RÉFÉRENCE UCB',
                                      style: t.labelSmall,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(d.reference, style: t.headlineSmall),
                                  ],
                                ),
                              ),
                              DossierPill(d.snapshot),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Net à payer', style: t.bodySmall),
                          const SizedBox(height: 2),
                          Text(
                            fmtMontant(d.net),
                            style: t.displayMedium?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Rejet ──
                  if (d.statut == StatutDossier.rejete) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.error.withValues(alpha: 0.5),
                        ),
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
                                  'Rejeté par le ${d.rejetePar} le ${fmtDate(d.dates[d.palierRejet!] ?? kMaintenant)}',
                                  style: t.titleSmall?.copyWith(
                                    color: scheme.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(d.motifRejet ?? '', style: t.bodyMedium),
                        ],
                      ),
                    ),
                  ],

                  // ── Paiement effectué ──
                  if (d.statut == StatutDossier.paye) ...[
                    const SizedBox(height: 12),
                    InfoSection('Paiement effectué', [
                      InfoRow(
                        'Date de paiement',
                        fmtDate(d.dates[6] ?? kMaintenant),
                      ),
                      InfoRow('Référence', d.referencePaiement ?? '—'),
                      InfoRow('Mode de règlement', d.modeReglement ?? '—'),
                      InfoRow('Bordereau', d.bordereau ?? '—'),
                      if (d.imputation != null && d.imputation!.isNotEmpty)
                        InfoRow('Imputation budgétaire', d.imputation!),
                    ]),
                  ],

                  // ── Anciens rejets corrigés ──
                  if (d.historique.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InfoSection('Historique des corrections', [
                      for (final h in d.historique) Text(h, style: t.bodySmall),
                    ]),
                  ],

                  const SizedBox(height: 20),
                  InfoSection('Prestataire', [
                    InfoRow('Nom', d.enseignant),
                    InfoRow('Grade', d.grade),
                    InfoRow('Faculté', d.faculte),
                  ]),
                  const SizedBox(height: 12),
                  InfoSection('Cours', [
                    InfoRow('Code', d.code),
                    InfoRow('Intitulé', d.intitule),
                    InfoRow('Promotion', d.promotion),
                    InfoRow('Crédits', '${d.credits}'),
                    InfoRow('Volume horaire', '${d.volume} h'),
                    InfoRow('Heures prestées', fmtH(d.heures)),
                  ]),
                  const SizedBox(height: 12),
                  InfoSection(
                    'Calcul de la paie',
                    [
                      InfoRow('Heures prestées', fmtH(d.heures)),
                      InfoRow(
                        'Taux horaire (${d.grade})',
                        '${d.taux.toStringAsFixed(0)} \$/h',
                      ),
                      InfoRow('Montant brut', fmtMontant(d.brut)),
                      InfoRow(
                        'Retenues fiscales (${kRetenueDemo.toStringAsFixed(0)} %)',
                        '− ${fmtMontant(d.retenues)}',
                      ),
                      InfoRow('Net à payer', fmtMontant(d.net), strong: true),
                    ],
                    footer:
                        "Taux de retenue fictif (démo). Montants figés à l'initialisation.",
                  ),
                  const SizedBox(height: 12),
                  InfoSection('Paiement', [
                    InfoRow('Mode', d.mode),
                    InfoRow('Coordonnées', d.coordonnees),
                    InfoRow("Date d'initialisation", fmtDate(d.dateInit)),
                  ]),
                  const SizedBox(height: 12),
                  InfoSection('Pièces jointes (${d.pieces.length})', [
                    if (d.pieces.isEmpty)
                      Text('Aucune pièce.', style: t.bodySmall),
                    for (final p in d.pieces.take(4))
                      Row(
                        children: [
                          Icon(
                            Icons.photo_outlined,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              p,
                              style: t.bodySmall?.copyWith(
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (d.pieces.length > 4)
                      Text(
                        '+ ${d.pieces.length - 4} autre(s)',
                        style: t.bodySmall,
                      ),
                  ]),

                  // ── Timeline ──
                  const SizedBox(height: 24),
                  Text('Position du dossier', style: t.headlineMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DossierTimeline(dossier: d.snapshot),
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
                        for (final s in d.seances)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fmtJour(s.date),
                                        style: t.titleSmall,
                                      ),
                                      Text(s.chapitre, style: t.bodySmall),
                                    ],
                                  ),
                                ),
                                Text(fmtH(s.heures), style: t.titleSmall),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class InfoSection extends StatelessWidget {
  const InfoSection(this.title, this.rows, {super.key, this.footer});
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

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.strong = false});
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

// ═══════════════════════════════════════════════════════════════
//  DLG-01 · Rejet avec motif obligatoire
// ═══════════════════════════════════════════════════════════════
Future<String?> showRejetSheet(BuildContext context, DossierWf d) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RejetSheet(dossier: d),
    );

class _RejetSheet extends StatefulWidget {
  const _RejetSheet({required this.dossier});
  final DossierWf dossier;

  @override
  State<_RejetSheet> createState() => _RejetSheetState();
}

class _RejetSheetState extends State<_RejetSheet> {
  final _c = TextEditingController();
  String? _err;

  static const _motifs = [
    "Discordance d'heures",
    'Pièce manquante',
    'Taux ou grade incorrect',
    'Informations de paiement erronées',
  ];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _confirm() {
    final v = _c.text.trim();
    if (v.length < 10) {
      setState(() => _err = 'Décrivez le motif (10 caractères minimum).');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = widget.dossier;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rejeter le dossier', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              '${d.reference} · ${d.intitule} · ${d.enseignant}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('MOTIFS FRÉQUENTS', style: t.labelSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in _motifs)
                  ActionChip(
                    label: Text(m),
                    onPressed: () => setState(() {
                      _c.text = _c.text.isEmpty ? m : '${_c.text}. $m';
                      _err = null;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _c,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _err = null),
              decoration: InputDecoration(
                labelText: 'Motif du rejet (obligatoire)',
                alignLabelWithHint: true,
                errorText: _err,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Le secrétaire de la faculté sera notifié avec ce motif.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                onPressed: _confirm,
                child: const Text('Confirmer le rejet'),
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

// ═══════════════════════════════════════════════════════════════
//  DLG-02 · Signature électronique
// ═══════════════════════════════════════════════════════════════
Future<bool> showSignatureSheet(
  BuildContext context,
  DossierWf d, {
  required String suivant,
}) async {
  final r = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SignatureSheet(dossier: d, suivant: suivant),
  );
  return r ?? false;
}

class _SignatureSheet extends StatefulWidget {
  const _SignatureSheet({required this.dossier, required this.suivant});
  final DossierWf dossier;
  final String suivant;

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  final _pwd = TextEditingController();
  bool _certifie = false;
  bool _obscure = true;

  @override
  void dispose() {
    _pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = widget.dossier;
    final ok = _certifie && _pwd.text.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Valider et signer', style: t.headlineMedium),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoRow('Dossier', d.reference),
                    const SizedBox(height: 10),
                    InfoRow('Enseignant', d.enseignant),
                    const SizedBox(height: 10),
                    InfoRow('Net à payer', fmtMontant(d.net), strong: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _certifie,
              onChanged: (v) => setState(() => _certifie = v ?? false),
              title: const Text(
                "J'ai examiné ce dossier et je le déclare conforme",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _pwd,
              obscureText: _obscure,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Mot de passe (confirmation)',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  style: IconButton.styleFrom(
                    side: BorderSide.none,
                    fixedSize: const Size(40, 40),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Votre signature (identité, date et empreinte) sera enregistrée, puis le dossier sera transmis ${widget.suivant}.',
              style: t.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: ok ? () => Navigator.pop(context, true) : null,
                icon: const Icon(Icons.draw_outlined, size: 18),
                label: const Text('Signer et valider'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
