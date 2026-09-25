import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/tb_theme.dart';
import '../providers/asset_provider.dart';
import '../services/auth_service.dart';
import '../widgets/tb_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = context.read<AuthService>();
      final AuthResult result;

      if (_isRegisterMode) {
        result = await authService.registerWithEmailPassword(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        result = await authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        if (result.isSuccess) {
          final assetProvider = context.read<AssetProvider>();
          final navigator = Navigator.of(context);
          assetProvider.setOwner(_emailController.text.trim());
          await assetProvider.syncWithBackend();
          if (mounted) {
            navigator.pushReplacementNamed('/home');
          }
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = result.errorMessage ?? 'Authentication failed';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication error. Please try again.';
        });
      }
    }
  }

  Future<void> _onDemoLogin() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final assetProvider = context.read<AssetProvider>();

      await authService.enterDemoMode();
      assetProvider.loadDemoData();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Demo entry error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TbColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo & Brand Header
                  AnimatedCardEntrance(
                    delayMs: 20,
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFF141416),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white24, width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.radar_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'TRACEBACK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'CAMPUS RECOVERY RADAR',
                          style: TextStyle(
                            color: TbColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // MAIN FLOATING CARD
                  AnimatedCardEntrance(
                    delayMs: 60,
                    child: TracebackCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mode Switcher Pill
                          Container(
                            width: double.infinity,
                            height: 40,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0A0A0A),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: TbColors.cardBorder),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (_isRegisterMode) {
                                        setState(() {
                                          _isRegisterMode = false;
                                          _errorMessage = null;
                                          _formKey.currentState?.reset();
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: !_isRegisterMode
                                            ? const Color(0xFF1C1C20)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        border: !_isRegisterMode
                                            ? Border.all(color: Colors.white12)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: !_isRegisterMode
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: !_isRegisterMode
                                              ? Colors.white
                                              : TbColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (!_isRegisterMode) {
                                        setState(() {
                                          _isRegisterMode = true;
                                          _errorMessage = null;
                                          _formKey.currentState?.reset();
                                        });
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _isRegisterMode
                                            ? const Color(0xFF1C1C20)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        border: _isRegisterMode
                                            ? Border.all(color: Colors.white12)
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Register',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: _isRegisterMode
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: _isRegisterMode
                                              ? Colors.white
                                              : TbColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Heading
                          Text(
                            _isRegisterMode ? 'Create Account' : 'Welcome Back',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _isRegisterMode
                                ? 'Register to safeguard your campus items'
                                : 'Sign in to access your recovery radar',
                            style: const TextStyle(
                              color: TbColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Error Message Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0x1AEF4444),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0x33EF4444)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: TbColors.statusLost,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFFCA5A5),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Full Name Field (Register mode only)
                          if (_isRegisterMode) ...[
                            _buildInputLabel('FULL NAME'),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: const Key('name_field'),
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              validator: (val) {
                                if (_isRegisterMode) {
                                  final text = val?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter your full name';
                                  }
                                }
                                return null;
                              },
                              decoration: _buildInputDecoration(
                                hint: 'e.g. Subhadeep Das',
                                icon: Icons.person_outline_rounded,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Email Field
                          _buildInputLabel('CAMPUS EMAIL'),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('email_field'),
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              final text = val?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!AuthService.isValidEmail(text)) {
                                return 'Please enter a valid email address';
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              hint: 'name@campus.edu',
                              icon: Icons.mail_outline_rounded,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Phone Number Field (Register mode only)
                          if (_isRegisterMode) ...[
                            _buildInputLabel('PHONE NUMBER'),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: const Key('phone_field'),
                              controller: _phoneController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              keyboardType: TextInputType.phone,
                              validator: (val) {
                                if (_isRegisterMode) {
                                  final text = val?.trim() ?? '';
                                  if (text.isEmpty) {
                                    return 'Please enter your phone number';
                                  }
                                  if (!AuthService.isValidPhone(text)) {
                                    return 'Please enter a valid 10-digit phone number';
                                  }
                                }
                                return null;
                              },
                              decoration: _buildInputDecoration(
                                hint: '10-digit mobile number',
                                icon: Icons.phone_outlined,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Password Field (Register & Login)
                          _buildInputLabel('PASSWORD'),
                          const SizedBox(height: 6),
                          TextFormField(
                            key: const Key('password_field'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            validator: (val) {
                              if (_isRegisterMode) {
                                if (val == null || val.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                              } else {
                                if (val == null || val.isEmpty) {
                                  return 'Please enter your password';
                                }
                              }
                              return null;
                            },
                            decoration: _buildInputDecoration(
                              hint: _isRegisterMode ? 'At least 6 characters' : 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: TbColors.textMuted,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const SizedBox(height: 8),

                          // Submit Button
                          InkWell(
                            key: const Key('continue_button'),
                            onTap: _isLoading ? null : _onSubmit,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.12),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isRegisterMode ? 'Create Account' : 'Sign In',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Quick Demo Login Button
                          InkWell(
                            key: const Key('try_demo_button'),
                            onTap: _isLoading ? null : _onDemoLogin,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: 46,
                              decoration: BoxDecoration(
                                color: const Color(0xFF141416),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: TbColors.cardBorder),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Explore Demo Environment',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: TbColors.textMuted,
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: TbColors.textMuted),
      prefixIcon: Icon(icon, size: 18, color: TbColors.textMuted),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0A0A0A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TbColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: TbColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white38),
      ),
    );
  }
}