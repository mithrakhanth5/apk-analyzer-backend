"""
Test Runner Script for APK Risk Analyzer Backend
Run all tests with coverage reporting
"""
import subprocess
import sys
import os

def run_tests():
    """Run pytest with coverage"""
    # Change to backend directory
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    
    print("=" * 60)
    print("APK Risk Analyzer - Backend Test Suite")
    print("=" * 60)
    
    # Run pytest with coverage
    result = subprocess.run([
        sys.executable, "-m", "pytest",
        "tests/",
        "-v",
        "--cov=analyzer",
        "--cov-report=term-missing",
        "--cov-report=html:coverage_report",
        "-x",  # Stop on first failure
    ])
    
    if result.returncode == 0:
        print("\n" + "=" * 60)
        print("✅ All tests passed!")
        print("Coverage report generated in: coverage_report/")
        print("=" * 60)
    else:
        print("\n" + "=" * 60)
        print("❌ Some tests failed!")
        print("=" * 60)
    
    return result.returncode


def run_quick_tests():
    """Run tests without coverage for faster feedback"""
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    os.chdir(backend_dir)
    
    print("Running quick tests...")
    result = subprocess.run([
        sys.executable, "-m", "pytest",
        "tests/",
        "-v",
        "--tb=short",
    ])
    
    return result.returncode


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--quick":
        sys.exit(run_quick_tests())
    else:
        sys.exit(run_tests())
