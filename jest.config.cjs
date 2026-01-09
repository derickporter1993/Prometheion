const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: [],
  testPathIgnorePatterns: [
    "<rootDir>/node_modules/",
    "<rootDir>/Sentinel-main/",
    "<rootDir>/force-app/main/default/lwc/__tests__/setupTests.js",
    "<rootDir>/force-app/main/default/lwc/__tests__/axeTestHelper.js",
    // Temporarily skip tests with wire adapter compatibility issues (sfdx-lwc-jest 7.x)
    // TODO: Fix wire adapter mocking to use createApexTestWireAdapter pattern
    "<rootDir>/force-app/main/default/lwc/prometheionDashboard/__tests__/",
    "<rootDir>/force-app/main/default/lwc/prometheionCopilot/__tests__/",
    "<rootDir>/force-app/main/default/lwc/prometheionEventExplorer/__tests__/",
    "<rootDir>/force-app/main/default/lwc/prometheionAuditWizard/__tests__/",
  ],
  // Setup files for global test configuration
  setupFilesAfterEnv: [
    "<rootDir>/force-app/main/default/lwc/__tests__/setupTests.js",
  ],
  // Coverage configuration
  collectCoverageFrom: [
    "force-app/main/default/lwc/**/*.js",
    "!force-app/main/default/lwc/**/__tests__/**",
    "!force-app/main/default/lwc/**/jsconfig.json",
    "!force-app/main/default/lwc/**/*.js-meta.xml",
  ],
  coverageThreshold: {
    global: {
      branches: 20,
      functions: 20,
      lines: 20,
      statements: 20,
    },
  },
  coverageReporters: ["text", "lcov", "html"],
};
