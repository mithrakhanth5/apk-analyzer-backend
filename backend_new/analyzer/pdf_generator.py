"""
PDF Report Generator
Generates professional PDF reports for APK risk analysis.
"""
from io import BytesIO
from datetime import datetime
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field

# Using reportlab for PDF generation
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.lib.colors import HexColor, black, white, red, green, orange
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_RIGHT
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, Image, ListFlowable, ListItem
)
from reportlab.graphics.shapes import Drawing, Rect
from reportlab.graphics.charts.piecharts import Pie


@dataclass
class ReportData:
    """Data structure for PDF report generation"""
    # Basic info
    analysis_id: str
    package_name: str
    version_name: str
    app_name: str
    file_hash: str
    analysis_date: str
    
    # Risk assessment
    risk_score: int
    classification: str  # SAFE, SUSPICIOUS, HIGH_RISK
    
    # Component scores
    permission_score: int
    certificate_score: int
    obfuscation_score: int
    network_score: int
    sandbox_score: int = 0
    
    # Details
    findings: List[Dict[str, Any]] = field(default_factory=list)
    permissions: List[Dict[str, Any]] = field(default_factory=list)
    certificate_info: Dict[str, Any] = field(default_factory=dict)
    sandbox_results: Dict[str, Any] = field(default_factory=dict)
    
    # Summary
    summary: str = ""
    recommendation: str = ""
    limitations: List[str] = field(default_factory=list)


class PDFReportGenerator:
    """
    Generates professional PDF reports for APK risk analysis.
    """
    
    # Color scheme
    COLORS = {
        "primary": HexColor("#6B46C1"),      # Purple
        "secondary": HexColor("#9F7AEA"),    # Light purple
        "safe": HexColor("#38A169"),          # Green
        "suspicious": HexColor("#D69E2E"),    # Yellow/Orange
        "high_risk": HexColor("#E53E3E"),     # Red
        "text": HexColor("#2D3748"),          # Dark gray
        "light_bg": HexColor("#F7FAFC"),      # Light gray
        "white": white,
        "black": black
    }
    
    def __init__(self):
        """Initialize PDF generator with styles"""
        self.styles = getSampleStyleSheet()
        self._setup_custom_styles()
    
    def _setup_custom_styles(self):
        """Setup custom paragraph styles"""
        # Title style
        self.styles.add(ParagraphStyle(
            name='ReportTitle',
            parent=self.styles['Heading1'],
            fontSize=24,
            textColor=self.COLORS["primary"],
            spaceAfter=20,
            alignment=TA_CENTER
        ))
        
        # Section header style
        self.styles.add(ParagraphStyle(
            name='SectionHeader',
            parent=self.styles['Heading2'],
            fontSize=16,
            textColor=self.COLORS["primary"],
            spaceBefore=20,
            spaceAfter=10
        ))
        
        # Subsection style
        self.styles.add(ParagraphStyle(
            name='SubSection',
            parent=self.styles['Heading3'],
            fontSize=12,
            textColor=self.COLORS["text"],
            spaceBefore=10,
            spaceAfter=5
        ))
        
        # Body text style - using different name to avoid conflict
        self.styles.add(ParagraphStyle(
            name='ReportBody',
            parent=self.styles['Normal'],
            fontSize=10,
            textColor=self.COLORS["text"],
            leading=14
        ))
        
        # Risk score styles
        for level in ['Safe', 'Suspicious', 'HighRisk']:
            color_key = level.lower().replace('highrisk', 'high_risk')
            self.styles.add(ParagraphStyle(
                name=f'Risk{level}',
                parent=self.styles['Heading1'],
                fontSize=48,
                textColor=self.COLORS.get(color_key, self.COLORS["text"]),
                alignment=TA_CENTER
            ))
    
    def generate_report(self, data: ReportData) -> bytes:
        """
        Generate a complete PDF report from analysis data.
        Returns the PDF as bytes.
        """
        buffer = BytesIO()
        doc = SimpleDocTemplate(
            buffer,
            pagesize=A4,
            rightMargin=0.75*inch,
            leftMargin=0.75*inch,
            topMargin=0.75*inch,
            bottomMargin=0.75*inch
        )
        
        # Build document elements
        elements = []
        
        # Title page
        elements.extend(self._build_title_page(data))
        elements.append(PageBreak())
        
        # Executive summary
        elements.extend(self._build_executive_summary(data))
        elements.append(Spacer(1, 20))
        
        # Risk breakdown
        elements.extend(self._build_risk_breakdown(data))
        elements.append(Spacer(1, 20))
        
        # Findings section
        if data.findings:
            elements.extend(self._build_findings_section(data))
            elements.append(Spacer(1, 20))
        
        # Permissions section
        if data.permissions:
            elements.extend(self._build_permissions_section(data))
            elements.append(Spacer(1, 20))
        
        # Certificate info
        if data.certificate_info:
            elements.extend(self._build_certificate_section(data))
            elements.append(Spacer(1, 20))
        
        # Sandbox results
        if data.sandbox_results:
            elements.extend(self._build_sandbox_section(data))
            elements.append(Spacer(1, 20))
        
        # Recommendations and limitations
        elements.extend(self._build_recommendations_section(data))
        
        # Footer/disclaimer
        elements.extend(self._build_footer())
        
        # Build PDF
        doc.build(elements)
        
        return buffer.getvalue()
    
    def _build_title_page(self, data: ReportData) -> List:
        """Build the title page elements"""
        elements = []
        
        # Main title
        elements.append(Spacer(1, 100))
        elements.append(Paragraph(
            "APK RISK ANALYSIS REPORT",
            self.styles['ReportTitle']
        ))
        elements.append(Spacer(1, 30))
        
        # App info box
        app_info = [
            ["App Name:", data.app_name or "Unknown"],
            ["Package:", data.package_name],
            ["Version:", data.version_name],
            ["File Hash:", data.file_hash[:32] + "..."],
            ["Analysis Date:", data.analysis_date],
            ["Report ID:", data.analysis_id[:16] + "..."]
        ]
        
        table = Table(app_info, colWidths=[2*inch, 4*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (0, -1), self.COLORS["light_bg"]),
            ('TEXTCOLOR', (0, 0), (-1, -1), self.COLORS["text"]),
            ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
            ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ('PADDING', (0, 0), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, self.COLORS["secondary"])
        ]))
        elements.append(table)
        elements.append(Spacer(1, 40))
        
        # Risk classification
        risk_color = self._get_risk_color(data.classification)
        risk_style = self._get_risk_style_name(data.classification)
        
        elements.append(Paragraph(
            f"<b>RISK CLASSIFICATION</b>",
            ParagraphStyle('RiskLabel', fontSize=12, alignment=TA_CENTER)
        ))
        elements.append(Spacer(1, 10))
        elements.append(Paragraph(
            data.classification.replace("_", " "),
            self.styles[risk_style]
        ))
        elements.append(Paragraph(
            f"Score: {data.risk_score}/100",
            ParagraphStyle('ScoreLabel', fontSize=14, alignment=TA_CENTER)
        ))
        
        return elements
    
    def _build_executive_summary(self, data: ReportData) -> List:
        """Build executive summary section"""
        elements = []
        
        elements.append(Paragraph("Executive Summary", self.styles['SectionHeader']))
        
        elements.append(Paragraph(data.summary or "No summary available.", self.styles['ReportBody']))
        
        return elements
    
    def _build_risk_breakdown(self, data: ReportData) -> List:
        """Build risk score breakdown section"""
        elements = []
        
        elements.append(Paragraph("Risk Score Breakdown", self.styles['SectionHeader']))
        
        # Score table
        scores = [
            ["Component", "Score", "Status"],
            ["Permission Risk", f"{data.permission_score}/100", self._get_status_text(data.permission_score)],
            ["Certificate Risk", f"{data.certificate_score}/100", self._get_status_text(data.certificate_score)],
            ["Obfuscation Risk", f"{data.obfuscation_score}/100", self._get_status_text(data.obfuscation_score)],
            ["Network Risk", f"{data.network_score}/100", self._get_status_text(data.network_score)],
            ["Sandbox Analysis", f"{data.sandbox_score}/100", self._get_status_text(data.sandbox_score)],
            ["Overall Risk", f"{data.risk_score}/100", data.classification.replace("_", " ")]
        ]
        
        table = Table(scores, colWidths=[2.5*inch, 1.5*inch, 2*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), self.COLORS["primary"]),
            ('TEXTCOLOR', (0, 0), (-1, 0), self.COLORS["white"]),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('BACKGROUND', (0, -1), (-1, -1), self.COLORS["light_bg"]),
            ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
            ('PADDING', (0, 0), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, self.COLORS["secondary"])
        ]))
        elements.append(table)
        
        return elements
    
    def _build_findings_section(self, data: ReportData) -> List:
        """Build security findings section"""
        elements = []
        
        elements.append(Paragraph("Security Findings", self.styles['SectionHeader']))
        
        if not data.findings:
            elements.append(Paragraph("No significant findings.", self.styles['ReportBody']))
            return elements
        
        for finding in data.findings[:10]:  # Limit to 10 findings
            severity = finding.get('severity', 'INFO')
            severity_color = self._get_severity_color(severity)
            
            elements.append(Paragraph(
                f"<font color='{severity_color}'>[{severity}]</font> {finding.get('title', 'Unknown')}",
                self.styles['SubSection']
            ))
            elements.append(Paragraph(
                finding.get('description', ''),
                self.styles['ReportBody']
            ))
            
            if finding.get('recommendation'):
                elements.append(Paragraph(
                    f"<b>Recommendation:</b> {finding['recommendation']}",
                    self.styles['ReportBody']
                ))
            
            elements.append(Spacer(1, 10))
        
        return elements
    
    def _build_permissions_section(self, data: ReportData) -> List:
        """Build permissions analysis section"""
        elements = []
        
        elements.append(Paragraph("Permission Analysis", self.styles['SectionHeader']))
        
        if not data.permissions:
            elements.append(Paragraph("No permissions data available.", self.styles['ReportBody']))
            return elements
        
        # Filter to dangerous permissions only
        dangerous_perms = [p for p in data.permissions if p.get('risk_level') in ['HIGH', 'CRITICAL']]
        
        if dangerous_perms:
            perm_data = [["Permission", "Risk Level", "Category"]]
            for perm in dangerous_perms[:15]:
                perm_name = perm.get('permission', '').split('.')[-1]
                perm_data.append([
                    perm_name[:30],
                    perm.get('risk_level', 'UNKNOWN'),
                    perm.get('category', 'N/A')
                ])
            
            table = Table(perm_data, colWidths=[2.5*inch, 1.5*inch, 2*inch])
            table.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), self.COLORS["primary"]),
                ('TEXTCOLOR', (0, 0), (-1, 0), self.COLORS["white"]),
                ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
                ('FONTSIZE', (0, 0), (-1, -1), 9),
                ('ALIGN', (1, 0), (-1, -1), 'CENTER'),
                ('PADDING', (0, 0), (-1, -1), 6),
                ('GRID', (0, 0), (-1, -1), 0.5, self.COLORS["secondary"])
            ]))
            elements.append(table)
        else:
            elements.append(Paragraph(
                "No dangerous permissions detected.",
                self.styles['ReportBody']
            ))
        
        return elements
    
    def _build_certificate_section(self, data: ReportData) -> List:
        """Build certificate analysis section"""
        elements = []
        
        elements.append(Paragraph("Certificate Analysis", self.styles['SectionHeader']))
        
        cert = data.certificate_info or {}
        
        cert_info = [
            ["Property", "Value"],
            ["Issuer", cert.get('issuer', 'Unknown')[:50]],
            ["Subject", cert.get('subject', 'Unknown')[:50]],
            ["Debug Signed", "Yes ⚠️" if cert.get('is_debug') else "No ✓"],
            ["Self Signed", "Yes ⚠️" if cert.get('is_self_signed') else "No ✓"],
            ["Expired", "Yes ⚠️" if cert.get('is_expired') else "No ✓"]
        ]
        
        table = Table(cert_info, colWidths=[2*inch, 4*inch])
        table.setStyle(TableStyle([
            ('BACKGROUND', (0, 0), (-1, 0), self.COLORS["primary"]),
            ('TEXTCOLOR', (0, 0), (-1, 0), self.COLORS["white"]),
            ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
            ('FONTSIZE', (0, 0), (-1, -1), 10),
            ('PADDING', (0, 0), (-1, -1), 8),
            ('GRID', (0, 0), (-1, -1), 0.5, self.COLORS["secondary"])
        ]))
        elements.append(table)
        
        # Add warnings
        warnings = cert.get('warnings', [])
        if warnings:
            elements.append(Spacer(1, 10))
            elements.append(Paragraph("<b>Warnings:</b>", self.styles['ReportBody']))
            for warning in warnings:
                elements.append(Paragraph(f"• {warning}", self.styles['ReportBody']))
        
        return elements
    
    def _build_sandbox_section(self, data: ReportData) -> List:
        """Build sandbox analysis section"""
        elements = []
        
        elements.append(Paragraph("Sandbox Analysis", self.styles['SectionHeader']))
        
        sandbox = data.sandbox_results or {}
        
        if sandbox.get('error_message'):
            elements.append(Paragraph(
                f"<i>Note: {sandbox['error_message']}</i>",
                self.styles['ReportBody']
            ))
            return elements
        
        # Detection info
        detection_ratio = sandbox.get('detection_ratio', 'N/A')
        threat_level = sandbox.get('threat_level', 'unknown')
        
        elements.append(Paragraph(
            f"<b>Detection Ratio:</b> {detection_ratio}",
            self.styles['ReportBody']
        ))
        elements.append(Paragraph(
            f"<b>Threat Level:</b> {threat_level.upper()}",
            self.styles['ReportBody']
        ))
        
        # Malware names if any
        malware_names = sandbox.get('malware_names', [])
        if malware_names:
            elements.append(Spacer(1, 10))
            elements.append(Paragraph("<b>Detected As:</b>", self.styles['ReportBody']))
            for name in malware_names[:5]:
                elements.append(Paragraph(f"• {name}", self.styles['ReportBody']))
        
        # Behavior indicators
        behaviors = sandbox.get('behaviors_detected', [])
        if behaviors:
            elements.append(Spacer(1, 10))
            elements.append(Paragraph("<b>Behavioral Indicators:</b>", self.styles['ReportBody']))
            for behavior in behaviors[:10]:
                elements.append(Paragraph(
                    f"• [{behavior.get('severity', 'INFO')}] {behavior.get('type', 'Unknown')}: {behavior.get('indicator', '')}",
                    self.styles['ReportBody']
                ))
        
        return elements
    
    def _build_recommendations_section(self, data: ReportData) -> List:
        """Build recommendations and limitations section"""
        elements = []
        
        elements.append(Paragraph("Recommendations", self.styles['SectionHeader']))
        elements.append(Paragraph(
            data.recommendation or "Review the analysis results carefully before installation.",
            self.styles['ReportBody']
        ))
        
        elements.append(Spacer(1, 20))
        
        elements.append(Paragraph("Analysis Limitations", self.styles['SectionHeader']))
        
        limitations = data.limitations or [
            "Static analysis only - runtime behavior not analyzed",
            "Cannot detect zero-day or unknown malware",
            "Risk scores are heuristic estimates"
        ]
        
        for limitation in limitations:
            elements.append(Paragraph(f"• {limitation}", self.styles['ReportBody']))
        
        return elements
    
    def _build_footer(self) -> List:
        """Build footer/disclaimer"""
        elements = []
        
        elements.append(Spacer(1, 30))
        elements.append(Paragraph(
            "<b>DISCLAIMER</b>",
            ParagraphStyle('DisclaimerTitle', fontSize=10, alignment=TA_CENTER)
        ))
        elements.append(Paragraph(
            "This report is provided for informational purposes only and does not guarantee security. "
            "The APK Risk Analyzer performs static and sandbox analysis to identify potential risks, "
            "but cannot detect all types of malware or malicious behavior. Always download apps from "
            "trusted sources. By proceeding with installation, you accept full responsibility for any consequences.",
            ParagraphStyle('Disclaimer', fontSize=8, alignment=TA_CENTER, textColor=HexColor("#718096"))
        ))
        elements.append(Spacer(1, 10))
        elements.append(Paragraph(
            f"Generated by APK Risk Analyzer • {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
            ParagraphStyle('Footer', fontSize=8, alignment=TA_CENTER, textColor=HexColor("#A0AEC0"))
        ))
        
        return elements
    
    def _get_risk_color(self, classification: str) -> HexColor:
        """Get color for risk classification"""
        mapping = {
            "SAFE": self.COLORS["safe"],
            "SUSPICIOUS": self.COLORS["suspicious"],
            "HIGH_RISK": self.COLORS["high_risk"]
        }
        return mapping.get(classification, self.COLORS["text"])
    
    def _get_risk_style_name(self, classification: str) -> str:
        """Get style name for risk classification"""
        mapping = {
            "SAFE": "RiskSafe",
            "SUSPICIOUS": "RiskSuspicious",
            "HIGH_RISK": "RiskHighRisk"
        }
        return mapping.get(classification, "RiskSuspicious")
    
    def _get_status_text(self, score: int) -> str:
        """Get status text based on score"""
        if score <= 30:
            return "Low Risk ✓"
        elif score <= 60:
            return "Medium Risk ⚠️"
        else:
            return "High Risk ⚠️"
    
    def _get_severity_color(self, severity: str) -> str:
        """Get color hex for severity level"""
        colors = {
            "CRITICAL": "#E53E3E",
            "HIGH": "#DD6B20",
            "MEDIUM": "#D69E2E",
            "LOW": "#38A169",
            "INFO": "#4299E1"
        }
        return colors.get(severity.upper(), "#2D3748")
