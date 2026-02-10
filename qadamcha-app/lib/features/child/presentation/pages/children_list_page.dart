import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/child_entity.dart';
import '../bloc/child_bloc.dart';

class ChildrenListPage extends StatelessWidget {
  const ChildrenListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolalarim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddChildDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<ChildBloc, ChildState>(
        builder: (context, state) {
          if (state.status == ChildStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (state.status == ChildStatus.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Xatolik'),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ChildBloc>().add(LoadChildrenEvent());
                    },
                    child: const Text('Qayta yuklash'),
                  ),
                ],
              ),
            );
          }
          
          if (state.children.isEmpty) {
            return _buildEmptyState(context);
          }
          
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: state.children.length,
            itemBuilder: (context, index) {
              final child = state.children[index];
              return _ChildCard(
                child: child,
                isSelected: state.selectedChild?.id == child.id,
                onTap: () {
                  context.read<ChildBloc>().add(SelectChildEvent(child.id));
                },
                onEdit: () => _showEditChildDialog(context, child),
                onDelete: () => _showDeleteConfirmation(context, child),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('👶', style: TextStyle(fontSize: 80.sp)),
            SizedBox(height: 24.h),
            Text(
              'Hali bola qo\'shilmagan',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Farzandingizni qo\'shib, ularning ekran vaqtini boshqaring',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: () => _showAddChildDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Bola qo\'shish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChildDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => const _AddChildSheet(),
    );
  }

  void _showEditChildDialog(BuildContext context, Child child) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => _EditChildSheet(child: child),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Child child) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirish'),
        content: Text('${child.name}ni o\'chirishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ChildBloc>().add(DeleteChildEvent(child.id));
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }
}

class _ChildCard extends StatelessWidget {
  final Child child;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ChildCard({
    required this.child,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28.r,
                  backgroundColor: child.gender == 'girl' 
                      ? AppColors.kidPink 
                      : AppColors.kidBlue,
                  child: Text(
                    child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                            child.name,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (isSelected) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Faol',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${child.age} yosh • ${child.ageGroup} guruh',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                PopupMenuButton(
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Tahrirlash'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
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
            SizedBox(height: 16.h),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  icon: Icons.timer,
                  value: '${child.remainingMinutes} min',
                  label: 'Qolgan vaqt',
                  color: child.hasTimeRemaining ? AppColors.success : AppColors.error,
                ),
                _StatItem(
                  icon: Icons.play_circle,
                  value: '${child.todayUsage.videosWatched}',
                  label: 'Videolar',
                  color: AppColors.kidBlue,
                ),
                _StatItem(
                  icon: Icons.games,
                  value: '${child.todayUsage.gamesPlayed}',
                  label: 'O\'yinlar',
                  color: AppColors.kidGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20.sp, color: color),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet();

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _nameController = TextEditingController();
  int _selectedAge = 5;
  String _selectedGender = 'boy';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bola qo\'shish',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Ismi',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16.h),
            // Age selector
            Text(
              'Yoshi: $_selectedAge',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _selectedAge.toDouble(),
              min: 3,
              max: 15,
              divisions: 12,
              label: '$_selectedAge yosh',
              onChanged: (v) => setState(() => _selectedAge = v.toInt()),
            ),
            SizedBox(height: 16.h),
            // Gender selector
            Text(
              'Jinsi',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'boy'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'boy' 
                            ? AppColors.kidBlue 
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          '👦 O\'g\'il',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: _selectedGender == 'boy' 
                                ? Colors.white 
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'girl'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'girl' 
                            ? AppColors.kidPink 
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Center(
                        child: Text(
                          '👧 Qiz',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: _selectedGender == 'girl' 
                                ? Colors.white 
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_nameController.text.trim().isNotEmpty) {
                    context.read<ChildBloc>().add(AddChildEvent(
                      name: _nameController.text.trim(),
                      age: _selectedAge,
                      gender: _selectedGender,
                    ));
                    Navigator.pop(context);
                  }
                },
                child: const Text('Qo\'shish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditChildSheet extends StatefulWidget {
  final Child child;
  
  const _EditChildSheet({required this.child});

  @override
  State<_EditChildSheet> createState() => _EditChildSheetState();
}

class _EditChildSheetState extends State<_EditChildSheet> {
  late final TextEditingController _nameController;
  late int _selectedAge;
  late int _weekdayMinutes;
  late int _weekendMinutes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.child.name);
    _selectedAge = widget.child.age;
    _weekdayMinutes = widget.child.limits.weekdayMinutes;
    _weekendMinutes = widget.child.limits.weekendMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tahrirlash',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ismi',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Yoshi: $_selectedAge',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _selectedAge.toDouble(),
                min: 3,
                max: 15,
                divisions: 12,
                label: '$_selectedAge yosh',
                onChanged: (v) => setState(() => _selectedAge = v.toInt()),
              ),
              SizedBox(height: 16.h),
              Text(
                'Hafta kuni limiti: $_weekdayMinutes min',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _weekdayMinutes.toDouble(),
                min: 15,
                max: 180,
                divisions: 11,
                label: '$_weekdayMinutes min',
                onChanged: (v) => setState(() => _weekdayMinutes = v.toInt()),
              ),
              Text(
                'Dam olish kuni limiti: $_weekendMinutes min',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              Slider(
                value: _weekendMinutes.toDouble(),
                min: 30,
                max: 240,
                divisions: 14,
                label: '$_weekendMinutes min',
                onChanged: (v) => setState(() => _weekendMinutes = v.toInt()),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<ChildBloc>()
                      ..add(UpdateChildEvent(
                        childId: widget.child.id,
                        name: _nameController.text.trim(),
                        age: _selectedAge,
                      ))
                      ..add(SetTimeLimitsEvent(
                        childId: widget.child.id,
                        weekdayMinutes: _weekdayMinutes,
                        weekendMinutes: _weekendMinutes,
                      ));
                    Navigator.pop(context);
                  },
                  child: const Text('Saqlash'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
