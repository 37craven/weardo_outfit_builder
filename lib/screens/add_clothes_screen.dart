import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_item.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/providers/clothes_provider.dart';
import 'package:go_router/go_router.dart';

class AddClothesScreen extends StatefulWidget {
  const AddClothesScreen({super.key});

  @override
  State<AddClothesScreen> createState() => _AddClothesScreenState();
}

class _AddClothesScreenState extends State<AddClothesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _widthController = TextEditingController();
  String? _selectedCategory;
  XFile? _imageFile;
  Uint8List? _imageBytes;       // for web preview
  bool _isUploading = false;

  final List<String> _categories = ['Shirt', 'Pants', 'Shoes'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = picked;
      });
      if (kIsWeb) {
        // Load bytes for web preview and later upload
        final bytes = await picked.readAsBytes();
        setState(() {
          _imageBytes = bytes;
        });
      }
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
      final tempFile = File('${Directory.systemTemp.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      await storage.upload(
        path,
        tempFile,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),
      );
      await tempFile.delete();
      final downloadUrl = storage.getPublicUrl(path);

      final newItem = ClothingItem(
        id: const Uuid().v4(),
        userId: userId,
        imageUrl: downloadUrl,
        heightInches: double.parse(_heightController.text),
        widthInches: double.parse(_widthController.text),
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
                      : kIsWeb && _imageBytes != null
                      ? Image.memory(_imageBytes!, fit: BoxFit.contain)
                      : kIsWeb
                      ? Image.network(_imageFile!.path, fit: BoxFit.contain)
                      : Image.network(_imageFile!.path, fit: BoxFit.contain), // mobile works with network too
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(labelText: 'Height (inches)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _widthController,
                decoration: const InputDecoration(labelText: 'Width (inches)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
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