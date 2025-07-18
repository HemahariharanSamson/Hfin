import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';

// Color System - Light Theme Design
class AppColors {
  // Professional Fintech Palette
  static const Color primary = Color(0xFF2563eb); // Blue
  static const Color primaryDark = Color(0xFF1e40af); // Darker Blue
  static const Color primaryLight = Color(0xFF60a5fa); // Lighter Blue

  static const Color accent = Color(0xFF10b981); // Teal/Green
  static const Color accentLight = Color(0xFF6ee7b7);
  static const Color accentDark = Color(0xFF047857);

  // Neutral Greys
  static const Color secondary = Color(0xFF22223b); // Dark Grey
  static const Color secondaryDark = Color(0xFF1a1a2e);
  static const Color secondaryLight = Color(0xFF6c757d); // Medium Grey

  // Backgrounds
  static const Color background = Color(0xFFf4f6fa); // Light grey
  static const Color surface = Color(0xFFffffff); // White
  static const Color surfaceLight = Color(0xFFe9ecef); // Very light grey
  static const Color cardBackground = Color(0xFFffffff); // White

  // Text
  static const Color textPrimary = Color(0xFF22223b); // Dark
  static const Color textSecondary = Color(0xFF6c757d); // Medium
  static const Color textTertiary = Color(0xFFadb5bd); // Light

  // Semantic
  static const Color success = Color(0xFF10b981); // Green
  static const Color warning = Color(0xFFfbbf24); // Amber
  static const Color error = Color(0xFFef4444); // Red
  static const Color info = Color(0xFF2563eb); // Blue

  // Category Colors (muted)
  static const Color food = Color(0xFF2563eb); // Blue
  static const Color utility = Color(0xFF10b981); // Green
  static const Color chill = Color(0xFF6366f1); // Indigo
  static const Color transport = Color(0xFF0ea5e9); // Sky blue
  static const Color shopping = Color(0xFFfbbf24); // Amber

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const LinearGradient cardGradient = LinearGradient(
    colors: [cardBackground, surfaceLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('transactions');
  await Hive.openBox('history');
  await Hive.openBox('cancelled');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hance',
      theme: _buildLightTheme(),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }



  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.textPrimary,
        onSecondary: AppColors.textPrimary,
        onSurface: AppColors.textPrimary,
        onBackground: AppColors.textPrimary,
        onError: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardBackground,
        elevation: 8,
        shadowColor: AppColors.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 8,
        shape: CircleBorder(),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.textSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late List<Map<String, dynamic>> _transactions;
  late List<Map<String, dynamic>> _history;
  late int _nextId;
  static const MethodChannel _channel = MethodChannel('sms_channel');
  late Box _transactionsBox;
  late Box _historyBox;
  late Box _cancelledBox;
  
  // Track which cards are expanded
  Set<int> _expandedCards = {};
  Set<int> _expandedDeletedCards = {};
  Set<int> _expandedCalendarCards = {};
  
  // Track which deleted transaction groups are expanded
  Set<String> _expandedDeletedGroups = {};
  
  // Loading state
  bool _isLoading = true;
  String _loadingMessage = 'Initializing...';
  
  // Scanning state
  bool _isScanning = false;
  String _scanningMessage = 'Scanning messages...';
  
  // Onboarding state
  bool _showOnboarding = false;
  
  // Check if user has completed onboarding
  bool _hasCompletedOnboarding = false;
  
  // Cancelled transactions list
  List<Map<String, dynamic>> _cancelledTransactions = [];
  
  // Calendar navigation
  DateTime _currentMonth = DateTime.now();
  DateTime? _selectedDay;

  // 1. Add a map to track selected action per transaction at the top of _MainScreenState:
  Map<int, String?> _selectedAction = {};

  // Shake animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // For analysis selection
  String _analysisType = 'Monthly'; // or 'Yearly'
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  
  // News state
  List<Map<String, String>>? _newsData;
  bool _isLoadingNews = true;
  bool _isRefreshingNews = false;
  
  // Transactions refresh state
  bool _isRefreshingTransactions = false;
  List<int> get _yearOptions {
    // Always show a range from earliest year in data to current year
    int minYear = DateTime.now().year;
    for (final tx in _history) {
      final dt = tx['timestamp'] as DateTime;
      if (dt.year < minYear) minYear = dt.year;
    }
    int maxYear = DateTime.now().year;
    return [for (int y = minYear; y <= maxYear; y++) y];
  }
  List<int> get _monthOptions => List.generate(12, (i) => i + 1);

  // Welcome message state
  bool _showWelcomeMessage = false;

  @override
  void initState() {
    super.initState();
    _selectedIndex = 1;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 16).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _initStorage();
    _loadData();
    _loadNews();
    _hasCompletedOnboarding = _transactionsBox.get('hasCompletedOnboarding', defaultValue: false);
    
    // Set welcome message for first-time users
    if (!_hasCompletedOnboarding) {
      _showWelcomeMessage = true;
    } else {
      _showWelcomeMessage = false;
    }
    
    if (_hasCompletedOnboarding) {
      // Returning user - show scanning screen directly
      setState(() {
        _isLoading = false;
        _showOnboarding = false;
        _isScanning = true;
      });
      _startScanningProcess();
    } else {
      // First-time user - show onboarding first
      setState(() {
        _isLoading = false;
        _showOnboarding = true;
        _isScanning = false;
      });
    }
  }

  Future<void> _startScanningProcess() async {
    setState(() {
      _scanningMessage = 'Scanning messages...';
    });
    
    // Add delay for scanning animation
    await Future.delayed(const Duration(milliseconds: 2000));
    
    setState(() {
      _scanningMessage = 'Processing transactions...';
    });
    
    // Initialize SMS listener and scan today's messages
    await _initSmsListener();
    
    // Add delay for processing animation
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _scanningMessage = 'Setting up your dashboard...';
    });
    
    // Final delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() {
      _isScanning = false;
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }



  void _initStorage() {
    _transactionsBox = Hive.box('transactions');
    _historyBox = Hive.box('history');
    _cancelledBox = Hive.box('cancelled');
  }
  void _loadData() {
    // Load transactions
    final savedTransactions = _transactionsBox.get('transactions', defaultValue: <Map<String, dynamic>>[]);
    final savedHistory = _historyBox.get('history', defaultValue: <Map<String, dynamic>>[]);
    final savedCancelled = _cancelledBox.get('cancelled', defaultValue: <Map<String, dynamic>>[]);
    
    setState(() {
      _transactions = _convertFromStorage(savedTransactions);
      _history = _convertFromStorage(savedHistory);
      _cancelledTransactions = _convertFromStorage(savedCancelled);

      // Sort transactions by timestamp (latest first)
      _transactions.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      _history.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      _cancelledTransactions.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
      
      // Find the highest ID to set _nextId
      int maxId = 0;
      for (final tx in [..._transactions, ..._history, ..._cancelledTransactions]) {
        if (tx['id'] is int && tx['id'] > maxId) {
          maxId = tx['id'];
        }
      }
      _nextId = maxId + 1;

      // If first-time user and transactions are found after scan, show welcome message once
      if (_showWelcomeMessage && _transactions.isNotEmpty) {
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            _showWelcomeMessage = false;
          });
        });
      }
    });
    
    // Load pending transactions from native storage
    _loadPendingTransactions();
  }

  void _loadPendingTransactions() async {
    try {
      final pendingTransactions = await _channel.invokeMethod('getPendingTransactions');
      if (pendingTransactions is List && pendingTransactions.isNotEmpty) {
        setState(() {
          for (final tx in pendingTransactions) {
            if (tx is Map) {
              final transaction = _parseTransactionFromSms(
                tx['body'] as String?,
                tx['sender'] as String?,
                tx['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(tx['timestamp'] as int) : null,
              );
              if (transaction != null) {
                _transactions.insert(0, transaction);
                _nextId++;
              }
            }
          }
        });
        // Sort transactions by timestamp (latest first)
        _transactions.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
        _saveTransactions();
        // Clear pending transactions after loading
        await _channel.invokeMethod('clearPendingTransactions');
      }
    } catch (e) {
      print('Error loading pending transactions: $e');
    }
  }

  List<Map<String, dynamic>> _convertFromStorage(List<dynamic> data) {
    return data.map((item) {
      final map = Map<String, dynamic>.from(item);
      // Convert timestamp back to DateTime
      if (map['timestamp'] is int) {
        map['timestamp'] = DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int);
      }
      return map;
    }).toList();
  }

  List<Map<String, dynamic>> _convertToStorage(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final map = Map<String, dynamic>.from(item);
      // Convert DateTime to milliseconds for storage
      if (map['timestamp'] is DateTime) {
        map['timestamp'] = (map['timestamp'] as DateTime).millisecondsSinceEpoch;
      }
      return map;
    }).toList();
  }

  void _saveTransactions() {
    _transactionsBox.put('transactions', _convertToStorage(_transactions));
  }

  void _saveHistory() {
    _historyBox.put('history', _convertToStorage(_history));
  }

  void _saveCancelledTransactions() {
    _cancelledBox.put('cancelled', _convertToStorage(_cancelledTransactions));
  }

  Future<void> _initSmsListener() async {
    try {
      // Request SMS permissions
      final bool? hasPermission = await _channel.invokeMethod('requestSmsPermissions');
      if (hasPermission == true) {
        // Scan SMS for today's transactions when app opens
        await _scanTodaySms();
      }
    } catch (e) {
      print('Error initializing SMS scanner: $e');
    }
  }

  Future<void> _scanTodaySms() async {
    try {
      // Get today's SMS and parse for transactions
      final todaySms = await _channel.invokeMethod('getTodaySms');
      if (todaySms is List && todaySms.isNotEmpty) {
        setState(() {
          for (final sms in todaySms) {
            if (sms is Map) {
              final transaction = _parseTransactionFromSms(
                sms['body'] as String?,
                sms['sender'] as String?,
                sms['timestamp'] != null ? DateTime.fromMillisecondsSinceEpoch(sms['timestamp'] as int) : null,
              );
              if (transaction != null) {
                // Create a unique identifier for this transaction based on SMS content and time
                final transactionKey = '${transaction['amount']}_${transaction['merchant']}_${(transaction['timestamp'] as DateTime).millisecondsSinceEpoch ~/ 60000}'; // Round to minute
                
                // Check if this transaction is already in history
                final isInHistory = _history.any((h) {
                  final historyKey = '${h['amount']}_${h['merchant']}_${(h['timestamp'] as DateTime).millisecondsSinceEpoch ~/ 60000}';
                  return historyKey == transactionKey;
                });
                
                // Check if this transaction is already in current transactions
                final isInCurrent = _transactions.any((t) {
                  final currentKey = '${t['amount']}_${t['merchant']}_${(t['timestamp'] as DateTime).millisecondsSinceEpoch ~/ 60000}';
                  return currentKey == transactionKey;
                });
                
                // Check if this transaction was cancelled/deleted
                final isCancelled = _cancelledTransactions.any((c) {
                  final cancelledKey = '${c['amount']}_${c['merchant']}_${(c['timestamp'] as DateTime).millisecondsSinceEpoch ~/ 60000}';
                  return cancelledKey == transactionKey;
                });
                
                if (!isInHistory && !isInCurrent && !isCancelled) {
                  _transactions.insert(0, transaction);
                  _nextId++;
                }
              }
            }
          }
        });
        // Sort transactions by timestamp (latest first)
        _transactions.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
        _saveTransactions();
      }
    } catch (e) {
      print('Error scanning today\'s SMS: $e');
    }
  }

  Map<String, dynamic>? _parseTransactionFromSms(String? body, String? sender, DateTime? timeReceived) {
    final text = body ?? '';

    // Enhanced amount extraction for various formats
    final amountRegex = RegExp(r'(?:INR|₹|Rs\.?|USD|\$)\s?(\d+(?:[.,]\d+)*)', caseSensitive: false);
    final amountMatch = amountRegex.firstMatch(text);
    if (amountMatch == null) return null;
    
    final amount = double.tryParse(amountMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) return null;

    // Determine transaction type (debit/credit)
    bool isDebited = false;
    bool isCredited = false;
    
    // Check for debit keywords (more specific patterns first)
    if (RegExp(r'\b(is paid from|paid from|debited from|debited|withdrawn|deducted|charged|purchase|payment|spent)\b', caseSensitive: false).hasMatch(text)) {
      isDebited = true;
    }
    // Check for credit keywords
    else if (RegExp(r'\b(is credited|credited|received|deposited|added|refund|cashback|reward)\b', caseSensitive: false).hasMatch(text)) {
      isCredited = true;
    }
    
    // If still unclear, look at sentence structure
    if (!isDebited && !isCredited) {
      // If amount comes before "from", it's likely a debit
      // If amount comes after "from", it's likely a credit
      final amountIndex = text.indexOf(amountMatch.group(0)!);
      final fromIndex = text.toLowerCase().indexOf(' from ');
      
      if (fromIndex > 0) {
        if (amountIndex < fromIndex) {
          isDebited = true; // "INR 40.00 is paid from account" = debit
        } else {
          isCredited = true; // "credited for INR 2.00 from sender" = credit
        }
      } else {
        isDebited = true; // Default to debit if unclear
      }
    }

    // Extract account information
    String fromAccount = 'Unknown';
    String toAccount = 'Unknown';
    String merchant = 'Unknown';

    if (isDebited) {
      // For debits: extract account and recipient
      
      // Extract account pattern: "from BANK account XXNUMBER" or "from BANK Acc XXNUMBER"
      final accountPattern = RegExp(r'from\s+([A-Z]+)\s+(?:account|Acc)\s+([A-Z0-9]+)', caseSensitive: false);
      final accountMatch = accountPattern.firstMatch(text);
      
      if (accountMatch != null) {
        final bankName = accountMatch.group(1)!;
        final accountNum = accountMatch.group(2)!;
        fromAccount = '$bankName Account $accountNum';
      }

      // Extract recipient/merchant
      // Pattern 1: "to MERCHANT NAME on date"
      final recipientPattern1 = RegExp(r'to\s+([^0-9]+?)\s+on\s+\d', caseSensitive: false);
      final recipientMatch1 = recipientPattern1.firstMatch(text);
      
      if (recipientMatch1 != null) {
        merchant = recipientMatch1.group(1)!.trim();
      } else {
        // Pattern 2: "to MERCHANT" (at end or before "with ref")
        final recipientPattern2 = RegExp(r'to\s+([^0-9]+?)(?:\s+with\s+ref|\s* $)', caseSensitive: false);
        final recipientMatch2 = recipientPattern2.firstMatch(text);
        
        if (recipientMatch2 != null) {
          merchant = recipientMatch2.group(1)!.trim();
        }
      }
      
      toAccount = merchant;

    } else if (isCredited) {
      // For credits: extract account and sender
      
      // Extract account pattern
      final accountPattern = RegExp(r'(?:Your\s+)?([A-Z]+)\s+(?:account|Acc)\s+([A-Z0-9]+)', caseSensitive: false);
      final accountMatch = accountPattern.firstMatch(text);
      
      if (accountMatch != null) {
        final bankName = accountMatch.group(1)!;
        final accountNum = accountMatch.group(2)!;
        toAccount = '$bankName Account $accountNum';
      }

      // Extract sender
      // Pattern 1: "from sendername@bank"
      final senderPattern1 = RegExp(r'from\s+([^\.\s]+@[^\.\s]+)', caseSensitive: false);
      final senderMatch1 = senderPattern1.firstMatch(text);
      
      if (senderMatch1 != null) {
        merchant = senderMatch1.group(1)!.trim();
        // Clean up UPI ID for display
        merchant = merchant.replaceAll(RegExp(r'@[a-z]+ $'), ''); // Remove @bank suffix
      } else {
        // Pattern 2: "from SENDER NAME"
        final senderPattern2 = RegExp(r'from\s+([^0-9]+?)(?:\s+on|\s+with|\.|$)', caseSensitive: false);
        final senderMatch2 = senderPattern2.firstMatch(text);
        
        if (senderMatch2 != null) {
          merchant = senderMatch2.group(1)!.trim();
      }
    }

      fromAccount = merchant;
    }

    // Clean up merchant/sender names
    if (merchant != 'Unknown') {
      // Remove common UPI suffixes and clean up
      merchant = merchant.replaceAll(RegExp(r'@[a-z]+$'), '');
      merchant = merchant.replaceAll(RegExp(r'\s+'), ' ').trim();
      
      // Handle special cases
      if (merchant.toLowerCase().contains('mr ') || merchant.toLowerCase().contains('ms ')) {
        // Keep as is for person names
      } else {
        // Convert to title case for business names
        merchant = _toTitleCase(merchant);
      }
    }

    // Fallback values
    if (fromAccount == 'Unknown') {
      fromAccount = sender ?? 'Unknown Bank';
    }
    if (toAccount == 'Unknown') {
      toAccount = merchant;
    }

    return {
      'id': _nextId,
      'amount': amount,
      'merchant': merchant,
      'fromAccount': fromAccount,
      'toAccount': toAccount,
      'timestamp': timeReceived ?? DateTime.now(),
      'tag': null,
      'isDebited': isDebited,
    };
  }

  // Helper function to convert text to title case
  String _toTitleCase(String text) {
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _tagTransaction(int id, String tag) {
    setState(() {
      final tx = _transactions.firstWhere((t) => t['id'] == id);
      tx['tag'] = tag;
      _history.insert(0, Map<String, dynamic>.from(tx));
      _transactions.removeWhere((t) => t['id'] == id);
      // Hide welcome message if all transactions are categorized
      if (_showWelcomeMessage && _transactions.isEmpty) {
        _showWelcomeMessage = false;
      }
    });
    _saveTransactions();
    _saveHistory();
  }

  void _cancelTransaction(int id) async {
    setState(() {
      final cancelledTx = _transactions.firstWhere((t) => t['id'] == id);
      _cancelledTransactions.insert(0, Map<String, dynamic>.from(cancelledTx));
      _transactions.removeWhere((t) => t['id'] == id);
      // Hide welcome message if all transactions are categorized/cancelled
      if (_showWelcomeMessage && _transactions.isEmpty) {
        _showWelcomeMessage = false;
      }
    });
    _saveTransactions();
    _saveCancelledTransactions();
  }

  Widget _transactionCard(Map<String, dynamic> tx) {
    final isExpanded = _expandedCards.contains(tx['id']);
    final isDebited = tx['isDebited'] == true;
    final isCredited = !isDebited;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDebited 
              ? AppColors.error.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCards.remove(tx['id']);
              } else {
                _expandedCards.add(tx['id']);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '₹ ${tx['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDebited ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDebited 
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isDebited ? 'DEBITED' : 'CREDITED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDebited ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _buildTransactionDetail(
                          tx['fromAccount'] ?? 'Unknown',
                          tx['toAccount'] ?? 'Unknown',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow('Date:', _formatDate(tx['timestamp']), Icons.calendar_today),
                        const SizedBox(height: 12),
                        _buildDetailRow('Time:', _formatTime(tx['timestamp']), Icons.access_time),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(child: _buildActionButton(
                      emoji: '🍔',
                      label: 'Food',
                      tooltip: 'Tag as Food',
                      selected: false,
                      onPressed: () => _tagTransaction(tx['id'], 'Food'),
                    )),
                    Expanded(child: _buildActionButton(
                      emoji: '⚡',
                      label: 'Utility',
                      tooltip: 'Tag as Utility',
                      selected: false,
                      onPressed: () => _tagTransaction(tx['id'], 'Utility'),
                    )),
                    Expanded(child: _buildActionButton(
                      emoji: '😎',
                      label: 'Chill',
                      tooltip: 'Tag as Chill',
                      selected: false,
                      onPressed: () => _tagTransaction(tx['id'], 'Chill'),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _modernTransactionCard(Map<String, dynamic> tx, {bool showActions = true}) {
    final isDebited = tx['isDebited'] == true;
    final isCredited = !isDebited;
    final tag = tx['tag'] as String?;
    final selected = _selectedAction[tx['id']];
    // Define credited categories
    final creditedCategories = [
      {
        'icon': FontAwesomeIcons.moneyCheckDollar,
        'color': Color(0xFF2563eb), // Blue
        'label': 'Salary',
      },
      {
        'icon': FontAwesomeIcons.laptopCode,
        'color': Color(0xFF10b981), // Green
        'label': 'Freelance',
      },
      {
        'icon': FontAwesomeIcons.rightLeft,
        'color': Color(0xFF6366f1), // Indigo
        'label': 'Transfer',
      },
    ];
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],

      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isDebited ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isDebited ? AppColors.error : AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹ ${tx['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16, // Reduced from 22
                          fontWeight: FontWeight.w600, // Slightly less bold
                          color: isDebited ? AppColors.error : AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx['merchant'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Add credited/debited tag
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDebited
                        ? AppColors.error.withOpacity(0.13)
                        : AppColors.success.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isDebited ? 'DEBITED' : 'CREDITED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDebited ? AppColors.error : AppColors.success,
                    ),
                  ),
                ),
                if (tag != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTagColor(tag).withOpacity(0.13),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _getTagColor(tag),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _buildTransactionInfoGrid(tx),
            const SizedBox(height: 10),
            if (showActions) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (isDebited) ...[
                    _buildCategoryActionButton(
                      icon: FontAwesomeIcons.utensils,
                      color: AppColors.food,
                      label: 'Food',
                      selected: selected == 'Food',
                      onPressed: () {
                        setState(() {
                          _selectedAction[tx['id']] = 'Food';
                        });
                      },
                    ),
                    _buildCategoryActionButton(
                      icon: FontAwesomeIcons.bolt,
                      color: AppColors.utility,
                      label: 'Utility',
                      selected: selected == 'Utility',
                      onPressed: () {
                        setState(() {
                          _selectedAction[tx['id']] = 'Utility';
                        });
                      },
                    ),
                    _buildCategoryActionButton(
                      icon: FontAwesomeIcons.spa,
                      color: AppColors.chill,
                      label: 'Chill',
                      selected: selected == 'Chill',
                      onPressed: () {
                        setState(() {
                          _selectedAction[tx['id']] = 'Chill';
                        });
                      },
                    ),
                  ] else ...[
                    // Credited transaction: show Salary, Freelance, Transfer
                    for (final cat in creditedCategories)
                      _buildCategoryActionButton(
                        icon: cat['icon'] as IconData,
                        color: cat['color'] as Color,
                        label: cat['label'] as String,
                        selected: selected == cat['label'],
                        onPressed: () {
                          setState(() {
                            _selectedAction[tx['id']] = cat['label'] as String;
                          });
                        },
                      ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onPressed,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
                border: selected ? Border.all(color: color, width: 2) : null,
              ),
              padding: const EdgeInsets.all(8), // Reduced padding
              child: FaIcon(
                icon,
                color: color,
                size: 24, // Slightly smaller for better fit
              ),
            ),
            const SizedBox(height: 2), // Less space below icon
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : (label == 'Delete' ? AppColors.error : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionDetail(String fromAccount, String toAccount) {
    return Row(
      children: [
        Icon(
          Icons.swap_horiz,
          color: AppColors.textPrimary,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$fromAccount → $toAccount',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textPrimary,
          size: 16,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String emoji,
    required String label,
    required String tooltip,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: selected ? Colors.yellow[100] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: Colors.orange, width: 2) : null,
        boxShadow: selected
            ? [BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 8)]
            : [],
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedScale(
          scale: selected ? 1.18 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 2),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.orange[900] : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        // History with calendar view
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            setState(() {});
          },
          child: _buildCalendarView(),
        );
      case 1:
        // Home: show transaction cards
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _isRefreshingTransactions = true;
            });
            
            // Start both operations concurrently
            final scanFuture = _scanTodaySms();
            final newsFuture = _loadNews(isRefreshing: true);
            
            // Wait for both to complete
            await Future.wait([scanFuture, newsFuture]);
            
            // Ensure minimum animation duration for better UX
            await Future.delayed(const Duration(milliseconds: 800));
            
            setState(() {
              _isRefreshingTransactions = false;
            });
          },
          child: SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // Transactions section
                Expanded(
                  child: _transactions.isEmpty
                      ? SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: _showWelcomeMessage
                                  ? _buildWelcomeMessage()
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: AppColors.surface,
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.04),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                            border: Border.all(
                                              color: AppColors.surfaceLight,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.celebration,
                                                size: 64,
                                                color: AppColors.success,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Congratulations!',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'You have tracked all your expenses!',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: AppColors.textSecondary,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Stay financially responsible!',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.success,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Pull down to refresh and check for new transactions',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textTertiary,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        )
                      : ListView(
              padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 2),
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                            _isRefreshingTransactions
                                ? Container(
                                    height: 320,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Refreshing transactions...',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    height: 320,
                  child: AnimatedBuilder(
                    animation: _shakeController,
                    builder: (context, child) {
                      final offset = _shakeController.isAnimating ? _shakeAnimation.value * (1 - 2 * (_shakeController.value % 0.5).floor()) : 0.0;
                      return Transform.translate(
                        offset: Offset(offset, 0),
                        child: CardSwiper(
                          key: ValueKey(_transactions.length),
                          cardsCount: _transactions.length,
                          numberOfCardsDisplayed: _transactions.length.clamp(1, 2),
                          isLoop: false,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                                            // backCardOffset: const Offset(0, -15),
                                            scale: 0.80, // Add this - makes back card slightly smaller
                                            threshold: 50, // Add this - reduces swipe sensitivity for tighter feel
                          allowedSwipeDirection: const AllowedSwipeDirection.only(
                            left: true,
                            right: true,
                            up: false,
                            down: false,
                          ),
                          cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                            final tx = _transactions[index];
                            return _modernTransactionCard(tx);
                          },
                          onSwipe: (index, direction, CardSwiperDirection? swipeDirection) async {
                            if (index >= _transactions.length) {
                              return false;
                            }
                            final tx = _transactions[index];
                            final selected = _selectedAction[tx['id']];
                            if (swipeDirection == CardSwiperDirection.left) {
                              if (selected == null || selected == 'Delete') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select a category before swiping left!')),
                                );
                                _shakeController.forward(from: 0);
                                return false;
                              } else {
                                _tagTransaction(tx['id'], selected);
                                setState(() {
                                  _selectedAction[tx['id']] = null;
                                });
                                return true;
                              }
                            } else if (swipeDirection == CardSwiperDirection.right) {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: Text('Are you sure you want to delete this transaction for ₹${tx['amount'].toStringAsFixed(2)}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: const Text('Yes'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                _cancelTransaction(tx['id']);
                                setState(() {
                                  _selectedAction[tx['id']] = null;
                                });
                                                  return true;
                              } else {
                                _shakeController.forward(from: 0);
                                                  return false;
                              }
                            }
                            return true;
                          },
                        ),
                      );
                    },
                  ),
                ),
                          ],
                        ),
                ),
                // News Container (always visible)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.surfaceLight,
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.newspaper, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Finance News',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                ),
                const SizedBox(height: 8),
                          _isLoadingNews || _isRefreshingNews
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      _isRefreshingNews ? 'Refreshing news...' : 'Fetching latest news...', 
                                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)
                                    ),
                                  ],
                                )
                              : _newsData == null || _newsData!.isEmpty
                                  ? Text('No news available.', style: TextStyle(fontSize: 13, color: AppColors.textTertiary))
                                  : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                      children: _newsData!.take(4).map((news) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Icon(Icons.circle, size: 7, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: InkWell(
                                          onTap: () async {
                                            final url = news['url']!;
                                            try {
                                              await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Could not open the link.')),
                                              );
                                            }
                                          },
                                          child: Text(
                                            news['title']!,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                              height: 1.3,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      case 2:
        // Cancelled transactions
        if (_cancelledTransactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline,
                  size: 64,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  'No cancelled transactions.',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            _loadData();
            setState(() {});
          },
          child: SafeArea(
            top: false,
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 2),
                  child: Text(
                    'Deleted Transactions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ..._buildGroupedDeletedTransactions(),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSplashScreen() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern illustration
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  height: 180,
                  child: Image.asset(
                    'assets/icon/sms_scan.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // App Title (modern, bold, spaced)
              Text(
                'Hance',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: AppColors.primary,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 32),
              // Linear progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: LinearProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: AppColors.primary.withOpacity(0.13),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),
              // Loading message
              Text(
                _loadingMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 18),
              // Tagline/tip
              Text(
                'Your SMS transactions are safe and private.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome to Hance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Personal Finance Tracker',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Features
              Column(
                children: [
                  _buildFeatureItem(
                    icon: Icons.sms,
                    title: 'SMS Transaction Scanning',
                    description: 'Automatically detects and categorizes your bank transactions from SMS messages',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.analytics,
                    title: 'Smart Analytics',
                    description: 'Get insights into your spending patterns with detailed charts and reports',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.security,
                    title: 'Privacy First',
                    description: 'All data stays on your device. We never access your personal information',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.history,
                    title: 'Transaction History',
                    description: 'View and manage your past transactions with detailed calendar view',
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    icon: Icons.trending_up,
                    title: 'Financial Insights',
                    description: 'Track your spending habits and get personalized financial recommendations',
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    _transactionsBox.put('hasCompletedOnboarding', true);
                    setState(() {
                      _showOnboarding = false;
                      _hasCompletedOnboarding = true;
                      _isScanning = true;
                    });
                    _startScanningProcess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanningScreen() {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modern illustration
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: SizedBox(
                  height: 180,
                  child: Image.asset(
                    'assets/icon/sms_scan.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // App Title
              Text(
                'Hance',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  color: AppColors.primary,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 32),
              // Linear progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48.0),
                child: LinearProgressIndicator(
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  backgroundColor: AppColors.primary.withOpacity(0.13),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),
              // Scanning message
              Text(
                _scanningMessage,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 18),
              // Tagline/tip
              Text(
                'Your SMS transactions are safe and private.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: (_isLoading || _showOnboarding || _isScanning || _selectedIndex == 0 || _selectedIndex == 2)
          ? null
          : AppBar(
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/icon/icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              title: Transform.translate(
                offset: Offset(-20, 0), // Move text 20 pixels to the left
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hance',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.textPrimary,
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
              ),
              centerTitle: false,
              elevation: 0,
              backgroundColor: AppColors.surface,
              actions: _selectedIndex == 1
                  ? [
                      IconButton(
                        icon: Icon(Icons.support_agent, color: AppColors.primary),
                        tooltip: 'Contact Dev',
                        onPressed: () => _showContactDevDialog(context),
                      ),
                    ]
                  : null,
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: _isLoading 
            ? _buildSplashScreen() 
            : _showOnboarding 
                ? _buildOnboardingScreen() 
                : _isScanning
                    ? _buildScanningScreen()
                    : _getBody(),
      ),
      bottomNavigationBar: (_isLoading || _showOnboarding || _isScanning) ? null : BottomAppBar(
        height: 70, // Increased from 60 to 70
        padding: EdgeInsets.zero,
        color: AppColors.surface,
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Increased vertical padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                label: 'History',
                index: 0,
                isSelected: _selectedIndex == 0,
              ),
              _buildNavItem(
                icon: Icons.receipt_long_outlined,
                label: 'Home',
                index: 1,
                isSelected: _selectedIndex == 1,
              ),
              _buildNavItem(
                icon: Icons.delete_outline,
                label: 'Deleted',
                index: 2,
                isSelected: _selectedIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    final selectedColor = AppColors.primary;
    final unselectedColor = AppColors.textTertiary;
    
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6), // Reduced from 7 to 6
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: selectedColor, width: 1.5)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 22, // Reduced from 24 to 22
              ),
              const SizedBox(height: 3), // Increased from 2 to 3 for better spacing
              Text(
                label,
                style: TextStyle(
                  fontSize: 10, // Reduced from 11 to 10
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? selectedColor : unselectedColor,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Calendar helper methods
  List<Map<String, dynamic>> _getTransactionsForMonth(DateTime month) {
    return _history.where((tx) {
      final txDate = tx['timestamp'] as DateTime;
      return txDate.year == month.year && txDate.month == month.month;
    }).toList();
  }

  List<Map<String, dynamic>> _getTransactionsForDay(DateTime day) {
    return _history.where((tx) {
      final txDate = tx['timestamp'] as DateTime;
      return txDate.year == day.year && 
             txDate.month == day.month && 
             txDate.day == day.day;
    }).toList();
  }

  double _getTotalExpenseForMonth(DateTime month) {
    final monthTransactions = _getTransactionsForMonth(month);
    return monthTransactions
        .where((tx) => tx['isDebited'] == true)
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
  }

  double _getTotalIncomeForMonth(DateTime month) {
    final monthTransactions = _getTransactionsForMonth(month);
    return monthTransactions
        .where((tx) => tx['isDebited'] == false)
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
  }

  double _getTotalExpenseForDay(DateTime day) {
    final dayTransactions = _getTransactionsForDay(day);
    return dayTransactions
        .where((tx) => tx['isDebited'] == true)
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
  }

  double _getTotalIncomeForDay(DateTime day) {
    final dayTransactions = _getTransactionsForDay(day);
    return dayTransactions
        .where((tx) => tx['isDebited'] == false)
        .fold(0.0, (sum, tx) => sum + (tx['amount'] as double));
  }

  Map<int, double> _getDailyTotalsForMonth(DateTime month) {
    final monthTransactions = _getTransactionsForMonth(month);
    final dailyTotals = <int, double>{};
    
    for (final tx in monthTransactions) {
      final day = (tx['timestamp'] as DateTime).day;
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + (tx['amount'] as double);
    }
    
    return dailyTotals;
  }

  Widget _buildCalendarView() {
    final monthTransactions = _getTransactionsForMonth(_currentMonth);
    final dailyTotals = _getDailyTotalsForMonth(_currentMonth);
    final monthExpense = _getTotalExpenseForMonth(_currentMonth);
    final monthIncome = _getTotalIncomeForMonth(_currentMonth);
    final isDark = false; // Always false since we removed dark mode
    
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Month navigation header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavigationButton(
                  icon: Icons.chevron_left,
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
                      _selectedDay = null;
                    });
                  },
                ),
                Column(
                  children: [
                    Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, color: AppColors.error, size: 15),
                        const SizedBox(width: 2),
                        Text(
                          'Expense: ₹${monthExpense.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.arrow_downward, color: AppColors.success, size: 15),
                        const SizedBox(width: 2),
                        Text(
                          'Income: ₹${monthIncome.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                _buildNavigationButton(
                  icon: Icons.chevron_right,
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                      _selectedDay = null;
                    });
                  },
                ),
              ],
            ),
          ),
          // Calendar grid
          Expanded(
            child: _selectedDay == null ? _buildMonthCalendar(dailyTotals) : _buildDayDetails(_selectedDay!),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppColors.primary, size: 20),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          padding: const EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthCalendar(Map<int, double> dailyTotals) {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Weekday headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((day) => Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          // Calendar days
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 42, // 6 weeks * 7 days
            itemBuilder: (context, index) {
              final dayOffset = index - (firstWeekday - 1);
              final day = dayOffset + 1;
              if (day < 1 || day > daysInMonth) {
                return Container(); // Empty space
              }
              final dayTotal = dailyTotals[day] ?? 0.0;
              final isToday = day == DateTime.now().day && 
                             _currentMonth.month == DateTime.now().month && 
                             _currentMonth.year == DateTime.now().year;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDay = DateTime(_currentMonth.year, _currentMonth.month, day);
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  decoration: BoxDecoration(
                    color: dayTotal > 0 
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceLight.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday 
                        ? Border.all(color: AppColors.primary, width: 2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day.toString(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isToday 
                              ? AppColors.primary 
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (dayTotal > 0) ...[
                        const SizedBox(height: 1),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '₹${dayTotal.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          // Analysis selection container
          if (_selectedDay == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.surfaceLight,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.analytics, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('Analysis Options', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // First row: chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ChoiceChip(
                                label: const Text('Yearly'),
                                selected: _analysisType == 'Yearly',
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _analysisType == 'Yearly' ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _analysisType = 'Yearly';
                                  });
                                },
                              ),
                              ChoiceChip(
                                label: const Text('Monthly'),
                                selected: _analysisType == 'Monthly',
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: _analysisType == 'Monthly' ? Colors.white : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    _analysisType = 'Monthly';
                                  });
                                },
                              ),
                            ],
                          ),
                          // Second row: dropdowns
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text('Year:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                              DropdownButton<int>(
                                value: _selectedYear,
                                items: _yearOptions.map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year.toString()),
                                )).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedYear = val!;
                                  });
                                },
                                style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                dropdownColor: AppColors.surface,
                              ),
                              if (_analysisType == 'Monthly') ...[
                                Text('Month:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                DropdownButton<int>(
                                  value: _selectedMonth,
                                  items: _monthOptions.map((month) => DropdownMenuItem(
                                    value: month,
                                    child: Text(month.toString().padLeft(2, '0')),
                                  )).toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      _selectedMonth = val!;
                                    });
                                  },
                                  style: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                                  dropdownColor: AppColors.surface, // light only
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Expenditure Analysis Chart (only show if no day is selected)
          if (_selectedDay == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.surfaceLight,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Expenditure Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _buildExpenditurePieChart(
                          analysisType: _analysisType,
                          year: _selectedYear,
                          month: _selectedMonth,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Income Analysis Chart (only show if no day is selected)
          if (_selectedDay == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: AppColors.surfaceLight,
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.pie_chart, color: AppColors.success, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Income Analysis',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: _buildIncomePieChart(
                          analysisType: _analysisType,
                          year: _selectedYear,
                          month: _selectedMonth,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper to build the pie chart for expenditure analysis
  Widget _buildExpenditurePieChart({required String analysisType, required int year, required int month}) {
    List<Map<String, dynamic>> txs;
    if (analysisType == 'Yearly') {
      txs = _history.where((tx) {
        final txDate = tx['timestamp'] as DateTime;
        return txDate.year == year && tx['isDebited'] == true;
      }).toList();
    } else {
      txs = _history.where((tx) {
        final txDate = tx['timestamp'] as DateTime;
        return txDate.year == year && txDate.month == month && tx['isDebited'] == true;
      }).toList();
    }
    // Group by tag/category
    final Map<String, double> categoryTotals = {};
    for (final tx in txs) {
      final tag = tx['tag'] ?? 'Other';
      categoryTotals[tag] = (categoryTotals[tag] ?? 0) + (tx['amount'] as double);
    }
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    if (categoryTotals.isEmpty || total == 0) {
      return Center(
        child: Text(
          'No expenditure data for this period.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    final List<PieChartSectionData> sections = [];
    final colors = [
      AppColors.food,
      AppColors.utility,
      AppColors.chill,
      AppColors.transport,
      AppColors.shopping,
      AppColors.accent,
      AppColors.primaryLight,
      AppColors.secondaryLight,
    ];
    int colorIdx = 0;
    categoryTotals.forEach((category, value) {
      final percent = value / total * 100;
      sections.add(PieChartSectionData(
        color: colors[colorIdx % colors.length],
        value: value,
        title: '${category}\n${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white),
        titlePositionPercentageOffset: 0.6,
      ));
      colorIdx++;
    });
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 32,
        sectionsSpace: 2,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  // Helper to build the pie chart for income analysis (credited)
  Widget _buildIncomePieChart({required String analysisType, required int year, required int month}) {
    List<Map<String, dynamic>> txs;
    if (analysisType == 'Yearly') {
      txs = _history.where((tx) {
        final txDate = tx['timestamp'] as DateTime;
        return txDate.year == year && tx['isDebited'] == false;
      }).toList();
    } else {
      txs = _history.where((tx) {
        final txDate = tx['timestamp'] as DateTime;
        return txDate.year == year && txDate.month == month && tx['isDebited'] == false;
      }).toList();
    }
    // Group by tag/category
    final Map<String, double> categoryTotals = {};
    for (final tx in txs) {
      final tag = tx['tag'] ?? 'Other';
      categoryTotals[tag] = (categoryTotals[tag] ?? 0) + (tx['amount'] as double);
    }
    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);
    if (categoryTotals.isEmpty || total == 0) {
      return Center(
        child: Text(
          'No income data for this period.',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );
    }
    final List<PieChartSectionData> sections = [];
    final colors = [
      Color(0xFF2563eb), // Salary
      Color(0xFF10b981), // Freelance
      Color(0xFF6366f1), // Transfer
      AppColors.accent,
      AppColors.primaryLight,
      AppColors.secondaryLight,
    ];
    int colorIdx = 0;
    categoryTotals.forEach((category, value) {
      final percent = value / total * 100;
      sections.add(PieChartSectionData(
        color: colors[colorIdx % colors.length],
        value: value,
        title: '${category}\n${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.white),
        titlePositionPercentageOffset: 0.6,
      ));
      colorIdx++;
    });
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 32,
        sectionsSpace: 2,
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildDayDetails(DateTime day) {
    final dayTransactions = _getTransactionsForDay(day);
    final dayExpense = _getTotalExpenseForDay(day);
    final dayIncome = _getTotalIncomeForDay(day);
    
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.surfaceLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _buildNavigationButton(
                  icon: Icons.arrow_back,
                  onPressed: () {
                    setState(() {
                      _selectedDay = null;
                    });
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_getMonthName(day.month)} ${day.day}, ${day.year}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.arrow_upward, color: AppColors.error, size: 15),
                        const SizedBox(width: 2),
                        Text(
                          'Expense: ₹${dayExpense.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.arrow_downward, color: AppColors.success, size: 15),
                        const SizedBox(width: 2),
                        Text(
                          'Income: ₹${dayIncome.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Day transactions
          Expanded(
            child: SafeArea(
              top: false,
              bottom: true,
              child: dayTransactions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions for this day',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                          child: Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        ...dayTransactions.map((tx) => Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.07),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      tx['isDebited'] == true ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                      color: tx['isDebited'] == true ? AppColors.error : AppColors.success,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '₹ ${tx['amount'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: tx['isDebited'] == true ? AppColors.error : AppColors.success,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            tx['merchant'] ?? 'Unknown',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Right side: restore and tags at the top
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _restoreTransactionFromHistory(tx['id']),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                                                alignment: Alignment.center,
                                                child: Icon(Icons.restore, color: AppColors.primary, size: 20),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: (tx['isDebited'] == true
                                                        ? AppColors.error.withOpacity(0.13)
                                                        : AppColors.success.withOpacity(0.13)),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tx['isDebited'] == true ? 'DEBITED' : 'CREDITED',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: tx['isDebited'] == true ? AppColors.error : AppColors.success,
                                                ),
                                              ),
                                            ),
                                            if (tx['tag'] != null) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: _getTagColor(tx['tag']).withOpacity(0.13),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  tx['tag'],
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: _getTagColor(tx['tag']),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _buildTransactionInfoGrid(tx),
                              ],
                            ),
                          ),
                        )).toList(),
                        const SizedBox(height: 8),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTagColor(String? tag) {
    switch (tag) {
      case 'Food':
        return AppColors.food;
      case 'Utility':
        return AppColors.utility;
      case 'Chill':
        return AppColors.chill;
      case 'Salary':
        return Color(0xFF2563eb); // Blue
      case 'Freelance':
        return Color(0xFF10b981); // Green
      case 'Transfer':
        return Color(0xFF6366f1); // Indigo
      default:
        return AppColors.textTertiary;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Group deleted transactions by month and day
  Map<String, Map<String, List<Map<String, dynamic>>>> _getGroupedDeletedTransactions() {
    final grouped = <String, Map<String, List<Map<String, dynamic>>>>{};
    
    for (final tx in _cancelledTransactions) {
      final date = tx['timestamp'] as DateTime;
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      
      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = {};
      }
      if (!grouped[monthKey]!.containsKey(dayKey)) {
        grouped[monthKey]![dayKey] = [];
      }
      grouped[monthKey]![dayKey]!.add(tx);
    }
    
    return grouped;
  }

  String _getMonthDisplayName(String monthKey) {
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    return '${_getMonthName(month)} $year';
  }

  String _getDayDisplayName(String dayKey) {
    final parts = dayKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    final date = DateTime(year, month, day);
    
    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return '${_getMonthName(month)} ${day}, $year';
    }
  }

  List<Widget> _buildGroupedDeletedTransactions() {
    final grouped = _getGroupedDeletedTransactions();
    final widgets = <Widget>[];
    
    // Sort months in descending order (newest first)
    final sortedMonths = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    for (final monthKey in sortedMonths) {
      final monthData = grouped[monthKey]!;
      final isMonthExpanded = _expandedDeletedGroups.contains(monthKey);
      
      // Calculate total for the month
      double monthTotal = 0;
      for (final dayTransactions in monthData.values) {
        for (final tx in dayTransactions) {
          monthTotal += tx['amount'] as double;
        }
      }
      
      // Month header
      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppColors.surfaceLight,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  if (isMonthExpanded) {
                    _expandedDeletedGroups.remove(monthKey);
                  } else {
                    _expandedDeletedGroups.add(monthKey);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isMonthExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getMonthDisplayName(monthKey),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${monthData.length} days • ₹${monthTotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      
      // Day groups (only if month is expanded)
      if (isMonthExpanded) {
        // Sort days in descending order (newest first)
        final sortedDays = monthData.keys.toList()..sort((a, b) => b.compareTo(a));
        
        for (final dayKey in sortedDays) {
          final dayTransactions = monthData[dayKey]!;
          final isDayExpanded = _expandedDeletedGroups.contains(dayKey);
          
          // Calculate total for the day
          double dayTotal = 0;
          for (final tx in dayTransactions) {
            dayTotal += tx['amount'] as double;
          }
          
          // Day header
          widgets.add(
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.surfaceLight,
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      if (isDayExpanded) {
                        _expandedDeletedGroups.remove(dayKey);
                      } else {
                        _expandedDeletedGroups.add(dayKey);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          isDayExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getDayDisplayName(dayKey),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${dayTransactions.length} transactions • ₹${dayTotal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          
          // Individual transactions (only if day is expanded)
          if (isDayExpanded) {
            for (final tx in dayTransactions) {
              widgets.add(_deletedTransactionCard(tx));
            }
          }
        }
      }
    }
    
    return widgets;
  }

  Widget _deletedTransactionCard(Map<String, dynamic> tx) {
    final isDebited = tx['isDebited'] == true;
    final tag = tx['tag'] as String?;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹ ${tx['amount'].toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tx['merchant'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right side: restore and tags at the top (match calendar card)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              final restoredTx = Map<String, dynamic>.from(tx);
                              restoredTx['tag'] = null;
                              _transactions.insert(0, restoredTx);
                              _cancelledTransactions.removeWhere((t) => t['id'] == tx['id']);
                              _saveTransactions();
                              _saveCancelledTransactions();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Transaction restored to pending!')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                            alignment: Alignment.center,
                            child: Icon(Icons.restore, color: AppColors.primary, size: 20),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: (isDebited
                                    ? AppColors.error.withOpacity(0.13)
                                    : AppColors.success.withOpacity(0.13)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDebited ? 'DEBITED' : 'CREDITED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDebited ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ),
                        if (tag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getTagColor(tag).withOpacity(0.13),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _getTagColor(tag),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 16, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'From: ${tx['fromAccount'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    'To: ${tx['toAccount'] ?? 'Unknown'}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Text(
                  _formatDate(tx['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.access_time_outlined, size: 15, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Text(
                  _formatTime(tx['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionInfoGrid(Map<String, dynamic> tx) {
    final borderColor = AppColors.surfaceLight;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.1),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1),
          1: FlexColumnWidth(1),
        },
        children: [
          TableRow(
            children: [
              _buildInfoCell(
                icon: Icons.account_balance_wallet_outlined,
                label: 'From',
                value: tx['fromAccount'] ?? 'Unknown',
              ),
              _buildInfoCell(
                icon: Icons.arrow_forward_ios_rounded,
                label: 'To',
                value: tx['toAccount'] ?? 'Unknown',
              ),
            ],
          ),
          TableRow(
            children: [
              _buildInfoCell(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: _formatDate(tx['timestamp']),
              ),
              _buildInfoCell(
                icon: Icons.access_time_outlined,
                label: 'Time',
                value: _formatTime(tx['timestamp']),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCell({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textSecondary),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Load news data
  Future<void> _loadNews({bool isRefreshing = false}) async {
    if (isRefreshing) {
      setState(() {
        _isRefreshingNews = true;
      });
    }
    
    try {
      final news = await _fetchFinanceNews();
      setState(() {
        _newsData = news;
        _isLoadingNews = false;
        _isRefreshingNews = false;
      });
    } catch (e) {
      setState(() {
        _newsData = [];
        _isLoadingNews = false;
        _isRefreshingNews = false;
      });
    }
  }

  // Add a method to fetch finance news from NewsAPI
  Future<List<Map<String, String>>> _fetchFinanceNews() async {
    const apiKey ='fbeb1c8586a1467da9845db403eee72c'; // <-- Replace with your NewsAPI.org API key
    
    // Keywords for finance-related news
    final financeKeywords = [
      'finance', 'financial', 'banking', 'investment', 'stock', 'market', 'trading',
      'economy', 'economic', 'GDP', 'inflation', 'interest rate', 'central bank',
      'cryptocurrency', 'bitcoin', 'crypto', 'blockchain', 'mutual fund', 'ETF',
      'bond', 'forex', 'currency', 'bank', 'credit', 'loan', 'mortgage',
      'insurance', 'tax', 'budget', 'revenue', 'profit', 'earnings', 'quarterly',
      'IPO', 'merger', 'acquisition', 'startup', 'venture capital', 'funding'
    ];
    
    final url = Uri.parse('https://newsapi.org/v2/top-headlines?category=business&language=en&apiKey=$apiKey');
    try {
      final response = await http.get(url);
      print('NewsAPI response: ' + response.body); // Debug print
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'ok' && data['articles'] != null) {
          final List articles = data['articles'];
          return articles
              .where((a) => a['title'] != null && a['url'] != null)
              .where((a) {
                final title = (a['title'] as String).toLowerCase();
                final description = (a['description'] as String? ?? '').toLowerCase();
                final content = (a['content'] as String? ?? '').toLowerCase();
                
                // Check if any finance keywords are present in title, description, or content
                return financeKeywords.any((keyword) => 
                  title.contains(keyword.toLowerCase()) ||
                  description.contains(keyword.toLowerCase()) ||
                  content.contains(keyword.toLowerCase())
                );
              })
              .map<Map<String, String>>((a) => {
                    'title': a['title'] as String,
                    'url': a['url'] as String,
                  })
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Add a welcome message widget
  Widget _buildWelcomeMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: AppColors.surfaceLight,
            width: 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.handshake,
                  size: 32,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Welcome to Hance!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your personal finance tracker powered by SMS.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Divider(),
            const SizedBox(height: 8),
            Text(
              'Hance automatically tracks your bank transactions from SMS and helps you manage your spending—all privately on your device.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Pull down to scan for your first transactions!',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _restoreTransactionFromHistory(int id) {
    if (_transactions.any((t) => t['id'] == id)) return;
    setState(() {
      final tx = Map<String, dynamic>.from(_history.firstWhere((t) => t['id'] == id));
      tx['tag'] = null;
      _transactions.insert(0, tx);
      _history.removeWhere((t) => t['id'] == id);
      _saveTransactions();
      _saveHistory();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction restored to pending!')),
    );
  }

  // --- Contact Dev Dialog ---
  void _showContactDevDialog(BuildContext context) {
    final TextEditingController _controller = TextEditingController();
    bool _messageSent = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(Icons.support_agent, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('Contact Developer'),
                ],
              ),
              content: _messageSent
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text('Thank you for reaching out!'),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: FaIcon(FontAwesomeIcons.solidEnvelope, color: AppColors.primary),
                              tooltip: 'Email',
                              onPressed: () async {
                                final Uri emailLaunchUri = Uri(
                                  scheme: 'mailto',
                                  path: 'hemahariharansamson@gmail.com',
                                  query: 'subject=Hance App Feedback',
                                );
                                await launchUrl(emailLaunchUri);
                              },
                            ),
                            IconButton(
                              icon: FaIcon(FontAwesomeIcons.github, color: Colors.black),
                              tooltip: 'GitHub',
                              onPressed: () async {
                                await launchUrl(Uri.parse('https://github.com/HemahariharanSamson'), mode: LaunchMode.externalApplication);
                              },
                            ),
                            IconButton(
                              icon: FaIcon(FontAwesomeIcons.linkedin, color: Color(0xFF0A66C2)),
                              tooltip: 'LinkedIn',
                              onPressed: () async {
                                await launchUrl(Uri.parse('https://in.linkedin.com/in/hemahariharansamson'), mode: LaunchMode.externalApplication);
                              },
                            ),
                            IconButton(
                              icon: FaIcon(FontAwesomeIcons.instagram, color: Color(0xFFE1306C)),
                              tooltip: 'Instagram',
                              onPressed: () async {
                                await launchUrl(Uri.parse('https://www.instagram.com/hemahariharansamson/'), mode: LaunchMode.externalApplication);
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _controller,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Type your message here...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
              actions: _messageSent
                  ? [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Close'),
                      ),
                    ]
                  : [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final message = _controller.text.trim();
                          if (message.isEmpty) return;
                          final Uri emailLaunchUri = Uri(
                            scheme: 'mailto',
                            path: 'hemahariharansamson@gmail.com',
                            query: 'subject=Hance App Feedback&body=${Uri.encodeComponent(message)}',
                          );
                          await launchUrl(emailLaunchUri);
                          setState(() {
                            _messageSent = true;
                          });
                        },
                        child: Text('Send'),
                      ),
                    ],
            );
          },
        );
      },
    );
  }
}