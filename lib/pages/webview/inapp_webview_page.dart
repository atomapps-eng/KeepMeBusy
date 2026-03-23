import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const InAppWebViewPage({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  InAppWebViewController? webViewController;
  bool isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(
  url: WebUri.uri(Uri.parse(widget.url)),
),
            initialSettings: InAppWebViewSettings(
  javaScriptEnabled: true,
  cacheEnabled: true,
  useShouldOverrideUrlLoading: true,
  mediaPlaybackRequiresUserGesture: false,

  // 🔥 PENTING UNTUK WEBSITE CLOUD / LOGIN
  useOnLoadResource: true,
  javaScriptCanOpenWindowsAutomatically: true,
  supportMultipleWindows: true,
  allowsInlineMediaPlayback: true,

  // 🔥 HANDLE REDIRECT & MIXED CONTENT
  mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onCreateWindow: (controller, createWindowRequest) async {
  final uri = createWindowRequest.request.url;

  if (uri != null) {
    await controller.loadUrl(
      urlRequest: URLRequest(url: uri),
    );
  }

  return true;
},
            onLoadStart: (controller, url) {
              setState(() => isLoading = true);
            },
            onLoadStop: (controller, url) {
              setState(() => isLoading = false);
            },
          ),

          if (isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}