import 'dart:math';

import 'package:flutter/material.dart';
import 'package:prestora/app/shared/styles/colors.dart';
import 'package:prestora/app/shared/styles/icons.dart';
import 'package:prestora/app/shared/styles/images.dart';

import 'admin_data.dart';

// ═══════════════════════════════════════════════════════════════
//  Modules de l'espace Administrateur
//  ADM-02/03 Comptes · ADM-04/05 Facultés · ADM-06/07 Cours · ADM-08 Barèmes
// ═══════════════════════════════════════════════════════════════

// ───────────────────────── Widgets partagés ─────────────────────────

/// Scaffold commun des sous-pages (même AppBar + filet que la page Admin).
class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    super.key,
    required this.title,
    required this.body,
    this.fab,
  });

  final String title;
  final Widget body;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final t = theme.textTheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Cache la flèche
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(0xFF7B3AEC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(AppImages.logo, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },

              child: const Text('PrestOra'),
            ),
          ],
        ),
        actions: [
          IconButton(
            // onPressed: action.changeThemeMode,
            onPressed: () {},
            icon: Icon(AppIcons.search),
          ),
          Stack(
            children: [
              IconButton(
                // onPressed: action.changeThemeMode,
                onPressed: null,
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
            onTap: () {},
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outline),
              ),
              child: Center(
                child: Text('L'.substring(0, 1), style: t.headlineMedium),
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
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),

      floatingActionButton: fab,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: body,
        ),
      ),
    );
  }
}

enum PillTone { brand, neutral, danger }

class StatusPill extends StatelessWidget {
  const StatusPill(this.label, {super.key, this.tone = PillTone.neutral});

  final String label;
  final PillTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (tone) {
      PillTone.brand => (scheme.primaryContainer, scheme.primary),
      PillTone.danger => (scheme.error.withValues(alpha: 0.12), scheme.error),
      PillTone.neutral => (
        scheme.surfaceContainerHigh,
        scheme.onSurfaceVariant,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: fg, fontSize: 12),
      ),
    );
  }
}

/// Pastille de filtre (sélectionnée = violet plein).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHigh,
      shape: StadiumBorder(
        side: BorderSide(color: selected ? scheme.primary : scheme.outline),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class PillRow extends StatelessWidget {
  const PillRow({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final c in children)
          Padding(padding: const EdgeInsets.only(right: 8), child: c),
      ],
    ),
  );
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key, required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      prefixIcon: const Icon(Icons.search),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar(this.initiales, {required this.active});
  final String initiales;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        border: Border.all(color: scheme.outline),
      ),
      child: Text(
        initiales,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: active ? scheme.primary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

Widget adminDropdown<T>({
  required String label,
  required T? value,
  required List<T> items,
  required String Function(T) text,
  required ValueChanged<T?>? onChanged,
  String? error,
}) {
  return DropdownButtonFormField<T>(
    // ignore: deprecated_member_use
    value: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label, errorText: error),
    items: [
      for (final i in items)
        DropdownMenuItem<T>(
          value: i,
          child: Text(text(i), overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: onChanged,
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  required String label,
  String? hint,
  String initial = '',
  TextInputType? keyboard,
}) => showDialog<String>(
  context: context,
  builder: (_) => _TextPrompt(
    title: title,
    label: label,
    hint: hint,
    initial: initial,
    keyboard: keyboard,
  ),
);

class _TextPrompt extends StatefulWidget {
  const _TextPrompt({
    required this.title,
    required this.label,
    this.hint,
    this.initial = '',
    this.keyboard,
  });
  final String title;
  final String label;
  final String? hint;
  final String initial;
  final TextInputType? keyboard;

  @override
  State<_TextPrompt> createState() => _TextPromptState();
}

class _TextPromptState extends State<_TextPrompt> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _ok() {
    final v = _c.text.trim();
    if (v.isNotEmpty) Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: TextField(
      controller: _c,
      autofocus: true,
      keyboardType: widget.keyboard,
      onSubmitted: (_) => _ok(),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      FilledButton(onPressed: _ok, child: const Text('Enregistrer')),
    ],
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Carte « titre de section » avec action à droite.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ),
      if (action != null) action!,
    ],
  );
}

// ═══════════════════════════════════════════════════════════════
//  ADM-02 · Liste des comptes
// ═══════════════════════════════════════════════════════════════
class ComptesPage extends StatefulWidget {
  const ComptesPage({super.key});

  @override
  State<ComptesPage> createState() => _ComptesPageState();
}

class _ComptesPageState extends State<ComptesPage> {
  String _q = '';
  TypeCompte? _type;
  bool? _actif;
  bool isOff = false;

  void isSearchTrue() {
    setState(() {
      isOff = !isOff;
    });
  }

  Future<void> _toggle(Compte c) async {
    if (c.id == adminStore.currentUserId) {
      _snack(context, 'Vous ne pouvez pas désactiver votre propre compte.');
      return;
    }
    final ok = await confirmDialog(
      context,
      title: c.actif ? 'Désactiver le compte ?' : 'Réactiver le compte ?',
      message: c.actif
          ? '${c.nomComplet} ne pourra plus se connecter. Son historique est conservé.'
          : '${c.nomComplet} pourra de nouveau se connecter.',
      confirmLabel: c.actif ? 'Désactiver' : 'Réactiver',
      destructive: c.actif,
    );
    if (ok) adminStore.toggleCompte(c);
  }

  void _openForm([Compte? c]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CompteForm(compte: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AdminScaffold(
      title: 'Comptes utilisateurs',
      fab: FloatingActionButton.extended(
        shape: const CircleBorder(),
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: SizedBox(),
      ),
      body: ListenableBuilder(
        listenable: adminStore,
        builder: (context, _) {
          final q = _q.toLowerCase();
          final list = adminStore.comptes.where((c) {
            return (_type == null || c.type == _type) &&
                (_actif == null || c.actif == _actif) &&
                (q.isEmpty ||
                    c.nomComplet.toLowerCase().contains(q) ||
                    c.email.toLowerCase().contains(q));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              isOff
                  ? SearchBox(
                      hint: 'Rechercher un nom ou un email',
                      onChanged: (v) => setState(() => _q = v),
                    )
                  : SizedBox(),
              const SizedBox(height: 12),
              PillRow(
                children: [
                  FilterPill(
                    label: 'Tous',
                    selected: _actif == null,
                    onTap: () => setState(() => _actif = null),
                  ),
                  FilterPill(
                    label: 'Actifs',
                    selected: _actif == true,
                    onTap: () => setState(() => _actif = true),
                  ),
                  FilterPill(
                    label: 'Désactivés',
                    selected: _actif == false,
                    onTap: () => setState(() => _actif = false),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              PillRow(
                children: [
                  FilterPill(
                    label: 'Tous les types',
                    selected: _type == null,
                    onTap: () => setState(() => _type = null),
                  ),
                  for (final type in TypeCompte.values)
                    FilterPill(
                      label: type.label,
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('${list.length} compte(s)', style: t.bodySmall),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                  message: 'Aucun compte ne correspond \nà votre recherche.',
                )
              else
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CompteCard(
                      compte: c,
                      onTap: () => _openForm(c),
                      onToggle: (_) => _toggle(c),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _CompteCard extends StatelessWidget {
  const _CompteCard({
    required this.compte,
    required this.onTap,
    required this.onToggle,
  });
  final Compte compte;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Avatar(compte.initiales, active: compte.actif),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(compte.nomComplet, style: t.titleMedium),
                    const SizedBox(height: 2),
                    Text(compte.type.label, style: t.bodySmall),
                    Text(compte.faculte ?? 'Rôle global', style: t.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        StatusPill(
                          compte.actif ? 'Actif' : 'Désactivé',
                          tone: compte.actif
                              ? PillTone.brand
                              : PillTone.neutral,
                        ),
                        if (compte.grade != null) StatusPill(compte.grade!),
                        if (compte.promotion != null)
                          StatusPill(compte.promotion!),
                      ],
                    ),
                  ],
                ),
              ),
              Switch(value: compte.actif, onChanged: onToggle),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-03 · Formulaire de compte (ajout / modification)
// ═══════════════════════════════════════════════════════════════
class CompteForm extends StatefulWidget {
  const CompteForm({super.key, this.compte});
  final Compte? compte;

  @override
  State<CompteForm> createState() => _CompteFormState();
}

class _CompteFormState extends State<CompteForm> {
  late final bool _edit = widget.compte != null;
  late final TextEditingController _nom = TextEditingController(
    text: widget.compte?.nom ?? '',
  );
  late final TextEditingController _email = TextEditingController(
    text: widget.compte?.email ?? '',
  );
  late final TextEditingController _tel = TextEditingController(
    text: widget.compte?.telephone ?? '',
  );
  late final TextEditingController _inst = TextEditingController(
    text: widget.compte?.institution ?? '',
  );
  late final TextEditingController _paie = TextEditingController(
    text: widget.compte?.coordonneesPaiement ?? '',
  );

  late String? _titre = (widget.compte?.titre.isEmpty ?? true)
      ? null
      : widget.compte!.titre;
  late TypeCompte? _type = widget.compte?.type;
  late String? _faculte = widget.compte?.faculte;
  late String? _promotion = widget.compte?.promotion;
  late String? _grade = widget.compte?.grade;
  late String _mode = widget.compte?.modePaiement ?? 'Banque';

  String? _eNom, _eEmail, _eType, _eFac, _ePromo, _eGrade;

  @override
  void dispose() {
    for (final c in [_nom, _email, _tel, _inst, _paie]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final emailTaken = adminStore.comptes.any(
      (c) =>
          c.email.toLowerCase() == _email.text.trim().toLowerCase() &&
          c.id != widget.compte?.id,
    );
    setState(() {
      _eNom = _nom.text.trim().isEmpty ? 'Champ obligatoire' : null;
      _eEmail = !_email.text.contains('@')
          ? 'Email invalide'
          : emailTaken
          ? 'Cet email est déjà utilisé'
          : null;
      _eType = _type == null ? 'Choisissez un type de compte' : null;
      _eFac = (_type?.needsFaculte ?? false) && _faculte == null
          ? 'Faculté obligatoire'
          : null;
      _ePromo = (_type?.needsPromotion ?? false) && _promotion == null
          ? 'Promotion obligatoire'
          : null;
      _eGrade = (_type?.isEnseignant ?? false) && _grade == null
          ? 'Grade obligatoire'
          : null;
    });
    if ([_eNom, _eEmail, _eType, _eFac, _ePromo, _eGrade].any((e) => e != null))
      return;

    final type = _type!;
    final c =
        widget.compte ??
        Compte(
          id: 'c${DateTime.now().millisecondsSinceEpoch}',
          nom: '',
          email: '',
          type: type,
        );
    c
      ..nom = _nom.text.trim()
      ..email = _email.text.trim()
      ..titre = _titre ?? ''
      ..telephone = _tel.text.trim()
      ..type = type
      ..faculte = type.needsFaculte ? _faculte : null
      ..promotion = type.needsPromotion ? _promotion : null
      ..grade = type.isEnseignant ? _grade : null
      ..institution = type.isEnseignant ? _inst.text.trim() : null
      ..modePaiement = type.isEnseignant ? _mode : null
      ..coordonneesPaiement = type.isEnseignant ? _paie.text.trim() : null;

    final messenger = ScaffoldMessenger.of(context);
    if (_edit) {
      adminStore.touch();
      messenger.showSnackBar(
        const SnackBar(content: Text('Compte mis à jour.')),
      );
    } else {
      adminStore.addCompte(c);
      final pwd = 'Prest-${1000 + Random().nextInt(9000)}';
      messenger.showSnackBar(
        SnackBar(content: Text('Compte créé. Mot de passe temporaire : $pwd')),
      );
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final type = _type;
    final faculteNames = adminStore.facultes.map((f) => f.nom).toList();

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
              _edit ? 'Modifier le compte' : 'Nouveau compte',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Les champs affichés dépendent du type de compte.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),

            adminDropdown<TypeCompte>(
              label: 'Type de compte',
              value: _type,
              items: TypeCompte.values,
              text: (v) => v.label,
              error: _eType,
              // Type non modifiable après création (règle à valider)
              onChanged: _edit
                  ? null
                  : (v) => setState(() {
                      _type = v;
                      _faculte = null;
                      _promotion = null;
                      _grade = null;
                    }),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: adminDropdown<String>(
                    label: 'Titre',
                    value: _titre,
                    items: kTitres,
                    text: (v) => v,
                    onChanged: (v) => setState(() => _titre = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nom,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Nom complet',
                      errorText: _eNom,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: _eEmail,
                prefixIcon: const Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tel,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Téléphone (facultatif)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),

            if (type != null && type.needsFaculte) ...[
              const SizedBox(height: 16),
              adminDropdown<String>(
                label: 'Faculté',
                value: _faculte,
                items: faculteNames,
                text: (v) => v,
                error: _eFac,
                onChanged: (v) => setState(() {
                  _faculte = v;
                  _promotion = null;
                }),
              ),
            ],
            if (type != null && type.needsPromotion) ...[
              const SizedBox(height: 16),
              adminDropdown<String>(
                label: 'Promotion',
                value: _promotion,
                items: adminStore.promotionsOf(_faculte),
                text: (v) => v,
                error: _ePromo,
                onChanged: _faculte == null
                    ? null
                    : (v) => setState(() => _promotion = v),
              ),
            ],
            if (type != null && type.isEnseignant) ...[
              const SizedBox(height: 16),
              adminDropdown<String>(
                label: 'Grade statutaire',
                value: _grade,
                items: kGrades,
                text: (v) => v,
                error: _eGrade,
                onChanged: (v) => setState(() => _grade = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inst,
                decoration: const InputDecoration(
                  labelText: "Institution d'origine",
                ),
              ),
              const SizedBox(height: 16),
              Text('MODE DE PAIEMENT', style: t.labelSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final m in const ['Banque', 'Mobile Money']) ...[
                    Expanded(
                      child: _mode == m
                          ? FilledButton(
                              onPressed: () => setState(() => _mode = m),
                              child: Text(m),
                            )
                          : OutlinedButton(
                              onPressed: () => setState(() => _mode = m),
                              child: Text(m),
                            ),
                    ),
                    if (m == 'Banque') const SizedBox(width: 12),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _paie,
                decoration: InputDecoration(
                  labelText: _mode == 'Banque'
                      ? 'Banque et numéro de compte'
                      : 'Numéro Mobile Money',
                ),
              ),
            ],
            if (type != null && type.isGlobal) ...[
              const SizedBox(height: 12),
              Text(
                'Rôle global : aucune faculté associée.',
                style: t.bodySmall,
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_edit ? 'Enregistrer' : 'Créer le compte'),
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

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-04 · Gestion des facultés
// ═══════════════════════════════════════════════════════════════
class FacultesPage extends StatelessWidget {
  const FacultesPage({super.key});

  Future<void> _add(BuildContext context) async {
    final nom = await askText(
      context,
      title: 'Nouvelle faculté',
      label: 'Nom de la faculté',
    );
    if (nom == null) return;
    if (adminStore.facultes.any(
      (f) => f.nom.toLowerCase() == nom.toLowerCase(),
    )) {
      if (context.mounted) _snack(context, 'Cette faculté existe déjà.');
      return;
    }
    adminStore.addFaculte(nom);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AdminScaffold(
      title: 'Facultés et promotions',
      fab: FloatingActionButton.extended(
        onPressed: () => _add(context),

        label: const Text('Ajouter une faculté'),
      ),
      body: ListenableBuilder(
        listenable: adminStore,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            for (final f in adminStore.facultes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FaculteDetailPage(faculte: f),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Faculté ${f.nom}',
                                  style: t.headlineLarge,
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    StatusPill(
                                      '${f.departements.length} départements',
                                      tone: PillTone.brand,
                                    ),
                                    StatusPill(
                                      '${f.promotions.length} promotions',
                                    ),
                                    StatusPill(
                                      '${adminStore.coursOf(f.nom)} cours',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-05 · Détail d'une faculté : départements et promotions
// ═══════════════════════════════════════════════════════════════
class FaculteDetailPage extends StatelessWidget {
  const FaculteDetailPage({super.key, required this.faculte});
  final Faculte faculte;

  Future<void> _rename(BuildContext context) async {
    final nom = await askText(
      context,
      title: 'Modifier la faculté',
      label: 'Nom',
      initial: faculte.nom,
    );
    if (nom == null) return;
    faculte.nom = nom;
    adminStore.touch();
  }

  Future<void> _addDept(BuildContext context) async {
    final nom = await askText(
      context,
      title: 'Nouveau département',
      label: 'Nom du département',
    );
    if (nom != null) adminStore.addDepartement(faculte, nom);
  }

  Future<void> _addPromo(BuildContext context, Departement d) async {
    final nom = await askText(
      context,
      title: 'Nouvelle promotion',
      label: 'Nom (ex. L1 Informatique)',
    );
    if (nom == null) return;
    if (faculte.promotions.any(
      (p) => p.nom.toLowerCase() == nom.toLowerCase(),
    )) {
      if (context.mounted)
        _snack(context, 'Ce nom de promotion existe déjà dans la faculté.');
      return;
    }
    adminStore.addPromotion(d, nom);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: adminStore,
      builder: (context, _) {
        final encadreurs = adminStore.comptes
            .where(
              (c) => c.type == TypeCompte.encadreur && c.faculte == faculte.nom,
            )
            .map((c) => c.nomComplet)
            .toList();
        return AdminScaffold(
          title: 'Faculté ${faculte.nom}',
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Comptes rattachés', style: t.headlineMedium),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _rename(context),

                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(''),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Doyen', faculte.doyen ?? 'Non assigné'),
                      const Divider(height: 24),
                      _InfoRow(
                        'Secrétaire',
                        faculte.secretaire ?? 'Non assigné',
                      ),
                      const Divider(height: 24),
                      _InfoRow(
                        'Encadreurs',
                        encadreurs.isEmpty ? 'Aucun' : encadreurs.join(', '),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _SectionHeader(
                title: 'Départements et promotions',
                action: TextButton.icon(
                  onPressed: () => _addDept(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Département'),
                ),
              ),
              const SizedBox(height: 12),
              if (faculte.departements.isEmpty)
                const EmptyState(
                  message:
                      'Aucun département. Ajoutez-en un pour créer des promotions.',
                ),
              for (final d in faculte.departements)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(d.nom, style: t.headlineSmall),
                              ),
                              TextButton.icon(
                                onPressed: () => _addPromo(context, d),
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Promotion'),
                              ),
                            ],
                          ),
                        ),
                        const Divider(),
                        if (d.promotions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Aucune promotion.',
                              style: t.bodySmall,
                            ),
                          ),
                        for (final p in d.promotions)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nom, style: t.titleMedium),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Chef : ${p.chef ?? 'non assigné'}',
                                        style: t.bodySmall?.copyWith(
                                          color: p.chef == null
                                              ? scheme.error
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                StatusPill(
                                  '${p.nbCours} cours',
                                  tone: PillTone.brand,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text(label, style: t.bodySmall)),
        Expanded(child: Text(value, style: t.titleSmall)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-06 · Gestion des cours
// ═══════════════════════════════════════════════════════════════
class CoursPage extends StatefulWidget {
  const CoursPage({super.key});

  @override
  State<CoursPage> createState() => _CoursPageState();
}

class _CoursPageState extends State<CoursPage> {
  String _q = '';
  String? _fac;

  void _openForm([Cours? c]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => CoursForm(cours: c),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AdminScaffold(
      title: 'Gestion des cours',
      fab: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un cours'),
      ),
      body: ListenableBuilder(
        listenable: adminStore,
        builder: (context, _) {
          final q = _q.toLowerCase();
          final list = adminStore.cours.where((c) {
            return (_fac == null || c.faculte == _fac) &&
                (q.isEmpty ||
                    c.code.toLowerCase().contains(q) ||
                    c.intitule.toLowerCase().contains(q));
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
            children: [
              SearchBox(
                hint: 'Rechercher un code ou un intitulé',
                onChanged: (v) => setState(() => _q = v),
              ),
              const SizedBox(height: 12),
              PillRow(
                children: [
                  FilterPill(
                    label: 'Toutes',
                    selected: _fac == null,
                    onTap: () => setState(() => _fac = null),
                  ),
                  for (final f in adminStore.facultes)
                    FilterPill(
                      label: f.nom,
                      selected: _fac == f.nom,
                      onTap: () => setState(() => _fac = f.nom),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text('${list.length} cours', style: t.bodySmall),
              const SizedBox(height: 12),
              if (list.isEmpty)
                const EmptyState(
                  message: 'Aucun cours ne correspond à votre recherche.',
                )
              else
                for (final c in list)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: InkWell(
                        onTap: () => _openForm(c),
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
                                  StatusPill(
                                    c.affecte ? 'Affecté' : 'Non affecté',
                                    tone: c.affecte
                                        ? PillTone.brand
                                        : PillTone.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(c.intitule, style: t.headlineSmall),
                              const SizedBox(height: 4),
                              Text(
                                '${c.promotion} · ${c.faculte}',
                                style: t.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${c.credits} crédits',
                                    style: t.bodySmall,
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.schedule_outlined,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text('${c.volume} h max', style: t.bodySmall),
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
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-07 · Formulaire de cours (ajout / modification)
// ═══════════════════════════════════════════════════════════════
class CoursForm extends StatefulWidget {
  const CoursForm({super.key, this.cours});
  final Cours? cours;

  @override
  State<CoursForm> createState() => _CoursFormState();
}

class _CoursFormState extends State<CoursForm> {
  late final bool _edit = widget.cours != null;
  late final TextEditingController _code = TextEditingController(
    text: widget.cours?.code ?? '',
  );
  late final TextEditingController _intitule = TextEditingController(
    text: widget.cours?.intitule ?? '',
  );
  late final TextEditingController _credits = TextEditingController(
    text: widget.cours?.credits.toString() ?? '',
  );
  late final TextEditingController _volume = TextEditingController(
    text: widget.cours?.volume.toString() ?? '',
  );
  late String? _faculte = widget.cours?.faculte;
  late String? _promotion = widget.cours?.promotion;

  String? _eFac, _ePromo, _eCode, _eIntitule, _eCredits, _eVolume;

  @override
  void dispose() {
    for (final c in [_code, _intitule, _credits, _volume]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final code = _code.text.trim().toUpperCase();
    final credits = int.tryParse(_credits.text.trim());
    final volume = int.tryParse(_volume.text.trim());
    final taken = adminStore.cours.any(
      (c) => c.code == code && c != widget.cours,
    );
    setState(() {
      _eFac = _faculte == null ? 'Faculté obligatoire' : null;
      _ePromo = _promotion == null ? 'Promotion obligatoire' : null;
      _eCode = code.isEmpty
          ? 'Champ obligatoire'
          : (taken ? 'Ce code existe déjà' : null);
      _eIntitule = _intitule.text.trim().isEmpty ? 'Champ obligatoire' : null;
      _eCredits = (credits == null || credits <= 0) ? 'Nombre invalide' : null;
      _eVolume = (volume == null || volume <= 0)
          ? 'Doit être supérieur à 0'
          : null;
    });
    if ([
      _eFac,
      _ePromo,
      _eCode,
      _eIntitule,
      _eCredits,
      _eVolume,
    ].any((e) => e != null))
      return;

    final messenger = ScaffoldMessenger.of(context);
    if (_edit) {
      widget.cours!
        ..code = code
        ..intitule = _intitule.text.trim()
        ..faculte = _faculte!
        ..promotion = _promotion!
        ..credits = credits!
        ..volume = volume!;
      adminStore.touch();
      messenger.showSnackBar(
        const SnackBar(content: Text('Cours mis à jour.')),
      );
    } else {
      adminStore.addCours(
        Cours(
          code: code,
          intitule: _intitule.text.trim(),
          faculte: _faculte!,
          promotion: _promotion!,
          credits: credits!,
          volume: volume!,
        ),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Cours créé.')));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
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
              _edit ? 'Modifier le cours' : 'Nouveau cours',
              style: t.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Un cours est toujours associé à une promotion.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 20),
            adminDropdown<String>(
              label: 'Faculté',
              value: _faculte,
              items: adminStore.facultes.map((f) => f.nom).toList(),
              text: (v) => v,
              error: _eFac,
              onChanged: (v) => setState(() {
                _faculte = v;
                _promotion = null;
              }),
            ),
            const SizedBox(height: 16),
            adminDropdown<String>(
              label: 'Promotion',
              value: _promotion,
              items: adminStore.promotionsOf(_faculte),
              text: (v) => v,
              error: _ePromo,
              onChanged: _faculte == null
                  ? null
                  : (v) => setState(() => _promotion = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Code du cours',
                hintText: 'INF101',
                errorText: _eCode,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _intitule,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Intitulé exact',
                errorText: _eIntitule,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _credits,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Crédits',
                      errorText: _eCredits,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _volume,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Volume horaire max (h)',
                      errorText: _eVolume,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(_edit ? 'Enregistrer' : 'Créer le cours'),
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
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  ADM-08 · Barèmes de taux horaire
// ═══════════════════════════════════════════════════════════════
class BaremesPage extends StatelessWidget {
  const BaremesPage({super.key});

  Future<void> _editTaux(BuildContext context, Bareme b) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _TauxDialog(bareme: b),
    );
  }

  Future<void> _editRetenue(BuildContext context) async {
    final v = await askText(
      context,
      title: 'Taux des retenues fiscales',
      label: 'Pourcentage (%)',
      initial: adminStore.retenueFiscale?.toString() ?? '',
      keyboard: const TextInputType.numberWithOptions(decimal: true),
    );
    final n = double.tryParse((v ?? '').replaceAll(',', '.'));
    if (n != null && n >= 0 && n < 100) adminStore.setRetenue(n);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return AdminScaffold(
      title: 'Barèmes de taux horaire',
      body: ListenableBuilder(
        listenable: adminStore,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Le taux du grade est appliqué aux heures prestées. Une modification ne touche pas les dossiers déjà initialisés.',
              style: t.bodySmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < adminStore.baremes.length; i++) ...[
                    if (i > 0) const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adminStore.baremes[i].grade,
                                  style: t.titleMedium,
                                ),
                                Text('Taux horaire', style: t.bodySmall),
                              ],
                            ),
                          ),
                          Text(
                            fmtTaux(adminStore.baremes[i].taux),
                            style: t.headlineMedium?.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            tooltip: 'Modifier le taux',
                            onPressed: () =>
                                _editTaux(context, adminStore.baremes[i]),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Retenues fiscales', style: t.headlineMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Taux des retenues', style: t.titleMedium),
                          const SizedBox(height: 6),
                          adminStore.retenueFiscale == null
                              ? const StatusPill(
                                  'À définir',
                                  tone: PillTone.danger,
                                )
                              : StatusPill(
                                  '${adminStore.retenueFiscale} %',
                                  tone: PillTone.brand,
                                ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Modifier le taux de retenue',
                      onPressed: () => _editRetenue(context),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Historique des modifications', style: t.headlineMedium),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (
                      var i = 0;
                      i < adminStore.historiqueBaremes.length;
                      i++
                    ) ...[
                      if (i > 0) const Divider(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.history,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              adminStore.historiqueBaremes[i],
                              style: t.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _TauxDialog extends StatefulWidget {
  const _TauxDialog({required this.bareme});
  final Bareme bareme;

  @override
  State<_TauxDialog> createState() => _TauxDialogState();
}

class _TauxDialogState extends State<_TauxDialog> {
  late final TextEditingController _c = TextEditingController(
    text: widget.bareme.taux.toString(),
  );
  DateTime _effet = DateTime.now();
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _effet,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _effet = d);
  }

  void _save() {
    final v = double.tryParse(_c.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) {
      setState(() => _err = 'Le taux doit être supérieur à 0');
      return;
    }
    adminStore.setTaux(widget.bareme, v, _effet);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      title: Text(widget.bareme.grade),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Nouveau taux (\$/h)',
              errorText: _err,
            ),
          ),
          const SizedBox(height: 16),
          Text("DATE D'EFFET", style: t.labelSmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(fmtDate(_effet)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
