import 'package:flutter/material.dart';
import 'package:prestora/app/shared/styles/images.dart';
import 'package:prestora/app/view/payslip/authority/autorite.dart';
import 'package:prestora/app/view/payslip/authority/paie_data.dart';
import 'package:prestora/app/view/prestation/student/student.dart';
import 'package:prestora/app/view/prestation/supervisor/encadreur.dart';
import 'package:prestora/app/view/teacher/enseignant.dart';
import 'package:prestora/controller/cubit/cubit.dart';

import '../admin/admin.dart';

// ═══════════════════════════════════════════════════════════════
//  Comptes de démonstration (cohérents avec les données des autres pages)
//  À remplacer par Firebase Authentication.
// ═══════════════════════════════════════════════════════════════
enum DemoRole {
  admin,
  encadreur,
  enseignant,
  etudiant,
  doyen,
  vra,
  recteur,
  ag,
}

class DemoAccount {
  const DemoAccount({
    required this.role,
    required this.label,
    required this.nom,
    required this.email,
    required this.password,
    required this.icon,
    required this.route,
  });

  final DemoRole role;
  final String label; // libellé du rôle
  final String nom;
  final String email;
  final String password;
  final IconData icon;
  final String route; // pour go_router

  /// Page ouverte après connexion.
  Widget get page => switch (role) {
    DemoRole.admin => const Admin(),
    DemoRole.encadreur => const Encadreur(),
    DemoRole.enseignant => const Enseignant(),
    DemoRole.etudiant => const Etudiant(),
    DemoRole.doyen => Autorite(role: RoleAutorite.doyen),
    DemoRole.vra => Autorite(role: RoleAutorite.vra),
    DemoRole.ag => Autorite(role: RoleAutorite.ag),
    DemoRole.recteur => Autorite(role: RoleAutorite.recteur),
  };
}

List kDemoAccounts = <DemoAccount>[
  DemoAccount(
    role: DemoRole.admin,
    label: 'Administrateur',
    nom: 'Léa Murhula',
    email: 'lea.murhula@ucbukavu.ac.cd',
    password: 'Admin@2026',
    icon: Icons.admin_panel_settings_outlined,
    route: Admin.route,
  ),
  DemoAccount(
    role: DemoRole.encadreur,
    label: 'Encadreur',
    nom: 'Dr Olivier Kabano',
    email: 'olivier.kabano@ucbukavu.ac.cd',
    password: 'Encadreur@2026',
    icon: Icons.supervisor_account_outlined,
    route: Encadreur.route,
  ),
  DemoAccount(
    role: DemoRole.enseignant,
    label: 'Enseignant visiteur',
    nom: 'Dr Grâce Bahati',
    email: 'g.bahati@exemple.org',
    password: 'Enseignant@2026',
    icon: Icons.school_outlined,
    route: Enseignant.route,
  ),
  DemoAccount(
    role: DemoRole.etudiant,
    label: 'Étudiant',
    nom: 'Patrick Bisimwa',
    email: 'p.bisimwa@exemple.org',
    password: 'Etudiant@2026',
    icon: Icons.groups_outlined,
    route: Etudiant.route,
  ),

  DemoAccount(
    role: DemoRole.doyen,
    label: 'Doyen',
    nom: 'Pr Fidèle Bashige',
    email: 'fidele.bashige@ucbukavu.ac.cd',
    password: 'Doyen@2026',
    icon: Icons.account_balance_outlined,
    route: Autorite.routeDoyen,
  ),

  DemoAccount(
    role: DemoRole.vra,
    label: 'Vice-recteur académique',
    nom: 'Pr Claire Mukamba',
    email: 'claire.mukamba@ucbukavu.ac.cd',
    password: 'VRA@2026',
    icon: Icons.account_tree_outlined,
    route: Autorite.routeVra,
  ),

  DemoAccount(
    role: DemoRole.recteur,
    label: 'Recteur',
    nom: 'Pr Samuel Kasereka',
    email: 'samuel.kasereka@ucbukavu.ac.cd',
    password: 'Recteur@2026',
    icon: Icons.account_balance_outlined,
    route: Autorite.routeRecteur,
  ),

  DemoAccount(
    role: DemoRole.ag,
    label: 'Administrateur général',
    nom: 'M. Jonathan Mwamba',
    email: 'jonathan.mwamba@ucbukavu.ac.cd',
    password: 'AG@2026',
    icon: Icons.business_center_outlined,
    route: Autorite.routeAg,
  ),
];

// ═══════════════════════════════════════════════════════════════
//  Page de connexion
// ═══════════════════════════════════════════════════════════════
class Login extends StatefulWidget {
  static const route = '/login';
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  int itemsPerRow = 2;

  bool _obscure = true;
  bool _loading = false;
  String? _eEmail;
  String? _ePassword;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final email = _email.text.trim().toLowerCase();
    final pwd = _password.text;

    setState(() {
      _eEmail = email.contains('@') ? null : 'Saisissez un email valide';
      _ePassword = pwd.isEmpty ? 'Saisissez votre mot de passe' : null;
      _error = null;
    });
    if (_eEmail != null || _ePassword != null) return;

    setState(() => _loading = true);
    await Future<void>.delayed(
      const Duration(milliseconds: 900),
    ); // simule l'appel réseau
    if (!mounted) return;

    final account = kDemoAccounts
        .where((a) => a.email == email && a.password == pwd)
        .firstOrNull;
    if (account == null) {
      setState(() {
        _loading = false;
        _error = 'Email ou mot de passe incorrect.';
      });
      return;
    }

    setState(() => _loading = false);
    // Redirection selon le rôle
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute<void>(builder: (_) => account.page));
    // Avec go_router, utilisez plutôt :  context.go(account.route);
  }

  void _fill(DemoAccount a) {
    setState(() {
      _email.text = a.email;
      _password.text = a.password;
      _eEmail = null;
      _ePassword = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final t = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - v)),
                    child: child,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Logo + bascule de thème ──
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7B3AEC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.asset(
                              AppImages.logo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text('PrestOra', style: t.titleLarge),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Changer de thème',
                          onPressed: () =>
                              MainCubit.get(context).changeThemeMode(),
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // ── Titre ──
                    Text(
                      'CONNEXION',
                      style: t.labelSmall?.copyWith(
                        color: scheme.primary,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Accédez à votre espace', style: t.displayMedium),
                    const SizedBox(height: 12),
                    Text(
                      "Suivi des prestations et gestion de la paie des enseignants visiteurs de l'UCB.",
                      style: t.bodyLarge,
                    ),
                    const SizedBox(height: 32),

                    // ── Formulaire ──
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _email,
                              enabled: !_loading,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.username],
                              decoration: InputDecoration(
                                labelText: 'Email',
                                hintText: 'nom@exemple.org',
                                prefixIcon: const Icon(Icons.mail_outline),
                                errorText: _eEmail,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _password,
                              enabled: !_loading,
                              obscureText: _obscure,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                errorText: _ePassword,
                                suffixIcon: IconButton(
                                  // retire la bordure du IconButton global dans un champ
                                  style: IconButton.styleFrom(
                                    side: BorderSide.none,
                                    fixedSize: const Size(40, 40),
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _loading
                                    ? null
                                    : () => ScaffoldMessenger.of(context)
                                        ..hideCurrentSnackBar()
                                        ..showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Un lien de réinitialisation sera envoyé par email (à brancher).',
                                            ),
                                          ),
                                        ),
                                child: const Text('Mot de passe oublié ?'),
                              ),
                            ),

                            // ── Message d'erreur ──
                            AnimatedSize(
                              duration: const Duration(milliseconds: 200),
                              child: _error == null
                                  ? const SizedBox(width: double.infinity)
                                  : Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 16),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: scheme.error.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: scheme.error.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 18,
                                            color: scheme.error,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _error!,
                                              style: t.bodySmall?.copyWith(
                                                color: scheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),

                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : const Text('Se connecter'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Comptes de démonstration ──
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('COMPTES DE DÉMO', style: t.labelSmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (
                      int i = 0;
                      i < kDemoAccounts.length;
                      i += itemsPerRow
                    ) ...[
                      Row(
                        children: [
                          for (
                            int j = i;
                            j < i + itemsPerRow && j < kDemoAccounts.length;
                            j++
                          ) ...[
                            Expanded(
                              child: _DemoTile(
                                account: kDemoAccounts[j],
                                selected: _email.text == kDemoAccounts[j].email,
                                onTap: _loading
                                    ? null
                                    : () => _fill(kDemoAccounts[j]),
                              ),
                            ),
                            if (j < i + itemsPerRow - 1 &&
                                j < kDemoAccounts.length - 1)
                              const SizedBox(width: 12),
                          ],

                          // Remplit la dernière ligne si elle est incomplète
                          if ((kDemoAccounts.length - i) == 1)
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                      if (i + itemsPerRow < kDemoAccounts.length)
                        const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({
    required this.account,
    required this.selected,
    required this.onTap,
  });
  final DemoAccount account;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outline,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? scheme.primary : scheme.primaryContainer,
                ),
                child: Icon(
                  account.icon,
                  size: 20,
                  color: selected ? scheme.onPrimary : scheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                account.label,
                style: t.titleSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                account.nom,
                style: t.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
