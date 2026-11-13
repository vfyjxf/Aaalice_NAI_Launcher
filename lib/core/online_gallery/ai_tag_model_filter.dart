/// AI TAG 画廊的模型快捷筛选。
///
/// AI TAG 的自有检索接口没有结构化的模型参数，但 `q` 会同时匹配作品的
/// 模型元数据；这里用稳定的 key 做本地筛选状态，请求时再映射成检索词，
/// 避免把多词模型名塞进标签查询而触发标签数量上限。
enum AiTagModelFilter {
  naiV5('nai_v5', 'NAI V5', 'NovelAI Diffusion V5'),
  naiV45('nai_v45', 'NAI V4.5', 'NovelAI Diffusion V4.5'),
  naiV4('nai_v4', 'NAI V4', 'NovelAI Diffusion V4'),
  naiV3('nai_v3', 'NAI V3', 'NovelAI Diffusion V3'),
  illustrious('illustrious', 'Illustrious', 'Illustrious'),
  pony('pony', 'Pony', 'Pony Diffusion');

  const AiTagModelFilter(this.key, this.label, this.queryToken);

  /// 持久化用的稳定标识
  final String key;

  /// 下拉菜单展示名（模型名不翻译）
  final String label;

  /// 拼进 AI TAG `q` 参数的检索词
  final String queryToken;

  static AiTagModelFilter? fromKey(String? key) {
    if (key == null || key.isEmpty) return null;
    for (final filter in values) {
      if (filter.key == key) return filter;
    }
    return null;
  }
}
