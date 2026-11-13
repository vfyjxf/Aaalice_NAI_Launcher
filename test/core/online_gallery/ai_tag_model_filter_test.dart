import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/online_gallery/ai_tag_model_filter.dart';

void main() {
  test('AI TAG model filters map stable keys to server search tokens', () {
    expect(AiTagModelFilter.fromKey(null), isNull);
    expect(AiTagModelFilter.fromKey(''), isNull);
    expect(AiTagModelFilter.fromKey('unknown'), isNull);

    final naiV5 = AiTagModelFilter.fromKey('nai_v5');
    expect(naiV5, AiTagModelFilter.naiV5);
    expect(naiV5!.queryToken, 'NovelAI Diffusion V5');
    expect(naiV5.label, 'NAI V5');

    for (final filter in AiTagModelFilter.values) {
      expect(AiTagModelFilter.fromKey(filter.key), filter);
      expect(filter.queryToken.trim(), isNotEmpty);
    }
  });
}
