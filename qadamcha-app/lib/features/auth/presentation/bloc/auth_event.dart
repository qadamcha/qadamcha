part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  
  @override
  List<Object?> get props => [];
}

class CheckAuthStatusEvent extends AuthEvent {}

class SendOtpEvent extends AuthEvent {
  final String phone;
  final String? purpose;
  
  const SendOtpEvent(this.phone, {this.purpose});
  
  @override
  List<Object?> get props => [phone, purpose];
}

class VerifyOtpEvent extends AuthEvent {
  final String phone;
  final String code;
  
  const VerifyOtpEvent({required this.phone, required this.code});
  
  @override
  List<Object?> get props => [phone, code];
}

class RegisterEvent extends AuthEvent {
  final String phone;
  final String name;
  final String pin;
  final String? childName;
  final int? childAge;
  final String? childGender;
  
  const RegisterEvent({
    required this.phone,
    required this.name,
    required this.pin,
    this.childName,
    this.childAge,
    this.childGender,
  });
  
  @override
  List<Object?> get props => [phone, name, pin, childName, childAge, childGender];
}

class LoginEvent extends AuthEvent {
  final String phone;
  final String pin;
  final String deviceId;
  
  const LoginEvent({
    required this.phone,
    required this.pin,
    required this.deviceId,
  });
  
  @override
  List<Object?> get props => [phone, pin, deviceId];
}

class LogoutEvent extends AuthEvent {}

class ResetAuthEvent extends AuthEvent {}

class ResetPinEvent extends AuthEvent {
  final String phone;
  final String newPin;
  
  const ResetPinEvent({required this.phone, required this.newPin});
  
  @override
  List<Object?> get props => [phone, newPin];
}

class AuthVerifyPinEvent extends AuthEvent {
  final String pin;
  
  const AuthVerifyPinEvent(this.pin);
  
  @override
  List<Object?> get props => [pin];
}

class UpdateProfileEvent extends AuthEvent {
  final String name;
  
  const UpdateProfileEvent({required this.name});
  
  @override
  List<Object?> get props => [name];
}

class ChangePinEvent extends AuthEvent {
  final String currentPin;
  final String newPin;
  final String phone;
  
  const ChangePinEvent({
    required this.currentPin,
    required this.newPin,
    required this.phone,
  });
  
  @override
  List<Object?> get props => [currentPin, newPin, phone];
}

