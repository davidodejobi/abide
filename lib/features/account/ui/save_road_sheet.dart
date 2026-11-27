import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:openbaptisthymnal/core/utils/extensions/string_extensions.dart';
import 'package:openbaptisthymnal/core/theme/lum_theme.dart';
import 'package:openbaptisthymnal/core/widgets/lum_button.dart';

import '../domain/auth_repository.dart';
import '../providers/account_providers.dart';
import 'account_strings.dart';

Future<void> showSaveRoadSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    useRootNavigator: true,
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: context.lum.bgPage,
    builder: (_) => const SaveRoadSheet(),
  );
}

enum _Step { email, code, success }

const _resendSeconds = 30;

/// Email, then a 6-digit code, then a success state. "Not now" is always there.
class SaveRoadSheet extends ConsumerStatefulWidget {
  const SaveRoadSheet({super.key});

  @override
  ConsumerState<SaveRoadSheet> createState() => _SaveRoadSheetState();
}

class _SaveRoadSheetState extends ConsumerState<SaveRoadSheet> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  _Step _step = _Step.email;
  bool _busy = false;
  AuthFailureKind? _error;
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn--);
      if (_resendIn <= 0) t.cancel();
    });
  }

  /// Runs [op] with the busy flag and maps any failure to an inline error.
  Future<bool> _run(Future<void> Function() op) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await op();
      return true;
    } on AuthFailure catch (f) {
      if (mounted && f.kind != AuthFailureKind.cancelled) {
        setState(() => _error = f.kind);
      }
    } catch (_) {
      if (mounted) setState(() => _error = AuthFailureKind.unknown);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    return false;
  }

  Future<void> _native(Future<void> Function(AuthRepository r) op) async {
    final ok = await _run(() => op(ref.read(authRepositoryProvider)!));
    if (ok && mounted) setState(() => _step = _Step.success);
  }

  Future<void> _sendCode() async {
    final email = _email.text.trim();
    final ok =
        await _run(() => ref.read(authRepositoryProvider)!.sendEmailCode(email));
    if (ok && mounted) {
      _code.clear();
      setState(() => _step = _Step.code);
      _startResendTimer();
    }
  }

  Future<void> _resend() async {
    final ok = await _run(() =>
        ref.read(authRepositoryProvider)!.sendEmailCode(_email.text.trim()));
    if (ok && mounted) _startResendTimer();
  }

  Future<void> _verify() async {
    if (_code.text.length != 6 || _busy) return;
    final email = _email.text.trim();
    final ok = await _run(
        () => ref.read(authRepositoryProvider)!.verifyCode(email, _code.text));
    if (ok && mounted) {
      _timer?.cancel();
      setState(() => _step = _Step.success);
    } else if (mounted) {
      _code.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.lum;
    final email = _email.text.trim();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          LumSize.screenGutter,
          0,
          LumSize.screenGutter,
          LumSpace.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: AnimatedSwitcher(
          duration: LumMotion.base,
          child: Column(
            key: ValueKey(_step),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: switch (_step) {
              _Step.email => _emailStep(c),
              _Step.code => _codeStep(c, email),
              _Step.success => _successStep(c, email),
            },
          ),
        ),
      ),
    );
  }

  bool get _hasNative {
    final r = ref.read(authRepositoryProvider);
    return r != null && (r.appleAvailable || r.googleAvailable);
  }

  Widget _title(LumColors c, String text) => Semantics(
        header: true,
        child: Text(text,
            style: LumText.title2.copyWith(color: c.textPrimary)),
      );

  Widget _errorText(LumColors c) => _error == null
      ? const SizedBox(height: LumSpace.lg)
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: LumSpace.md),
          child: Semantics(
            liveRegion: true,
            child: Text(AccountStrings.error(_error!),
                style: LumText.subheadline.copyWith(color: c.textDanger)),
          ),
        );

  Widget _notNow() => Center(
        child: TextButton(
          style: TextButton.styleFrom(
              minimumSize: const Size(LumSize.touchTarget, LumSize.touchTarget)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AccountStrings.notNow),
        ),
      );

  Widget _busyIcon() => const SizedBox(
      width: 18,
      height: 18,
      child: CircularProgressIndicator(strokeWidth: 2));

  List<Widget> _emailStep(LumColors c) => [
        _title(c, AccountStrings.title),
        const SizedBox(height: LumSpace.xs),
        Text(AccountStrings.body,
            style: LumText.subheadline.copyWith(color: c.textSecondary)),
        const SizedBox(height: LumSpace.lg),
        if (ref.watch(authRepositoryProvider)?.appleAvailable ?? false) ...[
          // Apple's guidelines: a black (or white) button with the Apple logo.
          // Primary is ink in light mode and paper in dark mode.
          LumButton(
            label: AccountStrings.continueApple,
            icon: Icon(PhosphorIcons.appleLogo(PhosphorIconsStyle.fill)),
            onPressed: _busy ? null : () => _native((r) => r.signInWithApple()),
          ),
          const SizedBox(height: LumSpace.sm),
        ],
        if (ref.watch(authRepositoryProvider)?.googleAvailable ?? false) ...[
          LumButton(
            label: AccountStrings.continueGoogle,
            kind: LumButtonKind.secondary,
            // Google's own four-colour G: brand rules ask for it, and it is
            // easier to recognise than a one-colour glyph.
            icon: VectorGraphic(
              loader: AssetBytesLoader('google_g'.iconSvg),
              width: LumSize.iconSm,
              height: LumSize.iconSm,
            ),
            onPressed: _busy ? null : () => _native((r) => r.signInWithGoogle()),
          ),
          const SizedBox(height: LumSpace.sm),
        ],
        if (_hasNative)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LumSpace.sm),
            child: Text(AccountStrings.orEmail,
                textAlign: TextAlign.center,
                style: LumText.subheadline.copyWith(color: c.textSecondary)),
          ),
        TextField(
          controller: _email,
          readOnly: _busy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _email.text.trim().isEmpty ? null : _sendCode(),
          decoration: const InputDecoration(
            labelText: AccountStrings.emailLabel,
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: LumSize.touchTarget),
          ),
        ),
        _errorText(c),
        LumButton(
          label: AccountStrings.sendCode,
          icon: _busy ? _busyIcon() : null,
          onPressed: _busy || _email.text.trim().isEmpty ? null : _sendCode,
        ),
        _notNow(),
      ];

  List<Widget> _codeStep(LumColors c, String email) => [
        _title(c, AccountStrings.title),
        const SizedBox(height: LumSpace.xs),
        Text(AccountStrings.codeSent(email),
            style: LumText.subheadline.copyWith(color: c.textSecondary)),
        const SizedBox(height: LumSpace.lg),
        // One field instead of six boxes: paste, autofill and the keyboard's
        // one-time-code suggestion all work, and it verifies on the sixth digit.
        TextField(
          controller: _code,
          readOnly: _busy,
          autofocus: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: LumText.title1.copyWith(color: c.textPrimary, letterSpacing: 12),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          onChanged: (v) {
            setState(() {});
            if (v.length == 6) _verify();
          },
          decoration: const InputDecoration(
            labelText: AccountStrings.codeLabel,
            border: OutlineInputBorder(),
            constraints: BoxConstraints(minHeight: LumSize.touchTarget),
          ),
        ),
        _errorText(c),
        LumButton(
          label: AccountStrings.verify,
          icon: _busy ? _busyIcon() : null,
          onPressed: _busy || _code.text.length != 6 ? null : _verify,
        ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize:
                      const Size(LumSize.touchTarget, LumSize.touchTarget)),
              onPressed: _busy || _resendIn > 0 ? null : _resend,
              child: Text(_resendIn > 0
                  ? AccountStrings.resendIn(_resendIn)
                  : AccountStrings.resend),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  minimumSize:
                      const Size(LumSize.touchTarget, LumSize.touchTarget)),
              onPressed: _busy
                  ? null
                  : () => setState(() {
                        _step = _Step.email;
                        _error = null;
                        _timer?.cancel();
                      }),
              child: const Text(AccountStrings.changeEmail),
            ),
          ],
        ),
        _notNow(),
      ];

  List<Widget> _successStep(LumColors c, String email) => [
        const SizedBox(height: LumSpace.md),
        Semantics(
          liveRegion: true,
          header: true,
          child: Text(AccountStrings.successTitle,
              style: LumText.title2.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LumSpace.xs),
        Text(AccountStrings.successBody(email),
            style: LumText.subheadline.copyWith(color: c.textSecondary)),
        const SizedBox(height: LumSpace.xl),
        LumButton(
          label: AccountStrings.done,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ];
}
