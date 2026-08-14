import 'dart:convert';
import 'dart:io';
import 'package:booking/data/models/hairstyle_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';

class VirtualTryOnScreen extends StatefulWidget {
  const VirtualTryOnScreen({super.key});

  @override
  State<VirtualTryOnScreen> createState() => _VirtualTryOnScreenState();
}

class _VirtualTryOnScreenState extends State<VirtualTryOnScreen> {
  // ── State ──────────────────────────────────────────────────────────────────
  String? imageBase64;
  String? imageUri;
  HairstyleOption? selectedStyle;
  String? resultUrl;
  bool loading = false;
  bool loadingStyles = true;
  bool saving = false;
  bool fullScreenVisible = false;
  bool transferring = false;
  bool saved = false;
  String activeCategory = 'All';
  String gender = 'female';
  String styleType = 'hairstyle';
  List<HairstyleOption> hairstyles = [];

  // Usage tracking
  int usedToday = 0;
  bool limitReached = false;
  int remaining = 3;
  static const int dailyLimit = 3;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultKey = GlobalKey();
  late Stream<QuerySnapshot> _hairstyleStream;

  @override
  void initState() {
    super.initState();
    _fetchUsage();
    _buildStream();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Usage ──────────────────────────────────────────────────────────────────
  Future<void> _fetchUsage() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final snap = await FirebaseFirestore.instance
        .collection('tryOnUsage')
        .doc(uid)
        .collection('daily')
        .doc(today)
        .get();
    final count = snap.exists ? (snap.data()?['count'] ?? 0) as int : 0;
    if (mounted) {
      setState(() {
        usedToday = count;
        remaining = dailyLimit - count;
        limitReached = count >= dailyLimit;
      });
    }
  }

  // ── Firestore stream ───────────────────────────────────────────────────────
  void _buildStream() {
    _hairstyleStream = FirebaseFirestore.instance
        .collection('hairstyles')
        .where('gender', isEqualTo: gender)
        .where('type', isEqualTo: styleType)
        .orderBy('order')
        .snapshots();
  }

  void _onFilterChanged({String? newGender, String? newStyleType}) {
    setState(() {
      if (newGender != null) gender = newGender;
      if (newStyleType != null) styleType = newStyleType;
      activeCategory = 'All';
      selectedStyle = null;
      resultUrl = null;
      loadingStyles = true;
      _buildStream();
    });
  }

  // ── Image picker ───────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Upload your photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.purple,
                ),
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Use your camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_outlined,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Pick an existing photo'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    // maxWidth/maxHeight cap the decoded dimensions at capture time —
    // without this, a modern phone photo (e.g. 4000x3000) gets fully
    // decoded, base64-encoded, and sent to the Cloud Function at full
    // resolution even though imageQuality only controls JPEG compression,
    // not pixel dimensions.
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        imageUri = picked.path;
        imageBase64 = base64Encode(bytes);
        resultUrl = null;
      });
    }
  }

  // ── Try On retry ─────────────────────────────────────────────────────────────────

  Future<String> _saveFalImageToStorage(
    String falUrl, {
    int retries = 3,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        debugPrint('Fetching fal.ai image, attempt $attempt...');
        final response = await http
            .get(Uri.parse(falUrl), headers: {'Cache-Control': 'no-cache'})
            .timeout(const Duration(seconds: 30));

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final storageRef = FirebaseStorage.instance.ref().child(
          'tryOnResults/$uid/$timestamp.jpg',
        );

        await storageRef.putData(
          response.bodyBytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );

        return await storageRef.getDownloadURL();
      } catch (e) {
        debugPrint('Attempt $attempt failed: $e');
        if (attempt == retries) rethrow;
        // Wait before retry: 2s, 4s, 6s
        await Future.delayed(Duration(seconds: attempt * 2));
      }
    }
    throw Exception('All retry attempts failed');
  }

  // ── Try On ─────────────────────────────────────────────────────────────────
  Future<void> _runTryOn() async {
    if (imageBase64 == null || selectedStyle == null) return;
    if (limitReached) {
      _showAlert(
        'Daily Limit Reached',
        "You've used all 3 free try-ons for today. Come back tomorrow!",
      );
      return;
    }
    setState(() {
      loading = true;
      saved = false; // reset on new generation
    });
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'virtualHairstyleTryOn',
      );
      final result = await callable.call({
        'imageBase64': imageBase64,
        'hairstylePrompt': selectedStyle!.targetHairstyle,
        'hairColor': selectedStyle!.hairColor,
      });

      final falUrl = result.data['outputImageUrl'] as String;

      // Switch to transfer state
      setState(() {
        loading = false;
        transferring = true;
      });

      final permanentUrl = await _saveFalImageToStorage(falUrl);
      setState(() => resultUrl = permanentUrl);
      await _fetchUsage();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _resultKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      final message = e is FirebaseFunctionsException
          ? e.message ?? 'Try-on failed. Please try again.'
          : e.toString();
      _showAlert('Error', message);
    } finally {
      setState(() {
        loading = false;
        transferring = false;
      });
    }
  }

  // ── Save result ────────────────────────────────────────────────────────────
  Future<void> _saveResult() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || resultUrl == null || selectedStyle == null) return;
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tryOnHistory')
          .add({
            'imageUrl': resultUrl,
            'styleName': selectedStyle!.name,
            'targetHairstyle': selectedStyle!.targetHairstyle,
            'hairColor': selectedStyle!.hairColor,
            'category': selectedStyle!.category,
            'gender': selectedStyle!.gender,
            'type': selectedStyle!.type,
            'savedAt': FieldValue.serverTimestamp(),
          });
      _showAlert('Saved! ✅', 'Your look has been saved to your history.');
    } catch (e) {
      _showAlert('Error', 'Failed to save. Please try again.');
    } finally {
      setState(() => saving = false);
    }
  }

  // ── Share ──────────────────────────────────────────────────────────────────
  Future<void> _share() async {
    if (resultUrl == null) return;
    await Share.share('Check out my new hairstyle from Timely! 💇\n$resultUrl');
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // ── Header ──
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                child:  Row(
                  children: [
                     GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 15,),
                    Text(
                      'Virtual Try-On ✨',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUsageBanner(colors),
                      const SizedBox(height: 12),
                      _buildGenderToggle(colors),
                      const SizedBox(height: 10),
                      _buildStyleTypeToggle(colors),
                      const SizedBox(height: 8),
                      _buildStepLabel('1. Upload your photo', colors),
                      _buildImagePicker(colors),
                      _buildStepLabel('2. Pick a style', colors),
                      _buildCategoryTabs(colors),
                      _buildStyleGrid(colors),
                      if (selectedStyle != null) _buildSelectedBanner(colors),
                      _buildTryOnButton(colors),
                      if (resultUrl != null) _buildResultSection(colors),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Full screen modal ──
          if (fullScreenVisible) _buildFullScreenModal(colors),
        ],
      ),
    );
  }

  // ── Usage Banner ───────────────────────────────────────────────────────────
  Widget _buildUsageBanner(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: limitReached ? const Color(0xFFFFF0F0) : const Color(0xFFF3EEFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              limitReached
                  ? '⛔ Daily limit reached — resets at midnight'
                  : '✨ $remaining of 3 free try-ons remaining today',
              style: TextStyle(
                color: limitReached ? const Color(0xFFE14444) : colors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: List.generate(3, (i) {
              return Container(
                width: 24,
                height: 8,
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: i < usedToday ? Colors.grey[300] : colors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Gender Toggle ──────────────────────────────────────────────────────────
  Widget _buildGenderToggle(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleBtn(
            label: '👩 Women',
            active: gender == 'female',
            color: colors.primary,
            onTap: () => _onFilterChanged(newGender: 'female'),
          ),
          _toggleBtn(
            label: '👨 Men',
            active: gender == 'male',
            color: colors.primary,
            onTap: () => _onFilterChanged(newGender: 'male'),
          ),
        ],
      ),
    );
  }

  // ── Style Type Toggle ──────────────────────────────────────────────────────
  Widget _buildStyleTypeToggle(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleBtn(
            label: '💇 Hairstyles',
            active: styleType == 'hairstyle',
            color: colors.primary,
            activeStyle: true,
            onTap: () => _onFilterChanged(newStyleType: 'hairstyle'),
          ),
          _toggleBtn(
            label: '✂️ Haircuts',
            active: styleType == 'haircut',
            color: colors.primary,
            activeStyle: true,
            onTap: () => _onFilterChanged(newStyleType: 'haircut'),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn({
    required String label,
    required bool active,
    required Color color,
    required VoidCallback onTap,
    bool activeStyle = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? (activeStyle
                      ? Theme.of(context).scaffoldBackgroundColor
                      : color)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: active && activeStyle
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active
                  ? (activeStyle
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.white)
                  : Colors.grey,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ── Step label ─────────────────────────────────────────────────────────────
  Widget _buildStepLabel(String text, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
      ),
    );
  }

  // ── Image Picker ───────────────────────────────────────────────────────────
  Widget _buildImagePicker(ColorScheme colors) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageUri != null
            ? Image.file(
                File(imageUri!),
                fit: BoxFit.cover,
                // Downsample the decode to roughly the display size —
                // without this, Image.file decodes the full picked
                // resolution just to show it in a 200px-tall box.
                cacheHeight:
                    (200 * MediaQuery.of(context).devicePixelRatio).round(),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📷 Tap to upload',
                    style: TextStyle(color: Colors.grey[500], fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Category Tabs ──────────────────────────────────────────────────────────
  Widget _buildCategoryTabs(ColorScheme colors) {
    final cats = ['All', ...hairstyles.map((h) => h.category).toSet().toList()];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final isActive = activeCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => activeCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? colors.primary : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Style Grid ─────────────────────────────────────────────────────────────
  Widget _buildStyleGrid(ColorScheme colors) {
    return StreamBuilder<QuerySnapshot>(
      stream: _hairstyleStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 10),
                  Text(
                    'Loading styles...',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'No styles available yet.',
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          );
        }

        hairstyles = snap.data!.docs
            .map((d) => HairstyleOption.fromFirestore(d))
            .toList();

        final filtered = activeCategory == 'All'
            ? hairstyles
            : hairstyles.where((h) => h.category == activeCategory).toList();

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filtered.map((style) {
              final isSelected = selectedStyle?.id == style.id;
              final tileSize = (MediaQuery.of(context).size.width - 48) / 3;
              // Match the decoded bitmap size to the actual rendered
              // tile size (scaled by device pixel ratio) instead of a
              // fixed guess — keeps the fix correct across phone and
              // tablet widths.
              final cacheWidth =
                  (tileSize * MediaQuery.of(context).devicePixelRatio)
                      .round();
              return GestureDetector(
                onTap: () => setState(() {
                  selectedStyle = style;
                  resultUrl = null;
                }),
                child: SizedBox(
                  width: tileSize,
                  height: tileSize * 1.3,
                  child: Stack(
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: style.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: cacheWidth,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Selection overlay
                      if (isSelected)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            color: colors.primary.withOpacity(0.35),
                            alignment: Alignment.center,
                            child: const Text(
                              '✓',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),

                      // Name label
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                          child: Container(
                            color: Colors.black.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              style.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),

                      // Selection border
                      if (isSelected)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colors.primary,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ── Selected Banner ────────────────────────────────────────────────────────
  Widget _buildSelectedBanner(ColorScheme colors) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: colors.primary, fontSize: 13),
          children: [
            const TextSpan(text: 'Selected: '),
            TextSpan(
              text: selectedStyle!.name,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  // ── Try On Button ──────────────────────────────────────────────────────────
  Widget _buildTryOnButton(ColorScheme colors) {
    final disabled =
        imageBase64 == null || selectedStyle == null || loading || limitReached;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: disabled ? null : _runTryOn,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.primary,
            disabledBackgroundColor: colors.primary.withOpacity(0.4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading || transferring
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      loading ? 'Generating...' : 'Saving result...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                )
              : Text(
                  limitReached ? '⛔ Limit Reached' : '✨ Try This Style',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  // ── Result Section ─────────────────────────────────────────────────────────
  Widget _buildResultSection(ColorScheme colors) {
    return Container(
      key: _resultKey,
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your New Look ✨',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            selectedStyle?.name ?? '',
            style: TextStyle(fontSize: 13, color: colors.primary),
          ),
          const SizedBox(height: 12),

          // After image
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'After',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => setState(() => fullScreenVisible = true),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 280,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: resultUrl!,
                          fit: BoxFit.cover,
                          memCacheHeight: 500,
                          placeholder: (_, __) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.4),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            alignment: Alignment.center,
                            child: const Text(
                              'Tap to view full screen',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: saving || saved ? null : _saveResult,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: saved ? const Color(0xFF22c55e) : colors.primary,
                    ),
                  ),
                  child: saving
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Text(
                          saved ? '✅ Saved' : '🔖 Save Look',
                          style: TextStyle(
                            color: saved
                                ? const Color(0xFF22c55e)
                                : colors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),

          // Try another
          GestureDetector(
            onTap: () {
              setState(() {
                resultUrl = null;
                selectedStyle = null;
              });
              _scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            },
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Try another style',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Full Screen Modal ──────────────────────────────────────────────────────
  Widget _buildFullScreenModal(ColorScheme colors) {
    return Material(
      color: Colors.black.withOpacity(0.95),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => fullScreenVisible = false),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        '✕',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          selectedStyle?.name ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          selectedStyle?.category ?? '',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _share,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Share',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Full image
            Expanded(
              child: CachedNetworkImage(
                imageUrl: resultUrl ?? '',
                fit: BoxFit.contain,
                width: double.infinity,
                // No pinch-zoom here (unlike the portfolio/gallery
                // viewers), so it's safe to cap this tightly to the
                // screen's physical pixel width rather than leaving it
                // unbounded.
                memCacheWidth: (MediaQuery.of(context).size.width *
                        MediaQuery.of(context).devicePixelRatio)
                    .round(),
                placeholder: (_, __) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white),
              ),
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving
                          ? null
                          : () {
                              setState(() => fullScreenVisible = false);
                              _saveResult();
                            },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '🔖 Save Look',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}