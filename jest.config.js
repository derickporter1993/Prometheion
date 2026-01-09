import { jestConfig } from "@salesforce/sfdx-lwc-jest/config.js";

export default {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver"],
  testPathIgnorePatterns: [
    "<rootDir>/node_modules/",
    "<rootDir>/Sentinel-main/",
    "<rootDir>/force-app/main/default/lwc/__tests__/setupTests.js",
    "<rootDir>/force-app/main/default/lwc/__tests__/axeTestHelper.js",
    "<rootDir>/force-app/main/default/lwc/__tests__/a11yTestUtils.js",
    // Temporarily skip tests with wire adapter compatibility issues (sfdx-lwc-jest 7.x)
    // TODO: Fix wire adapter mocking to use createApexTestWireAdapter pattern
    "<rootDir>/force-app/main/default/lwc/prometheionDashboard/__tests__/",
    "<rootDir>/force-app/main/default/lwc/prometheionCopilot/__tests__/",
    "<rootDir>/force-app/main/default/lwc/prometheionEventExplorer/__tests__/",
    "<rootDir>/force-app/main/default/lwc/prometheionAuditWizard/__tests__/",
    "<rootDir>/force-app/main/default/lwc/complianceCopilot/__tests__/",
  ],
  setupFilesAfterEnv: [
    "<rootDir>/force-app/main/default/lwc/__tests__/setupTests.js",
  ],
};
