import js from "@eslint/js";
import lwcConfig from "@salesforce/eslint-config-lwc";
import prettier from "eslint-config-prettier";

export default [
  {
    ignores: ["**/node_modules/**", "**/*.zip", "**/coverage/**", "**/Sentinel-main/**"],
  },
  js.configs.recommended,
  ...lwcConfig.configs.recommended,
  {
    files: ["force-app/**/*.js"],
    rules: {
      "no-console": "warn",
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      "@lwc/lwc/no-async-operation": "off", // Allow setTimeout/setInterval for debouncing and polling
    },
  },
  prettier,
];
