import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../engine/sound_service.dart';

/// Bo'yash ekranidagi ovoz sozlamalari bottom sheet.
/// BG musiqa va SFX ovoz balandligini sozlash imkonini beradi.
class SoundSettingsSheet extends StatefulWidget {
  const SoundSettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SoundSettingsSheet(),
    );
  }

  @override
  State<SoundSettingsSheet> createState() => _SoundSettingsSheetState();
}

class _SoundSettingsSheetState extends State<SoundSettingsSheet> {
  final _sound = SoundService();
  late double _bgVol;
  late double _sfxVol;

  @override
  void initState() {
    super.initState();
    _bgVol = _sound.bgVolume;
    _sfxVol = _sound.sfxVolume;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 16.h),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.tune_rounded,
                  size: 24.sp, color: const Color(0xFF7C3AED)),
              SizedBox(width: 8.w),
              Text(
                'Ovoz sozlamalari',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // BG Music slider
          _buildVolumeSlider(
            icon: Icons.music_note_rounded,
            label: 'Musiqa',
            value: _bgVol,
            color: const Color(0xFF7C3AED),
            onChanged: (v) {
              setState(() => _bgVol = v);
              _sound.setBgVolume(v);
            },
          ),
          SizedBox(height: 12.h),

          // SFX slider
          _buildVolumeSlider(
            icon: Icons.volume_up_rounded,
            label: 'Ovoz effektlari',
            value: _sfxVol,
            color: const Color(0xFFF97316),
            onChanged: (v) {
              setState(() => _sfxVol = v);
              _sound.setSfxVolume(v);
              // Demo ovoz
              if (v > 0) _sound.playPop();
            },
          ),

          SizedBox(height: 20.h),

          // Close button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 4,
                ),
                child: Text(
                  'Tayyor ✓',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 12.h),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          // Icon + Label
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          SizedBox(
            width: 80.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
                Text(
                  '${(value * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          // Slider
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: color,
                inactiveTrackColor: color.withValues(alpha: 0.15),
                thumbColor: color,
                overlayColor: color.withValues(alpha: 0.1),
                trackHeight: 6.h,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 10.r),
              ),
              child: Slider(
                value: value,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          // Mute icon
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(value > 0 ? 0.0 : 0.5);
            },
            child: Icon(
              value > 0
                  ? Icons.volume_up_rounded
                  : Icons.volume_off_rounded,
              color: value > 0 ? color : Colors.grey,
              size: 22.sp,
            ),
          ),
        ],
      ),
    );
  }
}
