import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _imageUrl;
  XFile? _selectedImage;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            setState(() {
              _imageUrl = data['profileImage'];
              _nameController.text = data['name'] ?? '';
              _phoneController.text = data['phone'] ?? '';
            });
          }
        }
      }
    } catch (e) {
      _showError('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      
      if (image != null) {
        setState(() => _selectedImage = image);
        await _uploadImage();
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('profileImages/${user.uid}/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        uploadTask = ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(
          File(_selectedImage!.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
      });

      setState(() {
        _imageUrl = downloadUrl;
        _selectedImage = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      }
    } catch (e) {
      _showError('Error uploading image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      _showError('Error saving profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.teal[700],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageUrl != null ? NetworkImage(_imageUrl!) : null,
                    child: _imageUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _isLoading ? null : _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLoading) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
              ],
              const SizedBox(height: 24),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveProfile,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
