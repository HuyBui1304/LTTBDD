import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: const SkeletonLoader(
          width: 40,
          height: 40,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: const SkeletonLoader(height: 16),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const SkeletonLoader(height: 12, width: double.infinity),
            const SizedBox(height: 4),
            const SkeletonLoader(height: 12, width: 150),
          ],
        ),
      ),
    );
  }
}

