//test i will test the provider her

import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/test_provider.dart';

class Test extends ConsumerWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackcing = ref.watch(testProvider);
    // TODO: implement build
    throw UnimplementedError();
  }
}
