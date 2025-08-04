import 'dart:io' show File;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:location_based_attendance_app/widgets/fieldtitle.dart';
import 'package:location_based_attendance_app/widgets/field.dart';
import 'package:location_based_attendance_app/widgets/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProfileDetailspage extends StatefulWidget {
  const ProfileDetailspage({super.key});

  @override
  State<ProfileDetailspage> createState() => _ProfileDetailspageState();
}

class _ProfileDetailspageState extends State<ProfileDetailspage> {
  double screenHeight = 0;
  double screenWidth = 0;
  bool isUploading = false;
  bool isObscure = true;
  bool isEditable = false;
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final passwordController = TextEditingController();
  final groupNameController = TextEditingController();
  String selectedRole = '';
  final String phoneNumberPattern = r'^\+?[0-9]{7,15}$';
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    fetchAndSetRoleThenUserData();
  }

  Future<void> fetchAndSetRoleThenUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try Staff first
      final staffDoc =
          await FirebaseFirestore.instance
              .collection('Staff')
              .doc(user.uid)
              .get();
      if (staffDoc.exists) {
        setState(() {
          selectedRole = 'Staff';
        });
        fetchUserData();
        return;
      }
      // Try Student
      final studentDoc =
          await FirebaseFirestore.instance
              .collection('Student')
              .doc(user.uid)
              .get();
      if (studentDoc.exists) {
        setState(() {
          selectedRole = 'Student';
        });
        fetchUserData();
        return;
      }
    }
  }

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (selectedRole == 'Staff') {
        final staffDoc =
            await FirebaseFirestore.instance
                .collection('Staff')
                .doc(user.uid)
                .get();
        if (staffDoc.exists) {
          final staffdata = staffDoc.data()!;
          setState(() {
            avatarUrl = staffdata['avatar'];
            nameController.text = staffdata['name'] ?? '';
            emailController.text = staffdata['email'] ?? '';
            phoneNumberController.text = staffdata['phoneNumber'] ?? '';
            selectedRole = staffdata['role'] ?? '';
          });
        }
      } else {
        final studentDoc =
            await FirebaseFirestore.instance
                .collection('Student')
                .doc(user.uid)
                .get();
        if (studentDoc.exists) {
          final studentdata = studentDoc.data()!;
          setState(() {
            avatarUrl = studentdata['avatar'];
            nameController.text = studentdata['name'] ?? '';
            emailController.text = studentdata['email'] ?? '';
            phoneNumberController.text = studentdata['phoneNumber'] ?? '';
            groupNameController.text = studentdata['GroupName'] ?? '';
            selectedRole = studentdata['role'] ?? '';
          });
        }
      }
    }
    // Only use local avatar if there is no network avatar
    if (avatarUrl == null ||
        avatarUrl!.isEmpty ||
        !(avatarUrl!.startsWith('http'))) {
      final prefs = await SharedPreferences.getInstance();
      final localAvatarPath = prefs.getString('avatarPath_$selectedRole');
      if (localAvatarPath != null && File(localAvatarPath).existsSync()) {
        setState(() {
          avatarUrl = localAvatarPath;
        });
      }
    }
  }

  Future<void> updateUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final phoneNumber = phoneNumberController.text.trim();
    final name = nameController.text.trim();

    // Validation
    final regExp = RegExp(phoneNumberPattern);
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(message: "Name cannot be empty"),
      );
      return;
    } else if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(message: "Phone number cannot be empty"),
      );
      return;
    } else if (!regExp.hasMatch(phoneNumber)) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().errorSnackBar(
          message:
              "Enter your phone number in the correct format (e.g. +60123456789)",
        ),
      );
      return;
    }

    if (user != null && selectedRole == 'Staff') {
      // 1. Get the old staff name before updating
      final staffDoc =
          await FirebaseFirestore.instance
              .collection('Staff')
              .doc(user.uid)
              .get();
      final oldName = staffDoc['name'] ?? '';

      // 2. Update the staff profile with the new name
      await FirebaseFirestore.instance.collection('Staff').doc(user.uid).update(
        {'name': name, 'phoneNumber': phoneNumber, 'avatar': avatarUrl ?? ''},
      );

      // 3. Update all timetable docs where Lecturer == oldName
      final timetableQuery =
          await FirebaseFirestore.instance
              .collection('Timetable')
              .where('Lecturer', isEqualTo: oldName)
              .get();

      for (var doc in timetableQuery.docs) {
        await doc.reference.update({'Lecturer': name});
      }
    } else if (user != null && selectedRole == 'Student') {
      // Get old name and email before update
      final studentDoc =
          await FirebaseFirestore.instance
              .collection('Student')
              .doc(user.uid)
              .get();
      final oldName = studentDoc['name'] ?? '';
      final email = studentDoc['email'] ?? '';

      // Update student profile
      await FirebaseFirestore.instance
          .collection('Student')
          .doc(user.uid)
          .update({
            'name': name,
            'phoneNumber': phoneNumber,
            'avatar': avatarUrl ?? '',
          });

      // Update all Class docs where this student is in the Students list
      final classQuery =
          await FirebaseFirestore.instance
              .collection('Class')
              .where('Students', arrayContains: "$oldName ($email)")
              .get();

      for (var doc in classQuery.docs) {
        List students = List.from(doc['Students']);
        int idx = students.indexOf("$oldName ($email)");
        if (idx != -1) {
          students[idx] = "$name ($email)";
          await doc.reference.update({'Students': students});
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        CustomSnackBar().successSnackBar(
          message: "User Profile updated successfully.",
        ),
      );
      setState(() {
        isEditable = false;
      });
    }
  }

  Future<void> pickUploadProfilePic() async {
    // At the beginning of the pickUploadProfilePic method
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || uploadPreset == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Missing Cloudinary configuration. Please contact support.',
          ),
        ),
      );
      return;
    }
    final picker = ImagePicker();

    // Let user choose source
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take a photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
    );

    if (source == null) return;

    final XFile? pickedImage = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 90,
    );

    if (pickedImage == null) {
      print('No image picked!');
      return;
    }

    try {
      setState(() {
        isUploading = true;
      });

      // Get Cloudinary credentials from env
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset =
          dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';

      // Upload to Cloudinary
      final imageFile = File(pickedImage.path);
      final uploadParams = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split("/").last,
        ),
        'upload_preset': uploadPreset,
      });

      final response = await Dio().post(
        'https://api.cloudinary.com/v1_1/$cloudName/upload',
        data: uploadParams,
        options: Options(headers: {'X-Requested-With': 'XMLHttpRequest'}),
      );

      if (response.statusCode == 200) {
        final imageUrl = response.data['secure_url'];

        setState(() {
          avatarUrl = imageUrl;
          isUploading = false;
        });

        // Save avatar URL to Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String collection = selectedRole == 'Staff' ? 'Staff' : 'Student';
          await FirebaseFirestore.instance
              .collection(collection)
              .doc(user.uid)
              .update({'avatar': avatarUrl});
          await fetchUserData(); // Refresh user data
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error uploading image: ${response.data['error']['message']}',
            ),
          ),
        );
        setState(() {
          isUploading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload avatar: $e')));
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Profile Details",
          style: TextStyle(
            fontSize: 20,
            fontFamily: "NexaBold",
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(isEditable ? Icons.check : Icons.edit),
            color: Colors.white,
            tooltip: isEditable ? 'Save Changes' : 'Edit Profile',
            onPressed: () {
              if (isEditable) {
                updateUserProfile();
              } else {
                setState(() {
                  isEditable = true;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  CustomSnackBar().infoSnackBar(
                    message: "You can now edit your profile.",
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              SizedBox(height: screenHeight / 60),
              GestureDetector(
                onTap: isEditable ? pickUploadProfilePic : null,
                child:
                    (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? (avatarUrl!.startsWith('http')
                            ? ClipOval(
                              child: Image.network(
                                avatarUrl! +
                                    '?v=${DateTime.now().millisecondsSinceEpoch}',
                                width: screenWidth / 3,
                                height: screenWidth / 3,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Image.asset(
                                      'assets/images/userAvatar.png',
                                      width: screenWidth / 3,
                                      height: screenWidth / 3,
                                      fit: BoxFit.cover,
                                    ),
                              ),
                            )
                            : (File(avatarUrl!).existsSync()
                                ? ClipOval(
                                  child: Image.file(
                                    File(avatarUrl!),
                                    width: screenWidth / 3,
                                    height: screenWidth / 3,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : ClipOval(
                                  child: Image.asset(
                                    'assets/images/userAvatar.png',
                                    width: screenWidth / 3,
                                    height: screenWidth / 3,
                                    fit: BoxFit.cover,
                                  ),
                                )))
                        : ClipOval(
                          child: Image.asset(
                            'assets/images/userAvatar.png',
                            width: screenWidth / 3,
                            height: screenWidth / 3,
                            fit: BoxFit.cover,
                          ),
                        ),
              ),
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.symmetric(horizontal: screenWidth / 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    fieldTitle("Name", screenWidth),
                    editableCustomField(
                      "Enter your name",
                      nameController,
                      Icons.person,
                      screenHeight,
                      screenWidth,
                      readOnly: !isEditable,
                    ),
                    fieldTitle("Phone Number", screenWidth),
                    editableCustomField(
                      "Enter your phone number",
                      phoneNumberController,
                      Icons.phone,
                      screenHeight,
                      screenWidth,
                      readOnly: !isEditable,
                    ),
                    fieldTitle("Email", screenWidth),
                    editableCustomField(
                      "Enter your email",
                      emailController,
                      Icons.email,
                      screenHeight,
                      screenWidth,
                      readOnly: true,
                    ),
                    if (selectedRole != 'Staff')
                      fieldTitle("Tutorial Group", screenWidth),
                    if (selectedRole != 'Staff')
                      editableCustomField(
                        "Enter your tutorial group",
                        groupNameController,
                        Icons.group,
                        screenHeight,
                        screenWidth,
                        readOnly: true,
                      ),
                  ],
                ),
              ),
              SizedBox(height: screenHeight / 50),
            ],
          ),
        ),
      ),
    );
  }
}
