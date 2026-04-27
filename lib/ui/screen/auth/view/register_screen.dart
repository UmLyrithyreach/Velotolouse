import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:velotolouse/ui/screen/auth/view_model/auth_viewmodel.dart';
import 'package:velotolouse/ui/screen/map/view/map_screen.dart';
import 'package:velotolouse/ui/widgets/app_logo.dart';
import 'package:velotolouse/ui/widgets/custom_text_field.dart';
import 'package:velotolouse/ui/widgets/error_message.dart';
import 'package:velotolouse/ui/widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to read text from the input fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Clean up controllers when the screen is removed
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Called when the user taps "Register"
  void _handleRegister() async {
    final authViewModel = context.read<AuthViewModel>();

    // Call the register method in the provider (all logic lives there)
    final success = await authViewModel.register(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // If registration succeeded, go to the map screen
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

                  // Title
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name input field
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Name',
                    prefixIcon: Icons.person,
                  ),
                  const SizedBox(height: 16),

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

                  // Show error message if registration failed
                  if (authViewModel.error != null)
                    ErrorMessage(message: authViewModel.error!),
                  const SizedBox(height: 16),

                  // Register button (shows loading spinner while waiting)
                  PrimaryButton(
                    text: 'Register',
                    isLoading: authViewModel.isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: 16),

                  // Link back to login screen
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Go back to login
                    },
                    child: const Text('Already have an account? Login'),
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
