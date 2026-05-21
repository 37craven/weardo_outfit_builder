import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:weardo_outfit_builder/models/clothing_item.dart';
import 'package:provider/provider.dart';
import 'package:weardo_outfit_builder/providers/clothes_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';

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
  File? _imageFile;
  bool _isUploading = false;

  final List<String> _categories = ['Shirt', 'Pants', 'Shoes'];

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
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
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final fileName = '${const Uuid().v4()}.jpg';
      final ref = FirebaseStorage.instance.ref().child('clothes/$userId/$fileName');
      await ref.putFile(_imageFile!);
      final downloadUrl = await ref.getDownloadURL();

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
                  child: _imageFile != null
                      ? kIsWeb
                      ? Image.network(_imageFile!.path, fit: BoxFit.contain) // ✅ Web Fix
                      : Image.file(_imageFile!, fit: BoxFit.contain)        // ✅ Mobile/Desktop
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate, size: 50),
                      Text('Tap to select image'),
                    ],
                  ),
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