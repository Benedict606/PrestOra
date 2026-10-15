import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/app/view/prestation/student/etudiant_modules.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:prestora/data/services/some.dart';

// Widgets partagés (Admin / Étudiant). À déplacer dans un dossier commun plus tard.
import '../admin/admin_modules.dart'
    show EmptyState, FilterPill, PillRow, PillTone, StatusPill;
import 'enseignant_data.dart';
import 'enseignant_modules.dart';

class Enseignant extends StatefulWidget {
  static const route = '/enseignant';
  const Enseignant({super.key});

  @override
  State<Enseignant> createState() => _EnseignantState();
}

class _EnseignantState extends State<Enseignant> {
  int _tab = 0; // 0 = Mes cours · 1 = Fiches de paie

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
          // ─────────────  AppBar  ─────────────
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
                      enseignantStore.initiale,
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

          // ───────────── Navigation inférieure : Mes cours | Fiches de paie ─────────────
          bottomNavigationBar: ListenableBuilder(
            listenable: enseignantStore,
            builder: (context, _) {
              final n = enseignantStore.nbDossiersEnCours;
              return NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.menu_book_outlined),
                    selectedIcon: Icon(Icons.menu_book),
                    label: 'Mes cours',
                  ),
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.receipt_long_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.receipt_long),
                    ),
                    label: 'Fiches de paie',
                  ),
                ],
              );
            },
          ),

          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              // IndexedStack : chaque onglet garde son état (filtres, défilement)
              child: IndexedStack(
                index: _tab,
                children: [
                  _MesCours(onOpenPaie: () => setState(() => _tab = 1)),
                  const _FichesPaie(),
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
//  ENS-01 · Accueil Enseignant (Mes cours)
// ═══════════════════════════════════════════════════════════════
class _MesCours extends StatelessWidget {
  const _MesCours({required this.onOpenPaie});
  final VoidCallback onOpenPaie;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: enseignantStore,
      builder: (context, _) {
        final s = enseignantStore;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // ── En-tête ──
            Text('Bonjour,', style: t.bodyLarge),
            const SizedBox(height: 4),
            Text(s.nom, style: t.displaySmall),
            const SizedBox(height: 4),
            Text(
              'Enseignant visiteur · ${s.grade} · Faculté ${s.faculte}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 24),

            // ── Raccourci vers les fiches de paie ──
            Card(
              child: InkWell(
                onTap: onOpenPaie,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.receipt_long_outlined,
                          color: scheme.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Fiches de paie', style: t.headlineSmall),
                            const SizedBox(height: 4),
                            Text(
                              '${s.nbDossiersEnCours} en cours · ${s.nbDossiersPayes} payée(s)',
                              style: t.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bandeau : séances à valider ──
            if (s.nbSeancesAValider > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_top_outlined, color: scheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.nbSeancesAValider} séance(s) à valider',
                            style: t.titleSmall?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Validez-les pour permettre à l'encadreur de clôturer vos cours.",
                            style: t.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ── Cours assignés ──
            const SizedBox(height: 32),
            Text('Mes cours', style: t.displaySmall),
            const SizedBox(height: 30),
            for (final c in s.cours)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CoursEnsCard(
                  cours: c,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CoursEnsPage(cours: c),
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

class _CoursEnsCard extends StatelessWidget {
  const _CoursEnsCard({required this.cours, required this.onTap});
  final CoursEns cours;
  final VoidCallback onTap;

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
                    s.code,
                    style: t.titleSmall?.copyWith(color: scheme.primary),
                  ),
                  const Spacer(),
                  CoursStatutPill(s.statut),
                ],
              ),
              const SizedBox(height: 6),
              Text(s.intitule, style: t.headlineSmall),
              const SizedBox(height: 4),
              Text(
                '${cours.promotion} · ${s.credits} crédits',
                style: t.bodySmall,
              ),
              const SizedBox(height: 16),
              HeuresProgress(cours: s),
              if (s.nbEncodees > 0 && !s.cloture) ...[
                const SizedBox(height: 12),
                StatusPill(
                  '${s.nbEncodees} séance(s) à valider',
                  tone: PillTone.danger,
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
//  ENS-03 · Liste des fiches de paie
// ═══════════════════════════════════════════════════════════════
enum _Filtre { tous, enCours, payes, rejetes }

class _FichesPaie extends StatefulWidget {
  const _FichesPaie();

  @override
  State<_FichesPaie> createState() => _FichesPaieState();
}

class _FichesPaieState extends State<_FichesPaie> {
  _Filtre _f = _Filtre.tous;

  bool _match(DossierPaie d) => switch (_f) {
    _Filtre.tous => true,
    _Filtre.enCours =>
      d.statut == StatutDossier.enAttente ||
          d.statut == StatutDossier.initialise,
    _Filtre.payes => d.statut == StatutDossier.paye,
    _Filtre.rejetes => d.statut == StatutDossier.rejete,
  };

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: enseignantStore,
      builder: (context, _) {
        final s = enseignantStore;
        final list = s.dossiers.where(_match).toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Mes fiches de paie', style: t.displaySmall),
            const SizedBox(height: 30),

            // ── Montants ──
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    icon: Icons.verified_outlined,
                    value: fmtUsd(s.montantPercu),
                    label: 'Déjà perçu',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.schedule_outlined,
                    value: fmtUsd(s.montantEnAttente),
                    label: 'En attente',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            PillRow(
              children: [
                FilterPill(
                  label: 'Toutes',
                  selected: _f == _Filtre.tous,
                  onTap: () => setState(() => _f = _Filtre.tous),
                ),
                FilterPill(
                  label: 'En cours',
                  selected: _f == _Filtre.enCours,
                  onTap: () => setState(() => _f = _Filtre.enCours),
                ),
                FilterPill(
                  label: 'Payées',
                  selected: _f == _Filtre.payes,
                  onTap: () => setState(() => _f = _Filtre.payes),
                ),
                FilterPill(
                  label: 'Rejetées',
                  selected: _f == _Filtre.rejetes,
                  onTap: () => setState(() => _f = _Filtre.rejetes),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (list.isEmpty)
              const EmptyState(
                message: 'Aucune fiche de paie dans cette catégorie.',
              )
            else
              for (final d in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DossierCard(
                    dossier: d,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DossierDetailPage(dossier: d),
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

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: scheme.primary),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: t.headlineLarge),
            ),
            const SizedBox(height: 2),
            Text(label, style: t.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _DossierCard extends StatelessWidget {
  const _DossierCard({required this.dossier, required this.onTap});
  final DossierPaie dossier;
  final VoidCallback onTap;

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
                  DossierPill(d),
                ],
              ),
              const SizedBox(height: 6),
              Text(d.intitule, style: t.headlineSmall),
              const SizedBox(height: 2),
              Text('${d.promotion} · ${d.reference}', style: t.bodySmall),
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
                          fmtUsd(d.net),
                          style: t.headlineMedium?.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: 12),
              MiniTimeline(dossier: d),
            ],
          ),
        ),
      ),
    );
  }
}
