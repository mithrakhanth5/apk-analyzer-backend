/// Report screen - Full detailed risk report with premium UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/analysis_service.dart';
import '../widgets/widgets.dart';
import 'consent_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, bool> _expandedFindings = {};
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalysisService>(
      builder: (context, service, child) {
        if (!service.hasReport) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text('Report'),
              backgroundColor: Colors.transparent,
            ),
            body: GradientBackground(
              child: const Center(child: Text('No report available')),
            ),
          );
        }
        
        final report = service.riskReport!;
        
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Security Report'),
            backgroundColor: Colors.transparent,
            actions: [
              // PDF Download button
              if (service.isDownloadingPdf)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentPink),
                    ),
                  ),
                )
              else ...[
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Download PDF Report',
                  onPressed: () => _downloadPdf(context, service),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  tooltip: 'Share PDF Report',
                  onPressed: () => _sharePdf(context, service),
                ),
              ],
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.glassColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    gradient: AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Findings'),
                    Tab(text: 'Permissions'),
                    Tab(text: 'Certificate'),
                  ],
                ),
              ),
            ),
          ),
          body: GradientBackground(
            child: SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(report),
                  _buildFindingsTab(report),
                  _buildPermissionsTab(report),
                  _buildCertificateTab(report),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomBar(report),
        );
      },
    );
  }
  
  Widget _buildOverviewTab(report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Risk indicator
          Center(
            child: RiskIndicator(
              score: report.riskScore,
              classification: report.classification,
              size: 160,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Summary
          Text(
            report.summary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.getRiskColor(report.classification),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Score breakdown
          GlassmorphicCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Risk Score Breakdown',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ScoreBar(label: 'Permissions (35%)', score: report.permissionScore),
                const SizedBox(height: 14),
                ScoreBar(label: 'Certificate (25%)', score: report.certificateScore),
                const SizedBox(height: 14),
                ScoreBar(label: 'Obfuscation (20%)', score: report.obfuscationScore),
                const SizedBox(height: 14),
                ScoreBar(label: 'Network (10%)', score: report.networkScore),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recommendation
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.infoColor.withOpacity(0.15),
                  AppTheme.infoColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
            ),
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
                      child: const Icon(Icons.recommend, color: AppTheme.infoColor, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Recommendation',
                      style: TextStyle(
                        color: AppTheme.infoColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  report.recommendation,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Limitations
          GlassmorphicCard(
            padding: EdgeInsets.zero,
            child: ExpansionTile(
              title: const Text('Analysis Limitations'),
              subtitle: Text(
                'Important disclaimers',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              iconColor: AppTheme.textMuted,
              collapsedIconColor: AppTheme.textMuted,
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                ...report.limitations.map<Widget>((l) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppTheme.textMuted,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFindingsTab(report) {
    final findings = report.findings;
    
    if (findings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.3),
                    blurRadius: 30,
                  ),
                ],
              ),
              child: const Icon(Icons.check_circle, size: 40, color: AppTheme.successColor),
            ),
            const SizedBox(height: 16),
            const Text('No significant findings'),
          ],
        ),
      );
    }
    
    // Group by severity
    final critical = findings.where((f) => f.severity == 'CRITICAL').toList();
    final high = findings.where((f) => f.severity == 'HIGH').toList();
    final medium = findings.where((f) => f.severity == 'MEDIUM').toList();
    final low = findings.where((f) => f.severity == 'LOW').toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (critical.isNotEmpty) ...[
          _buildFindingSection('Critical', critical, AppTheme.criticalColor),
        ],
        if (high.isNotEmpty) ...[
          _buildFindingSection('High Risk', high, AppTheme.highRiskColor),
        ],
        if (medium.isNotEmpty) ...[
          _buildFindingSection('Medium Risk', medium, AppTheme.suspiciousColor),
        ],
        if (low.isNotEmpty) ...[
          _buildFindingSection('Low Risk', low, AppTheme.infoColor),
        ],
      ],
    );
  }
  
  Widget _buildFindingSection(String title, List findings, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$title (${findings.length})',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...findings.asMap().entries.map((entry) {
          final finding = entry.value;
          final isExpanded = _expandedFindings[finding.hashCode] ?? false;
          
          return FindingCard(
            finding: finding,
            expanded: isExpanded,
            onTap: () {
              setState(() {
                _expandedFindings[finding.hashCode] = !isExpanded;
              });
            },
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildPermissionsTab(report) {
    final permissions = report.permissions;
    
    if (permissions.isEmpty) {
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
              child: const Icon(Icons.lock_open, size: 40, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            const Text('No permissions declared'),
          ],
        ),
      );
    }
    
    // Sort by risk score
    final sorted = List.of(permissions)
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    
    final dangerous = sorted.where((p) => p.riskScore >= 7).toList();
    final moderate = sorted.where((p) => p.riskScore >= 4 && p.riskScore < 7).toList();
    final low = sorted.where((p) => p.riskScore < 4).toList();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        GlassmorphicCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPermissionStat('Total', permissions.length, AppTheme.textSecondary),
              Container(width: 1, height: 40, color: AppTheme.glassBorder),
              _buildPermissionStat('Dangerous', dangerous.length, AppTheme.highRiskColor),
              Container(width: 1, height: 40, color: AppTheme.glassBorder),
              _buildPermissionStat('Moderate', moderate.length, AppTheme.suspiciousColor),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        if (dangerous.isNotEmpty) ...[
          _buildPermissionSection('Dangerous Permissions', dangerous),
        ],
        if (moderate.isNotEmpty) ...[
          _buildPermissionSection('Moderate Risk', moderate),
        ],
        if (low.isNotEmpty) ...[
          _buildPermissionSection('Low Risk', low),
        ],
      ],
    );
  }
  
  Widget _buildPermissionStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
  
  Widget _buildPermissionSection(String title, List permissions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...permissions.map((p) => PermissionCard(permission: p)),
        const SizedBox(height: 8),
      ],
    );
  }
  
  Widget _buildCertificateTab(report) {
    final cert = report.certificate;
    
    Color statusColor = cert.isDebug || cert.isExpired
        ? AppTheme.highRiskColor
        : cert.isSelfSigned
            ? AppTheme.suspiciousColor
            : AppTheme.successColor;
    
    IconData statusIcon = cert.isDebug || cert.isExpired
        ? Icons.warning
        : cert.isSelfSigned
            ? Icons.help_outline
            : Icons.verified_user;
    
    String statusText = cert.isDebug
        ? 'Debug Certificate'
        : cert.isExpired
            ? 'Expired Certificate'
            : cert.isSelfSigned
                ? 'Self-Signed Certificate'
                : 'Valid Certificate';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Certificate status card
          GlassmorphicCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(statusIcon, size: 40, color: statusColor),
                ),
                const SizedBox(height: 16),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Certificate details card
          GlassmorphicCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: AppTheme.accentGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Certificate Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildCertField('Issuer', cert.issuer),
                _buildCertField('Subject', cert.subject),
                _buildCertField('Signature', cert.signatureVersion ?? 'Unknown'),
                _buildCertField('Debug', cert.isDebug ? 'Yes ⚠️' : 'No'),
                _buildCertField('Self-Signed', cert.isSelfSigned ? 'Yes' : 'No'),
                _buildCertField('Expired', cert.isExpired ? 'Yes ⚠️' : 'No'),
              ],
            ),
          ),
          
          // Warnings
          if (cert.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...cert.warnings.map((w) => WarningBanner(
              message: w.replaceAll('⚠️', '').replaceAll('ℹ️', '').trim(),
              severity: w.contains('⚠️') ? 'warning' : 'info',
            )),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCertField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Unknown' : value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar(report) {
    final isHighRisk = report.classification == 'HIGH_RISK';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        border: Border(
          top: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Done'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isHighRisk
                      ? LinearGradient(colors: [AppTheme.warningColor, AppTheme.warningColor.withOpacity(0.8)])
                      : LinearGradient(colors: [AppTheme.successColor, AppTheme.successColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isHighRisk ? AppTheme.warningColor : AppTheme.successColor).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isHighRisk) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ConsentScreen()),
                        );
                      } else {
                        _showProceedDialog();
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        isHighRisk ? 'Proceed Anyway' : 'Safe to Install',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showProceedDialog() {
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
                color: AppTheme.successColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Ready to Install'),
          ],
        ),
        content: const Text(
          'Based on static analysis, this APK appears to be low-risk. '
          'You can proceed to install it from your file manager.\n\n'
          'Note: This analysis does not guarantee safety.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _downloadPdf(BuildContext context, AnalysisService service) async {
    String? filePath = await service.downloadPdfReport();
    
    if (!mounted) return;
    
    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.successColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PDF saved to Downloads',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    } else if (service.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: AppTheme.highRiskColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
          duration: const Duration(seconds: 4),
        ),
      );
      service.clearError();
    }
  }
  
  Future<void> _sharePdf(BuildContext context, AnalysisService service) async {
    await service.sharePdfReport();
    
    if (!mounted) return;
    
    if (service.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: AppTheme.highRiskColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  service.error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.cardColor,
          duration: const Duration(seconds: 4),
        ),
      );
      service.clearError();
    }
  }
}
