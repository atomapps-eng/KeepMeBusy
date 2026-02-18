import 'package:flutter/material.dart';

class DraggableResizableWindow extends StatefulWidget {
  final String title;
  final Widget child;

  const DraggableResizableWindow({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  State<DraggableResizableWindow> createState() =>
      _DraggableResizableWindowState();
}

class _DraggableResizableWindowState
    extends State<DraggableResizableWindow> {

  bool _initialized = false;

  double width = 900;
  double height = 550;
  double top = 120;
  double left = 200;

  @override
  Widget build(BuildContext context) {

    final screenSize = MediaQuery.of(context).size;

    if (!_initialized) {
      left = (screenSize.width - width) / 2;
      top = (screenSize.height - height) / 2;
      _initialized = true;
    }

    return Stack(
      children: [
        Positioned(
          top: top,
          left: left,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          left += details.delta.dx;
                          top += details.delta.dy;
                        });
                      },
                      child: Container(
                        height: 50,
                        color: Colors.green,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.white),
                              onPressed: () =>
                                  Navigator.pop(context),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Expanded(child: widget.child),

                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            width += details.delta.dx;
                            height += details.delta.dy;

                            if (width < 600) width = 600;
                            if (height < 400) height = 400;
                          });
                        },
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.drag_handle,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
