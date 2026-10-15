import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/themes/txttheme.dart';

/// Page de démonstration du thème PrestOra.
///
/// 1) Elle montre comment chaque élément configuré s'affiche (clair / sombre).
/// 2) La dernière section « Comment l'utiliser » donne les lignes de code à copier.
///
/// À supprimer (ou garder en page « debug ») une fois le thème validé.
class ThemeShowcasePage extends StatefulWidget {
  const ThemeShowcasePage({super.key, required this.themeMode});

  /// Permet de basculer clair / sombre depuis l'AppBar.
  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<ThemeShowcasePage> createState() => _ThemeShowcasePageState();
}

class _ThemeShowcasePageState extends State<ThemeShowcasePage> {
  int _navIndex = 0;
  int _preset = 0;
  double _hours = 24;
  bool _push = true;
  bool _certify = false;
  bool _obscure = true;

  static const _presets = <(String, IconData)>[
    ('Enseignant', Icons.school_outlined),
    ('Secrétaire', Icons.assignment_ind_outlined),
    ('Doyen', Icons.account_balance_outlined),
    ('Comptabilité', Icons.payments_outlined),
  ];

  void _toggleTheme() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    widget.themeMode.value = dark ? ThemeMode.light : ThemeMode.dark;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _openDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rejeter le dossier ?'),
        content: const Text(
          'Le secrétaire sera notifié et devra corriger le dossier avant de le soumettre à nouveau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _openSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Valider et signer', style: t.headlineMedium),
              const SizedBox(height: 8),
              Text(
                "Votre signature sera horodatée et ajoutée à l'historique du dossier.",
                style: t.bodySmall,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Signer et valider'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // ── AppBar : logo + titre à gauche, bouton icône bordé à droite ──
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.assignment_turned_in_outlined,
                color: scheme.onPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('PrestOra'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Changer de thème',
            onPressed: _toggleTheme,
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),

      // ── Bouton flottant ──
      floatingActionButton: FloatingActionButton(
        onPressed: () => _snack('Bouton flottant (FloatingActionButton)'),
        child: const Icon(Icons.add),
      ),

      // ── Barre de navigation inférieure ──
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Alertes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),

      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 96),
            children: [
              // ═════════ HERO ═════════
              Text(
                'SUIVI DES PRESTATIONS',
                textAlign: TextAlign.center,
                style: TxtTheme.eyebrow(scheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'PrestOra : du cours enseigné au paiement',
                textAlign: TextAlign.center,
                style: t.displayLarge,
              ),
              const SizedBox(height: 16),
              Text(
                "Encodez les séances, faites-les valider et suivez chaque dossier de paie jusqu'au règlement.",
                textAlign: TextAlign.center,
                style: t.bodyLarge,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _snack('Commencer'),
                      child: const Text('Commencer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _snack('Documentation'),
                      child: const Text('Documentation'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ═════════ 3 ÉTAPES (cartes centrées) ═════════
              Text(
                'Comment ça marche',
                textAlign: TextAlign.center,
                style: t.displayMedium,
              ),
              const SizedBox(height: 20),
              const _StepCard(
                icon: Icons.edit_calendar_outlined,
                title: 'Encoder',
                description:
                    'Le chef de promotion enregistre chaque séance dispensée.',
              ),
              const SizedBox(height: 16),
              const _StepCard(
                icon: Icons.fact_check_outlined,
                title: 'Valider',
                description:
                    "L'enseignant certifie ses séances, puis le dossier suit le circuit.",
              ),
              const SizedBox(height: 16),
              const _StepCard(
                icon: Icons.payments_outlined,
                title: 'Payer',
                description:
                    'La comptabilité règle le dossier et génère la quittance.',
              ),
              const SizedBox(height: 32),

              // ═════════ 01 TYPOGRAPHIE ═════════
              _SectionCard(
                number: '01',
                title: 'Typographie',
                trailing: const Chip(label: Text('Plus Jakarta Sans')),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (name, style) in <(String, TextStyle?)>[
                      ('displayLarge', t.displayLarge),
                      ('displayMedium', t.displayMedium),
                      ('displaySmall', t.displaySmall),
                      ('headlineLarge', t.headlineLarge),
                      ('headlineMedium', t.headlineMedium),
                      ('headlineSmall', t.headlineSmall),
                      ('titleLarge', t.titleLarge),
                      ('titleMedium', t.titleMedium),
                      ('titleSmall', t.titleSmall),
                      ('bodyLarge', t.bodyLarge),
                      ('bodyMedium', t.bodyMedium),
                      ('bodySmall', t.bodySmall),
                      ('labelLarge', t.labelLarge),
                      ('labelMedium', t.labelMedium),
                      ('labelSmall', t.labelSmall),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$name · ${style?.fontSize?.round()} px · w${style?.fontWeight?.value ?? 400}',
                              style: TxtTheme.code(
                                scheme.onSurfaceVariant,
                              ).copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              name == 'labelSmall'
                                  ? 'QUICK PRESETS'
                                  : 'Suivi des prestations',
                              style: style,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═════════ 02 BOUTONS ═════════
              _SectionCard(
                number: '02',
                title: 'Boutons',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('QUICK PRESETS', style: t.labelSmall),
                    const SizedBox(height: 12),
                    // Sélecteur 2 × 2 : sélectionné = FilledButton, sinon OutlinedButton
                    for (var row = 0; row < 2; row++) ...[
                      Row(
                        children: [
                          for (var col = 0; col < 2; col++) ...[
                            Expanded(child: _presetButton(row * 2 + col)),
                            if (col == 0) const SizedBox(width: 12),
                          ],
                        ],
                      ),
                      if (row == 0) const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 24),
                    Text('TOUS LES TYPES', style: t.labelSmall),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton(
                          onPressed: () {},
                          child: const Text('Filled'),
                        ),
                        ElevatedButton(
                          onPressed: () {},
                          child: const Text('Elevated'),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: const Text('Outlined'),
                        ),
                        TextButton(onPressed: () {}, child: const Text('Text')),
                        const FilledButton(
                          onPressed: null,
                          child: Text('Désactivé'),
                        ),
                        const OutlinedButton(
                          onPressed: null,
                          child: Text('Désactivé'),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.menu),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_outlined),
                        label: const Text('Télécharger la fiche (PDF)'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═════════ 03 FORMULAIRE ═════════
              _SectionCard(
                number: '03',
                title: 'Formulaire',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TextField(
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'nom@exemple.com',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        // On retire la bordure du IconButton global dans un champ
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
                    const SizedBox(height: 16),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Motif du rejet',
                        errorText: 'Ce champ est obligatoire',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Heures prestées : ${_hours.round()} h / 30 h',
                      style: t.titleSmall,
                    ),
                    Slider(
                      value: _hours,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Notifications push'),
                      subtitle: const Text(
                        'Recevoir les alertes de validation',
                      ),
                      value: _push,
                      onChanged: (v) => setState(() => _push = v),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text("Je certifie avoir vérifié les heures"),
                      value: _certify,
                      onChanged: (v) => setState(() => _certify = v ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═════════ 04 STATUTS & PROGRESSION ═════════
              _SectionCard(
                number: '04',
                title: 'Statuts et progression',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Chip(label: Text('Selected 2 platforms')),
                        const Chip(label: Text('En attente du Doyen')),
                        Chip(
                          label: const Text('Payé'),
                          backgroundColor: scheme.primary,
                          labelStyle: t.labelMedium?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                        Chip(
                          label: const Text('Rejeté'),
                          backgroundColor: scheme.error.withValues(alpha: 0.12),
                          labelStyle: t.labelMedium?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Heures prestées : 24 / 30', style: t.bodySmall),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const LinearProgressIndicator(value: 0.8),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 16),
                        Text('Synchronisation en cours…'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═════════ 05 FENÊTRES ═════════
              _SectionCard(
                number: '05',
                title: 'Fenêtres et messages',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: _openDialog,
                      child: const Text('Dialogue'),
                    ),
                    OutlinedButton(
                      onPressed: _openSheet,
                      child: const Text('Bottom sheet'),
                    ),
                    OutlinedButton(
                      onPressed: () => _snack('Dossier soumis au Doyen'),
                      child: const Text('SnackBar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ═════════ 06 PALETTE ═════════
              _SectionCard(
                number: '06',
                title: isDark
                    ? 'Palette : mode sombre'
                    : 'Palette : mode clair',
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = (c.maxWidth - 12) / 2;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (final (name, color) in _palette(isDark))
                          SizedBox(
                            width: w,
                            child: _Swatch(name: name, color: color),
                          ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ═════════ 07 COMMENT L'UTILISER ═════════
              _SectionCard(
                number: '07',
                title: "Comment l'utiliser",
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UsageBlock(
                      label: 'Un texte stylé',
                      code:
                          r"Text('Titre', style: Theme.of(context).textTheme.displayMedium)",
                    ),
                    _UsageBlock(
                      label: 'Un texte grisé (descriptions)',
                      code:
                          r"Text('Aide', style: Theme.of(context).textTheme.bodySmall)",
                    ),
                    _UsageBlock(
                      label: 'Une couleur du thème (s\'adapte clair / sombre)',
                      code:
                          r"final scheme = Theme.of(context).colorScheme;"
                          "\n"
                          r"Container(color: scheme.primaryContainer)",
                    ),
                    _UsageBlock(
                      label: 'Une couleur brute de la palette',
                      code: r"AppColors.tdViolet",
                    ),
                    _UsageBlock(
                      label: 'Un bouton principal / secondaire',
                      code:
                          r"FilledButton(onPressed: () {}, child: const Text('Valider'))"
                          "\n"
                          r"OutlinedButton(onPressed: () {}, child: const Text('Annuler'))",
                    ),
                    _UsageBlock(
                      label: 'Une carte',
                      code:
                          r"Card(child: Padding(padding: EdgeInsets.all(20), child: Text('...')))",
                    ),
                    _UsageBlock(
                      label: 'Un champ de saisie',
                      code:
                          r"TextField(decoration: InputDecoration(labelText: 'Email'))",
                    ),
                    _UsageBlock(
                      label: 'Changer de thème (depuis n\'importe où)',
                      code: r"themeMode.value = ThemeMode.dark;",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _presetButton(int i) {
    final (label, icon) = _presets[i];
    final selected = _preset == i;
    void onTap() => setState(() => _preset = i);
    return selected
        ? FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
  }

  List<(String, Color)> _palette(bool dark) => [
    ('tdWhite', AppColors.tdWhite),
    ('tdError', AppColors.tdError),
    if (!dark) ...[
      ('tdViolet', AppColors.tdViolet),
      ('tdVioletTint', AppColors.tdVioletTint),
      ('tdVioletTintAlt', AppColors.tdVioletTintAlt),
      ('tdLightPage', AppColors.tdLightPage),
      ('tdLightCard', AppColors.tdLightCard),
      ('tdLightBorder', AppColors.tdLightBorder),
      ('tdLightText', AppColors.tdLightText),
      ('tdLightTextMuted', AppColors.tdLightTextMuted),
    ] else ...[
      ('tdVioletSoft', AppColors.tdVioletSoft),
      ('tdVioletDeep', AppColors.tdVioletDeep),
      ('tdVioletTintDark', AppColors.tdVioletTintDark),
      ('tdDarkPage', AppColors.tdDarkPage),
      ('tdDarkCard', AppColors.tdDarkCard),
      ('tdDarkSurfaceAlt', AppColors.tdDarkSurfaceAlt),
      ('tdDarkCode', AppColors.tdDarkCode),
      ('tdDarkBorder', AppColors.tdDarkBorder),
      ('tdDarkText', AppColors.tdDarkText),
      ('tdDarkTextMuted', AppColors.tdDarkTextMuted),
    ],
  ];
}

// ───────────────────────── Widgets locaux ─────────────────────────

/// Carte d'étape centrée (icône dans un cercle teinté, titre, description).
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary, size: 28),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: t.displaySmall),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de section : pastille numérotée + titre, séparateur, contenu.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String number;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Text(
                    number,
                    style: TxtTheme.code(scheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: t.headlineLarge)),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

/// Pastille de couleur + nom + code hexadécimal.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final hex =
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: scheme.outline),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: t.labelMedium, overflow: TextOverflow.ellipsis),
              Text(
                hex,
                style: TxtTheme.code(
                  scheme.onSurfaceVariant,
                ).copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bloc de code copiable avec son libellé.
class _UsageBlock extends StatelessWidget {
  const _UsageBlock({required this.label, required this.code});

  final String label;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.titleSmall),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outline),
            ),
            child: SelectableText(
              code,
              style: TxtTheme.code(
                scheme.onSurface,
              ).copyWith(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
