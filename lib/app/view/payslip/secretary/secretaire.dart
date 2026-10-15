import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/payslip/authority/paie_widgets.dart';
import 'package:prestora/app/view/prestation/student/etudiant_data.dart';
import 'package:prestora/app/view/teacher/enseignant_data.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:prestora/data/services/some.dart';

// Widgets partagés (Admin / circuit de paie). À déplacer dans un dossier commun plus tard.

import 'secretaire_modules.dart';

class Secretaire extends StatefulWidget {
  static const route = '/secretaire';
  const Secretaire({super.key});

  @override
  State<Secretaire> createState() => _SecretaireState();
}

class _SecretaireState extends State<Secretaire> {
  int _tab = 0; // 0 Accueil · 1 Cours terminés · 2 Dossiers · 3 Rejetés

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;

    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {},
      builder: (context, state) {
        final action = MainCubit.get(context);

        return Scaffold(
          // ─────────────  AppBar ─────────────
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B3AEC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(AppImages.logo, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('PrestOra'),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    onPressed: () => openNotificationsDialog(context),
                    icon: Icon(AppIcons.notification),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      height: 5,
                      width: 5,
                      decoration: BoxDecoration(
                        color: AppColors.tdError,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 5),
              GestureDetector(
                onTap: () => openProfileDialog(context, action),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Center(
                    child: Text(
                      paieStore.secretaireNom.split(' ')[1].substring(0, 1),
                      style: t.headlineMedium,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant,
              ),
            ),
          ),

          // ───────────── Navigation : Accueil | Cours terminés | Dossiers | Rejetés ─────────────
          bottomNavigationBar: ListenableBuilder(
            listenable: paieStore,
            builder: (context, _) {
              final aInit = paieStore.coursAInitialiser.length;
              final rej = paieStore.dossiersRejetes.length;
              return NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Accueil',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: aInit > 0,
                      label: Text('$aInit'),
                      child: const Icon(Icons.task_alt_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: aInit > 0,
                      label: Text('$aInit'),
                      child: const Icon(Icons.task_alt),
                    ),
                    label: 'Terminés',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.folder_open_outlined),
                    selectedIcon: Icon(Icons.folder_open),
                    label: 'Dossiers',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: rej > 0,
                      label: Text('$rej'),
                      child: const Icon(Icons.block_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: rej > 0,
                      label: Text('$rej'),
                      child: const Icon(Icons.block),
                    ),
                    label: 'Rejetés',
                  ),
                ],
              );
            },
          ),

          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: IndexedStack(
                index: _tab,
                children: [
                  _Accueil(go: (i) => setState(() => _tab = i)),
                  const _CoursTermines(),
                  const _Dossiers(),
                  const _Rejetes(),
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
//  Aides : ouverture d'un dossier + soumission au Doyen
// ═══════════════════════════════════════════════════════════════
bool _peutSoumettre(DossierWf d) =>
    d.palierRejet == null && d.palierCourant == 1;

Future<void> _soumettre(BuildContext context, DossierWf d) async {
  final ok = await confirmDialog(
    context,
    title: 'Soumettre au Doyen ?',
    message:
        'Le dossier ${d.reference} sera transmis au Doyen. Après soumission, il ne pourra plus être modifié.',
    confirmLabel: 'Soumettre',
  );
  if (!ok || !context.mounted) return;
  paieStore.soumettre(d);
  paieSnack(context, 'Dossier ${d.reference} soumis au Doyen.');
}

void _ouvrirDossier(BuildContext context, DossierWf d) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DossierPage(
        dossier: d,
        bottomBar: (ctx, dos) {
          if (_peutSoumettre(dos)) {
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _soumettre(ctx, dos),
                icon: const Icon(Icons.send_outlined, size: 18),
                label: const Text('Soumettre au Doyen'),
              ),
            );
          }
          if (dos.palierRejet != null) {
            return SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CorrectionPage(dossier: dos),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Corriger le dossier'),
              ),
            );
          }
          return null;
        },
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════
//  SEC-01 · Accueil
// ═══════════════════════════════════════════════════════════════
class _Accueil extends StatelessWidget {
  const _Accueil({required this.go});
  final ValueChanged<int> go;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final s = paieStore;
        // À traiter en priorité : rejets d'abord, puis dossiers initialisés à soumettre
        final prioritaires = [
          ...s.dossiersRejetes,
          ...s.dossiersEnCircuit.where(_peutSoumettre),
        ].take(3).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Bonjour,', style: t.bodyLarge),
            const SizedBox(height: 4),
            Text(s.secretaireNom, style: t.displaySmall),
            const SizedBox(height: 4),
            Text(
              'Secrétaire de faculté · Faculté ${s.secretaireFaculte}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.task_alt_outlined,
                    value: '${s.coursAInitialiser.length}',
                    label: 'Cours à initialiser',
                    onTap: () => go(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.sync_alt,
                    value:
                        '${s.dossiersEnCircuit.where((d) => d.enCirculation).length}',
                    label: 'Dossiers en circuit',
                    onTap: () => go(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.block,
                    value: '${s.dossiersRejetes.length}',
                    label: 'Dossiers rejetés',
                    danger: s.dossiersRejetes.isNotEmpty,
                    onTap: () => go(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.verified_outlined,
                    value: '${s.nbPayes}',
                    label: 'Dossiers payés',
                    onTap: () => go(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text('À traiter en priorité', style: t.displaySmall),
            const SizedBox(height: 30),
            if (prioritaires.isEmpty)
              const EmptyState(message: 'Rien à traiter pour le moment.')
            else
              for (final d in prioritaires)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DossierCard(
                    dossier: d,
                    badge: StatusPill(
                      d.palierRejet != null ? 'À corriger' : 'À soumettre',
                      tone: d.palierRejet != null
                          ? PillTone.danger
                          : PillTone.brand,
                    ),
                    onTap: () => _ouvrirDossier(context, d),
                  ),
                ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEC-02 · Cours terminés
// ═══════════════════════════════════════════════════════════════
class _CoursTermines extends StatefulWidget {
  const _CoursTermines();

  @override
  State<_CoursTermines> createState() => _CoursTerminesState();
}

class _CoursTerminesState extends State<_CoursTermines> {
  String _q = '';
  String? _promo;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final tous = paieStore.coursAInitialiser;
        final promos = {for (final c in tous) c.promotion}.toList()..sort();
        final q = _q.toLowerCase();
        final liste = tous
            .where(
              (c) =>
                  (_promo == null || c.promotion == _promo) &&
                  (q.isEmpty ||
                      c.intitule.toLowerCase().contains(q) ||
                      c.code.toLowerCase().contains(q) ||
                      c.enseignant.toLowerCase().contains(q)),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Cours terminés', style: t.displayMedium),
            const SizedBox(height: 16),
            Text(
              "Cours clôturés par l'encadreur, en attente de l'initialisation du dossier de paie.",
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),
            SearchBox(
              hint: 'Rechercher un cours ou un enseignant',
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 12),
            PillRow(
              children: [
                FilterPill(
                  label: 'Toutes les promotions',
                  selected: _promo == null,
                  onTap: () => setState(() => _promo = null),
                ),
                for (final p in promos)
                  FilterPill(
                    label: p,
                    selected: _promo == p,
                    onTap: () => setState(() => _promo = p),
                  ),
              ],
            ),
            const SizedBox(height: 30),
            if (liste.isEmpty)
              const EmptyState(message: 'Aucun cours terminé à initialiser.')
            else
              for (final c in liste)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CoursTermineDetailPage(cours: c),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  c.code,
                                  style: t.titleSmall?.copyWith(
                                    color: scheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                const StatusPill(
                                  'Dossier à initialiser',
                                  tone: PillTone.brand,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(c.intitule, style: t.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${c.enseignant} · ${c.grade}',
                              style: t.bodySmall,
                            ),
                            Text(
                              '${c.promotion} · ${c.credits} crédits',
                              style: t.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule_outlined,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${fmtH(c.heures)} prestées',
                                  style: t.bodySmall,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.chevron_right,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEC-05 · Dossiers initialisés / en circuit
// ═══════════════════════════════════════════════════════════════
enum _Filtre { tous, initialises, enCircuit, payes }

class _Dossiers extends StatefulWidget {
  const _Dossiers();

  @override
  State<_Dossiers> createState() => _DossiersState();
}

class _DossiersState extends State<_Dossiers> {
  _Filtre _f = _Filtre.tous;
  String _q = '';

  bool _match(DossierWf d) => switch (_f) {
    _Filtre.tous => true,
    _Filtre.initialises => d.statut == StatutDossier.initialise,
    _Filtre.enCircuit => d.statut == StatutDossier.enAttente,
    _Filtre.payes => d.statut == StatutDossier.paye,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final q = _q.toLowerCase();
        // Les dossiers rejetés ont leur propre onglet
        final liste = paieStore.dossiersEnCircuit
            .where(_match)
            .where(
              (d) =>
                  q.isEmpty ||
                  d.intitule.toLowerCase().contains(q) ||
                  d.enseignant.toLowerCase().contains(q) ||
                  d.reference.toLowerCase().contains(q),
            )
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Dossiers de paie', style: t.displaySmall),
            const SizedBox(height: 16),
            Text(
              'Suivez la position de chaque dossier dans le circuit.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 30),
            SearchBox(
              hint: 'Rechercher un cours, un enseignant ou une référence',
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 12),
            PillRow(
              children: [
                FilterPill(
                  label: 'Tous',
                  selected: _f == _Filtre.tous,
                  onTap: () => setState(() => _f = _Filtre.tous),
                ),
                FilterPill(
                  label: 'Initialisés',
                  selected: _f == _Filtre.initialises,
                  onTap: () => setState(() => _f = _Filtre.initialises),
                ),
                FilterPill(
                  label: 'En circuit',
                  selected: _f == _Filtre.enCircuit,
                  onTap: () => setState(() => _f = _Filtre.enCircuit),
                ),
                FilterPill(
                  label: 'Payés',
                  selected: _f == _Filtre.payes,
                  onTap: () => setState(() => _f = _Filtre.payes),
                ),
              ],
            ),
            const SizedBox(height: 30),
            if (liste.isEmpty)
              const EmptyState(message: 'Aucun dossier dans cette catégorie.')
            else
              for (final d in liste)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DossierCard(
                    dossier: d,
                    onTap: () => _ouvrirDossier(context, d),
                    footer: _peutSoumettre(d)
                        ? SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _soumettre(context, d),
                              icon: const Icon(Icons.send_outlined, size: 18),
                              label: const Text('Soumettre au Doyen'),
                            ),
                          )
                        : null,
                  ),
                ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  SEC-06 · Dossiers rejetés
// ═══════════════════════════════════════════════════════════════
class _Rejetes extends StatelessWidget {
  const _Rejetes();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final liste = [...paieStore.dossiersRejetes]
          ..sort(
            (a, b) =>
                b.dates[b.palierRejet!]!.compareTo(a.dates[a.palierRejet!]!),
          );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Dossiers rejetés', style: t.displaySmall),
            const SizedBox(height: 16),
            Text(
              'Corrigez-les puis réinitialisez-les pour les remettre dans le circuit.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 30),
            if (liste.isEmpty)
              const EmptyState(
                message: 'Aucun dossier rejeté. Tout est en ordre.',
              )
            else
              for (final d in liste)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: InkWell(
                      onTap: () => _ouvrirDossier(context, d),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  d.code,
                                  style: t.titleSmall?.copyWith(
                                    color: scheme.primary,
                                  ),
                                ),
                                const Spacer(),
                                StatusPill(d.niveau, tone: PillTone.danger),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(d.intitule, style: t.headlineSmall),
                            const SizedBox(height: 2),
                            Text(
                              '${d.enseignant} · ${d.promotion}',
                              style: t.bodySmall,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: scheme.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.error.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d.rejetePar} · ${fmtDate(d.dates[d.palierRejet!] ?? kMaintenant)}',
                                    style: t.titleSmall?.copyWith(
                                      color: scheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(d.motifRejet ?? '', style: t.bodySmall),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                FilledButton.icon(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          CorrectionPage(dossier: d),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Corriger'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
