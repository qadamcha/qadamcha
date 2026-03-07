import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../data/coloring_storage.dart';
import '../engine/sound_service.dart';

/// Saqlangan rasmlar galereyasi
class MyArtworksScreen extends StatefulWidget {
  const MyArtworksScreen({super.key});

  @override
  State<MyArtworksScreen> createState() => _MyArtworksScreenState();
}

class _MyArtworksScreenState extends State<MyArtworksScreen> {
  List<SavedArtwork> _artworks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    final artworks = await ColoringStorage.getSavedArtworks();
    if (mounted) {
      setState(() {
        _artworks = artworks;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteArtwork(SavedArtwork artwork) async {
    SoundService().playPop();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('O\'chirish'),
        content: const Text('Rostdan ham bu rasmni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ColoringStorage.deleteArtwork(artwork);
      _loadArtworks();
    }
  }

  void _shareArtwork(SavedArtwork artwork) {
    SoundService().playPop();
    Share.shareXFiles([XFile(artwork.savedPath)], text: 'Mening bo\'yagan rasmim! 🎨');
  }

  void _viewArtwork(SavedArtwork artwork) {
    SoundService().playPop();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.file(File(artwork.savedPath)),
            ),
            Positioned(
              top: 40.h,
              right: 20.w,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 32),
              ),
            ),
            Positioned(
              bottom: 40.h,
              child: ElevatedButton.icon(
                onPressed: () => _shareArtwork(artwork),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Ulashish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2979FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF424242)),
        ),
        title: Text(
          'Mening Rasmlarim',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _artworks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🎨', style: TextStyle(fontSize: 64.sp)),
                      SizedBox(height: 16.h),
                      Text(
                        'Hali rasmlar yo\'q',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF424242),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Bo\'yashni boshlang va saqlang!',
                        style: TextStyle(fontSize: 14.sp, color: const Color(0xFF757575)),
                      ),
                    ],
                  ),
                )
              : Builder(
                  builder: (context) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final crossAxisCount = screenWidth > 800 ? 5 : (screenWidth > 600 ? 4 : (screenWidth > 400 ? 3 : 2));
                    
                    return GridView.builder(
                      padding: EdgeInsets.all(16.w),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 0.8,
                      ),
                  itemCount: _artworks.length,
                  itemBuilder: (ctx, index) {
                    final artwork = _artworks[index];
                    return _SavedArtworkCard(
                      artwork: artwork,
                      onTap: () => _viewArtwork(artwork),
                      onDelete: () => _deleteArtwork(artwork),
                      onShare: () => _shareArtwork(artwork),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _SavedArtworkCard extends StatelessWidget {
  final SavedArtwork artwork;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const _SavedArtworkCard({
    required this.artwork,
    required this.onTap,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Rasm (fileni o'qish)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF9F9F9),
                  child: Image.file(
                    File(artwork.savedPath),
                    fit: BoxFit.cover,
                    cacheWidth: 400, // Memory leak oldini olish u-n
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${artwork.emoji} ${artwork.name}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F0F0F),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          _formatDate(artwork.date),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          SoundService().playPop();
                          onShare();
                        },
                        child: Icon(Icons.share_rounded, size: 20.sp, color: const Color(0xFF2979FF)),
                      ),
                      SizedBox(width: 8.w),
                      InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          SoundService().playPop();
                          onDelete();
                        },
                        child: Icon(Icons.delete_outline_rounded, size: 20.sp, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
