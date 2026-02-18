import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/device_entity.dart';
import '../bloc/device_bloc.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
      body: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, state) {
          if (state.status == DeviceLoadStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info section
                _buildAutoLinkingInfo(),
                SizedBox(height: 24.h),
                
                // Devices List
                Text(
                  'Ulangan qurilmalar',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 12.h),
                
                if (state.devices.isEmpty)
                  _buildEmptyDevices()
                else
                  ...state.devices.map((device) => _DeviceCard(
                    device: device,
                    onBlock: () {
                      context.read<DeviceBloc>().add(BlockDeviceEvent(device.id));
                    },
                    onUnblock: () {
                      context.read<DeviceBloc>().add(UnblockDeviceEvent(device.id));
                    },
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
              color: Colors.white.withOpacity(0.9),
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
        title: const Text('Qurilmani o\'chirish'),
        content: Text('${device.deviceName}ni o\'chirishni xohlaysizmi?'),
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
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onBlock;
  final VoidCallback onUnblock;
  final VoidCallback onRemove;

  const _DeviceCard({
    required this.device,
    required this.onBlock,
    required this.onUnblock,
    required this.onRemove,
  });

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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Device Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: device.isOnline 
                  ? AppColors.success.withOpacity(0.1) 
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              device.platform.emoji,
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
          SizedBox(width: 16.w),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      device.deviceName,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: device.isOnline ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  '${device.type.label} • ${device.platform.label}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (device.status == DeviceStatus.blocked) ...[
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Bloklangan',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Actions
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              if (device.status == DeviceStatus.blocked)
                PopupMenuItem(
                  onTap: onUnblock,
                  child: const Row(
                    children: [
                      Icon(Icons.lock_open, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Blokdan chiqarish'),
                    ],
                  ),
                )
              else
                PopupMenuItem(
                  onTap: onBlock,
                  child: const Row(
                    children: [
                      Icon(Icons.block, color: AppColors.warning),
                      SizedBox(width: 8),
                      Text('Bloklash'),
                    ],
                  ),
                ),
              PopupMenuItem(
                onTap: onRemove,
                child: const Row(
                  children: [
                    Icon(Icons.delete, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('O\'chirish', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
