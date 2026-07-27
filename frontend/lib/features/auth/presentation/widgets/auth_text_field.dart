import 'package:flutter/material.dart';
import 'package:split_frontend/core/constants/app_spacing.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? placeholder;
  final TextEditingController controller;
  final bool isPassword;
  final bool enabled;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    this.placeholder,
    this.isPassword = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;
  bool _isFocused = false;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_handleFocusChange);
    _obscureText = widget.isPassword;
  }

  void _handleFocusChange() {
    if (mounted && _isFocused != _effectiveFocusNode.hasFocus) {
      setState(() {
        _isFocused = _effectiveFocusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  void _togglePasswordVisibility() {
    if (!widget.enabled) return;
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    final borderColor = hasError
        ? colorScheme.error
        : (_isFocused
              ? colorScheme.primary
              : Colors.white.withValues(alpha: 0.1));

    return Semantics(
      label: widget.label,
      textField: true,
      enabled: widget.enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: textTheme.labelSmall?.copyWith(
              color: hasError
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.unit),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: borderColor,
                  width: _isFocused || hasError ? 2.0 : 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    focusNode: _effectiveFocusNode,
                    enabled: widget.enabled,
                    obscureText: widget.isPassword && _obscureText,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    onChanged: widget.onChanged,
                    onFieldSubmitted: widget.onSubmitted,
                    style: textTheme.bodyLarge?.copyWith(
                      color: widget.enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    cursorColor: colorScheme.primary,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.isPassword)
                  Semantics(
                    button: true,
                    label: 'Toggle password visibility',
                    enabled: widget.enabled,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.enabled
                            ? _togglePasswordVisibility
                            : null,
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 48.0,
                            minHeight: 48.0,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: widget.enabled
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurfaceVariant.withValues(
                                    alpha: 0.5,
                                  ),
                            size: 20.0,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.unit),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 14.0,
                    color: colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.unit),
                  Expanded(
                    child: Text(
                      widget.errorText!,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
