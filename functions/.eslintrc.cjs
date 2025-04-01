module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    ecmaVersion: 2022,
    sourceType: "module",
  },
  extends: ["eslint:recommended", "google"],
  rules: {
    "no-restricted-globals": ["error", "name", "length"],
    "prefer-arrow-callback": "error",
    "quotes": ["error", "double", { allowTemplateLiterals: true }], // Fixed quotes property
    "object-curly-spacing": ["error", "always"], // Enforce consistent spacing in objects
    "max-len": ["error", { code: 150 }], // Increase line length limit from 80 to 120
    "linebreak-style": ["off"],
    "indent": ["off"], // Disable the indent rule
    "no-trailing-spaces": ["off"], // Disable the no-trailing-spaces rule
    "comma-dangle": ["off"], // Optionally disable comma-dangle if it's also causing issues
    "require-jsdoc": ["off"], // Optionally disable require-jsdoc if you don't want JSDoc comments
    "eol-last": ["off"], // Optionally disable eol-last if the newline at end of file is an issue
  },
  overrides: [
    {
      files: ["**/*.spec.*"],
      env: {
        mocha: true,
      },
      rules: {},
    },
  ],
  globals: {},
};
