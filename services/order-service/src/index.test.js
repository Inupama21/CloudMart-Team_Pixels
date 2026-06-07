// Mock app.listen before requiring index to prevent Jest from hanging
jest.spyOn(require('express').prototype, 'listen').mockImplementation(function() {
  return { close: (cb) => cb && cb() };
});

const app = require('./index');

describe('Order Service basic tests', () => {
  it('should export the app object', () => {
    expect(app).toBeDefined();
  });
});
