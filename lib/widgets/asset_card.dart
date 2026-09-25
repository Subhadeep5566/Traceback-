import 'package:flutter/material.dart';
import '../models/asset.dart';
import 'tb_widgets.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final VoidCallback onTap;

  const AssetCard({
    super.key,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: TracebackItemCard(
        icon: asset.category.icon,
        title: asset.name,
        tracebackId: asset.tracebackId,
        status: asset.isLost
            ? TracebackItemStatus.lost
            : asset.isFound
                ? TracebackItemStatus.found
                : TracebackItemStatus.safe,
        location: asset.address.isNotEmpty ? asset.address : null,
        onTap: onTap,
      ),
    );
  }
}
