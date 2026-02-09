/// About screen with premium UI

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../config/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo and name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AppTheme.purpleGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentPink.withOpacity(0.4),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.security,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
                        child: Text(
                          AppConstants.appName,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.glassColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Text(
                          'Version ${AppConstants.appVersion}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Purpose section
                _buildSection(
                  context,
                  'Purpose',
                  Icons.info_outline,
                  AppTheme.infoColor,
                  AppConstants.appDescription,
                ),
                
                const SizedBox(height: 16),
                
                // Disclaimer section
                _buildSection(
                  context,
                  'Important Disclaimer',
                  Icons.warning_amber_rounded,
                  AppTheme.warningColor,
                  SecurityMessages.disclaimer,
                ),
                
                const SizedBox(height: 16),
                
                // Analysis types section
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentPurple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.analytics, color: AppTheme.accentPurple, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Analysis Types',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFeatureRow(context, 'Permission Analysis', Icons.security, AppTheme.accentPink),
                      _buildFeatureRow(context, 'Certificate Verification', Icons.verified_user, AppTheme.accentCyan),
                      _buildFeatureRow(context, 'Code Obfuscation Detection', Icons.code, AppTheme.accentPurple),
                      _buildFeatureRow(context, 'Network Endpoint Extraction', Icons.language, AppTheme.infoColor),
                      _buildFeatureRow(context, 'Signature Validation', Icons.fingerprint, AppTheme.successColor),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Developer section
                GlassmorphicCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.code, color: AppTheme.accentCyan, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Developer',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Built with modern Flutter and Python backend for comprehensive APK analysis.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildTechBadge(context, 'Flutter'),
                          const SizedBox(width: 8),
                          _buildTechBadge(context, 'Python'),
                          const SizedBox(width: 8),
                          _buildTechBadge(context, 'FastAPI'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Footer
                Center(
                  child: Text(
                    '© 2026 APK Risk Analyzer',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, IconData icon, Color color, String content) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFeatureRow(BuildContext context, String feature, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            feature,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTechBadge(BuildContext context, String tech) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentPink.withOpacity(0.2),
            AppTheme.accentPurple.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentPink.withOpacity(0.3)),
      ),
      child: Text(
        tech,
        style: TextStyle(
          color: AppTheme.accentPinkLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
