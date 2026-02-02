import { jestConfig } from "@salesforce/sfdx-lwc-jest/config.js";

export default {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/.localdevserver", "<rootDir>/platform/"],
  testPathIgnorePatterns: [
    "<rootDir>/node_modules/",
    "<rootDir>/platform/",
    "<rootDir>/force-app/main/default/lwc/__tests__/setupTests.js",
    "<rootDir>/force-app/main/default/lwc/__tests__/axeTestHelper.js",
    "<rootDir>/force-app/main/default/lwc/__tests__/a11yTestUtils.js",
    "<rootDir>/force-app/main/default/lwc/__tests__/wireAdapterTestUtils.js",
  ],
  setupFilesAfterEnv: ["<rootDir>/force-app/main/default/lwc/__tests__/setupTests.js"],
};
