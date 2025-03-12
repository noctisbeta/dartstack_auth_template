import 'dart:async';

import 'package:client/authentication/controllers/auth_bloc.dart';
import 'package:client/authentication/models/auth_event.dart';
import 'package:client/authentication/models/auth_state.dart';
import 'package:client/authentication/views/auth_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Home'),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            context.read<AuthBloc>().add(const AuthEventLogout());
          },
        ),
      ],
    ),
    body: BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthStateUnauthenticated) {
          unawaited(
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthView()),
            ),
          );
        }
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is AuthStateAuthenticated) {
                  return Text(
                    'Welcome, ${state.user.username}!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthEventLogout());
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    ),
  );
}
