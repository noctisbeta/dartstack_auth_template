import 'dart:async';

import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/repositories/auth_repository.dart';
import 'package:client/common/widgets/my_snackbar.dart';
import 'package:client/dio_wrapper/dio_wrapper.dart';
import 'package:common/auth/tokens/jwtoken.dart';
import 'package:common/auth/tokens/refresh_token.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with SingleTickerProviderStateMixin {
  String _jwtExpiresIn = '';
  String _refreshExpiresIn = '';
  String _requestResult = '';
  late Timer _timer;
  bool _isRefreshing = false;

  // Add these variables to track progress
  double _jwtProgress = 1;
  double _refreshProgress = 1;

  // Store the expiration times
  DateTime? _jwtExpiresAt;
  DateTime? _refreshExpiresAt;

  @override
  void initState() {
    super.initState();

    unawaited(_updateTokenInfo());
    // Update token info every second
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => unawaited(_updateTokenInfo()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _updateTokenInfo() async {
    final AuthRepository authRepo = context.read<AuthRepository>();
    final ({DateTime jwtExpiresAt, DateTime refreshExpiresAt})? tokenInfo =
        await authRepo.getTokenExpirations();

    if (tokenInfo == null) {
      return;
    }

    final now = DateTime.now();

    // Store expiration times on first load if not set yet
    _jwtExpiresAt ??= tokenInfo.jwtExpiresAt;
    _refreshExpiresAt ??= tokenInfo.refreshExpiresAt;

    // Calculate new progress values
    double newJwtProgress;
    double newRefreshProgress;

    // JWT countdown
    if (tokenInfo.jwtExpiresAt.isAfter(now)) {
      // Get remaining milliseconds and convert to seconds
      final int millisLeft =
          tokenInfo.jwtExpiresAt.difference(now).inMilliseconds;
      final int secondsLeft = millisLeft ~/ 1000;

      _jwtExpiresIn = '${secondsLeft ~/ 60}m ${secondsLeft % 60}s';

      final int totalMillis = JWToken.expirationDuration.inMilliseconds;

      newJwtProgress = millisLeft / totalMillis;
      newJwtProgress = newJwtProgress.clamp(0.0, 1.0);
    } else {
      _jwtExpiresIn = 'Expired';
      newJwtProgress = 0;
    }

    // Refresh token countdown
    if (tokenInfo.refreshExpiresAt.isAfter(now)) {
      // Get remaining milliseconds and convert as needed for display
      final int millisLeft =
          tokenInfo.refreshExpiresAt.difference(now).inMilliseconds;
      final int secondsLeft = millisLeft ~/ 1000;

      _refreshExpiresIn =
          '${secondsLeft ~/ 60}m '
          '${secondsLeft % 60}s';

      // For refresh token, we need to calculate total duration
      // (assuming it's typically 7 days, adjust as needed)
      final int totalMillis = RefreshToken.expirationDuration.inMilliseconds;

      newRefreshProgress = millisLeft / totalMillis;
      newRefreshProgress = newRefreshProgress.clamp(0.0, 1.0);
    } else {
      _refreshExpiresIn = 'Expired';
      newRefreshProgress = 0;
    }

    // Update the UI
    setState(() {
      _jwtProgress = newJwtProgress;
      _refreshProgress = newRefreshProgress;
    });
  }

  Future<void> _sendTestRequest() async {
    setState(() {
      _requestResult = 'Loading...';
    });

    void showSnack(String message, {bool isError = false}) {
      if (isError) {
        MySnackBar.showError(context, message);
      } else {
        MySnackBar.showInfo(context, message);
      }
    }

    try {
      final DioWrapper dio = context.read<DioWrapper>();
      final Response response = await dio.get('/api/protected-resource');

      setState(() {
        _requestResult = 'Success: ${response.data}';
      });

      showSnack('API request successful');
    } on Exception catch (e) {
      setState(() {
        _requestResult = 'Error: $e';
      });

      showSnack('Failed to send API request', isError: true);
    }
  }

  // Add this new method for refreshing the JWT
  Future<void> _refreshJwt() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      context.read<AuthBloc>().add(const AuthEventRefreshToken());

      // Show success message
      MySnackBar.showSuccess(context, 'JWT refreshed successfully');
    } on Exception catch (e) {
      MySnackBar.showError(context, 'Failed to refresh JWT: $e');
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  Future<void> _logout() async {
    context.read<AuthBloc>().add(const AuthEventLogout());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('JWT Test Dashboard'),
      actions: [
        IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          tooltip: 'Logout',
        ),
      ],
    ),
    body: Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Token Information',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // JWT token info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'JWT Token',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: _isRefreshing ? null : _refreshJwt,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child:
                                _isRefreshing
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text('Refresh JWT'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Expires in: $_jwtExpiresIn'),
                      LinearProgressIndicator(
                        value: _jwtProgress,
                        backgroundColor: Colors.blue.shade100,
                        color: _jwtProgress > 0.25 ? Colors.blue : Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Refresh token info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Refresh Token',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Expires in: $_refreshExpiresIn'),
                      LinearProgressIndicator(
                        value: _refreshProgress,
                        backgroundColor: Colors.blue.shade100,
                        color:
                            _refreshProgress > 0.25 ? Colors.blue : Colors.red,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Test request section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _sendTestRequest,
                      child: const Text('Send Protected API Request'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (_requestResult.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _requestResult.contains('Error')
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_requestResult),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
