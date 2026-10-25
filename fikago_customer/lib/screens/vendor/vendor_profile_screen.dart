import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../config/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/vendor_service.dart';
import '../../utils/phone_number.dart';
import '../auth/role_selection_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});
  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _delivery = TextEditingController();
  String _opening = '08:00';
  String _closing = '22:00';
  String? _logo;
  String? _cover;
  List<String> _gallery = [];
  List<Map<String, dynamic>> _reviews = [];
  double _rating = 0;
  int _reviewCount = 0;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _phone.dispose();
    _delivery.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait(
        [VendorService.getProfile(), VendorService.getReviews()]);
    if (!mounted) return;
    final profile = results[0];
    final data = profile['data'] is Map
        ? Map<String, dynamic>.from(profile['data'])
        : <String, dynamic>{};
    final reviews = results[1]['data'] is List
        ? (results[1]['data'] as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];
    setState(() {
      _name.text = data['name']?.toString() ?? '';
      _description.text = data['description']?.toString() ?? '';
      _address.text = data['address']?.toString() ?? '';
      _phone.text = nationalTzPhoneDigits(
        data['phone_number']?.toString() ?? '',
      );
      _delivery.text = data['delivery_area']?.toString() ?? '';
      _opening = _timeValue(data['opening_time'], '08:00');
      _closing = _timeValue(data['closing_time'], '22:00');
      _logo = data['logo_url']?.toString();
      _cover = data['cover_image_url']?.toString();
      _gallery = data['gallery_images'] is List
          ? List<String>.from(data['gallery_images'])
          : [];
      _rating = double.tryParse(data['rating_avg']?.toString() ?? '') ?? 0;
      _reviewCount = int.tryParse(data['review_count']?.toString() ?? '') ??
          reviews.length;
      _reviews = reviews;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _address.text.trim().isEmpty) {
      _message(context.localized(
          'Jina na eneo vinahitajika.', 'Name and location are required.'));
      return;
    }
    final normalizedPhone = normalizeTzPhone(_phone.text.trim());
    if (normalizedPhone == null) {
      _message(context.localized('Weka namba sahihi ya simu yenye tarakimu 9.',
          'Enter a valid phone number with 9 digits.'));
      return;
    }
    setState(() => _saving = true);
    final result = await VendorService.updateProfile({
      'name': _name.text.trim(),
      'description': _description.text.trim(),
      'address': _address.text.trim(),
      'phone_number': normalizedPhone,
      'delivery_area': _delivery.text.trim(),
      'opening_time': _opening,
      'closing_time': _closing,
      'logo_url': _logo,
      'cover_image_url': _cover,
      'gallery_images': _gallery,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    _message(result['success'] == true
        ? context.localized('Wasifu umehifadhiwa.', 'Restaurant profile saved.')
        : result['message']?.toString() ?? 'Could not save profile.');
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _timeValue(dynamic value, String fallback) {
    final text = value?.toString() ?? '';
    return text.length >= 5 ? text.substring(0, 5) : fallback;
  }

  Future<String?> _pickImage() async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (file == null) return null;
    final uploaded = await VendorService.uploadRestaurantImage(file);
    if (uploaded['success'] != true) {
      _message(uploaded['message']?.toString() ?? 'Image upload failed.');
      return null;
    }
    return uploaded['data']?['image_url']?.toString();
  }

  Future<void> _chooseTime(bool opening) async {
    final parts = (opening ? _opening : _closing).split(':');
    final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0));
    if (selected == null) return;
    setState(() {
      final value =
          '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
      if (opening) {
        _opening = value;
      } else {
        _closing = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F4),
      appBar: AppBar(
          title: Text(
              context.localized('Restaurant profile', 'Restaurant profile'),
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold)),
          centerTitle: false,
          backgroundColor: const Color(0xFFF5F7F4),
          elevation: 0),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _heroCard(),
                    const SizedBox(height: 16),
                    _section(
                        context.localized(
                            'Taarifa za biashara', 'Business details'),
                        Icons.store_outlined,
                        [
                          _field(
                              _name,
                              context.localized(
                                  'Jina la mgahawa', 'Restaurant name'),
                              Icons.restaurant),
                          _field(
                              _description,
                              context.localized('Maelezo', 'Description'),
                              Icons.notes,
                              lines: 3),
                          _field(
                              _address,
                              context.localized(
                                  'Eneo / anuani', 'Location / address'),
                              Icons.location_on_outlined),
                          _field(
                              _phone,
                              context.localized(
                                  'Namba ya simu', 'Phone number'),
                              Icons.phone,
                              type: TextInputType.phone),
                          _field(
                              _delivery,
                              context.localized(
                                  'Maeneo ya delivery', 'Delivery area'),
                              Icons.delivery_dining,
                              hint: 'Mfano: Mikocheni, Msasani'),
                        ]),
                    const SizedBox(height: 14),
                    _section(
                        context.localized('Muda wa kazi', 'Operating hours'),
                        Icons.schedule, [
                      Row(children: [
                        Expanded(
                            child: _timeTile(
                                context.localized('Inafunguliwa', 'Opens'),
                                _opening,
                                true)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _timeTile(
                                context.localized('Inafungwa', 'Closes'),
                                _closing,
                                false))
                      ]),
                    ]),
                    const SizedBox(height: 14),
                    _section(
                        context.localized(
                            'Picha za mgahawa', 'Restaurant photos'),
                        Icons.photo_library_outlined,
                        [
                          Row(children: [
                            Expanded(
                                child: _imageTile(
                                    context.localized('Nembo', 'Logo'),
                                    _logo,
                                    (url) => setState(() => _logo = url))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _imageTile(
                                    context.localized(
                                        'Picha ya jalada', 'Cover image'),
                                    _cover,
                                    (url) => setState(() => _cover = url)))
                          ]),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                              onPressed: () async {
                                final url = await _pickImage();
                                if (url != null && mounted) {
                                  setState(() => _gallery.add(url));
                                }
                              },
                              icon: const Icon(
                                  Icons.add_photo_alternate_outlined),
                              label: Text(context.localized(
                                  'Ongeza picha za mgahawa',
                                  'Add restaurant photos'))),
                          if (_gallery.isNotEmpty)
                            SizedBox(
                                height: 88,
                                child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: _gallery
                                        .map((url) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: Stack(children: [
                                              ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.network(url,
                                                      width: 100,
                                                      height: 78,
                                                      fit: BoxFit.cover)),
                                              Positioned(
                                                  right: 2,
                                                  top: 2,
                                                  child: InkWell(
                                                      onTap: () => setState(
                                                          () => _gallery
                                                              .remove(url)),
                                                      child: const CircleAvatar(
                                                          radius: 12,
                                                          backgroundColor:
                                                              Colors.white,
                                                          child: Icon(
                                                              Icons.close,
                                                              size: 14))))
                                            ])))
                                        .toList())),
                        ]),
                    const SizedBox(height: 14),
                    _section(
                        context.localized(
                            'Ratings na reviews', 'Ratings & reviews'),
                        Icons.star_outline,
                        [
                          Row(children: [
                            const Icon(Icons.star, color: Color(0xFFF4B740)),
                            const SizedBox(width: 6),
                            Text(_rating.toStringAsFixed(1),
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold, fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                                '($_reviewCount ${context.localized('reviews', 'reviews')})',
                                style: GoogleFonts.montserrat(
                                    color: Colors.black54))
                          ]),
                          const SizedBox(height: 12),
                          if (_reviews.isEmpty)
                            Text(
                                context.localized(
                                    'Reviews za wateja zitaonekana hapa.',
                                    'Customer reviews will appear here.'),
                                style: GoogleFonts.montserrat(
                                    color: Colors.black54))
                          else
                            ..._reviews.take(5).map((review) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const CircleAvatar(
                                    child: Icon(Icons.person_outline)),
                                title: Text(review['customer_name']?.toString() ??
                                    'Customer'),
                                subtitle: Text(
                                    review['comment']?.toString().isNotEmpty == true
                                        ? review['comment'].toString()
                                        : context.localized(
                                            'Hakuna maoni yaliyoandikwa.', 'No written comment.')),
                                trailing: Text('★ ${review['rating'] ?? 0}'))),
                        ]),
                    const SizedBox(height: 14),
                    _section(context.localized('Mipangilio', 'Settings'),
                        Icons.settings_outlined, [
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.language,
                              color: FikaGoColors.forestGreen),
                          title: Text('vendor_profile.language'.tr()),
                          trailing: Text(context.locale.languageCode == 'sw'
                              ? 'Kiswahili'
                              : 'English'),
                          onTap: () => context.setLocale(
                              context.locale.languageCode == 'sw'
                                  ? const Locale('en')
                                  : const Locale('sw'))),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.help_outline,
                              color: FikaGoColors.forestGreen),
                          title: Text('vendor_profile.help'.tr()),
                          onTap: () {}),
                      ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading:
                              const Icon(Icons.logout, color: Colors.redAccent),
                          title: Text('vendor_profile.logout'.tr()),
                          onTap: () => _logout()),
                    ]),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save_outlined),
                            label: Text(_saving
                                ? context.localized(
                                    'Inahifadhi...', 'Saving...')
                                : context.localized(
                                    'Hifadhi wasifu', 'Save profile')),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: FikaGoColors.forestGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))))),
                  ]),
            ),
    );
  }

  Widget _heroCard() => Container(
      height: 180,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: FikaGoColors.forestGreen,
          image: _cover == null
              ? null
              : DecorationImage(
                  image: NetworkImage(_cover!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: .35), BlendMode.darken))),
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                backgroundImage: _logo == null ? null : NetworkImage(_logo!),
                child: _logo == null
                    ? const Icon(Icons.restaurant,
                        color: FikaGoColors.forestGreen, size: 32)
                    : null),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                      _name.text.isEmpty
                          ? context.localized('Mgahawa wako', 'Your restaurant')
                          : _name.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_address.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 7),
                  Text(
                      '★ ${_rating.toStringAsFixed(1)}  ·  $_reviewCount ${context.localized('reviews', 'reviews')}',
                      style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12))
                ]))
          ])));

  Widget _section(String title, IconData icon, List<Widget> children) =>
      Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: .035),
                    blurRadius: 14,
                    offset: const Offset(0, 5))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: FikaGoColors.forestGreen),
              const SizedBox(width: 9),
              Text(title,
                  style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold, fontSize: 15))
            ]),
            const SizedBox(height: 14),
            ...children
          ]));
  Widget _field(TextEditingController controller, String label, IconData icon,
          {int lines = 1, TextInputType? type, String? hint}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: TextField(
              controller: controller,
              maxLines: lines,
              keyboardType: type,
              decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  prefixText: type == TextInputType.phone ? '+255 ' : null,
                  prefixIcon: Icon(icon, size: 19),
                  filled: true,
                  fillColor: const Color(0xFFF7F8F6),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none))));
  Widget _timeTile(String label, String value, bool opening) => InkWell(
      onTap: () => _chooseTime(opening),
      child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: const Color(0xFFF7F8F6),
              borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: Colors.black54)),
            const SizedBox(height: 5),
            Text(value,
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold))
          ])));
  Widget _imageTile(
          String label, String? url, ValueChanged<String?> onChanged) =>
      InkWell(
          onTap: () async {
            final value = await _pickImage();
            if (value != null) onChanged(value);
          },
          child: Container(
              height: 100,
              decoration: BoxDecoration(
                  color: const Color(0xFFF7F8F6),
                  borderRadius: BorderRadius.circular(12),
                  image: url == null
                      ? null
                      : DecorationImage(
                          image: NetworkImage(url), fit: BoxFit.cover)),
              child: url == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          const Icon(Icons.add_a_photo_outlined,
                              color: FikaGoColors.forestGreen),
                          const SizedBox(height: 5),
                          Text(label,
                              style: GoogleFonts.montserrat(fontSize: 11))
                        ])
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                          width: double.infinity,
                          color: Colors.black54,
                          padding: const EdgeInsets.all(4),
                          child: Text(label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                  color: Colors.white, fontSize: 10))))));

  Future<void> _logout() async {
    final provider = context.read<AuthProvider>();
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
                title: Text('vendor_profile.logout_confirm'.tr()),
                content: Text(context.localized('Una uhakika unataka kutoka?',
                    'Are you sure you want to log out?')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(context.localized('Ghairi', 'Cancel'))),
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(context.localized('Toka', 'Log out')))
                ]));
    if (confirm == true && mounted) {
      await provider.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
            (_) => false);
      }
    }
  }
}
