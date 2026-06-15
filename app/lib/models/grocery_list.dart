class GroceryItem {
  final String name;
  final String quantity;
  final String notes;
  GroceryItem({required this.name, required this.quantity, this.notes = ''});
  factory GroceryItem.fromJson(Map<String, dynamic> j) => GroceryItem(
        name: j['name'] ?? '',
        quantity: j['quantity'] ?? '',
        notes: j['notes'] ?? '',
      );
}

class GrocerySection {
  final String section;
  final List<GroceryItem> items;
  GrocerySection({required this.section, required this.items});
  factory GrocerySection.fromJson(Map<String, dynamic> j) => GrocerySection(
        section: j['section'] ?? '',
        items: (j['items'] as List? ?? [])
            .map((e) => GroceryItem.fromJson(e))
            .toList(),
      );
}

class GroceryList {
  final List<GrocerySection> sections;
  GroceryList({required this.sections});
  factory GroceryList.fromJson(Map<String, dynamic> json) => GroceryList(
        sections: (json['sections'] as List? ?? [])
            .map((e) => GrocerySection.fromJson(e))
            .toList(),
      );
}