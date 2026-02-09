/// Consent screen - Required acknowledgment for high-risk APKs with premium UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../config/constants.dart';
import '../services/analysis_service.dart';
import '../widgets/widgets.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _understandRisks = false;
  bool _trustSource = false;
  bool _acceptResponsibility = false;
  
  bool get _canProceed => _understandRisks && _trustSource && _acceptResponsibility;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Security Warning'),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A0A0A),
              Color(0xFF2A1015),
              Color(0xFF1A0A15),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Red glow orbs
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.highRiskColor.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.criticalColor.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Consumer<AnalysisService>(
              builder: (context, service, child) {
                if (!service.hasReport) {
                  return const Center(child: Text('No report available'));
                }
                
                final report = service.riskReport!;
                
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Warning header
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.highRiskColor.withOpacity(0.2),
                                AppTheme.highRiskColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.highRiskColor.withOpacity(0.4),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.highRiskColor.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.highRiskColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.highRiskColor.withOpacity(0.5),
                                      blurRadius: 25,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 50,
                                  color: AppTheme.highRiskColor,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'HIGH RISK APK',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppTheme.highRiskColor,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.highRiskColor.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Risk Score: ${report.riskScore}/100',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Critical findings summary
                        if (report.criticalFindings.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppTheme.criticalColor,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.criticalColor.withOpacity(0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Critical Issues Found',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.criticalColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...report.criticalFindings.take(3).map((f) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.criticalColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.criticalColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.criticalColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.error, 
                                    color: AppTheme.criticalColor, 
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    f.title,
                                    style: const TextStyle(color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 24),
                        ],
                        
                        // Warning message
                        GlassmorphicCard(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            SecurityMessages.consentWarning,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 28),
                        
                        // Consent checkboxes
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: AppTheme.accentGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Required Acknowledgments',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        ConsentCheckbox(
                          text: 'I understand the security risks identified in this analysis',
                          value: _understandRisks,
                          onChanged: (v) => setState(() => _understandRisks = v ?? false),
                        ),
                        
                        ConsentCheckbox(
                          text: 'I trust the source of this APK file',
                          value: _trustSource,
                          onChanged: (v) => setState(() => _trustSource = v ?? false),
                        ),
                        
                        ConsentCheckbox(
                          text: 'I accept full responsibility for any consequences of installing this app',
                          value: _acceptResponsibility,
                          onChanged: (v) => setState(() => _acceptResponsibility = v ?? false),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Buttons
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back (Recommended)'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.successColor,
                            side: BorderSide(color: AppTheme.successColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: _canProceed
                                ? LinearGradient(
                                    colors: [
                                      AppTheme.highRiskColor,
                                      AppTheme.highRiskColor.withOpacity(0.8),
                                    ],
                                  )
                                : null,
                            color: _canProceed ? null : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _canProceed
                                ? [
                                    BoxShadow(
                                      color: AppTheme.highRiskColor.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _canProceed ? () => _showFinalConfirmation() : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text(
                                    'I Accept the Risks - Proceed',
                                    style: TextStyle(
                                      color: _canProceed ? Colors.white : AppTheme.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Final disclaimer
                        Text(
                          'This tool cannot prevent you from installing apps. The final decision is yours. '
                          'Installing high-risk apps may compromise your device security and personal data.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFinalConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.highRiskColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning, color: AppTheme.highRiskColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Final Warning'),
          ],
        ),
        content: const Text(
          'You have acknowledged the risks and chosen to proceed.\n\n'
          'To install this APK:\n'
          '1. Open your file manager\n'
          '2. Navigate to the APK file\n'
          '3. Tap to install\n\n'
          'This analysis tool does NOT install apps for you.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.highRiskColor,
                  AppTheme.highRiskColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.popUntil(context, (route) => route.isFirst);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('You may now install the APK from your file manager'),
                      duration: const Duration(seconds: 4),
                      backgroundColor: AppTheme.cardColor,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'I Understand',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
