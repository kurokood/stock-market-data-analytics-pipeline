#!/usr/bin/env pwsh
# Setup script for pre-commit hooks
# This script installs and configures pre-commit hooks for the project

Write-Host "🔧 Setting up pre-commit hooks for Terraform project" -ForegroundColor Green

$ErrorActionPreference = "Stop"

try {
    # Check if Python is installed
    Write-Host "🐍 Checking Python installation..." -ForegroundColor Yellow
    $pythonVersion = python --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Python is not installed or not in PATH. Please install Python 3.7+ first."
    }
    Write-Host "✅ Found Python: $pythonVersion" -ForegroundColor Green
    
    # Check if pip is available
    Write-Host "📦 Checking pip installation..." -ForegroundColor Yellow
    pip --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "pip is not available. Please ensure pip is installed."
    }
    Write-Host "✅ pip is available" -ForegroundColor Green
    
    # Install pre-commit
    Write-Host "⬇️  Installing pre-commit..." -ForegroundColor Yellow
    pip install pre-commit
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install pre-commit"
    }
    Write-Host "✅ pre-commit installed successfully" -ForegroundColor Green
    
    # Install pre-commit hooks
    Write-Host "🪝 Installing pre-commit hooks..." -ForegroundColor Yellow
    pre-commit install
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install pre-commit hooks"
    }
    Write-Host "✅ Pre-commit hooks installed successfully" -ForegroundColor Green
    
    # Install commit-msg hook for conventional commits (optional)
    Write-Host "📝 Installing commit-msg hook..." -ForegroundColor Yellow
    pre-commit install --hook-type commit-msg
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Failed to install commit-msg hook (optional)" -ForegroundColor Yellow
    } else {
        Write-Host "✅ Commit-msg hook installed successfully" -ForegroundColor Green
    }
    
    # Run pre-commit on all files to test setup
    Write-Host "🧪 Testing pre-commit setup..." -ForegroundColor Yellow
    Write-Host "This may take a few minutes on first run as it downloads tools..." -ForegroundColor Gray
    
    pre-commit run --all-files
    if ($LASTEXITCODE -ne 0) {
        Write-Host "⚠️  Some pre-commit checks failed, but setup is complete" -ForegroundColor Yellow
        Write-Host "Run 'pre-commit run --all-files' to see and fix issues" -ForegroundColor Gray
    } else {
        Write-Host "✅ All pre-commit checks passed!" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "🎉 Pre-commit setup completed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Cyan
    Write-Host "  • Hooks will run automatically on git commit" -ForegroundColor Gray
    Write-Host "  • Run manually: pre-commit run --all-files" -ForegroundColor Gray
    Write-Host "  • Update hooks: pre-commit autoupdate" -ForegroundColor Gray
    Write-Host "  • Skip hooks: git commit --no-verify" -ForegroundColor Gray
    
} catch {
    Write-Host "❌ Pre-commit setup failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Manual setup instructions:" -ForegroundColor Yellow
    Write-Host "1. Install Python 3.7+ from https://python.org" -ForegroundColor Gray
    Write-Host "2. Run: pip install pre-commit" -ForegroundColor Gray
    Write-Host "3. Run: pre-commit install" -ForegroundColor Gray
    Write-Host "4. Run: pre-commit run --all-files" -ForegroundColor Gray
    exit 1
}