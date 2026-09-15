import 'dart:io';

import 'package:booking/presentaion/screens/location/region_screen.dart';
import 'package:booking/presentaion/screens/shop/cubit/sell_cubit.dart';
import 'package:booking/presentaion/user/cubit/user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:booking/data/models/product_model.dart';

class SellScreen extends StatelessWidget {
  final String? productId;

  const SellScreen({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SellCubit(productId: productId),
      child: const _SellView(),
    );
  }
}

class _SellView extends StatelessWidget {
  const _SellView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SellCubit, SellState>(
      listenWhen: (prev, curr) =>
          prev.submitError != curr.submitError ||
          (!prev.submitted && curr.submitted),
      listener: (context, state) {
        if (state.submitError != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.submitError!)));
        }
        if (state.submitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isEditMode
                    ? 'Listing updated'
                    : 'Listed successfully. Your product is now under review.',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        if (state.isEditMode && state.loadStatus == SellLoadStatus.loading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state.isEditMode && state.loadStatus == SellLoadStatus.error) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Couldn't load this listing."),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go back'),
                  ),
                ],
              ),
            ),
          );
        }

        return const _SellForm();
      },
    );
  }
}

class _SellForm extends StatefulWidget {
  const _SellForm();

  @override
  State<_SellForm> createState() => _SellFormState();
}

class _SellFormState extends State<_SellForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _landmarkCtrl = TextEditingController();
  final _callCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _tagCtrl.dispose();
    _landmarkCtrl.dispose();
    _callCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<UserCubit>().loadUser();

    return BlocBuilder<SellCubit, SellState>(
      builder: (context, state) {
        // Sync controllers with loaded state (edit mode).
        if (_nameCtrl.text != state.name && state.name.isNotEmpty) {
          _nameCtrl.text = state.name;
        }
        if (_descCtrl.text != state.description &&
            state.description.isNotEmpty) {
          _descCtrl.text = state.description;
        }
        if (_priceCtrl.text != state.price && state.price.isNotEmpty) {
          _priceCtrl.text = state.price;
        }
        if (_landmarkCtrl.text != state.landmark && state.landmark.isNotEmpty) {
          _landmarkCtrl.text = state.landmark;
        }
        if (_callCtrl.text != state.callNumber && state.callNumber.isNotEmpty) {
          _callCtrl.text = state.callNumber;
        }

        return GestureDetector(
          onTap: () {
            FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus) {
              currentFocus.unfocus();
            }
          },
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Column(
              children: [
                _Header(isEditMode: state.isEditMode),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label('Photos'),
                        _ImageGrid(state: state),
                        const SizedBox(height: 6),
                        _Hint('${state.totalImageCount}/$kMaxImages photos'),
                        _Label('Product name'),
                        _TextField(
                          controller: _nameCtrl,
                          hint: 'e.g. Argan hair oil',
                          onChanged: context.read<SellCubit>().setName,
                        ),
                        _Label('Description'),
                        _TextField(
                          controller: _descCtrl,
                          hint: 'Describe the product, condition, and size',
                          maxLines: 4,
                          onChanged: context.read<SellCubit>().setDescription,
                        ),
                        _Label('Price ($kCurrency)'),
                        _TextField(
                          controller: _priceCtrl,
                          hint: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: context.read<SellCubit>().setPrice,
                        ),
                        _Label('Category'),
                        _CategoryGrid(selected: state.category),
                        _Label('Tags (help buyers find this in search)'),
                        _TagInput(
                          controller: _tagCtrl,
                          tags: state.tags,
                          onSubmit: () {
                            context.read<SellCubit>().setTagInput(
                              _tagCtrl.text,
                            );
                            context.read<SellCubit>().addTag();
                            _tagCtrl.clear();
                          },
                          onRemove: (t) =>
                              context.read<SellCubit>().removeTag(t),
                        ),
                        const SizedBox(height: 6),
                        _Hint(
                          '${state.tags.length}/$kMaxTags tags · tap a tag to remove it',
                        ),
                        _Label('Location'),
                        _LocationRow(state: state),
                        const SizedBox(height: 8),
                        _TextField(
                          controller: _landmarkCtrl,
                          hint: 'Nearest landmark',
                          onChanged: context.read<SellCubit>().setLandmark,
                        ),
                        const SizedBox(height: 6),
                        _Hint(
                          'Adding a location helps buyers nearby find this listing first.',
                        ),
                        _DeliverySwitch(value: state.isDelivery),
                        _Label('How should buyers reach you?'),
                        _ContactRow(useCall: state.useCall),
                        if (state.useCall) ...[
                          const SizedBox(height: 8),
                          _TextField(
                            controller: _callCtrl,
                            hint: 'e.g. 0244123456',
                            keyboardType: TextInputType.phone,
                            onChanged: context.read<SellCubit>().setCallNumber,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _Footer(submitting: state.submitting),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final bool isEditMode;
  const _Header({required this.isEditMode});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.arrow_back, color: colors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            isEditMode ? 'Edit listing' : 'Sell a product',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image grid ────────────────────────────────────────────────────────
class _ImageGrid extends StatelessWidget {
  final SellState state;
  const _ImageGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SellCubit>();
    final colors = Theme.of(context).colorScheme;
    final canAdd = state.totalImageCount < kMaxImages;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...state.existingImages.map(
          (url) => _Thumb(
            child: Image.network(url, fit: BoxFit.cover),
            onRemove: () => cubit.removeExistingImage(url),
          ),
        ),
        ...state.images.map(
          (img) => _Thumb(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(img.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      ColoredBox(color: colors.surfaceContainerHighest),
                ),
                if (img.processing)
                  Container(
                    color: Colors.black.withOpacity(0.35),
                    child: const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            onRemove: () => cubit.removeImage(img.id),
          ),
        ),
        if (canAdd)
          _AddImageButton(
            onTap: () => cubit.pickImages(),
            borderColor: colors.outlineVariant,
          ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final Widget child;
  final VoidCallback onRemove;
  const _Thumb({required this.child, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.expand(child: child),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddImageButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color borderColor;
  const _AddImageButton({required this.onTap, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          Icons.add_a_photo_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Category grid ─────────────────────────────────────────────────────
class _CategoryGrid extends StatelessWidget {
  final ProductCategory? selected;
  const _CategoryGrid({required this.selected});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kCategories.map((c) {
        final isSelected = selected == c.id;
        return InkWell(
          onTap: () => context.read<SellCubit>().setCategory(c.id),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _iconFor(c.icon),
                  size: 18,
                  color: isSelected ? Colors.white : colors.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  c.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _iconFor(String name) {
    // Map the MCI-style name to your Flutter icon set.
    switch (name) {
      case 'hair-dryer':
        return Icons.air;
      case 'hand-back-right':
        return Icons.back_hand_outlined;
      case 'spa':
        return Icons.spa_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'content-cut':
        return Icons.content_cut;
      case 'toolbox':
        return Icons.handyman_outlined;
      case 'flower':
        return Icons.local_florist_outlined;
      case 'gift':
        return Icons.card_giftcard_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

// ─── Tag input ─────────────────────────────────────────────────────────
class _TagInput extends StatelessWidget {
  final TextEditingController controller;
  final List<String> tags;
  final VoidCallback onSubmit;
  final ValueChanged<String> onRemove;
  const _TagInput({
    required this.controller,
    required this.tags,
    required this.onSubmit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _TextField(
                controller: controller,
                hint: 'e.g. extensions, curly, 18-inch',
                onChanged: context.read<SellCubit>().setTagInput,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onSubmit,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (t) => InkWell(
                    onTap: () => onRemove(t),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(Icons.close, size: 12, color: colors.onSurface),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─── Location row ──────────────────────────────────────────────────────
class _LocationRow extends StatelessWidget {
  final SellState state;
  const _LocationRow({required this.state});

  Future<void> _pickLocation(BuildContext context) async {
    final result = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(builder: (_) => const RegionsScreen(isService: true)),
    );
    if (!context.mounted) return;

    final picked = _parseLocationResult(result);
    if (picked != null) {
      context.read<SellCubit>().setSelectedLocation(picked);
    }
  }

  /// RegionsScreen can return:
  ///   • null (dismissed without selecting)
  ///   • String  "Region - District"
  ///   • Map     { region: ..., district: ... }
  /// We normalize all of them to a [SelectedLocation].
  SelectedLocation? _parseLocationResult(dynamic result) {
    if (result == null) return null;

    if (result is SelectedLocation) return result;

    if (result is Map) {
      final region = result['region'] as String?;
      final district = result['district'] as String?;
      if (region != null &&
          district != null &&
          region.isNotEmpty &&
          district.isNotEmpty) {
        return SelectedLocation(region: region, district: district);
      }
      return null;
    }

    if (result is String) {
      final trimmed = result.trim();
      // Guard against the "null - null" case when nothing was picked.
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'null - null') {
        return null;
      }

      final parts = trimmed.split(' - ');
      if (parts.length >= 2) {
        final region = parts.first.trim();
        final district = parts.sublist(1).join(' - ').trim();
        if (region.isNotEmpty && district.isNotEmpty) {
          return SelectedLocation(region: region, district: district);
        }
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loc = state.selectedLocation;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _pickLocation(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.place_outlined, size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      loc?.label ?? 'Choose region & district',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: colors.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (loc != null) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.read<SellCubit>().clearSelectedLocation(),
            child: Icon(
              Icons.cancel_outlined,
              size: 20,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Delivery switch ───────────────────────────────────────────────────
class _DeliverySwitch extends StatelessWidget {
  final bool value;
  const _DeliverySwitch({required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Offer delivery'),
                _Hint('Let buyers know you can ship or drop this off.'),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: context.read<SellCubit>().setIsDelivery,
            activeColor: colors.primary,
          ),
        ],
      ),
    );
  }
}

// ─── Contact row ───────────────────────────────────────────────────────
class _ContactRow extends StatelessWidget {
  final bool useCall;
  const _ContactRow({required this.useCall});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactOption(
            label: 'In-app chat',
            selected: !useCall,
            onTap: () => context.read<SellCubit>().setUseCall(false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ContactOption(
            label: 'Call',
            selected: useCall,
            onTap: () => context.read<SellCubit>().setUseCall(true),
          ),
        ),
      ],
    );
  }
}

class _ContactOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ContactOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.outlineVariant),
          color: selected ? colors.onSurface : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: selected
                ? Theme.of(context).scaffoldBackgroundColor
                : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ─── Footer ────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final bool submitting;
  const _Footer({required this.submitting});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isEditMode = context.select<SellCubit, bool>(
      (c) => c.state.isEditMode,
    );

    return BlocBuilder<UserCubit, UserState>(
      builder: (BuildContext context, UserState state) {
        if (state is UserLoaded) {
          final user = state.user;
          return Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.surfaceBright)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting
                    ? null
                    : () => context.read<SellCubit>().submit(user['displayName']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditMode ? 'Save changes' : 'Publish listing',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          );
        }
        return SizedBox.shrink();
      },
    );
  }
}

// ─── Small building blocks ─────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: TextStyle(color: colors.onSurface, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
        filled: true,
        fillColor: colors.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.surfaceBright),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.surfaceBright),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.primary),
        ),
      ),
    );
  }
}
