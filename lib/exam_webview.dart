import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:kiosk_mode/kiosk_mode.dart';
import 'package:flutter_windowmanager_plus/flutter_windowmanager_plus.dart';

class ExamWebView extends StatefulWidget {
  final String url;

  const ExamWebView({super.key, required this.url});

  @override
  State<ExamWebView> createState() => _ExamWebViewState();
}

class _ExamWebViewState extends State<ExamWebView> with WidgetsBindingObserver {
  late final WebViewController _controller;
  int _progress = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isFullscreen = false;
  bool _isJsDialogOpen = false;
  bool _ignoreTemporaryPause = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _secureScreen(); // blokir screenshot
    _startKioskMode(); // aktifkan kiosk mode

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(
        "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 "
        "(KHTML, like Gecko) Chrome/111.0.0.0 Mobile Safari/537.36 ExamBrowser",
      )
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) => setState(() => _progress = progress),
          onPageFinished: (url) => _injectSafeJS(),
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// Blokir screenshot
  Future<void> _secureScreen() async {
    await FlutterWindowManagerPlus.addFlags(FlutterWindowManagerPlus.FLAG_SECURE);
  }

  /// Aktifkan kiosk mode (blokir Home/Recent Apps)
  Future<void> _startKioskMode() async {
    await startKioskMode();
  }

  Future<void> _stopKioskMode() async {
    await stopKioskMode();
  }

  /// Lifecycle listener → jangan langsung keluar jika "pause" karena JS event
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!_ignoreTemporaryPause && mounted) {
          _handleViolation(showExit: true);
        }
      });
    }
  }

  /// Tangani pelanggaran
  Future<void> _handleViolation({bool showExit = true}) async {
    await _audioPlayer.play(AssetSource('assets/alarm.wav'));
    if (mounted && showExit) {
      await _stopKioskMode();
      Navigator.of(context).pop();
    }
  }

  /// Injeksi JavaScript untuk mendeteksi fullscreen / dialog / blur-focus event
  Future<void> _injectSafeJS() async {
    const js = '''
      (function() {
        if (window.ExamAppChannel) return;
        function notify(msg) { window.ExamAppChannel.postMessage(msg); }

        // Deteksi event aman dari web
        document.addEventListener('fullscreenchange', function() {
          if (document.fullscreenElement) notify('fullscreen_enter');
          else notify('fullscreen_exit');
        });

        window.addEventListener('blur', function() {
          notify('blur_event');
        });
        window.addEventListener('focus', function() {
          notify('focus_event');
        });

        const nativeAlert = window.alert;
        const nativeConfirm = window.confirm;
        const nativePrompt = window.prompt;

        window.alert = function(msg) {
          notify('js_dialog_open');
          nativeAlert(msg);
          notify('js_dialog_close');
        };
        window.confirm = function(msg) {
          notify('js_dialog_open');
          const r = nativeConfirm(msg);
          notify('js_dialog_close');
          return r;
        };
        window.prompt = function(msg, def) {
          notify('js_dialog_open');
          const r = nativePrompt(msg, def);
          notify('js_dialog_close');
          return r;
        };
      })();
    ''';

    await _controller.runJavaScript(js);

    _controller.addJavaScriptChannel(
      'ExamAppChannel',
      onMessageReceived: (msg) {
        final event = msg.message;
        if (event == 'fullscreen_enter' || event == 'js_dialog_open' || event == 'blur_event') {
          _ignoreTemporaryPause = true;
        } else if (event == 'fullscreen_exit' ||
            event == 'js_dialog_close' ||
            event == 'focus_event') {
          _ignoreTemporaryPause = false;
        }
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.dispose();
    _stopKioskMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _handleViolation(showExit: false);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Bee Exambro"),
          backgroundColor: Colors.teal,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => _controller.reload(),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () async {
                await _audioPlayer.play(AssetSource('assets/alarm.wav'));
                final keluar = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("PERINGATAN !!!!"),
                    content: const Text("Apakah Anda yakin ingin keluar ujian?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text("NO"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text("YES"),
                      ),
                    ],
                  ),
                );
                if (keluar == true && mounted) {
                  await _stopKioskMode();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(
                value: _progress / 100,
                color: Colors.blue,
                backgroundColor: Colors.grey[300],
                minHeight: 3,
              ),
            Expanded(
              child: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async => _controller.reload(),
                  child: WebViewWidget(controller: _controller),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
