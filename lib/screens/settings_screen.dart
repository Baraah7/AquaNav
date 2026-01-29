import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: const Color(0xFF0077BE),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),

          // Language Section
          _buildSectionHeader(l10n.language),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
                  title: const Text('English'),
                  trailing: locale.languageCode == 'en'
                      ? const Icon(Icons.check_circle, color: Color(0xFF0077BE))
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    ref.read(languageProvider.notifier).setLanguage(const Locale('en'));
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
                  title: const Text('العربية'),
                  trailing: locale.languageCode == 'ar'
                      ? const Icon(Icons.check_circle, color: Color(0xFF0077BE))
                      : const Icon(Icons.circle_outlined, color: Colors.grey),
                  onTap: () {
                    ref.read(languageProvider.notifier).setLanguage(const Locale('ar'));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader(l10n.account),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(FirebaseAuth.instance.currentUser?.email ?? l10n.guest),
                  subtitle: Text(FirebaseAuth.instance.currentUser != null
                      ? l10n.signedIn
                      : l10n.guestMode),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    l10n.signOut,
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmSignOut(context, ref, l10n),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(l10n.about),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.appName),
                  subtitle: Text('${l10n.version} 1.0.0'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0077BE),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.areYouSureSignOut),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              l10n.signOut,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
