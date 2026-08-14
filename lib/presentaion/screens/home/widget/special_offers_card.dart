
import 'package:booking/presentaion/provider/pages/registration_screen.dart';
import 'package:flutter/material.dart';

class SpecialOffersCard extends StatelessWidget {
  final Map<String, dynamic> user;
  const SpecialOffersCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {

    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      if (value is int) return value != 0; // Handles 1/0 just in case
      return false;
    }

    final isProvider = parseBool(user['isProvider']);
    /* Future<void> seedHairstyles() async {
      final db = FirebaseFirestore.instance;

      final List<Map<String, dynamic>> allStyles = [
        // ─────────────────────────────────────────
        // WOMEN HAIRSTYLES
        // ─────────────────────────────────────────
        {
          "name": "Box Braids",
          "category": "Braids",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fbox%20braid.jpg?alt=media&token=e0228af9-c9e3-4048-bef2-d566e3c7d2cd",
          "popular": true,
          "order": 1,
        },
        {
          "name": "Knotless Braids",
          "category": "Braids",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fknotless%20braids.jpg?alt=media&token=a3ff8852-ac3d-4ffe-8920-20944682bb8d",
          "popular": true,
          "order": 2,
        },
        {
          "name": "Jumbo Braids",
          "category": "Braids",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fjumbo%20braids.jpg?alt=media&token=f4131d02-47de-4501-81d8-a32d3df04490",
          "popular": false,
          "order": 3,
        },
        {
          "name": "Boho Braids",
          "category": "Braids",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fboho%20braids.jpg?alt=media&token=46916766-4cc4-443d-8bd4-1bbc850bcee6",
          "popular": true,
          "order": 4,
        },
        {
          "name": "Fulani Braids",
          "category": "Braids",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Ffulani%20braids.jpg?alt=media&token=d64fc0f1-8a72-4e58-99a8-f2813fa6ce21",
          "popular": false,
          "order": 5,
        },

        {
          "name": "Natural Afro",
          "category": "Natural",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "afro", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fnatural%20afro.jpg?alt=media&token=dd3c2583-ce5c-4cd7-b3cb-e41233232c54",
          "popular": true,
          "order": 6,
        },
        {
          "name": "Twist Out",
          "category": "Natural",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "curly_hair", // closest enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Ftwist%20out.jpg?alt=media&token=7e6a24d6-226e-464b-a745-dfd526611a71",
          "popular": true,
          "order": 7,
        },
        {
          "name": "Bantu Knots",
          "category": "Natural",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle":
              "short_hair", // closest enum — bantu knots sit close to scalp
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fbantu%20knots.jpg?alt=media&token=7d4416eb-0924-4f23-9c64-e16c22cb2ffb",
          "popular": false,
          "order": 8,
        },
        {
          "name": "Wash and Go",
          "category": "Natural",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "curly_hair", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fwash%20and%20go.jpg?alt=media&token=896df8fc-debc-43bb-95f1-55fc95d41a9b",
          "popular": false,
          "order": 9,
        },

        {
          "name": "Short Bob",
          "category": "Short",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "bob_cut", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fshort%20bob.jpg?alt=media&token=31759310-5371-4e1b-8dad-26e0a2aab159",
          "popular": true,
          "order": 10,
        },
        {
          "name": "Pixie Cut",
          "category": "Short",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "pixie_cut", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fpixie%20cut.jpg?alt=media&token=2fc1ec43-e016-4333-acc7-e019e577a772",
          "popular": false,
          "order": 11,
        },
        {
          "name": "Braided Bob",
          "category": "Short",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ braids is more accurate than bob_cut
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fbraided%20bob.jpg?alt=media&token=7bcbed9c-f435-40a3-add5-c1f48952540d",
          "popular": true,
          "order": 12,
        },
        {
          "name": "TWA",
          "category": "Short",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "buzz_cut", // closest enum — very short all over
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fteeny%20weeny%20afro.jpg?alt=media&token=3fd152cb-82d1-4208-be1a-f61205f5972e",
          "popular": false,
          "order": 13,
        },

        {
          "name": "Straight & Sleek",
          "category": "Straight",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "straight_hair", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fstraight%20%26%20sleek.jpg?alt=media&token=05978402-48c0-463d-8fcc-48c76b661052",
          "popular": true,
          "order": 14,
        },
        {
          "name": "Straight Lob",
          "category": "Straight",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "straight_hair", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fstraight%20lob.jpg?alt=media&token=5ea28771-8ca2-4be5-91cd-24c3692478ad",
          "popular": true,
          "order": 15,
        },
        {
          "name": "Blowout",
          "category": "Straight",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle":
              "straight_hair", // ✅ exact enum — blowout = straight voluminous
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fblowout.jpg?alt=media&token=3f842161-9f98-415c-81d8-67205d2519f4",
          "popular": false,
          "order": 16,
        },

        {
          "name": "Faux Locs",
          "category": "Locs",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "dreadlocks", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Ffaux%20locs.jpg?alt=media&token=ec2b33e3-e06e-4b0e-a565-d41fcadbeab4",
          "popular": true,
          "order": 17,
        },
        {
          "name": "Soft Locs",
          "category": "Locs",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "dreadlocks", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fsoft%20locs.jpg?alt=media&token=5d431bb0-f24f-4d45-aa18-4342a8d5eb41",
          "popular": true,
          "order": 18,
        },
        {
          "name": "Goddess Locs",
          "category": "Locs",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "dreadlocks", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fgoddess%20locs.jpg?alt=media&token=982c643a-fee0-40eb-bcc4-e9d072170026",
          "popular": false,
          "order": 19,
        },
        {
          "name": "Butterfly Locs",
          "category": "Locs",
          "gender": "female",
          "type": "hairstyle",
          "targetHairstyle": "dreadlocks", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fbutterfly%20locs.jpg?alt=media&token=62f8c756-2b93-4346-a680-efc9f56c15df",
          "popular": false,
          "order": 20,
        },

        // ─────────────────────────────────────────
        // WOMEN HAIRCUTS
        // ─────────────────────────────────────────
        {
          "name": "Classic Pixie",
          "category": "Pixie",
          "gender": "female",
          "type": "haircut",
          "targetHairstyle": "pixie_cut", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2FClassic%20Pixie.jpg?alt=media&token=a72e6357-ef22-4227-b596-60652cdc5288",
          "popular": true,
          "order": 21,
        },

        // ─────────────────────────────────────────
        // MEN HAIRCUTS
        // ─────────────────────────────────────────
        {
          "name": "Textured Crop",
          "category": "Crop",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "short_hair", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Ftextured%20crop.jpg?alt=media&token=7dbf7f01-116a-473e-99ba-84c7211d990c",
          "popular": true,
          "order": 22,
        },
        {
          "name": "French Crop",
          "category": "Crop",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle":
              "bangs", // ✅ french crop has fringe/bangs across forehead
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Ffrench%20crop.jpg?alt=media&token=2a125c72-33a4-4330-8a92-18f037ffa112",
          "popular": true,
          "order": 23,
        },
        {
          "name": "Blowout Crop",
          "category": "Crop",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "short_hair", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fblowout%20crop.jpg?alt=media&token=95c52565-8add-48f9-9859-cdc92aa8a314",
          "popular": false,
          "order": 24,
        },

        {
          "name": "Skin Fade",
          "category": "Fade",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle":
              "buzz_cut", // ✅ skin fade = very short/bald on sides
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fskin%20fade.jpg?alt=media&token=e3c04f20-f0e4-420d-94ae-1d20bc85c9bd",
          "popular": true,
          "order": 25,
        },
        {
          "name": "Low Fade",
          "category": "Fade",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle":
              "side_part", // ✅ low fade usually has styled top with side part
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Flow%20fade.jpg?alt=media&token=603eaba8-d568-4806-9ab1-e2dfc1779fed",
          "popular": true,
          "order": 26,
        },
        {
          "name": "High Fade",
          "category": "Fade",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "buzz_cut", // ✅ high fade = very short on sides
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fhigh%20fade.jpg?alt=media&token=37f0d264-4eec-4f66-8139-b552883fe31b",
          "popular": true,
          "order": 27,
        },
        {
          "name": "Drop Fade",
          "category": "Fade",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "buzz_cut", // closest enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fdrop%20fade.jpg?alt=media&token=ce5a8a40-e8cf-4d19-8afb-f845b5f696af",
          "popular": false,
          "order": 28,
        },
        {
          "name": "Burst Fade",
          "category": "Fade",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "buzz_cut", // closest enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fburst%20fade.jpg?alt=media&token=6faa6ddd-1db9-426d-bfc3-31a34b63416e",
          "popular": false,
          "order": 29,
        },

        {
          "name": "Buzz Cut",
          "category": "Short",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "buzz_cut", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fbuzz%20cut.jpg?alt=media&token=1f52b10d-cdc2-4aeb-9b44-8a9917fb704d",
          "popular": true,
          "order": 30,
        },
        {
          "name": "Crew Cut",
          "category": "Short",
          "gender": "male",
          "type": "haircut",
          "targetHairstyle": "short_hair", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fcrew%20cut.jpg?alt=media&token=26c31610-5f42-4c07-b84a-d57b68958d2e",
          "popular": true,
          "order": 31,
        },

        // ─────────────────────────────────────────
        // MEN HAIRSTYLES
        // ─────────────────────────────────────────
        {
          "name": "Box Braids",
          "category": "Braids",
          "gender": "male",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fbox%20braids%20men.jpg?alt=media&token=a7f805b7-b17c-4e97-811f-ca76cf0255e9",
          "popular": true,
          "order": 32,
        },
        {
          "name": "Cornrows",
          "category": "Braids",
          "gender": "male",
          "type": "hairstyle",
          "targetHairstyle":
              "braids", // ✅ exact enum — cornrows are a braid style
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Fcornrows.jpg?alt=media&token=75c3f912-e7e5-4053-adfe-4bbdb275e4af",
          "popular": true,
          "order": 33,
        },
        {
          "name": "Fulani Cornrows",
          "category": "Braids",
          "gender": "male",
          "type": "hairstyle",
          "targetHairstyle": "braids", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Ffulani%20cornrows.jpg?alt=media&token=4c02754b-251b-4ee9-a8c5-5f3da34d4c1f",
          "popular": false,
          "order": 34,
        },
        {
          "name": "Locs",
          "category": "Braids",
          "gender": "male",
          "type": "hairstyle",
          "targetHairstyle": "dreadlocks", // ✅ exact enum
          "hairColor": "natural",
          "imageUrl":
              "https://firebasestorage.googleapis.com/v0/b/booking-cd20f.firebasestorage.app/o/hairstyles%2Flocs.jpg?alt=media&token=8244ef59-6a4c-429c-aa13-499990b66a05",
          "popular": true,
          "order": 35,
        },
      ];

      // Firestore allows max 500 ops per batch — chunk into 400 to be safe
      const chunkSize = 400;
      int committed = 0;

      for (int i = 0; i < allStyles.length; i += chunkSize) {
        final chunk = allStyles.sublist(
          i,
          (i + chunkSize) > allStyles.length ? allStyles.length : i + chunkSize,
        );

        final batch = db.batch();
        for (final style in chunk) {
          final ref = db.collection('hairstyles').doc();
          batch.set(ref, {...style, 'createdAt': FieldValue.serverTimestamp()});
        }

        await batch.commit();
        committed += chunk.length;
        print('✅ Committed $committed / ${allStyles.length}');
      }

      print('🎉 Done! Seeded ${allStyles.length} styles.');
    }*/

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Are you a Service Provider?',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Register your service now for free!!!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () async {

                            if (user['isEmailVerified'] == false) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.red,
                                content: Text(
                                  'Email not verified. Go to Profile Screen',
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServiceRegistrationScreen(
                                  userId: user['id'] ?? '',
                                  isProvider: isProvider,
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Colors.white,
                              width: 0.5,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Register Now'),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 110,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FREE!!!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
