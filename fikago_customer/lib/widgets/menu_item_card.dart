import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_localizations.dart';
import '../config/theme.dart';
import '../models/menu_item_model.dart';

class MenuItemCard extends StatelessWidget {
  final MenuItem item;
  final String? restaurantName;
  final bool isAdding;
  final VoidCallback? onTap;
  final VoidCallback? onBuy;

  const MenuItemCard({
    super.key,
    required this.item,
    this.restaurantName,
    this.isAdding = false,
    this.onTap,
    this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      elevation: 1.5,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (restaurantName?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 5, 6, 4),
                child: Row(
                  children: [
                    const Icon(Icons.storefront,
                        size: 11, color: FikaGoColors.forestGreen),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        restaurantName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: FikaGoColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: restaurantName?.isNotEmpty == true ? 72 : 82,
              child: item.imageUrl?.isNotEmpty == true
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ProductPlaceholder(),
                    )
                  : const _ProductPlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(7, 5, 7, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 10.5,
                        height: 1.12,
                        fontWeight: FontWeight.w700,
                        color: FikaGoColors.charcoal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'TZS ${item.price.toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: FikaGoColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 27,
                      child: FilledButton(
                        onPressed: isAdding ? null : onBuy,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: FikaGoColors.forestGreen,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              FikaGoColors.forestGreen.withValues(alpha: 0.7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: isAdding
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.8,
                                  color: Colors.white,
                                ),
                              )
                            : FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.add_shopping_cart,
                                        size: 12),
                                    const SizedBox(width: 2),
                                    Text(
                                      context.localized(
                                          'Ongeza kikapuni', 'Add to Cart'),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder();

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: FikaGoColors.lightGreen,
        child: Center(
          child: Icon(Icons.fastfood,
              color: FikaGoColors.forestGreen.withValues(alpha: 0.7), size: 25),
        ),
      );
}
