import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:math';

// ==================== THEME PROVIDER ====================
// ==================== THEME PROVIDER ====================
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDarkMode);
    notifyListeners();
  }

  // Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        // ✅ Changed from CardTheme to CardThemeData
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Colors.blue,
        surface: Color(0xFF1E1E1E),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        // ✅ Changed from CardTheme to CardThemeData
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

// ==================== MAIN ====================
void main() => runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const BusFareApp(),
      ),
    );

class BusFareApp extends StatelessWidget {
  const BusFareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smart Bus Fare',
          debugShowCheckedModeBanner: false,
          theme: ThemeProvider.lightTheme,
          darkTheme: ThemeProvider.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}

// ==================== STORAGE SERVICE ====================
// ==================== STORAGE SERVICE ====================
class Storage {
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('logged_in') ?? false;
  }

  static Future<void> login(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', true);
    await prefs.setString('name', name);
    await prefs.setString('email', email);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('logged_in', false);
  }

  static Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('name') ?? 'User';
  }

  static Future<double> getBalance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('balance') ?? 100.0;
  }

  static Future<void> setBalance(double balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('balance', balance);
  }

  static Future<void> saveTrip(
      String bus, DateTime time, double lat, double lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('trip', '$bus|${time.toIso8601String()}|$lat|$lon');
  }

  static Future<Map<String, dynamic>?> getTrip() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('trip');
    if (data != null) {
      final parts = data.split('|');
      return {
        'bus': parts[0],
        'time': DateTime.parse(parts[1]),
        'lat': double.parse(parts[2]),
        'lon': double.parse(parts[3]),
      };
    }
    return null;
  }

  static Future<void> clearTrip() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trip');
  }

  // ==================== TRIP HISTORY ====================

  // Save completed trip to history
  static Future<void> saveCompletedTrip({
    required String busNumber,
    required DateTime checkInTime,
    required DateTime checkOutTime,
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required double distance,
    required double fare,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing history
    List<String> history = prefs.getStringList('trip_history') ?? [];

    // Create trip data string
    final tripData = [
      busNumber,
      checkInTime.toIso8601String(),
      checkOutTime.toIso8601String(),
      startLat.toString(),
      startLon.toString(),
      endLat.toString(),
      endLon.toString(),
      distance.toString(),
      fare.toString(),
    ].join('|');

    // Add to beginning of list (most recent first)
    history.insert(0, tripData);

    // Keep only last 100 trips
    if (history.length > 100) {
      history = history.sublist(0, 100);
    }

    // Save back to preferences
    await prefs.setStringList('trip_history', history);
  }

  // Get all trip history
  static Future<List<Map<String, dynamic>>> getTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('trip_history') ?? [];

    return history.map((tripData) {
      final parts = tripData.split('|');
      return {
        'bus_number': parts[0],
        'check_in_time': DateTime.parse(parts[1]),
        'check_out_time': DateTime.parse(parts[2]),
        'start_lat': double.parse(parts[3]),
        'start_lon': double.parse(parts[4]),
        'end_lat': double.parse(parts[5]),
        'end_lon': double.parse(parts[6]),
        'distance': double.parse(parts[7]),
        'fare': double.parse(parts[8]),
      };
    }).toList();
  }

  // Get statistics
  static Future<Map<String, dynamic>> getStatistics() async {
    final trips = await getTripHistory();

    if (trips.isEmpty) {
      return {
        'total_trips': 0,
        'total_distance': 0.0,
        'total_spent': 0.0,
        'avg_fare': 0.0,
      };
    }

    double totalDistance = 0;
    double totalSpent = 0;

    for (var trip in trips) {
      totalDistance += trip['distance'] as double;
      totalSpent += trip['fare'] as double;
    }

    return {
      'total_trips': trips.length,
      'total_distance': totalDistance,
      'total_spent': totalSpent,
      'avg_fare': totalSpent / trips.length,
    };
  }

  // Clear all trip history
  static Future<void> clearTripHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('trip_history');
  }
}

// ==================== SPLASH SCREEN ====================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      final loggedIn = await Storage.isLoggedIn();
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    loggedIn ? const HomePage() : const LoginScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700])),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.directions_bus,
                    size: 80, color: Colors.blue),
              ),
              const SizedBox(height: 24),
              const Text('Smart Bus Fare',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const Text('GPS Integrated',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== LOGIN SCREEN ====================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade50])),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Spacer(),
                            const Icon(Icons.directions_bus,
                                size: 80, color: Colors.white),
                            const SizedBox(height: 24),
                            const Text('Welcome',
                                style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 40),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20)),
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameCtrl,
                                    decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: const Icon(Icons.person),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Enter name'
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: const Icon(Icons.email),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12))),
                                    validator: (v) =>
                                        v == null || !v.contains('@')
                                            ? 'Enter valid email'
                                            : null,
                                  ),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        if (_formKey.currentState!.validate()) {
                                          await Storage.login(
                                              _nameCtrl.text, _emailCtrl.text);
                                          if (mounted) {
                                            Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        const HomePage()));
                                          }
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16)),
                                      child: const Text('Login',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}

// ==================== HOME PAGE ====================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double balance = 100.0;
  Map<String, dynamic>? trip;
  String name = 'User';
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await Storage.getBalance();
    final t = await Storage.getTrip();
    final n = await Storage.getName();
    setState(() {
      balance = b;
      trip = t;
      name = n;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: [
        _buildHome(),
        _buildHistory(),
        _buildWallet(),
        _buildProfile(),
      ][_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
              : [Colors.blue.shade400, Colors.blue.shade50],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome Back!',
                          style: TextStyle(
                              color:
                                  isDark ? Colors.grey.shade400 : Colors.white,
                              fontSize: 16)),
                      Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Icon(Icons.notifications,
                      color: isDark ? Colors.grey.shade400 : Colors.white,
                      size: 28),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Wallet Balance',
                          style: TextStyle(color: Colors.grey.shade600)),
                      Icon(Icons.wallet, color: Colors.blue.shade400),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  AddMoneyScreen(balance: balance)));
                      if (result != null) {
                        setState(() => balance = result);
                        await _load();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Add Money',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30))),
                child: trip != null ? _buildActiveTrip() : _buildActions(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTrip() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Trip',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green)),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8)),
                      child:
                          const Icon(Icons.directions_bus, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bus ${trip!['bus']}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(DateFormat('hh:mm a').format(trip!['time']),
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Text(
                        'GPS: ${trip!['lat'].toStringAsFixed(4)}, ${trip!['lon'].toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                QRScanner(isCheckIn: false, trip: trip)));
                    if (result != null) {
                      setState(() {
                        balance = result;
                        trip = null;
                      });
                      await _load();
                    }
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Check Out'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _actionCard('Check In', Icons.login, Colors.green, () async {
                  if (balance < 5) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Low balance!'),
                        backgroundColor: Colors.red));
                    return;
                  }
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const QRScanner(isCheckIn: true)));
                  if (result != null) {
                    setState(() => trip = result);
                    await _load();
                  }
                }),
                _actionCard('History', Icons.history, Colors.blue,
                    () => setState(() => _index = 1)),
                _actionCard('Routes', Icons.route, Colors.orange, () {}),
                _actionCard('Support', Icons.support, Colors.purple, () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip History'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () async {
              final stats = await Storage.getStatistics();
              if (mounted) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Row(
                      children: [
                        Icon(Icons.analytics, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Travel Statistics'),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statRow(Icons.directions_bus, 'Total Trips',
                            '${stats['total_trips']}'),
                        const Divider(),
                        _statRow(Icons.route, 'Total Distance',
                            '${stats['total_distance'].toStringAsFixed(1)} km'),
                        const Divider(),
                        _statRow(Icons.currency_rupee, 'Total Spent',
                            '₹${stats['total_spent'].toStringAsFixed(2)}'),
                        const Divider(),
                        _statRow(Icons.attach_money, 'Average Fare',
                            '₹${stats['avg_fare'].toStringAsFixed(2)}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'clear') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear History?'),
                    content: const Text(
                        'This will permanently delete all trip history. This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await Storage.clearTripHistory();
                  setState(() {}); // Refresh the UI
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Trip history cleared'),
                          backgroundColor: Colors.green),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear History', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: Storage.getTripHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No trips yet',
                      style:
                          TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  const Text('Your trip history will appear here',
                      style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() => _index = 0); // Go to home
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Start Your First Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          final trips = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Refresh the FutureBuilder
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final trip = trips[index];
                return _buildTripCard(trip);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 15)),
          ),
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final checkInTime = trip['check_in_time'] as DateTime;
    final checkOutTime = trip['check_out_time'] as DateTime;
    final duration = checkOutTime.difference(checkInTime);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bus number and fare
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.directions_bus,
                            color: Colors.blue, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip['bus_number'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMM dd, yyyy').format(checkOutTime),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.3), width: 1.5),
                    ),
                    child: Text(
                      '₹${trip['fare'].toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Trip details grid
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade800.withOpacity(0.3)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _tripDetailItem(
                            Icons.access_time,
                            'Duration',
                            '${duration.inMinutes} min',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _tripDetailItem(
                            Icons.route,
                            'Distance',
                            '${trip['distance'].toStringAsFixed(1)} km',
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _tripDetailItem(
                            Icons.login,
                            'Check-in',
                            DateFormat('hh:mm a').format(checkInTime),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: _tripDetailItem(
                            Icons.logout,
                            'Check-out',
                            DateFormat('hh:mm a').format(checkOutTime),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripDetailItem(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    final checkInTime = trip['check_in_time'] as DateTime;
    final checkOutTime = trip['check_out_time'] as DateTime;
    final duration = checkOutTime.difference(checkInTime);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.directions_bus, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip['bus_number']),
                  Text(
                    DateFormat('MMMM dd, yyyy').format(checkOutTime),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _detailRow('Distance',
                        '${trip['distance'].toStringAsFixed(2)} km'),
                    const Divider(),
                    _detailRow('Fare', '₹${trip['fare'].toStringAsFixed(2)}'),
                    const Divider(),
                    _detailRow('Duration', '${duration.inMinutes} minutes'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Journey Times:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _detailRow('Check-in', DateFormat('hh:mm a').format(checkInTime)),
              _detailRow(
                  'Check-out', DateFormat('hh:mm a').format(checkOutTime)),
              const SizedBox(height: 16),
              const Text('Locations:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start:',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          '${trip['start_lat'].toStringAsFixed(5)}, ${trip['start_lon'].toStringAsFixed(5)}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End:',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          '${trip['end_lat'].toStringAsFixed(5)}, ${trip['end_lon'].toStringAsFixed(5)}',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildWallet() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('₹${balance.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddMoneyScreen(balance: balance)));
                if (result != null) {
                  setState(() => balance = result);
                  await _load();
                }
              },
              child: const Text('Add Money'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfile() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(name,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Balance: ₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const Divider(height: 40),

          // Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Dark Mode Toggle
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return SwitchListTile(
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Dark Mode'),
                subtitle: Text(
                  themeProvider.isDarkMode
                      ? 'Dark theme enabled'
                      : 'Light theme enabled',
                ),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),

          const Divider(),

          // Account Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Account',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to edit profile
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),

          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            subtitle: const Text('English'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to language settings
            },
          ),

          const Divider(),

          // Support Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help
            },
          ),

          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Smart Bus Fare',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.directions_bus, size: 48),
                children: const [
                  Text('GPS-integrated bus ticketing system'),
                ],
              );
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await Storage.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              }
            },
          ),

          const SizedBox(height: 20),

          // Version Info
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ==================== QR SCANNER ====================
// ==================== QR SCANNER ====================
class QRScanner extends StatefulWidget {
  final bool isCheckIn;
  final Map<String, dynamic>? trip;

  const QRScanner({super.key, required this.isCheckIn, this.trip});

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  MobileScannerController? controller;
  bool processing = false;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isCheckIn ? 'Scan to Check In' : 'Scan to Check Out'),
        backgroundColor: widget.isCheckIn ? Colors.green : Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: () => controller?.switchCamera(),
            tooltip: 'Switch Camera',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => controller?.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller!,
            onDetect: (capture) {
              if (!processing && !isDisposed && capture.barcodes.isNotEmpty) {
                setState(() {
                  processing = true;
                });
                _process(capture.barcodes.first.rawValue ?? '');
              }
            },
          ),

          // Scanning Guide Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isCheckIn ? Colors.green : Colors.red,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ],
              ),
            ),
          ),

          // Instruction Text
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.isCheckIn
                    ? 'Align QR code within the frame to check in'
                    : 'Scan QR code to complete your journey',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Manual Entry Button

          if (processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _process(String qr) async {
    try {
      // Stop the scanner first
      await controller?.stop();

      print('============ PROCESSING START ============');
      print('QR Code: $qr');
      print('Is Check In: ${widget.isCheckIn}');

      // Validate trip data for checkout
      if (!widget.isCheckIn) {
        print('Validating checkout data...');

        if (widget.trip == null) {
          print('ERROR: Trip is null');
          _showError('No active trip found!');
          return;
        }

        print('Trip data: ${widget.trip}');

        // Validate required fields
        if (!widget.trip!.containsKey('lat') ||
            !widget.trip!.containsKey('lon') ||
            widget.trip!['lat'] == null ||
            widget.trip!['lon'] == null) {
          print('ERROR: Missing lat/lon in trip data');
          _showError('Invalid trip data. Missing location information.');
          return;
        }

        print('Trip validation passed');
      }

      // Check location permissions
      print('Checking location permissions...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('Current permission: $permission');

      if (permission == LocationPermission.denied) {
        print('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('ERROR: Permission denied');
          _showError(
              'Location permission denied. Please enable location access.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('ERROR: Permission denied forever');
        _showError(
            'Location permissions are permanently denied. Please enable them in settings.');
        return;
      }

      // Check if location services are enabled
      print('Checking location services...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('Location service enabled: $serviceEnabled');

      if (!serviceEnabled) {
        print('ERROR: Location services disabled');
        _showError('Location services are disabled. Please enable GPS.');
        return;
      }

      if (widget.isCheckIn) {
        print('===== CHECK IN PROCESS =====');

        print('Getting current position...');
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        print('Position: ${pos.latitude}, ${pos.longitude}');

        final bus = qr.isNotEmpty ? qr : 'BUS${Random().nextInt(9999)}';
        final time = DateTime.now();

        print('Saving trip: Bus=$bus, Time=$time');
        await Storage.saveTrip(bus, time, pos.latitude, pos.longitude);
        print('Trip saved successfully');

        if (!isDisposed && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 8),
                  Text('Check-In Success!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Bus: $bus',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('hh:mm a, MMM dd').format(time),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.gps_fixed,
                          size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        'Accuracy: ${pos.accuracy.toStringAsFixed(0)}m',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isDisposed && mounted) {
                      Navigator.pop(context, {
                        'bus': bus,
                        'time': time,
                        'lat': pos.latitude,
                        'lon': pos.longitude
                      });
                    }
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        }
      } else {
        print('===== CHECK OUT PROCESS =====');

        print('Getting current position for checkout...');
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
        print('Current position: ${pos.latitude}, ${pos.longitude}');

        // Extract and convert coordinates
        final startLat = (widget.trip!['lat'] as num).toDouble();
        final startLon = (widget.trip!['lon'] as num).toDouble();
        print('Start position: $startLat, $startLon');

        // Calculate distance
        final distance = Geolocator.distanceBetween(
                startLat, startLon, pos.latitude, pos.longitude) /
            1000;
        print('Distance: ${distance.toStringAsFixed(2)} km');

        // Calculate fare (₹2.5 per km, minimum ₹5)
        final calculatedFare = (distance * 2.5).roundToDouble();
        final fare = calculatedFare < 5 ? 5.0 : calculatedFare;
        print('Calculated Fare: ₹$calculatedFare, Final Fare: ₹$fare');

        // Check balance
        final balance = await Storage.getBalance();
        print('Current balance: ₹$balance');

        if (balance < fare) {
          print('ERROR: Insufficient balance');
          if (!isDisposed && mounted) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange, size: 32),
                    SizedBox(width: 8),
                    Text('Insufficient Balance'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Required: ₹${fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Current Balance: ₹${balance.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text('Please add money to your wallet.'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (!isDisposed && mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }

        // Deduct fare and save to history
        final newBalance = balance - fare;
        print('Deducting fare. New balance: ₹$newBalance');

        // ✅ Save completed trip to history
        print('Saving trip to history...');
        await Storage.saveCompletedTrip(
          busNumber: widget.trip!['bus'],
          checkInTime: widget.trip!['time'],
          checkOutTime: DateTime.now(),
          startLat: startLat,
          startLon: startLon,
          endLat: pos.latitude,
          endLon: pos.longitude,
          distance: distance,
          fare: fare,
        );
        print('Trip saved to history successfully');

        await Storage.setBalance(newBalance);
        await Storage.clearTrip();
        print('Balance updated and trip cleared');

        if (!isDisposed && mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 8),
                  Text('Journey Complete!'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Distance:',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '${distance.toStringAsFixed(2)} km',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Fare:',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '₹${fare.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('New Balance:',
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              '₹${newBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Trip saved to history!',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (!isDisposed && mounted) {
                      Navigator.pop(context, newBalance);
                    }
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          );
        }
      }

      print('============ PROCESSING COMPLETE ============');
    } catch (e, stackTrace) {
      print('============ ERROR ============');
      print('Error in _process: $e');
      print('Stack trace: $stackTrace');
      print('===============================');

      if (!isDisposed && mounted) {
        _showError('Failed to process: ${e.toString()}');
      }
    } finally {
      if (!isDisposed && mounted) {
        setState(() {
          processing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (isDisposed || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 32),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (!isDisposed && mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    isDisposed = true;
    controller?.dispose();
    super.dispose();
  }
}

// ==================== ADD MONEY SCREEN ====================
class AddMoneyScreen extends StatefulWidget {
  final double balance;

  const AddMoneyScreen({super.key, required this.balance});

  @override
  State<AddMoneyScreen> createState() => _AddMoneyScreenState();
}

class _AddMoneyScreenState extends State<AddMoneyScreen> {
  final amounts = [50.0, 100.0, 200.0, 500.0];
  double? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Money')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text('Current: ₹${widget.balance.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 30),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: amounts.length,
              itemBuilder: (_, i) {
                final amt = amounts[i];
                return InkWell(
                  onTap: () => setState(() => selected = amt),
                  child: Container(
                    decoration: BoxDecoration(
                        color: selected == amt
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Theme.of(context).primaryColor)),
                    child: Center(
                        child: Text('₹${amt.toInt()}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: selected == amt
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.color))),
                  ),
                );
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (selected != null) {
                  final newBalance = widget.balance + selected!;
                  await Storage.setBalance(newBalance);
                  if (mounted) Navigator.pop(context, newBalance);
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text('Add Money',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
