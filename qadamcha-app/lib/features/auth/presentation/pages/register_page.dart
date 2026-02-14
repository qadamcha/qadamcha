import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/back_button_box.dart';
import '../../../../core/widgets/gradient_button.dart';
import '../bloc/auth_bloc.dart';
import 'pin_create_page.dart';

/// Register Page - matching full_architecture.html design
/// 📝 emoji header, user details with icons, gender toggle
class RegisterPage extends StatefulWidget {
  final String phone;

  const RegisterPage({super.key, required this.phone});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _childNameController = TextEditingController();
  final _childAgeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _childGender = 'boy'; // 'boy' or 'girl'

  @override
  void dispose() {
    _nameController.dispose();
    _childNameController.dispose();
    _childAgeController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PinCreatePage(
            phone: widget.phone,
            name: _nameController.text.trim(),
            childName: _childNameController.text.trim(),
            childAge: int.tryParse(_childAgeController.text.trim()) ?? 5,
            childGender: _childGender,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Back button
                BackButtonBox(
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 20),
                // Title
                const Text(
                  "📝 Ma'lumotlaringiz",
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Ro'yxatdan o'tish uchun to'ldiring",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 22),
                // Name Input
                _buildInput(
                  controller: _nameController,
                  label: '👤 Ismingiz',
                  hint: 'Masalan: Alisher',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ismingizni kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Child Name Input
                _buildInput(
                  controller: _childNameController,
                  label: '🧒 Bolangiz ismi',
                  hint: 'Masalan: Sardor',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Bolangiz ismini kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                // Child Age Input
                _buildInput(
                  controller: _childAgeController,
                  label: '🎂 Bolangiz yoshi',
                  hint: '5',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Yoshini kiriting';
                    }
                    final age = int.tryParse(value.trim());
                    if (age == null || age < 1 || age > 18) {
                      return 'Yosh 1-18 orasida bolishi kerak';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Gender selection
                const Text(
                  'Jinsi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Nunito',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildGenderButton(
                      emoji: "👦",
                      label: "O'g'il",
                      value: 'boy',
                    ),
                    const SizedBox(width: 12),
                    _buildGenderButton(
                      emoji: '👧',
                      label: 'Qiz',
                      value: 'girl',
                    ),
                  ],
                ),
                const Spacer(),
                // Submit Button
                GradientButton(
                  onPressed: _continue,
                  text: 'Davom etish →',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Nunito',
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textDisabled,
              fontSize: 15,
              fontFamily: 'Nunito',
            ),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildGenderButton({
    required String emoji,
    required String label,
    required String value,
  }) {
    final isSelected = _childGender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _childGender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.5 : 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
