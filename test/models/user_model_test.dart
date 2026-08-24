import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management_system/models/user_model.dart';

void main() {
  // UserRole is the enum that gates access across the whole app (patient vs
  // doctor vs admin screens/permissions). If conversion to/from string ever
  // breaks, someone could silently end up with the wrong role.
  group('UserRoleExtension', () {
    // Confirms the exact strings we write to Firestore never drift —
    // if these change, existing documents in the database become unreadable.
    test('value converts each enum case to the correct storage string', () {
      expect(UserRole.patient.value, 'patient');
      expect(UserRole.doctor.value, 'doctor');
      expect(UserRole.admin.value, 'admin');
    });

    // The reverse of the above — reading a role back out of Firestore
    // must map to the correct enum, not just "some" enum.
    test('fromString parses valid role strings back into the correct enum', () {
      expect(UserRoleExtension.fromString('patient'), UserRole.patient);
      expect(UserRoleExtension.fromString('doctor'), UserRole.doctor);
      expect(UserRoleExtension.fromString('admin'), UserRole.admin);
    });

    // Firestore data could have inconsistent casing if entered manually
    // or migrated from another system — role checks shouldn't break over case.
    test('fromString is case-insensitive', () {
      expect(UserRoleExtension.fromString('DOCTOR'), UserRole.doctor);
      expect(UserRoleExtension.fromString('Admin'), UserRole.admin);
    });

    // This documents existing behavior in user_model.dart: an unrecognized
    // role string silently becomes "patient" instead of throwing an error.
    // That's worth knowing and locking in as an explicit, visible test —
    // if this default ever needs to change (e.g. to fail loudly instead),
    // this test should be the first thing that flags it.
    test(
      'fromString defaults unrecognized values to patient rather than throwing',
      () {
        expect(UserRoleExtension.fromString('superadmin'), UserRole.patient);
        expect(UserRoleExtension.fromString(''), UserRole.patient);
      },
    );
  });

  group('User model', () {
    // fullName is used across the UI (dashboards, appointment cards, etc.)
    // so a formatting slip here (e.g. missing space) would show up everywhere.
    test('fullName combines firstName and lastName with a space', () {
      final user = User(
        id: 'u1',
        email: 'jane@example.com',
        firstName: 'Jane',
        lastName: 'Wanjiru',
        role: UserRole.patient,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user.fullName, 'Jane Wanjiru');
    });

    // isActive controls whether a user can log in / appears in listings.
    // Confirming the default is "true" prevents accidentally locking out
    // every newly created user if this default ever gets flipped by mistake.
    test('isActive defaults to true when not explicitly provided', () {
      final user = User(
        id: 'u2',
        email: 'active@example.com',
        firstName: 'Active',
        lastName: 'User',
        role: UserRole.doctor,
        createdAt: DateTime(2025, 1, 1),
      );

      expect(user.isActive, isTrue);
    });

    // toMap() is what actually gets written to Firestore. If a key is
    // renamed or dropped here without anyone noticing, writes would silently
    // stop saving that field for every user going forward.
    test('toMap produces a map with the expected keys and role string', () {
      final createdAt = DateTime(2025, 6, 15);
      final user = User(
        id: 'u3',
        email: 'doc@example.com',
        firstName: 'Sarah',
        lastName: 'Kim',
        role: UserRole.doctor,
        createdAt: createdAt,
        isActive: false,
      );

      final map = user.toMap();

      expect(map['email'], 'doc@example.com');
      expect(map['firstName'], 'Sarah');
      expect(map['lastName'], 'Kim');
      expect(map['role'], 'doctor');
      expect(map['isActive'], false);
      expect(map['createdAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), createdAt);
    });

    // fromDocument is how every user profile in the app gets loaded from
    // Firestore. Using fake_cloud_firestore here lets us build a realistic
    // document/snapshot without touching a real Firebase project.
    test(
      'fromDocument correctly rebuilds a User from a Firestore-style document',
      () async {
        final firestore = FakeFirebaseFirestore();
        final createdAt = DateTime(2024, 3, 10);

        await firestore.collection('users').doc('doc123').set({
          'email': 'patient@example.com',
          'firstName': 'John',
          'lastName': 'Kamau',
          'role': 'patient',
          'createdAt': Timestamp.fromDate(createdAt),
          'isActive': true,
        });

        final snapshot =
            await firestore.collection('users').doc('doc123').get();
        final user = User.fromDocument(snapshot);

        expect(user.id, 'doc123');
        expect(user.email, 'patient@example.com');
        expect(user.fullName, 'John Kamau');
        expect(user.role, UserRole.patient);
        expect(user.createdAt, createdAt);
        expect(user.isActive, isTrue);
      },
    );

    // Real-world safety net: not every document in Firestore will have
    // every field (older records, manual edits, partial writes). This
    // confirms fromDocument never crashes and falls back to sane defaults.
    test(
      'fromDocument fills in safe defaults when fields are missing',
      () async {
        final firestore = FakeFirebaseFirestore();

        // Deliberately incomplete document — simulates older/malformed data.
        await firestore.collection('users').doc('incomplete').set({
          'email': 'partial@example.com',
        });

        final snapshot =
            await firestore.collection('users').doc('incomplete').get();
        final user = User.fromDocument(snapshot);

        expect(user.firstName, '');
        expect(user.lastName, '');
        expect(user.role, UserRole.patient); // default fallback
        expect(user.isActive, isTrue); // default fallback
      },
    );

    // The ultimate correctness check: whatever we write to Firestore via
    // toMap() must come back out identical via fromDocument(). If these
    // two ever drift apart, data would quietly get corrupted on every save.
    test('toMap -> fromDocument round trip preserves all field values', () async {
      final firestore = FakeFirebaseFirestore();
      final original = User(
        id: 'roundtrip',
        email: 'round@example.com',
        firstName: 'Round',
        lastName: 'Trip',
        role: UserRole.admin,
        createdAt: DateTime(2025, 2, 20),
        isActive: false,
      );

      await firestore
          .collection('users')
          .doc('roundtrip')
          .set(original.toMap());

      final snapshot =
          await firestore.collection('users').doc('roundtrip').get();
      final rebuilt = User.fromDocument(snapshot);

      expect(rebuilt.email, original.email);
      expect(rebuilt.fullName, original.fullName);
      expect(rebuilt.role, original.role);
      expect(rebuilt.isActive, original.isActive);
      expect(rebuilt.createdAt, original.createdAt);
    });
  });
}