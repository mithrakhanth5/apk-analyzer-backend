"""
APK Risk Analyzer - FastAPI Backend
Secure, consent-based pre-installation APK risk assessment API.
With sandbox-based inspection and PDF report generation.
"""
import base64
import hashlib
import tempfile
import os
from datetime import datetime
from typing import Optional
from contextlib import asynccontextmanager
from io import BytesIO

from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import List, Dict, Any

from analyzer import (
    APKParser,
    PermissionAnalyzer,
    CertificateAnalyzer,
    ObfuscationDetector,
    NetworkExtractor,
    RiskEngine,
    VirusTotalAnalyzer,
    LocalSandboxSimulator,
    PDFReportGenerator,
    ReportData
)


# ============================================================================
# Pydantic Models
# ============================================================================

class AnalysisRequest(BaseModel):
    """Request model for APK analysis"""
    apk_hash: str = Field(..., description="SHA256 hash of the APK file")
    apk_data: str = Field(..., description="Base64 encoded APK file content")


class PermissionRiskResponse(BaseModel):
    """Permission risk in response"""
    permission: str
    risk_score: int
    risk_level: str
    category: str
    description: str


class FindingResponse(BaseModel):
    """Risk finding in response"""
    category: str
    severity: str
    title: str
    description: str
    evidence: List[str]
    score_impact: int
    recommendation: str = ""


class CertificateResponse(BaseModel):
    """Certificate info in response"""
    issuer: str
    subject: str
    is_debug: bool
    is_self_signed: bool
    is_expired: bool
    signature_version: Optional[str]
    warnings: List[str]


class SandboxResponse(BaseModel):
    """Sandbox analysis results"""
    detection_ratio: str
    positives: int
    total_scanners: int
    threat_level: str
    malware_names: List[str] = []
    behaviors_detected: List[Dict[str, Any]] = []
    risk_score: int
    warnings: List[str] = []
    error_message: str = ""


class AnalysisResponse(BaseModel):
    """Complete analysis response"""
    analysis_id: str
    package_name: str
    version_name: str
    app_name: str
    file_hash: str
    
    risk_score: int
    classification: str  # SAFE, SUSPICIOUS, HIGH_RISK
    
    # Component scores
    permission_score: int
    certificate_score: int
    obfuscation_score: int
    network_score: int
    sandbox_score: int = 0  # Sandbox analysis score
    
    # Detailed findings
    findings: List[FindingResponse]
    permissions: List[PermissionRiskResponse]
    certificate: CertificateResponse
    sandbox: Optional[SandboxResponse] = None  # Sandbox results
    
    summary: str
    recommendation: str
    
    # Transparency
    limitations: List[str]


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    version: str
    analyzer_ready: bool


# ============================================================================
# Application Setup
# ============================================================================

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    print("🔒 APK Risk Analyzer Backend Starting...")
    print("⚠️  DISCLAIMER: This is an advisory tool, not a security guarantee.")
    yield
    # Shutdown
    print("👋 APK Risk Analyzer Backend Shutting Down...")


app = FastAPI(
    title="APK Risk Analyzer API",
    description=(
        "Secure, consent-based pre-installation APK risk assessment. "
        "This API performs static analysis on Android APK files to identify "
        "potential security risks BEFORE installation. "
        "\n\n"
        "**LIMITATIONS**: Static analysis cannot detect runtime-loaded code, "
        "encrypted payloads, or zero-day exploits. Risk scores are heuristic "
        "and not definitive security verdicts."
    ),
    version="1.0.0",
    lifespan=lifespan
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, restrict to your app's domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ============================================================================
# API Endpoints
# ============================================================================

@app.get("/", response_model=HealthResponse)
async def root():
    """Health check endpoint"""
    return HealthResponse(
        status="operational",
        version="1.0.0",
        analyzer_ready=True
    )


@app.get("/api/v1/health", response_model=HealthResponse)
async def health_check():
    """Detailed health check"""
    return HealthResponse(
        status="operational",
        version="1.0.0",
        analyzer_ready=True
    )


@app.post("/api/v1/analyze", response_model=AnalysisResponse)
async def analyze_apk(request: AnalysisRequest):
    """
    Analyze an APK file for security risks.
    
    This endpoint performs static analysis on the provided APK and returns
    a comprehensive risk assessment with explainable findings.
    
    **Privacy Note**: The APK is processed in memory and not permanently stored.
    """
    try:
        # Decode base64 APK data
        try:
            apk_bytes = base64.b64decode(request.apk_data)
        except Exception:
            raise HTTPException(status_code=400, detail="Invalid base64 APK data")
        
        # Verify hash
        calculated_hash = hashlib.sha256(apk_bytes).hexdigest()
        if calculated_hash != request.apk_hash:
            raise HTTPException(
                status_code=400, 
                detail="Hash mismatch - APK data may be corrupted"
            )
        
        # Perform analysis
        return await _perform_analysis(apk_bytes, calculated_hash)
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_detail = f"Analysis failed: {str(e)}\n{traceback.format_exc()}"
        print(f"ERROR: {error_detail}")  # Log for Render
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


@app.post("/api/v1/analyze/upload")
async def analyze_apk_upload(file: UploadFile = File(...)):
    """
    Analyze an uploaded APK file.
    
    Alternative endpoint that accepts direct file upload instead of base64.
    """
    if not file.filename.endswith('.apk'):
        raise HTTPException(status_code=400, detail="File must be an APK")
    
    try:
        apk_bytes = await file.read()
        file_hash = hashlib.sha256(apk_bytes).hexdigest()
        
        return await _perform_analysis(apk_bytes, file_hash)
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")


async def _perform_analysis(apk_bytes: bytes, file_hash: str) -> AnalysisResponse:
    """
    Perform the actual APK analysis including sandbox inspection.
    """
    import uuid
    
    # Initialize analyzers
    parser = APKParser()
    permission_analyzer = PermissionAnalyzer()
    certificate_analyzer = CertificateAnalyzer()
    obfuscation_detector = ObfuscationDetector()
    network_extractor = NetworkExtractor()
    risk_engine = RiskEngine()
    vt_analyzer = VirusTotalAnalyzer()
    local_sandbox = LocalSandboxSimulator()
    
    # Parse APK
    metadata = parser.parse_from_bytes(apk_bytes)
    
    # Run permission analysis
    perm_result = permission_analyzer.analyze(metadata.permissions)
    
    # Run certificate analysis
    cert_result = certificate_analyzer.analyze(metadata.certificate_info)
    
    # Run obfuscation detection
    dex_info = parser.get_dex_info()
    obf_result = obfuscation_detector.analyze(dex_info)
    
    # Run network extraction (basic - from class names for now)
    net_result = network_extractor.analyze(strings=dex_info.get("classes", []))
    
    # ========== SANDBOX ANALYSIS ==========
    # Try VirusTotal first (cloud sandbox)
    vt_result = await vt_analyzer.analyze_hash(file_hash)
    
    # Also run local sandbox simulation for behavior detection
    local_sandbox_result = local_sandbox.analyze(
        dex_classes=dex_info.get("classes", []),
        permissions=metadata.permissions
    )
    
    # Combine sandbox results
    sandbox_score = 0
    sandbox_response = None
    behaviors_detected = []
    
    if vt_result.positives > 0:
        # VirusTotal found detections
        sandbox_score = vt_result.risk_score
        behaviors_detected = [
            {"type": "antivirus", "indicator": name, "severity": "HIGH"}
            for name in vt_result.malware_names[:5]
        ]
    else:
        # Use local sandbox simulation results
        sandbox_score = local_sandbox_result.get("risk_score", 0)
        behaviors_detected = local_sandbox_result.get("behaviors_detected", [])
    
    # Create sandbox response
    sandbox_response = SandboxResponse(
        detection_ratio=vt_result.detection_ratio,
        positives=vt_result.positives,
        total_scanners=vt_result.total_scanners,
        threat_level=vt_result.threat_level.value,
        malware_names=vt_result.malware_names,
        behaviors_detected=behaviors_detected,
        risk_score=sandbox_score,
        warnings=vt_result.warnings + local_sandbox_result.get("risk_indicators", []),
        error_message=vt_result.error_message
    )
    
    # Calculate overall risk (include sandbox score)
    components = {
        "services": metadata.services,
        "receivers": metadata.receivers,
        "activities": metadata.activities
    }
    
    risk_report = risk_engine.calculate_risk(
        package_name=metadata.package_name,
        version_name=metadata.version_name,
        app_name=metadata.app_name,
        file_hash=file_hash,
        permission_result=perm_result,
        certificate_result=cert_result,
        obfuscation_result=obf_result,
        network_result=net_result,
        components=components
    )
    
    # Adjust overall score with sandbox results
    final_risk_score = risk_report.overall_score
    if sandbox_score > 0:
        # Blend sandbox score into final score (weighted average)
        final_risk_score = int((risk_report.overall_score * 0.7) + (sandbox_score * 0.3))
        final_risk_score = min(100, final_risk_score)
    
    # Determine final classification
    if final_risk_score <= 30:
        classification = "SAFE"
    elif final_risk_score <= 60:
        classification = "SUSPICIOUS"
    else:
        classification = "HIGH_RISK"
    
    # Build response
    return AnalysisResponse(
        analysis_id=str(uuid.uuid4()),
        package_name=risk_report.package_name,
        version_name=risk_report.version_name,
        app_name=risk_report.app_name,
        file_hash=file_hash,
        
        risk_score=final_risk_score,
        classification=classification,
        
        permission_score=risk_report.permission_score,
        certificate_score=risk_report.certificate_score,
        obfuscation_score=risk_report.obfuscation_score,
        network_score=risk_report.network_score,
        sandbox_score=sandbox_score,
        
        findings=[
            FindingResponse(
                category=f.category,
                severity=f.severity,
                title=f.title,
                description=f.description,
                evidence=f.evidence,
                score_impact=f.score_impact,
                recommendation=f.recommendation
            )
            for f in risk_report.findings
        ],
        
        permissions=[
            PermissionRiskResponse(
                permission=p.permission,
                risk_score=p.risk_score,
                risk_level=p.risk_level.value,
                category=p.category.value,
                description=p.description
            )
            for p in perm_result.permission_risks
        ],
        
        certificate=CertificateResponse(
            issuer=cert_result.issuer,
            subject=cert_result.subject,
            is_debug=cert_result.is_debug_signed,
            is_self_signed=cert_result.is_self_signed,
            is_expired=cert_result.is_expired,
            signature_version=cert_result.signature_version,
            warnings=cert_result.warnings
        ),
        
        sandbox=sandbox_response,
        
        summary=risk_report.summary,
        recommendation=risk_report.recommendation,
        limitations=risk_report.limitations + [
            "Sandbox analysis uses VirusTotal API (if configured) and local behavior simulation"
        ]
    )


@app.get("/api/v1/permissions")
async def list_dangerous_permissions():
    """
    List all dangerous permissions tracked by the analyzer.
    
    Useful for educational purposes and transparency.
    """
    from analyzer.permission_analyzer import DANGEROUS_PERMISSIONS
    
    return {
        "count": len(DANGEROUS_PERMISSIONS),
        "permissions": {
            perm: {
                "risk_score": info["risk"],
                "category": info["category"].value,
                "description": info["description"]
            }
            for perm, info in DANGEROUS_PERMISSIONS.items()
        }
    }


@app.get("/api/v1/limitations")
async def get_limitations():
    """
    Get explicit list of analysis limitations.
    
    Transparency about what this tool can and cannot detect.
    """
    return {
        "limitations": [
            {
                "category": "Static Analysis Only",
                "description": "This tool performs static analysis on APK files. Runtime behavior, dynamically loaded code, and encrypted payloads cannot be detected."
            },
            {
                "category": "Heuristic Scoring",
                "description": "Risk scores are based on heuristics and pattern matching. They are estimates, not definitive security verdicts."
            },
            {
                "category": "Unknown Malware",
                "description": "Zero-day exploits, unknown malware families, and novel attack techniques may not be detected."
            },
            {
                "category": "False Positives",
                "description": "Legitimate apps with unusual permission requirements or heavy obfuscation may receive higher risk scores."
            },
            {
                "category": "Advisory Only",
                "description": "This tool provides advisory information to help users make informed decisions. It is NOT a guarantee of security."
            }
        ],
        "disclaimer": (
            "APK Risk Analyzer is designed to help users assess potential risks "
            "of sideloaded APK files. It does NOT replace Google Play Protect or "
            "other security solutions. Always download apps from trusted sources."
        )
    }


@app.post("/api/v1/report/pdf")
async def generate_pdf_report(analysis: AnalysisResponse):
    """
    Generate a PDF report from analysis results.
    
    Returns a downloadable PDF file containing the complete risk assessment.
    """
    try:
        # Create report data
        report_data = ReportData(
            analysis_id=analysis.analysis_id,
            package_name=analysis.package_name,
            version_name=analysis.version_name,
            app_name=analysis.app_name,
            file_hash=analysis.file_hash,
            analysis_date=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            risk_score=analysis.risk_score,
            classification=analysis.classification,
            permission_score=analysis.permission_score,
            certificate_score=analysis.certificate_score,
            obfuscation_score=analysis.obfuscation_score,
            network_score=analysis.network_score,
            sandbox_score=analysis.sandbox_score,
            findings=[f.model_dump() for f in analysis.findings],
            permissions=[p.model_dump() for p in analysis.permissions],
            certificate_info=analysis.certificate.model_dump(),
            sandbox_results=analysis.sandbox.model_dump() if analysis.sandbox else None,
            summary=analysis.summary,
            recommendation=analysis.recommendation,
            limitations=analysis.limitations
        )
        
        # Generate PDF
        pdf_generator = PDFReportGenerator()
        pdf_bytes = pdf_generator.generate_report(report_data)
        
        # Return as streaming response
        filename = f"APK_Risk_Report_{analysis.package_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        return StreamingResponse(
            BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )
        
    except Exception as e:
        import traceback
        error_detail = f"PDF generation failed: {str(e)}\n{traceback.format_exc()}"
        print(f"ERROR: {error_detail}")
        raise HTTPException(status_code=500, detail=f"PDF generation failed: {str(e)}")


@app.post("/api/v1/analyze-and-report")
async def analyze_and_generate_report(file: UploadFile = File(...)):
    """
    Analyze an APK and directly generate a PDF report.
    
    Combines analysis and PDF generation in one endpoint.
    Returns the PDF report as a downloadable file.
    """
    if not file.filename.endswith('.apk'):
        raise HTTPException(status_code=400, detail="File must be an APK")
    
    try:
        # Read APK
        apk_bytes = await file.read()
        file_hash = hashlib.sha256(apk_bytes).hexdigest()
        
        # Perform analysis
        analysis = await _perform_analysis(apk_bytes, file_hash)
        
        # Create report data
        report_data = ReportData(
            analysis_id=analysis.analysis_id,
            package_name=analysis.package_name,
            version_name=analysis.version_name,
            app_name=analysis.app_name,
            file_hash=analysis.file_hash,
            analysis_date=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            risk_score=analysis.risk_score,
            classification=analysis.classification,
            permission_score=analysis.permission_score,
            certificate_score=analysis.certificate_score,
            obfuscation_score=analysis.obfuscation_score,
            network_score=analysis.network_score,
            sandbox_score=analysis.sandbox_score,
            findings=[f.model_dump() for f in analysis.findings],
            permissions=[p.model_dump() for p in analysis.permissions],
            certificate_info=analysis.certificate.model_dump(),
            sandbox_results=analysis.sandbox.model_dump() if analysis.sandbox else None,
            summary=analysis.summary,
            recommendation=analysis.recommendation,
            limitations=analysis.limitations
        )
        
        # Generate PDF
        pdf_generator = PDFReportGenerator()
        pdf_bytes = pdf_generator.generate_report(report_data)
        
        # Return as streaming response
        filename = f"APK_Risk_Report_{analysis.package_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.pdf"
        
        return StreamingResponse(
            BytesIO(pdf_bytes),
            media_type="application/pdf",
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )
        
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_detail = f"Analysis/Report failed: {str(e)}\n{traceback.format_exc()}"
        print(f"ERROR: {error_detail}")
        raise HTTPException(status_code=500, detail=f"Analysis/Report failed: {str(e)}")


# ============================================================================
# Run Server
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True
    )
