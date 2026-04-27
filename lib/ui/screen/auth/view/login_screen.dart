import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/ui/screen/auth/view_model/auth_viewmodel.dart';
import 'package:velotolouse/ui/screen/auth/view/register_screen.dart';
import 'package:velotolouse/ui/screen/map/view/map_screen.dart';
import 'package:velotolouse/ui/widgets/app_logo.dart';
import 'package:velotolouse/ui/widgets/custom_text_field.dart';
import 'package:velotolouse/ui/widgets/error_message.dart';
import 'package:velotolouse/ui/widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to read text from the input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers when the screen is removed
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Called when the user taps "Login"
  void _handleLogin() async {
    final authViewModel = context.read<AuthViewModel>();

    // Call the login method in the provider (all logic lives there)
    final success = await authViewModel.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // If login succeeded, go to the map screen
    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider so the UI rebuilds when state changes
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App icon
                  const AppLogo(),
                  const SizedBox(height: 16),

                  // App title
                  const Text(
                    'VeloToulouse',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email input field
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password input field
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock,
                    obscureText: true, // Hide the password text
                  ),
                  const SizedBox(height: 8),

                  // Show error message if login failed
                  if (authViewModel.error != null)
                    ErrorMessage(message: authViewModel.error!),
                  const SizedBox(height: 16),

                  // Login button (shows loading spinner while waiting)
                  PrimaryButton(
                    text: 'Login',
                    isLoading: authViewModel.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: 16),

                  // Link to register screen
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text("Don't have an account? Register"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
