#!/usr/bin/env node
/**
 * Accessibility Audit Script for Elaro LWC Components
 *
 * This script performs static analysis of LWC HTML templates to identify
 * common WCAG 2.1 AA accessibility issues.
 *
 * Usage: npm run test:a11y
 */

import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const LWC_PATH = path.join(__dirname, "../force-app/main/default/lwc");

// WCAG 2.1 AA Rules
const rules = {
  // Check for buttons without aria-label or accessible name
  buttonWithoutLabel: {
    id: "button-name",
    description: "Buttons must have discernible text",
    wcag: "4.1.2",
    severity: "critical",
    pattern:
      /<button[^>]*(?!aria-label)[^>]*>\s*<(?:svg|img|lightning-icon)[^>]*>\s*<\/button>/gi,
    fix: 'Add aria-label attribute to icon-only buttons',
  },

  // Check for images without alt text
  imageWithoutAlt: {
    id: "image-alt",
    description: "Images must have alternative text",
    wcag: "1.1.1",
    severity: "critical",
    pattern: /<img(?![^>]*alt=)[^>]*>/gi,
    fix: 'Add alt="" for decorative images or descriptive alt text for informative images',
  },

  // Check for SVGs without aria-hidden for decorative
  svgWithoutAriaHidden: {
    id: "svg-decorative",
    description: "Decorative SVGs should have aria-hidden",
    wcag: "1.1.1",
    severity: "moderate",
    pattern:
      /<svg(?![^>]*aria-hidden)[^>]*>(?![\s\S]*<title>)[\s\S]*?<\/svg>/gi,
    fix: 'Add aria-hidden="true" for decorative SVGs or add <title> for informative SVGs',
  },

  // Check for form inputs without labels
  inputWithoutLabel: {
    id: "input-label",
    description: "Form inputs must have associated labels",
    wcag: "1.3.1",
    severity: "critical",
    pattern: /<input(?![^>]*aria-label)[^>]*type=["'](?!hidden)[^"']*["'][^>]*>/gi,
    additionalCheck: (content, match) => {
      // Check if input has id and there's a label for it
      const idMatch = match.match(/id=["']([^"']+)["']/);
      if (idMatch) {
        const hasLabel = new RegExp(
          `<label[^>]*for=["']${idMatch[1]}["']`,
          "i"
        ).test(content);
        if (hasLabel) return false; // Has label, not a violation
      }
      return true; // No label found
    },
    fix: "Add a <label> with for attribute or add aria-label to the input",
  },

  // Check for interactive elements with onclick but no keyboard support
  divWithOnclick: {
    id: "click-interactive",
    description:
      "Interactive elements should be buttons or have keyboard support",
    wcag: "2.1.1",
    severity: "serious",
    pattern: /<div[^>]*onclick[^>]*>/gi,
    additionalCheck: (content, match) => {
      // Check if it also has onkeydown or onkeypress
      return !(/onkey(?:down|press|up)/i.test(match));
    },
    fix: "Convert to <button> or add keyboard event handlers (onkeydown)",
  },

  // Check for modals without proper ARIA attributes
  // Only check the main modal section element, not child elements
  modalWithoutAria: {
    id: "dialog-aria",
    description: "Dialogs must have proper ARIA attributes",
    wcag: "4.1.2",
    severity: "serious",
    pattern: /<section[^>]*class=["'][^"']*(?:slds-modal)[^"']*["'][^>]*>/gi,
    additionalCheck: (content, match) => {
      const hasRole = /role=["']dialog["']/i.test(match);
      const hasAriaModal = /aria-modal=["']true["']/i.test(match);
      const hasAriaLabelledby = /aria-labelledby/i.test(match);
      return !(hasRole && hasAriaModal && hasAriaLabelledby);
    },
    fix: 'Add role="dialog" aria-modal="true" aria-labelledby="heading-id"',
  },

  // Check for headings that skip levels
  headingSkip: {
    id: "heading-order",
    description: "Heading levels should not skip",
    wcag: "1.3.1",
    severity: "moderate",
    customCheck: (content) => {
      const headings = [];
      const headingRegex = /<h([1-6])/gi;
      let match;
      while ((match = headingRegex.exec(content)) !== null) {
        headings.push(parseInt(match[1], 10));
      }

      const violations = [];
      for (let i = 1; i < headings.length; i++) {
        if (headings[i] > headings[i - 1] + 1) {
          violations.push({
            issue: `Heading level skipped from h${headings[i - 1]} to h${headings[i]}`,
            line: null,
          });
        }
      }
      return violations;
    },
    fix: "Ensure heading levels are sequential (h1 → h2 → h3, not h1 → h3)",
  },

  // Check for color contrast issues in inline styles
  lowContrastText: {
    id: "color-contrast",
    description: "Text must have sufficient color contrast",
    wcag: "1.4.3",
    severity: "serious",
    pattern: /color:\s*#(?:[0-9a-f]{3}|[0-9a-f]{6})\s*;/gi,
    additionalCheck: (content, match) => {
      // Extract color and check if it's likely low contrast (light colors)
      const colorMatch = match.match(/#([0-9a-f]{3}|[0-9a-f]{6})/i);
      if (colorMatch) {
        const hex = colorMatch[1];
        const r =
          hex.length === 3
            ? parseInt(hex[0] + hex[0], 16)
            : parseInt(hex.slice(0, 2), 16);
        const g =
          hex.length === 3
            ? parseInt(hex[1] + hex[1], 16)
            : parseInt(hex.slice(2, 4), 16);
        const b =
          hex.length === 3
            ? parseInt(hex[2] + hex[2], 16)
            : parseInt(hex.slice(4, 6), 16);
        // Check if very light (likely low contrast against white)
        return r > 200 && g > 200 && b > 200;
      }
      return false;
    },
    fix: "Ensure color contrast ratio is at least 4.5:1 for normal text",
  },

  // Check for tabindex greater than 0
  positiveTabindex: {
    id: "tabindex-positive",
    description: "Avoid positive tabindex values",
    wcag: "2.4.3",
    severity: "serious",
    pattern: /tabindex=["'][1-9][0-9]*["']/gi,
    fix: 'Use tabindex="0" for focusable elements or tabindex="-1" for programmatic focus',
  },

  // Check for auto-playing media
  autoplayMedia: {
    id: "autoplay",
    description: "Auto-playing media can cause accessibility issues",
    wcag: "1.4.2",
    severity: "serious",
    pattern: /<(?:audio|video)[^>]*autoplay/gi,
    fix: "Remove autoplay or provide controls to pause",
  },

  // Check for links without href
  // Only check actual anchor tags, not other elements
  linkWithoutHref: {
    id: "link-href",
    description: "Links must have valid href",
    wcag: "2.4.4",
    severity: "moderate",
    pattern: /<a\s+(?![^>]*href)[^>]*>/gi,
    additionalCheck: (content, match) => {
      // Make sure it's actually an anchor tag (starts with <a followed by space or >)
      return /^<a[\s>]/i.test(match);
    },
    fix: "Add href attribute or convert to button",
  },

  // Check for empty links
  emptyLink: {
    id: "link-name",
    description: "Links must have discernible text",
    wcag: "2.4.4",
    severity: "critical",
    pattern: /<a[^>]*>\s*<\/a>/gi,
    fix: "Add text content or aria-label to links",
  },
};

/**
 * Find line number for a match in content
 */
function getLineNumber(content, index) {
  const lines = content.substring(0, index).split("\n");
  return lines.length;
}

/**
 * Audit a single HTML file
 */
function auditFile(filePath) {
  const content = fs.readFileSync(filePath, "utf-8");
  const violations = [];
  const relativePath = path.relative(process.cwd(), filePath);

  for (const [ruleName, rule] of Object.entries(rules)) {
    if (rule.customCheck) {
      // Run custom check function
      const customViolations = rule.customCheck(content);
      customViolations.forEach((v) => {
        violations.push({
          file: relativePath,
          rule: rule.id,
          description: rule.description,
          severity: rule.severity,
          wcag: rule.wcag,
          line: v.line,
          issue: v.issue,
          fix: rule.fix,
        });
      });
    } else if (rule.pattern) {
      // Run pattern-based check
      let match;
      const regex = new RegExp(rule.pattern.source, rule.pattern.flags);

      while ((match = regex.exec(content)) !== null) {
        let isViolation = true;

        // Run additional check if provided
        if (rule.additionalCheck) {
          isViolation = rule.additionalCheck(content, match[0]);
        }

        if (isViolation) {
          violations.push({
            file: relativePath,
            rule: rule.id,
            description: rule.description,
            severity: rule.severity,
            wcag: rule.wcag,
            line: getLineNumber(content, match.index),
            issue: match[0].substring(0, 100) + (match[0].length > 100 ? "..." : ""),
            fix: rule.fix,
          });
        }
      }
    }
  }

  return violations;
}

/**
 * Get all HTML files in LWC directory
 */
function getLwcHtmlFiles(dir) {
  const files = [];

  function walkDir(currentPath) {
    const entries = fs.readdirSync(currentPath, { withFileTypes: true });

    for (const entry of entries) {
      const fullPath = path.join(currentPath, entry.name);

      if (entry.isDirectory() && entry.name !== "__tests__") {
        walkDir(fullPath);
      } else if (entry.isFile() && entry.name.endsWith(".html")) {
        files.push(fullPath);
      }
    }
  }

  walkDir(dir);
  return files;
}

/**
 * Format violations for console output
 */
function formatViolations(violations) {
  const grouped = {};

  violations.forEach((v) => {
    if (!grouped[v.file]) {
      grouped[v.file] = [];
    }
    grouped[v.file].push(v);
  });

  let output = "";

  for (const [file, fileViolations] of Object.entries(grouped)) {
    output += `\n📄 ${file}\n`;
    output += "─".repeat(60) + "\n";

    fileViolations.forEach((v, index) => {
      const severityIcon =
        v.severity === "critical"
          ? "🔴"
          : v.severity === "serious"
            ? "🟠"
            : "🟡";
      output += `  ${severityIcon} [${v.rule}] ${v.description}\n`;
      output += `     Line ${v.line || "?"}: ${v.issue}\n`;
      output += `     WCAG: ${v.wcag} | Fix: ${v.fix}\n`;
      if (index < fileViolations.length - 1) output += "\n";
    });
  }

  return output;
}

/**
 * Main function
 */
function main() {
  console.log("🔍 Elaro Accessibility Audit");
  console.log("═".repeat(60));
  console.log("Scanning LWC components for WCAG 2.1 AA violations...\n");

  const htmlFiles = getLwcHtmlFiles(LWC_PATH);
  console.log(`Found ${htmlFiles.length} HTML files to audit\n`);

  let allViolations = [];
  let filesWithViolations = 0;

  htmlFiles.forEach((file) => {
    const violations = auditFile(file);
    if (violations.length > 0) {
      filesWithViolations++;
      allViolations = allViolations.concat(violations);
    }
  });

  // Print results
  if (allViolations.length === 0) {
    console.log("✅ No accessibility violations found!");
    console.log("\nAll components passed the automated WCAG 2.1 AA audit.");
  } else {
    console.log(formatViolations(allViolations));
    console.log("═".repeat(60));
    console.log("\n📊 Summary");
    console.log("─".repeat(30));
    console.log(`Files scanned: ${htmlFiles.length}`);
    console.log(`Files with violations: ${filesWithViolations}`);
    console.log(`Total violations: ${allViolations.length}`);

    const bySeverity = {
      critical: allViolations.filter((v) => v.severity === "critical").length,
      serious: allViolations.filter((v) => v.severity === "serious").length,
      moderate: allViolations.filter((v) => v.severity === "moderate").length,
    };

    console.log(
      `  🔴 Critical: ${bySeverity.critical} | 🟠 Serious: ${bySeverity.serious} | 🟡 Moderate: ${bySeverity.moderate}`
    );

    console.log("\n💡 Run individual tests with: npm run test:unit -- --testPathPattern=<component>");
    console.log("📖 WCAG 2.1 Guidelines: https://www.w3.org/WAI/WCAG21/quickref/\n");

    // Exit with error code if critical violations found
    if (bySeverity.critical > 0) {
      process.exit(1);
    }
  }
}

main();
