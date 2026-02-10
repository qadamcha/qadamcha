import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';

class PinInput extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int length;

  const PinInput({
    super.key,
    required this.controller,
    this.validator,
    this.obscureText = true,
    this.length = 4,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput> {
  bool _showPin = false;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    
    for (int i = 0; i < widget.length; i++) {
      _controllers[i].addListener(_updateMainController);
    }
  }

  void _updateMainController() {
    widget.controller.text = _controllers.map((c) => c.text).join();
  }

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _updateMainController();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator?.call(widget.controller.text),
      builder: (field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (index) {
                return SizedBox(
                  width: widget.length == 6 ? 48.w : 56.w,
                  height: widget.length == 6 ? 48.h : 56.h,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    obscureText: widget.obscureText && !_showPin,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _controllers[index].text.isNotEmpty
                          ? AppColors.primary.withOpacity(0.1)
                          : AppColors.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: field.hasError
                            ? const BorderSide(color: AppColors.error)
                            : BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: field.hasError
                            ? const BorderSide(color: AppColors.error)
                            : BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: field.hasError 
                              ? AppColors.error 
                              : AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (value) => _onDigitChanged(index, value),
                  ),
                );
              }),
            ),
            if (widget.obscureText)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: GestureDetector(
                  onTap: () => setState(() => _showPin = !_showPin),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showPin ? Icons.visibility_off : Icons.visibility,
                        size: 18.sp,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _showPin ? 'Yashirish' : 'Ko\'rsatish',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (field.hasError)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  field.errorText ?? '',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.error,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
