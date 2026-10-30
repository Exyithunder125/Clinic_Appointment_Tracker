import 'dart:io';


// CODE REUSE
mixin Loggable {
  String get logTag;

  void log(String message) {
    print('  [$logTag] $message');
  }
}

// CUSTOM EXCEPTION
class AppointmentException implements Exception {
  final String message;
  AppointmentException(this.message);

  @override
  String toString() => 'AppointmentException: $message';
}

// ABSTRACT CLASS
abstract class Person {
  final String id;
  final String name;

  Person(this.id, this.name);


  String describe();

  @override
  String toString() => describe();
}

// INHERITANCE
class Patient extends Person with Loggable {
  final int age;
  final List<Appointment> history = [];

  Patient(String id, String name, this.age) : super(id, name);

  @override
  String get logTag => 'PATIENT';

  void addToHistory(Appointment appt) {
    history.add(appt);
    log('$name now has ${history.length} appointment(s) on record.');
  }

  @override
  String describe() => 'Patient #$id: $name, $age yrs old';
}

class Doctor extends Person with Loggable {
  final String specialty;
  final double consultationFee; // in PHP
  final List<String> availableSlots;

  Doctor(
    String id,
    String name,
    this.specialty,
    this.consultationFee,
    List<String> slots,
  ) : availableSlots = List<String>.from(slots),
      super(id, name);

  @override
  String get logTag => 'DOCTOR';

  bool isAvailable(String slot) => availableSlots.contains(slot);

  void reserveSlot(String slot) {
    availableSlots.remove(slot);
    log('Dr. $name slot $slot reserved.');
  }

  void releaseSlot(String slot) {
    availableSlots.add(slot);
    log('Dr. $name slot $slot is open again.');
  }

  @override
  String describe() =>
      '[$id] Dr. $name ($specialty) - PHP ${consultationFee.toStringAsFixed(2)} '
      '| Slots: ${availableSlots.isEmpty ? "FULL" : availableSlots.join(", ")}';
}


// Appointment record
enum AppointmentStatus { booked, cancelled }

class Appointment {
  final String id;
  final Patient patient;
  final Doctor doctor;
  final String slot;
  AppointmentStatus status;

  Appointment(this.id, this.patient, this.doctor, this.slot)
    : status = AppointmentStatus.booked;

  void cancel() {
    status = AppointmentStatus.cancelled;
  }

  @override
  String toString() =>
      '[$id] ${patient.name} with Dr. ${doctor.name} at $slot '
      '(${status.name.toUpperCase()})';
}

// SERVICE CLASS
class ClinicService with Loggable {
  final List<Doctor> doctors = [];
  final List<Patient> patients = [];
  final List<Appointment> appointments = [];
  int _apptCounter = 0;
  int _patientCounter = 0;

  ClinicService();

  @override
  String get logTag => 'CLINIC';

  // Simulates loading data from a server/database.
  Future<void> loadData() async {
    log('Loading clinic data...');
    await Future.delayed(Duration(seconds: 2));

    doctors.addAll([
      Doctor('D1', 'Jenrick Bejarin', 'Pediatrics', 800, ['9:00 AM', '10:00 AM']),
      Doctor('D2', 'Remelyn Perales', 'Cardiology', 1500, ['1:00 PM', '2:00 PM']),
      Doctor('D3', 'Jessica Flores', 'Dermatology', 1000, ['11:00 AM']),
      Doctor('D4', 'Faith Gabao', 'Ophthalmologists', 2000, ['12:00 PM', '3:00PM']),
    ]);

    patients.addAll([
      Patient('P1', 'Juan Dela Pena', 28),
      Patient('P2', 'Liza Mercado', 7),
      Patient('P3', 'Pedro Ramos', 54),
    ]);
    _patientCounter = patients.length;

    log('Data loaded: ${doctors.length} doctors, ${patients.length} patients.');
  }

  Patient findPatient(String id) {
    return patients.firstWhere(
      (p) => p.id == id,
      orElse: () => throw AppointmentException('Patient "$id" not found.'),
    );
  }

  Doctor findDoctor(String id) {
    return doctors.firstWhere(
      (d) => d.id == id,
      orElse: () => throw AppointmentException('Doctor "$id" not found.'),
    );
  }

  // Simulates saving a new patient record.
  Future<Patient> registerPatient(String name, int age) async {
    log('Registering patient...');
    await Future.delayed(Duration(milliseconds: 800));

    if (name.trim().isEmpty) {
      throw AppointmentException('Name cannot be empty.');
    }
    if (age <= 0 || age > 120) {
      throw AppointmentException('Age must be between 1 and 120.');
    }

    _patientCounter++;
    final patient = Patient('P$_patientCounter', name.trim(), age);
    patients.add(patient);
    log('Registered: $patient');
    return patient;
  }

  // Simulates a network request that may fail.
  Future<Appointment> bookAppointment(
    String patientId,
    String doctorId,
    String slot,
  ) async {
    log('Booking appointment...');
    await Future.delayed(Duration(seconds: 1));

    final patient = findPatient(patientId);
    final doctor = findDoctor(doctorId);

    if (!doctor.isAvailable(slot)) {
      throw AppointmentException(
        'Dr. ${doctor.name} is not available at $slot.',
      );
    }

    doctor.reserveSlot(slot);
    _apptCounter++;
    final appt = Appointment('A$_apptCounter', patient, doctor, slot);
    appointments.add(appt);
    patient.addToHistory(appt);

    log('Booked! Fee: PHP ${doctor.consultationFee.toStringAsFixed(2)}');
    return appt;
  }

  Future<void> cancelAppointment(String appointmentId) async {
    log('Cancelling $appointmentId...');
    await Future.delayed(Duration(milliseconds: 800));

    final appt = appointments.firstWhere(
      (a) => a.id == appointmentId,
      orElse: () =>
          throw AppointmentException('Appointment "$appointmentId" not found.'),
    );

    if (appt.status == AppointmentStatus.cancelled) {
      throw AppointmentException('$appointmentId is already cancelled.');
    }

    appt.cancel();
    appt.doctor.releaseSlot(appt.slot);
    log('Cancelled: $appt');
  }

  void showDoctors() {
    print('\n--- Doctors ---');
    for (final d in doctors) {
      print(d);
    }
  }

  void showPatients() {
    print('\n--- Patients ---');
    for (final p in patients) {
      print(p);
    }
  }

  void showAppointments() {
    print('\n--- All Appointments ---');
    if (appointments.isEmpty) {
      print('No appointments yet.');
      return;
    }
    for (final a in appointments) {
      print(a);
    }
  }
}

// INPUT HELPER
String? ask(String label) {
  stdout.write('$label ');
  final input = stdin.readLineSync();
  return input?.trim();
}

void printMenu() {
  print('\n=====================================');
  print('   BAYANIHAN CLINIC - MAIN MENU');
  print('=====================================');
  print('1. View doctors');
  print('2. View patients');
  print('3. Register new patient');
  print('4. Book appointment');
  print('5. Cancel appointment');
  print('6. View all appointments');
  print('0. Exit');
}

// MENU ACTIONS
Future<void> registerFlow(ClinicService clinic) async {
  final name = ask('Patient name:');
  if (name == null) return;
  final ageText = ask('Age:');
  if (ageText == null) return;

  final age = int.tryParse(ageText);
  if (age == null) {
    throw AppointmentException('Age must be a whole number.');
  }
  await clinic.registerPatient(name, age);
}

Future<void> bookFlow(ClinicService clinic) async {
  clinic.showPatients();
  final patientId = ask('\nEnter patient ID (e.g. P1):')?.toUpperCase();
  if (patientId == null) return;
  clinic.findPatient(patientId); // fail early if invalid

  clinic.showDoctors();
  final doctorId = ask('\nEnter doctor ID (e.g. D1):')?.toUpperCase();
  if (doctorId == null) return;
  final doctor = clinic.findDoctor(doctorId);

  if (doctor.availableSlots.isEmpty) {
    throw AppointmentException('Dr. ${doctor.name} is fully booked.');
  }

  print('\nAvailable slots for Dr. ${doctor.name}:');
  for (var i = 0; i < doctor.availableSlots.length; i++) {
    print('  ${i + 1}. ${doctor.availableSlots[i]}');
  }
  final choiceText = ask('Choose a slot number:');
  if (choiceText == null) return;

  final choice = int.tryParse(choiceText);
  if (choice == null || choice < 1 || choice > doctor.availableSlots.length) {
    throw AppointmentException('Invalid slot choice "$choiceText".');
  }

  final slot = doctor.availableSlots[choice - 1];
  final appt = await clinic.bookAppointment(patientId, doctorId, slot);
  print('\nConfirmed: $appt');
}

Future<void> cancelFlow(ClinicService clinic) async {
  clinic.showAppointments();
  if (clinic.appointments.isEmpty) return;

  final id = ask('\nEnter appointment ID to cancel (e.g. A1):')?.toUpperCase();
  if (id == null) return;
  await clinic.cancelAppointment(id);
}

// MAIN
Future<void> main() async {
  print('=====================================');
  print('   BAYANIHAN CLINIC - APPOINTMENTS   ');
  print('=====================================\n');

  final clinic = ClinicService();

  try {
    await clinic.loadData();
  } catch (e) {
    print('[FATAL] Could not load clinic data: $e');
    return;
  }

  var running = true;
  while (running) {
    printMenu();
    final choice = ask('\nChoose an option:');

    // null means input ended and exit cleanly instead of crashing.
    if (choice == null) {
      print('\nNo more input. Exiting...');
      break;
    }

    try {
      switch (choice) {
        case '1':
          clinic.showDoctors();
          break;
        case '2':
          clinic.showPatients();
          break;
        case '3':
          await registerFlow(clinic);
          break;
        case '4':
          await bookFlow(clinic);
          break;
        case '5':
          await cancelFlow(clinic);
          break;
        case '6':
          clinic.showAppointments();
          break;
        case '0':
          running = false;
          break;
        default:
          print('Invalid option. Please enter a number from 0 to 6.');
      }
    } on AppointmentException catch (e) {
      print('\n[ERROR] $e');
    } catch (e) {
      print('\n[UNEXPECTED ERROR] $e');
    }
  }

  print('\nThank you for using Bayanihan Clinic. Goodbye!');
}
