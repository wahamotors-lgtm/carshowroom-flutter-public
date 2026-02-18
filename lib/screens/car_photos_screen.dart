import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import '../config/theme.dart';

class CarPhotosScreen extends StatelessWidget {
  const CarPhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final images = (args?['images'] as List?)?.cast<String>() ?? [];
    final title = '${args?['make'] ?? ''} ${args?['model'] ?? ''}'.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(title.isEmpty ? 'صور السيارة' : title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: images.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text('لا توجد صور', style: TextStyle(color: AppColors.textGray, fontSize: 16)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: images.length,
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      backgroundColor: Colors.black,
                      appBar: AppBar(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        title: Text('${i + 1} / ${images.length}'),
                      ),
                      body: PhotoView(imageProvider: NetworkImage(images[i])),
                    ),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.bgLight,
                      child: const Icon(Icons.broken_image, color: AppColors.textMuted, size: 40),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
