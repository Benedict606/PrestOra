import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/app/view/admin/admin_data.dart';
import 'package:prestora/app/view/admin/admin_modules.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart'
    hide fmtDate;
import 'package:prestora/app/view/payslip/authority/paie_stats.dart';
import 'package:prestora/app/view/payslip/authority/paie_widgets.dart';
import 'package:prestora/controller/cubit/cubit.dart';
import 'package:prestora/controller/state/state.dart';
import 'package:prestora/data/services/some.dart';

// Widgets partagés (Admin / circuit de paie). À déplacer dans un dossier commun plus tard.

import 'comptabilite_modules.dart';

class Comptabilite extends StatefulWidget {
  static const route = '/comptabilite';
  const Comptabilite({super.key});

  @override
  State<Comptabilite> createState() => _ComptabiliteState();
}

class _ComptabiliteState extends State<Comptabilite> {
  int _tab = 0; // 0 À payer · 1 Historique · 2 Statistiques

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
          // ───────────── Même AppBar que les autres pages ─────────────
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
                      paieStore.comptableNom.split(' ')[1].substring(0, 1),
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

          // ───────────── Navigation : À payer | Historique | Statistiques ─────────────
          bottomNavigationBar: ListenableBuilder(
            listenable: paieStore,
            builder: (context, _) {
              final n = paieStore.aPayer.length;
              return NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  NavigationDestination(
                    icon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.payments_outlined),
                    ),
                    selectedIcon: Badge(
                      isLabelVisible: n > 0,
                      label: Text('$n'),
                      child: const Icon(Icons.payments),
                    ),
                    label: 'À payer',
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
                children: const [
                  _APayer(),
                  _Historique(),
                  StatsView(), // toutes les facultés
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
//  Ouverture d'un dossier + barre d'actions du comptable
// ═══════════════════════════════════════════════════════════════
void _ouvrirDossier(BuildContext context, DossierWf d) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          DossierPage(dossier: d, bottomBar: (ctx, dos) => _barre(ctx, dos)),
    ),
  );
}

void _payer(BuildContext context, DossierWf d) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => PaiementPage(dossier: d)));
}

Widget? _barre(BuildContext context, DossierWf d) {
  final scheme = Theme.of(context).colorScheme;

  // Dossier à payer : [Rejeter] [Enregistrer le paiement]
  if (d.palierRejet == null && d.palierCourant == 6) {
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
            onPressed: () => _payer(context, d),
            icon: const Icon(Icons.payments_outlined, size: 18),
            label: const Text('Enregistrer le paiement'),
          ),
        ),
      ],
    );
  }

  // Dossier payé : quittance
  if (d.palierCourant >= 7) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => paieSnack(
          context,
          'Quittance de ${d.reference} (PDF) : téléchargement simulé.',
        ),
        icon: const Icon(Icons.receipt_long_outlined, size: 18),
        label: const Text('Télécharger la quittance (PDF)'),
      ),
    );
  }
  return null;
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
//  CPT-01 + CPT-02 · À payer
// ═══════════════════════════════════════════════════════════════
class _APayer extends StatefulWidget {
  const _APayer();

  @override
  State<_APayer> createState() => _APayerState();
}

class _APayerState extends State<_APayer> {
  String _q = '';
  bool _parAnciennete = true;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final liste =
            paieStore.aPayer
                .where(
                  (d) =>
                      q.isEmpty ||
                      d.intitule.toLowerCase().contains(q) ||
                      d.enseignant.toLowerCase().contains(q) ||
                      d.reference.toLowerCase().contains(q),
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
            Text(paieStore.comptableNom, style: t.displaySmall),
            const SizedBox(height: 4),
            Text("Comptabilité · Toute l'université", style: t.bodySmall),
            const SizedBox(height: 24),

            // ── Compteurs ──
            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.payments_outlined,
                    value: '${paieStore.aPayer.length}',
                    label: 'Dossiers à payer',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.account_balance_wallet_outlined,
                    value: fmtMontant(paieStore.totalAPayer),
                    label: 'Total à payer',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: PaieKpi(
                    icon: Icons.verified_outlined,
                    value: '${paieStore.payesCeMois}',
                    label: 'Payés ce mois',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PaieKpi(
                    icon: Icons.block,
                    value: '${paieStore.rejetesCompta}',
                    label: 'Rejetés',
                    danger: paieStore.rejetesCompta > 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // ── Liste ──
            Text('Dossiers à payer', style: t.displaySmall),
            const SizedBox(height: 16),
            Text(
              "Validés par l'Administrateur général, en attente de règlement.",
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
            SearchBox(
              hint: 'Rechercher un cours, un enseignant ou une référence',
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 16),
            PillRow(
              children: [
                FilterPill(
                  label: "Plus anciens",
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
            const SizedBox(height: 16),

            if (liste.isEmpty)
              const EmptyState(message: 'Aucun dossier à payer pour le moment.')
            else
              for (final f in paieStore.facultes)
                if (liste.any((d) => d.faculte == f))
                  _Groupe(
                    faculte: f,
                    dossiers: liste.where((d) => d.faculte == f).toList(),
                    builder: (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DossierCard(
                        dossier: d,
                        showFaculte: true,
                        badge: StatusPill(
                          'Validé le ${fmtDate(d.recuLe)} · ${d.ancienneteJours} j',
                          tone: d.ancienneteJours >= 5
                              ? PillTone.danger
                              : PillTone.neutral,
                        ),
                        onTap: () => _ouvrirDossier(context, d),
                        footer: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.account_balance_outlined,
                                  size: 16,
                                  color: scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${d.mode} · ${d.coordonnees}',
                                    style: t.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: () => _payer(context, d),
                                icon: const Icon(
                                  Icons.payments_outlined,
                                  size: 18,
                                ),
                                label: const Text('Enregistrer le paiement'),
                              ),
                            ),
                          ],
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
//  CPT-04 · Historique
// ═══════════════════════════════════════════════════════════════
enum _Filtre { tous, payes, rejetes }

class _Historique extends StatefulWidget {
  const _Historique();

  @override
  State<_Historique> createState() => _HistoriqueState();
}

class _HistoriqueState extends State<_Historique> {
  _Filtre _f = _Filtre.tous;
  String _q = '';
  String? _fac;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: paieStore,
      builder: (context, _) {
        final q = _q.toLowerCase();
        final liste = paieStore.traitesCompta.where((d) {
          final rej = paieStore.rejeteParCompta(d);
          final okStatut = switch (_f) {
            _Filtre.tous => true,
            _Filtre.payes => !rej,
            _Filtre.rejetes => rej,
          };
          return okStatut &&
              (_fac == null || d.faculte == _fac) &&
              (q.isEmpty ||
                  d.intitule.toLowerCase().contains(q) ||
                  d.enseignant.toLowerCase().contains(q) ||
                  (d.referencePaiement ?? '').toLowerCase().contains(q));
        }).toList()..sort((a, b) => b.dates[6]!.compareTo(a.dates[6]!));

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            Text('Historique', style: t.displayMedium),
            const SizedBox(height: 4),
            Text(
              'Dossiers que vous avez déjà payés ou rejetés.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
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
                  label: 'Payés',
                  selected: _f == _Filtre.payes,
                  onTap: () => setState(() => _f = _Filtre.payes),
                ),
                FilterPill(
                  label: 'Rejetés',
                  selected: _f == _Filtre.rejetes,
                  onTap: () => setState(() => _f = _Filtre.rejetes),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 16),
            if (liste.isEmpty)
              const EmptyState(message: 'Aucun dossier dans cette catégorie.')
            else
              for (final d in liste)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DossierCard(
                    dossier: d,
                    showFaculte: true,
                    badge: paieStore.rejeteParCompta(d)
                        ? StatusPill(
                            'Rejeté le ${fmtDate(d.dates[6]!)}',
                            tone: PillTone.danger,
                          )
                        : StatusPill(
                            'Payé le ${fmtDate(d.dates[6]!)}',
                            tone: PillTone.brand,
                          ),
                    onTap: () => _ouvrirDossier(context, d),
                    footer: paieStore.rejeteParCompta(d)
                        ? null
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.tag,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${d.referencePaiement ?? '—'} · ${d.modeReglement ?? ''}',
                                      style: t.bodySmall,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => paieSnack(
                                        context,
                                        'Fiche ${d.reference} (PDF) : téléchargement simulé.',
                                      ),
                                      icon: const Icon(
                                        Icons.description_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Fiche'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => paieSnack(
                                        context,
                                        'Quittance ${d.reference} (PDF) : téléchargement simulé.',
                                      ),
                                      icon: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Quittance'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
          ],
        );
      },
    );
  }
}
