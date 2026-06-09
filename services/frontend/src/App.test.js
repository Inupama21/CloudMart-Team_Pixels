import { render, screen } from '@testing-library/react';
import App from './App';

beforeEach(() => {
  global.fetch = jest.fn(() =>
    Promise.resolve({
      json: () =>
        Promise.resolve({
          products: []
        })
    })
  );
});

afterEach(() => {
  jest.restoreAllMocks();
});

describe('CloudMart Frontend', () => {
  test('renders CloudMart header', () => {
    render(<App />);

    expect(screen.getByText('CloudMart')).toBeInTheDocument();
  });

  test('renders Products page', () => {
    render(<App />);

    expect(screen.getByText('Products')).toBeInTheDocument();
  });

  test('renders Login button', () => {
    render(<App />);

    expect(screen.getByText('Login')).toBeInTheDocument();
  });
});