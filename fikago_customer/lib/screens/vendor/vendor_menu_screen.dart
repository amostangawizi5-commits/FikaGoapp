// ============================================================
// FIKAGO VENDOR - MENU SCREEN
// ============================================================
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/vendor_service.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});

  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    final response = await VendorService.getMenu();
    if (!mounted) return;
    setState(() {
      _items = response['success'] == true
          ? (response['data'] as List)
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : [];
      _isLoading = false;
    });
    if (response['success'] != true) {
      _showMessage(response['message'] ?? 'Failed to load menu.');
    }
  }

  // ============================================================
  // ADD ITEM BOTTOM SHEET
  // ============================================================
  Future<void> _addItem({Map<String, dynamic>? editing}) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    final extrasController = TextEditingController();

    final List<String> categories = <String>{
      'Food',
      'Grocery',
      'Shops',
      'Drinks',
      'Pharmacy',
      'Salon'
    }.toList();
    final editingCategory = editing?['category_name']?.toString().trim();
    if (editingCategory != null &&
        editingCategory.isNotEmpty &&
        !categories.contains(editingCategory)) {
      categories.add(editingCategory);
    }
    String? selectedCategory =
        editingCategory != null && categories.contains(editingCategory)
            ? editingCategory
            : null;
    nameController.text = editing?['name']?.toString() ?? '';
    priceController.text = editing?['price']?.toString() ?? '';
    descriptionController.text = editing?['description']?.toString() ?? '';
    final oldExtras = editing?['extras'];
    if (oldExtras is List) {
      extrasController.text =
          oldExtras.map((e) => '${e['name']}:${e['price']}').join(', ');
    }
    XFile? selectedImage;
    Uint8List? selectedImageBytes;

    final values = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) =>
          StatefulBuilder(builder: (context, setDialogState) {
        final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: FractionallySizedBox(
            heightFactor: 0.82,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              decoration: const BoxDecoration(
                color: FikaGoColors.lightGreen,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: FikaGoColors.charcoal.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    editing == null
                        ? context.localized(
                            'Ongeza bidhaa mpya', 'Add menu item')
                        : context.localized('Hariri bidhaa', 'Edit menu item'),
                    style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: FikaGoColors.forestGreen),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            key: ValueKey<String?>(selectedCategory),
                            initialValue: selectedCategory,
                            decoration: InputDecoration(
                              labelText:
                                  context.localized('Kategoria', 'Category'),
                              labelStyle: GoogleFonts.montserrat(
                                  color: FikaGoColors.charcoal),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: FikaGoColors.forestGreen, width: 2),
                              ),
                              prefixIcon: const Icon(Icons.category,
                                  color: FikaGoColors.forestGreen),
                            ),
                            hint: Text(
                                context.localized(
                                    'Chagua kategoria', 'Choose a category'),
                                style: GoogleFonts.montserrat()),
                            items: categories.map((String cat) {
                              return DropdownMenuItem(
                                  value: cat,
                                  child: Text(_localizedCategory(context, cat),
                                      style: GoogleFonts.montserrat()));
                            }).toList(),
                            onChanged: (val) =>
                                setDialogState(() => selectedCategory = val),
                          ),
                          if (selectedCategory != null) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                                nameController,
                                context.localized(
                                    'Jina la bidhaa', 'Item name'),
                                Icons.fastfood),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                try {
                                  final pickedFile = await picker.pickImage(
                                      source: ImageSource.gallery);
                                  if (pickedFile == null) return;
                                  final imageBytes =
                                      await pickedFile.readAsBytes();
                                  setDialogState(() {
                                    selectedImage = pickedFile;
                                    selectedImageBytes = imageBytes;
                                  });
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Could not open the selected image: $e')),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: FikaGoColors.lightGreen,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: FikaGoColors.forestGreen,
                                      width: 1.5),
                                  image: selectedImageBytes != null
                                      ? DecorationImage(
                                          image:
                                              MemoryImage(selectedImageBytes!),
                                          fit: BoxFit.cover)
                                      : null,
                                ),
                                child: selectedImage == null
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.cloud_upload,
                                              size: 40,
                                              color: FikaGoColors.forestGreen),
                                          const SizedBox(height: 8),
                                          Text(
                                            context.localized(
                                                'Pakia picha', 'Upload image'),
                                            style: GoogleFonts.montserrat(
                                                fontSize: 12,
                                                color: FikaGoColors.forestGreen,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 4. PRICE
                            _buildTextField(
                                priceController,
                                context.localized('Bei (TZS)', 'Price (TZS)'),
                                Icons.attach_money,
                                keyboardType: TextInputType.number),
                            const SizedBox(height: 12),

                            // 5. DESCRIPTION
                            _buildTextField(
                                descriptionController,
                                context.localized('Maelezo (Hiari)',
                                    'Description (Optional)'),
                                Icons.description,
                                maxLines: 2),
                            const SizedBox(height: 12),
                            _buildTextField(
                                extrasController,
                                context.localized('Extras: jina:bei, jina:bei',
                                    'Add-ons: name:price, name:price'),
                                Icons.add_circle_outline,
                                maxLines: 2),

                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(context.localized('GHAIRI', 'CANCEL'),
                              style: GoogleFonts.montserrat(
                                  color: FikaGoColors.charcoal,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FikaGoColors.sunYellow,
                            foregroundColor: FikaGoColors.charcoal,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () {
                            final name = nameController.text.trim();
                            final price =
                                double.tryParse(priceController.text.trim());

                            if (selectedCategory == null ||
                                name.isEmpty ||
                                price == null ||
                                price <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                    content: Text(context.localized(
                                        'Chagua kategoria, kisha jaza jina na bei sahihi.',
                                        'Choose a category, then enter a valid name and price.'))),
                              );
                              return;
                            }

                            Navigator.pop(dialogContext, {
                              'name': name,
                              'category': selectedCategory,
                              'price': price.toString(),
                              'description': descriptionController.text.trim(),
                              'image': selectedImage,
                              'extras': extrasController.text
                                  .split(',')
                                  .map((value) {
                                    final parts = value.split(':');
                                    if (parts.length < 2 ||
                                        parts.first.trim().isEmpty) {
                                      return null;
                                    }
                                    final addonPrice = double.tryParse(
                                        parts.sublist(1).join(':').trim());
                                    if (addonPrice == null || addonPrice < 0) {
                                      return null;
                                    }
                                    return {
                                      'name': parts.first.trim(),
                                      'price': addonPrice
                                    };
                                  })
                                  .whereType<Map<String, dynamic>>()
                                  .toList(),
                            });
                          },
                          child: Text(context.localized('HIFADHI', 'SAVE'),
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );

    nameController.dispose();
    priceController.dispose();
    descriptionController.dispose();
    extrasController.dispose();

    if (values == null || !mounted) return;

    // 1. Upload Image First
    String? imageUrl;
    if (values['image'] != null) {
      final uploadResponse = await VendorService.uploadImage(values['image']);
      if (uploadResponse['success'] == true) {
        imageUrl = uploadResponse['data']['image_url'];
      } else {
        _showMessage('Failed to upload image: ${uploadResponse['message']}');
        return;
      }
    }

    // 2. Add Menu Item
    final response = editing == null
        ? await VendorService.addMenuItem(
            name: values['name']!,
            categoryName: values['category']!,
            price: double.parse(values['price']!),
            description: values['description'],
            imageUrl: imageUrl,
            extras: List<Map<String, dynamic>>.from(values['extras']))
        : await VendorService.updateMenuItem(
            itemId: int.parse(editing['id'].toString()),
            isAvailable: editing['is_available'] != false,
            name: values['name'],
            categoryName: values['category'],
            price: double.parse(values['price']!),
            description: values['description'],
            imageUrl: imageUrl ?? editing['image_url']?.toString(),
            extras: List<Map<String, dynamic>>.from(values['extras']));

    if (!mounted) return;
    if (response['success'] == true) {
      _showMessage(editing == null
          ? context.localized('Bidhaa imeongezwa.', 'Item added successfully.')
          : context.localized(
              'Bidhaa imesasishwa.', 'Item updated successfully.'));
      await _loadMenu();
    } else {
      _showMessage(response['message'] ??
          context.localized(
              'Imeshindwa kuongeza bidhaa.', 'Failed to add item.'));
    }
  }

  String _localizedCategory(BuildContext context, String category) {
    switch (category) {
      case 'Food':
        return context.localized('Chakula', 'Food');
      case 'Grocery':
        return context.localized('Vyakula', 'Grocery');
      case 'Shops':
        return context.localized('Maduka', 'Shops');
      case 'Drinks':
        return context.localized('Vinywaji', 'Drinks');
      case 'Pharmacy':
        return context.localized('Duka la dawa', 'Pharmacy');
      case 'Salon':
        return context.localized('Saluni', 'Salon');
      default:
        return category;
    }
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.montserrat(color: FikaGoColors.charcoal),
        prefixIcon: Icon(icon, color: FikaGoColors.forestGreen),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: FikaGoColors.forestGreen, width: 2),
        ),
      ),
    );
  }

  Future<void> _setAvailability(
      Map<String, dynamic> item, bool available) async {
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final response =
        await VendorService.updateMenuItem(itemId: id, isAvailable: available);
    if (!mounted) return;
    if (response['success'] == true) {
      await _loadMenu();
    } else {
      _showMessage(response['message'] ?? 'Failed to update availability.');
    }
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.localized('Futa bidhaa?', 'Delete item?'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
        content: Text(context.localized(
            'Una uhakika unataka kufuta ${item['name']}?',
            'Are you sure you want to delete ${item['name']}?')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.localized('Ghairi', 'Cancel'))),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.localized('Futa', 'Delete'),
                  style: const TextStyle(color: FikaGoColors.charcoal))),
        ],
      ),
    );
    if (confirmed != true) return;
    final id = int.tryParse(item['id'].toString());
    if (id == null) return;
    final response = await VendorService.deleteMenuItem(id);
    if (!mounted) return;
    if (response['success'] == true) {
      await _loadMenu();
    } else {
      _showMessage(response['message'] ?? 'Failed to delete item.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FikaGoColors.lightGreen,
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('assets/images/fikaGO.png', height: 35),
        backgroundColor: FikaGoColors.lightGreen,
        foregroundColor: FikaGoColors.charcoal,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadMenu,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 140),
                        const Icon(Icons.restaurant_menu,
                            size: 56, color: FikaGoColors.forestGreen),
                        const SizedBox(height: 12),
                        Center(
                            child: Text(context.localized(
                                'Bado hujaongeza bidhaa.',
                                'No items added yet.'))),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final available = item['is_available'] != false;
                        final price =
                            double.tryParse(item['price'].toString()) ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: FikaGoColors.lightGreen,
                                borderRadius: BorderRadius.circular(8),
                                image: item['image_url'] != null
                                    ? DecorationImage(
                                        image: NetworkImage(item['image_url']),
                                        fit: BoxFit.cover)
                                    : null,
                              ),
                              child: item['image_url'] == null
                                  ? const Icon(Icons.fastfood,
                                      color: FikaGoColors.forestGreen)
                                  : null,
                            ),
                            title: Text(
                              item['name']?.toString() ?? '',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 3),
                                Text('TZS ${price.toStringAsFixed(0)}',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: FikaGoColors.forestGreen)),
                                Text(
                                    item['category_name']?.toString() ?? 'Item',
                                    style: GoogleFonts.montserrat(
                                        fontSize: 11,
                                        color: FikaGoColors.charcoal
                                            .withValues(alpha: .7))),
                                if (item['description'] != null)
                                  Text(item['description'],
                                      style: GoogleFonts.montserrat(
                                          fontSize: 11,
                                          color: FikaGoColors.charcoal),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                if (item['extras'] is List &&
                                    (item['extras'] as List).isNotEmpty)
                                  Text(
                                      '${context.localized('Extras', 'Add-ons')}: ${(item['extras'] as List).map((e) => e['name']).join(', ')}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.montserrat(
                                          fontSize: 10,
                                          color: FikaGoColors.forestGreen)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: available,
                                  activeThumbColor: FikaGoColors.forestGreen,
                                  onChanged: (value) =>
                                      _setAvailability(item, value),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      _addItem(editing: item);
                                    }
                                    if (action == 'delete') {
                                      _deleteItem(item);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                        value: 'edit',
                                        child: Text(context.localized(
                                            'Hariri', 'Edit'))),
                                    PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                            context.localized('Futa', 'Delete'),
                                            style: const TextStyle(
                                                color: Colors.redAccent))),
                                  ],
                                  icon: const Icon(Icons.more_vert,
                                      color: FikaGoColors.charcoal),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        backgroundColor: FikaGoColors.sunYellow,
        foregroundColor: FikaGoColors.charcoal,
        icon: const Icon(Icons.add),
        label: Text(context.localized('Ongeza bidhaa', 'Add item'),
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
