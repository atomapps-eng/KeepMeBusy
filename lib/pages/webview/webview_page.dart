import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  bool isLoading = true;

  @override
void initState() {
  super.initState();

 controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..setBackgroundColor(const Color(0x00000000))
  ..enableZoom(true)
  ..setUserAgent(
    'Mozilla/5.0 (Linux; Android 10; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36'
  )

  ..setNavigationDelegate(
    NavigationDelegate(
      onPageStarted: (url) {
        print('START: $url');
        setState(() {
          isLoading = true;
        });
      },
      onPageFinished: (url) {
        print('FINISH: $url');
        setState(() {
          isLoading = false;
        });
      },
      onWebResourceError: (error) {
        print('ERROR: ${error.description}');
      },
    ),
  )
  ..loadRequest(Uri.parse(widget.url));
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
  children: [
    WebViewWidget(controller: controller),

    if (isLoading)
      const Center(
        child: CircularProgressIndicator(),
      ),
  ],
),
    );
  }
}