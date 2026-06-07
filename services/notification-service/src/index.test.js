// Mock app.listen before requiring index to prevent Jest from hanging
jest.spyOn(require('express').application, 'listen').mockImplementation(function() {
  return { close: (cb) => cb && cb() };
});

const app = require('./index');

describe('Notification Service basic tests', () => {
  it('should export the app object', () => {
    expect(app).toBeDefined();
  });
});
