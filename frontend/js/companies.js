document.addEventListener('DOMContentLoaded', () => {
// companies.js - moved from inline script to external file to satisfy CSP
document.addEventListener('DOMContentLoaded', () => {
  const form = document.getElementById('addCompanyForm');
  const tableBody = document.getElementById('companyTable');
  const cancelBtn = document.getElementById('cancelEdit');

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const id = document.getElementById('companyId').value;
    const name = document.getElementById('companyName').value;
    const industry = document.getElementById('industry').value;
    const location = document.getElementById('location').value;
    const website = document.getElementById('website').value;
    const description = document.getElementById('description').value;

    const payload = { name, industry, location, website, description };
    let method = 'POST';
    let url = '/api/companies';
    if (id) {
      method = 'PUT';
      url = `/api/companies/${id}`;
    }
    try {
      const res = await fetch(url, {
        method,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });
      if (res.ok) {
        alert(id ? 'Company updated!' : 'Company added!');
        resetForm();
        loadCompanies();
      } else {
        alert('Failed to save company');
      }
    } catch (err) {
      console.error('Error saving company:', err);
    }
  });

  cancelBtn.addEventListener('click', resetForm);

  // Event delegation for edit/delete buttons
  tableBody.addEventListener('click', (e) => {
    const editBtn = e.target.closest('[data-action="edit"]');
    if (editBtn) {
      const id = editBtn.dataset.id;
      const name = editBtn.dataset.name || '';
      const industry = editBtn.dataset.industry || '';
      const location = editBtn.dataset.location || '';
      const website = editBtn.dataset.website || '';
      const description = editBtn.dataset.description || '';
      populateForm(id, name, industry, location, website, description);
      return;
    }
    const delBtn = e.target.closest('[data-action="delete"]');
    if (delBtn) {
      const id = delBtn.dataset.id;
      deleteCompany(id);
      return;
    }
  });

  async function loadCompanies() {
    try {
      const res = await fetch('/api/companies');
      const data = await res.json();
      tableBody.innerHTML = '';
      data.forEach(comp => {
        const row = document.createElement('tr');
        const website = comp.Website || '';
        const description = comp.Description || '';
        row.innerHTML = `
          <td>${escapeHtml(comp.Name)}</td>
          <td>${escapeHtml(comp.Industry)}</td>
          <td>${escapeHtml(comp.Location)}</td>
          <td><a href="${escapeAttr(website)}" target="_blank">${escapeHtml(website)}</a></td>
          <td>${escapeHtml(description)}</td>
          <td>
            <button type="button" data-action="edit" data-id="${comp.CompanyID}" data-name="${escapeAttr(comp.Name)}" data-industry="${escapeAttr(comp.Industry)}" data-location="${escapeAttr(comp.Location)}" data-website="${escapeAttr(website)}" data-description="${escapeAttr(description)}">Edit</button>
            <button type="button" data-action="delete" data-id="${comp.CompanyID}">Delete</button>
          </td>
        `;
        tableBody.appendChild(row);
      });
    } catch (err) {
      console.error('Error loading companies:', err);
    }
  }

  function populateForm(id, name, industry, location, website, description) {
    document.getElementById('companyId').value = id;
    document.getElementById('companyName').value = name;
    document.getElementById('industry').value = industry;
    document.getElementById('location').value = location;
    document.getElementById('website').value = website;
    document.getElementById('description').value = description;
    document.getElementById('formTitle').innerText = 'Edit Company';
    document.getElementById('cancelEdit').style.display = '';
  }

  async function deleteCompany(id) {
    if (!confirm('Delete this company?')) return;
    try {
      const res = await fetch('/api/companies/' + id, { method: 'DELETE' });
      if (res.ok) {
        alert('Company deleted');
        loadCompanies();
      }
    } catch (err) {
      console.error('Error deleting company:', err);
    }
  }

  function resetForm() {
    document.getElementById('companyId').value = '';
    document.getElementById('companyName').value = '';
    document.getElementById('industry').value = '';
    document.getElementById('location').value = '';
    document.getElementById('website').value = '';
    document.getElementById('description').value = '';
    document.getElementById('formTitle').innerText = 'Add New Company';
    document.getElementById('cancelEdit').style.display = 'none';
  }

  function escapeHtml(str) {
    if (!str && str !== 0) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  function escapeAttr(str) {
    return escapeHtml(str);
  }

  // Initialize
  loadCompanies();
});
