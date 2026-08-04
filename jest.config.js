const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');
const setupFilesAfterEnv = jestConfig.setupFilesAfterEnv || [];
setupFilesAfterEnv.push('<rootDir>/jest-sa11y-setup.js');
module.exports = {
    ...jestConfig,
    moduleNameMapper: {
        '^@salesforce/apex$': '<rootDir>/force-app/test/jest-mocks/apex',
        '^@salesforce/schema$': '<rootDir>/force-app/test/jest-mocks/schema',
        '^lightning/navigation$': '<rootDir>/force-app/test/jest-mocks/lightning/navigation',
        '^lightning/platformShowToastEvent$': '<rootDir>/force-app/test/jest-mocks/lightning/platformShowToastEvent',
        '^lightning/uiRecordApi$': '<rootDir>/force-app/test/jest-mocks/lightning/uiRecordApi',
        '^lightning/messageService$': '<rootDir>/force-app/test/jest-mocks/lightning/messageService',
        '^c/button$': '<rootDir>/force-app/test/jest-mocks/c/button/button',
        '^c/hot_freelanceCommonTable$':
            '<rootDir>/force-app/test/jest-mocks/c/hot_freelanceCommonTable/hot_freelanceCommonTable'
    },
    setupFiles: ['jest-canvas-mock'],
    setupFilesAfterEnv,
    testTimeout: 10000
};
