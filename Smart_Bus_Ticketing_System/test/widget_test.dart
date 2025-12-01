import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bus_fare/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // Setup before tests
  setUp(() async {
    // Initialize SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
  });

  group('App Initialization Tests', () {
    testWidgets('App starts with splash screen', (WidgetTester tester) async {
      await tester.pumpWidget(const BusFareApp());

      // Verify splash screen elements
      expect(find.text('Smart Bus Fare'), findsOneWidget);
      expect(find.text('GPS Integrated'), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
    });

    testWidgets('Splash screen navigates to login when not logged in',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'logged_in': false});

      await tester.pumpWidget(const BusFareApp());

      // Wait for splash screen duration
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should navigate to login screen
      expect(find.text('Welcome'), findsWidgets);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('Splash screen navigates to home when logged in',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'logged_in': true,
        'name': 'Test User',
        'balance': 100.0,
      });

      await tester.pumpWidget(const BusFareApp());

      // Wait for splash screen duration
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should navigate to home page
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
    });
  });

  group('Login Screen Tests', () {
    testWidgets('Login screen has all required fields',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
      expect(find.byIcon(Icons.email), findsOneWidget);
    });

    testWidgets('Login validation works correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Try to login without filling fields
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Enter name'), findsOneWidget);
      expect(find.text('Enter valid email'), findsOneWidget);
    });

    testWidgets('Login works with valid credentials',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Enter valid data
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'John Doe');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'john@example.com');

      // Tap login
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should navigate to home (check for home elements)
      expect(find.text('Welcome Back!'), findsOneWidget);
    });
  });

  group('Home Screen Tests', () {
    testWidgets('Home screen displays user info and balance',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'logged_in': true,
        'name': 'Test User',
        'balance': 150.0,
      });

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Wallet Balance'), findsOneWidget);
      expect(find.textContaining('₹150.00'), findsOneWidget);
    });

    testWidgets('Bottom navigation bar works', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'logged_in': true,
        'name': 'Test User',
        'balance': 100.0,
      });

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      // Test navigation to History
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('Trip History'), findsOneWidget);

      // Test navigation to Wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('Wallet'), findsOneWidget);

      // Test navigation to Profile
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);

      // Test navigation back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome Back!'), findsOneWidget);
    });

    testWidgets('Quick actions are displayed when no active trip',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'logged_in': true,
        'name': 'Test User',
        'balance': 100.0,
      });

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Check In'), findsOneWidget);
      expect(find.text('History'), findsWidgets); // Multiple instances
      expect(find.text('Routes'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    });

    testWidgets('Active trip is displayed when trip exists',
        (WidgetTester tester) async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'logged_in': true,
        'name': 'Test User',
        'balance': 100.0,
        'trip': 'BUS123|${now.toIso8601String()}|13.0827|80.2707',
      });

      await tester.pumpWidget(const MaterialApp(home: HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Active Trip'), findsOneWidget);
      expect(find.text('Bus BUS123'), findsOneWidget);
      expect(find.text('Check Out'), findsOneWidget);
    });
  });

  group('Add Money Screen Tests', () {
    testWidgets('Add money screen displays amounts',
        (WidgetTester tester) async {
      await tester
          .pumpWidget(const MaterialApp(home: AddMoneyScreen(balance: 100.0)));

      expect(find.text('Add Money'), findsNWidgets(2)); // Title and button
      expect(find.text('Current: ₹100.00'), findsOneWidget);
      expect(find.text('₹50'), findsOneWidget);
      expect(find.text('₹100'), findsOneWidget);
      expect(find.text('₹200'), findsOneWidget);
      expect(find.text('₹500'), findsOneWidget);
    });

    testWidgets('Can select amount and add money', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({'balance': 100.0});

      await tester
          .pumpWidget(const MaterialApp(home: AddMoneyScreen(balance: 100.0)));

      // Select ₹200
      await tester.tap(find.text('₹200'));
      await tester.pumpAndSettle();

      // Tap Add Money button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Money'));
      await tester.pumpAndSettle();

      // Verify balance was updated in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getDouble('balance'), 300.0);
    });
  });

  group('Storage Service Tests', () {
    test('Login stores user data', () async {
      SharedPreferences.setMockInitialValues({});

      await Storage.login('John Doe', 'john@example.com');

      final loggedIn = await Storage.isLoggedIn();
      final name = await Storage.getName();

      expect(loggedIn, true);
      expect(name, 'John Doe');
    });

    test('Logout clears logged in status', () async {
      SharedPreferences.setMockInitialValues({'logged_in': true});

      await Storage.logout();

      final loggedIn = await Storage.isLoggedIn();
      expect(loggedIn, false);
    });

    test('Balance operations work correctly', () async {
      SharedPreferences.setMockInitialValues({});

      await Storage.setBalance(250.0);
      final balance = await Storage.getBalance();

      expect(balance, 250.0);
    });

    test('Trip save and retrieve works', () async {
      SharedPreferences.setMockInitialValues({});

      final now = DateTime.now();
      await Storage.saveTrip('BUS456', now, 13.0827, 80.2707);

      final trip = await Storage.getTrip();

      expect(trip, isNotNull);
      expect(trip!['bus'], 'BUS456');
      expect(trip['lat'], 13.0827);
      expect(trip['lon'], 80.2707);
    });

    test('Clear trip removes trip data', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        'trip': 'BUS123|${now.toIso8601String()}|13.0827|80.2707',
      });

      await Storage.clearTrip();
      final trip = await Storage.getTrip();

      expect(trip, isNull);
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('Full user flow: Login -> Home -> Add Money',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const BusFareApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      // Should be on login screen
      expect(find.text('Welcome'), findsOneWidget);

      // Login
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'Test User');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email'), 'test@example.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle();

      // Should be on home screen
      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);

      // Navigate to Wallet
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();

      // Tap Add Money from wallet screen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Add Money'));
      await tester.pumpAndSettle();

      // Should be on Add Money screen
      expect(find.text('Add Money'), findsNWidgets(2));
    });
  });
}
