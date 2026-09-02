import 'package:flutter/material.dart';
import 'models.dart';

class AppColors {
  static const Color brandBlue = Color(0xFF0B2A7A);
  static const Color brandBlueSoft = Color(0xFFEAF0FB);

  static const Color accentBlue = Color(0xFF2F5D8C);
  static const Color accentBlueSoft = Color(0xFFEAF1F7);

  static const Color neutralDark = Color(0xFF1F2937);
  static const Color neutralMedium = Color(0xFF374151);
  static const Color neutralSoft = Color(0xFF6B7280);

  static const Color surface = Color(0xFFF7F8FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF1F4F8);

  static const Color taupe = Color(0xFF6B5B4D);
  static const Color taupeSoft = Color(0xFFF3EEE8);

  // Verde-azulado do logo — usado no destaque "Registar" e no tipo Fitness.
  static const Color brandGreen = Color(0xFF1F8A6B);
  static const Color brandGreenSoft = Color(0xFFE3F3EE);

  static const Color success = Color(0xFF1F8A4D);
  static const Color warning = Color(0xFFB7791F);
}

/// Cor de destaque associada a cada Tipo de Atividade — usada para
/// diferenciar visualmente alunos/disciplinas quando o tipo de atividade
/// global é alterado mas ainda existem registos de tipos anteriores.
Color colorForActivityType(ActivityType type) {
  switch (type) {
    case ActivityType.education:
      return AppColors.brandBlue;
    case ActivityType.fitness:
      return AppColors.brandGreen;
    case ActivityType.health:
      return AppColors.neutralMedium;
    case ActivityType.otherServices:
      return AppColors.taupe;
  }
}

/// Símbolo associado a cada Tipo de Atividade — usado no ecrã inicial, nas
/// Definições, e na lista de Disciplinas/Aulas.
IconData iconForActivityType(ActivityType type) {
  switch (type) {
    case ActivityType.education:
      return Icons.school_outlined;
    case ActivityType.fitness:
      return Icons.fitness_center_outlined;
    case ActivityType.health:
      return Icons.favorite_border;
    case ActivityType.otherServices:
      return Icons.work_outline;
  }
}
