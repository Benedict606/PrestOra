import 'package:flutter/material.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/payslip/authority/paie_widgets.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';

// ═══════════════════════════════════════════════════════════════
//  Formulaire de paiement partagé (SEC-04 et SEC-07)
// ═══════════════════════════════════════════════════════════════
class PaiementController extends ChangeNotifier {
  PaiementController({
    String mode = 'Mob-Money',
    String coordonnees = '',
    DateTime? date,
  }) : _mode = mode,
       date = date ?? kMaintenant {
    final i = coordonnees.indexOf(' · ');
    if (mode == 'Banque' && i >= 0) {
      banque.text = coordonnees.substring(0, i);
      numero.text = coordonnees.substring(i + 3);
    } else {
      numero.text = coordonnees;
    }
  }

  String _mode;
  final TextEditingController banque = TextEditingController();
  final TextEditingController numero = TextEditingController();
  DateTime date;
  String? errBanque;
  String? errNumero;

  String get mode => _mode;

  void setMode(String v) {
    _mode = v;
    errBanque = null;
    errNumero = null;
    notifyListeners();
  }

  void setDate(DateTime d) {
    date = d;
    notifyListeners();
  }

  bool validate() {
    errBanque = (_mode == 'Banque' && banque.text.trim().isEmpty)
        ? 'Nom de la banque obligatoire'
        : null;
    errNumero = numero.text.trim().isEmpty ? 'Numéro obligatoire' : null;
    notifyListeners();
    return errBanque == null && errNumero == null;
  }

  String get coordonnees => _mode == 'Banque'
      ? '${banque.text.trim()} · ${numero.text.trim()}'
      : numero.text.trim();

  @override
  void dispose() {
    banque.dispose();
    numero.dispose();
    super.dispose();
  }
}

class PaiementFields extends StatelessWidget {
  const PaiementFields({
    super.key,
    required this.controller,
    this.showDate = true,
  });
  final PaiementController controller;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final banque = controller.mode == 'Banque';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('MODE DE PAIEMENT', style: t.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final m in const ['Banque', 'Mob-Money']) ...[
                  Expanded(
                    child: controller.mode == m
                        ? FilledButton(
                            onPressed: () => controller.setMode(m),
                            child: Text(m),
                          )
                        : OutlinedButton(
                            onPressed: () => controller.setMode(m),
                            child: Text(m),
                          ),
                  ),
                  if (m == 'Banque') const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 16),
            if (banque) ...[
              TextField(
                controller: controller.banque,
                decoration: InputDecoration(
                  labelText: 'Nom de la banque',
                  errorText: controller.errBanque,
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: controller.numero,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: banque ? 'Numéro de compte' : 'Numéro Mobile Money',
                errorText: controller.errNumero,
              ),
            ),
            if (showDate) ...[
              const SizedBox(height: 16),
              Text("DATE D'INITIALISATION", style: t.labelSmall),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: controller.date,
                      firstDate: DateTime(2026, 1, 1),
                      lastDate: kMaintenant,
                    );
                    if (d != null) controller.setDate(d);
                  },
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(fmtDate(controller.date)),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEC-03 · Détail d'un cours terminé
// ═══════════════════════════════════════════════════════════════
class CoursTermineDetailPage extends StatelessWidget {
  const CoursTermineDetailPage({super.key, required this.cours});
  final CoursTermine cours;

  Future<void> _initialiser(BuildContext context) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => InitialiserSheet(cours: cours),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Dossier de paie initialisé pour ${cours.code}. Retrouvez-le dans « Dossiers ».',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final c = cours;
    final retenues = c.brut * kRetenueDemo / 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(c.code),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _initialiser(context),
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('Initialiser le dossier de paie'),
              ),
            ),
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.code,
                        style: t.titleSmall?.copyWith(color: scheme.primary),
                      ),
                      const SizedBox(height: 6),
                      Text(c.intitule, style: t.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${c.promotion} · Faculté ${c.faculte}',
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InfoSection('Enseignant', [
                InfoRow('Nom', c.enseignant),
                InfoRow('Grade', c.grade),
                InfoRow('Taux appliqué', '${c.taux.toStringAsFixed(0)} \$/h'),
                InfoRow(
                  'Paiement (profil)',
                  c.mode == 'Banque'
                      ? c.coordonnees
                      : '${c.mode} · ${c.coordonnees}',
                ),
              ]),
              const SizedBox(height: 12),
              InfoSection('Récapitulatif des séances', [
                InfoRow('Séances validées', '${c.seances.length}'),
                InfoRow('Total d\'heures', fmtH(c.heures)),
                InfoRow('Volume du cours', '${c.volume} h'),
                InfoRow(
                  'Pièces (photos du registre)',
                  '${c.seances.where((s) => s.preuve != null).length}',
                ),
              ]),
              const SizedBox(height: 12),
              InfoSection(
                'Aperçu du calcul',
                [
                  InfoRow('Montant brut', fmtMontant(c.brut)),
                  InfoRow(
                    'Retenues fiscales (${kRetenueDemo.toStringAsFixed(0)} %)',
                    '− ${fmtMontant(retenues)}',
                  ),
                  InfoRow(
                    'Net estimé',
                    fmtMontant(c.brut - retenues),
                    strong: true,
                  ),
                ],
                footer:
                    'Estimation : le calcul définitif est figé à l\'initialisation du dossier.',
              ),
              const SizedBox(height: 12),
              Card(
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(
                    'Séances validées (${c.seances.length})',
                    style: t.titleMedium,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    for (final s in c.seances)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(fmtJour(s.date), style: t.titleSmall),
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
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEC-04 · Initialiser le dossier de paie (feuille modale)
// ═══════════════════════════════════════════════════════════════
class InitialiserSheet extends StatefulWidget {
  const InitialiserSheet({super.key, required this.cours});
  final CoursTermine cours;

  @override
  State<InitialiserSheet> createState() => _InitialiserSheetState();
}

class _InitialiserSheetState extends State<InitialiserSheet> {
  late final PaiementController _p = PaiementController(
    mode: widget.cours.mode,
    coordonnees: widget.cours.coordonnees,
  );

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_p.validate()) return;
    paieStore.initialiser(
      widget.cours,
      mode: _p.mode,
      coordonnees: _p.coordonnees,
      date: _p.date,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = widget.cours;
    final net = c.brut * (1 - kRetenueDemo / 100);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Initialiser le dossier de paie', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text('${c.code} · ${c.intitule}', style: t.bodySmall),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    InfoRow('Enseignant', c.enseignant),
                    const SizedBox(height: 10),
                    InfoRow('Heures prestées', fmtH(c.heures)),
                    const SizedBox(height: 10),
                    InfoRow('Net estimé', fmtMontant(net), strong: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PaiementFields(controller: _p),
            const SizedBox(height: 8),
            Text(
              'Champs pré-remplis depuis le profil de l\'enseignant.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submit,
                child: const Text('Initialiser'),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEC-07 · Correction et réinitialisation d'un dossier rejeté
// ═══════════════════════════════════════════════════════════════
class CorrectionPage extends StatefulWidget {
  const CorrectionPage({super.key, required this.dossier});
  final DossierWf dossier;

  @override
  State<CorrectionPage> createState() => _CorrectionPageState();
}

class _CorrectionPageState extends State<CorrectionPage> {
  late final PaiementController _p = PaiementController(
    mode: widget.dossier.mode,
    coordonnees: widget.dossier.coordonnees,
    date: widget.dossier.dateInit,
  );
  late final List<String> _pieces = [...widget.dossier.pieces];
  final _commentaire = TextEditingController();

  @override
  void dispose() {
    _p.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  void _reinitialiser() {
    if (!_p.validate()) return;
    final d = widget.dossier;
    final cible = d.palierRejet!;
    d.pieces
      ..clear()
      ..addAll(_pieces);
    paieStore.reinitialiser(
      d,
      mode: _p.mode,
      coordonnees: _p.coordonnees,
      commentaire: _commentaire.text.trim(),
    );
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Dossier ${d.reference} remis au ${_acteur(cible)} pour une nouvelle validation.',
          ),
        ),
      );
  }

  String _acteur(int palier) => const [
    'secrétaire',
    'Doyen',
    'VRA',
    'Recteur',
    'AG',
    'comptable',
  ][palier - 1];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final d = widget.dossier;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corriger le dossier'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _reinitialiser,
                icon: const Icon(Icons.restart_alt, size: 18),
                label: const Text('Réinitialiser le dossier'),
              ),
            ),
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
              // ── Bandeau de rejet ──
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
                            style: t.titleSmall?.copyWith(color: scheme.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(d.motifRejet ?? '', style: t.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('${d.reference} · ${d.intitule}', style: t.headlineSmall),
              Text('${d.enseignant} · ${d.promotion}', style: t.bodySmall),
              const SizedBox(height: 20),

              // ── Informations de paiement ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: PaiementFields(controller: _p, showDate: false),
                ),
              ),

              // ── Pièces jointes ──
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIÈCES JOINTES (${_pieces.length})',
                        style: t.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      for (var i = 0; i < _pieces.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                size: 18,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _pieces[i],
                                  style: t.bodySmall?.copyWith(
                                    color: scheme.primary,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _pieces.removeAt(i)),
                                child: const Text('Retirer'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        // TODO : brancher image_picker / file_picker
                        onPressed: () => setState(
                          () => _pieces.add(
                            'piece_corrigee_${_pieces.length + 1}.pdf',
                          ),
                        ),
                        icon: const Icon(Icons.attach_file, size: 18),
                        label: const Text('Ajouter ou remplacer une pièce'),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Commentaire ──
              const SizedBox(height: 12),
              TextField(
                controller: _commentaire,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Commentaire de correction (facultatif)',
                  alignLabelWithHint: true,
                ),
              ),

              // ── Net recalculé ──
              const SizedBox(height: 12),
              InfoSection(
                'Aperçu du net recalculé',
                [
                  InfoRow('Heures prestées', fmtH(d.heures)),
                  InfoRow('Net à payer', fmtMontant(d.net), strong: true),
                ],
                footer:
                    'Les heures ne sont pas modifiables : elles proviennent des séances validées.',
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => paieSnack(
                  context,
                  'Les heures doivent rester cohérentes avec les séances validées.',
                ),
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text(
                  'Pourquoi les heures sont-elles verrouillées ?',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
