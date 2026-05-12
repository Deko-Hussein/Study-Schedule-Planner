import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../utils/color.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local state for UI responsiveness and demo mode
  String _userName = 'Your Name';
  String _userRole = 'Student';
  String _plan     = 'FREE PLAN';
  String _reminderTime = '15 Mins';
  String _alertSound   = 'Classic Chime';
  bool _loadingSettings = false;

  final List<String> _reminderOptions = ['Exact Time', '15 Mins', '1 Hour'];
  final List<String> _soundOptions    = ['Classic Chime', 'Crystal', 'Minimalist'];

  @override
  void initState() {
    super.initState();
    _syncWithProvider();
    _loadSettingsFromBackend();
  }

  void _syncWithProvider() {
    final auth = context.read<AuthProvider>();
    if (auth.isLoggedIn) {
      setState(() {
        _userName = auth.userName.isNotEmpty ? auth.userName : 'Your Name';
        _userRole = auth.userMajor.isNotEmpty ? auth.userMajor : 'Student';
        _plan     = auth.subscription == 'premium' ? 'PREMIUM PLAN ACTIVE' : 'FREE PLAN';
      });
    }
  }

  Future<void> _loadSettingsFromBackend() async {
    final token = await ApiService.getToken();
    if (token == null) return;

    setState(() => _loadingSettings = true);
    try {
      final data = await ApiService.getReminders();
      final r = data['reminders'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        setState(() {
          _reminderTime = r['reminderTime']?.toString() ?? '15 Mins';
          _alertSound   = r['alertSound']?.toString()   ?? 'Classic Chime';
        });
      }
    } catch (_) {
      // Silent fail
    } finally {
      if (mounted) setState(() => _loadingSettings = false);
    }
  }

  Future<void> _updateSetting(String key, String value) async {
    setState(() {
      if (key == 'reminderTime') _reminderTime = value;
      if (key == 'alertSound')   _alertSound = value;
    });

    final token = await ApiService.getToken();
    if (token == null) return;

    try {
      await ApiService.updateReminders({
        'reminderTime': _reminderTime,
        'alertSound':   _alertSound,
      });
    } catch (_) {}
  }

  // 1. Edit Profile Logic
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
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColor.borderPrimary, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Edit Profile', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.kTextStyleColor)),
              const SizedBox(height: 20),
              _sheetField(nameCtrl, 'Full Name', Icons.person_outline_rounded),
              const SizedBox(height: 14),
              _sheetField(roleCtrl, 'Role / Major', Icons.school_outlined),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _userName = nameCtrl.text.trim();
                    _userRole = roleCtrl.text.trim();
                  });
                  Navigator.pop(ctx);
                  if (auth.isLoggedIn) {
                    await auth.updateProfile({'name': _userName, 'major': _userRole});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.kPrimaryColor, foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Subscription Logic
  void _showSubscription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColor.borderPrimary, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Manage Subscription', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColor.kTextStyleColor)),
            const SizedBox(height: 8),
            Text('Current: $_plan', style: GoogleFonts.inter(fontSize: 13, color: AppColor.kTextStyleColorGray)),
            const SizedBox(height: 24),
            _planTile(ctx, 'Free Plan', 'Standard features for students', _plan == 'FREE PLAN'),
            const SizedBox(height: 12),
            _planTile(ctx, 'Premium Plan', 'Unlock advanced planning tools', _plan == 'PREMIUM PLAN ACTIVE'),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _planTile(BuildContext ctx, String title, String sub, bool active) => InkWell(
    onTap: () {
      setState(() => _plan = title == 'Free Plan' ? 'FREE PLAN' : 'PREMIUM PLAN ACTIVE');
      Navigator.pop(ctx);
    },
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: active ? AppColor.kPrimaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? AppColor.kPrimaryColor : AppColor.borderPrimary, width: 1.5),
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.kTextStyleColor)),
          Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColor.kTextStyleColorGray)),
        ])),
        if (active) const Icon(Icons.check_circle_rounded, color: AppColor.kPrimaryColor, size: 20),
      ]),
    ),
  );

  // 5. Sign Out Logic
  void _showSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.inter(color: AppColor.kTextStyleColorGray))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final auth = context.read<AuthProvider>();
              await auth.logout();
              // Reset local state if no navigation happens
              setState(() {
                _userName = 'Your Name';
                _userRole = 'Student';
                _plan     = 'FREE PLAN';
              });
            },
            child: Text('Sign Out', style: GoogleFonts.inter(color: AppColor.kCheckOutActiveTextColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _sheetField(TextEditingController ctrl, String label, IconData icon) =>
      TextFormField(
        controller: ctrl,
        style: GoogleFonts.inter(fontSize: 14, color: AppColor.kTextStyleColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColor.kTextStyleColorGray),
          prefixIcon: Icon(icon, size: 18, color: AppColor.kTextStyleColorGray),
          filled: true, fillColor: AppColor.kbgColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColor.borderPrimary)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColor.borderPrimary)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColor.kPrimaryColor, width: 1.5)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    // We use local state primarily for responsiveness, but watch for external updates
    final auth = context.watch<AuthProvider>();
    final String avatar = auth.userAvatar;

    return Scaffold(
      backgroundColor: AppColor.kbgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: CustomScrollView(
              slivers: [
                // ── App Bar ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)]),
                          child: const Icon(Icons.school_rounded, size: 16, color: AppColor.kPrimaryColor),
                        ),
                        const SizedBox(width: 8),
                        Text('Study Planner', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColor.kTextStyleColor)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded, size: 22, color: AppColor.kTextStyleColor),
                          onPressed: () {},
                          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Avatar + name ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(children: [
                      Stack(children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColor.kPrimaryColor.withOpacity(0.12),
                          backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                          child: avatar.isEmpty
                              ? Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
                                  style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: AppColor.kPrimaryColor))
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(color: AppColor.kPrimaryColor, shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)),
                            child: const Icon(Icons.edit, size: 11, color: Colors.white),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Text(_userName,
                          style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColor.kTextStyleColor)),
                      const SizedBox(height: 2),
                      Text(_userRole,
                          style: GoogleFonts.inter(fontSize: 12, color: AppColor.kTextStyleColorGray)),
                    ]),
                  ),
                ),

                // ── Account section ────────────────────────────────────
                SliverToBoxAdapter(child: _sectionLabel('ACCOUNT')),
                SliverToBoxAdapter(
                  child: _card(children: [
                    _listTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColor.kPrimaryColor,
                      title: 'Edit Profile',
                      onTap: () => _showEditProfile(context),
                    ),
                    _divider(),
                    _listTile(
                      icon: Icons.credit_card_rounded,
                      iconColor: const Color(0xFFEA580C),
                      title: 'Subscription',
                      subtitle: _plan,
                      subtitleColor: _plan == 'PREMIUM PLAN ACTIVE' ? const Color(0xFFEA580C) : AppColor.kTextStyleColorGray,
                      onTap: () => _showSubscription(context),
                    ),
                  ]),
                ),

                // ── Notification Defaults ──────────────────────────────
                SliverToBoxAdapter(child: _sectionLabel('NOTIFICATION DEFAULTS')),
                SliverToBoxAdapter(
                  child: _card(children: [
                    // Reminder Time
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text('REMINDER TIME',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppColor.kTextStyleColorGray, letterSpacing: 1.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: _loadingSettings
                          ? const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)))
                          : Row(children: _reminderOptions.map((opt) {
                              final active = _reminderTime == opt;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () => _updateSetting('reminderTime', opt),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: active ? AppColor.kPrimaryColor : AppColor.kbgColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: active ? AppColor.kPrimaryColor : AppColor.borderPrimary),
                                    ),
                                    child: Center(child: Text(opt,
                                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                                            color: active ? Colors.white : AppColor.kTextStyleColorGray))),
                                  ),
                                ),
                              );
                            }).toList()),
                    ),

                    _divider(),

                    // Alert Sound
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Text('ALERT SOUND',
                          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppColor.kTextStyleColorGray, letterSpacing: 1.2)),
                    ),
                    ..._soundOptions.map((sound) {
                      final active = _alertSound == sound;
                      return InkWell(
                        onTap: () => _updateSetting('alertSound', sound),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(children: [
                            const Icon(Icons.notifications_active_outlined, size: 18,
                                color: AppColor.kTextStyleColorGray),
                            const SizedBox(width: 12),
                            Expanded(child: Text(sound,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                                    color: active ? AppColor.kTextStyleColor : AppColor.kTextStyleColorGray))),
                            if (active) const Icon(Icons.check_rounded, size: 16, color: AppColor.kPrimaryColor),
                          ]),
                        ),
                      );
                    }),
                    const SizedBox(height: 4),
                  ]),
                ),

                // ── More ───────────────────────────────────────────────
                SliverToBoxAdapter(child: _sectionLabel('MORE')),
                SliverToBoxAdapter(
                  child: _card(children: [
                    _listTile(
                      icon: Icons.logout_rounded,
                      iconColor: AppColor.kCheckOutActiveTextColor,
                      title: 'Sign Out',
                      titleColor: AppColor.kCheckOutActiveTextColor,
                      onTap: () => _showSignOut(context),
                    ),
                  ]),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
            color: AppColor.kTextStyleColorGray, letterSpacing: 1.4)),
  );

  Widget _card({required List<Widget> children}) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
  );

  Widget _divider() => const Divider(height: 1, indent: 16, endIndent: 16, color: AppColor.borderSecondary);

  Widget _listTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? subtitleColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
              child: Icon(icon, size: 17, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500,
                  color: titleColor ?? AppColor.kTextStyleColor)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600,
                    color: subtitleColor ?? AppColor.kTextStyleColorGray, letterSpacing: 0.5)),
              ],
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColor.kTextStyleColorGray),
          ]),
        ),
      );
}
