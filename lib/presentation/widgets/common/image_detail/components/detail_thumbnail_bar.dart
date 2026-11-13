import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../image_detail_data.dart';

/// 缩略图导航
///
/// 显示所有图片的缩略图，支持点击跳转
/// 横向为底部导航条，纵向为侧边导航轨
/// 悬停效果：放大（仅横向）、边框高亮、阴影
class DetailThumbnailBar extends StatelessWidget {
  final List<ImageDetailData> images;
  final int currentIndex;
  final ScrollController scrollController;
  final ValueChanged<int> onTap;

  /// 排列方向
  ///
  /// 纵向使用固定尺寸的侧边轨道，悬停不再改变几何
  final Axis axis;

  const DetailThumbnailBar({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.scrollController,
    required this.onTap,
    this.axis = Axis.horizontal,
  });

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent ||
        event.scrollDelta.dy == 0 ||
        !scrollController.hasClients) {
      return;
    }

    GestureBinding.instance.pointerSignalResolver.register(event, (
      resolvedEvent,
    ) {
      final scrollEvent = resolvedEvent as PointerScrollEvent;
      final position = scrollController.position;
      final target = (position.pixels + scrollEvent.scrollDelta.dy * 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      scrollController.jumpTo(target);
      scrollEvent.respond(allowPlatformDefault: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isVertical = axis == Axis.vertical;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerSignal: _handlePointerSignal,
      child: SizedBox(
        // 横向条固定高度，纵向轨道固定宽度
        height: isVertical ? null : 84,
        width: isVertical ? 84 : null,
        child: ListView.builder(
          controller: scrollController,
          scrollDirection: axis,
          padding: isVertical
              ? const EdgeInsets.symmetric(horizontal: 10, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: images.length,
          itemBuilder: (context, index) {
            return _ThumbnailItem(
              key: ValueKey(images[index].identifier),
              image: images[index],
              index: index,
              axis: axis,
              isSelected: index == currentIndex,
              onTap: () => onTap(index),
            );
          },
        ),
      ),
    );
  }
}

/// 单个缩略图项（带悬停动效）
class _ThumbnailItem extends StatefulWidget {
  final ImageDetailData image;
  final int index;
  final Axis axis;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThumbnailItem({
    super.key,
    required this.image,
    required this.index,
    required this.axis,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThumbnailItem> createState() => _ThumbnailItemState();
}

class _ThumbnailItemState extends State<_ThumbnailItem> {
  bool _isHovered = false;

  ImageProvider<Object> _buildThumbnailProvider() {
    ImageProvider<Object> provider = widget.image.getImageProvider();

    // 详情图可能已经为了限制大图解码尺寸而包装过 ResizeImage。
    // ResizeImage 不支持嵌套，缩略图应直接基于最底层 provider 解码。
    while (provider is ResizeImage) {
      provider = provider.imageProvider;
    }

    return ResizeImage(provider, width: 160);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // 计算尺寸：横向选中最大、悬停次之、默认最小；纵向固定尺寸，
    // 悬停只改变描边与透明度，避免轨道内元素跳动
    const baseSize = 72.0;
    const selectedSize = 80.0;
    const hoveredSize = 78.0;
    const railSize = 64.0;

    final isVertical = widget.axis == Axis.vertical;
    final size = isVertical
        ? railSize
        : widget.isSelected
        ? selectedSize
        : _isHovered
        ? hoveredSize
        : baseSize;

    // 计算边距：横向保持总高度不变，纵向在下方留出轨道间距
    const totalHeight = 84.0;
    final verticalMargin = (totalHeight - size) / 2;
    final margin = isVertical
        ? const EdgeInsets.only(bottom: 8)
        : EdgeInsets.only(
            right: 8,
            top: verticalMargin,
            bottom: verticalMargin,
          );

    // 边框颜色
    final borderColor = widget.isSelected
        ? primary
        : _isHovered
        ? primary.withValues(alpha: 0.7)
        : Colors.white.withValues(alpha: 0.2);

    // 边框宽度
    final borderWidth = widget.isSelected
        ? 2.5
        : _isHovered
        ? 2.0
        : 1.0;

    // 阴影
    final shadow = widget.isSelected || _isHovered
        ? [
            BoxShadow(
              color: primary.withValues(alpha: widget.isSelected ? 0.4 : 0.25),
              blurRadius: widget.isSelected ? 12 : 8,
              spreadRadius: widget.isSelected ? 2 : 1,
            ),
          ]
        : null;

    // 透明度
    final opacity = widget.isSelected
        ? 1.0
        : _isHovered
        ? 0.85
        : 0.5;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: size,
          height: size,
          margin: margin,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: shadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedOpacity(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 150),
              opacity: opacity,
              child: Image(image: _buildThumbnailProvider(), fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
