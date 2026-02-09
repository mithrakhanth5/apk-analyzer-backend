/// Analysis screen - Displays analysis progress and results with premium UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/analysis_service.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import 'report_screen.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Security Analysis'),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final service = context.read<AnalysisService>();
            if (!service.isAnalyzing) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Consumer<AnalysisService>(
            builder: (context, service, child) {
              if (service.isAnalyzing) {
                return _buildAnalyzingView(context, service);
              } else if (service.state == AnalysisState.completed && service.hasReport) {
                return _buildCompletedView(context, service);
              } else if (service.state == AnalysisState.error) {
                return _buildErrorView(context, service);
              }
              
              return _buildIdleView(context);
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnalyzingView(BuildContext context, AnalysisService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated scanning indicator
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPink.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
                // Progress ring
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: service.progress,
                    strokeWidth: 6,
                    backgroundColor: AppTheme.glassColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Center icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppTheme.purpleGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              'Analyzing APK...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              service.progressMessage,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Progress bar
            GlassmorphicCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: service.progress,
                      backgroundColor: AppTheme.cardColor,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(service.progress * 100).toInt()}% Complete',
                    style: TextStyle(
                      color: AppTheme.accentPink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCompletedView(BuildContext context, AnalysisService service) {
    final report = service.riskReport!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Risk score indicator
          Center(
            child: RiskIndicator(
              score: report.riskScore,
              classification: report.classification,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App info card
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppTheme.purpleGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.android, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.appName.isEmpty ? 'Unknown App' : report.appName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            report.packageName,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (report.versionName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.glassColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Version ${report.versionName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Summary banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.getRiskColor(report.classification).withOpacity(0.2),
                  AppTheme.getRiskColor(report.classification).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.getRiskColor(report.classification).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getRiskIcon(report.classification),
                  color: AppTheme.getRiskColor(report.classification),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    report.summary,
                    style: TextStyle(
                      color: AppTheme.getRiskColor(report.classification),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Score breakdown
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
                'Risk Breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          GlassmorphicCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ScoreBar(
                  label: 'Permissions',
                  score: report.permissionScore,
                ),
                const SizedBox(height: 16),
                ScoreBar(
                  label: 'Certificate',
                  score: report.certificateScore,
                ),
                const SizedBox(height: 16),
                ScoreBar(
                  label: 'Obfuscation',
                  score: report.obfuscationScore,
                ),
                const SizedBox(height: 16),
                ScoreBar(
                  label: 'Network',
                  score: report.networkScore,
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
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.criticalColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error, color: AppTheme.criticalColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  '${report.criticalFindings.length} Critical Issue(s)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.criticalColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...report.criticalFindings.take(3).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FindingCard(finding: f),
            )),
          ],
          
          const SizedBox(height: 24),
          
          // View full report button
          GradientButton(
            text: 'View Full Report',
            icon: Icons.description,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportScreen()),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Back button
          OutlinedButton.icon(
            onPressed: () {
              service.reset();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Analyze Another APK'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Disclaimer
          Text(
            'Note: This is static analysis only. Runtime behavior cannot be predicted.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  IconData _getRiskIcon(String classification) {
    switch (classification.toUpperCase()) {
      case 'SAFE':
        return Icons.check_circle;
      case 'SUSPICIOUS':
        return Icons.warning;
      case 'HIGH_RISK':
        return Icons.dangerous;
      default:
        return Icons.help_outline;
    }
  }
  
  Widget _buildErrorView(BuildContext context, AnalysisService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: AppTheme.errorColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Analysis Failed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            GlassmorphicCard(
              padding: const EdgeInsets.all(16),
              child: Text(
                service.error ?? 'Unknown error occurred',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            GradientButton(
              text: 'Retry',
              icon: Icons.refresh,
              onPressed: () => service.analyzeApk(),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                service.clearError();
                Navigator.pop(context);
              },
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildIdleView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.glassColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.hourglass_empty,
              size: 40,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to analyze',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
