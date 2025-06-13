import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_advertisement_screen.dart';
import 'advertisement_view_screen.dart';

class MyAdvertisementsScreen extends StatefulWidget {
  const MyAdvertisementsScreen({super.key});

  @override
  State<MyAdvertisementsScreen> createState() => _MyAdvertisementsScreenState();
}

class _MyAdvertisementsScreenState extends State<MyAdvertisementsScreen> {
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  final List<String> _statuses = ['All', 'Pending', 'Approved', 'Denied'];
  final List<String> _defaultCategories = [
    'All', 'Discount', 'New Product', 'Vacation', 'Closure', 'Hiring', 'Other'
  ];
  List<String> _categories = ['All'];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1B203D),
        body: Center(
          child: Text(
            'You are not signed in.',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final String userId = user.uid;

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
              "My Advertisements",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('ads').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "You have no ads yet.",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              final allAds = snapshot.data!.docs;
              final myAds = allAds.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['advertiserId'] == userId;
              }).toList();

              final Set<String> dynamicCategories = _defaultCategories.toSet();
              for (var doc in myAds) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['category'] != null && data['category'].toString().trim().isNotEmpty) {
                  dynamicCategories.add(data['category'] as String);
                }
              }
              _categories = dynamicCategories.toList();

              final filteredAds = myAds.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final matchesStatus = _selectedStatus == 'All' || data['status'] == _selectedStatus;
                final matchesCategory = _selectedCategory == 'All' || data['category'] == _selectedCategory;
                final matchesSearch = _searchQuery.isEmpty || (data['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
                return matchesStatus && matchesCategory && matchesSearch;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Total: ${filteredAds.length}",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by ad title...'
                            .toUpperCase(),
                        hintStyle: const TextStyle(color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white12,
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white70),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : const Icon(Icons.search, color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF27354C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              items: _categories.map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              )).toList(),
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                border: InputBorder.none,
                                label: Text('Category'),
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              onChanged: (value) => setState(() => _selectedCategory = value!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF27354C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              items: _statuses.map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              )).toList(),
                              dropdownColor: Colors.white,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                border: InputBorder.none,
                                label: Text('Status'),
                                labelStyle: TextStyle(color: Colors.white),
                              ),
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                              onChanged: (value) => setState(() => _selectedStatus = value!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: filteredAds.isEmpty
                        ? const Center(
                            child: Text(
                              "No ads match the selected filters.",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            itemCount: filteredAds.length,
                            itemBuilder: (context, index) {
                              final ad = filteredAds[index];
                              final adData = ad.data() as Map<String, dynamic>;
                              adData['id'] = ad.id;

                              final title = adData['title'] ?? '';
                              final category = adData['category'] ?? '';
                              final imageUrl = adData['imageUrl'] ?? '';
                              final status = adData['status'] ?? 'Pending';
                              final createdAt = (adData['createdAt'] as Timestamp?)?.toDate();

                              return Dismissible(
                                key: ValueKey(ad.id),
                                background: Container(
                                  color: const Color.fromARGB(255, 0, 145, 255),
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.edit, color: Colors.white),
                                ),
                                secondaryBackground: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                confirmDismiss: (direction) async {
                                  if (direction == DismissDirection.endToStart) {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("Delete Ad"),
                                        content: const Text("Are you sure you want to delete this ad?"),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                                        ],
                                      ),
                                    );
                                    if (confirmed == true) {
                                      await FirebaseFirestore.instance.collection('ads').doc(ad.id).delete();
                                    }
                                    return confirmed;
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditAdvertisementScreen(adId: adData['id'], adData: adData),
                                      ),
                                    );
                                    return false;
                                  }
                                },
                                child: InkWell(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdvertisementViewScreen(ad: adData),
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                          child: Image.network(
                                            imageUrl,
                                            width: double.infinity,
                                            height: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const SizedBox(
                                              height: 160,
                                              child: Center(child: Icon(Icons.image_not_supported)),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                                              const SizedBox(height: 4),
                                              Text(category, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    createdAt != null
                                                        ? "${createdAt.day}-${createdAt.month}-${createdAt.year}"
                                                        : "Date Unknown",
                                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(status),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => AdvertisementViewScreen(ad: adData),
                                                      ),
                                                    ),
                                                    child: const Text("More Info >", style: TextStyle(color: Colors.black)),
                                                  )
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Denied':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }
}
