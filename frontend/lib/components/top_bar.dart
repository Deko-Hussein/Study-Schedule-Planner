import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:frontend/utils/color.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

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
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            backgroundImage: avatarImage,
            child: avatarImage == null
                ? const Icon(
                    Icons.person_outline_rounded,
                    color: AppColor.kPrimaryColor,
                    size: 26,
                  )
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
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: AppColor.kPrimaryColor,
            ),
            splashRadius: 22,
          ),
        ),
      ],
    );
  }
}
