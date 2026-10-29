import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/kumpas_theme.dart';

Future<void> showLoreDialog(
  BuildContext context, {
  required String title,
  required String content,
  int xpGained = 0,
  bool questCompleted = false,
  String? imageUrl,
  String? loreSource,
  String? imageCredit,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: KumpasPalette.paper,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho em verde
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [KumpasPalette.forestDark, KumpasPalette.forest],
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.explore,
                          color: KumpasPalette.amber,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          questCompleted
                              ? context.l10n.trailCompleted
                              : context.l10n.loreUnlocked,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Fraunces',
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              // Foto real do local (Commons/Wikipédia)
              if (imageUrl != null && imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 190,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(
                        color: KumpasPalette.ink,
                        fontSize: 14.5,
                        height: 1.55,
                      ),
                    ),
                    if (xpGained > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: KumpasPalette.amberSoft,
                          borderRadius: BorderRadius.circular(KumpasRadius.pill),
                          border: Border.all(
                            color: KumpasPalette.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.bolt,
                              color: KumpasPalette.amber,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.l10n.loreXpGained(xpGained),
                              style: const TextStyle(
                                color: KumpasPalette.amberDeep,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (questCompleted) ...[
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.loreRewardNote,
                        style: const TextStyle(
                          color: KumpasPalette.muted,
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (loreSource != null && loreSource.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.loreSource(loreSource),
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: KumpasPalette.forestDark,
                        ),
                      ),
                    ],
                    if (imageCredit != null && imageCredit.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        imageCredit,
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: KumpasPalette.muted,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(context.l10n.continue_),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

