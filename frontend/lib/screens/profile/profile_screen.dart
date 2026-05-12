import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/color.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Your Name';
  String _userRole = 'Student Planner';
  String _plan = 'FREE PLAN';
  String _reminderTime = '15 Mins';
  String _alertSound = 'Classic Chime';
  bool _loadingSettings = false;
  bool _uploadingAvatar = false;
  String? _localAvatar;

  final ImagePicker _imagePicker = ImagePicker();
  final List<String> _reminderOptions = ['Exact Time', '15 Mins', '1 Hour'];
  final List<String> _soundOptions = ['Classic Chime', 'Crystal', 'Minimalist'];

  @override
  void initState() {
    super.initState();
    _syncWithProvider();
    _loadSettingsFromBackend();
  }

  void _syncWithProvider() {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) {
      return;
    }

    setState(() {
      _userName = auth.userName.isNotEmpty ? auth.userName : 'Your Name';
      _userRole =
          auth.userMajor.isNotEmpty ? auth.userMajor : 'Student Planner';
      _plan =
          auth.subscription == 'premium' ? 'PREMIUM PLAN ACTIVE' : 'FREE PLAN';
    });
  }

  Future<void> _loadSettingsFromBackend() async {
    final token = await ApiService.getToken();
    if (token == null) {
      return;
    }

    setState(() => _loadingSettings = true);
    try {
      final data = await ApiService.getReminders();
      final reminders = data['reminders'] as Map<String, dynamic>? ?? {};
      if (!mounted) {
        return;
      }

      setState(() {
        _reminderTime = reminders['reminderTime']?.toString() ?? '15 Mins';
        _alertSound = reminders['alertSound']?.toString() ?? 'Classic Chime';
      });
    } catch (_) {
      // Silent fail
    } finally {
      if (mounted) {
        setState(() => _loadingSettings = false);
      }
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    setState(() {
      if (key == 'reminderTime') {
        _reminderTime = value;
      }
      if (key == 'alertSound') {
        _alertSound = value;
      }
    });

    final token = await ApiService.getToken();
    if (token == null) {
      return;
    }

    try {
      await ApiService.updateReminders({
        'reminderTime': _reminderTime,
        'alertSound': _alertSound,
      });
    } catch (_) {}
  }

  ImageProvider<Object>? _avatarImageProvider(String avatar) {
    if (avatar.isEmpty) {
      return null;
    }

    if (avatar.startsWith('data:image')) {
      final separator = avatar.indexOf(',');
      if (separator == -1) {
        return null;
      }

      try {
        return MemoryImage(base64Decode(avatar.substring(separator + 1)));
      } catch (_) {
        return null;
      }
    }

    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return NetworkImage(avatar);
    }

    return null;
  }

  String _mimeTypeForImage(String path) {
    final lowerPath = path.toLowerCase();
    if (lowerPath.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerPath.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _pickProfileImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 72,
        maxWidth: 720,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes = await pickedFile.readAsBytes();
      final avatarData =
          'data:${_mimeTypeForImage(pickedFile.path)};base64,${base64Encode(bytes)}';

      if (!mounted) {
        return;
      }

      setState(() {
        _localAvatar = avatarData;
        _uploadingAvatar = true;
      });

      final auth = context.read<AuthProvider>();
      await auth.cacheProfilePatch({'avatar': avatarData});

      if (auth.isLoggedIn) {
        final saved = await auth.updateProfile({'avatar': avatarData});
        if (!mounted) {
          return;
        }

        setState(() => _uploadingAvatar = false);

        if (!saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated locally, but syncing failed.'),
            ),
          );
        }
      } else {
        await auth.cacheLocalAvatar(avatarData);
        if (!mounted) {
          return;
        }
        setState(() => _uploadingAvatar = false);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() => _uploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select a profile image right now.'),
        ),
      );
    }
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: _userName);
    final roleCtrl = TextEditingController(text: _userRole);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.borderPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Edit Profile',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kTextStyleColor,
                ),
              ),
              const SizedBox(height: 20),
              _sheetField(
                nameCtrl,
                'Full Name',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 14),
              _sheetField(
                roleCtrl,
                'Role / Major',
                Icons.school_outlined,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _userName = nameCtrl.text.trim();
                    _userRole = roleCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  if (auth.isLoggedIn) {
                    await auth.updateProfile({
                      'name': _userName,
                      'major': _userRole,
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubscription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.borderPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Manage Subscription',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColor.kTextStyleColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current: $_plan',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColor.kTextStyleColorGray,
              ),
            ),
            const SizedBox(height: 24),
            _planTile(
              ctx,
              'Free Plan',
              'Standard features for students',
              _plan == 'FREE PLAN',
            ),
            const SizedBox(height: 12),
            _planTile(
              ctx,
              'Premium Plan',
              'Unlock advanced planning tools',
              _plan == 'PREMIUM PLAN ACTIVE',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _planTile(
    BuildContext ctx,
    String title,
    String subtitle,
    bool active,
  ) {
    return InkWell(
      onTap: () {
        setState(() {
          _plan = title == 'Free Plan' ? 'FREE PLAN' : 'PREMIUM PLAN ACTIVE';
        });
        Navigator.pop(ctx);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              active ? AppColor.kPrimaryColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColor.kPrimaryColor : AppColor.borderPrimary,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.kTextStyleColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColor.kTextStyleColorGray,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColor.kPrimaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sign Out',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppColor.kTextStyleColorGray,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final auth = context.read<AuthProvider>();
              await auth.logout();

              if (!mounted) return;

              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(
                color: AppColor.kCheckOutActiveTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon,
  ) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColor.kTextStyleColor,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColor.kTextStyleColorGray,
        ),
        prefixIcon: Icon(
          icon,
          size: 18,
          color: AppColor.kTextStyleColorGray,
        ),
        filled: true,
        fillColor: AppColor.kbgColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColor.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColor.kPrimaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final avatar = _localAvatar ?? auth.userAvatar;
    final avatarImage = _avatarImageProvider(avatar);
    final displayName = _userName.trim().isNotEmpty ? _userName : 'Your Name';
    final displayRole =
        _userRole.trim().isNotEmpty ? _userRole : 'Student Planner';

    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 16,
                            color: AppColor.kPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Study Planner',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColor.kTextStyleColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            size: 22,
                            color: AppColor.kTextStyleColor,
                          ),
                          onPressed: () {},
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Color(0xFFF7FAFF),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _uploadingAvatar ? null : _pickProfileImage,
                            customBorder: const CircleBorder(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColor.kSecondColor
                                            .withOpacity(0.18),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: AppColor.kPrimaryColor
                                        .withOpacity(0.10),
                                    backgroundImage: avatarImage,
                                    child: avatarImage == null
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 50,
                                            color: AppColor.kPrimaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                                if (_uploadingAvatar)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0x660F172A),
                                      ),
                                      child: const Center(
                                        child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: InkWell(
                                    onTap: _uploadingAvatar
                                        ? null
                                        : _pickProfileImage,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: AppColor.kPrimaryColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.12),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.photo_camera_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            displayName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColor.kTextStyleColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            displayRole,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColor.kTextStyleColorGray,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => _showEditProfile(context),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColor.kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              'Edit Profile',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _sectionLabel('ACCOUNT')),
                SliverToBoxAdapter(
                  child: _card(
                    children: [
                      _listTile(
                        icon: Icons.credit_card_rounded,
                        iconColor: const Color(0xFFEA580C),
                        title: 'Subscription',
                        subtitle: _plan,
                        subtitleColor: _plan == 'PREMIUM PLAN ACTIVE'
                            ? const Color(0xFFEA580C)
                            : AppColor.kTextStyleColorGray,
                        onTap: () => _showSubscription(context),
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: _sectionLabel('NOTIFICATION DEFAULTS'),
                ),
                SliverToBoxAdapter(
                  child: _card(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          'REMINDER TIME',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kTextStyleColorGray,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        child: _loadingSettings
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Row(
                                children: _reminderOptions.map((option) {
                                  final active = _reminderTime == option;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => _updateSetting(
                                        'reminderTime',
                                        option,
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: active
                                              ? AppColor.kPrimaryColor
                                              : AppColor.kbgColor,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: active
                                                ? AppColor.kPrimaryColor
                                                : AppColor.borderPrimary,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            option,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: active
                                                  ? Colors.white
                                                  : AppColor
                                                      .kTextStyleColorGray,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                      _divider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                        child: Text(
                          'ALERT SOUND',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColor.kTextStyleColorGray,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ..._soundOptions.map((sound) {
                        final active = _alertSound == sound;
                        return InkWell(
                          onTap: () => _updateSetting('alertSound', sound),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.notifications_active_outlined,
                                  size: 18,
                                  color: AppColor.kTextStyleColorGray,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    sound,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: active
                                          ? AppColor.kTextStyleColor
                                          : AppColor.kTextStyleColorGray,
                                    ),
                                  ),
                                ),
                                if (active)
                                  const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: AppColor.kPrimaryColor,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
                SliverToBoxAdapter(child: _sectionLabel('MORE')),
                SliverToBoxAdapter(
                  child: _card(
                    children: [
                      _listTile(
                        icon: Icons.logout_rounded,
                        iconColor: AppColor.kCheckOutActiveTextColor,
                        title: 'Sign Out',
                        titleColor: AppColor.kCheckOutActiveTextColor,
                        onTap: () => _showSignOut(context),
                      ),
                    ],
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColor.kTextStyleColorGray,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: AppColor.borderSecondary,
    );
  }

  Widget _listTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColor.kTextStyleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor ?? AppColor.kTextStyleColorGray,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColor.kTextStyleColorGray,
            ),
          ],
        ),
      ),
    );
  }
}
