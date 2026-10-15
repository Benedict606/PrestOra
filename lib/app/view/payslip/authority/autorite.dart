import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/payslip/authority/paie_stats.dart';
import 'package:prestora/app/view/payslip/authority/paie_widgets.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:prestora/data/services/some.dart';

// Widgets partagés (Admin / circuit de paie). À déplacer dans un dossier commun plus tard.

/// Page commune au Doyen, au VRA, au Recteur et à l'Administrateur général.
/// Seuls changent : la portée (faculté), le palier du circuit et la personne suivante.
class Autorite extends StatefulWidget {
  const Autorite({super.key, required this.role});
  final RoleAutorite role;

  static const routeDoyen = '/doyen';
  static const routeVra = '/vra';
  static const routeRecteur = '/recteur';
  static const routeAg = '/ag';
  static const route = '/autorite';

  static String routeOf(RoleAutorite r) => switch (r) {
    RoleAutorite.doyen => routeDoyen,
    RoleAutorite.vra => routeVra,
    RoleAutorite.recteur => routeRecteur,
    RoleAutorite.ag => routeAg,
  };

  @override
  State<Autorite> createState() => _AutoriteState();
}

class _AutoriteState extends State<Autorite> {
  int _tab = 0; // 0 = À valider · 1 = Historique · 2 = Statistiques

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;

    void _openDialog() {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            margin: const EdgeInsets.only(top: 20),
            child: const Text("data"),
          ),
        ),
      );
    }

    return BlocConsumer<MainCubit, MainState>(
      listener: (context, state) {},
      builder: (context, state) {
        final action = MainCubit.get(context);

        return Scaffold(
          // ───────────── AppBar ─────────────
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
                    child: Text(role.initiale, style: t.headlineMedium),
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

          // ───────────── Navigation : À valider | Historique | Statistiques ─────────────
          bottomNavigationBar: ListenableBuilder(
            listenable: paieStore,
            builder: (context, _) {
              final n = paieStore.enAttente(role).length;
              return NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.pending_actions_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.pending_actions),
                    ),
                    label: 'À valider',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.history),
                    label: 'Historique',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: 'Statistiques',
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
                  _AValider(role: role),
                  _Historique(role: role),
                  StatsView(faculteFixe: role.faculte),
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
//  Ouverture d'un dossier avec la barre de décision (AUT-03)
// ═══════════════════════════════════════════════════════════════
void _ouvrirDossier(
  BuildContext context,
  DossierWf d,
  RoleAutorite role, {
  bool decision = true,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => DossierPage(
        dossier: d,
        bottomBar: decision
            ? (ctx, dos) => _barreDecision(ctx, dos, role)
            : null,
      ),
    ),
  );
}

/// Barre fixe [Rejeter] [Valider et signer] : visible seulement si le dossier est à mon palier.
Widget? _barreDecision(BuildContext context, DossierWf d, RoleAutorite role) {
  final aMonPalier = d.palierRejet == null && d.palierCourant == role.palier;
  if (!aMonPalier) return null;
  final scheme = Theme.of(context).colorScheme;
  return Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => _rejeter(context, d),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Rejeter'),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        flex: 2,
        child: FilledButton.icon(
          onPressed: () => _valider(context, d, role),
          icon: const Icon(Icons.draw_outlined, size: 18),
          label: const Text('Valider et signer'),
        ),
      ),
    ],
  );
}

Future<void> _valider(
  BuildContext context,
  DossierWf d,
  RoleAutorite role,
) async {
  final ok = await showSignatureSheet(context, d, suivant: role.suivant);
  if (!ok || !context.mounted) return;
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  paieStore.valider(d);
  nav.pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Dossier ${d.reference} signé et transmis ${role.suivant}.',
        ),
      ),
    );
}

Future<void> _rejeter(BuildContext context, DossierWf d) async {
  final motif = await showRejetSheet(context, d);
  if (motif == null || !context.mounted) return;
  final nav = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  paieStore.rejeter(d, motif);
  nav.pop();
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          'Dossier ${d.reference} rejeté. Le secrétaire est notifié.',
        ),
      ),
    );
}

// ═══════════════════════════════════════════════════════════════
//  AUT-01 + AUT-02 · À valider
// ═══════════════════════════════════════════════════════════════
class _AValider extends StatefulWidget {
  const _AValider({required this.role});
  final RoleAutorite role;

  @override
  State<_AValider> createState() => _AValiderState();
}

class _AValiderState extends State<_AValider> {
  String _q = '';
  bool _parAnciennete = true; // sinon : par montant décroissant

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final liste =
            paieStore
                .enAttente(role)
                .where(
                  (d) =>
                      q.isEmpty ||
                      d.intitule.toLowerCase().contains(q) ||
                      d.enseignant.toLowerCase().contains(q) ||
                      d.code.toLowerCase().contains(q),
                )
                .toList()
              ..sort(
                (a, b) => _parAnciennete
                    ? b.ancienneteJours.compareTo(a.ancienneteJours)
                    : b.net.compareTo(a.net),
              );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            // ── En-tête ──
            Text('Bonjour,', style: t.bodyLarge),
            const SizedBox(height: 4),
            Text(role.nom, style: t.displaySmall),
            const SizedBox(height: 4),
            Text(
              role.faculte == null
                  ? '${role.titre} · Toute l\'université'
                  : '${role.titre} · Faculté ${role.faculte}',
              style: t.bodySmall,
            ),
            const SizedBox(height: 24),

            // ── Compteurs ──
            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.pending_actions_outlined,
                    value: '${paieStore.enAttente(role).length}',
                    label: 'À valider',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.task_alt,
                    value: '${paieStore.validesCeMois(role)}',
                    label: 'Validés (mois)',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.block,
                    value: '${paieStore.rejetesParMoi(role)}',
                    label: 'Rejetés',
                    danger: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Liste ──
            Text('Dossiers à valider', style: t.displaySmall),
            const SizedBox(height: 25),
            SearchBox(
              hint: 'Rechercher un cours ou un enseignant',
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 15),
            PillRow(
              children: [
                FilterPill(
                  label: 'Plus anciens',
                  selected: _parAnciennete,
                  onTap: () => setState(() => _parAnciennete = true),
                ),
                FilterPill(
                  label: 'Décroissant',
                  selected: !_parAnciennete,
                  onTap: () => setState(() => _parAnciennete = false),
                ),
              ],
            ),
            const SizedBox(height: 25),

            if (liste.isEmpty)
              const EmptyState(
                message: 'Aucun dossier en attente de votre validation.',
              )
            else if (role.faculte != null)
              // Doyen : liste simple de sa faculté
              for (final d in liste) _carte(context, d, role, scheme)
            else
              // VRA / Recteur / AG : regroupé par faculté (sections repliables)
              for (final f in paieStore.facultes)
                if (liste.any((d) => d.faculte == f))
                  _Groupe(
                    faculte: f,
                    dossiers: liste.where((d) => d.faculte == f).toList(),
                    builder: (d) => _carte(context, d, role, scheme),
                  ),
          ],
        );
      },
    );
  }

  Widget _carte(
    BuildContext context,
    DossierWf d,
    RoleAutorite role,
    ColorScheme scheme,
  ) {
    final vieux = d.ancienneteJours >= 5; // seuil d'alerte (à valider)
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DossierCard(
        dossier: d,
        showFaculte: role.faculte == null,
        badge: StatusPill(
          'Reçu le ${fmtDate(d.recuLe)} · ${d.ancienneteJours} j',
          tone: vieux ? PillTone.danger : PillTone.neutral,
        ),
        onTap: () => _ouvrirDossier(context, d, role),
      ),
    );
  }
}

class _Groupe extends StatelessWidget {
  const _Groupe({
    required this.faculte,
    required this.dossiers,
    required this.builder,
  });
  final String faculte;
  final List<DossierWf> dossiers;
  final Widget Function(DossierWf) builder;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = dossiers.fold(0.0, (s, d) => s + d.net);
    return ExpansionTile(
      initiallyExpanded: true,
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      title: Text(faculte, style: t.headlineSmall),
      subtitle: Text(
        '${dossiers.length} dossier(s) · ${fmtMontant(total)}',
        style: t.bodySmall,
      ),
      children: [for (final d in dossiers) builder(d)],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  AUT-04 · Historique
// ═══════════════════════════════════════════════════════════════
enum _Decision { toutes, validees, rejetees }

class _Historique extends StatefulWidget {
  const _Historique({required this.role});
  final RoleAutorite role;

  @override
  State<_Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends State<_Historique> {
  _Decision _f = _Decision.toutes;

  @override
  Widget build(BuildContext context) {
    final role = widget.role;
    final t = Theme.of(context).textTheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final liste =
            paieStore.traites(role).where((d) {
              final rej = paieStore.rejeteParMoi(role, d);
              return switch (_f) {
                _Decision.toutes => true,
                _Decision.validees => !rej,
                _Decision.rejetees => rej,
              };
            }).toList()..sort(
              (a, b) => b.dates[role.palier]!.compareTo(a.dates[role.palier]!),
            );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Historique', style: t.displayMedium),
            const SizedBox(height: 4),
            Text('Dossiers que vous avez déjà traités.', style: t.bodySmall),
            const SizedBox(height: 16),
            PillRow(
              children: [
                FilterPill(
                  label: 'Toutes',
                  selected: _f == _Decision.toutes,
                  onTap: () => setState(() => _f = _Decision.toutes),
                ),
                FilterPill(
                  label: 'Validées',
                  selected: _f == _Decision.validees,
                  onTap: () => setState(() => _f = _Decision.validees),
                ),
                FilterPill(
                  label: 'Rejetées',
                  selected: _f == _Decision.rejetees,
                  onTap: () => setState(() => _f = _Decision.rejetees),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (liste.isEmpty)
              const EmptyState(message: 'Aucun dossier dans cette catégorie.')
            else
              for (final d in liste)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DossierCard(
                    dossier: d,
                    showFaculte: role.faculte == null,
                    badge: paieStore.rejeteParMoi(role, d)
                        ? StatusPill(
                            'Rejeté le ${fmtDate(d.dates[role.palier]!)}',
                            tone: PillTone.danger,
                          )
                        : StatusPill(
                            'Validé le ${fmtDate(d.dates[role.palier]!)}',
                            tone: PillTone.brand,
                          ),
                    footer: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: () => paieSnack(
                          context,
                          'Fiche ${d.reference} (PDF) : téléchargement simulé.',
                        ),
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Télécharger (PDF)'),
                      ),
                    ),
                    onTap: () =>
                        _ouvrirDossier(context, d, role, decision: false),
                  ),
                ),
          ],
        );
      },
    );
  }
}
