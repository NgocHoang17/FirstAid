// Requires mock_ai_fixture.js on 127.0.0.1:18081 and backend configured to call it.
const base = 'http://127.0.0.1:18080/api/v1/assistant/query';

async function ask(message) {
  const response = await fetch(base, {
    method: 'POST', headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ client_request_id: crypto.randomUUID(), message, age_group: null, context_mode: 'learning' }),
  });
  if (response.status !== 200) throw new Error(`Unexpected HTTP ${response.status}`);
  return (await response.json()).data;
}

const valid = await ask('valid');
const stale = await ask('stale');
const emergency = await ask('emergency');
if (valid.status !== 'answered' || valid.citations[0]?.source_title !== 'CẨM NANG SƠ CẤP CỨU')
  throw new Error('Valid citation was not mapped from DB');
if (stale.status !== 'insufficient_evidence' || stale.answer_blocks.length !== 0)
  throw new Error('Stale source revision was not rejected');
if (emergency.status !== 'emergency_redirect' || emergency.safety_message_code !== 'CONTACT_HELP')
  throw new Error('Emergency status contract failed');
console.log('PASS: answered citation mapping, stale citation rejection, emergency redirect');
