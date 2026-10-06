import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../chat/chat_screen.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({
    super.key,
  });

  @override
  State<UsersScreen> createState() =>
      _UsersScreenState();
}

class _UsersScreenState
    extends State<UsersScreen> {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth auth =
      FirebaseAuth.instance;

  final TextEditingController searchController =
  TextEditingController();

  String searchText = '';

  // =====================================================
  // CURRENT USER ID
  // =====================================================

  String get currentUserId {
    return auth.currentUser?.uid ?? '';
  }

  // =====================================================
  // OPEN CHAT
  // =====================================================

  Future<void> openChat(
      UserModel user,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          receiver: user,
        ),
      ),
    );
  }

  // =====================================================
  // SEARCH FILTER
  // =====================================================

  bool matchesSearch(
      UserModel user,
      ) {
    if (searchText.trim().isEmpty) {
      return true;
    }

    final String search =
    searchText.trim().toLowerCase();

    final String name =
    user.name.toLowerCase();

    final String email =
    user.email.toLowerCase();

    final String phone =
    user.phone.toLowerCase();

    return name.contains(search) ||
        email.contains(search) ||
        phone.contains(search);
  }

  // =====================================================
  // USER ITEM
  // =====================================================

  Widget userItem(
      UserModel user,
      ) {
    return Material(
      color: Colors.white,

      child: InkWell(
        onTap: () {
          openChat(user);
        },

        child: Padding(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),

          child: Row(
            children: [
              // ==========================================
              // PROFILE
              // ==========================================

              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,

                    backgroundColor:
                    Colors.blue.shade100,

                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0]
                          .toUpperCase()
                          : '?',

                      style:
                      const TextStyle(
                        fontSize: 22,
                        fontWeight:
                        FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),

                  // ONLINE DOT
                  if (user.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,

                      child: Container(
                        width: 15,
                        height: 15,

                        decoration:
                        BoxDecoration(
                          color: Colors.green,
                          shape:
                          BoxShape.circle,
                          border:
                          Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(
                width: 14,
              ),

              // ==========================================
              // USER DETAILS
              // ==========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,

                  children: [
                    Text(
                      user.name.isEmpty
                          ? 'Unknown User'
                          : user.name,

                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style:
                      const TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      user.email,

                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,

                      style: TextStyle(
                        fontSize: 13,
                        color:
                        Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // ==========================================
              // CHAT ICON
              // ==========================================

              const Icon(
                Icons.chat_outlined,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // EMPTY SEARCH
  // =====================================================

  Widget emptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [
          Icon(
            Icons.person_search,
            size: 70,
            color: Colors.grey.shade400,
          ),

          const SizedBox(
            height: 15,
          ),

          const Text(
            'No user found',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
              FontWeight.w600,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Try another name or email',
            style: TextStyle(
              color:
              Colors.grey.shade600,
            ),
          ),
        ],
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
            'New Chat',
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
      backgroundColor:
      Colors.grey.shade50,

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        title: const Text(
          'New Chat',
        ),

        actions: [
          if (searchText.isNotEmpty)
            IconButton(
              onPressed: () {
                searchController.clear();

                setState(() {
                  searchText = '';
                });
              },

              icon: const Icon(
                Icons.clear,
              ),
            ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: Column(
        children: [
          // =============================================
          // SEARCH BOX
          // =============================================

          Padding(
            padding:
            const EdgeInsets.all(12),

            child: TextField(
              controller:
              searchController,

              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },

              decoration:
              InputDecoration(
                hintText:
                'Search name, email or phone',

                prefixIcon:
                const Icon(
                  Icons.search,
                ),

                suffixIcon:
                searchText.isNotEmpty
                    ? IconButton(
                  onPressed: () {
                    searchController
                        .clear();

                    setState(() {
                      searchText =
                      '';
                    });
                  },

                  icon:
                  const Icon(
                    Icons.clear,
                  ),
                )
                    : null,

                filled: true,

                fillColor:
                Colors.white,

                border:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),

                  borderSide:
                  BorderSide.none,
                ),

                enabledBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),

                  borderSide:
                  BorderSide.none,
                ),

                focusedBorder:
                OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),

                  borderSide:
                  const BorderSide(
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),

          // =============================================
          // USERS
          // =============================================

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('users')
                  .snapshots(),

              builder: (
                  context,
                  snapshot,
                  ) {
                // =========================================
                // LOADING
                // =========================================

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                // =========================================
                // ERROR
                // =========================================

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        20,
                      ),

                      child: Text(
                        'Something went wrong\n\n'
                            '${snapshot.error}',
                        textAlign:
                        TextAlign.center,
                      ),
                    ),
                  );
                }

                // =========================================
                // NO USERS
                // =========================================

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users available',
                    ),
                  );
                }

                // =========================================
                // CONVERT USERS
                // =========================================

                final List<UserModel>
                users = [];

                for (final doc
                in snapshot.data!.docs) {
                  try {
                    final data =
                    doc.data()
                    as Map<String, dynamic>;

                    final UserModel user =
                    UserModel.fromMap(
                      data,
                      doc.id,
                    );

                    // Don't show current user
                    if (user.uid !=
                        currentUserId) {
                      // Search filter
                      if (matchesSearch(
                        user,
                      )) {
                        users.add(user);
                      }
                    }
                  } catch (e) {
                    debugPrint(
                      'User parsing error: $e',
                    );
                  }
                }

                // =========================================
                // NO SEARCH RESULT
                // =========================================

                if (users.isEmpty) {
                  return emptySearch();
                }

                // =========================================
                // SORT
                // =========================================

                users.sort(
                      (a, b) {
                    return a.name
                        .toLowerCase()
                        .compareTo(
                      b.name
                          .toLowerCase(),
                    );
                  },
                );

                // =========================================
                // USER LIST
                // =========================================

                return Material(
                  color:
                  Colors.grey.shade50,

                  child: ListView.separated(
                    padding:
                    EdgeInsets.zero,

                    itemCount:
                    users.length,

                    separatorBuilder:
                        (context, index) {
                      return const Divider(
                        height: 1,
                        indent: 72,
                      );
                    },

                    itemBuilder:
                        (context, index) {
                      return userItem(
                        users[index],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    searchController.dispose();

    super.dispose();
  }
}