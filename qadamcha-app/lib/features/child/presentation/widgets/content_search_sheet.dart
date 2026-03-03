import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../content/domain/entities/content_entity.dart';

/// Kontent qidirish bottom sheet
class ContentSearchSheet extends StatefulWidget {
  final List<ContentEntity> contents;
  final void Function(ContentEntity content, List<ContentEntity> allContents, int index) onSelect;

  const ContentSearchSheet({
    super.key,
    required this.contents,
    required this.onSelect,
  });

  @override
  State<ContentSearchSheet> createState() => _ContentSearchSheetState();
}

class _ContentSearchSheetState extends State<ContentSearchSheet> {
  String _query = '';

  List<ContentEntity> get _results {
    if (_query.isEmpty) return [];
    return widget.contents
        .where((c) => c.title.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16.w,
        16.h,
        16.w,
        MediaQuery.of(context).viewInsets.bottom + 16.h,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Qidirish...',
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF606060)),
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            ),
          ),
          if (_results.isNotEmpty) ...[
            SizedBox(height: 12.h),
            SizedBox(
              height: 300.h,
              child: ListView.separated(
                itemCount: _results.length > 10 ? 10 : _results.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF2F2F2)),
                itemBuilder: (_, i) {
                  final c = _results[i];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6.r),
                      child: SizedBox(
                        width: 64.w,
                        height: 40.h,
                        child: c.thumbnailUrl != null && c.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                c.thumbnailUrl!,
                                fit: BoxFit.cover,
                                headers: const {'Referer': 'https://qadamcha.uz/'},
                                errorBuilder: (_, __, ___) =>
                                    Container(color: const Color(0xFFE5E5E5)),
                              )
                            : Container(color: const Color(0xFFE5E5E5)),
                      ),
                    ),
                    title: Text(
                      c.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onSelect(
                        c,
                        widget.contents,
                        widget.contents.indexOf(c),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          if (_query.isNotEmpty && _results.isEmpty) ...[
            SizedBox(height: 24.h),
            Text(
              'Topilmadi 😔',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF606060)),
            ),
            SizedBox(height: 24.h),
          ],
        ],
      ),
    );
  }
}
