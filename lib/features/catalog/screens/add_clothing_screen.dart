import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/widgets/bg_removal_status_banner.dart';
import 'package:weardo_outfit_builder/services/background_removal/bg_removal_service.dart';
import 'package:weardo_outfit_builder/services/background_removal/bg_removal_status.dart';
import 'package:weardo_outfit_builder/widgets/button.dart';
import 'package:go_router/go_router.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  State<AddClothesScreen> createState() => _AddClothesScreenState();
}

class _AddClothesScreenState extends State<AddClothesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bgRemovalService = BgRemovalService(
    baseUrl: dotenv.get('BG_REMOVAL_URL', fallback: 'http://localhost:8000'),
    username: dotenv.env['BG_REMOVAL_USERNAME'],
    password: dotenv.env['BG_REMOVAL_PASSWORD'],
  );
  final _nameController = TextEditingController();

  String? _selectedCategory;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  Uint8List? _processedBytes;
  BgRemovalStatus _bgStatus = BgRemovalStatus.idle;
  bool _isUploading = false;

  final List<String> _categories = ['Headwear', 'Outer Tops', 'Inner Tops', 'Bottoms', 'Footwear'];

  static const _inputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.zero,
    borderSide: BorderSide(color: Colors.black, width: 1),
  );

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 40),
                  SizedBox(height: 8),
                  Text('Gallery'),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 40),
                  SizedBox(height: 8),
                  Text('Camera'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
        _processedBytes = null;
        _bgStatus = BgRemovalStatus.processing;
      });
      _removeBackground(bytes);
    }
  }

  Future<void> _removeBackground(Uint8List bytes) async {
    try {
      final result = await _bgRemovalService.removeBackground(bytes);
      if (mounted) {
        setState(() {
          _processedBytes = result;
          _bgStatus = BgRemovalStatus.done;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bgStatus = BgRemovalStatus.failed;
        });
      }
    }
  }

  Uint8List get _uploadBytes =>
      _processedBytes ?? _imageBytes!;

  Future<void> _uploadAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a category')));
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final fileName = '${const Uuid().v4()}.png';
      final path = '$userId/$fileName';
      final storage = Supabase.instance.client.storage.from('clothes');

      await storage.uploadBinary(
        path,
        _uploadBytes,
        fileOptions: const FileOptions(contentType: 'image/png'),
      );
      final downloadUrl = storage.getPublicUrl(path);

      const double defaultSize = 30.0;
      final newItem = ClothingItem(
        id: const Uuid().v4(),
        userId: userId,
        imageUrl: downloadUrl,
        heightInches: defaultSize,
        widthInches: defaultSize,
        category: _selectedCategory!,
        name: _nameController.text.trim(),
        createdAt: DateTime.now(),
      );

      await Provider.of<CatalogProvider>(context, listen: false).addClothingItem(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clothing added!')));
        context.go('/catalog');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text('Add Clothing', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.black, width: 1),
                        bottom: BorderSide(color: Colors.black, width: 1),
                        left: BorderSide(color: Colors.black, width: 1),
                        right: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                    child: _imageFile == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50),
                              SizedBox(height: 8),
                              Text('Tap to select image'),
                            ],
                          )
                        : _displayBytes != null
                            ? Image.memory(_displayBytes!, fit: BoxFit.contain)
                            : Image.file(File(_imageFile!.path), fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 12),
                BgRemovalStatusBanner(status: _bgStatus),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: _inputBorder,
                    enabledBorder: _inputBorder,
                    focusedBorder: _inputBorder,
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: _inputBorder,
                    enabledBorder: _inputBorder,
                    focusedBorder: _inputBorder,
                  ),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Add Clothing',
                  isLoading: _isUploading,
                  onPressed: _isUploading ? null : _uploadAndSave,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/catalog'),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Uint8List? get _displayBytes => _processedBytes ?? _imageBytes;
}
