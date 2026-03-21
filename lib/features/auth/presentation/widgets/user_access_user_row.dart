import 'package:flutter/material.dart';
import 'dart:io';

import '../../data/auth_local_datasource.dart';

class UserAccessUserRow extends StatelessWidget {
  const UserAccessUserRow({
    super.key,
    required this.user,
    required this.onTap,
    required this.onActionSelected,
  });

  final AuthUserSummary user;
  final VoidCallback onTap;
  final ValueChanged<String> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final String username = user.username.trim();
    final String initials = username.isEmpty
        ? 'U'
        : username.substring(0, username.length < 2 ? 1 : 2).toUpperCase();
    final String email = '$username@negocio.com';
    final String imagePath = (user.employeeImagePath ?? '').trim();
    final bool hasImage = imagePath.isNotEmpty && File(imagePath).existsSync();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
        leading: Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: hasImage
                ? null
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: user.isActive
                        ? const <Color>[Color(0xFF0F766E), Color(0xFF99F6E4)]
                        : const <Color>[Color(0xFFF3E4D8), Color(0xFFEBD1BE)],
                  ),
          ),
          alignment: Alignment.center,
          child: hasImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(imagePath),
                    width: 58,
                    height: 58,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildInitials(initials),
                  ),
                )
              : _buildInitials(initials),
        ),
        title: Text(
          username,
          style: const TextStyle(
            fontSize: 33 / 2,
            fontWeight: FontWeight.w800,
            color: Color(0xFF13171D),
          ),
        ),
        subtitle: Text(
          email,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF31384A),
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: onActionSelected,
          itemBuilder: (_) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Text('Editar'),
            ),
            if (!user.isDefaultAdmin)
              PopupMenuItem<String>(
                value: 'toggle',
                child: Text(user.isActive ? 'Desactivar' : 'Activar'),
              ),
          ],
          icon: const Icon(
            Icons.more_vert_rounded,
            color: Color(0xFF30374A),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String initials) {
    return Text(
      initials,
      style: TextStyle(
        fontWeight: FontWeight.w900,
        fontSize: 18,
        color:
            user.isActive ? const Color(0xFFECFEFF) : const Color(0xFFB58F73),
      ),
    );
  }
}
