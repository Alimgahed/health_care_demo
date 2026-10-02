import 'package:flutter/material.dart';

class TherapySession {
  final String id;
  final int sessionNumber;
  final DateTime scheduledDate;
  bool isAttended;
  double? weightAfter;
  double? heightAfter;
  String? notes;

  TherapySession({
    required this.id,
    required this.sessionNumber,
    required this.scheduledDate,
    this.isAttended = false,
    this.weightAfter,
    this.heightAfter,
    this.notes,
  });
}

class HomeExercise {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final String category;
  final int durationMinutes;
  final int sets;
  final int reps;
  final String iconPath;
  List<DateTime> completedDates;

  HomeExercise({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.category,
    required this.durationMinutes,
    required this.sets,
    required this.reps,
    required this.iconPath,
    List<DateTime>? completedDates,
  }) : completedDates = completedDates ?? [];
}

class MedicationLog {
  final String id;
  final String patientId;
  final DateTime scheduledTime;
  bool confirmed;
  DateTime? confirmedAt;

  MedicationLog({
    required this.id,
    required this.patientId,
    required this.scheduledTime,
    this.confirmed = false,
    this.confirmedAt,
  });
}

class TreatmentPlan {
  final String id;
  final String patientId;
  final String doctorName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Medication
  final String medicationDose;
  final int medicationFrequencyDays;
  final int medicationQuantity;
  final String prescriptionId;
  final DateTime prescriptionValidUntil;
  final List<TimeOfDay> reminderTimes;

  // Therapy
  final String? assignedCenterId;
  final int totalSessions;
  final List<TherapySession> sessions;

  // Home Exercises
  final List<HomeExercise> homeExercises;

  // Goals
  final double targetWeight;
  final String status; // "Active", "Completed", "Paused"
  /// "approved" = ready for dispensing; "pending_review" = awaiting clinical sign-off.
  final String clinicalApprovalStatus;

  TreatmentPlan({
    required this.id,
    required this.patientId,
    required this.doctorName,
    required this.createdAt,
    this.updatedAt,
    required this.medicationDose,
    required this.medicationFrequencyDays,
    this.medicationQuantity = 1,
    String? prescriptionId,
    DateTime? prescriptionValidUntil,
    required this.reminderTimes,
    this.assignedCenterId,
    this.totalSessions = 0,
    required this.sessions,
    required this.homeExercises,
    required this.targetWeight,
    this.status = "Active",
    this.clinicalApprovalStatus = "approved",
  }) : prescriptionId = prescriptionId ?? 'RX-$id',
       prescriptionValidUntil =
           prescriptionValidUntil ?? createdAt.add(const Duration(days: 365));

  TreatmentPlan copyWith({
    DateTime? updatedAt,
    String? clinicalApprovalStatus,
    String? status,
    String? medicationDose,
    int? medicationFrequencyDays,
    int? medicationQuantity,
    String? prescriptionId,
    DateTime? prescriptionValidUntil,
  }) {
    return TreatmentPlan(
      id: id,
      patientId: patientId,
      doctorName: doctorName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      medicationDose: medicationDose ?? this.medicationDose,
      medicationFrequencyDays:
          medicationFrequencyDays ?? this.medicationFrequencyDays,
      medicationQuantity: medicationQuantity ?? this.medicationQuantity,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      prescriptionValidUntil:
          prescriptionValidUntil ?? this.prescriptionValidUntil,
      reminderTimes: reminderTimes,
      assignedCenterId: assignedCenterId,
      totalSessions: totalSessions,
      sessions: sessions,
      homeExercises: homeExercises,
      targetWeight: targetWeight,
      status: status ?? this.status,
      clinicalApprovalStatus:
          clinicalApprovalStatus ?? this.clinicalApprovalStatus,
    );
  }
}
