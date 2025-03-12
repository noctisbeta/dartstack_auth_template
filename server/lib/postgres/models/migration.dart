final class Migration {
  const Migration({required this.order, required this.up, required this.down});

  final String up;
  final String down;
  final int order;
}
