// Fetch and display student data
async function loadStudents() {
  try {
    const res = await fetch("/api/students");
    const students = await res.json();

    let html = "<h2>Students</h2><table border='1'><tr><th>ID</th><th>Name</th><th>Resume</th></tr>";
    students.forEach(s => {
      html += `<tr>
        <td>${s.id}</td>
        <td>${s.name}</td>
        <td><a href="${s.resumeUrl}" target="_blank">View Resume</a></td>
      </tr>`;
    });
    html += "</table>";

    document.getElementById("studentData").innerHTML = html;
  } catch (err) {
    console.error(err);
    document.getElementById("studentData").innerHTML = "<p>Error loading students</p>";
  }
}

// Fetch and display internships & placements
async function loadFacultyData() {
  try {
    // Internships
    const internRes = await fetch("/api/internships"); // (We’ll add this route next in backend if missing)
    let internships = [];
    if (internRes.ok) internships = await internRes.json();

    // Placements
    const placeRes = await fetch("/api/placements"); // (We’ll add this route next in backend if missing)
    let placements = [];
    if (placeRes.ok) placements = await placeRes.json();

    let html = "<h2>Internships</h2><table border='1'><tr><th>Student ID</th><th>Company</th><th>Role</th><th>Duration</th></tr>";
    internships.forEach(i => {
      html += `<tr>
        <td>${i.studentId}</td>
        <td>${i.company}</td>
        <td>${i.role}</td>
        <td>${i.duration}</td>
      </tr>`;
    });
    html += "</table>";

    html += "<h2>Placements</h2><table border='1'><tr><th>Student ID</th><th>Company</th><th>Role</th><th>Package</th></tr>";
    placements.forEach(p => {
      html += `<tr>
        <td>${p.studentId}</td>
        <td>${p.company}</td>
        <td>${p.role}</td>
        <td>${p.packageAmount}</td>
      </tr>`;
    });
    html += "</table>";

    document.getElementById("facultyData").innerHTML = html;
  } catch (err) {
    console.error(err);
    document.getElementById("facultyData").innerHTML = "<p>Error loading faculty data</p>";
  }
}

// Load everything when page starts
window.onload = () => {
  loadStudents();
  loadFacultyData();
};