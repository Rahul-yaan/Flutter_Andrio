// import 'package:flutter/material.dart';
// import 'register_page.dart';
//
//
// class OnboardingPage extends StatefulWidget {
//   const OnboardingPage({super.key});
//
//   @override
//   State<OnboardingPage> createState() => _OnboardingPageState();
// }
//
// class _OnboardingPageState extends State<OnboardingPage> {
//
//   final PageController controller = PageController();
//   int currentPage = 0;
//
//   void nextPage() {
//
//     if (currentPage < 2) {
//
//       controller.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeIn,
//       );
//
//     } else {
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const RegisterPage(),
//         ),
//       );
//
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//
//       body: Column(
//         children: [
//
//           Expanded(
//             child: PageView(
//               controller: controller,
//               onPageChanged: (index){
//                 setState(() {
//                   currentPage = index;
//                 });
//               },
//               children: [
//
//                 // PAGE 1
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//
//                       Image.asset(
//                         "assets/images/welcome.jpeg",
//                         height: 250,
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       const Text(
//                         "Welcome to YAAN",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       const Text(
//                         "Your smart way to manage hotel bookings easily.",
//                         textAlign: TextAlign.center,
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//                 // PAGE 2
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//
//                       Image.asset(
//                         "assets/images/discover.jpeg",
//                         height: 250,
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       const Text(
//                         "Discover and Book",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       const Text(
//                         "Find the best hotels and book rooms instantly.",
//                         textAlign: TextAlign.center,
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//                 // PAGE 3
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//
//                       Image.asset(
//                         "assets/images/manage.jpeg",
//                         height: 250,
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       const Text(
//                         "Manage Your Schedule",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       const Text(
//                         "Keep track of all your bookings in one place.",
//                         textAlign: TextAlign.center,
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//               ],
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: nextPage,
//                 child: Text(
//                   currentPage == 2 ? "Get Started" : "Next",
//                 ),
//               ),
//             ),
//           )
//
//         ],
//       ),
//
//     );
//
//   }
// }








//
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // 🔥 Firestore import
// import 'register_page.dart';
//
// class OnboardingPage extends StatefulWidget {
//   const OnboardingPage({super.key});
//
//   @override
//   State<OnboardingPage> createState() => _OnboardingPageState();
// }
//
// class _OnboardingPageState extends State<OnboardingPage> {
//
//   final PageController controller = PageController();
//   int currentPage = 0;
//
//   // 🔥 Firestore Test Function
//   void testFirestore() async {
//     try {
//       await FirebaseFirestore.instance.collection('test').add({
//         'name': 'Yaan App',
//         'createdAt': DateTime.now(),
//       });
//
//       print("✅ Firestore is working");
//     } catch (e) {
//       print("❌ Firestore error: $e");
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     testFirestore(); // 🔥 Runs automatically when page opens
//   }
//
//   void nextPage() {
//
//     if (currentPage < 2) {
//
//       controller.nextPage(
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeIn,
//       );
//
//     } else {
//
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => const RegisterPage(),
//         ),
//       );
//
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//
//       body: Column(
//         children: [
//
//           Expanded(
//             child: PageView(
//               controller: controller,
//               onPageChanged: (index){
//                 setState(() {
//                   currentPage = index;
//                 });
//               },
//               children: [
//
//                 // PAGE 1
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//
//                       Image.asset(
//                         "assets/images/welcome.jpeg",
//                         height: 250,
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       const Text(
//                         "Welcome to YAAN",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       const Text(
//                         "Your smart way to manage hotel bookings easily.",
//                         textAlign: TextAlign.center,
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//                 // PAGE 2
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//
//                       Image.asset(
//                         "assets/images/discover.jpeg",
//                         height: 250,
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       const Text(
//                         "Discover and Book",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       const Text(
//                         "Find the best hotels and book rooms instantly.",
//                         textAlign: TextAlign.center,
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//                 // PAGE 3
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//
//                       Image.asset(
//                         "assets/images/manage.jpeg",
//                         height: 250,
//                       ),
//
//                       const SizedBox(height: 30),
//
//                       const Text(
//                         "Manage Your Schedule",
//                         style: TextStyle(
//                           fontSize: 28,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//
//                       const SizedBox(height: 15),
//
//                       const Text(
//                         "Keep track of all your bookings in one place.",
//                         textAlign: TextAlign.center,
//                       ),
//
//                     ],
//                   ),
//                 ),
//
//               ],
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.all(20),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: nextPage,
//                 child: Text(
//                   currentPage == 2 ? "Get Started" : "Next",
//                 ),
//               ),
//             ),
//           )
//
//         ],
//       ),
//
//     );
//
//   }
// }




import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {

  final PageController controller = PageController();
  int currentPage = 0;

  // 🔥 Firestore Test Function
  void testFirestore() async {
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'name': 'Yaan App',
        'createdAt': DateTime.now(),
      });

      debugPrint("✅ Firestore is working");
    } catch (e) {
      debugPrint("❌ Firestore error: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    testFirestore();
  }

  void nextPage() {
    if (currentPage < 2) {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => RegisterPage(), // ✅ FIXED (removed const)
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Column(
        children: [

          Expanded(
            child: PageView(
              controller: controller,
              onPageChanged: (index){
                setState(() {
                  currentPage = index;
                });
              },
              children: [

                // PAGE 1
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset(
                        "assets/images/welcome.jpeg",
                        height: 250,
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Welcome to YAAN",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Your smart way to manage hotel bookings easily.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // PAGE 2
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset(
                        "assets/images/discover.jpeg",
                        height: 250,
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Discover and Book",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Find the best hotels and book rooms instantly.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // PAGE 3
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Image.asset(
                        "assets/images/manage.jpeg",
                        height: 250,
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        "Manage Your Schedule",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        "Keep track of all your bookings in one place.",
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextPage,
                child: Text(
                  currentPage == 2 ? "Get Started" : "Next",
                ),
              ),
            ),
          )

        ],
      ),
    );
  }
}





