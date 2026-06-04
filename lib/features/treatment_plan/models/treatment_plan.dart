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
  
  // Medication
  final String medicationDose;
  final int medicationFrequencyDays;
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
    required this.medicationDose,
    required this.medicationFrequencyDays,
    required this.reminderTimes,
    this.assignedCenterId,
    this.totalSessions = 0,
    required this.sessions,
    required this.homeExercises,
    required this.targetWeight,
    this.status = "Active",
    this.clinicalApprovalStatus = "approved",
  });

  TreatmentPlan copyWith({
    String? clinicalApprovalStatus,
    String? status,
    String? medicationDose,
    int? medicationFrequencyDays,
  }) {
    return TreatmentPlan(
      id: id,
      patientId: patientId,
      doctorName: doctorName,
      createdAt: createdAt,
      medicationDose: medicationDose ?? this.medicationDose,
      medicationFrequencyDays: medicationFrequencyDays ?? this.medicationFrequencyDays,
      reminderTimes: reminderTimes,
      assignedCenterId: assignedCenterId,
      totalSessions: totalSessions,
      sessions: sessions,
      homeExercises: homeExercises,
      targetWeight: targetWeight,
      status: status ?? this.status,
      clinicalApprovalStatus: clinicalApprovalStatus ?? this.clinicalApprovalStatus,
    );
  }
}
