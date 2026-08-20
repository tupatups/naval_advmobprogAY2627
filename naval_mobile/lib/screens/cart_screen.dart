import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, required this.userId});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<CartProduct> _cartItems = [];

  final double _taxRate = 0.05;
  final double _deliveryFee = 5.99;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final products = await ProductService().getAllProducts();
      if (products.isNotEmpty) {
        final fallbackItems = _buildFallbackItems(products);

        if (mounted) {
          setState(() {
            _cartItems = fallbackItems;
            _errorMessage = null;
            _isLoading = false;
          });
        }
        return;
      }

      final cart = await CartService().getUserCart(widget.userId);
      if (mounted) {
        setState(() {
          _cartItems = cart.products;
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      try {
        final cart = await CartService().getUserCart(widget.userId);
        if (mounted) {
          setState(() {
            _cartItems = cart.products;
            _errorMessage = null;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  List<CartProduct> _buildFallbackItems(List<Product> products) {
    return products.take(3).toList().map((product) {
      final total = product.price;
      final discountedTotal = total - (total * (product.discountPercentage / 100));

      return CartProduct(
        id: product.id,
        title: product.title,
        price: product.price,
        quantity: 1,
        total: total,
        discountPercentage: product.discountPercentage,
        discountedTotal: discountedTotal,
        thumbnail: product.thumbnail,
      );
    }).toList();
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final item = _cartItems[index];
      final newQuantity = item.quantity + delta;

      if (newQuantity <= 0) {
        // remove if quantity is 0
        _cartItems.removeAt(index);
      } else {
        final newTotal = item.price * newQuantity;
        final newDiscountedTotal =
            newTotal - (newTotal * (item.discountPercentage / 100));

        _cartItems[index] = CartProduct(
          id: item.id,
          title: item.title,
          price: item.price,
          quantity: newQuantity,
          total: newTotal,
          discountPercentage: item.discountPercentage,
          discountedTotal: newDiscountedTotal,
          thumbnail: item.thumbnail,
        );
      }
    });
  }

  void _confirmOrder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Order confirmed successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _cartItems.clear();
    });
  }

  void _navigateToDetail(int productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      Product fullProduct = await ProductService().getProductById(productId);
      if (!mounted) return;
      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailScreen(product: fullProduct),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load product details: $e')),
      );
    }
  }

  double get _subtotal => _cartItems.fold(0, (sum, item) => sum + item.total);
  double get _tax => _subtotal * _taxRate;
  double get _total =>
      _cartItems.isEmpty ? 0 : (_subtotal + _tax + _deliveryFee);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: CustomText(text: 'Error: $_errorMessage', fontSize: 14.sp),
      );
    }

    if (_cartItems.isEmpty) {
      return Center(
        child: CustomText(text: 'Your cart is empty.', fontSize: 16.sp),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.2),
            colorScheme.surface,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 10.h),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Cart',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_cartItems.length} item${_cartItems.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    'Ready to checkout',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              itemCount: _cartItems.length,
              separatorBuilder: (context, index) => SizedBox(height: 14.h),
              itemBuilder: (context, index) {
                final cartItem = _cartItems[index];
                final hasDiscount = cartItem.discountPercentage > 0;

                return InkWell(
                  onTap: () => _navigateToDetail(cartItem.id),
                  borderRadius: BorderRadius.circular(24.r),
                  child: Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18.r),
                          child: Container(
                            width: 90.w,
                            height: 90.h,
                            color: colorScheme.primaryContainer.withValues(
                              alpha: 0.25,
                            ),
                            child: Image.network(
                              cartItem.thumbnail,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 34.sp,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      cartItem.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  if (hasDiscount)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          999.r,
                                        ),
                                      ),
                                      child: Text(
                                        '${cartItem.discountPercentage.toStringAsFixed(0)}% OFF',
                                        style: TextStyle(
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              Row(
                                children: [
                                  Text(
                                    '\$${cartItem.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  if (hasDiscount) ...[
                                    SizedBox(width: 8.w),
                                    Text(
                                      '\$${(cartItem.price * (1 + cartItem.discountPercentage / 100)).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        decoration: TextDecoration.lineThrough,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      _buildQtyButton(
                                        icon: Icons.remove_rounded,
                                        onTap: () => _updateQuantity(index, -1),
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        '${cartItem.quantity}',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w800,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      _buildQtyButton(
                                        icon: Icons.add_rounded,
                                        onTap: () => _updateQuantity(index, 1),
                                        color: colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '\$${cartItem.total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20.w, 0, 20.w, 18.h),
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryRow('Subtotal', _subtotal, color: Colors.white),
                SizedBox(height: 10.h),
                _buildSummaryRow(
                  'Delivery Fee',
                  _deliveryFee,
                  color: Colors.white,
                ),
                SizedBox(height: 10.h),
                _buildSummaryRow('Tax (5%)', _tax, color: Colors.white),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: Divider(color: Colors.white.withValues(alpha: 0.35)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '\$${_total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),
                ElevatedButton(
                  onPressed: _confirmOrder,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 52.h),
                    backgroundColor: Colors.white,
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Confirm Order',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {required Color color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            color: color.withValues(alpha: 0.9),
          ),
        ),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Padding(
          padding: EdgeInsets.all(6.r),
          child: Icon(
            icon,
            size: 18.sp,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
