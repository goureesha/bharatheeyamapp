// ═══════════════════════════════════════════
// BHARATHEEYAM ADMIN DASHBOARD - APP LOGIC
// ═══════════════════════════════════════════

// Firebase config (same as your app)
const firebaseConfig = {
  apiKey: 'AIzaSyAkG1hdauVlL9b8nHM5o2B25yPQ6IANci4',
  authDomain: 'bharatheeyam-app.firebaseapp.com',
  projectId: 'bharatheeyam-app',
  storageBucket: 'bharatheeyam-app.firebasestorage.app',
  messagingSenderId: '212430902387',
  appId: '1:212430902387:web:149c933fd3d29aa5014606',
  measurementId: 'G-BNTGY2WSLZ',
};

firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const db = firebase.firestore();

// Only your admin email can access
const ADMIN_EMAIL = 'goureesh3690@gmail.com';

let allClients = [];
let currentUnlockEmail = null;
let currentRevokeEmail = null;

// ─── Auth ───

function signInWithGoogle() {
  const provider = new firebase.auth.GoogleAuthProvider();
  auth.signInWithPopup(provider).catch(err => {
    alert('Sign-in failed: ' + err.message);
  });
}

function signOut() {
  auth.signOut();
}

auth.onAuthStateChanged(user => {
  if (user && user.email === ADMIN_EMAIL) {
    document.getElementById('loginScreen').classList.add('hidden');
    document.getElementById('dashboard').classList.remove('hidden');
    document.getElementById('adminEmail').textContent = user.email;
    loadClients();
  } else if (user) {
    alert('Access denied. Only ' + ADMIN_EMAIL + ' can access this dashboard.');
    auth.signOut();
  } else {
    document.getElementById('loginScreen').classList.remove('hidden');
    document.getElementById('dashboard').classList.add('hidden');
  }
});

// ─── Load Clients ───

async function loadClients() {
  try {
    const snapshot = await db.collection('device_bindings').get();
    allClients = [];
    
    snapshot.forEach(doc => {
      const data = doc.data();
      allClients.push({
        email: doc.id,
        ...data,
        _isPremium: data.manualPremium === true,
        _isTrialActive: data.isTrialActive === true,
        _daysLeft: getDaysLeft(data),
        _expiryDate: getExpiryDate(data),
        _lastSeenStr: formatTimestamp(data.lastSeen),
        _lastSeenDate: data.lastSeen ? data.lastSeen.toDate() : null,
      });
    });

    // Sort: premium first, then by last seen
    allClients.sort((a, b) => {
      if (a._isPremium && !b._isPremium) return -1;
      if (!a._isPremium && b._isPremium) return 1;
      if (a._lastSeenDate && b._lastSeenDate) return b._lastSeenDate - a._lastSeenDate;
      return 0;
    });

    updateStats();
    updateExpiryTimeline();
    filterClients();
  } catch (err) {
    console.error('Error loading clients:', err);
    document.getElementById('clientTableBody').innerHTML =
      '<tr><td colspan="9" class="empty-state">Error loading data: ' + err.message + '</td></tr>';
  }
}

function getDaysLeft(data) {
  if (data.manualPremium !== true) return -1;
  if (!data.manualPremiumExpiry) return Infinity; // Lifetime
  const expiry = data.manualPremiumExpiry.toDate();
  const now = new Date();
  return Math.ceil((expiry - now) / (1000 * 60 * 60 * 24));
}

function getExpiryDate(data) {
  if (!data.manualPremiumExpiry) return null;
  return data.manualPremiumExpiry.toDate();
}

function formatTimestamp(ts) {
  if (!ts) return '—';
  const d = ts.toDate();
  const now = new Date();
  const diff = now - d;
  
  if (diff < 3600000) return Math.floor(diff / 60000) + 'm ago';
  if (diff < 86400000) return Math.floor(diff / 3600000) + 'h ago';
  if (diff < 604800000) return Math.floor(diff / 86400000) + 'd ago';
  
  return d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

function formatDate(date) {
  if (!date) return '—';
  return date.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
}

// ─── Stats ───

function updateStats() {
  const total = allClients.length;
  const premium = allClients.filter(c => c._isPremium).length;
  const trial = allClients.filter(c => c._isTrialActive && !c._isPremium).length;
  const expiring7 = allClients.filter(c => c._isPremium && c._daysLeft > 0 && c._daysLeft <= 7).length;

  animateNumber('totalClients', total);
  animateNumber('premiumClients', premium);
  animateNumber('trialClients', trial);
  animateNumber('expiringClients', expiring7);
}

function animateNumber(id, target) {
  const el = document.getElementById(id);
  const start = parseInt(el.textContent) || 0;
  if (start === target) { el.textContent = target; return; }
  
  const duration = 400;
  const startTime = Date.now();
  
  function tick() {
    const elapsed = Date.now() - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    el.textContent = Math.round(start + (target - start) * eased);
    if (progress < 1) requestAnimationFrame(tick);
  }
  tick();
}

// ─── Expiry Timeline ───

function updateExpiryTimeline() {
  const container = document.getElementById('expiryTimeline');
  const premiumClients = allClients.filter(c => c._isPremium && c._expiryDate);
  
  // Group by expiry date
  const byDate = {};
  premiumClients.forEach(c => {
    const key = c._expiryDate.toISOString().split('T')[0];
    if (!byDate[key]) byDate[key] = [];
    byDate[key].push(c.email);
  });

  const sorted = Object.entries(byDate).sort(([a], [b]) => a.localeCompare(b));
  
  if (sorted.length === 0) {
    container.innerHTML = '<p class="empty-state">No upcoming expirations</p>';
    return;
  }

  // Show next 30 days only
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() + 365);
  
  container.innerHTML = sorted
    .filter(([dateStr]) => new Date(dateStr) <= cutoff)
    .map(([dateStr, emails]) => {
      const d = new Date(dateStr);
      const daysUntil = Math.ceil((d - new Date()) / (1000 * 60 * 60 * 24));
      const dateLabel = d.toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' });
      const urgency = daysUntil <= 7 ? 'color: var(--red)' : daysUntil <= 30 ? 'color: var(--orange)' : '';
      
      return `
        <div class="expiry-day" style="border-color: ${daysUntil <= 7 ? 'var(--red)' : daysUntil <= 30 ? 'var(--orange)' : 'var(--border)'}">
          <div class="expiry-day-date">${dateLabel}</div>
          <div class="expiry-day-count" style="${urgency}">${emails.length}</div>
          <div class="expiry-day-label">${daysUntil <= 0 ? 'EXPIRED' : daysUntil + ' days left'}</div>
          <div class="expiry-day-emails">${emails.join('<br>')}</div>
        </div>
      `;
    }).join('') || '<p class="empty-state">No expirations in the next year</p>';
}

// ─── Filter & Search ───

function filterClients() {
  const search = document.getElementById('searchBox').value.toLowerCase();
  const filter = document.getElementById('filterSelect').value;

  let filtered = allClients;

  // Apply filter
  switch (filter) {
    case 'premium':
      filtered = filtered.filter(c => c._isPremium);
      break;
    case 'trial':
      filtered = filtered.filter(c => c._isTrialActive && !c._isPremium);
      break;
    case 'expired':
      filtered = filtered.filter(c => !c._isPremium && !c._isTrialActive);
      break;
    case 'expiring7':
      filtered = filtered.filter(c => c._isPremium && c._daysLeft > 0 && c._daysLeft <= 7);
      break;
    case 'expiring30':
      filtered = filtered.filter(c => c._isPremium && c._daysLeft > 0 && c._daysLeft <= 30);
      break;
  }

  // Apply search
  if (search) {
    filtered = filtered.filter(c =>
      c.email.toLowerCase().includes(search) ||
      (c.deviceName || '').toLowerCase().includes(search) ||
      (c.deviceModel || '').toLowerCase().includes(search) ||
      (c.deviceId || '').toLowerCase().includes(search)
    );
  }

  renderTable(filtered);
}

// ─── Render Table ───

function renderTable(clients) {
  const tbody = document.getElementById('clientTableBody');

  if (clients.length === 0) {
    tbody.innerHTML = '<tr><td colspan="9" class="empty-state">No clients found</td></tr>';
    return;
  }

  tbody.innerHTML = clients.map((c, i) => {
    // Status badge
    let statusBadge;
    if (c._isPremium && c._daysLeft === Infinity) {
      statusBadge = '<span class="badge badge-lifetime">Lifetime</span>';
    } else if (c._isPremium) {
      statusBadge = '<span class="badge badge-premium">Premium</span>';
    } else if (c._isTrialActive) {
      statusBadge = '<span class="badge badge-trial">Trial</span>';
    } else {
      statusBadge = '<span class="badge badge-expired">Expired</span>';
    }

    // Days left
    let daysDisplay;
    if (c._isPremium && c._daysLeft === Infinity) {
      daysDisplay = '<span class="days-left days-green">∞</span>';
    } else if (c._isPremium && c._daysLeft > 30) {
      daysDisplay = `<span class="days-left days-green">${c._daysLeft}</span>`;
    } else if (c._isPremium && c._daysLeft > 7) {
      daysDisplay = `<span class="days-left days-orange">${c._daysLeft}</span>`;
    } else if (c._isPremium && c._daysLeft > 0) {
      daysDisplay = `<span class="days-left days-red">${c._daysLeft}</span>`;
    } else if (c._isTrialActive) {
      daysDisplay = `<span class="days-left days-orange">${c.trialMinutesRemaining || 0}m</span>`;
    } else {
      daysDisplay = '<span class="days-left" style="color: var(--muted)">—</span>';
    }

    // Actions
    let actions;
    if (c._isPremium) {
      actions = `<button class="btn-revoke-small" onclick="openRevokeModal('${c.email}')">Revoke</button>`;
    } else {
      actions = `<button class="btn-unlock" onclick="openUnlockModal('${c.email}')">Unlock</button>`;
    }

    const device = c.deviceName || c.deviceModel || '—';
    const version = c.appVersion || '—';

    return `
      <tr>
        <td style="color: var(--muted)">${i + 1}</td>
        <td style="font-weight: 600">${c.email}</td>
        <td style="color: var(--muted); font-size: 12px">${device}</td>
        <td>${statusBadge}</td>
        <td>${daysDisplay}</td>
        <td style="font-size: 12px; color: var(--muted)">${formatDate(c._expiryDate)}</td>
        <td style="font-size: 12px; color: var(--muted)">${c._lastSeenStr}</td>
        <td style="font-size: 12px; color: var(--muted)">${version}</td>
        <td>${actions}</td>
      </tr>
    `;
  }).join('');
}

// ─── Unlock / Revoke Modals ───

function openUnlockModal(email) {
  currentUnlockEmail = email;
  document.getElementById('unlockEmail').textContent = email;
  document.getElementById('unlockModal').classList.remove('hidden');
}

function openRevokeModal(email) {
  currentRevokeEmail = email;
  document.getElementById('revokeEmail').textContent = email;
  document.getElementById('revokeModal').classList.remove('hidden');
}

function closeModal() {
  document.getElementById('unlockModal').classList.add('hidden');
  document.getElementById('revokeModal').classList.add('hidden');
  currentUnlockEmail = null;
  currentRevokeEmail = null;
}

async function confirmUnlock() {
  if (!currentUnlockEmail) return;

  const days = parseInt(document.getElementById('unlockDuration').value);
  const updateData = { manualPremium: true };

  if (days > 0) {
    const expiry = new Date();
    expiry.setDate(expiry.getDate() + days);
    expiry.setHours(23, 59, 59, 0);
    updateData.manualPremiumExpiry = firebase.firestore.Timestamp.fromDate(expiry);
  }
  // If days === 0, lifetime — no expiry field

  try {
    await db.collection('device_bindings').doc(currentUnlockEmail).update(updateData);
    closeModal();
    loadClients();
  } catch (err) {
    alert('Error: ' + err.message);
  }
}

async function confirmRevoke() {
  if (!currentRevokeEmail) return;

  try {
    await db.collection('device_bindings').doc(currentRevokeEmail).update({
      manualPremium: false,
      manualPremiumExpiry: firebase.firestore.FieldValue.delete(),
    });
    closeModal();
    loadClients();
  } catch (err) {
    alert('Error: ' + err.message);
  }
}

// Close modal on backdrop click
document.addEventListener('click', e => {
  if (e.target.classList.contains('modal')) closeModal();
});

// Close modal on Escape
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeModal();
});
