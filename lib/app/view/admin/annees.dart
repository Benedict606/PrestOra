import 'package:flutter/material.dart';
import 'package:prestora/core/notify.dart';
import 'package:prestora/data/models/annee.dart';
import 'package:prestora/data/repositories/annee_repository.dart';
import 'package:prestora/data/services/session.dart';

import 'admin_data.dart';
import 'admin_modules.dart';

// ═══════════════════════════════════════════════════════════════
//  Années académiques
//  ANN-01 liste · ANN-02 nouvelle année · ANN-03 détail + offre de cours
//  Accessible à l'administrateur et aux comptes « peut_gerer_annees ».
// ═══════════════════════════════════════════════════════════════

final _repo = AnneeRepository.instance;

PillTone _tone(StatutAnnee s) => switch (s) {
  StatutAnnee.active => PillTone.brand,
  StatutAnnee.planifiee => PillTone.neutral,
  StatutAnnee.cloturee => PillTone.neutral,
};

// ───────────────────────── Carte « année en cours » (hub) ─────────────────────────
class AnneeHeroCard extends StatelessWidget {
  const AnneeHeroCard({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final a = Session.instance.active;
        final fg = scheme.onPrimary;
        return Material(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.event_available_outlined, color: fg, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'ANNÉE ACADÉMIQUE',
                        style: t.labelSmall?.copyWith(
                          color: fg.withValues(alpha: 0.85),
                          letterSpacing: 1.8,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.chevron_right, color: fg),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (a == null) ...[
                    Text(
                      'Aucune année active',
                      style: t.displaySmall?.copyWith(color: fg),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Créez ou activez une année pour lancer le suivi des prestations.',
                      style: t.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.9),
                      ),
                    ),
                  ] else ...[
                    Text(a.libelle, style: t.displaySmall?.copyWith(color: fg)),
                    const SizedBox(height: 4),
                    Text(
                      '${fmtDate(a.debut)} → ${fmtDate(a.fin)}',
                      style: t.bodySmall?.copyWith(
                        color: fg.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: a.avancement,
                        minHeight: 6,
                        backgroundColor: fg.withValues(alpha: 0.25),
                        valueColor: AlwaysStoppedAnimation(fg),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(a.avancement * 100).round()} % de l\'année écoulée',
                      style: t.labelSmall?.copyWith(
                        color: fg.withValues(alpha: 0.9),
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

// ═══════════════════════════════════════════════════════════════
//  ANN-01 · Liste des années
// ═══════════════════════════════════════════════════════════════
class AnneesPage extends StatelessWidget {
  const AnneesPage({super.key});

  void _nouvelle(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const NouvelleAnneeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final s = Session.instance;
        final ok = s.gereAnnees;
        return AdminScaffold(
          title: 'Années académiques',
          fab: ok
              ? FloatingActionButton.extended(
                  onPressed: () => _nouvelle(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle année'),
                )
              : null,
          body: !ok
              ? const EmptyState(
                  message:
                      "Vous n'avez pas le droit de gérer les années académiques.",
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                  children: [
                    Text(
                      'Les cours, les promotions et les comptes sont permanents. '
                      "Les prestations, séances et dossiers de paie appartiennent "
                      "à une année : une année clôturée devient en lecture seule.",
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (s.annees.isEmpty)
                      const EmptyState(
                        message:
                            'Aucune année pour le moment.\nCréez la première avec « Nouvelle année ».',
                      )
                    else
                      for (final a in s.annees)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AnneeCard(annee: a),
                        ),
                  ],
                ),
        );
      },
    );
  }
}

class _AnneeCard extends StatelessWidget {
  const _AnneeCard({required this.annee});
  final AnneeAcademique annee;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AnneeDetailPage(anneeId: annee.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: annee.estActive
                      ? scheme.primary
                      : scheme.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  annee.estCloturee
                      ? Icons.lock_outline
                      : annee.estActive
                      ? Icons.play_arrow_rounded
                      : Icons.schedule_outlined,
                  color: annee.estActive
                      ? scheme.onPrimary
                      : scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(annee.libelle, style: t.headlineLarge),
                    const SizedBox(height: 4),
                    Text(
                      '${fmtDate(annee.debut)} → ${fmtDate(annee.fin)}',
                      style: t.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusPill(annee.statut.label, tone: _tone(annee.statut)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ANN-02 · Nouvelle année
// ═══════════════════════════════════════════════════════════════
class NouvelleAnneeSheet extends StatefulWidget {
  const NouvelleAnneeSheet({super.key});

  @override
  State<NouvelleAnneeSheet> createState() => _NouvelleAnneeSheetState();
}

class _NouvelleAnneeSheetState extends State<NouvelleAnneeSheet> {
  late final String? _source = Session.instance.annees.firstOrNull?.id;
  late final TextEditingController _lib = TextEditingController(
    text: AnneeAcademique.suivant(_source),
  );
  late DateTime _debut = DateTime(_premiereAnnee, 10, 1);
  late DateTime _fin = DateTime(_premiereAnnee + 1, 7, 31);
  late bool _reprendre = _source != null;
  String? _err;
  bool _busy = false;

  int get _premiereAnnee =>
      int.tryParse(_lib.text.split('-').first) ?? DateTime.now().year;

  @override
  void dispose() {
    _lib.dispose();
    super.dispose();
  }

  Future<void> _pick(bool debut) async {
    final d = await showDatePicker(
      context: context,
      initialDate: debut ? _debut : _fin,
      firstDate: DateTime(2020),
      lastDate: DateTime(2045),
    );
    if (d != null) setState(() => debut ? _debut = d : _fin = d);
  }

  Future<void> _creer() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final nav = Navigator.of(context);
    try {
      final n = await _repo.creer(
        libelle: _lib.text,
        debut: _debut,
        fin: _fin,
        reprendreDe: _reprendre ? _source : null,
      );
      Notif.info(
        n > 0
            ? 'Année ${_lib.text.trim()} créée · $n cours repris.'
            : 'Année ${_lib.text.trim()} créée.',
      );
      nav.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _err = Notif.humaniser(e);
        });
      }
    }
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
            Text('Nouvelle année académique', style: t.headlineMedium),
            const SizedBox(height: 4),
            Text(
              "L'année est créée « Planifiée » : vous préparez l'offre de cours, "
              "puis vous l'activez quand elle commence.",
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _lib,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Libellé',
                hintText: '2027-2028',
                prefixIcon: Icon(Icons.event_note_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(true),
                    icon: const Icon(Icons.flag_outlined, size: 18),
                    label: Text('Début ${fmtDate(_debut)}'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(false),
                    icon: const Icon(Icons.sports_score_outlined, size: 18),
                    label: Text('Fin ${fmtDate(_fin)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_source != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _reprendre,
                onChanged: (v) => setState(() => _reprendre = v),
                title: Text("Reprendre l'offre de $_source"),
                subtitle: const Text(
                  "Recopie les cours programmés et les affectations de "
                  "promotion. Vous pourrez ensuite ajuster.",
                ),
              ),
            if (_err != null) ...[
              const SizedBox(height: 8),
              Text(_err!, style: t.bodySmall?.copyWith(color: scheme.error)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _creer,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text("Créer l'année"),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
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
//  ANN-03 · Détail d'une année + offre de cours
// ═══════════════════════════════════════════════════════════════
class AnneeDetailPage extends StatefulWidget {
  const AnneeDetailPage({super.key, required this.anneeId});
  final String anneeId;

  @override
  State<AnneeDetailPage> createState() => _AnneeDetailPageState();
}

class _AnneeDetailPageState extends State<AnneeDetailPage> {
  String _q = '';
  bool _busy = false;

  AnneeAcademique? get _annee =>
      Session.instance.annees.where((a) => a.id == widget.anneeId).firstOrNull;

  Future<void> _run(Future<void> Function() f, String ok) async {
    setState(() => _busy = true);
    try {
      await f();
      Notif.info(ok);
    } catch (e) {
      Notif.erreur(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _activer(AnneeAcademique a, int nbOffres) async {
    final go = await confirmDialog(
      context,
      title: 'Activer ${a.libelle} ?',
      message: nbOffres == 0
          ? "Aucun cours n'est encore programmé. Vous pourrez en ajouter après l'activation."
          : '$nbOffres cours programmés. Les encadreurs, chefs de promotion et '
                "enseignants pourront commencer le suivi dès maintenant.",
      confirmLabel: 'Activer',
    );
    if (go) await _run(() => _repo.activer(a.id), 'Année ${a.libelle} activée.');
  }

  Future<void> _cloturer(AnneeAcademique a) async {
    final go = await confirmDialog(
      context,
      title: 'Clôturer ${a.libelle} ?',
      message:
          "Plus aucune séance ni validation de paie ne pourra être modifiée dans "
          "cette année. Cette action est définitive.",
      confirmLabel: "Clôturer l'année",
      destructive: true,
    );
    if (go) {
      await _run(() => _repo.cloturer(a.id), 'Année ${a.libelle} clôturée.');
    }
  }

  Future<void> _supprimer(AnneeAcademique a) async {
    final go = await confirmDialog(
      context,
      title: 'Supprimer ${a.libelle} ?',
      message: "L'année et son offre de cours seront supprimées.",
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!go) return;
    final nav = Navigator.of(context);
    try {
      await _repo.supprimer(a.id);
      Notif.info('Année supprimée.');
      nav.pop();
    } catch (e) {
      Notif.erreur(e);
    }
  }

  Future<void> _reprendre(AnneeAcademique a) async {
    final autres = Session.instance.annees.where((x) => x.id != a.id).toList();
    if (autres.isEmpty) {
      Notif.info("Il n'y a pas d'autre année à recopier.");
      return;
    }
    final src = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text("Reprendre l'offre de…"),
        children: [
          for (final x in autres)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, x.id),
              child: Text('${x.libelle}  ·  ${x.statut.label}'),
            ),
        ],
      ),
    );
    if (src == null) return;
    setState(() => _busy = true);
    try {
      final n = await _repo.reprendre(depuis: src, vers: a.id);
      Notif.info('$n cours repris depuis $src.');
    } catch (e) {
      Notif.erreur(e);
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _volume(OffreCours o) async {
    final v = await askText(
      context,
      title: 'Volume horaire · ${o.code}',
      label: "Heures pour l'année",
      initial: '${o.volume}',
      keyboard: TextInputType.number,
    );
    final n = int.tryParse((v ?? '').trim());
    if (n == null || n <= 0) return;
    try {
      await _repo.changerVolume(o, n);
    } catch (e) {
      Notif.erreur(e);
    }
  }

  Future<void> _retirer(OffreCours o) async {
    final go = await confirmDialog(
      context,
      title: 'Retirer ${o.code} ?',
      message: "Ce cours ne sera plus programmé cette année.",
      confirmLabel: 'Retirer',
      destructive: true,
    );
    if (!go) return;
    try {
      await _repo.retirerOffre(o);
    } catch (e) {
      Notif.erreur(e);
    }
  }

  void _ajouter(AnneeAcademique a, Set<String> dejaIds) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AjouterCoursSheet(anneeId: a.id, dejaIds: dejaIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) {
        final a = _annee;
        if (a == null) {
          return const AdminScaffold(
            title: 'Année académique',
            body: EmptyState(message: 'Année introuvable.'),
          );
        }
        final ok = Session.instance.gereAnnees;
        return StreamBuilder<List<OffreCours>>(
          stream: _repo.watchOffres(a.id),
          builder: (context, snap) {
            final offres = snap.data ?? const <OffreCours>[];
            final q = _q.toLowerCase();
            final liste = offres
                .where(
                  (o) =>
                      q.isEmpty ||
                      o.code.toLowerCase().contains(q) ||
                      o.intitule.toLowerCase().contains(q),
                )
                .toList();
            return AdminScaffold(
              title: a.libelle,
              fab: ok && a.modifiable
                  ? FloatingActionButton.extended(
                      onPressed: () =>
                          _ajouter(a, offres.map((o) => o.coursId).toSet()),
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter des cours'),
                    )
                  : null,
              body: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                children: [
                  _EnTete(annee: a, offres: offres),
                  const SizedBox(height: 16),
                  if (ok) _actions(a, offres.length),
                  const SizedBox(height: 24),
                  _Section(
                    title: 'Offre de cours',
                    count: offres.length,
                  ),
                  const SizedBox(height: 12),
                  if (offres.isNotEmpty)
                    SearchBox(
                      hint: 'Rechercher un code ou un intitulé',
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  const SizedBox(height: 12),
                  if (snap.hasError)
                    EmptyState(message: Notif.humaniser(snap.error!))
                  else if (offres.isEmpty)
                    const EmptyState(
                      message:
                          "Aucun cours programmé.\nAjoutez des cours du catalogue ou reprenez l'offre d'une autre année.",
                    )
                  else
                    ..._groupes(liste, ok && a.modifiable),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _actions(AnneeAcademique a, int nbOffres) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    if (a.estCloturee) {
      return Row(
        children: [
          const Icon(Icons.lock_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Année clôturée : lecture seule.',
              style: t.bodySmall,
            ),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (a.statut == StatutAnnee.planifiee)
          FilledButton.icon(
            onPressed: _busy ? null : () => _activer(a, nbOffres),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Activer cette année'),
          ),
        if (a.estActive)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
            ),
            onPressed: _busy ? null : () => _cloturer(a),
            icon: const Icon(Icons.lock_outline),
            label: const Text("Clôturer l'année"),
          ),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _reprendre(a),
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: const Text("Reprendre une offre"),
        ),
        if (a.statut == StatutAnnee.planifiee)
          TextButton.icon(
            onPressed: _busy ? null : () => _supprimer(a),
            icon: Icon(Icons.delete_outline, color: scheme.error),
            label: Text('Supprimer', style: TextStyle(color: scheme.error)),
          ),
      ],
    );
  }

  List<Widget> _groupes(List<OffreCours> liste, bool editable) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final out = <Widget>[];
    String? fac;
    String? promo;
    for (final o in liste) {
      if (o.faculteNom != fac) {
        fac = o.faculteNom;
        promo = null;
        out.add(const SizedBox(height: 12));
        out.add(
          Text(
            'FACULTÉ ${fac.toUpperCase()}',
            style: t.labelSmall?.copyWith(color: scheme.primary),
          ),
        );
      }
      if (o.promotionNom != promo) {
        promo = o.promotionNom;
        out.add(const SizedBox(height: 8));
        out.add(
          Text(promo.isEmpty ? 'Sans promotion' : promo, style: t.titleSmall),
        );
        out.add(const SizedBox(height: 6));
      }
      out.add(
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: editable ? () => _volume(o) : null,
            title: Text('${o.code} · ${o.intitule}', style: t.titleSmall),
            subtitle: Text('${o.credits} crédits · ${o.volume} h'),
            trailing: editable
                ? IconButton(
                    tooltip: 'Retirer',
                    onPressed: () => _retirer(o),
                    icon: const Icon(Icons.close),
                  )
                : null,
          ),
        ),
      );
    }
    return out;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      StatusPill('$count', tone: PillTone.brand),
    ],
  );
}

class _EnTete extends StatelessWidget {
  const _EnTete({required this.annee, required this.offres});
  final AnneeAcademique annee;
  final List<OffreCours> offres;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final promos = offres.map((o) => o.promotionId).toSet().length;
    final heures = offres.fold<int>(0, (s, o) => s + o.volume);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(annee.libelle, style: t.displaySmall)),
                StatusPill(annee.statut.label, tone: _tone(annee.statut)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${fmtDate(annee.debut)} → ${fmtDate(annee.fin)}'
              '${annee.dateCloture != null ? '  ·  clôturée le ${fmtDate(annee.dateCloture!)}' : ''}',
              style: t.bodySmall,
            ),
            if (annee.estActive) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: annee.avancement,
                  minHeight: 6,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat('${offres.length}', 'cours'),
                _Stat('$promos', 'promotions'),
                _Stat('$heures h', 'au total'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.headlineLarge),
          Text(label, style: t.bodySmall),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  Ajout de cours du catalogue à l'offre d'une année
// ═══════════════════════════════════════════════════════════════
class AjouterCoursSheet extends StatefulWidget {
  const AjouterCoursSheet({
    super.key,
    required this.anneeId,
    required this.dejaIds,
  });
  final String anneeId;
  final Set<String> dejaIds;

  @override
  State<AjouterCoursSheet> createState() => _AjouterCoursSheetState();
}

class _AjouterCoursSheetState extends State<AjouterCoursSheet> {
  late final Future<List<CoursCatalogue>> _cat = _repo.catalogue();
  final Set<String> _sel = {};
  String _q = '';
  bool _busy = false;

  Future<void> _valider(List<CoursCatalogue> all) async {
    final nav = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await _repo.ajouterOffres(
        widget.anneeId,
        all.where((c) => _sel.contains(c.id)).toList(),
      );
      Notif.info('${_sel.length} cours ajouté(s).');
      nav.pop();
    } catch (e) {
      Notif.erreur(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FutureBuilder<List<CoursCatalogue>>(
        future: _cat,
        builder: (context, snap) {
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyState(message: Notif.humaniser(snap.error!)),
            );
          }
          if (!snap.hasData) {
            return const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final q = _q.toLowerCase();
          final dispo = snap.data!
              .where((c) => !widget.dejaIds.contains(c.id))
              .where(
                (c) =>
                    q.isEmpty ||
                    c.code.toLowerCase().contains(q) ||
                    c.intitule.toLowerCase().contains(q),
              )
              .toList();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ajouter des cours', style: t.headlineMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Choisissez dans le catalogue permanent.',
                      style: t.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SearchBox(
                      hint: 'Rechercher un cours',
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: dispo.isEmpty
                    ? const EmptyState(
                        message: 'Tous les cours du catalogue sont déjà programmés.',
                      )
                    : ListView(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          for (final c in dispo)
                            CheckboxListTile(
                              value: _sel.contains(c.id),
                              onChanged: (v) => setState(
                                () => v == true
                                    ? _sel.add(c.id)
                                    : _sel.remove(c.id),
                              ),
                              title: Text('${c.code} · ${c.intitule}'),
                              subtitle: Text(
                                '${c.faculteNom} · ${c.promotionNom} · ${c.volume} h',
                              ),
                            ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy || _sel.isEmpty
                        ? null
                        : () => _valider(snap.data!),
                    child: Text(
                      _sel.isEmpty
                          ? 'Sélectionnez des cours'
                          : 'Ajouter (${_sel.length})',
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
