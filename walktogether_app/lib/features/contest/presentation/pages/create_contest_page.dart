import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/repositories/contest_repository.dart';

/// Page for creating a new contest
class CreateContestPage extends StatefulWidget {
  final String groupId;
  final String groupName;

  const CreateContestPage({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<CreateContestPage> createState() => _CreateContestPageState();
}

class _CreateContestPageState extends State<CreateContestPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = isStart
        ? (_startDate ?? today)
        : (_endDate ?? (_startDate ?? today).add(const Duration(days: 7)));

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Auto-adjust end date if needed
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('contest.select_dates_required'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await context.read<ContestRepository>().createContest(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            groupId: widget.groupId,
            startDate: _startDate!.toIso8601String(),
            endDate: _endDate!.toIso8601String(),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('contest.created_success'.tr()),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('contest.create_title'.tr()),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Group info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.group, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'group.contest_for'.tr(),
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        Text(
                          widget.groupName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contest name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'contest.name_label'.tr(),
                hintText: 'contest.name_hint'.tr(),
                prefixIcon: const Icon(Icons.emoji_events_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'contest.name_required'.tr() : null,
              maxLength: 100,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'contest.desc_label'.tr(),
                hintText: 'contest.desc_hint'.tr(),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: 16),

            // Start date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.play_arrow_rounded, color: AppColors.success),
              title: Text('contest.start_date_label'.tr()),
              subtitle: Text(
                _startDate != null
                    ? '${_startDate!.day.toString().padLeft(2, '0')}/${_startDate!.month.toString().padLeft(2, '0')}/${_startDate!.year}'
                    : 'common.not_selected'.tr(),
                style: TextStyle(
                  color: _startDate != null ? AppColors.textMain : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(true),
            ),
            const Divider(),

            // End date
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.stop_rounded, color: AppColors.danger),
              title: Text('contest.end_date_label'.tr()),
              subtitle: Text(
                _endDate != null
                    ? '${_endDate!.day.toString().padLeft(2, '0')}/${_endDate!.month.toString().padLeft(2, '0')}/${_endDate!.year}'
                    : 'common.not_selected'.tr(),
                style: TextStyle(
                  color: _endDate != null ? AppColors.textMain : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 32),

            // Submit
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'contest.create_title'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
