import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import { AdminApi } from './api';
import './styles.css';

async function start() {
  const demo = import.meta.env.DEV && import.meta.env.VITE_DEMO === 'true';
  const api = demo ? new AdminApi((await import('./demo')).createDemoTransport()) : new AdminApi();
  ReactDOM.createRoot(document.getElementById('root')!).render(<React.StrictMode><App api={api} demo={demo}/></React.StrictMode>);
}
void start();
