document.addEventListener('DOMContentLoaded', () => {
  // Delegated navigation for elements with data-href
  document.body.addEventListener('click', (e) => {
    const nav = e.target.closest('[data-href]');
    if (nav) {
      e.preventDefault();
      window.location.href = nav.dataset.href;
      return;
    }
    const actionEl = e.target.closest('[data-action]');
    if (actionEl) {
      handleAction(actionEl, e);
    }
  });

  // Attach form handlers if present
  const resumeForm = document.getElementById('resumeUploadForm');
  if (resumeForm) {
    resumeForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const fileInput = document.getElementById('resumeFile');
      const file = fileInput?.files?.[0];
      if (!file) return;
      // For demo: show filename and clear input. Replace with upload to /api/uploads as needed.
      document.getElementById('resumeMessage').innerText = 'Resume uploaded successfully: ' + file.name;
      document.getElementById('resumeLink').innerHTML = `<a href='#'>${file.name}</a>`;
      fileInput.value = '';
    });
  }

  // Hook application form submit if present
  const appForm = document.getElementById('applicationForm');
  if (appForm) {
    appForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      const token = localStorage.getItem('token');
      const studentId = localStorage.getItem('userId');
      const companyId = document.getElementById('company').value;
      const role = document.getElementById('role').value;
      const type = document.getElementById('type').value;
      try {
        const res = await fetch('/api/applications', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token },
          body: JSON.stringify({ studentId, companyId, role, type })
        });
        if (res.ok) {
          document.getElementById('applyMsg').innerText = 'Application submitted!';
          if (typeof loadApplications === 'function') loadApplications();
          e.target.reset();
        } else {
          document.getElementById('applyMsg').innerText = 'Error submitting application.';
        }
      } catch (err) {
        console.error(err);
        document.getElementById('applyMsg').innerText = 'Error submitting application.';
      }
    });
  }

  // Auto-load companies and applications if functions available (for pages that expect them)
  if (typeof loadCompanies === 'function') loadCompanies();
  if (typeof loadApplications === 'function') loadApplications();
});

  // Provide loadCompanies and loadApplications for pages that need them
  async function loadCompanies() {
    try {
      const res = await fetch('/api/companies');
      const data = await res.json();
      const select = document.getElementById('company');
      const table = document.getElementById('companyTable');
      if (select) {
        select.innerHTML = '';
        data.forEach(c => {
          const opt = document.createElement('option');
          opt.value = c.CompanyID;
          opt.textContent = c.Name;
          select.appendChild(opt);
        });
      }
      if (table) {
        table.innerHTML = '';
        data.forEach(comp => {
          const row = document.createElement('tr');
          row.innerHTML = `
            <td>${escapeHtml(comp.Name)}</td>
            <td>${escapeHtml(comp.Industry)}</td>
            <td>${escapeHtml(comp.Location)}</td>
            <td><a href="${escapeAttr(comp.Website)}" target="_blank">${escapeHtml(comp.Website || '')}</a></td>
            <td>${escapeHtml(comp.Description || '')}</td>
            <td>
              <button data-action="edit-company" data-id="${comp.CompanyID}" data-name="${escapeAttr(comp.Name)}" data-industry="${escapeAttr(comp.Industry)}" data-location="${escapeAttr(comp.Location)}" data-website="${escapeAttr(comp.Website|| '')}" data-description="${escapeAttr(comp.Description|| '')}">Edit</button>
              <button data-action="delete-company" data-id="${comp.CompanyID}">Delete</button>
            </td>
          `;
          table.appendChild(row);
        });
      }
    } catch (err) {
      console.error('loadCompanies error', err);
    }
  }

  async function loadApplications() {
    try {
      const token = localStorage.getItem('token');
      const studentId = localStorage.getItem('userId');
      if (!studentId) return;
      const res = await fetch(`/api/applications/${studentId}`, { headers: { 'Authorization': 'Bearer ' + token } });
      const data = await res.json();
      const table = document.getElementById('statusTable');
      if (!table) return;
      table.innerHTML = '';
      data.forEach(app => {
        const row = document.createElement('tr');
        row.innerHTML = `
          <td>${escapeHtml(app.CompanyName)}</td>
          <td>${escapeHtml(app.Role)}</td>
          <td>${escapeHtml(app.Type)}</td>
          <td>${escapeHtml(app.Status)}</td>
          <td>${escapeHtml(app.Comments || '')}</td>
        `;
        table.appendChild(row);
      });
    } catch (err) {
      console.error('loadApplications error', err);
    }
  }

  function escapeHtml(s){ if(!s) return ''; return String(s).replace(/[&<>\"']/g, c=>({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":"&#39;" })[c]); }
  function escapeAttr(s){ return escapeHtml(s).replace(/"/g,'&quot;'); }

// Generic action handler
async function handleAction(el, e) {
  const action = el.dataset.action;
  switch (action) {
    case 'logout':
      localStorage.clear();
      window.location.href = 'login.html';
      break;
    case 'delete-student':
      await deleteEntity('students', el.dataset.id);
      break;
    case 'delete-faculty':
      await deleteEntity('faculty', el.dataset.id);
      break;
    case 'delete-company':
      await deleteEntity('companies', el.dataset.id);
      break;
    case 'review-application':
      await reviewApplication(el.dataset.id, el.dataset.status);
      break;
    case 'download-report':
      await downloadReport();
      break;
    default:
      console.warn('Unhandled action', action);
  }
}

async function deleteEntity(path, id) {
  if (!confirm('Are you sure?')) return;
  try {
    const res = await fetch(`/api/${path}/${id}`, { method: 'DELETE' });
    if (res.ok) window.location.reload();
  } catch (err) {
    console.error(err);
  }
}

async function reviewApplication(id, status) {
  try {
    const res = await fetch(`/api/applications/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status })
    });
    if (res.ok) window.location.reload();
  } catch (err) {
    console.error(err);
  }
}

async function downloadReport() {
  try {
    const res = await fetch('/api/reports', { method: 'GET' });
    if (!res.ok) return;
    const blob = await res.blob();
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'report.csv';
    document.body.appendChild(a);
    a.click();
    a.remove();
    URL.revokeObjectURL(url);
  } catch (err) {
    console.error(err);
  }
}

// Dashboard helpers
async function loadStats() {
  try {
    const students = await fetch('/api/students').then(r => r.json());
    const internships = await fetch('/api/internships').then(r => r.json());
    const placements = await fetch('/api/placements').then(r => r.json());
    const el = (id) => document.getElementById(id);
    if (el('totalStudents')) el('totalStudents').innerText = students.length;
    if (el('totalInternships')) el('totalInternships').innerText = internships.length;
    if (el('totalPlacements')) el('totalPlacements').innerText = placements.length;
    const avg = placements.length ? (placements.reduce((sum, p) => sum + (parseFloat(p.Package) || 0), 0) / placements.length).toFixed(2) : 0;
    if (el('avgPackage')) el('avgPackage').innerText = avg;
  } catch (err) { console.error(err); }
}

async function loadTables() {
  try {
    const placements = await fetch('/api/placements').then(r => r.json());
    const placementTable = document.getElementById('placementTable');
    if (placementTable) {
      placementTable.innerHTML = '';
      placements.forEach(p => {
        const row = placementTable.insertRow();
        row.insertCell(0).innerText = p.PlacementID;
        row.insertCell(1).innerText = p.StudentID;
        row.insertCell(2).innerText = p.Company;
        row.insertCell(3).innerText = p.Package;
        row.insertCell(4).innerText = p.Status;
      });
    }
    const internships = await fetch('/api/internships').then(r => r.json());
    const internshipTable = document.getElementById('internshipTable');
    if (internshipTable) {
      internshipTable.innerHTML = '';
      internships.forEach(i => {
        const row = internshipTable.insertRow();
        row.insertCell(0).innerText = i.InternshipID;
        row.insertCell(1).innerText = i.StudentID;
        row.insertCell(2).innerText = i.Company;
        row.insertCell(3).innerText = i.Role;
        row.insertCell(4).innerText = i.StartDate;
        row.insertCell(5).innerText = i.EndDate;
      });
    }
  } catch (err) { console.error(err); }
}

// Trigger dashboard loads if elements exist
if (document.getElementById('totalStudents') || document.getElementById('placementTable')) {
  loadStats();
  loadTables();
}

// Faculty forms (internship/placement)
const internshipForm = document.getElementById('internshipForm');
if (internshipForm) {
  internshipForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = {
      studentId: document.getElementById('internStudentId').value,
      company: document.getElementById('internCompany').value,
      role: document.getElementById('internRole').value,
      startDate: document.getElementById('internStartDate').value,
      endDate: document.getElementById('internEndDate').value
    };
    try {
      const res = await fetch('/api/internships', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) });
      if (res.ok) { alert('Internship details submitted successfully!'); internshipForm.reset(); }
      else alert('Error submitting internship details.');
    } catch (err) { console.error(err); alert('Server error.'); }
  });
}

const placementForm = document.getElementById('placementForm');
if (placementForm) {
  placementForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const data = {
      studentId: document.getElementById('placeStudentId').value,
      company: document.getElementById('placeCompany').value,
      packageAmount: document.getElementById('placePackage').value,
      status: document.getElementById('placeStatus').value
    };
    try {
      const res = await fetch('/api/placements', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(data) });
      if (res.ok) { alert('Placement details submitted successfully!'); placementForm.reset(); }
      else alert('Error submitting placement details.');
    } catch (err) { console.error(err); alert('Server error.'); }
  });
}
