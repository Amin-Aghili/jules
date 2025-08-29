import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl =
    'https://zrrypgzzfovkbebsyzih.supabase.co'; // از Dashboard
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpycnlwZ3p6Zm92a2JlYnN5emloIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4Mjc3MDMsImV4cCI6MjA3MDQwMzcwM30.9eR3O4uBrBn5CPThrjYQIbpZ2LqvaXbVnskxH1lx8Yg';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Sign In with Supabase Demo',
      home: SignInScreen(),
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _supabase = Supabase.instance.client;
  final _googleSignIn = GoogleSignIn.instance;
  bool _isInitialized = false;
  String? _errorMessage;
  User? _currentUser; // از Supabase

  @override
  void initState() {
    super.initState();
    _initializeGoogleSignIn();
    _listenToAuthChanges();
  }

  // گام 1: Initialize Google Sign In (الزامی در 7.x)
  Future<void> _initializeGoogleSignIn() async {
    const webClientId =
        '569147759580-ov6i3gsb5irgn3latsb4t79gut4csu8r.apps.googleusercontent.com';

    const iosClientId =
        '569147759580-5t2qh6vf1uffanpoe3md7frocm1pf1ov.apps.googleusercontent.com';
    try {
      // clientId: iOS/Android Client ID، serverClientId: Web Client ID از Google Cloud
      await _googleSignIn.initialize(
        clientId: iosClientId,
        serverClientId: webClientId,
      );
      setState(() {
        _isInitialized = true;
      });
      print('Google Sign In initialized');
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed: $e';
      });
    }
  }

  // گوش دادن به تغییرات auth در Supabase
  void _listenToAuthChanges() {
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        setState(() {
          _currentUser = data.session?.user;
        });
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _currentUser = null;
        });
      }
    });
  }

  // گام 2: Sign In with Google و Supabase
  Future<void> _handleSignIn() async {
    if (!_isInitialized) {
      _errorMessage = 'Not initialized yet';
      return;
    }

    try {
      // Authenticate با Google (جایگزین signIn() در 7.x)
      final account = await _googleSignIn.authenticate(
        scopeHint: ['openid', 'email', 'profile'], // scopes برای OIDC
      );

      // گرفتن tokens
      final auth = await account.authorizationClient.authorizationForScopes([
        'openid',
        'email',
        'profile',
      ]);
      final idToken = account.id;
      final accessToken = auth?.accessToken;

      if (accessToken == null) {
        throw 'No tokens found';
      }

      // Sign in با Supabase (با idToken)
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
        nonce:
            null, // اگر nonce استفاده می‌کنید، generate کنید (اختیاری برای امنیت بیشتر)
      );

      if (response.user != null) {
        setState(() {
          _currentUser = response.user;
        });
        print('Signed in: ${response.user?.email}');
      }
    } on GoogleSignInException catch (e) {
      setState(() {
        _errorMessage = _errorFromGoogleException(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign in failed: $e';
      });
    }
  }

  // Sign Out
  Future<void> _handleSignOut() async {
    try {
      await _googleSignIn.signOut();
      await _supabase.auth.signOut();
      setState(() {
        _currentUser = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Sign out failed: $e';
      });
    }
  }

  // مدیریت خطاهای Google (جدید در 7.x)
  String _errorFromGoogleException(GoogleSignInException e) {
    switch (e.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Sign in canceled by user';
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Network error';
      default:
        return 'Google error: ${e.code} - ${e.description}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Sign In with Supabase')),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_currentUser != null) {
      // حالت لاگین شده (اطلاعات از Supabase)
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(
              _currentUser!.userMetadata?['avatar_url'] ?? '',
            ),
            radius: 50,
          ),
          Text(
            'Name: ${_currentUser!.userMetadata?['full_name'] ?? _currentUser!.email}',
          ),
          Text('Email: ${_currentUser!.email}'),
          Text('User ID: ${_currentUser!.id}'),
          ElevatedButton(onPressed: _handleSignOut, child: Text('SIGN OUT')),
        ],
      );
    } else {
      // حالت لاگین نشده
      final List<Widget> children = [];
      if (_isInitialized) {
        children.add(
          ElevatedButton(
            onPressed: _handleSignIn,
            child: Text('SIGN IN WITH GOOGLE'),
          ),
        );
      } else {
        children.add(CircularProgressIndicator());
        children.add(Text('Initializing...'));
      }
      if (_errorMessage != null) {
        children.add(Text(_errorMessage!, style: TextStyle(color: Colors.red)));
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: children,
        ),
      );
    }
  }
}
