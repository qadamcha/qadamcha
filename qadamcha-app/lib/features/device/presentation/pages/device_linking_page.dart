import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/device_entity.dart';
import '../bloc/device_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class DeviceLinkingPage extends StatefulWidget {
  const DeviceLinkingPage({super.key});

  @override
  State<DeviceLinkingPage> createState() => _DeviceLinkingPageState();
}

class _DeviceLinkingPageState extends State<DeviceLinkingPage> {
  @override
  void initState() {
    super.initState();
    context.read<DeviceBloc>().add(LoadDevicesEvent());
  }

  Future<void> _onRefresh() async {
    context.read<DeviceBloc>().add(LoadDevicesEvent());
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        elevation: 0,
        title: const Text('Qurilmalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DeviceBloc>().add(LoadDevicesEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listenWhen: (prev, curr) => curr.errorMessage != null && curr.errorMessage!.isNotEmpty && prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
            if (state.errorMessage!.contains('AUTH_REQUIRED')) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Sessiya muddati tugagi. Tizimga qayta kiring.'),
                   backgroundColor: AppColors.error,
                 ),
               );
               context.read<AuthBloc>().add(LogoutEvent());
            } else {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(state.errorMessage!),
                   backgroundColor: AppColors.error,
                 ),
               );
            }
          }
        },
        builder: (context, state) {
          if (state.status == DeviceLoadStatus.loading && state.devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _buildAutoLinkingInfo(),
                SizedBox(height: 24.h),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ulangan qurilmalar',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (state.status == DeviceLoadStatus.loading)
                      SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                SizedBox(height: 12.h),
                
                if (state.devices.isEmpty)
                  _buildEmptyDevices()
                else
                  ...state.devices.map((device) => _DeviceCard(
                    device: device,
                    onRemove: () => _showRemoveConfirmation(context, device),
                  )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoLinkingInfo() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Icon(Icons.devices, size: 48.sp, color: Colors.white),
          SizedBox(height: 12.h),
          Text(
            'Avtomatik qurilma ulash',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bola telefoniga ilovani o\'rnating va shu telefon raqam bilan kiring.\n'
            'Qurilma avtomatik ravishda bola qurilmasi sifatida ulanadi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDevices() {
    return Container(
      padding: EdgeInsets.all(32.w),
      child: Column(
        children: [
          Text('📱', style: TextStyle(fontSize: 64.sp)),
          SizedBox(height: 16.h),
          Text(
            'Hali boshqa qurilma ulanmagan',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Bola qurilmasidan shu raqam bilan kirilganda avtomatik ulanadi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, Device device) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Qurilmani o\'chirish'),
        content: Text('${device.deviceName}ni o\'chirishni xohlaysizmi?\n\nBu qurilma akkauntdan chiqariladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<DeviceBloc>().add(RemoveDeviceEvent(device.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('O\'chirish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onRemove;

  const _DeviceCard({
    required this.device,
    required this.onRemove,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              device.platform.emoji,
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${device.type.label} • ${device.platform.label}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '📅 ${_formatDate(device.linkedAt)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.error,
              size: 22.sp,
            ),
            tooltip: 'O\'chirish',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
