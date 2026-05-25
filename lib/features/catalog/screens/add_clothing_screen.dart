import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_model.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/features/catalog/providers/catalog_provider.dart';
import 'package:go_router/go_router.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  State<AddClothesScreen> createState() => _AddClothesScreenState();
}

class _AddClothesScreenState extends State<AddClothesScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  XFile? _imageFile;
  Uint8List? _imageBytes;       // for image preview
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
      });
    }
  }

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
      final fileName = '${const Uuid().v4()}.jpg';
      final path = '$userId/$fileName';
      final storage = Supabase.instance.client.storage.from('clothes');

      final bytes = await _imageFile!.readAsBytes();
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
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

      await Provider.of<ClothesProvider>(context, listen: false).addClothingItem(newItem);

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
                      : _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : Image.file(File(_imageFile!.path), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 20),
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
}