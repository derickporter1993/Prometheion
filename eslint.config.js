import js from "@eslint/js";
import babelParser from "@babel/eslint-parser";
import lwc from "@lwc/eslint-plugin-lwc";
import prettier from "eslint-config-prettier";

const sharedLanguageOptions = {
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
};

const lwcRecommended = lwc.configs.recommended ?? {};

export default [
  {
    ignores: ["**/node_modules/**", "**/*.zip", "**/coverage/**"],
  },
  {
    ...js.configs.recommended,
    files: ["**/*.js", "**/*.mjs", "**/*.cjs"],
    languageOptions: {
      ...(js.configs.recommended.languageOptions ?? {}),
      ...sharedLanguageOptions,
    },
  },
  {
    ...lwcRecommended,
    files: ["force-app/**/*.js"],
    languageOptions: {
      ...(lwcRecommended.languageOptions ?? {}),
      ...sharedLanguageOptions,
      globals: {
        ...(lwcRecommended.languageOptions?.globals ?? {}),
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
      ...(lwcRecommended.plugins ?? {}),
      lwc,
    },
    rules: {
      ...(lwcRecommended.rules ?? {}),
      "no-console": "warn",
      "no-unused-vars": ["warn", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
    },
  },
  prettier,
];
