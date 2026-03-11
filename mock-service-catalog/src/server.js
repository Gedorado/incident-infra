import express from 'express';

const app = express();
const port = Number(process.env.PORT || 3001);

const services = {
  'payments-api': {
    serviceId: 'payments-api',
    ownerEmail: 'payments-team@example.com',
    tier: 'tier-1'
  },
  'orders-api': {
    serviceId: 'orders-api',
    ownerEmail: 'orders-team@example.com',
    tier: 'tier-2'
  },
  'webhooks-api': {
    serviceId: 'webhooks-api',
    ownerEmail: 'integrations-team@example.com',
    tier: 'tier-3'
  }
};

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

app.get('/services/:serviceId', (req, res) => {
  const { serviceId } = req.params;
  const service = services[serviceId];

  if (!service) {
    return res.status(404).json({
      message: `Service ${serviceId} not found`
    });
  }

  return res.json(service);
});

app.listen(port, () => {
  console.log(`Service Catalog Mock listening on port ${port}`);
});
