import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../common/image_viewport_surface.dart';
import '../common/surface_ink_well.dart';
import '../../../core/cache/gallery_image_request.dart';
import '../../../core/cache/online_gallery_image_cache_manager.dart';
import '../../../data/models/online_gallery/gallery_item.dart';
import 'gallery_detail_controller.dart';
import 'gallery_detail_models.dart';
import 'video_player_widget.dart';

class GalleryDetailMediaViewer extends StatelessWidget {
  const GalleryDetailMediaViewer({
    super.key,
    required this.controller,
    required this.viewModel,
    required this.actions,
    required this.actionRail,
  });

  final GalleryDetailController controller;
  final GalleryDetailViewModel viewModel;
  final GalleryDetailActions actions;
  final Widget actionRail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionRailWidth = constraints.maxWidth < 600 ? 48.0 : 188.0;
        final compactHeight = constraints.maxHeight < 220;
        final actionRailVerticalInset = compactHeight ? 8.0 : 54.0;
        const actionRailRight = 10.0;
        if (viewModel.media.isEmpty) {
          return Stack(
            fit: StackFit.expand,
            children: [
              _noImageState(theme),
              Positioned(
                top: actionRailVerticalInset,
                right: actionRailRight,
                bottom: actionRailVerticalInset,
                width: actionRailWidth,
                child: _scrollableActionRail(),
              ),
            ],
          );
        }

        // 多图时的缩略图轨独立占宽，不覆盖图片
        final showThumbnailRail = viewModel.media.length > 1 && !compactHeight;
        final mediaWidth = math.max(
          0.0,
          constraints.maxWidth - (showThumbnailRail ? _thumbnailRailWidth : 0),
        );

        return ColoredBox(
          color: ImageViewportSurface.background,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showThumbnailRail) _thumbnailRail(theme),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: controller.pageController,
                      itemCount: viewModel.media.length,
                      onPageChanged: actions.mediaPageChanged,
                      itemBuilder: (context, index) => _mediaPage(
                        context,
                        theme,
                        viewModel.media[index],
                        index,
                        mediaWidth,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _darkOverlay(
                        child: Text(
                          viewModel.labels.imageCounter(
                            viewModel.mediaIndex + 1,
                            viewModel.media.length,
                          ),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: _darkOverlay(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.zoom_in,
                              size: 15,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              viewModel.labels.zoomHint,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_currentMediaFacts.isNotEmpty)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: _darkOverlay(
                          child: Text(
                            _currentMediaFacts,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (viewModel.mediaIndex > 0)
                      _navigationButton(left: true, rightOffset: 0),
                    if (viewModel.mediaIndex + 1 < viewModel.media.length)
                      _navigationButton(
                        left: false,
                        rightOffset: actionRailRight + actionRailWidth + 8,
                      ),
                    Positioned(
                      top: actionRailVerticalInset,
                      right: actionRailRight,
                      bottom: actionRailVerticalInset,
                      width: actionRailWidth,
                      child: _scrollableActionRail(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 缩略图轨宽度：64 的缩略图加两侧 7px 内边距
  static const double _thumbnailRailWidth = 78;

  Widget _scrollableActionRail() => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: SizedBox(
        height: math.max(48, constraints.maxHeight),
        child: actionRail,
      ),
    ),
  );

  String get _currentMediaFacts {
    final media = viewModel.currentMedia;
    if (media == null) return '';
    final values = <String>[];
    if (media.width > 0 && media.height > 0) {
      values.add('${media.width} × ${media.height}');
    }
    final extension = media.extension?.trim().toUpperCase() ?? '';
    if (extension.isNotEmpty) values.add(extension);
    return values.join(' · ');
  }

  Widget _mediaPage(
    BuildContext context,
    ThemeData theme,
    GalleryMedia media,
    int index,
    double availableWidth,
  ) {
    final capability = media.capability;
    if (capability.isVideo) {
      final videoUrl = capability.videoUrl;
      return videoUrl.isEmpty
          ? _videoPlaceholder(theme)
          : VideoPlayerWidget(videoUrl: videoUrl);
    }
    final imageUrl = capability.imageDisplayUrl;
    if (imageUrl.isEmpty) return _noImageState(theme);

    return InteractiveViewer(
      minScale: 0.75,
      maxScale: 5,
      boundaryMargin: const EdgeInsets.all(40),
      child: Center(
        child: CachedNetworkImage(
          key: ValueKey('$imageUrl:$index:${viewModel.imageRevision}'),
          imageUrl: imageUrl,
          cacheManager: OnlineGalleryImageCacheManager.instance,
          cacheKey: onlineGalleryImageCacheKeyForUrl(imageUrl),
          httpHeaders: onlineGalleryImageHeadersForUrl(imageUrl),
          memCacheWidth: GalleryImageSizing.detailViewportTargetWidth(
            MediaQuery.devicePixelRatioOf(context),
            availableWidth,
          ),
          fit: BoxFit.contain,
          placeholder: (_, __) => const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          errorWidget: (_, __, ___) => _imageError(theme, media),
        ),
      ),
    );
  }

  Widget _videoPlaceholder(ThemeData theme) => _scrollablePlaceholder([
    const Icon(Icons.play_circle_outline, color: Colors.white70, size: 54),
    const SizedBox(height: 10),
    Text(
      viewModel.labels.noImageDescription,
      textAlign: TextAlign.center,
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70),
    ),
  ]);

  Widget _imageError(ThemeData theme, GalleryMedia media) {
    return _scrollablePlaceholder([
      const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 46),
      const SizedBox(height: 10),
      Text(
        viewModel.labels.imageLoadFailed,
        style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
      ),
      const SizedBox(height: 10),
      FilledButton.tonalIcon(
        onPressed: () => actions.retryMedia(media),
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(viewModel.labels.retry),
      ),
    ]);
  }

  Widget _noImageState(ThemeData theme) {
    const foreground = ImageViewportSurface.mutedForeground;
    return ColoredBox(
      color: ImageViewportSurface.background,
      child: _scrollablePlaceholder([
        const Icon(
          Icons.image_not_supported_outlined,
          size: 54,
          color: foreground,
        ),
        const SizedBox(height: 12),
        Text(
          viewModel.labels.noImage,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          viewModel.labels.noImageDescription,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: foreground),
        ),
      ]),
    );
  }

  Widget _scrollablePlaceholder(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minHeight = constraints.hasBoundedHeight
            ? (constraints.maxHeight - 48).clamp(0.0, double.infinity)
            : 0.0;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _navigationButton({required bool left, required double rightOffset}) {
    return Positioned(
      left: left ? 12 : null,
      right: left ? null : rightOffset,
      top: 0,
      bottom: 0,
      child: Center(
        child: IconButton.filled(
          key: ValueKey(
            left
                ? 'gallery-detail-previous-media'
                : 'gallery-detail-next-media',
          ),
          onPressed: () =>
              actions.moveToMedia(viewModel.mediaIndex + (left ? -1 : 1)),
          tooltip: left
              ? viewModel.labels.previousImage
              : viewModel.labels.nextImage,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.55),
            foregroundColor: Colors.white,
          ),
          icon: Icon(left ? Icons.chevron_left : Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _thumbnailRail(ThemeData theme) {
    return SizedBox(
      width: _thumbnailRailWidth,
      child: DecoratedBox(
        // 分隔线画在轨道右缘，不挤占缩略图宽度
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border(
            right: BorderSide(color: theme.dividerColor.withValues(alpha: 0.6)),
          ),
        ),
        child: _MediaThumbnailRail(
          media: viewModel.media,
          currentIndex: viewModel.mediaIndex,
          labels: viewModel.labels,
          onSelect: actions.moveToMedia,
        ),
      ),
    );
  }

  Widget _darkOverlay({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: child,
      ),
    );
  }
}

/// 竖向缩略图轨
///
/// 自持滚动位置；当前媒体变化时把选中项滚到轨道中部，
/// 轨道独立占宽，不覆盖主图。
class _MediaThumbnailRail extends StatefulWidget {
  const _MediaThumbnailRail({
    required this.media,
    required this.currentIndex,
    required this.labels,
    required this.onSelect,
  });

  final List<GalleryMedia> media;
  final int currentIndex;
  final GalleryDetailDialogLabels labels;
  final ValueChanged<int> onSelect;

  @override
  State<_MediaThumbnailRail> createState() => _MediaThumbnailRailState();
}

class _MediaThumbnailRailState extends State<_MediaThumbnailRail> {
  static const double _itemSize = 64;
  static const double _itemGap = 8;

  /// 列表上下内边距，居中计算需要考虑它
  static const double _listPadding = 8;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    // 打开时可能停在非首项，首帧后先不加动画地就位
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerOn(widget.currentIndex, animate: false);
    });
  }

  @override
  void didUpdateWidget(covariant _MediaThumbnailRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _centerOn(widget.currentIndex);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _centerOn(int index, {bool animate = true}) {
    if (!_controller.hasClients) return;

    final position = _controller.position;
    final itemCenter =
        _listPadding + index * (_itemSize + _itemGap) + (_itemSize / 2);
    final target = (itemCenter - (position.viewportDimension / 2)).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if (!animate || MediaQuery.disableAnimationsOf(context)) {
      _controller.jumpTo(target);
      return;
    }
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView.builder(
      controller: _controller,
      scrollDirection: Axis.vertical,
      // 7px 水平内边距让 64 的缩略图在 78 宽的轨道里居中
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: _listPadding,
      ),
      itemCount: widget.media.length,
      itemBuilder: (context, index) => _buildItem(context, theme, index),
    );
  }

  Widget _buildItem(BuildContext context, ThemeData theme, int index) {
    final media = widget.media[index];
    final capability = media.capability;
    final selected = index == widget.currentIndex;
    final previewUrl = capability.canPrefetchPreview
        ? capability.previewUrl
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: _itemGap),
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.labels.imageCounter(index + 1, widget.media.length),
        child: SizedBox(
          width: _itemSize,
          height: _itemSize,
          child: SurfaceInkWell(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surfaceContainerLow,
            side: BorderSide(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
            clipBehavior: Clip.antiAlias,
            inkAboveChild: true,
            duration: const Duration(milliseconds: 140),
            onTap: () => widget.onSelect(index),
            child: previewUrl.isEmpty
                ? Icon(
                    capability.isVideo
                        ? Icons.play_circle_outline
                        : Icons.image_not_supported_outlined,
                  )
                : CachedNetworkImage(
                    imageUrl: previewUrl,
                    cacheManager: OnlineGalleryImageCacheManager.instance,
                    cacheKey: onlineGalleryImageCacheKeyForUrl(previewUrl),
                    httpHeaders: onlineGalleryImageHeadersForUrl(previewUrl),
                    memCacheWidth: GalleryImageSizing.gridTargetWidth(
                      layoutWidth: _itemSize,
                      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    ),
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
          ),
        ),
      ),
    );
  }
}
