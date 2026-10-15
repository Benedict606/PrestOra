import 'package:flutter/material.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';

// Widgets partagés définis dans la page Admin.
// Conseil : à terme, déplacez-les dans un dossier commun (ex. lib/app/shared/widgets/).
import 'etudiant_data.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Pastille de statut d'un cours (utilisée par l'accueil et le détail).
class CoursStatutPill extends StatelessWidget {
  const CoursStatutPill(this.statut, {super.key});
  final StatutCours statut;

  @override
  Widget build(BuildContext context) => switch (statut) {
    StatutCours.enCours => const StatusPill('En cours', tone: PillTone.brand),
    StatutCours.valideParEnseignant => const StatusPill(
      "Validé par l'enseignant",
      tone: PillTone.brand,
    ),
    StatutCours.cloture => const StatusPill('Clôturé'),
  };
}

/// Barre de progression « heures prestées / volume ».
class HeuresProgress extends StatelessWidget {
  const HeuresProgress({super.key, required this.cours});
  final CoursSuivi cours;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Heures prestées', style: t.bodySmall)),
            Text(
              '${fmtH(cours.heuresPrestees)} / ${cours.volume} h',
              style: t.titleSmall,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(value: cours.progression),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CP-02 · Détail d'un cours et séances
// ═══════════════════════════════════════════════════════════════
class CoursDetailPage extends StatelessWidget {
  const CoursDetailPage({super.key, required this.cours});
  final CoursSuivi cours;

  void _openForm(BuildContext context, [Seance? s]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SeanceForm(cours: cours, seance: s),
    );
  }

  Future<void> _delete(BuildContext context, Seance s) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer la séance ?',
      message:
          'La séance du ${fmtJour(s.date)} (${fmtH(s.heures)}) sera supprimée.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (ok) etudiantStore.deleteSeance(cours, s);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: etudiantStore,
      builder: (context, _) {
        final seances = [...cours.seances]
          ..sort((a, b) => b.date.compareTo(a.date));
        final lecture = cours.cloture;

        return AdminScaffold(
          title: cours.code,
          fab: lecture
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter une séance'),
                ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
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
                            cours.code,
                            style: t.titleSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const Spacer(),
                          CoursStatutPill(cours.statut),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(cours.intitule, style: t.headlineLarge),
                      const SizedBox(height: 4),
                      Text(
                        '${cours.enseignant} · ${cours.grade}',
                        style: t.bodySmall,
                      ),
                      Text(
                        '${etudiantStore.promotion} · ${cours.credits} crédits',
                        style: t.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      HeuresProgress(cours: cours),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          StatusPill(
                            '${cours.nbValidees} validée(s)',
                            tone: PillTone.brand,
                          ),
                          StatusPill('${cours.nbEncodees} en attente'),
                          StatusPill(
                            cours.heuresRestantes > 0
                                ? 'Reste ${fmtH(cours.heuresRestantes)}'
                                : 'Volume atteint',
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
                            "Cours clôturé par l'encadreur : consultation uniquement.",
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
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 40,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune séance encodée.\nAppuyez sur « Ajouter une séance ».',
                        textAlign: TextAlign.center,
                        style: t.bodySmall,
                      ),
                    ],
                  ),
                ),

              for (final s in seances)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SeanceCard(
                    seance: s,
                    editable:
                        !s.validee &&
                        !lecture, // masqué dès validation par l'enseignant
                    onEdit: () => _openForm(context, s),
                    onDelete: () => _delete(context, s),
                  ),
                ),

              // ── Outil de démo (à supprimer) ──
              if (!lecture && cours.nbEncodees > 0) ...[
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
                          "Simule le moment où l'enseignant valide ses séances, pour voir l'écran passer en lecture seule.",
                          style: t.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            etudiantStore.simulerValidationEnseignant(cours);
                            _snack(
                              context,
                              "L'enseignant a validé toutes les séances.",
                            );
                          },
                          icon: const Icon(Icons.fact_check_outlined, size: 18),
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
        );
      },
    );
  }
}

class _SeanceCard extends StatelessWidget {
  const _SeanceCard({
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(fmtJour(seance.date), style: t.titleMedium),
                ),
                StatusPill(
                  seance.validee ? 'Validée' : 'Encodée',
                  tone: seance.validee ? PillTone.brand : PillTone.neutral,
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
            if (seance.preuve != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.photo_outlined, size: 16, color: scheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    seance.preuve!,
                    style: t.bodySmall?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ],
            if (editable) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modifier'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: scheme.error),
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Supprimer'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  CP-03 · Formulaire de séance (ajout / modification)
// ═══════════════════════════════════════════════════════════════
class SeanceForm extends StatefulWidget {
  const SeanceForm({super.key, required this.cours, this.seance});
  final CoursSuivi cours;
  final Seance? seance;

  @override
  State<SeanceForm> createState() => _SeanceFormState();
}

class _SeanceFormState extends State<SeanceForm> {
  late final bool _edit = widget.seance != null;
  late DateTime _date = widget.seance?.date ?? DateTime.now();
  late TimeOfDay _debut =
      widget.seance?.debut ?? const TimeOfDay(hour: 8, minute: 0);
  late TimeOfDay _fin =
      widget.seance?.fin ?? const TimeOfDay(hour: 10, minute: 0);
  late TypeSeance _type = widget.seance?.type ?? TypeSeance.cm;
  late String? _preuve = widget.seance?.preuve;
  late final TextEditingController _chap = TextEditingController(
    text: widget.seance?.chapitre ?? '',
  );

  String? _eChap;
  String? _eHeure;

  double get _duree => (minutesOf(_fin) - minutesOf(_debut)) / 60;

  @override
  void dispose() {
    _chap.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date.isAfter(today) ? today : _date,
      firstDate: DateTime(2026, 9, 1),
      lastDate: today, // pas de date future
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool debut) async {
    final t = await showTimePicker(
      context: context,
      initialTime: debut ? _debut : _fin,
    );
    if (t == null) return;
    setState(() => debut ? _debut = t : _fin = t);
  }

  void _save() {
    final cours = widget.cours;
    final others = cours.seances.where((s) => s != widget.seance).toList();
    final dejaPreste = others.fold(0.0, (s, e) => s + e.heures);
    final d = _duree;

    String? eHeure;
    if (d <= 0) {
      eHeure = "L'heure de fin doit être après l'heure de début.";
    } else if (dejaPreste + d > cours.volume) {
      eHeure =
          'Dépasse le volume horaire : il reste ${fmtH(cours.volume - dejaPreste)} sur ${cours.volume} h.';
    } else if (others.any(
      (s) =>
          s.date.year == _date.year &&
          s.date.month == _date.month &&
          s.date.day == _date.day &&
          minutesOf(s.debut) < minutesOf(_fin) &&
          minutesOf(_debut) < minutesOf(s.fin),
    )) {
      eHeure = 'Cette tranche chevauche une autre séance du même jour.';
    }

    setState(() {
      _eHeure = eHeure;
      _eChap = _chap.text.trim().isEmpty ? 'Décrivez le chapitre vu' : null;
    });
    if (_eHeure != null || _eChap != null) return;

    final messenger = ScaffoldMessenger.of(context);
    if (_edit) {
      widget.seance!
        ..date = _date
        ..debut = _debut
        ..fin = _fin
        ..type = _type
        ..chapitre = _chap.text.trim()
        ..preuve = _preuve;
      etudiantStore.touch();
      messenger.showSnackBar(
        const SnackBar(content: Text('Séance mise à jour.')),
      );
    } else {
      etudiantStore.addSeance(
        cours,
        Seance(
          id: 's${DateTime.now().microsecondsSinceEpoch}',
          date: _date,
          debut: _debut,
          fin: _fin,
          chapitre: _chap.text.trim(),
          type: _type,
          preuve: _preuve,
        ),
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Séance enregistrée. L'enseignant sera notifié."),
        ),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _edit ? 'Modifier la séance' : 'Nouvelle séance',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.cours.code} · ${widget.cours.intitule}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),

            Text('DATE', style: t.labelSmall),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined, size: 18),
                label: Text(fmtJour(_date)),
              ),
            ),
            const SizedBox(height: 20),

            Text('TRANCHE HORAIRE', style: t.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text('Début ${fmtHeure(_debut)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text('Fin ${fmtHeure(_fin)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _duree > 0 ? 'Durée : ${fmtH(_duree)}' : 'Durée invalide',
              style: t.bodySmall?.copyWith(
                color: _duree > 0 ? null : scheme.error,
              ),
            ),
            if (_eHeure != null) ...[
              const SizedBox(height: 4),
              Text(_eHeure!, style: t.bodySmall?.copyWith(color: scheme.error)),
            ],
            const SizedBox(height: 20),

            Text('TYPE DE SÉANCE', style: t.labelSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final type in TypeSeance.values) ...[
                  Expanded(
                    child: _type == type
                        ? FilledButton(
                            onPressed: () => setState(() => _type = type),
                            child: Text(type.label),
                          )
                        : OutlinedButton(
                            onPressed: () => setState(() => _type = type),
                            child: Text(type.label),
                          ),
                  ),
                  if (type != TypeSeance.values.last) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _chap,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Chapitre vu / description',
                alignLabelWithHint: true,
                errorText: _eChap,
              ),
            ),
            const SizedBox(height: 20),

            Text('PHOTO DU REGISTRE SIGNÉ (FACULTATIF)', style: t.labelSmall),
            const SizedBox(height: 8),
            if (_preuve == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  // TODO : brancher image_picker (appareil photo / galerie)
                  onPressed: () => setState(
                    () => _preuve =
                        'registre_${two(_date.day)}-${two(_date.month)}.jpg',
                  ),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Ajouter une photo'),
                ),
              )
            else
              Row(
                children: [
                  Icon(Icons.photo_outlined, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _preuve!,
                      style: t.bodyMedium?.copyWith(color: scheme.primary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _preuve = null),
                    child: const Text('Retirer'),
                  ),
                ],
              ),

            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_edit ? 'Enregistrer' : 'Enregistrer la séance'),
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
