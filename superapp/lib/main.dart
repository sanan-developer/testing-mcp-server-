import 'package:flutter/material.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Superwall with your API key and enable dev features
  await Superwall.configure(
    'pk_jz0WEXrnIUZLsES3fYtOs',
    // options: SuperwallOptions(), // Removed as it takes no args or defaults are used
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Superwall Demo - Branch A Version',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Superwall Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}


// Custom Delegate implementation
class MySuperwallDelegate extends SuperwallDelegate {
  final Function(SuperwallEventInfo) onEvent;

  MySuperwallDelegate({required this.onEvent});

  @override
  void handleSuperwallEvent(SuperwallEventInfo eventInfo) {
    onEvent(eventInfo);
  }

  @override
  void handleCustomPaywallAction(String name) {
    debugPrint('Custom paywall action: $name');
  }

  @override
  void willDismissPaywall(PaywallInfo paywallInfo) {
    debugPrint('Will dismiss paywall: ${paywallInfo.name}');
  }

  @override
  void willPresentPaywall(PaywallInfo paywallInfo) {
    debugPrint('Will present paywall: ${paywallInfo.name}');
  }

  @override
  void didDismissPaywall(PaywallInfo paywallInfo) {
    debugPrint('Did dismiss paywall: ${paywallInfo.name}');
  }

  @override
  void didPresentPaywall(PaywallInfo paywallInfo) {
    debugPrint('Did present paywall: ${paywallInfo.name}');
  }

  @override
  void paywallWillOpenURL(Uri url) {
    debugPrint('Paywall will open URL: $url');
  }

  @override
  void paywallWillOpenDeepLink(Uri url) {
    debugPrint('Paywall will open deep link: $url');
  }

  @override
  void handleLog(String level, String scope, String? message, Map<dynamic, dynamic>? info, String? error) {
    debugPrint('Superwall Log [$level][$scope]: $message');
  }

  @override
  void handleSuperwallDeepLink(Uri fullURL, List<String> pathComponents, Map<String, String> queryParams) {
    debugPrint('Handle Superwall deep link: $fullURL');
  }

  @override
  void subscriptionStatusDidChange(SubscriptionStatus newValue) {
    debugPrint('Subscription status changed: $newValue');
  }
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isLoading = false;
  String _subscriptionStatus = 'Unknown';
  String _lastPurchaseInfo = 'No purchases yet';
  bool _hasActiveSubscription = false;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _setupSuperwallListeners();
    _checkSubscriptionStatus();
  }

  void _setupSuperwallListeners() {
    // Listen to Superwall events
    Superwall.shared.setDelegate(
      MySuperwallDelegate(
        onEvent: (eventInfo) {
          debugPrint('Superwall Event: ${eventInfo.event}');
          
          // Handle different events
          // Note: Using toString() comparison as backup if specific enum values match differently in this version
          final eventName = eventInfo.event.toString();
          
          if (eventName.contains('transactionComplete')) {
            setState(() {
              _lastPurchaseInfo = 'Purchase completed successfully!';
              _hasActiveSubscription = true;
              _subscriptionStatus = 'Active';
            });
            _showMessage('Purchase successful!', Colors.green);
          } else if (eventName.contains('transactionFail')) {
            setState(() {
              _lastPurchaseInfo = 'Purchase failed';
            });
            _showMessage('Purchase failed', Colors.red);
          } else if (eventName.contains('transactionRestore')) {
            setState(() {
              _lastPurchaseInfo = 'Purchases restored';
              _hasActiveSubscription = true;
              _subscriptionStatus = 'Active (Restored)';
            });
            _showMessage('Purchases restored!', Colors.green);
          }
        },
      ),
    );
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      // Check if user has active subscription
      final status = await Superwall.shared.getSubscriptionStatus();
      debugPrint('Raw Subscription Status: $status');
      
      setState(() {
        _subscriptionStatus = status.toString();
        // Adjust check based on actual enum values or use string comparison safely
        _hasActiveSubscription = status.toString().toUpperCase().contains('ACTIVE'); 
      });
    } catch (e) {
      debugPrint('Error checking subscription status: $e');
      setState(() {
        _subscriptionStatus = 'Error: $e';
      });
    }
  }

  void _showMessage(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  void _showSuperwall() {
    setState(() {
      _isLoading = true;
    });

    try {
      // Register the placement with the campaign name
      Superwall.shared.registerPlacement(
        'test_campaign',
        feature: () {
          if (mounted) {
            setState(() {
              _lastPurchaseInfo = 'Access granted - User has premium!';
              _hasActiveSubscription = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Access granted! User has premium access.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    } catch (e) {
      debugPrint('Superwall error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Superwall.shared.restorePurchases();
      _showMessage('Checking for previous purchases...', Colors.blue);
    } catch (e) {
      _showMessage('Error restoring purchases: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: const Icon(
                Icons.payment,
                size: 100,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Superwall Paywall Test',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Click the button below to trigger the paywall',
                textAlign: TextAlign.left,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
            // Menu Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isMenuOpen = !_isMenuOpen;
                        });
                      },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4E157),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4E157).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isMenuOpen ? Icons.close : Icons.menu,
                                color: const Color(0xFF33691E),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isMenuOpen ? 'Close' : 'Menu',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF33691E),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            // Menu Items (shown when menu is open)
            if (_isMenuOpen) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.payment, color: Colors.deepPurple),
                        title: const Text('Show Superwall'),
                        onTap: () {
                          setState(() => _isMenuOpen = false);
                          _showSuperwall();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.restore, color: Colors.teal),
                        title: const Text('Restore Purchases'),
                        onTap: () {
                          setState(() => _isMenuOpen = false);
                          _restorePurchases();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.refresh, color: Colors.orange),
                        title: const Text('Refresh Status'),
                        onTap: () {
                          setState(() => _isMenuOpen = false);
                          _checkSubscriptionStatus();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.science, color: Colors.pink),
                        title: const Text('Test'),
                        onTap: () {
                          setState(() => _isMenuOpen = false);
                          _showMessage('Test button pressed!', Colors.pink);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Subscription Status Card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: _hasActiveSubscription ? Colors.green[50] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasActiveSubscription ? Colors.green : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasActiveSubscription ? Icons.check_circle : Icons.info_outline,
                        color: _hasActiveSubscription ? Colors.green : Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Subscription Status:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _subscriptionStatus,
                    style: TextStyle(
                      fontSize: 13,
                      color: _hasActiveSubscription ? Colors.green[800] : Colors.grey[700],
                      fontWeight: _hasActiveSubscription ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Last Purchase:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _lastPurchaseInfo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Configuration Info
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Configuration:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'API Key: pk_jz0WEXrnIUZLsES3fYtOs',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Campaign: test_campaign',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dev Features: Enabled',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
