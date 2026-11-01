import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/app_localizations.dart';
import '../../../config/theme.dart';
import '../../../models/cart_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../auth/register_screen.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    if (context.read<AuthProvider>().isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.read<AuthProvider>().isLoggedIn) {
          context.read<CartProvider>().loadCart();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    final tickets = cartProvider.tickets;
    return Scaffold(
      appBar: AppBar(title: Text(context.localized('Vikapu', 'Your carts'))),
      body: cartProvider.isLoading && tickets.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
              ? Center(
                  child: Text(context.localized(
                    'Kikapu ni tupu',
                    'Your carts are empty',
                  )),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: tickets.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _ticketCard(tickets[index], isLoggedIn),
                ),
    );
  }

  Widget _ticketCard(Cart ticket, bool isLoggedIn) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: FikaGoColors.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ticket.restaurantName.isEmpty
                        ? context.localized(
                            'Mgahawa ${ticket.restaurantId ?? ''}',
                            'Restaurant ${ticket.restaurantId ?? ''}',
                          )
                        : ticket.restaurantName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.localized('Ondoa kikapu', 'Remove cart'),
                  onPressed: () => context.read<CartProvider>().removeCart(
                        ticket.cartId,
                      ),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const Divider(),
            ...ticket.items.map(_cartItemRow),
            const Divider(),
            _amountRow(
              context.localized('Bidhaa', 'Items'),
              ticket.subtotal,
            ),
            if (ticket.cartId > 0) ...[
              _amountRow(
                context.localized('Usafirishaji', 'Delivery'),
                ticket.deliveryFee,
              ),
              _amountRow(
                context.localized('Ada ya huduma', 'Service fee'),
                ticket.serviceFee,
              ),
              if (ticket.discount > 0)
                _amountRow(
                  context.localized('Punguzo', 'Discount'),
                  -ticket.discount,
                ),
            ],
            const SizedBox(height: 5),
            _amountRow(
              context.localized('Jumla ya kikapu hiki', 'Cart total'),
              ticket.totalAmount,
              bold: true,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _buyNow(ticket, isLoggedIn),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: Text(context.localized(
                  isLoggedIn ? 'Agiza kutoka hapa' : 'Jisajili kuagiza',
                  isLoggedIn ? 'Checkout this restaurant' : 'Register to order',
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartItemRow(CartItem item) {
    final cart = context.read<CartProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  'TZS ${item.unitPrice.toStringAsFixed(0)} × ${item.quantity}',
                  style:
                      const TextStyle(fontSize: 12, color: FikaGoColors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => cart.updateQuantity(item.id, item.quantity - 1),
          ),
          Text('${item.quantity}'),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => cart.updateQuantity(item.id, item.quantity + 1),
          ),
          IconButton(
            tooltip: context.localized('Ondoa bidhaa', 'Remove item'),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.delete_outline, size: 19),
            onPressed: () => cart.removeItem(item.id),
          ),
          Text(
            'TZS ${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(String label, double amount, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            Text(
              'TZS ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontSize: bold ? 16 : 13,
              ),
            ),
          ],
        ),
      );

  Future<void> _buyNow(Cart ticket, bool isLoggedIn) async {
    final restaurantId = ticket.restaurantId;
    if (!isLoggedIn) {
      final registered = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => const RegisterScreen(returnToCaller: true),
        ),
      );
      if (!mounted || registered != true) return;
    }

    final cart = context.read<CartProvider>();
    final synced = await cart.syncGuestItems();
    if (!mounted) return;
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

    final selectedTicket = cart.carts.firstWhere(
      (candidate) => candidate.restaurantId == restaurantId,
      orElse: () => ticket,
    );
    if (selectedTicket.cartId < 1) return;
    cart.selectCart(selectedTicket.cartId);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(cartId: selectedTicket.cartId),
      ),
    );
  }
}
