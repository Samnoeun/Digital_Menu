import '../models/cart_item_model.dart';
import '../models/item_model.dart';

class CartService {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;

  CartService._internal();

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  void addToCart(ItemModel item) {
    final index = _items.indexWhere((cartItem) => cartItem.item.id == item.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItemModel(item: item));
    }
  }

  void removeFromCart(ItemModel item) {
    _items.removeWhere((cartItem) => cartItem.item.id == item.id);
  }

  void clearCart() {
    _items.clear();
  }

  double get totalPrice =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);
}
