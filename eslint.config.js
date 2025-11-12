import babelParser from "@babel/eslint-parser";
import lwc from "@lwc/eslint-plugin-lwc";
import prettier from "eslint-config-prettier";

export default [
  {
    files: ["force-app/**/*.js"],
    languageOptions: {
      parser: babelParser,
      parserOptions: {
        requireConfigFile: false,
        babelOptions: {
          parserOpts: {
            plugins: ["classProperties", "decorators-legacy"],
          },
        },
        ecmaVersion: 2021,
        sourceType: "module",
      },
      globals: {
        console: "readonly",
        document: "readonly",
        setInterval: "readonly",
        clearInterval: "readonly",
        setTimeout: "readonly",
        clearTimeout: "readonly",
        Date: "readonly",
        Math: "readonly",
      },
    },
    plugins: {
      lwc,
    },
    rules: {
      // Standard JavaScript rules
      "no-console": "warn",
      "no-unused-vars": "warn",

      // LWC specific rules
      "lwc/consistent-component-name": "error",
      "lwc/no-api-reassignments": "error",
      "lwc/no-deprecated": "warn",
      "lwc/no-document-query": "error",
      "lwc/no-inner-html": "error",
      "lwc/no-async-await": "off",
      "lwc/no-leading-uppercase-api-name": "error",
      "lwc/valid-api": "error",
      "lwc/valid-track": "error",
      "lwc/valid-wire": "error",
    },
  },
  prettier,
];
