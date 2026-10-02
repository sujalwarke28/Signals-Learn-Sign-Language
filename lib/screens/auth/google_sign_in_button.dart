import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../../providers/app_providers.dart';

/// "Continue with Google" for the login and sign-up screens.
///
/// Owns its own busy state so the two screens don't each have to thread one
/// through, and reports back through [onBusy] so they can disable their email
/// form while the picker is open. Errors surface through [onError]; a learner
/// who backs out of the picker gets nothing, because cancelling isn't a fault.
class GoogleSignInButton extends ConsumerStatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onError,
    required this.onBusy,
    this.enabled = true,
  });

  final ValueChanged<String> onError;
  final ValueChanged<bool> onBusy;
  final bool enabled;

  @override
  ConsumerState<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends ConsumerState<GoogleSignInButton> {
  bool _busy = false;

  void _setBusy(bool value) {
    setState(() => _busy = value);
    widget.onBusy(value);
  }

  Future<void> _signIn() async {
    _setBusy(true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      // On success the router's redirect takes it from here; this widget is
      // already gone by the time that future completes.
    } on AuthFailure catch (e) {
      widget.onError(e.message);
    } catch (e) {
      widget.onError('Could not sign in with Google: $e');
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && !_busy;
    return OutlinedButton.icon(
      onPressed: on ? _signIn : null,
      icon: _busy
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            )
          : Opacity(
              // The mark is fixed-colour by Google's brand rules, so it can't
              // follow the scheme; dimming it matches a disabled button.
              opacity: on ? 1 : 0.4,
              child: Image.asset(
                'assets/images/google_g.png',
                height: 18,
                width: 18,
                filterQuality: FilterQuality.medium,
              ),
            ),
      label: Text(_busy ? 'Signing in…' : 'Continue with Google'),
    );
  }
}

/// "or" rule between the email form and the Google button.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Divider(color: scheme.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: Divider(color: scheme.outlineVariant)),
      ],
    );
  }
}
