/// Presentation options kept for compatibility with existing prompt fields.
/// User-level autocomplete settings take precedence where explicitly set.
class AutocompleteConfig {
  const AutocompleteConfig({
    this.maxSuggestions,
    this.showTranslation = true,
    this.showCategory = true,
    this.showCount = true,
    this.enableChineseSearch = true,
    this.debounceDelay = const Duration(milliseconds: 150),
    this.minQueryLength = 2,
    this.autoInsertComma = true,
    this.replaceUnderscoreWithSpace = false,
    this.treatSpacesAsSeparators = false,
    this.submitOnEnter = false,
  });

  /// Overrides the user-level result count only for space-constrained fields.
  final int? maxSuggestions;
  final bool showTranslation;
  final bool showCategory;
  final bool showCount;
  final bool enableChineseSearch;
  final Duration debounceDelay;
  final int minQueryLength;
  final bool autoInsertComma;
  final bool replaceUnderscoreWithSpace;
  final bool treatSpacesAsSeparators;

  /// 单行检索框在 Enter 时优先提交搜索，而不是吞掉按键等待补全。
  /// 仅在补全没有可插入的候选项时生效，多行输入不受影响。
  final bool submitOnEnter;
}
