// Jest Setup File
// Test uchun global sozlamalar

// Timeout for async tests
jest.setTimeout(10000);

// Mock console.log in tests to reduce noise
global.console = {
    ...console,
    log: jest.fn(),
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: console.error // Keep error visible
};

// Global test helpers
global.testHelpers = {
    generatePhone: () => `+998${Math.floor(900000000 + Math.random() * 99999999)}`,
    generatePin: () => Math.floor(1000 + Math.random() * 9000).toString(),
    generateDeviceId: () => `test-device-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`
};
