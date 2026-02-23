import '../../theme/app_theme.dart';
import 'package:flutter/material.dart';

// lib/data/company_data.dart
class CompanyData {
  static Map<String, Map<String, dynamic>> companies = {
    'indonesia': {
      'flag': '🇮🇩',
      'name': 'ATOM INDONESIA',
      'city': 'Jakarta',
      'employees': '128 employees',
      'color': Color(0xFFFF6B6B),
    },
    'india': {
      'flag': '🇮🇳',
      'name': 'ATOM INDIA',
      'city': 'Mumbai',
      'employees': '256 employees',
      'color': Color(0xFFFFA06B),
    },
    'vietnam': {
      'flag': '🇻🇳',
      'name': 'ATOM VIETNAM',
      'city': 'Ho Chi Minh',
      'employees': '64 employees',
      'color': Color(0xFF6BCBFF),
    },
  };

  static Map<String, dynamic> getCompany(String companyId) {
    return companies[companyId.toLowerCase()] ?? {
      'flag': '🏢',
      'name': 'ATOM ${companyId.toUpperCase()}',
      'city': 'Headquarters',
      'employees': '0 employees',
      'color': AppTheme.primaryColor,
    };
  }
}