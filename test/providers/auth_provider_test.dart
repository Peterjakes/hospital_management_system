import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hospital_management_system/models/user_model.dart' as app_user;
import 'package:hospital_management_system/providers/auth_provider.dart';
import 'package:hospital_management_system/services/auth_service.dart';

// A fake stand-in for AuthService. Mocktail generates a mock that lets us
// control exactly what each method returns/throws, without ever touching
// real Firebase Auth or Firestore. This is what the AuthProvider refactor
// (accepting AuthService via constructor) makes possible.
class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;
  late AuthProvider authProvider;

  // mocktail needs a registered "fallback value" for any custom type used
  // with any() as an argument matcher — otherwise it can throw at runtime
  // when stubbing a method that takes a non-nullable custom enum.
  setUpAll(() {
    registerFallbackValue(app_user.UserRole.patient);
  });

  setUp(() {
    mockAuthService = MockAuthService();
    // Inject the mock instead of letting AuthProvider create a real
    // AuthService() internally — this is the whole point of the refactor.
    authProvider = AuthProvider(authService: mockAuthService);
  });

  group('AuthProvider.signIn', () {
    test(
      'returns true and stores user data when AuthService signs in successfully',
      () async {
        // Arrange: tell the mock what a successful sign-in returns.
        when(() => mockAuthService.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => {
              'id': 'uid123',
              'email': 'patient@example.com',
              'firstName': 'John',
              'lastName': 'Kamau',
              'role': 'patient',
            });

        final result = await authProvider.signIn(
          email: 'patient@example.com',
          password: 'correct-password',
        );

        expect(result, isTrue);
        expect(authProvider.currentUserData?['email'], 'patient@example.com');
        expect(authProvider.errorMessage, isNull);
        expect(authProvider.isLoading, isFalse);
      },
    );

    test(
      'returns false and sets an error message when credentials are wrong',
      () async {
        // Arrange: simulate exactly what AuthService throws on bad login —
        // it wraps FirebaseAuthException into a plain Exception with a
        // human-readable message (see auth_service.dart _handleAuthException).
        when(() => mockAuthService.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(Exception('Wrong password provided.'));

        final result = await authProvider.signIn(
          email: 'patient@example.com',
          password: 'wrong-password',
        );

        expect(result, isFalse);
        expect(authProvider.errorMessage, contains('Wrong password'));
        expect(authProvider.isLoading, isFalse);
        // Importantly: no stale user data should linger after a failed login.
        expect(authProvider.currentUserData, isNull);
      },
    );

    test('returns false when AuthService returns null (no matching user doc)',
        () async {
      // This mirrors a real edge case in auth_service.dart: Firebase Auth
      // succeeds but there's no matching Firestore user document, so
      // signInWithEmailAndPassword resolves to null instead of throwing.
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => null);

      final result = await authProvider.signIn(
        email: 'orphaned@example.com',
        password: 'somepassword',
      );

      expect(result, isFalse);
    });

    test('sets isLoading to true during the call and false after it completes',
        () async {
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async {
        // While this future is pending, isLoading should already be true.
        expect(authProvider.isLoading, isTrue);
        return {'id': 'uid1', 'email': 'a@b.com', 'role': 'patient'};
      });

      await authProvider.signIn(email: 'a@b.com', password: 'pw');

      expect(authProvider.isLoading, isFalse);
    });

    test('clears any previous error message at the start of a new attempt',
        () async {
      // First attempt fails and leaves an error message behind.
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('Wrong password provided.'));

      await authProvider.signIn(email: 'a@b.com', password: 'wrong');
      expect(authProvider.errorMessage, isNotNull);

      // Second attempt succeeds — the old error should not still be showing.
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => {
            'id': 'uid1',
            'email': 'a@b.com',
            'role': 'patient',
          });

      await authProvider.signIn(email: 'a@b.com', password: 'correct');
      expect(authProvider.errorMessage, isNull);
    });
  });

  group('AuthProvider.registerUser', () {
    test('returns true and updates state when registration succeeds',
        () async {
      final newUser = app_user.User(
        id: 'uid456',
        email: 'newdoctor@example.com',
        firstName: 'Sarah',
        lastName: 'Kim',
        role: app_user.UserRole.doctor,
        createdAt: DateTime(2025, 1, 1),
      );

      when(() => mockAuthService.registerUser(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            role: any(named: 'role'),
          )).thenAnswer((_) async => newUser);

      // AuthProvider.registerUser also reads `_authService.currentUser`
      // after a successful registration to keep local state in sync.
      when(() => mockAuthService.currentUser).thenReturn(null);

      final result = await authProvider.registerUser(
        email: 'newdoctor@example.com',
        password: 'securepass123',
        firstName: 'Sarah',
        lastName: 'Kim',
        role: app_user.UserRole.doctor,
      );

      expect(result, isTrue);
      expect(authProvider.currentUserData?['role'], 'doctor');
      expect(authProvider.currentUserData?['email'], 'newdoctor@example.com');
    });

    test(
      'returns false and sets an error message when email is already in use',
      () async {
        when(() => mockAuthService.registerUser(
              email: any(named: 'email'),
              password: any(named: 'password'),
              firstName: any(named: 'firstName'),
              lastName: any(named: 'lastName'),
              role: any(named: 'role'),
            )).thenThrow(
          Exception('An account already exists for this email address.'),
        );

        final result = await authProvider.registerUser(
          email: 'taken@example.com',
          password: 'securepass123',
          firstName: 'Sarah',
          lastName: 'Kim',
        );

        expect(result, isFalse);
        expect(authProvider.errorMessage, contains('already exists'));
      },
    );

    test('defaults new registrations to the patient role when none is given',
        () async {
      // This test locks in the existing default in both AuthService and
      // AuthProvider's registerUser signature (role = UserRole.patient).
      // If that default ever silently changes, this test should catch it —
      // it's a meaningful default since it controls what access level a
      // new account gets.
      final defaultRoleUser = app_user.User(
        id: 'uid789',
        email: 'default@example.com',
        firstName: 'Default',
        lastName: 'User',
        role: app_user.UserRole.patient,
        createdAt: DateTime(2025, 1, 1),
      );

      when(() => mockAuthService.registerUser(
            email: any(named: 'email'),
            password: any(named: 'password'),
            firstName: any(named: 'firstName'),
            lastName: any(named: 'lastName'),
            role: app_user.UserRole.patient,
          )).thenAnswer((_) async => defaultRoleUser);
      when(() => mockAuthService.currentUser).thenReturn(null);

      final result = await authProvider.registerUser(
        email: 'default@example.com',
        password: 'securepass123',
        firstName: 'Default',
        lastName: 'User',
        // role intentionally omitted
      );

      expect(result, isTrue);
      expect(authProvider.currentUserData?['role'], 'patient');
    });
  });

  group('AuthProvider derived getters', () {
    test('isAuthenticated reflects whether a Firebase user is present', () {
      // No sign-in has happened yet, so there should be no current user.
      expect(authProvider.isAuthenticated, isFalse);
    });

    test('currentUserRole parses the role out of currentUserData', () async {
      when(() => mockAuthService.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => {
            'id': 'uid1',
            'email': 'doc@example.com',
            'role': 'doctor',
          });

      await authProvider.signIn(email: 'doc@example.com', password: 'pw');

      expect(authProvider.currentUserRole, app_user.UserRole.doctor);
    });

    test('currentUserRole is null before any user data has been loaded', () {
      expect(authProvider.currentUserRole, isNull);
    });
  });
}