const request = require('supertest');

jest.spyOn(require('express').application, 'listen')
  .mockImplementation(() => ({
    close: cb => cb && cb()
  }));

const app = require('./index');

describe('Order Service', () => {

  test('GET /health returns healthy', async () => {
    const response = await request(app).get('/health');

    expect(response.statusCode).toBe(200);
    expect(response.body.status).toBe('healthy');
  });

  test('GET /orders returns order list', async () => {
    const response = await request(app).get('/orders');

    expect(response.statusCode).toBe(200);
    expect(response.body).toHaveProperty('orders');
    expect(response.body).toHaveProperty('count');
  });

  test('POST /orders returns 400 when required fields are missing', async () => {
    const response = await request(app)
      .post('/orders')
      .send({});

    expect(response.statusCode).toBe(400);
    expect(response.body.error).toBe('Bad Request');
  });

  test('PATCH /orders/:id/status rejects invalid status', async () => {
    const response = await request(app)
      .patch('/orders/ord-001/status')
      .send({
        status: 'INVALID_STATUS'
      });

    expect(response.statusCode).toBe(400);
    expect(response.body.error).toBe('Bad Request');
  });

});