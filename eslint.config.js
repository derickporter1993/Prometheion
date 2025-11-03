import babelParser from '@babel/eslint-parser';
import lwc from '@lwc/eslint-plugin-lwc';
import prettier from 'eslint-config-prettier';

export default [
  {
    files: ['force-app/**/*.js'],
    languageOptions: {
      parser: babelParser,
      parserOptions: {
        requireConfigFile: false,
        babelOptions: {
          parserOpts: {
            plugins: ['classProperties', 'decorators-legacy']
          }
        },
        ecmaVersion: 2021,
        sourceType: 'module'
      },
      globals: {
        console: 'readonly',
        document: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        Date: 'readonly',
        Math: 'readonly'
      }
    },
    plugins: {
      lwc
    },
    rules: {
      'no-console': 'warn',
      'no-unused-vars': 'warn'
    }
  },
  prettier
];
