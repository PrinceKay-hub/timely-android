import 'package:flutter/material.dart';

// Empty State - No Bookings Screen
class EmptyScreen extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const EmptyScreen({super.key, required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
          children: [
            // Empty State Content
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration Container
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Background Circle
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(80),
                              ),
                            ),
                            // Icon
                             Icon(
                              icon,
                              size: 80,
                              color: Color(0xFF8B5CF6),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Title
                       Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Description
                       Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
  }}