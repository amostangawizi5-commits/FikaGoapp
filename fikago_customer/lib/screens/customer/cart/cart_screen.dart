import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../auth/register_screen.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return Scaffold(
      appBar: AppBar(title: Text(context.localized('Kikapu', 'Cart'))),
      body: cart.items.isEmpty
          ? Center(
              child: Text(
                  context.localized('Kikapu ni tupu', 'Your cart is empty')))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                ...cart.items.map(
                  (item) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'TZS ${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints.tightFor(
                                          width: 34, height: 34),
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => cart.updateQuantity(
                                          item.id, item.quantity - 1),
                                    ),
                                    Text('${item.quantity}'),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints.tightFor(
                                          width: 34, height: 34),
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => cart.updateQuantity(
                                          item.id, item.quantity + 1),
                                    ),
                                    IconButton(
                                      tooltip: context.localized(
                                          'Ondoa bidhaa', 'Remove item'),
                                      visualDensity: VisualDensity.compact,
                                      constraints: const BoxConstraints.tightFor(
                                          width: 34, height: 34),
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          size: 19),
                                      onPressed: () => cart.removeItem(item.id),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'TZS ${item.totalPrice.toStringAsFixed(0)}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                    '${context.localized('JUMLA', 'TOTAL')}: TZS ${cart.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _buyNow(context),
                    icon: const Icon(Icons.shopping_bag_outlined),
                    label: Text(context.localized(
                      isLoggedIn ? 'NUNUA SASA' : 'JISAJILI ILI KUNUNUA',
                      isLoggedIn ? 'BUY NOW' : 'REGISTER TO BUY',
                    )),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _buyNow(BuildContext context) async {
    if (!context.read<AuthProvider>().isLoggedIn) {
      final registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterScreen(returnToCaller: true),
        ),
      );
      if (!context.mounted || registered != true) return;
    }

    final cart = context.read<CartProvider>();
    final synced = await cart.syncGuestItems();
    if (!context.mounted) return;
    if (!synced) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.localized(
            'Bidhaa hazikuweza kuhamishwa kwenye akaunti. Jaribu tena.',
            'Could not move cart items to your account. Please try again.',
          )),
        ),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
    );
  }
}
