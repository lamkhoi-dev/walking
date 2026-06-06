import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:walktogether_app/core/services/step_counter_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    // Create a temporary directory for Hive files during tests
    tempDir = await Directory.systemTemp.createTemp('hive_test_dir');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    // Close all open boxes and clean up files
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('StepCounterService handles switchUser concurrency safely', () async {
    final service = StepCounterService();

    // Call switchUser multiple times concurrently for the same user
    final future1 = service.switchUser('test_user_123');
    final future2 = service.switchUser('test_user_123');
    final future3 = service.switchUser('test_user_123');

    // All concurrent calls should complete without throwing FileSystemException (lock failed)
    await expectLater(Future.wait([future1, future2, future3]), completes);

    // Verify the box is indeed open
    expect(Hive.isBoxOpen('step_counter_test_user_123'), isTrue);
  });

  test('StepCounterService switchUser to different users sequentially', () async {
    final service = StepCounterService();

    await service.switchUser('user_a');
    expect(Hive.isBoxOpen('step_counter_user_a'), isTrue);

    await service.switchUser('user_b');
    expect(Hive.isBoxOpen('step_counter_user_b'), isTrue);
    // The previous user's box should have been closed
    expect(Hive.isBoxOpen('step_counter_user_a'), isFalse);
  });
}
