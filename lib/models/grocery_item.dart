class GroceryItem {
  String id;
  String name;
  double price;

  GroceryItem({required this.id, required this.name, required this.price});

  // Convert to/from Firestore Document
  factory GroceryItem.fromFirestore(
      Map<String, dynamic> data, String documentId) {
    return GroceryItem(
      id: documentId,
      name: data['name'] ?? '',
      price: data['price'] ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
    };
  }
}
