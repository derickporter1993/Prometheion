const { defaults } = require("@salesforce/sfdx-lwc-jest/config");

module.exports = {
  ...defaults,
  modulePathIgnorePatterns: ["<rootDir>/Sentinel-main/"],
  testPathIgnorePatterns: ["<rootDir>/node_modules/", "<rootDir>/Sentinel-main/"],
};
