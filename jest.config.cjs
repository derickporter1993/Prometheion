const { jestConfig } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...jestConfig,
  modulePathIgnorePatterns: ["<rootDir>/Sentinel-main/"],
  testPathIgnorePatterns: ["<rootDir>/node_modules/", "<rootDir>/Sentinel-main/"],
};
