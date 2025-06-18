import 'package:flutter/material.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

class HelpeePopup9JobPayment extends StatefulWidget {
  final VoidCallback? onClose;
  const HelpeePopup9JobPayment({Key? key, this.onClose}) : super(key: key);
  @override
  State<HelpeePopup9JobPayment> createState() => _HelpeePopup9JobPaymentState();
}

class _HelpeePopup9JobPaymentState extends State<HelpeePopup9JobPayment> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _animationController.forward();
    Future.delayed(const Duration(seconds: 3), () { if (mounted) _closePopup(); });
  }

  @override
  void dispose() { _animationController.dispose(); super.dispose(); }

  void _closePopup() async {
    await _animationController.reverse();
    if (widget.onClose != null) widget.onClose!();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            width: double.infinity, height: double.infinity, color: Colors.black.withOpacity(0.3),
            child: Center(
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 340, height: 295,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 4), spreadRadius: 2)]),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3), spreadRadius: 2)]),
                        child: const Icon(Icons.payment_rounded, color: Colors.white, size: 50),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text('Payment Processed Successfully', textAlign: TextAlign.center, style: TextStyle().copyWith(fontSize: 24, color: Colors.black, height: 1.3)),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 100, height: 4,
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft, widthFactor: _animationController.value,
                          child: Container(decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(2))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void show(BuildContext context) {
    showDialog(context: context, barrierDismissible: false, barrierColor: Colors.transparent, builder: (BuildContext context) => HelpeePopup9JobPayment(onClose: () => Navigator.of(context).pop()));
  }
} 
