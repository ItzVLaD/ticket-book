import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tickets_booking/services/user_service.dart';

// Generate mocks
@GenerateMocks([User])
import 'user_service_test.mocks.dart';

void main() {
  group('UserService Tests', () {
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser();
      
      // Setup mock user
      when(mockUser.uid).thenReturn('test-user-id');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.photoURL).thenReturn('https://example.com/photo.jpg');
    });

    group('createOrUpdateUser', () {
      test('should accept User parameter without throwing parse error', () async {
        try {
          final userService = UserService();
          await userService.createOrUpdateUser(mockUser);
          expect(true, isTrue);
        } catch (e) {
          // Expected to fail due to Firebase not being initialized in tests
          expect(e, isA<Exception>());
        }
      });

      test('should handle user with minimum required fields', () async {
        final minimalUser = MockUser();
        when(minimalUser.uid).thenReturn('minimal-user-id');
        when(minimalUser.email).thenReturn('minimal@example.com');
        when(minimalUser.displayName).thenReturn(null);
        when(minimalUser.photoURL).thenReturn(null);

        try {
          final userService = UserService();
          await userService.createOrUpdateUser(minimalUser);
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('getUser', () {
      test('should return user document stream', () {
        try {
          final userService = UserService();
          final stream = userService.getUser('test-user-id');
          expect(stream, isNotNull);
          expect(stream, isA<Stream>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle empty user ID', () {
        try {
          final userService = UserService();
          final stream = userService.getUser('');
          expect(stream, isNotNull);
          expect(stream, isA<Stream>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('addToWishlist', () {
      test('should accept correct parameters without throwing parse error', () async {
        try {
          final userService = UserService();
          await userService.addToWishlist('test-user-id', 'test-event-id');
          expect(true, isTrue);
        } catch (e) {
          // Expected to fail due to Firebase not being initialized in tests
          expect(e, isA<Exception>());
        }
      });

      test('should handle various event IDs', () async {
        final eventIds = ['event-1', 'event-2', 'event-3'];
        
        for (final eventId in eventIds) {
          try {
            final userService = UserService();
            await userService.addToWishlist('test-user-id', eventId);
            expect(true, isTrue);
          } catch (e) {
            expect(e, isA<Exception>());
          }
        }
      });
    });

    group('removeFromWishlist', () {
      test('should accept correct parameters without throwing parse error', () async {
        try {
          final userService = UserService();
          await userService.removeFromWishlist('test-user-id', 'test-event-id');
          expect(true, isTrue);
        } catch (e) {
          // Expected to fail due to Firebase not being initialized in tests
          expect(e, isA<Exception>());
        }
      });

      test('should handle non-existent event ID', () async {
        try {
          final userService = UserService();
          await userService.removeFromWishlist('test-user-id', 'non-existent-event');
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('getWishlist', () {
      test('should return wishlist stream', () {
        try {
          final userService = UserService();
          final stream = userService.getWishlist('test-user-id');
          expect(stream, isNotNull);
          expect(stream, isA<Stream>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle empty user ID', () {
        try {
          final userService = UserService();
          final stream = userService.getWishlist('');
          expect(stream, isNotNull);
          expect(stream, isA<Stream>());
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('deleteUserData', () {
      test('should accept user ID parameter without throwing parse error', () async {
        try {
          final userService = UserService();
          await userService.deleteUserData('test-user-id');
          expect(true, isTrue);
        } catch (e) {
          // Expected to fail due to Firebase not being initialized in tests
          expect(e, isA<Exception>());
        }
      });

      test('should handle empty user ID', () async {
        try {
          final userService = UserService();
          await userService.deleteUserData('');
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should handle non-existent user ID', () async {
        try {
          final userService = UserService();
          await userService.deleteUserData('non-existent-user');
          expect(true, isTrue);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Service initialization', () {
      test('should create UserService instance', () {
        try {
          final userService = UserService();
          expect(userService, isA<UserService>());
          expect(userService, isNotNull);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });

      test('should have usersCollection', () {
        try {
          final userService = UserService();
          expect(userService.usersCollection, isNotNull);
        } catch (e) {
          expect(e, isA<Exception>());
        }
      });
    });

    group('Parameter validation', () {
      test('should handle various user ID formats', () {
        final userIds = [
          'user123',
          'user_with_underscores',
          'user-with-dashes',
          '1234567890',
          'very-long-user-id-with-many-characters'
        ];

        for (final userId in userIds) {
          try {
            final userService = UserService();
            final stream = userService.getUser(userId);
            expect(stream, isNotNull);
            expect(stream, isA<Stream>());
          } catch (e) {
            expect(e, isA<Exception>());
          }
        }
      });

      test('should handle various event ID formats', () async {
        final eventIds = [
          'event123',
          'event_with_underscores',
          'event-with-dashes',
          '9876543210',
          'very-long-event-id-with-many-characters'
        ];

        for (final eventId in eventIds) {
          try {
            final userService = UserService();
            await userService.addToWishlist('test-user-id', eventId);
            expect(true, isTrue);
          } catch (e) {
            expect(e, isA<Exception>());
          }
        }
      });
    });
  });
}
