import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';

class DetailScreen extends StatelessWidget {
  final Product product;
  final int _currentUserId = 1;

  const DetailScreen({super.key, required this.product});

  
  void _addToCart(BuildContext context) async {
    try {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Adding to cart...')));

      final success = await CartService().addToCart(
        _currentUserId,
        product.id,
        1,
      );

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to cart successfully!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add to cart: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _buildHeaderImage(),
                  Positioned(
                    top: 12.h,
                    left: 12.w,
                    child: _iconButton(
                      icon: Icons.keyboard_backspace,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    top: 12.h,
                    right: 12.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16.sp),
                          SizedBox(width: 4.w),
                          CustomText(
                            text: product.rating.toStringAsFixed(1),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            text: product.title,
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        CustomText(
                          text: '₱ ${product.price.toStringAsFixed(2)}',
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: [
                        _infoChip('Category', product.category),
                        _infoChip(
                          'Discount',
                          '${product.discountPercentage.toStringAsFixed(1)}%',
                        ),
                        _infoChip('Stock', '${product.stock} pcs'),
                        _infoChip('Brand', product.brand),
                        _infoChip('SKU', product.sku),
                        _infoChip(
                          'Min Order',
                          '${product.minimumOrderQuantity}',
                        ),
                        _infoChip('Availability', product.availabilityStatus),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    _sectionTitle('Description'),
                    SizedBox(height: 6.h),
                    CustomText(
                      text: product.description,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                    SizedBox(height: 16.h),
                    _sectionTitle('Tags'),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: product.tags
                          .map((tag) => Chip(label: Text(tag)))
                          .toList(),
                    ),
                    SizedBox(height: 16.h),
                    _sectionTitle('Product Details'),
                    SizedBox(height: 8.h),
                    _detailRow('Rating', product.rating.toStringAsFixed(1)),
                    _detailRow('Weight', '${product.weight} kg'),
                    _detailRow(
                      'Dimensions',
                      '${product.dimensions.width} x ${product.dimensions.height} x ${product.dimensions.depth}',
                    ),
                    _detailRow('Warranty', product.warrantyInformation),
                    _detailRow('Shipping', product.shippingInformation),
                    _detailRow('Return Policy', product.returnPolicy),
                    _detailRow('Barcode', product.meta.barcode),
                    _detailRow('Created At', product.meta.createdAt),
                    _detailRow('Updated At', product.meta.updatedAt),
                    SizedBox(height: 16.h),
                    _sectionTitle('Reviews'),
                    SizedBox(height: 8.h),
                    if (product.reviews.isEmpty)
                      const Text('No reviews available yet.')
                    else
                      ListView.separated(
                        itemCount: product.reviews.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final review = product.reviews[index];
                          return Card(
                            elevation: 1,
                            child: Padding(
                              padding: EdgeInsets.all(12.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: CustomText(
                                          text: review.reviewerName,
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: List.generate(
                                          review.rating,
                                          (_) => Icon(
                                            Icons.star,
                                            size: 16.sp,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: review.comment,
                                    fontSize: 13.sp,
                                  ),
                                  SizedBox(height: 4.h),
                                  CustomText(
                                    text: review.date,
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    SizedBox(height: 20.h),
                    ElevatedButton(
                      onPressed: () => _addToCart(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 52.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: CustomText(
                        text: 'Add to cart',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: Image.network(
            product.thumbnail,
            fit: BoxFit.cover,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.image, size: 56)),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 80.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Icon(icon, size: 24.sp),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return CustomText(
      text: title,
      fontSize: 18.sp,
      fontWeight: FontWeight.bold,
    );
  }

  Widget _infoChip(String label, String value) {
    return Chip(label: Text('$label: $value'));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110.w,
            child: CustomText(
              text: label,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: CustomText(text: value, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}