const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        '^lightning/modal$': '<rootDir>/force-app/test/jest-mocks/lightning/modal',
        '^c/button$': '<rootDir>/force-app/test/jest-mocks/c/button/button',
        '^c/checkbox$': '<rootDir>/force-app/test/jest-mocks/c/checkbox/checkbox',
        '^c/radiobuttons$': '<rootDir>/force-app/test/jest-mocks/c/radiobuttons/radiobuttons',
        '^c/recordFilesWithSharing$':
            '<rootDir>/force-app/test/jest-mocks/c/recordFilesWithSharing/recordFilesWithSharing'
    },
    setupFiles: ['jest-canvas-mock'],
    setupFilesAfterEnv,
    testTimeout: 10000
};
