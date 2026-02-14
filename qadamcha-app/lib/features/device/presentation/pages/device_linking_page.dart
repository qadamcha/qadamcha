import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../child/presentation/bloc/child_bloc.dart';
import '../../domain/entities/device_entity.dart';
import '../bloc/device_bloc.dart';

class DeviceLinkingPage extends StatefulWidget {
  const DeviceLinkingPage({super.key});

  @override
  State<DeviceLinkingPage> createState() => _DeviceLinkingPageState();
}

class _DeviceLinkingPageState extends State<DeviceLinkingPage> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    context.read<DeviceBloc>().add(LoadDevicesEvent());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ignore: unused_element
  void _startCountdown(Duration duration) {
    _remainingSeconds = duration.inSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
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
                // Generate Code Section
                _buildGenerateCodeSection(context, state),
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

  Widget _buildGenerateCodeSection(BuildContext context, DeviceState state) {
    final childState = context.watch<ChildBloc>().state;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          Text(
            'Bola qurilmasini ulash',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'QR kodni bola qurilmasidan skanerlang',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 20.h),
          
          // QR Code or Generate Button
          if (state.linkingCode != null && !state.linkingCode!.isExpired) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: state.linkingCode!.code,
                    version: QrVersions.auto,
                    size: 180.w,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Code display
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: state.linkingCode!.code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Kod nusxalandi')),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.linkingCode!.code,
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Icon(Icons.copy, size: 20.sp, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Amal qilish muddati: ${_formatDuration(Duration(seconds: _remainingSeconds))}',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Child selector
            if (childState.children.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButton<String>(
                  value: childState.selectedChild?.id,
                  dropdownColor: AppColors.primary,
                  style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  underline: const SizedBox(),
                  isExpanded: true,
                  items: childState.children.map((child) {
                    return DropdownMenuItem(
                      value: child.id,
                      child: Text(child.name),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      context.read<ChildBloc>().add(SelectChildEvent(id));
                    }
                  },
                ),
              ),
              SizedBox(height: 16.h),
            ],
            ElevatedButton.icon(
              onPressed: state.isGeneratingCode
                  ? null
                  : () {
                      final selectedChild = childState.selectedChild;
                      if (selectedChild != null) {
                        context.read<DeviceBloc>().add(
                          GenerateLinkingCodeEvent(selectedChild.id),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
              ),
              icon: state.isGeneratingCode
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code),
              label: Text(state.isGeneratingCode ? 'Yaratilmoqda...' : 'QR kod yaratish'),
            ),
          ],
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
            'Hali qurilma ulanmagan',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Yuqoridagi QR kodni bola qurilmasidan skanerlang',
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
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
