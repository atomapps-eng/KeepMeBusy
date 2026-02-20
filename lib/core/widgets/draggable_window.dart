import 'package:flutter/material.dart';

class DraggableResizableWindow extends StatefulWidget {
  final String title;
  final Widget child;
  final Color headerColor; // ← TAMBAH INI

  const DraggableResizableWindow({
    super.key,
    required this.title,
    required this.child,
    this.headerColor = Colors.green, // default tetap hijau
  });

  @override
  State<DraggableResizableWindow> createState() =>
      _DraggableResizableWindowState();
}

class _DraggableResizableWindowState
    extends State<DraggableResizableWindow> {

  bool _initialized = false;
  bool _isMinimized = false;
bool _isMaximized = false;

double? _previousWidth;
double? _previousHeight;
double? _previousTop;
double? _previousLeft;

  double width = 1000;
double height = 650;
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
                        color: widget.headerColor,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      widget.title,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),

    Row(
      mainAxisSize: MainAxisSize.min,
      children: [

        // MINIMIZE
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.white, size: 18),
          onPressed: _toggleMinimize,
        ),

        // MAXIMIZE / RESTORE
        IconButton(
          icon: Icon(
            _isMaximized
                ? Icons.crop_square
                : Icons.check_box_outline_blank,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => _toggleMaximize(screenSize),
        ),

        // CLOSE
        IconButton(
          icon: const Icon(Icons.close,
              color: Colors.white),
          onPressed: () =>
              Navigator.pop(context),
        ),
      ],
    ),
  ],
),
                      ),
                    ),

                    if (!_isMinimized)
  Expanded(child: widget.child),
if (!_isMinimized)
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
  void _toggleMinimize() {
  setState(() {
    _isMinimized = !_isMinimized;
  });
}

void _toggleMaximize(Size screenSize) {
  setState(() {
    if (!_isMaximized) {
      _previousWidth = width;
      _previousHeight = height;
      _previousTop = top;
      _previousLeft = left;

      width = screenSize.width * 0.95;
      height = screenSize.height * 0.95;
      left = (screenSize.width - width) / 2;
      top = (screenSize.height - height) / 2;
    } else {
      width = _previousWidth ?? 900;
      height = _previousHeight ?? 550;
      top = _previousTop ?? 120;
      left = _previousLeft ?? 200;
    }

    _isMaximized = !_isMaximized;
  });
}
}
