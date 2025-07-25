import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_text_styles.dart';

class HelperPopup10JobEnding extends StatefulWidget {
  final VoidCallback? onClose;
  final String? jobId;
  const HelperPopup10JobEnding({Key? key, this.onClose, this.jobId})
      : super(key: key);
  @override
  State<HelperPopup10JobEnding> createState() => _HelperPopup10JobEndingState();
}

class _HelperPopup10JobEndingState extends State<HelperPopup10JobEnding>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale, _opacity;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        duration: const Duration(milliseconds: 300), vsync: this);
    _scale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _opacity = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _close();
    });
  }

  void _close() async {
    await _controller.reverse();
    if (widget.onClose != null) widget.onClose!();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
              opacity: _opacity.value,
              child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                      child: Transform.scale(
                          scale: _scale.value,
                          child: Container(
                              width: 340,
                              height: 295,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                        spreadRadius: 2)
                                  ]),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                            color: Colors.grey,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                  spreadRadius: 2)
                                            ]),
                                        child: const Icon(Icons.stop_rounded,
                                            color: Colors.white, size: 50)),
                                    const SizedBox(height: 30),
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40),
                                        child: Text('Job has been Ended',
                                            textAlign: TextAlign.center,
                                            style: TextStyle().copyWith(
                                                fontSize: 24,
                                                color: Colors.black,
                                                height: 1.3))),
                                    const SizedBox(height: 20),
                                    Container(
                                        width: 100,
                                        height: 4,
                                        decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(2)),
                                        child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: _controller.value,
                                            child: Container(
                                                decoration: BoxDecoration(
                                                    color: Colors.grey,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            2))))),
                                  ]))))));
        });
  }

  static void show(BuildContext context, {String? jobId}) => showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (context) => HelperPopup10JobEnding(
          onClose: () => Navigator.of(context).pop(), jobId: jobId));
}
