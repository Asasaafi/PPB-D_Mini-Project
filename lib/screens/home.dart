// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'auth/login.dart';
// import '../homepage.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   void logout(BuildContext context) async {
//     await FirebaseAuth.instance.signOut();
//     Navigator.pushReplacementNamed(context, 'login');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           return Scaffold(
//             appBar: AppBar(
//               title: const Text('Notes App'),
//               centerTitle: true,
//               actions: [
//                 IconButton(
//                   onPressed: () => logout(context),
//                   icon: const Icon(Icons.logout),
//                 )
//               ],
//             ),
//             body: const HomePage(),
//           );
//         } else {
//           return const LoginScreen();
//         }
//       },
//     );
//   }
// }