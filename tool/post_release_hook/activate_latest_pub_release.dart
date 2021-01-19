#! /usr/bin/env dcli

import 'package:dcli/dcli.dart';

/// This hook does a pub global activate so we are running the lateset version
/// pub_release whenever we push it to pub.dev.

void main(List<String> args) {
  print('activating latest version of pub_release');
  'dart pub global activate pub_release'.run;
}
