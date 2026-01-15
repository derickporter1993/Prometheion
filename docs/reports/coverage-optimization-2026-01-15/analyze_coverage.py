#!/usr/bin/env python3
"""
Prometheion Coverage Analysis Script
Analyzes Apex codebase to identify coverage gaps and prioritize testing work
"""

import os
import re
import json
from pathlib import Path
from collections import defaultdict

# Configuration
CLASSES_DIR = "/Users/derickporter/Prometheion/force-app/main/default/classes"
OUTPUT_DIR = "/Users/derickporter/Prometheion/docs/reports/coverage-optimization-2026-01-15"

# Business criticality tiers
CRITICAL_PATTERNS = [
    'Compliance', 'Scorer', 'Framework', 'Evidence', 'Security', 'Audit'
]
HIGH_PATTERNS = [
    'Controller', 'Service', 'Scheduler', 'Batch', 'Queueable'
]
MEDIUM_PATTERNS = [
    'Util', 'Helper', 'Factory', 'Builder', 'Manager'
]

def analyze_class_file(filepath):
    """Extract metrics from an Apex class file"""
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Count lines (excluding comments and blank lines)
    lines = [l.strip() for l in content.split('\n') if l.strip() and not l.strip().startswith('//')]
    loc = len(lines)
    
    # Count methods
    method_pattern = r'(public|private|protected|global)\s+(static\s+)?\w+\s+\w+\s*\('
    methods = len(re.findall(method_pattern, content))
    
    # Check for integration patterns
    has_callout = '@future' in content or 'HttpRequest' in content or 'HttpResponse' in content
    has_database_ops = 'Database.' in content or 'insert ' in content or 'update ' in content
    has_soql = '[SELECT' in content.upper()
    
    return {
        'loc': loc,
        'methods': methods,
        'has_callout': has_callout,
        'has_database_ops': has_database_ops,
        'has_soql': has_soql
    }

def determine_criticality(classname):
    """Determine business criticality tier"""
    for pattern in CRITICAL_PATTERNS:
        if pattern.lower() in classname.lower():
            return 'CRITICAL'
    for pattern in HIGH_PATTERNS:
        if pattern.lower() in classname.lower():
            return 'HIGH'
    for pattern in MEDIUM_PATTERNS:
        if pattern.lower() in classname.lower():
            return 'MEDIUM'
    return 'LOW'

def main():
    print("Starting Prometheion Coverage Analysis...")
    
    # Get all production classes
    prod_classes = []
    test_classes = set()
    
    for filename in os.listdir(CLASSES_DIR):
        if filename.endswith('.cls'):
            if 'Test.cls' in filename:
                # Extract base class name (remove Test.cls suffix)
                base = filename.replace('Test.cls', '')
                test_classes.add(base)
            else:
                prod_classes.append(filename.replace('.cls', ''))
    
    print(f"Found {len(prod_classes)} production classes")
    print(f"Found {len(test_classes)} test classes")
    
    # Analyze each production class
    analysis_results = []
    
    for classname in prod_classes:
        filepath = os.path.join(CLASSES_DIR, f"{classname}.cls")
        
        if not os.path.exists(filepath):
            continue
        
        metrics = analyze_class_file(filepath)
        has_test = classname in test_classes
        criticality = determine_criticality(classname)
        
        analysis_results.append({
            'class': classname,
            'has_test': has_test,
            'criticality': criticality,
            'loc': metrics['loc'],
            'methods': metrics['methods'],
            'has_callout': metrics['has_callout'],
            'has_database_ops': metrics['has_database_ops'],
            'has_soql': metrics['has_soql'],
            'priority_score': calculate_priority(metrics, has_test, criticality)
        })
    
    # Sort by priority score (highest first)
    analysis_results.sort(key=lambda x: x['priority_score'], reverse=True)
    
    # Generate reports
    generate_json_report(analysis_results)
    generate_markdown_report(analysis_results)
    generate_cursor_handoff(analysis_results)
    
    print(f"\nAnalysis complete! Reports generated in {OUTPUT_DIR}")

def calculate_priority(metrics, has_test, criticality):
    """Calculate priority score for testing"""
    score = 0
    
    # Criticality weight
    crit_weights = {'CRITICAL': 1000, 'HIGH': 500, 'MEDIUM': 200, 'LOW': 100}
    score += crit_weights.get(criticality, 0)
    
    # No test class = highest priority
    if not has_test:
        score += 5000
    
    # Complexity adds to priority
    score += metrics['loc'] // 10  # 1 point per 10 LOC
    score += metrics['methods'] * 10  # 10 points per method
    
    # Integration complexity
    if metrics['has_callout']:
        score += 200
    if metrics['has_database_ops']:
        score += 100
    if metrics['has_soql']:
        score += 50
    
    return score

def generate_json_report(results):
    """Generate JSON report for programmatic consumption"""
    output_file = os.path.join(OUTPUT_DIR, "coverage-analysis-data.json")
    
    with open(output_file, 'w') as f:
        json.dump({
            'analysis_date': '2026-01-15',
            'total_classes': len(results),
            'classes_without_tests': len([r for r in results if not r['has_test']]),
            'results': results
        }, f, indent=2)
    
    print(f"JSON report: {output_file}")

def generate_markdown_report(results):
    """Generate human-readable markdown report"""
    output_file = os.path.join(OUTPUT_DIR, "coverage-analysis-report.md")
    
    no_tests = [r for r in results if not r['has_test']]
    with_tests = [r for r in results if r['has_test']]
    
    with open(output_file, 'w') as f:
        f.write("# Prometheion Coverage Analysis Report\n\n")
        f.write("**Generated:** 2026-01-15\n\n")
        f.write("## Summary Statistics\n\n")
        f.write(f"- Total Production Classes: {len(results)}\n")
        f.write(f"- Classes Without Tests: {len(no_tests)}\n")
        f.write(f"- Classes With Tests: {len(with_tests)}\n")
        f.write(f"- Estimated Coverage Gap: {(len(no_tests)/len(results)*100):.1f}%\n\n")
        
        f.write("## Classes Without Test Coverage (Priority Order)\n\n")
        f.write("| Class | Criticality | LOC | Methods | Callouts | DB Ops | Priority |\n")
        f.write("|-------|-------------|-----|---------|----------|--------|----------|\n")
        
        for r in no_tests[:50]:  # Top 50
            f.write(f"| {r['class']} | {r['criticality']} | {r['loc']} | {r['methods']} | "
                   f"{'✓' if r['has_callout'] else ''} | {'✓' if r['has_database_ops'] else ''} | "
                   f"{r['priority_score']} |\n")
        
        if len(no_tests) > 50:
            f.write(f"\n*...and {len(no_tests) - 50} more classes*\n")
    
    print(f"Markdown report: {output_file}")

def generate_cursor_handoff(results):
    """Generate Cursor-specific task list"""
    output_file = os.path.join(OUTPUT_DIR, "CURSOR-TASK-LIST.md")
    
    no_tests = [r for r in results if not r['has_test']]
    
    with open(output_file, 'w') as f:
        f.write("# CURSOR TASK LIST - Test Class Generation\n\n")
        f.write("**Generated for Cursor IDE**\n")
        f.write("**Work Type:** Mechanical test class generation\n\n")
        
        f.write("## Instructions for Cursor\n\n")
        f.write("For each class below, generate a comprehensive test class following this template:\n\n")
        f.write("```apex\n")
        f.write("@isTest\n")
        f.write("private class <ClassName>Test {\n")
        f.write("    @TestSetup\n")
        f.write("    static void setup() {\n")
        f.write("        // Use ComplianceTestDataFactory\n")
        f.write("    }\n\n")
        f.write("    @isTest static void testPositiveScenario() { /* 200+ records */ }\n")
        f.write("    @isTest static void testNegativeScenario() { /* Error handling */ }\n")
        f.write("    @isTest static void testBulkScenario() { /* Governor limits */ }\n")
        f.write("    @isTest static void testEdgeCases() { /* Boundary conditions */ }\n")
        f.write("}\n```\n\n")
        
        f.write(f"## Classes Requiring Test Generation ({len(no_tests)} total)\n\n")
        
        for idx, r in enumerate(no_tests, 1):
            f.write(f"### {idx}. {r['class']}\n")
            f.write(f"- **Criticality:** {r['criticality']}\n")
            f.write(f"- **Complexity:** {r['loc']} LOC, {r['methods']} methods\n")
            if r['has_callout']:
                f.write(f"- **⚠️ Requires Mock:** HTTP callouts detected\n")
            if r['has_database_ops']:
                f.write(f"- **Database Operations:** Test data setup required\n")
            f.write(f"- **Priority Score:** {r['priority_score']}\n\n")
    
    print(f"Cursor handoff: {output_file}")

if __name__ == "__main__":
    main()
