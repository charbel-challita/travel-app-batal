import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> currentUser;

  const EditProfileScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final avatarUrlController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  String? errorMessage;
  Uint8List? selectedAvatarBytes;

  static const blue = Color(0xFF2563EB);
  static const grey = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();

    final fullName = (widget.currentUser['full_name'] ?? '').toString();
    final parts = fullName.trim().split(' ');

    firstNameController.text = parts.isNotEmpty ? parts.first : '';
    lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    emailController.text = (widget.currentUser['email'] ?? '').toString();
    avatarUrlController.text = (widget.currentUser['avatar_url'] ?? '').toString();
  }

  InputDecoration fieldDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: grey),
      floatingLabelStyle: const TextStyle(
        color: blue,
        fontWeight: FontWeight.w600,
      ),
      border: const OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: blue, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      suffixIcon: suffixIcon,
    );
  }

  Future<void> pickAvatarImage() async {
    final picker = ImagePicker();

    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 600,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);

    setState(() {
      selectedAvatarBytes = bytes;
      avatarUrlController.text = 'data:image/jpeg;base64,$base64Image';
    });
  }

  String? validateForm() {
    if (firstNameController.text.trim().isEmpty) {
      return 'First name is required.';
    }

    if (lastNameController.text.trim().isEmpty) {
      return 'Last name is required.';
    }

    if (!ApiService.isValidEmail(emailController.text)) {
      return 'Please enter a valid email address.';
    }

    final newPassword = passwordController.text.trim();
    if (newPassword.isNotEmpty && newPassword.length < 6) {
      return 'Password must be at least 6 characters.';
    }

    return null;
  }

  Future<void> saveProfile() async {
    final validationError = validateForm();
    if (validationError != null) {
      setState(() {
        errorMessage = validationError;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ApiService.updateCurrentUser(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        avatarUrl: avatarUrlController.text.trim().isEmpty
            ? null
            : avatarUrlController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        errorMessage = ApiService.cleanErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    avatarUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = avatarUrlController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: blue.withOpacity(0.12),
                  backgroundImage: selectedAvatarBytes != null
                      ? MemoryImage(selectedAvatarBytes!)
                      : avatarUrl.startsWith('data:image')
                          ? MemoryImage(
                              base64Decode(avatarUrl.split(',').last),
                            )
                          : avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                  child: avatarUrl.isEmpty && selectedAvatarBytes == null
                      ? const Icon(
                          Icons.person,
                          color: blue,
                          size: 50,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: pickAvatarImage,
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: blue,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            TextField(
              controller: firstNameController,
              decoration: fieldDecoration('First name'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: lastNameController,
              decoration: fieldDecoration('Last name'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration('Email'),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              decoration: fieldDecoration(
                'New password',
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: grey,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: avatarUrlController,
              keyboardType: TextInputType.url,
              onChanged: (_) {
                setState(() {});
              },
              decoration: fieldDecoration('Photo URL'),
            ),

            const SizedBox(height: 8),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Leave password empty if you do not want to change it.',
                style: TextStyle(
                  color: grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            if (errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue,
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: Colors.black26,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: isLoading ? null : saveProfile,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
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
