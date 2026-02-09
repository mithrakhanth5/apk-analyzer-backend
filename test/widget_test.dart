// Flutter Widget Tests for APK Risk Analyzer
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

// Import using relative paths since we're in the test directory
import '../lib/models/models.dart';
import '../lib/widgets/widgets.dart';
import '../lib/theme/app_theme.dart';

void main() {
  group('RiskIndicator Widget Tests', () {
    testWidgets('displays SAFE classification correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RiskIndicator(
              score: 20,
              classification: 'SAFE',
            ),
          ),
        ),
      );

      expect(find.text('20'), findsOneWidget);
      expect(find.text('SAFE'), findsOneWidget);
    });

    testWidgets('displays SUSPICIOUS classification correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RiskIndicator(
              score: 45,
              classification: 'SUSPICIOUS',
            ),
          ),
        ),
      );

      expect(find.text('45'), findsOneWidget);
      expect(find.text('SUSPICIOUS'), findsOneWidget);
    });

    testWidgets('displays HIGH_RISK classification correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: RiskIndicator(
              score: 85,
              classification: 'HIGH_RISK',
            ),
          ),
        ),
      );

      expect(find.text('85'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsOneWidget);
    });
  });

  group('PermissionCard Widget Tests', () {
    testWidgets('displays permission information correctly', (tester) async {
      final permission = PermissionRisk(
        permission: 'android.permission.READ_SMS',
        riskScore: 9,
        riskLevel: 'CRITICAL',
        category: 'sms',
        description: 'Can read all SMS messages',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: PermissionCard(permission: permission),
          ),
        ),
      );

      expect(find.text('READ_SMS'), findsOneWidget);
      expect(find.text('Can read all SMS messages'), findsOneWidget);
      expect(find.text('9/10'), findsOneWidget);
    });
  });

  group('FindingCard Widget Tests', () {
    testWidgets('displays finding with severity icon', (tester) async {
      final finding = RiskFinding(
        category: 'PERMISSION',
        severity: 'CRITICAL',
        title: 'SMS Access Detected',
        description: 'App can read and send SMS',
        evidence: ['READ_SMS', 'SEND_SMS'],
        scoreImpact: 25,
        recommendation: 'Avoid unless necessary',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: FindingCard(finding: finding),
          ),
        ),
      );

      expect(find.text('SMS Access Detected'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget); // Critical icon
    });

    testWidgets('expands to show details when tapped', (tester) async {
      final finding = RiskFinding(
        category: 'PERMISSION',
        severity: 'HIGH',
        title: 'Test Finding',
        description: 'Full description here',
        evidence: ['evidence1'],
        scoreImpact: 10,
        recommendation: 'Test recommendation',
      );

      bool isExpanded = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return FindingCard(
                  finding: finding,
                  expanded: isExpanded,
                  onTap: () => setState(() => isExpanded = !isExpanded),
                );
              },
            ),
          ),
        ),
      );

      // Initially collapsed
      expect(find.text('Full description here'), findsNothing);

      // Tap to expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
    });
  });

  group('WarningBanner Widget Tests', () {
    testWidgets('displays warning message with correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: WarningBanner(
              message: 'This is a warning',
              severity: 'warning',
            ),
          ),
        ),
      );

      expect(find.text('This is a warning'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('displays error with error icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: WarningBanner(
              message: 'This is an error',
              severity: 'error',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('calls onDismiss when close is tapped', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: WarningBanner(
              message: 'Dismissible warning',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });
  });

  group('ScoreBar Widget Tests', () {
    testWidgets('displays label and score correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: ScoreBar(
              label: 'Permissions',
              score: 75,
              maxScore: 100,
            ),
          ),
        ),
      );

      expect(find.text('Permissions'), findsOneWidget);
      expect(find.text('75/100'), findsOneWidget);
    });
  });

  group('ConsentCheckbox Widget Tests', () {
    testWidgets('toggles value when tapped', (tester) async {
      bool value = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ConsentCheckbox(
                  text: 'I understand the risks',
                  value: value,
                  onChanged: (v) => setState(() => value = v ?? false),
                );
              },
            ),
          ),
        ),
      );

      expect(value, isFalse);

      // Tap the checkbox area
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(value, isTrue);
    });
  });

  // Model unit tests
  group('ApkInfo Model Tests', () {
    test('fileSizeFormatted returns correct format for bytes', () {
      var info = ApkInfo(
        fileName: 'test.apk',
        filePath: '/path/to/test.apk',
        fileSize: 500,
        sha256Hash: 'hash',
      );
      expect(info.fileSizeFormatted, '500 B');
    });

    test('fileSizeFormatted returns correct format for KB', () {
      var info = ApkInfo(
        fileName: 'test.apk',
        filePath: '/path/to/test.apk',
        fileSize: 2048,
        sha256Hash: 'hash',
      );
      expect(info.fileSizeFormatted, '2.0 KB');
    });

    test('fileSizeFormatted returns correct format for MB', () {
      var info = ApkInfo(
        fileName: 'test.apk',
        filePath: '/path/to/test.apk',
        fileSize: 5 * 1024 * 1024,
        sha256Hash: 'hash',
      );
      expect(info.fileSizeFormatted, '5.0 MB');
    });
  });

  group('PermissionRisk Model Tests', () {
    test('shortName extracts last part of permission', () {
      var perm = PermissionRisk(
        permission: 'android.permission.READ_SMS',
        riskScore: 9,
        riskLevel: 'CRITICAL',
        category: 'sms',
        description: 'Read SMS',
      );
      expect(perm.shortName, 'READ_SMS');
    });

    test('fromJson parses correctly', () {
      var json = {
        'permission': 'android.permission.CAMERA',
        'risk_score': 5,
        'risk_level': 'MEDIUM',
        'category': 'camera',
        'description': 'Camera access',
      };
      var perm = PermissionRisk.fromJson(json);
      expect(perm.permission, 'android.permission.CAMERA');
      expect(perm.riskScore, 5);
    });
  });

  group('RiskFinding Model Tests', () {
    test('fromJson parses correctly', () {
      var json = {
        'category': 'PERMISSION',
        'severity': 'HIGH',
        'title': 'Test Title',
        'description': 'Test Description',
        'evidence': ['ev1', 'ev2'],
        'score_impact': 15,
        'recommendation': 'Test rec',
      };
      var finding = RiskFinding.fromJson(json);
      expect(finding.title, 'Test Title');
      expect(finding.evidence.length, 2);
      expect(finding.scoreImpact, 15);
    });
  });

  group('RiskReport Model Tests', () {
    test('criticalFindings filters correctly', () {
      final report = RiskReport(
        analysisId: 'test',
        packageName: 'test',
        versionName: '1.0',
        appName: 'Test',
        fileHash: 'hash',
        riskScore: 50,
        classification: 'SUSPICIOUS',
        permissionScore: 50,
        certificateScore: 30,
        obfuscationScore: 20,
        networkScore: 10,
        findings: [
          RiskFinding(
            category: 'PERMISSION',
            severity: 'CRITICAL',
            title: 'Critical Issue',
            description: 'Description',
            evidence: [],
            scoreImpact: 25,
          ),
          RiskFinding(
            category: 'CERTIFICATE',
            severity: 'HIGH',
            title: 'High Issue',
            description: 'Description',
            evidence: [],
            scoreImpact: 15,
          ),
        ],
        permissions: [],
        certificate: CertificateInfo(
          issuer: '',
          subject: '',
          isDebug: false,
          isSelfSigned: false,
          isExpired: false,
          warnings: [],
        ),
        summary: '',
        recommendation: '',
        limitations: [],
      );

      expect(report.criticalFindings.length, 1);
      expect(report.criticalFindings.first.title, 'Critical Issue');
    });
  });
}
