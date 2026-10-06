
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/incoming_call_service.dart';
import '../call/call_history_screen.dart';
import '../profile/profile_screen.dart';
import 'chat_list_screen.dart';
import 'users_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ============================================================
  // SERVICES
  // ============================================================

  final AuthService authService = AuthService();

  final IncomingCallService incomingCallService =
  IncomingCallService();

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        if (!mounted) return;

        final String userId =
            authService.currentUserId;

        if (userId.isEmpty) return;

        incomingCallService.startListening(
          context,
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    incomingCallService.stopListening();

    super.dispose();
  }

  // ============================================================
  // CURRENT USER ID
  // ============================================================

  String get currentUserId {
    return authService.currentUserId;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    // ----------------------------------------------------------
    // Confirmation Dialog
    // ----------------------------------------------------------

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
            // --------------------------------------------------
            // CANCEL
            // --------------------------------------------------

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

            // --------------------------------------------------
            // LOGOUT
            // --------------------------------------------------

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

    // ----------------------------------------------------------
    // User cancelled
    // ----------------------------------------------------------

    if (confirm != true) {
      return;
    }

    try {
      // --------------------------------------------------------
      // Stop incoming call listener
      // --------------------------------------------------------

      incomingCallService.stopListening();

      // --------------------------------------------------------
      // Logout through AuthService
      // --------------------------------------------------------
      //
      // AuthService:
      // 1. User offline karega
      // 2. Firebase signOut karega
      //
      // AuthGate automatically LoginScreen show karega.
      // --------------------------------------------------------

      await authService.logout();

      // --------------------------------------------------------
      // No manual navigation required
      // --------------------------------------------------------
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

  // ============================================================
  // OPEN PROFILE
  // ============================================================

  void openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const ProfileScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN USERS
  // ============================================================

  void openUsers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const UsersScreen(),
      ),
    );
  }

  // ============================================================
  // OPEN CALL HISTORY
  // ============================================================

  void openCallHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const CallHistoryScreen(),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    // ==========================================================
    // LOGIN CHECK
    // ==========================================================

    if (currentUserId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Chat App',
          ),
        ),
        body: const Center(
          child: Text(
            'Please login first',
          ),
        ),
      );
    }

    // ==========================================================
    // HOME SCREEN
    // ==========================================================

    return Scaffold(
      backgroundColor: Colors.white,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,

        // ------------------------------------------------------
        // TITLE
        // ------------------------------------------------------

        title: const Text(
          'Chats',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),

        // ------------------------------------------------------
        // ACTIONS
        // ------------------------------------------------------

        actions: [
          // ====================================================
          // NEW CHAT / USERS
          // ====================================================

          IconButton(
            tooltip: 'New Chat',
            onPressed: openUsers,
            icon: const Icon(
              Icons.search,
            ),
          ),

          // ====================================================
          // CALL HISTORY
          // ====================================================

          IconButton(
            tooltip: 'Call History',
            onPressed: openCallHistory,
            icon: const Icon(
              Icons.call,
            ),
          ),

          // ====================================================
          // PROFILE
          // ====================================================

          IconButton(
            tooltip: 'Profile',
            onPressed: openProfile,
            icon: const Icon(
              Icons.account_circle,
              size: 28,
            ),
          ),

          // ====================================================
          // MORE MENU
          // ====================================================

          PopupMenuButton<String>(
            tooltip: 'More',

            onSelected: (String value) {
              // ------------------------------------------------
              // PROFILE
              // ------------------------------------------------

              if (value == 'profile') {
                openProfile();
              }

              // ------------------------------------------------
              // CALL HISTORY
              // ------------------------------------------------

              else if (value == 'call_history') {
                openCallHistory();
              }

              // ------------------------------------------------
              // LOGOUT
              // ------------------------------------------------

              else if (value == 'logout') {
                logout();
              }
            },

            itemBuilder: (
                BuildContext context,
                ) {
              return [
                // =================================================
                // PROFILE
                // =================================================

                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Profile',
                      ),
                    ],
                  ),
                ),

                // =================================================
                // CALL HISTORY
                // =================================================

                const PopupMenuItem<String>(
                  value: 'call_history',
                  child: Row(
                    children: [
                      Icon(
                        Icons.call,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Call History',
                      ),
                    ],
                  ),
                ),

                // =================================================
                // LOGOUT
                // =================================================

                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Logout',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      // ========================================================
      // CHAT LIST
      // ========================================================

      body: const ChatListScreen(),

      // ========================================================
      // NEW CHAT BUTTON
      // ========================================================

      floatingActionButton:
      FloatingActionButton(
        onPressed: openUsers,

        backgroundColor:
        Colors.blue,

        foregroundColor:
        Colors.white,

        tooltip: 'New Chat',

        child: const Icon(
          Icons.chat,
        ),
      ),
    );
  }
}