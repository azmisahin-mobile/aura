import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ui/screens/aura_home.dart';
import 'logic/aura_bloc.dart';

void main() {
  runApp(
    BlocProvider(
      create: (_) => AuraBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(brightness: Brightness.dark),
        home: AuraHome(),
      ),
    ),
  );
}
