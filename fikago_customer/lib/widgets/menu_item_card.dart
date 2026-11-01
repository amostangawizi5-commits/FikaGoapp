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
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: SizedBox.expand(
                child: item.imageUrl?.isNotEmpty == true
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const _ProductPlaceholder(),
                      )
                    : const _ProductPlaceholder(),
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (restaurantName?.isNotEmpty == true)
                      Row(
                        children: [
                          const Icon(Icons.storefront,
                              size: 13, color: FikaGoColors.forestGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              restaurantName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: FikaGoColors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: FikaGoColors.charcoal,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'TZS ${item.price.toStringAsFixed(0)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: FikaGoColors.forestGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 34,
                          child: FilledButton.icon(
                            onPressed: isAdding ? null : onBuy,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: FikaGoColors.forestGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: FikaGoColors.forestGreen
                                  .withValues(alpha: 0.7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            icon: isAdding
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.8,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.add_shopping_cart, size: 15),
                            label: Text(
                              context.localized('Ongeza', 'Add'),
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
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
