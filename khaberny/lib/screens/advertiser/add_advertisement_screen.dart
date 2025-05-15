import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddAdvertisementScreen extends StatefulWidget {
  const AddAdvertisementScreen({super.key});

  @override
  State<AddAdvertisementScreen> createState() => _AddAdvertisementScreenState();
}

class _AddAdvertisementScreenState extends State<AddAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _businessController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategory;
  bool _isUploading = false;

  final List<String> _categories = [
    'Discount', 'New Product', 'Vacation', 'Closure', 'Hiring', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _imageUrlController.addListener(() {
      setState(() {}); // Triggers rebuild to show image preview
    });
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('ads').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'business': _businessController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory == 'Other'
            ? _categoryController.text.trim()
            : _selectedCategory,
        'imageUrl': _imageUrlController.text.trim(),
        'status': 'Pending',
        'createdAt': Timestamp.now(),
        'advertiserId': userId,
        'likes': 0,
        'dislikes': 0,
        'views': 0,
        'shares': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad submitted successfully!')),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/advertiser', (route) => false);
      }
    } catch (e) {
      print('❌ Error submitting ad: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting ad: $e')),
      );
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox.expand(
          child: Image.asset(
            'assets/images/khaberny_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Add new Advertisement',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_titleController, 'Ad Title ', isRequired: true),
                    const SizedBox(height: 16),
                    _buildTextField(_descriptionController, 'Description ', maxLines: 3, isRequired: true),
                    const SizedBox(height: 16),
                    _buildTextField(_businessController, 'Business Name ', isRequired: true),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _imageUrlController,
                      'Choose Image',
                      suffixIcon: const Icon(Icons.upload, color: Colors.black),
                    ),
                    if (_imageUrlController.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrlController.text.trim(),
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('Invalid image URL', style: TextStyle(color: Colors.red)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _locationController,
                      'Location',
                      suffixIcon: const Icon(Icons.location_on_outlined, color: Colors.black),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: const TextStyle(color: Colors.black),
                        filled: true,
                        fillColor: const Color.fromARGB(159, 255, 255, 255),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null ? 'Select a category' : null,
                    ),
                    if (_selectedCategory == 'Other')
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildTextField(_categoryController, 'Enter New Category'),
                        ],
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isUploading ? null : _submitAd,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0A1A3A),
                        padding: const EdgeInsets.symmetric(horizontal: 120, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Add',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {int maxLines = 1, Widget? suffixIcon, bool isRequired = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(color: Colors.black),
            children: isRequired
                ? [
                    const TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    )
                  ]
                : [],
          ),
        ),
        filled: true,
        fillColor: const Color.fromARGB(162, 255, 255, 255),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => isRequired && value!.isEmpty ? 'Required' : null,
    );
  }
}
