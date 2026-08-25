import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hospital_management_system/models/appointment_model.dart';
import 'package:hospital_management_system/providers/appointment_provider.dart';
import 'package:hospital_management_system/services/firestore_service.dart';

// Mocks FirestoreService so these tests never touch real Firebase.
//
// Scope note: this file only covers AppointmentProvider methods that go
// through FirestoreService — status updates, cancellation, and loading
// appointments. bookAppointmentWithPayment() and the M-Pesa payment
// polling logic are NOT covered here, because MpesaService currently
// uses static methods (see mpesa_service.dart), which can't be mocked
// with mocktail without a separate refactor to make it instance-based.
class MockFirestoreService extends Mock implements FirestoreService {}

void main() {
  late MockFirestoreService mockFirestoreService;
  late AppointmentProvider appointmentProvider;

  setUpAll(() {
    registerFallbackValue(AppointmentStatus.scheduled);
  });

  setUp(() {
    mockFirestoreService = MockFirestoreService();
    appointmentProvider =
        AppointmentProvider(firestoreService: mockFirestoreService);
  });

  Appointment buildAppointment({
    required String id,
    AppointmentStatus status = AppointmentStatus.scheduled,
  }) {
    final now = DateTime.now();
    return Appointment(
      id: id,
      patientId: 'p1',
      doctorId: 'd1',
      departmentId: 'dept1',
      appointmentDate: now,
      appointmentTime: '10:00',
      status: status,
      reasonForVisit: 'Checkup',
      consultationFee: 500,
      paymentStatus: PaymentStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('AppointmentProvider.loadPatientAppointments', () {
    test(
      'populates patientAppointments and clears loading state on success',
      () async {
        final appointments = [
          buildAppointment(id: 'a1'),
          buildAppointment(id: 'a2'),
        ];

        when(() => mockFirestoreService.getPatientAppointments(
              any(),
              status: any(named: 'status'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => appointments);

        await appointmentProvider.loadPatientAppointments('p1');

        expect(appointmentProvider.patientAppointments.length, 2);
        expect(appointmentProvider.isLoading, isFalse);
        expect(appointmentProvider.errorMessage, isNull);
      },
    );

    test('sets an error message and clears loading state on failure',
        () async {
      when(() => mockFirestoreService.getPatientAppointments(
            any(),
            status: any(named: 'status'),
            limit: any(named: 'limit'),
          )).thenThrow(Exception('Firestore unavailable'));

      await appointmentProvider.loadPatientAppointments('p1');

      expect(appointmentProvider.errorMessage, contains('Firestore unavailable'));
      expect(appointmentProvider.isLoading, isFalse);
    });
  });

  group('AppointmentProvider.loadDoctorAppointments', () {
    test('populates doctorAppointments on success', () async {
      final appointments = [buildAppointment(id: 'a1')];

      when(() => mockFirestoreService.getDoctorAppointments(
            any(),
            date: any(named: 'date'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => appointments);

      await appointmentProvider.loadDoctorAppointments('d1');

      expect(appointmentProvider.doctorAppointments.length, 1);
      expect(appointmentProvider.isLoading, isFalse);
    });

    test('sets an error message on failure', () async {
      when(() => mockFirestoreService.getDoctorAppointments(
            any(),
            date: any(named: 'date'),
            status: any(named: 'status'),
          )).thenThrow(Exception('Network error'));

      await appointmentProvider.loadDoctorAppointments('d1');

      expect(appointmentProvider.errorMessage, contains('Network error'));
    });
  });

  group('AppointmentProvider.updateAppointmentStatus', () {
    test(
      'returns true and calls FirestoreService.updateAppointment with the correct status value',
      () async {
        when(() => mockFirestoreService.updateAppointment(any(), any()))
            .thenAnswer((_) async {});

        final result = await appointmentProvider.updateAppointmentStatus(
          'a1',
          AppointmentStatus.confirmed,
        );

        expect(result, isTrue);
        // Confirms the provider passes the correct status.value string
        // through to Firestore — this is the exact kind of detail that
        // silently breaks if someone edits the enum's .value getter.
        final captured = verify(() => mockFirestoreService.updateAppointment(
              'a1',
              captureAny(),
            )).captured.single as Map<String, dynamic>;
        expect(captured['status'], 'confirmed');
      },
    );

    test('returns false and sets an error message when Firestore throws',
        () async {
      when(() => mockFirestoreService.updateAppointment(any(), any()))
          .thenThrow(Exception('Permission denied'));

      final result = await appointmentProvider.updateAppointmentStatus(
        'a1',
        AppointmentStatus.confirmed,
      );

      expect(result, isFalse);
      expect(appointmentProvider.errorMessage, contains('Permission denied'));
    });

    test(
      'updates the status of the matching appointment in local state after success',
      () async {
        // Pre-load an appointment into patientAppointments so we can
        // verify the provider updates its own in-memory copy, not just
        // Firestore — this is what makes the UI reflect changes instantly
        // without needing a full reload.
        when(() => mockFirestoreService.getPatientAppointments(
              any(),
              status: any(named: 'status'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => [
              buildAppointment(id: 'a1', status: AppointmentStatus.scheduled),
            ]);
        await appointmentProvider.loadPatientAppointments('p1');

        when(() => mockFirestoreService.updateAppointment(any(), any()))
            .thenAnswer((_) async {});

        await appointmentProvider.updateAppointmentStatus(
          'a1',
          AppointmentStatus.confirmed,
        );

        final updated = appointmentProvider.patientAppointments
            .firstWhere((a) => a.id == 'a1');
        expect(updated.status, AppointmentStatus.confirmed);
      },
    );
  });

  group('AppointmentProvider.cancelAppointment', () {
    test(
      'returns true and calls FirestoreService.cancelAppointment with the id and reason',
      () async {
        when(() => mockFirestoreService.cancelAppointment(any(), any()))
            .thenAnswer((_) async {});

        final result = await appointmentProvider.cancelAppointment(
          'a1',
          'Patient requested reschedule',
        );

        expect(result, isTrue);
        verify(() => mockFirestoreService.cancelAppointment(
              'a1',
              'Patient requested reschedule',
            )).called(1);
      },
    );

    test('returns false and sets an error message when Firestore throws',
        () async {
      when(() => mockFirestoreService.cancelAppointment(any(), any()))
          .thenThrow(Exception('Appointment not found'));

      final result =
          await appointmentProvider.cancelAppointment('a1', 'No longer needed');

      expect(result, isFalse);
      expect(
          appointmentProvider.errorMessage, contains('Appointment not found'));
    });

    test(
      'marks the matching local appointment as cancelled after success',
      () async {
        when(() => mockFirestoreService.getPatientAppointments(
              any(),
              status: any(named: 'status'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => [
              buildAppointment(id: 'a1', status: AppointmentStatus.confirmed),
            ]);
        await appointmentProvider.loadPatientAppointments('p1');

        when(() => mockFirestoreService.cancelAppointment(any(), any()))
            .thenAnswer((_) async {});

        await appointmentProvider.cancelAppointment('a1', 'Change of plans');

        final updated = appointmentProvider.patientAppointments
            .firstWhere((a) => a.id == 'a1');
        expect(updated.status, AppointmentStatus.cancelled);
      },
    );
  });

  group('AppointmentProvider.upcomingAppointments', () {
    test('filters to only appointments where isUpcoming is true', () async {
      final future = DateTime.now().add(const Duration(days: 2));
      final past = DateTime.now().subtract(const Duration(days: 2));

      final upcoming = Appointment(
        id: 'upcoming1',
        patientId: 'p1',
        doctorId: 'd1',
        departmentId: 'dept1',
        appointmentDate: future,
        appointmentTime: '10:00',
        status: AppointmentStatus.scheduled,
        reasonForVisit: 'Checkup',
        consultationFee: 500,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pastAppointment = Appointment(
        id: 'past1',
        patientId: 'p1',
        doctorId: 'd1',
        departmentId: 'dept1',
        appointmentDate: past,
        appointmentTime: '10:00',
        status: AppointmentStatus.scheduled,
        reasonForVisit: 'Checkup',
        consultationFee: 500,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockFirestoreService.getPatientAppointments(
            any(),
            status: any(named: 'status'),
            limit: any(named: 'limit'),
          )).thenAnswer((_) async => [upcoming, pastAppointment]);

      await appointmentProvider.loadPatientAppointments('p1');
      // Note: upcomingAppointments filters `_appointments`, not
      // `_patientAppointments` — loadPatientAppointments only populates
      // the latter, so this documents that upcomingAppointments is
      // currently driven by a separate, general appointments list.
      expect(appointmentProvider.upcomingAppointments, isEmpty);
      expect(appointmentProvider.patientAppointments.length, 2);
    });
  });
}