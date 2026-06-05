import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/language_toggle.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Register page — fullName, email/phone, password, company code
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyCodeController = TextEditingController();
  bool _showCompanyCode = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyCodeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('auth.please_accept_terms'.tr()),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      final identifier = _emailController.text.trim();
      final isEmail = identifier.contains('@');

      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          email: isEmail ? identifier : null,
          phone: !isEmail ? identifier : null,
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          companyCode: _showCompanyCode
              ? _companyCodeController.text.trim()
              : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.go('/'),
                        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const LanguageToggle(),
                    ],
                  ),

                const SizedBox(height: 24),

                Text(
                  'auth.create_account'.tr(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.join_runly'.tr(),
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: 32),

                CustomTextField(
                  label: 'auth.name'.tr(),
                  hint: 'auth.enter_name'.tr(),
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'auth.please_enter_name'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'auth.email_or_phone'.tr(),
                  hint: 'auth.enter_email_or_phone'.tr(),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'auth.please_enter_email_or_phone'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'auth.password'.tr(),
                  hint: 'auth.min_characters'.tr(),
                  controller: _passwordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'auth.please_enter_password'.tr();
                    }
                    if (value.length < 6) {
                      return 'auth.password_min_length'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                CustomTextField(
                  label: 'auth.confirm_password'.tr(),
                  hint: 'auth.enter_password_confirm'.tr(),
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'auth.passwords_do_not_match'.tr();
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Optional company code section
                GestureDetector(
                  onTap: () => setState(() => _showCompanyCode = !_showCompanyCode),
                  child: Row(
                    children: [
                      Icon(
                        _showCompanyCode
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'auth.i_have_company_code'.tr(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),

                if (_showCompanyCode) ...[
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'auth.company_code'.tr(),
                    hint: 'auth.enter_company_code_hint'.tr(),
                    controller: _companyCodeController,
                    prefixIcon: const Icon(Icons.business_outlined, size: 20),
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty && value.trim().length != 6) {
                        return 'auth.company_code_length'.tr();
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // EULA checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.push('/terms'),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary.withValues(alpha: 0.8),
                            ),
                            children: [
                              TextSpan(text: 'auth.i_agree_to'.tr()),
                              TextSpan(
                                text: 'settings.terms'.tr(),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return CustomButton(
                      text: 'auth.register'.tr(),
                      isLoading: state is AuthLoading,
                      onPressed: _handleRegister,
                    );
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'auth.already_have_account'.tr(),
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'auth.login'.tr(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Business registration redirect
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.business_center_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'auth.are_you_company'.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'auth.register_company_desc'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(
                              'https://walktogether-admin.vercel.app/register-company',
                            );
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: Text('auth.register_company'.tr()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }
}
