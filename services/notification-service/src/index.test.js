const request = require('supertest');

// Prevent app.listen from running
jest.spyOn(require('express').application, 'listen')
  .mockImplementation(() => ({
    close: cb => cb && cb()
  }));

const app = require('./index');

describe('Notification Service', () => {

  test('GET /health returns healthy', async () => {
    const response = await request(app).get('/health');

    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe('healthy');
  });

  test('GET /ready returns ready', async () => {
    const response = await request(app).get('/ready');

    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe('ready');
  });

  test('GET /notifications returns notifications list', async () => {
    const response = await request(app).get('/notifications');

    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('notifications');
    expect(response.body).toHaveProperty('count');
  });

});