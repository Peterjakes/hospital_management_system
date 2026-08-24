import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hospital_management_system/models/appointment_model.dart';

void main() {
  // These enums drive status badges, filtering, and workflow logic across
  // doctor/patient/admin screens. A wrong mapping here could show a patient
  // the wrong appointment status or let a cancelled appointment look active.
  group('AppointmentStatusExtension', () {
    test('value maps each status to its correct storage string', () {
      expect(AppointmentStatus.scheduled.value, 'scheduled');
      expect(AppointmentStatus.confirmed.value, 'confirmed');
      expect(AppointmentStatus.inProgress.value, 'in_progress');
      expect(AppointmentStatus.completed.value, 'completed');
      expect(AppointmentStatus.cancelled.value, 'cancelled');
      expect(AppointmentStatus.noShow.value, 'no_show');
    });

    test('fromString parses valid strings back into the correct enum', () {
      expect(AppointmentStatusExtension.fromString('confirmed'),
          AppointmentStatus.confirmed);
      expect(AppointmentStatusExtension.fromString('no_show'),
          AppointmentStatus.noShow);
    });

    // Documents the existing fallback behavior: an unrecognized status
    // string becomes "scheduled" rather than crashing. Worth knowing this
    // is intentional, since a silent fallback to "scheduled" could make a
    // broken/corrupted appointment look perfectly normal in the UI.
    test('fromString defaults unknown values to scheduled', () {
      expect(AppointmentStatusExtension.fromString('bogus_status'),
          AppointmentStatus.scheduled);
    });
  });

  // Payment status drives whether a patient can proceed with a consultation
  // and whether the M-Pesa payment flow shows as complete. Getting this
  // wrong could let someone see a doctor without having actually paid.
  group('PaymentStatusExtension', () {
    test('value maps each status to its correct storage string', () {
      expect(PaymentStatus.pending.value, 'pending');
      expect(PaymentStatus.paid.value, 'paid');
      expect(PaymentStatus.failed.value, 'failed');
      expect(PaymentStatus.refunded.value, 'refunded');
    });

    test('fromString defaults unknown values to pending', () {
      expect(PaymentStatusExtension.fromString('nonsense'),
          PaymentStatus.pending);
    });
  });

  // Shared helper so every test below only needs to specify the fields
  // it actually cares about, instead of repeating the full constructor.
  Appointment buildAppointment({
    AppointmentStatus status = AppointmentStatus.scheduled,
    PaymentStatus paymentStatus = PaymentStatus.pending,
    DateTime? appointmentDate,
    String appointmentTime = '10:00',
    double consultationFee = 500,
    double? paymentAmount,
    String? paymentReference,
    String? paymentId,
  }) {
    final now = DateTime.now();
    return Appointment(
      id: 'a1',
      patientId: 'p1',
      doctorId: 'd1',
      departmentId: 'dept1',
      appointmentDate: appointmentDate ?? now,
      appointmentTime: appointmentTime,
      status: status,
      reasonForVisit: 'Checkup',
      consultationFee: consultationFee,
      paymentStatus: paymentStatus,
      paymentAmount: paymentAmount,
      paymentReference: paymentReference,
      paymentId: paymentId,
      createdAt: now,
      updatedAt: now,
    );
  }

  // These getters power what patients/doctors actually see and can do —
  // e.g. whether a "Cancel" button shows up, or whether an appointment
  // counts as "upcoming" on a dashboard. Bugs here are user-facing bugs.
  group('Appointment computed getters', () {
    test('isUpcoming is true for a future scheduled appointment', () {
      final future = DateTime.now().add(const Duration(days: 3));
      final appointment = buildAppointment(
        appointmentDate: future,
        appointmentTime: '14:30',
        status: AppointmentStatus.scheduled,
      );

      expect(appointment.isUpcoming, isTrue);
    });

    test('isUpcoming is false for a past appointment', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      final appointment = buildAppointment(
        appointmentDate: past,
        appointmentTime: '09:00',
        status: AppointmentStatus.scheduled,
      );

      expect(appointment.isUpcoming, isFalse);
    });

    // A completed appointment shouldn't appear as "upcoming" even if its
    // original date happens to be in the future (e.g. data was edited).
    test('isUpcoming is false when status is completed, even if in the future',
        () {
      final future = DateTime.now().add(const Duration(days: 3));
      final appointment = buildAppointment(
        appointmentDate: future,
        appointmentTime: '14:30',
        status: AppointmentStatus.completed,
      );

      expect(appointment.isUpcoming, isFalse);
    });

    test('isToday is true when appointmentDate matches today\'s date', () {
      final appointment = buildAppointment(appointmentDate: DateTime.now());
      expect(appointment.isToday, isTrue);
    });

    test('isToday is false for a different day', () {
      final appointment = buildAppointment(
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
      );
      expect(appointment.isToday, isFalse);
    });

    // Determines whether the "Cancel appointment" action is available —
    // a patient/doctor should never be able to cancel something already
    // completed or already cancelled.
    test('canBeCancelled is true for scheduled and confirmed statuses', () {
      expect(
        buildAppointment(status: AppointmentStatus.scheduled)
            .canBeCancelled,
        isTrue,
      );
      expect(
        buildAppointment(status: AppointmentStatus.confirmed)
            .canBeCancelled,
        isTrue,
      );
    });

    test(
      'canBeCancelled is false for completed, cancelled, and inProgress statuses',
      () {
        expect(
          buildAppointment(status: AppointmentStatus.completed)
              .canBeCancelled,
          isFalse,
        );
        expect(
          buildAppointment(status: AppointmentStatus.cancelled)
              .canBeCancelled,
          isFalse,
        );
        expect(
          buildAppointment(status: AppointmentStatus.inProgress)
              .canBeCancelled,
          isFalse,
        );
      },
    );

    // Money formatting shown directly to patients — a rounding or currency
    // display bug here is the kind of thing that erodes trust fast.
    test('formattedFee formats consultationFee as whole-number KSh', () {
      final appointment = buildAppointment(consultationFee: 1500.75);
      expect(appointment.formattedFee, 'KSh 1501');
    });

    test('formattedPaymentAmount falls back to consultationFee when null',
        () {
      final appointment =
          buildAppointment(consultationFee: 500, paymentAmount: null);
      expect(appointment.formattedPaymentAmount, 'KSh 500');
    });

    test('formattedPaymentAmount uses paymentAmount when present', () {
      final appointment =
          buildAppointment(consultationFee: 500, paymentAmount: 450);
      expect(appointment.formattedPaymentAmount, 'KSh 450');
    });

    // Flags cases where what was actually paid via M-Pesa doesn't match
    // the expected consultation fee — important for catching underpayment
    // or M-Pesa rounding issues before they become a billing dispute.
    test('hasPaymentDiscrepancy is false when amounts match', () {
      final appointment =
          buildAppointment(consultationFee: 500, paymentAmount: 500);
      expect(appointment.hasPaymentDiscrepancy, isFalse);
    });

    test('hasPaymentDiscrepancy is true when amounts differ meaningfully',
        () {
      final appointment =
          buildAppointment(consultationFee: 500, paymentAmount: 300);
      expect(appointment.hasPaymentDiscrepancy, isTrue);
    });

    // M-Pesa amounts can have tiny floating-point rounding differences —
    // this confirms we don't flag a false discrepancy over a fraction of a cent.
    test('hasPaymentDiscrepancy tolerates tiny rounding differences', () {
      final appointment =
          buildAppointment(consultationFee: 500, paymentAmount: 500.005);
      expect(appointment.hasPaymentDiscrepancy, isFalse);
    });

    test('hasPaymentDiscrepancy is false when paymentAmount is null', () {
      final appointment =
          buildAppointment(consultationFee: 500, paymentAmount: null);
      expect(appointment.hasPaymentDiscrepancy, isFalse);
    });

    // Confirms the app correctly labels how someone paid, which matters
    // for admin reporting and for patients reviewing their payment history.
    test('paymentMethodDisplay shows M-Pesa when paymentReference is set',
        () {
      final appointment =
          buildAppointment(paymentReference: 'ws_CO_123456');
      expect(appointment.paymentMethodDisplay, 'M-Pesa');
    });

    test(
      'paymentMethodDisplay shows Other when only paymentId is set (no M-Pesa reference)',
      () {
        final appointment = buildAppointment(paymentId: 'generic-id-1');
        expect(appointment.paymentMethodDisplay, 'Other');
      },
    );

    test(
      'paymentMethodDisplay shows Not Specified when neither reference nor id is set',
      () {
        final appointment = buildAppointment();
        expect(appointment.paymentMethodDisplay, 'Not Specified');
      },
    );

    test('isPaymentCompleted, isPaymentPending, hasPaymentFailed reflect paymentStatus',
        () {
      final paid = buildAppointment(paymentStatus: PaymentStatus.paid);
      final pending = buildAppointment(paymentStatus: PaymentStatus.pending);
      final failed = buildAppointment(paymentStatus: PaymentStatus.failed);

      expect(paid.isPaymentCompleted, isTrue);
      expect(paid.isPaymentPending, isFalse);

      expect(pending.isPaymentPending, isTrue);
      expect(pending.isPaymentCompleted, isFalse);

      expect(failed.hasPaymentFailed, isTrue);
      expect(failed.isPaymentCompleted, isFalse);
    });
  });

  // This is the most important group in the file. appointment_model.dart
  // has to support OLD documents (that only ever had an "isPaid" boolean)
  // and NEW documents (that use the richer "paymentStatus" enum). Getting
  // this backward-compatibility logic wrong could make old, already-paid
  // appointments suddenly look unpaid, or vice versa.
  group('Appointment.fromDocument backward compatibility', () {
    test(
      'derives paymentStatus=paid from legacy isPaid:true when paymentStatus field is absent',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('appointments').doc('legacy1').set({
          'patientId': 'p1',
          'doctorId': 'd1',
          'departmentId': 'dept1',
          'appointmentDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
          'appointmentTime': '10:00',
          'reasonForVisit': 'Checkup',
          'consultationFee': 500,
          'isPaid': true,
          // no 'paymentStatus' field — simulates data written before that
          // field existed in the schema.
          'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
          'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        });

        final snapshot =
            await firestore.collection('appointments').doc('legacy1').get();
        final appointment = Appointment.fromDocument(snapshot);

        expect(appointment.paymentStatus, PaymentStatus.paid);
        expect(appointment.isPaid, isTrue);
      },
    );

    // If a document somehow has both fields and they disagree, the newer,
    // more specific field should win — otherwise a manually corrected
    // paymentStatus could get silently overridden by a stale isPaid flag.
    test(
      'prefers explicit paymentStatus field over legacy isPaid when both are present',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('appointments').doc('modern1').set({
          'patientId': 'p1',
          'doctorId': 'd1',
          'departmentId': 'dept1',
          'appointmentDate': Timestamp.fromDate(DateTime(2025, 5, 1)),
          'appointmentTime': '10:00',
          'reasonForVisit': 'Checkup',
          'consultationFee': 500,
          'isPaid': true, // stale/incorrect legacy flag
          'paymentStatus': 'failed', // this should win
          'createdAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
          'updatedAt': Timestamp.fromDate(DateTime(2025, 5, 1)),
        });

        final snapshot =
            await firestore.collection('appointments').doc('modern1').get();
        final appointment = Appointment.fromDocument(snapshot);

        expect(appointment.paymentStatus, PaymentStatus.failed);
        expect(appointment.isPaid, isFalse);
      },
    );

    test('fills in safe defaults for a minimal/incomplete document', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('appointments').doc('minimal').set({
        'patientId': 'p1',
        'doctorId': 'd1',
        'departmentId': 'dept1',
        'appointmentTime': '11:00',
        'reasonForVisit': 'Follow-up',
      });

      final snapshot =
          await firestore.collection('appointments').doc('minimal').get();
      final appointment = Appointment.fromDocument(snapshot);

      expect(appointment.status, AppointmentStatus.scheduled);
      expect(appointment.consultationFee, 0.0);
      expect(appointment.paymentStatus, PaymentStatus.pending);
      expect(appointment.isPaid, isFalse);
    });
  });

  // The ultimate correctness check for this model: whatever gets written
  // to Firestore via toMap() must come back identical via fromDocument().
  group('Appointment toMap -> fromDocument round trip', () {
    test('preserves core fields and status/payment enums through a full round trip',
        () async {
      final firestore = FakeFirebaseFirestore();
      final original = buildAppointment(
        status: AppointmentStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        appointmentDate: DateTime(2025, 8, 20),
        appointmentTime: '13:00',
        consultationFee: 800,
        paymentAmount: 800,
        paymentReference: 'ws_CO_999',
      );

      await firestore
          .collection('appointments')
          .doc('roundtrip')
          .set(original.toMap());

      final snapshot = await firestore
          .collection('appointments')
          .doc('roundtrip')
          .get();
      final rebuilt = Appointment.fromDocument(snapshot);

      expect(rebuilt.status, original.status);
      expect(rebuilt.paymentStatus, original.paymentStatus);
      expect(rebuilt.consultationFee, original.consultationFee);
      expect(rebuilt.paymentAmount, original.paymentAmount);
      expect(rebuilt.paymentReference, original.paymentReference);
      expect(rebuilt.appointmentTime, original.appointmentTime);
    });
  });
}