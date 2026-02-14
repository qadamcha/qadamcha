import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';

/// PIN tiklash sahifasi — multi-step oqim
/// full_architecture.html Bo'lim 7: PIN tiklash (7 ekran)
class PinResetPage extends StatefulWidget {
  const PinResetPage({super.key});

  @override
  State<PinResetPage> createState() => _PinResetPageState();
}

class _PinResetPageState extends State<PinResetPage> {
  int _step = 0; // 0: raqam, 1: SMS, 2: yangi PIN, 3: tasdiqlash, 4: muvaffaqiyat
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String _newPin = '';
  String _confirmPin = '';
  String _error = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 9) {
      setState(() => _error = 'Telefon raqamni to\'liq kiriting');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    context.read<AuthBloc>().add(SendOtpEvent('+998$phone'));
  }

  void _verifyOtp() {
    final code = _otpController.text.trim();
    if (code.length < 6) {
      setState(() => _error = 'Tasdiqlash kodini to\'liq kiriting');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = '';
    });
    context.read<AuthBloc>().add(
        VerifyOtpEvent(phone: '+998${_phoneController.text.trim()}', code: code));
  }

  void _onNewPinDigit(String digit) {
    if (_newPin.length < 4) {
      setState(() {
        _newPin += digit;
        _error = '';
      });
      if (_newPin.length == 4) {
        setState(() => _step = 3);
      }
    }
  }

  void _onNewPinBackspace() {
    if (_newPin.isNotEmpty) {
      setState(() => _newPin = _newPin.substring(0, _newPin.length - 1));
    }
  }

  void _onConfirmPinDigit(String digit) {
    if (_confirmPin.length < 4) {
      setState(() {
        _confirmPin += digit;
        _error = '';
      });
      if (_confirmPin.length == 4) {
        _submitPinReset();
      }
    }
  }

  void _onConfirmPinBackspace() {
    if (_confirmPin.isNotEmpty) {
      setState(() => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1));
    }
  }

  void _submitPinReset() {
    if (_newPin != _confirmPin) {
      setState(() {
        _error = 'PIN kodlar mos kelmadi';
        _confirmPin = '';
      });
      return;
    }
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(
        ResetPinEvent(phone: '+998${_phoneController.text.trim()}', newPin: _newPin));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _isLoading = false);

        if (state.status == AuthStatus.otpSent && _step == 0) {
          setState(() => _step = 1);
        } else if (state.status == AuthStatus.otpVerified && _step == 1) {
          setState(() => _step = 2);
        } else if (state.status == AuthStatus.pinReset) {
          setState(() => _step = 4);
        } else if (state.status == AuthStatus.error) {
          setState(() => _error = state.errorMessage ?? 'Xatolik yuz berdi');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new_rounded, size: 22.sp),
                      onPressed: () {
                        if (_step > 0 && _step < 4) {
                          setState(() {
                            _step--;
                            _error = '';
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Spacer(),
                    Text(
                      'PIN tiklash',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontFamily: 'Nunito',
                      ),
                    ),
                    const Spacer(),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),

              // Progress
              if (_step < 4)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Row(
                    children: List.generate(4, (i) {
                      return Expanded(
                        child: Container(
                          height: 4.h,
                          margin: EdgeInsets.symmetric(horizontal: 2.w),
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? AppColors.primary
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              SizedBox(height: 8.h),

              // Content
              Expanded(
                child: _buildStepContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return _buildPhoneStep();
      case 1:
        return _buildOtpStep();
      case 2:
        return _buildNewPinStep();
      case 3:
        return _buildConfirmPinStep();
      case 4:
        return _buildSuccessStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPhoneStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('📱', style: TextStyle(fontSize: 40.sp)),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Telefon raqamingizni kiriting',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Ro\'yxatdan o\'tgan raqamingizga SMS kod yuboramiz',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 32.h),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: AppColors.border)),
                  ),
                  child: Text(
                    '+998',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Nunito',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontFamily: 'Nunito',
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '90 123 45 67',
                      hintStyle: TextStyle(color: AppColors.textDisabled),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                      fillColor: Colors.transparent,
                      filled: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              _error,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.error,
                fontFamily: 'Nunito',
              ),
            ),
          ],
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'SMS kod yuborish',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('✉️', style: TextStyle(fontSize: 40.sp)),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Tasdiqlash kodi',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            '+998 ${_phoneController.text} raqamiga kod yuborildi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
              fontFamily: 'Nunito',
            ),
          ),
          SizedBox(height: 32.h),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              fontFamily: 'Nunito',
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              hintStyle: TextStyle(color: AppColors.textDisabled),
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          if (_error.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              _error,
              style: TextStyle(fontSize: 13.sp, color: AppColors.error),
            ),
          ],
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      'Tasdiqlash',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Nunito',
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPinStep() {
    return Column(
      children: [
        SizedBox(height: 40.h),
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppColors.purple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('🔐', style: TextStyle(fontSize: 40.sp)),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Yangi PIN yarating',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '4 xonali yangi PIN kodni kiriting',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 32.h),
        PinDots(currentLength: _newPin.length, errorMessage: _error),
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: PinKeypad(
            onDigitEntered: _onNewPinDigit,
            onBackspace: _onNewPinBackspace,
            isLoading: false,
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildConfirmPinStep() {
    return Column(
      children: [
        SizedBox(height: 40.h),
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('🔑', style: TextStyle(fontSize: 40.sp)),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'PIN ni tasdiqlang',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Yangi PIN kodni qayta kiriting',
          style: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'Nunito',
          ),
        ),
        SizedBox(height: 32.h),
        PinDots(currentLength: _confirmPin.length, errorMessage: _error),
        const Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: PinKeypad(
            onDigitEntered: _onConfirmPinDigit,
            onBackspace: _onConfirmPinBackspace,
            isLoading: _isLoading,
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }

  Widget _buildSuccessStep() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('✅', style: TextStyle(fontSize: 52.sp)),
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              'PIN yangilandi!',
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Yangi PIN kodingiz muvaffaqiyatli saqlandi.\nEndi kirish uchun foydalanishingiz mumkin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                color: AppColors.textSecondary,
                height: 1.5,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 40.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'Kirish sahifasiga qaytish',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Nunito',
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
