# Integration Test Checklist

## Backend Tests

Run from `d:\creater\my_first_app\backend`:

```bash
# Install dependencies
pip install -r requirements.txt

# Run all tests with coverage
python run_tests.py

# Or run quick tests
python run_tests.py --quick

# Or use pytest directly
pytest tests/ -v
```

### Test Files

| Test File | Coverage |
|-----------|----------|
| `test_permission_analyzer.py` | Permission classification, combinations, scoring |
| `test_certificate_analyzer.py` | Debug/self-signed detection, expiry, repackaging |
| `test_risk_engine.py` | Weighted scoring, classification thresholds |
| `test_api.py` | REST endpoints, validation, error handling |

### Expected Results

```
tests/test_permission_analyzer.py::TestPermissionAnalyzer::test_empty_permissions PASSED
tests/test_permission_analyzer.py::TestPermissionAnalyzer::test_safe_permissions PASSED
tests/test_permission_analyzer.py::TestPermissionAnalyzer::test_dangerous_sms_permissions PASSED
tests/test_permission_analyzer.py::TestPermissionAnalyzer::test_otp_theft_combination PASSED
tests/test_permission_analyzer.py::TestPermissionAnalyzer::test_keylogger_combination PASSED
...
```

---

## Flutter Tests

Run from `d:\creater\my_first_app`:

```bash
# Get dependencies
flutter pub get

# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

### Test Files

| Test File | Coverage |
|-----------|----------|
| `test/widget_test.dart` | RiskIndicator, PermissionCard, FindingCard, etc. |
| `test/service_test.dart` | FileService, hash verification |

---

## Manual Integration Testing

### 1. Start Backend Server

```bash
cd d:\creater\my_first_app\backend
python main.py
```

Server runs at `http://localhost:8000`

### 2. Test API Endpoints

```bash
# Health check
curl http://localhost:8000/api/v1/health

# Get limitations
curl http://localhost:8000/api/v1/limitations

# Get dangerous permissions list
curl http://localhost:8000/api/v1/permissions
```

### 3. Run Flutter App

```bash
cd d:\creater\my_first_app
flutter run
```

### 4. User Flow Testing

- [ ] App launches without errors
- [ ] "Select APK" button works
- [ ] File picker opens correctly
- [ ] APK file info displays after selection
- [ ] "Analyze" button triggers analysis
- [ ] Progress indicator shows during analysis
- [ ] Risk report displays correctly
- [ ] Tabbed report navigation works
- [ ] Consent screen shows for HIGH_RISK apps
- [ ] All checkboxes must be checked to proceed
- [ ] About screen shows limitations

---

## Acceptance Criteria

✅ Permission analyzer detects 50+ dangerous permissions  
✅ Certificate analyzer detects debug/self-signed certs  
✅ Risk engine produces weighted scores  
✅ Classification thresholds: SAFE ≤30, SUSPICIOUS ≤60, HIGH_RISK >60  
✅ OTP theft pattern (SMS + Internet) detected  
✅ Keylogger pattern (Accessibility + Internet) detected  
✅ All API endpoints return valid JSON  
✅ Flutter UI renders all risk levels correctly  
✅ Consent flow requires all acknowledgments  
