/// Home screen - APK selection entry point with premium UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../config/constants.dart';
import '../services/analysis_service.dart';
import '../models/models.dart';
import 'analysis_screen.dart';
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  bool _showDisclaimer = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppTheme.textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: GradientBackground(
        child: Consumer<AnalysisService>(
          builder: (context, service, child) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Disclaimer banner
                    if (_showDisclaimer)
                      _buildDisclaimerBanner(),
                    
                    const SizedBox(height: 24),
                    
                    // Hero section
                    _buildHeroSection(),
                    
                    const SizedBox(height: 32),
                    
                    // APK Selection
                    _buildApkSelectionSection(service),
                    
                    const SizedBox(height: 24),
                    
                    // Selected APK info
                    if (service.hasApk)
                      _buildApkInfoCard(service.apkInfo!),
                    
                    const SizedBox(height: 24),
                    
                    // Error display
                    if (service.error != null)
                      _buildErrorCard(service),
                    
                    // Analyze button
                    if (service.hasApk && service.state == AnalysisState.fileSelected)
                      _buildAnalyzeButton(service),
                      
                    const SizedBox(height: 32),
                    
                    // How it works section
                    _buildHowItWorksSection(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildDisclaimerBanner() {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shield_outlined, color: AppTheme.infoColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Security Advisory Tool',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.textMuted, size: 18),
                onPressed: () => setState(() => _showDisclaimer = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'This tool provides advisory information to help assess APK security risks. It does NOT guarantee protection against all threats.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeroSection() {
    return Column(
      children: [
        // Glowing logo container
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
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
                BoxShadow(
                  color: AppTheme.accentPurple.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
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
        ),
        const SizedBox(height: 24),
        ShaderMask(
          shaderCallback: (bounds) => AppTheme.accentGradient.createShader(bounds),
          child: Text(
            'APK Risk Analyzer',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pre-installation security assessment\nfor sideloaded APK files',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildApkSelectionSection(AnalysisService service) {
    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: service.isAnalyzing ? null : () => service.selectApk(),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPink.withOpacity(0.2),
                        AppTheme.accentPurple.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.accentPink.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    size: 32,
                    color: AppTheme.accentPink,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  service.hasApk ? 'Change APK File' : 'Select APK File',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to choose an APK file from storage',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildApkInfoCard(ApkInfo apkInfo) {
    return GlassmorphicCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.android, color: AppTheme.successColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apkInfo.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      apkInfo.fileSizeFormatted,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.successColor.withOpacity(0.2),
                      AppTheme.successColor.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'Ready',
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.glassBorder,
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.fingerprint, size: 16, color: AppTheme.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SHA-256: ${apkInfo.sha256Hash.substring(0, 16)}...',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorCard(AnalysisService service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service.error!,
              style: const TextStyle(color: AppTheme.errorColor),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppTheme.errorColor, size: 18),
            onPressed: () => service.clearError(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAnalyzeButton(AnalysisService service) {
    return GradientButton(
      text: 'Analyze Security Risks',
      icon: Icons.security,
      onPressed: () async {
        await service.analyzeApk();
        if (service.state == AnalysisState.completed && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnalysisScreen()),
          );
        }
      },
    );
  }
  
  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              'How It Works',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildStepCard(
          '01',
          'Select APK',
          'Choose an APK file from your device storage',
          Icons.folder_open_rounded,
          AppTheme.accentPink,
        ),
        _buildStepCard(
          '02',
          'Analyze',
          'Static analysis of permissions, certificates, and code',
          Icons.analytics_rounded,
          AppTheme.accentPurple,
        ),
        _buildStepCard(
          '03',
          'Review Risks',
          'Get explainable risk assessment with recommendations',
          Icons.assessment_rounded,
          AppTheme.accentCyan,
        ),
        _buildStepCard(
          '04',
          'Decide',
          'Make an informed decision to install or not',
          Icons.check_circle_rounded,
          AppTheme.successColor,
        ),
      ],
    );
  }
  
  Widget _buildStepCard(String number, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color.withOpacity(0.7), size: 20),
          ),
        ],
      ),
    );
  }
}
