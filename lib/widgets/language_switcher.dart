import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class LanguageSwitcher extends ConsumerWidget {
  final bool showLabel;
  final Color? iconColor;

  const LanguageSwitcher({
    super.key,
    this.showLabel = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = locale.languageCode == 'ar';

    if (showLabel) {
      return TextButton.icon(
        onPressed: () => _showLanguageDialog(context, ref, l10n),
        icon: Icon(Icons.language, color: iconColor ?? Colors.white),
        label: Text(
          isArabic ? l10n.arabic : l10n.english,
          style: TextStyle(color: iconColor ?? Colors.white),
        ),
      );
    }

    return IconButton(
      icon: Icon(Icons.language, color: iconColor ?? Colors.white),
      onPressed: () => _showLanguageDialog(context, ref, l10n),
      tooltip: l10n.changeLanguage,
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final locale = ref.read(languageProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: locale.languageCode == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Text('🇸🇦', style: TextStyle(fontSize: 24)),
              title: const Text('العربية'),
              trailing: locale.languageCode == 'ar'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                ref.read(languageProvider.notifier).setLanguage(const Locale('ar'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Quick toggle button (for compact spaces)
class LanguageToggleButton extends ConsumerWidget {
  final Color? color;

  const LanguageToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);
    final isArabic = locale.languageCode == 'ar';

    return GestureDetector(
      onTap: () => ref.read(languageProvider.notifier).toggleLanguage(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color ?? Colors.white),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isArabic ? 'EN' : 'ع',
          style: TextStyle(
            color: color ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
