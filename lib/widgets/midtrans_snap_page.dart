import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_colors.dart';

/// Halaman WebView untuk membuka halaman pembayaran Snap Midtrans.
///
/// Selama pembayaran, Snap akan redirect ke `finishUrl` setelah selesai.
/// URL itu ditangkap di sini, lalu halaman ditutup dan mengembalikan `true`
/// supaya pemanggil bisa mengecek status transaksi ke backend.
class MidtransSnapPage extends StatefulWidget {
  final String redirectUrl;
  final String finishUrl;
  final String title;

  const MidtransSnapPage({
    super.key,
    required this.redirectUrl,
    required this.finishUrl,
    this.title = 'Pembayaran Midtrans',
  });

  @override
  State<MidtransSnapPage> createState() => _MidtransSnapPageState();
}

class _MidtransSnapPageState extends State<MidtransSnapPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _finished = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onNavigationRequest: (request) {
            if (_isFinishUrl(request.url)) {
              _complete();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loadError = null);
          },
          onPageFinished: (url) {
            if (_isFinishUrl(url)) _complete();
          },
          onWebResourceError: (error) {
            // Abaikan error resource kecil (gambar/script), hanya tampilkan
            // kalau halaman utama gagal dimuat.
            if (error.isForMainFrame == true && error.description.isNotEmpty) {
              if (mounted) {
                setState(() => _loadError = error.description);
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.redirectUrl));
  }

  bool _isFinishUrl(String url) {
    final finish = widget.finishUrl.trim();
    if (finish.isNotEmpty && url.startsWith(finish)) return true;
    if (url.startsWith('draghub://midtrans-finish')) return true;

    // Cadangan: halaman redirect Snap biasanya membawa query status ini.
    return url.contains('order_id=') &&
        url.contains('status_code=') &&
        url.contains('transaction_status=');
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryMaroon,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          if (_loadError != null)
            Container(
              width: double.infinity,
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Text(
                'Gagal memuat halaman pembayaran: $_loadError\n'
                'Pastikan koneksi internet aktif.',
                style: TextStyle(fontSize: 11, color: Colors.red.shade900),
              ),
            ),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
