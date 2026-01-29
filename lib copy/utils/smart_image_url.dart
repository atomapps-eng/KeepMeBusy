import '../models/spare_part.dart';

String smartImageUrl(SparePart part) {
  if (part.imageUrl.isEmpty) return '';
  return '${part.imageUrl}?v=${part.imageVersion}';
}
