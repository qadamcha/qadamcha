import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/pin_dots.dart';
import '../widgets/pin_keypad.dart';
import '../../../home/presentation/pages/child_home_page.dart';

/// Child PIN Page — Bola rejimiga kirish uchun PIN kiritish
/// full_architecture.html dizayniga mos — child gradient va bola ismi
class ChildPinPage extends StatefulWidget {
  final String childName;

  const ChildPinPage({super.key, this.childName = 'Bolajon'});

  @override
  State<ChildPinPage> createState() => _ChildPinPageState();
}

class _ChildPinPageState extends State<ChildPinPage> {
  String _pin = '';
  String _error = '';
  bool _isLoading = false;

  void _onDigitEntered(String digit) {
    if (_pin.length < 4) {
      setState(() {
        _pin += digit;
        _error = '';
      });

      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _error = '';
      });
    }
  }

  void _verifyPin() {
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(AuthVerifyPinEvent(_pin));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state.status == AuthStatus.pinVerified) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const ChildHomePage()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.error) {
          setState(() {
            _isLoading = false;
            _error = state.errorMessage ?? 'PIN kod noto\'g\'ri';
            _pin = '';
          });
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A4A73), Color(0xFF2D6A9F), Color(0xFFE8F0F8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Back button
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22.sp),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),

                const Spacer(flex: 1),

                // Avatar
                Container(
                  width: 90.w,
                  height: 90.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(Icons.child_care_rounded, size: 44.sp, color: Colors.white),
                  ),
                ),

                SizedBox(height: 20.h),

                // Title
                Text(
                  'Salom, ${widget.childName}!',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontFamily: 'Nunito',
                  ),
                ),

                SizedBox(height: 8.h),

                Text(
                  'PIN kodingizni kiriting',
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: Colors.white.withOpacity(0.85),
                    fontFamily: 'Nunito',
                  ),
                ),

                SizedBox(height: 32.h),

                // PIN Dots
                PinDots(
                  currentLength: _pin.length,
                  errorMessage: _error,
                ),

                const Spacer(flex: 2),

                // Keypad
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: PinKeypad(
                    onDigitEntered: _onDigitEntered,
                    onBackspace: _onBackspace,
                    isLoading: _isLoading,
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
