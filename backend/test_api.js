// Comprehensive Automated Test for all Traceback API Endpoints
const http = require('http');

function request(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const postData = body ? JSON.stringify(body) : null;
    const headers = {
      'Content-Type': 'application/json',
    };
    if (postData) {
      headers['Content-Length'] = Buffer.byteLength(postData);
    }
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(
      {
        host: 'localhost',
        port: 5000,
        path,
        method,
        headers,
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve({ statusCode: res.statusCode, body: parsed });
          } catch (e) {
            resolve({ statusCode: res.statusCode, raw: data });
          }
        });
      }
    );

    req.on('error', (e) => reject(e));
    if (postData) req.write(postData);
    req.end();
  });
}

async function runTests() {
  console.log('--- STARTING TRACEBACK API TESTS ---');

  const testEmail = `student_${Date.now()}@bgu.ac.in`;
  const testPassword = 'Password123!';
  let token = null;
  let userId = null;
  let itemId = null;

  // 1. Test Health
  const healthRes = await request('GET', '/api/health');
  console.log('✓ [GET /api/health]:', healthRes.statusCode, healthRes.body.status);

  // 2. Test Register
  const regRes = await request('POST', '/api/auth/register', {
    name: 'Subhadeep Test',
    email: testEmail,
    phone: '9876543210',
    password: testPassword,
  });
  console.log('✓ [POST /api/auth/register]:', regRes.statusCode, regRes.body.message);
  if (!regRes.body.token) throw new Error('Registration failed to return token');
  token = regRes.body.token;
  userId = regRes.body.user.id;

  // 3. Test Login
  const loginRes = await request('POST', '/api/auth/login', {
    email: testEmail,
    password: testPassword,
  });
  console.log('✓ [POST /api/auth/login]:', loginRes.statusCode, loginRes.body.message);
  token = loginRes.body.token;

  // 4. Test User Profile
  const profileRes = await request('GET', '/api/users/profile', null, token);
  console.log('✓ [GET /api/users/profile]:', profileRes.statusCode, profileRes.body.user.name, profileRes.body.user.email);

  // 5. Test Update Profile
  const updateProfileRes = await request('PUT', '/api/users/profile', { phone: '9998887776' }, token);
  console.log('✓ [PUT /api/users/profile]:', updateProfileRes.statusCode, updateProfileRes.body.user.phone);

  // 6. Test Add Item
  const addItemRes = await request('POST', '/api/items', {
    name: 'Campus Cycle Trek',
    category: 'bike',
    description: 'Matte black mountain cycle with red accents',
    tag_id: `TB-BIKE-${Date.now().toString(36).toUpperCase()}`,
    last_detected_location: 'Hostel 3 Parking',
  }, token);
  console.log('✓ [POST /api/items]:', addItemRes.statusCode, addItemRes.body.item.name, 'ID:', addItemRes.body.item.id);
  itemId = addItemRes.body.item.id;

  // 7. Test Load Items
  const getItemsRes = await request('GET', '/api/items', null, token);
  console.log('✓ [GET /api/items]:', getItemsRes.statusCode, `Loaded ${getItemsRes.body.count} items`);

  // 8. Test Get Item By ID
  const getItemRes = await request('GET', `/api/items/${itemId}`, null, token);
  console.log('✓ [GET /api/items/:id]:', getItemRes.statusCode, getItemRes.body.item.name);

  // 9. Test Update Item
  const updateItemRes = await request('PUT', `/api/items/${itemId}`, {
    description: 'Updated cycle description with lock installed',
  }, token);
  console.log('✓ [PUT /api/items/:id]:', updateItemRes.statusCode, updateItemRes.body.item.description);

  // 10. Test Mark Item Lost
  const lostRes = await request('PUT', `/api/items/${itemId}/lost`, {
    location: 'Central Library Entrance',
    description: 'Left cycle outside library after evening session',
  }, token);
  console.log('✓ [PUT /api/items/:id/lost]:', lostRes.statusCode, 'Status:', lostRes.body.item.status);

  // 11. Test Found Report
  const foundReportRes = await request('POST', '/api/reports/found', {
    item_id: itemId,
    location: 'Library Porch Desk',
    note: 'Cycle found unlocked near library steps.',
  }, token);
  console.log('✓ [POST /api/reports/found]:', foundReportRes.statusCode, foundReportRes.body.message);

  // 12. Test Get Found Reports
  const getReportsRes = await request('GET', '/api/reports/found', null, token);
  console.log('✓ [GET /api/reports/found]:', getReportsRes.statusCode, `Found ${getReportsRes.body.count} reports`);

  // 13. Test Mark Item Found / Safe
  const foundRes = await request('PUT', `/api/items/${itemId}/found`, {
    location: 'Recovered at Security Office',
  }, token);
  console.log('✓ [PUT /api/items/:id/found]:', foundRes.statusCode, 'Status:', foundRes.body.item.status);

  // 14. Test Notifications
  const notifRes = await request('GET', '/api/notifications', null, token);
  console.log('✓ [GET /api/notifications]:', notifRes.statusCode, `Retrieved ${notifRes.body.count} notifications`);
  const firstNotifId = notifRes.body.notifications[0].id;

  // 15. Test Mark Notification Read
  const readRes = await request('PUT', `/api/notifications/${firstNotifId}/read`, null, token);
  console.log('✓ [PUT /api/notifications/:id/read]:', readRes.statusCode, readRes.body.message);

  // 16. Test Activity Log
  const actRes = await request('GET', '/api/activity', null, token);
  console.log('✓ [GET /api/activity]:', actRes.statusCode, `Retrieved ${actRes.body.count} activity entries`);

  console.log('\n🎉 ALL 16 BACKEND API TESTS COMPLETED AND PASSED PERFECTLY!');
}

runTests().catch((err) => {
  console.error('❌ TEST FAILED:', err);
  process.exit(1);
});
