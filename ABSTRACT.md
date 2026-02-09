# 📄 Abstract

## Team Name
*(Fill in your team name)*

---

## Problem Statement
Android users frequently download and install APK files from third-party sources, exposing themselves to significant security risks including malware, spyware, data theft, and privacy breaches. Currently, there is no user-friendly, consent-based solution that allows non-technical users to assess the potential risks of an APK file **before installation**. This gap leaves millions of users vulnerable to malicious applications that can compromise their personal data, financial information, and device security.

---

## Proposed Solution
**APK Risk Analyzer** is a mobile application that performs comprehensive pre-installation security assessment of Android APK files using both static and sandbox-based analysis. The app scans uploaded APK files and provides users with:

- **Risk Score Classification** (Safe / Suspicious / High Risk)
- **Sandbox-Based Inspection** via VirusTotal integration and local behavior simulation
- **Detailed Permission Analysis** identifying dangerous permissions
- **Certificate Verification** detecting debug/expired/self-signed signatures
- **Obfuscation Detection** flagging suspicious code patterns
- **Network Endpoint Extraction** revealing embedded URLs
- **PDF Report Generation** for documentation and sharing

The solution empowers users to make **informed, consent-based decisions** before installing any third-party application, with full transparency about analysis limitations.

---

## Technical Approach

### System Architecture
```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│   Flutter App    │     │   FastAPI        │     │   Analysis       │
│   (Mobile UI)    │◄───►│   Backend        │◄───►│   Engines        │
│                  │     │                  │     │                  │
│ • File Selection │     │ • APK Processing │     │ • APK Parser     │
│ • Consent Screen │     │ • Risk Scoring   │     │ • Permission     │
│ • Risk Reports   │     │ • PDF Generation │     │ • Certificate    │
│ • PDF Download   │     │ • Sandbox API    │     │ • Obfuscation    │
└──────────────────┘     └──────────────────┘     │ • Network        │
                                │                 │ • Sandbox        │
                                ▼                 └──────────────────┘
                         ┌──────────────────┐
                         │   VirusTotal     │
                         │   Cloud Sandbox  │
                         │   (70+ AV scans) │
                         └──────────────────┘
```

### Technology Stack
| Component | Technology | Purpose |
|-----------|------------|---------|
| **Mobile App** | Flutter (Dart) | Cross-platform UI with modern glassmorphism design |
| **Backend API** | FastAPI (Python) | RESTful API for APK processing |
| **APK Parsing** | Androguard | Extract manifest, permissions, certificates, DEX code |
| **Sandbox** | VirusTotal API + Local Simulator | Multi-engine AV scanning & behavior detection |
| **PDF Reports** | ReportLab | Professional PDF report generation |
| **Cloud Hosting** | Render.com | Scalable deployment with Docker containerization |

### Analysis Pipeline
1. **Upload**: User uploads APK → SHA256 hash verification
2. **Parse**: Androguard extracts metadata (permissions, certificate, components)
3. **Static Analysis**: Permission, certificate, obfuscation, network analyzers run
4. **Sandbox Analysis**: 
   - VirusTotal API queries 70+ antivirus engines (if API key configured)
   - Local sandbox simulator detects suspicious patterns (dynamic loading, root checks, etc.)
5. **Risk Calculation**: Weighted scoring combines all analysis results
6. **Report**: JSON response + downloadable PDF report generation

### API Endpoints
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/analyze/upload` | POST | Analyze uploaded APK file |
| `/api/v1/report/pdf` | POST | Generate PDF from analysis results |
| `/api/v1/analyze-and-report` | POST | Analyze APK and return PDF directly |
| `/api/v1/health` | GET | API health check |
| `/api/v1/limitations` | GET | Transparency about analysis limits |

---

## Expected Outcomes ✅

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| ✅ Basic sandbox-based APK inspection | **DONE** | VirusTotal API (70+ AV) + Local behavior simulator |
| ✅ Pre-installation APK risk analysis | **DONE** | Complete analysis before any installation |
| ✅ Permission and authenticity verification | **DONE** | Permission analyzer + Certificate analyzer |
| ✅ Risk score or safety classification | **DONE** | 0-100 score with SAFE/SUSPICIOUS/HIGH_RISK |
| ✅ Clear warning for unsafe APKs | **DONE** | UI warnings + detailed findings + recommendations |
| ✅ Informed user consent to proceed | **DONE** | Consent screen with explicit acknowledgment |
| ✅ PDF Report Generation | **BONUS** | Professional PDF reports for documentation |

---

## Feasibility

| Aspect | Assessment |
|--------|------------|
| **Technical** | ✅ Fully implemented with working prototype |
| **Sandbox** | ✅ VirusTotal provides free tier (500 lookups/day); local simulator as fallback |
| **Infrastructure** | ✅ Cloud-deployed on Render.com with Docker support |
| **Cost** | ✅ Free tier hosting; VirusTotal free API available |
| **User Adoption** | ✅ Simple UX with one-click analysis; no technical knowledge required |
| **Limitations** | ⚠️ Static + cloud sandbox; cannot fully replace device-level dynamic analysis |
| **Market Demand** | ✅ Growing sideloading culture; increasing need for pre-install security |

### Current Status
✅ **Fully functional** with:
- Flutter mobile app with modern UI
- FastAPI backend with sandbox integration
- VirusTotal cloud sandbox + local behavior simulator
- PDF report generation
- Cloud deployment on Render.com

---

## Files Modified/Added

### New Files:
- `backend/analyzer/virustotal_analyzer.py` - VirusTotal API + Local sandbox simulator
- `backend/analyzer/pdf_generator.py` - PDF report generator

### Modified Files:
- `backend/main.py` - Added sandbox analysis to pipeline, new PDF endpoints
- `backend/analyzer/__init__.py` - Exported new modules
- `backend/requirements.txt` - Added aiohttp, reportlab dependencies

---

## Environment Variables (Optional)
```
VIRUSTOTAL_API_KEY=your_free_api_key_here
```
*Get free API key at: https://www.virustotal.com/gui/join-us*
