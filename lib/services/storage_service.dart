import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload user profile image
  Future<String?> uploadUserProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('users/${user.uid}/profile/$fileName');

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Upload web image (for web platform)
  Future<String?> uploadUserProfileImageWeb(Uint8List imageData, String fileName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fullFileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final Reference ref = _storage.ref().child('users/${user.uid}/profile/$fullFileName');

      // Upload data
      final UploadTask uploadTask = ref.putData(
        imageData,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'userId': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Profile image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  // Upload task attachment
  Future<String?> uploadTaskAttachment(File file, String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName = path.basename(file.path);
      final String extension = path.extension(fileName);
      final String fullFileName = 'attachment_${taskId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      
      final Reference ref = _storage.ref().child('users/${user.uid}/tasks/$taskId/attachments/$fullFileName');

      // Determine content type
      String contentType = 'application/octet-stream';
      if (extension.toLowerCase() == '.jpg' || extension.toLowerCase() == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.pdf') {
        contentType = 'application/pdf';
      } else if (extension.toLowerCase() == '.txt') {
        contentType = 'text/plain';
      }

      // Upload file
      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'userId': user.uid,
            'taskId': taskId,
            'originalName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Task attachment uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading task attachment: $e');
      return null;
    }
  }

  // Upload task attachment for web
  Future<String?> uploadTaskAttachmentWeb(Uint8List fileData, String fileName, String taskId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String extension = path.extension(fileName);
      final String fullFileName = 'attachment_${taskId}_${DateTime.now().millisecondsSinceEpoch}_$fileName';
      
      final Reference ref = _storage.ref().child('users/${user.uid}/tasks/$taskId/attachments/$fullFileName');

      // Determine content type
      String contentType = 'application/octet-stream';
      if (extension.toLowerCase() == '.jpg' || extension.toLowerCase() == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (extension.toLowerCase() == '.png') {
        contentType = 'image/png';
      } else if (extension.toLowerCase() == '.pdf') {
        contentType = 'application/pdf';
      }

      // Upload data
      final UploadTask uploadTask = ref.putData(
        fileData,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'userId': user.uid,
            'taskId': taskId,
            'originalName': fileName,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('Task attachment uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading task attachment: $e');
      return null;
    }
  }

  // Pick and upload profile image
  Future<String?> pickAndUploadProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      
      if (kIsWeb) {
        // Web platform
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (image != null) {
          final Uint8List imageData = await image.readAsBytes();
          return await uploadUserProfileImageWeb(imageData, image.name);
        }
      } else {
        // Mobile platform
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (image != null) {
          final File imageFile = File(image.path);
          return await uploadUserProfileImage(imageFile);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking and uploading profile image: $e');
      return null;
    }
  }

  // Pick and upload task attachment
  Future<String?> pickAndUploadTaskAttachment(String taskId) async {
    try {
      if (kIsWeb) {
        // Web platform - use file picker
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt', 'doc', 'docx'],
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final PlatformFile file = result.files.first;
          if (file.bytes != null) {
            return await uploadTaskAttachmentWeb(file.bytes!, file.name, taskId);
          }
        }
      } else {
        // Mobile platform
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt', 'doc', 'docx'],
          allowMultiple: false,
        );
        
        if (result != null && result.files.isNotEmpty) {
          final String? filePath = result.files.first.path;
          if (filePath != null) {
            final File file = File(filePath);
            return await uploadTaskAttachment(file, taskId);
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking and uploading task attachment: $e');
      return null;
    }
  }

  // Delete file from storage
  Future<bool> deleteFile(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('File deleted successfully: $downloadUrl');
      return true;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Get file metadata
  Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      final FullMetadata metadata = await ref.getMetadata();
      return metadata;
    } catch (e) {
      debugPrint('Error getting file metadata: $e');
      return null;
    }
  }

  // List user files
  Future<List<Reference>> getUserFiles(String folder) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Reference ref = _storage.ref().child('users/${user.uid}/$folder');
      final ListResult result = await ref.listAll();
      return result.items;
    } catch (e) {
      debugPrint('Error listing user files: $e');
      return [];
    }
  }

  // Delete all user data (for account deletion)
  Future<bool> deleteAllUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Reference userRef = _storage.ref().child('users/${user.uid}');
      final ListResult result = await userRef.listAll();

      // Delete all files recursively
      for (final Reference item in result.items) {
        await item.delete();
      }

      // Delete all subdirectories
      for (final Reference prefix in result.prefixes) {
        await _deleteDirectory(prefix);
      }

      debugPrint('All user data deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting all user data: $e');
      return false;
    }
  }

  // Helper method to delete directory recursively
  Future<void> _deleteDirectory(Reference dirRef) async {
    final ListResult result = await dirRef.listAll();
    
    // Delete all files in this directory
    for (final Reference item in result.items) {
      await item.delete();
    }
    
    // Recursively delete subdirectories
    for (final Reference prefix in result.prefixes) {
      await _deleteDirectory(prefix);
    }
  }

  // Get storage usage for user
  Future<int> getUserStorageUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Reference userRef = _storage.ref().child('users/${user.uid}');
      final ListResult result = await userRef.listAll();

      int totalSize = 0;
      
      for (final Reference item in result.items) {
        final FullMetadata metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      // Check subdirectories recursively
      for (final Reference prefix in result.prefixes) {
        totalSize += await _getDirectorySize(prefix);
      }

      return totalSize;
    } catch (e) {
      debugPrint('Error calculating storage usage: $e');
      return 0;
    }
  }

  // Helper method to calculate directory size
  Future<int> _getDirectorySize(Reference dirRef) async {
    final ListResult result = await dirRef.listAll();
    int size = 0;
    
    for (final Reference item in result.items) {
      final FullMetadata metadata = await item.getMetadata();
      size += metadata.size ?? 0;
    }
    
    for (final Reference prefix in result.prefixes) {
      size += await _getDirectorySize(prefix);
    }
    
    return size;
  }

  // Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}