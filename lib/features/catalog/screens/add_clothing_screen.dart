import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:weardo_outfit_builder/features/catalog/widgets/bg_removal_status_banner.dart';
import 'package:weardo_outfit_builder/services/background_removal/bg_removal_service.dart';
import 'package:weardo_outfit_builder/services/background_removal/bg_removal_status.dart';
import 'package:go_router/go_router.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  State<AddClothesScreen> createState() => _AddClothesScreenState();
}

class _AddClothesScreenState extends State<AddClothesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bgRemovalService = BgRemovalService();

  String? _selectedCategory;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  Uint8List? _processedBytes;
  BgRemovalStatus _bgStatus = BgRemovalStatus.idle;
  bool _isUploading = false;

  final List<String> _categories = ['Outer', 'Inner', 'Pants', 'Shoes'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
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
        createdAt: DateTime.now(),
      );

      await Provider.of<CatalogProvider>(context, listen: false).addClothingItem(newItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Clothing added!')));
        context.go('/clothes');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Clothing')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _imageFile == null
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50),
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
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
                validator: (v) => v == null ? 'Select a category' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadAndSave,
                child: _isUploading ? const CircularProgressIndicator() : const Text('Add Clothing'),
              ),
              TextButton(
                onPressed: () => context.go('/clothes'),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List? get _displayBytes => _processedBytes ?? _imageBytes;
}
