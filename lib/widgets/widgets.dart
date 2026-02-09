/// Custom widgets for the APK Risk Analyzer with premium styling

import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../models/models.dart';

/// Risk score indicator widget with glowing ring
class RiskIndicator extends StatelessWidget {
  final int score;
  final String classification;
  final double size;
  
  const RiskIndicator({
    super.key,
    required this.score,
    required this.classification,
    this.size = 180,
  });
  
  @override
  Widget build(BuildContext context) {
    Color color = AppTheme.getRiskColor(classification);
    
    return Container(
      width: size + 40,
      height: size + 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: size + 20,
            height: size + 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.glassColor,
              border: Border.all(
                color: AppTheme.glassBorder,
                width: 1,
              ),
            ),
          ),
          // Progress ring
          SizedBox(
            width: size - 20,
            height: size - 20,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 10,
              backgroundColor: AppTheme.cardColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ).createShader(bounds),
                child: Text(
                  '$score',
                  style: AppTextStyles.riskScore.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  classification.replaceAll('_', ' '),
                  style: AppTextStyles.classification.copyWith(color: color),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Permission card widget with glassmorphism
class PermissionCard extends StatelessWidget {
  final PermissionRisk permission;
  
  const PermissionCard({
    super.key,
    required this.permission,
  });
  
  @override
  Widget build(BuildContext context) {
    Color severityColor = AppTheme.getSeverityColor(permission.riskLevel);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.glassColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Row(
              children: [
                // Risk indicator bar
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [severityColor, severityColor.withOpacity(0.3)],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                // Permission details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        permission.shortName,
                        style: AppTextStyles.permissionName.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        permission.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Score badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        severityColor.withOpacity(0.3),
                        severityColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: severityColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    '${permission.riskScore}/10',
                    style: TextStyle(
                      color: severityColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
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
}

/// Risk finding card widget with premium styling
class FindingCard extends StatelessWidget {
  final RiskFinding finding;
  final bool expanded;
  final VoidCallback? onTap;
  
  const FindingCard({
    super.key,
    required this.finding,
    this.expanded = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    Color severityColor = AppTheme.getSeverityColor(finding.severity);
    IconData icon = _getSeverityIcon(finding.severity);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.glassColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: severityColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                finding.title,
                                style: AppTextStyles.findingTitle.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      severityColor.withOpacity(0.25),
                                      severityColor.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${finding.severity} • ${finding.category}',
                                  style: TextStyle(
                                    color: severityColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (onTap != null)
                          Icon(
                            expanded ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.textMuted,
                          ),
                      ],
                    ),
                    if (expanded) ...[
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
                      Text(
                        finding.description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (finding.evidence.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Evidence:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...finding.evidence.map((e) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e,
                                  style: AppTextStyles.permissionName.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                      if (finding.recommendation.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.infoColor.withOpacity(0.15),
                                AppTheme.infoColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.infoColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: AppTheme.infoColor,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  finding.recommendation,
                                  style: TextStyle(
                                    color: AppTheme.infoColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  IconData _getSeverityIcon(String severity) {
    switch (severity.toUpperCase()) {
      case 'CRITICAL':
        return Icons.error;
      case 'HIGH':
        return Icons.warning;
      case 'MEDIUM':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }
}

/// Warning banner widget with modern styling
class WarningBanner extends StatelessWidget {
  final String message;
  final String severity; // info, warning, error
  final VoidCallback? onDismiss;
  
  const WarningBanner({
    super.key,
    required this.message,
    this.severity = 'warning',
    this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    
    switch (severity) {
      case 'error':
        color = AppTheme.errorColor;
        icon = Icons.error_outline;
        break;
      case 'info':
        color = AppTheme.infoColor;
        icon = Icons.info_outline;
        break;
      default:
        color = AppTheme.warningColor;
        icon = Icons.warning_amber_rounded;
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: color, size: 18),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

/// Score breakdown bar with gradient
class ScoreBar extends StatelessWidget {
  final String label;
  final int score;
  final int maxScore;
  final Color? color;
  
  const ScoreBar({
    super.key,
    required this.label,
    required this.score,
    this.maxScore = 100,
    this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    Color barColor = color ?? AppTheme.getScoreColor(score);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: barColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$score/$maxScore',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: barColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: score / maxScore,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [barColor, barColor.withOpacity(0.6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Consent checkbox with required acknowledgment
class ConsentCheckbox extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool?> onChanged;
  
  const ConsentCheckbox({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: value ? AppTheme.accentPink.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? AppTheme.accentPink.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.accentPink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
