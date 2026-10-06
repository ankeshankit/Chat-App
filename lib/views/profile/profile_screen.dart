import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState
    extends State<ProfileScreen> {
  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController phoneController =
  TextEditingController();

  bool isEditing = false;
  bool isSaving = false;

  // =====================================================
  // CURRENT USER
  // =====================================================

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  // =====================================================
  // SAVE PROFILE
  // =====================================================

  Future<void> saveProfile() async {
    if (currentUserId.isEmpty) {
      return;
    }

    final String name =
    nameController.text.trim();

    final String phone =
    phoneController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your name',
          ),
        ),
      );

      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      await firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'name': name,
        'phone': phone,
      });

      if (!mounted) return;

      setState(() {
        isEditing = false;
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Profile updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Update failed: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    final bool? confirm =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),
          content: const Text(
            'Are you sure you want to logout?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      // Set offline
      if (currentUserId.isNotEmpty) {
        await firestore
            .collection('users')
            .doc(currentUserId)
            .update({
          'isOnline': false,
          'lastSeen':
          FieldValue.serverTimestamp(),
        });
      }

      await auth.signOut();

      if (!mounted) return;

      // Go to login
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Logout failed: $e',
          ),
        ),
      );
    }
  }

  // =====================================================
  // PROFILE HEADER
  // =====================================================

  Widget profileAvatar(
      String name,
      ) {
    return CircleAvatar(
      radius: 55,
      backgroundColor:
      Colors.blue.shade100,
      child: Text(
        name.isNotEmpty
            ? name[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontSize: 42,
          fontWeight:
          FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  // =====================================================
  // INFO CARD
  // =====================================================

  Widget infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
      const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius:
        BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
            Colors.blue.shade50,
            child: Icon(
              icon,
              color: Colors.blue,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    Colors.grey.shade600,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value.isEmpty
                      ? 'Not available'
                      : value,
                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // EDIT FIELD
  // =====================================================

  Widget editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration:
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(14),
        ),
      ),
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    if (currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Profile',
          ),
        ),
        body: const Center(
          child: Text(
            'Please login first',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                if (!isEditing) {
                  isEditing = true;
                } else {
                  isEditing = false;
                }
              });
            },
            icon: Icon(
              isEditing
                  ? Icons.close
                  : Icons.edit,
            ),
          ),
        ],
      ),

      body: StreamBuilder<
          DocumentSnapshot>(
        stream: firestore
            .collection('users')
            .doc(currentUserId)
            .snapshots(),

        builder: (
            context,
            snapshot,
            ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData ||
              !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'User data not found',
              ),
            );
          }

          final data =
          snapshot.data!.data()
          as Map<String, dynamic>;

          final String name =
              data['name'] ?? '';

          final String email =
              data['email'] ?? '';

          final String phone =
              data['phone'] ?? '';

          final bool isOnline =
              data['isOnline'] ?? false;

          // Set controllers only when
          // opening edit mode
          if (!isEditing) {
            nameController.text =
                name;

            phoneController.text =
                phone;
          }

          return SingleChildScrollView(
            padding:
            const EdgeInsets.all(20),

            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),

                // ==========================================
                // AVATAR
                // ==========================================

                Stack(
                  children: [
                    profileAvatar(
                      name,
                    ),

                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration:
                        BoxDecoration(
                          color: isOnline
                              ? Colors.green
                              : Colors.grey,
                          shape:
                          BoxShape.circle,
                          border:
                          Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                Text(
                  name.isEmpty
                      ? 'User'
                      : name,
                  style:
                  const TextStyle(
                    fontSize: 23,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  isOnline
                      ? 'Online'
                      : 'Offline',
                  style: TextStyle(
                    color: isOnline
                        ? Colors.green
                        : Colors.grey,
                    fontWeight:
                    FontWeight.w500,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // ==========================================
                // EDIT MODE
                // ==========================================

                if (isEditing) ...[
                  editField(
                    controller:
                    nameController,
                    label: 'Name',
                    icon:
                    Icons.person_outline,
                  ),

                  const SizedBox(
                    height: 15,
                  ),

                  editField(
                    controller:
                    phoneController,
                    label: 'Phone',
                    icon:
                    Icons.phone_outlined,
                    keyboardType:
                    TextInputType.phone,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  SizedBox(
                    width:
                    double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : saveProfile,
                      child: isSaving
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                        CircularProgressIndicator(
                          strokeWidth:
                          2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Text(
                        'Save Changes',
                        style:
                        TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ]

                // ==========================================
                // VIEW MODE
                // ==========================================

                else ...[
                  infoCard(
                    icon:
                    Icons.person_outline,
                    title: 'Name',
                    value: name,
                  ),

                  infoCard(
                    icon:
                    Icons.email_outlined,
                    title: 'Email',
                    value: email,
                  ),

                  infoCard(
                    icon:
                    Icons.phone_outlined,
                    title: 'Phone',
                    value: phone,
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  // ========================================
                  // LOGOUT
                  // ========================================

                  SizedBox(
                    width:
                    double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: logout,
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      label:
                      const Text(
                        'Logout',
                        style:
                        TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                      style:
                      OutlinedButton.styleFrom(
                        side:
                        const BorderSide(
                          color: Colors.red,
                        ),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 30,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();

    super.dispose();
  }
}