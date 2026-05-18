import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final avatarImage = _avatarImageProvider(auth.userAvatar);

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.transparent,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 24)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Planner',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kSecondColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Organize your day with simple schedule cards',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColor.kTextStyleColorGray,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none, color: Color(0xFF2563EB)),
            splashRadius: 24,
          ),
        ),
      ],
    );
  }
}