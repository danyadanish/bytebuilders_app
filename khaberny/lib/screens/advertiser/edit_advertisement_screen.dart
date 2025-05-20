import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditAdvertisementScreen extends StatefulWidget {
  final String adId;
  final Map<String, dynamic> adData;

  const EditAdvertisementScreen({super.key, required this.adId, required this.adData});

  @override
  State<EditAdvertisementScreen> createState() => _EditAdvertisementScreenState();
}

class _EditAdvertisementScreenState extends State<EditAdvertisementScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _businessController;
  late TextEditingController _locationController;
  late TextEditingController _categoryController;
  late TextEditingController _imageUrlController;

  String? _selectedCategory;
  bool _isUploading = false;

  final List<String> _categories = [
    'Discount',
    'New Product',
    'Vacation',
    'Closure',
    'Hiring',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.adData['title']);
    _descriptionController = TextEditingController(text: widget.adData['description']);
    _businessController = TextEditingController(text: widget.adData['business']);
    _locationController = TextEditingController(text: widget.adData['location']);
    _selectedCategory = widget.adData['category'];
    _categoryController = TextEditingController();
    _imageUrlController = TextEditingController(text: widget.adData['imageUrl']);

    if (_selectedCategory != null && !_categories.contains(_selectedCategory)) {
      _categories.insert(_categories.length - 1, _selectedCategory!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _businessController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final String imageUrl = _imageUrlController.text.trim();

      final String finalCategory = _selectedCategory == 'Other'
          ? _categoryController.text.trim()
          : _selectedCategory!;

      await FirebaseFirestore.instance.collection('ads').doc(widget.adId).update({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'business': _businessController.text.trim(),
        'location': _locationController.text.trim(),
        'category': finalCategory,
        'imageUrl': imageUrl,
        'updatedAt': Timestamp.now(),
      });

      if (_selectedCategory == 'Other' && finalCategory.isNotEmpty) {
        final doc = await FirebaseFirestore.instance
            .collection('ad_categories')
            .doc(finalCategory)
            .get();

        if (!doc.exists) {
          await FirebaseFirestore.instance
              .collection('ad_categories')
              .doc(finalCategory)
              .set({'createdAt': Timestamp.now()});
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Advertisement updated successfully!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update ad.")),
      );
    } finally {
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
            title: const Text(
              "Edit Advertisement",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(_titleController, 'Ad Title *'),
                    const SizedBox(height: 12),
                    _buildTextField(_descriptionController, 'Description *', maxLines: 3),
                    const SizedBox(height: 12),
                    _buildTextField(_businessController, 'Business Name *'),
                    const SizedBox(height: 12),
                    _buildTextField(_imageUrlController, 'Image URL *'),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrlController.text,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[300],
                          alignment: Alignment.center,
                          child: const Text("Invalid image URL"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(_locationController, 'Location'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categories.contains(_selectedCategory)
                          ? _selectedCategory
                          : 'Other',
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value),
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        filled: true,
                        fillColor: Color.fromARGB(108, 255, 255, 255),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                    ),
                    if (_selectedCategory == 'Other') ...[
                      const SizedBox(height: 12),
                      _buildTextField(_categoryController, 'Enter New Category'),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _isUploading ? null : _submitAd,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A1A3A),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Update', style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
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
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: const Color.fromARGB(162, 255, 255, 255),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Required' : null,
    );
  }
}
