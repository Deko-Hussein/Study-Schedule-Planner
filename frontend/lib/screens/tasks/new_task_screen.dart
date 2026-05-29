import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../utils/color.dart';
import '../../utils/sizes.dart';

class TaskIconly {
  TaskIconly._();

  static const IconData activity = IconlyLight.activity;
  static const IconData calendar = IconlyLight.calendar;
  static const IconData calendarBold = IconlyBold.calendar;
  static const IconData notification = IconlyLight.notification;
  static const IconData notificationBold = IconlyBold.notification;
  static const IconData profile = IconlyLight.profile;
  static const IconData profileBold = IconlyBold.profile;
  static const IconData time = IconlyLight.time_circle;
  static const IconData timeBold = IconlyBold.time_circle;
}

class NewTaskScreen extends StatefulWidget {
  final VoidCallback? onTaskSaved;
  final VoidCallback? onProfileTap;

  const NewTaskScreen({
    super.key,
    this.onTaskSaved,
    this.onProfileTap,
  });

  @override
  State<NewTaskScreen> createState() => _NewTaskScreenState();
}

class _NewTaskScreenState extends State<NewTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _taskDate = DateTime.now();
  TimeOfDay _taskTime = TimeOfDay.now();
  DateTime? _dueDate;
  bool _reminderEnabled = true;
  TimeOfDay _reminderTime = TimeOfDay.now();
  String _category = 'Study';
  String _recurrence = 'None';
  bool _saving = false;

  final List<String> _categories = const [
    'Study',
    'Assignment',
    'Exam',
    'Reading',
    'Personal',
  ];

  @override
  void initState() {
    super.initState();
    final now = TimeOfDay.now();
    _taskTime = now;
    _reminderTime = _subtractMinutes(now, 15);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  TimeOfDay _subtractMinutes(TimeOfDay time, int minutes) {
    final total = (time.hour * 60 + time.minute - minutes) % (24 * 60);
    return TimeOfDay(hour: total ~/ 60, minute: total % 60);
  }

  String _dateLabel(DateTime date) => DateFormat('MM/dd/yyyy').format(date);

  String _timeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _pickDate({
    required DateTime initialDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColor.kPrimaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _pickTime({
    required TimeOfDay initialTime,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColor.kPrimaryColor,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final dueDate = DateTime(
      _dueDate?.year ?? _taskDate.year,
      _dueDate?.month ?? _taskDate.month,
      _dueDate?.day ?? _taskDate.day,
      _taskTime.hour,
      _taskTime.minute,
    );

    try {
      final token = await ApiService.getToken();
      if (token != null) {
        await ApiService.createTask({
          'title': _titleController.text.trim(),
          'description': _notesController.text.trim(),
          'dueDate': dueDate.toIso8601String(),
          'priority': _category == 'Exam' ? 'high' : 'medium',
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            token == null
                ? 'Task ready locally. Log in to save it.'
                : 'Task saved',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: AppColor.kSecondColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      widget.onTaskSaved?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save task: $e', style: GoogleFonts.inter()),
          backgroundColor: AppColor.kCheckOutActiveTextColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColor.kbgColor,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
          children: [
            _appHeader(),
            const SizedBox(height: 28),
            _titleHeader(),
            const SizedBox(height: 28),
            _formCard(),
            const SizedBox(height: 24),
            _focusBanner(),
          ],
        ),
      ),
    );
  }

  Widget _appHeader() => Row(
        children: [
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onProfileTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColor.borderPrimary),
                ),
                child: const Icon(
                  TaskIconly.profileBold,
                  size: 18,
                  color: AppColor.kPrimaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Study Planner',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColor.kSecondColor,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Badge(
              smallSize: 6,
              backgroundColor: AppColor.kCheckOutActiveTextColor,
              child: Icon(
                TaskIconly.notification,
                color: AppColor.kPrimaryColor,
                size: 24,
              ),
            ),
          ),
        ],
      );

  Widget _titleHeader() => Text(
        'New Task',
        style: GoogleFonts.inter(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: AppColor.kSecondColor,
        ),
      );

  Widget _formCard() => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColor.borderPrimary),
          boxShadow: [
            BoxShadow(
              color: AppColor.kSecondColor.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('TASK TITLE'),
              const SizedBox(height: 8),
              _textField(
                controller: _titleController,
                hint: 'Enter task name...',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      label: 'DATE',
                      icon: TaskIconly.calendarBold,
                      value: _dateLabel(_taskDate),
                      trailingIcon: TaskIconly.calendar,
                      onTap: () => _pickDate(
                        initialDate: _taskDate,
                        onPicked: (date) => setState(() => _taskDate = date),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _pickerTile(
                      label: 'TIME',
                      icon: TaskIconly.timeBold,
                      value: _timeLabel(_taskTime),
                      trailingIcon: TaskIconly.time,
                      onTap: () => _pickTime(
                        initialTime: _taskTime,
                        onPicked: (time) => setState(() => _taskTime = time),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _pickerTile(
                      label: 'DUE DATE (OPTIONAL)',
                      icon: TaskIconly.calendarBold,
                      value: _dueDate == null
                          ? 'mm/dd/yyyy'
                          : _dateLabel(_dueDate!),
                      trailingIcon: TaskIconly.calendar,
                      onTap: () => _pickDate(
                        initialDate: _dueDate ?? _taskDate,
                        onPicked: (date) => setState(() => _dueDate = date),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _menuTile(
                      label: 'RECURRENCE',
                      icon: TaskIconly.timeBold,
                      value: _recurrence,
                      items: const ['None', 'Daily', 'Weekly', 'Monthly'],
                      onChanged: (value) => setState(() => _recurrence = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _label('REMINDER'),
                  const Spacer(),
                  Switch(
                    value: _reminderEnabled,
                    activeThumbColor: AppColor.kPrimaryColor,
                    activeTrackColor:
                        AppColor.kPrimaryColor.withValues(alpha: 0.45),
                    onChanged: (value) =>
                        setState(() => _reminderEnabled = value),
                  ),
                ],
              ),
              _reminderTile(),
              const SizedBox(height: 24),
              _label('CATEGORY'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map(_categoryChip).toList(),
              ),
              const SizedBox(height: 26),
              _label('NOTES'),
              const SizedBox(height: 8),
              _textField(
                controller: _notesController,
                hint: 'Add details here...',
                minLines: 4,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.buttonPrimary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColor.buttonDisabled,
                  elevation: 8,
                  shadowColor: AppColor.kPrimaryColor.withValues(alpha: 0.35),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Save Task',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColor.kTextStyleColorGray,
          letterSpacing: 1.2,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        minLines: minLines,
        maxLines: maxLines,
        validator: validator,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColor.kSecondColor,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColor.kTextStyleColorGray,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: _inputBorder(),
          enabledBorder: _inputBorder(),
          focusedBorder: _inputBorder(AppColor.kPrimaryColor),
          errorBorder: _inputBorder(AppColor.kCheckOutActiveTextColor),
          focusedErrorBorder: _inputBorder(AppColor.kCheckOutActiveTextColor),
        ),
      );

  OutlineInputBorder _inputBorder([Color color = AppColor.borderPrimary]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Sizes.inputFieldRadius),
        borderSide: BorderSide(color: color),
      );

  Widget _pickerTile({
    required String label,
    required IconData icon,
    required String value,
    required IconData trailingIcon,
    required VoidCallback onTap,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColor.borderPrimary),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 16, color: AppColor.kTextStyleColorGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColor.kSecondColor,
                      ),
                    ),
                  ),
                  Icon(trailingIcon, size: 14, color: AppColor.kSecondColor),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _menuTile({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(label),
          const SizedBox(height: 8),
          Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColor.borderPrimary),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kSecondColor,
                ),
                items: items
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Row(
                          children: [
                            Icon(icon,
                                size: 18, color: AppColor.kTextStyleColorGray),
                            const SizedBox(width: 8),
                            Text(item),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      );

  Widget _reminderTile() => Opacity(
        opacity: _reminderEnabled ? 1 : 0.55,
        child: InkWell(
          onTap: _reminderEnabled
              ? () => _pickTime(
                    initialTime: _reminderTime,
                    onPicked: (time) => setState(() => _reminderTime = time),
                  )
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColor.borderSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.borderSecondary),
            ),
            child: Row(
              children: [
                const Icon(TaskIconly.notificationBold,
                    size: 17, color: AppColor.kTextStyleColorGray),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Remind me at',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColor.kTextStyleColor,
                    ),
                  ),
                ),
                Text(
                  _timeLabel(_reminderTime),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColor.kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(TaskIconly.time,
                    size: 13, color: AppColor.kSecondColor),
              ],
            ),
          ),
        ),
      );

  Widget _categoryChip(String category) {
    final selected = _category == category;
    return ChoiceChip(
      selected: selected,
      label: Text(category),
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: selected ? Colors.white : AppColor.kTextStyleColorGray,
      ),
      selectedColor: AppColor.kPrimaryColor,
      backgroundColor: AppColor.borderSecondary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      onSelected: (_) => setState(() => _category = category),
    );
  }

  Widget _focusBanner() => Container(
        height: 140,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF4A90F2),
              Color(0xFF5FB6E9),
              Color(0xFF203B3A),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: 150,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius:
                      const BorderRadius.only(topRight: Radius.circular(48)),
                ),
              ),
            ),
            Positioned(
              left: 118,
              top: 0,
              bottom: 0,
              child: Container(
                  width: 8,
                  color: AppColor.kSecondColor.withValues(alpha: 0.28)),
            ),
            Positioned(
              left: 128,
              top: 0,
              bottom: 0,
              child: Container(
                  width: 88, color: Colors.white.withValues(alpha: 0.16)),
            ),
            Positioned(
              right: 28,
              top: 34,
              child: Container(
                width: 54,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.86),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7), width: 2),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 48,
              child: Container(
                width: 18,
                height: 26,
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.82), width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            Positioned(
              right: 48,
              top: 12,
              child: Icon(
                TaskIconly.activity,
                size: 44,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Positioned(
              left: 20,
              right: 92,
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stay focused, stay ahead.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Break large projects into smaller, manageable chunks.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
