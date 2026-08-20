import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'detail_screen.dart';
import '../providers/theme_provider.dart';

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
        final itemList = _buildFallbackItems(products);
        if (mounted) {
          setState(() {
            _cartItems = itemList;
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
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<CartProduct> _buildFallbackItems(List<Product> products) {
    return products.take(4).map((product) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

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

    return Column(
      children: [
        // cart items 
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: _cartItems.length,
            separatorBuilder: (context, index) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final cartItem = _cartItems[index];

              return InkWell(
                onTap: () => _navigateToDetail(cartItem.id),
                borderRadius: BorderRadius.circular(12.r),
                child: Card(
                  elevation: 2,
                  color: isDarkMode ? Colors.grey[900] : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.r),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Image.network(
                            cartItem.thumbnail,
                            width: 80.w,
                            height: 80.h,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.image, size: 40.sp),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                text: cartItem.title,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 8.h),
                              CustomText(
                                text: '\$${cartItem.price.toStringAsFixed(2)}',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                              SizedBox(height: 8.h),

                              // Quantity Adjuster
                              Row(
                                children: [
                                  _buildQtyButton(
                                    icon: Icons.remove,
                                    isDarkMode: isDarkMode,
                                    onTap: () => _updateQuantity(index, -1),
                                  ),
                                  SizedBox(width: 12.w),
                                  CustomText(
                                    text: '${cartItem.quantity}',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(width: 12.w),
                                  _buildQtyButton(
                                    icon: Icons.add,
                                    isDarkMode: isDarkMode,
                                    onTap: () => _updateQuantity(index, 1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        CustomText(
                          text: '\$${cartItem.total.toStringAsFixed(2)}',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[900] : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSummaryRow('Subtotal', _subtotal),
              SizedBox(height: 8.h),
              _buildSummaryRow('Delivery Fee', _deliveryFee),
              SizedBox(height: 8.h),
              _buildSummaryRow('Tax (5%)', _tax),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Divider(color: isDarkMode ? Colors.grey[700] : null),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText(
                    text: 'Total',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  CustomText(
                    text: '\$${_total.toStringAsFixed(2)}',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    // color: const Color(
                    //   0xFF6D4AFF,
                    // ), // Maintain Shopee orange for total
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              ElevatedButton(
                onPressed: _confirmOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55),
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 52.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: CustomText(
                  text: 'Confirm Order',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(text: label, fontSize: 14.sp),
        CustomText(
          text: '\$${value.toStringAsFixed(2)}',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }

  Widget _buildQtyButton({
    required IconData icon,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(4.r),
          child: Icon(
            icon,
            size: 20.sp,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}