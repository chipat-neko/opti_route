/*
 * Dashboard CSV viewer
 *
 * Parse le CSV genere par StatsService.exportCsvTournees :
 * `date,nom,statut,arrets,colis_livres,distance_km,duree_min,pause_min`
 *
 * Affiche stats agreges + 3 graphes Chart.js + tableau brut.
 * 100% local au navigateur : aucune requete reseau hors fonts/CDN.
 */
(function () {
  'use strict';

  // ---------- Parser CSV minimaliste RFC 4180 ----------
  function parseCSV(text) {
    const rows = [];
    let cur = '';
    let row = [];
    let inQuotes = false;

    for (let i = 0; i < text.length; i++) {
      const ch = text[i];
      const next = text[i + 1];

      if (inQuotes) {
        if (ch === '"' && next === '"') {
          cur += '"';
          i++;
        } else if (ch === '"') {
          inQuotes = false;
        } else {
          cur += ch;
        }
      } else {
        if (ch === '"') {
          inQuotes = true;
        } else if (ch === ',') {
          row.push(cur);
          cur = '';
        } else if (ch === '\n') {
          row.push(cur);
          cur = '';
          if (row.length > 1 || (row.length === 1 && row[0] !== '')) {
            rows.push(row);
          }
          row = [];
        } else if (ch === '\r') {
          // skip
        } else {
          cur += ch;
        }
      }
    }
    if (cur.length > 0 || row.length > 0) {
      row.push(cur);
      if (row.length > 1 || (row.length === 1 && row[0] !== '')) {
        rows.push(row);
      }
    }
    return rows;
  }

  // ---------- Mapping CSV -> objets ----------
  function rowsToTournees(rows) {
    if (rows.length < 2) return [];
    const header = rows[0].map((h) => h.trim().toLowerCase());
    const idx = (name) => header.indexOf(name);

    const iDate = idx('date');
    const iNom = idx('nom');
    const iStatut = idx('statut');
    const iArrets = idx('arrets');
    const iColis = idx('colis_livres');
    const iKm = idx('distance_km');
    const iDuree = idx('duree_min');
    const iPause = idx('pause_min');

    if (iDate < 0 || iNom < 0) {
      throw new Error(
        'Le CSV ne ressemble pas a un export opti_route. Header attendu : ' +
        'date,nom,statut,arrets,colis_livres,distance_km,duree_min,pause_min'
      );
    }

    const list = [];
    for (let i = 1; i < rows.length; i++) {
      const r = rows[i];
      if (r.length < 2) continue;
      list.push({
        date: r[iDate],
        nom: r[iNom],
        statut: iStatut >= 0 ? r[iStatut] : '',
        arrets: parseInt(r[iArrets] || '0', 10),
        colisLivres: parseInt(r[iColis] || '0', 10),
        km: parseFloat(r[iKm] || '0'),
        dureeMin: parseInt(r[iDuree] || '0', 10),
        pauseMin: parseInt(r[iPause] || '0', 10),
      });
    }
    return list;
  }

  // ---------- Helpers display ----------
  function formatDureeMin(min) {
    if (min < 60) return `${min} min`;
    const h = Math.floor(min / 60);
    const m = min % 60;
    return m === 0 ? `${h}h` : `${h}h${String(m).padStart(2, '0')}`;
  }

  function statutBadgeClass(s) {
    return {
      'terminee': 'badge-terminee',
      'en_cours': 'badge-encours',
      'optimisee': 'badge-optimisee',
      'brouillon': 'badge-brouillon',
    }[s] || 'badge-brouillon';
  }

  // ---------- Theme palette (lue depuis CSS vars) ----------
  function cssVar(name) {
    return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
  }

  function chartColors() {
    return {
      emerald: cssVar('--emerald') || '#0E7C5A',
      lime: cssVar('--lime') || '#B8F24A',
      amber: cssVar('--amber') || '#F2A341',
      red: cssVar('--red') || '#D9483B',
      text: cssVar('--text') || '#0E1410',
      textMute: cssVar('--text-mute') || '#5C6660',
      divider: cssVar('--divider') || 'rgba(14,20,16,0.08)',
    };
  }

  // ---------- Chart instances (pour pouvoir destroy au reload) ----------
  let charts = { colis: null, statuts: null, km: null };

  function destroyCharts() {
    for (const k in charts) {
      if (charts[k]) {
        charts[k].destroy();
        charts[k] = null;
      }
    }
  }

  function renderCharts(tournees) {
    destroyCharts();
    const c = chartColors();
    const labels = tournees.map((t) => `${t.date}\n${truncate(t.nom, 14)}`);

    Chart.defaults.font.family = "'Manrope', sans-serif";
    Chart.defaults.color = c.textMute;
    Chart.defaults.borderColor = c.divider;

    // Colis livres
    charts.colis = new Chart(document.getElementById('chartColis'), {
      type: 'bar',
      data: {
        labels,
        datasets: [{
          label: 'Colis livres',
          data: tournees.map((t) => t.colisLivres),
          backgroundColor: c.lime,
          borderRadius: 6,
        }],
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, grid: { color: c.divider } },
          x: { grid: { display: false } },
        },
      },
    });

    // Statuts (pie)
    const counts = {};
    for (const t of tournees) {
      counts[t.statut] = (counts[t.statut] || 0) + 1;
    }
    const statutLabels = Object.keys(counts);
    const statutColors = statutLabels.map((s) => ({
      'terminee': c.emerald,
      'en_cours': c.lime,
      'optimisee': c.amber,
      'brouillon': c.textMute,
    }[s] || c.textMute));

    charts.statuts = new Chart(document.getElementById('chartStatuts'), {
      type: 'doughnut',
      data: {
        labels: statutLabels,
        datasets: [{
          data: statutLabels.map((s) => counts[s]),
          backgroundColor: statutColors,
          borderColor: cssVar('--paper'),
          borderWidth: 3,
        }],
      },
      options: {
        responsive: true,
        cutout: '60%',
        plugins: {
          legend: { position: 'bottom', labels: { boxWidth: 12 } },
        },
      },
    });

    // Kilometres (line)
    charts.km = new Chart(document.getElementById('chartKm'), {
      type: 'line',
      data: {
        labels,
        datasets: [{
          label: 'Km',
          data: tournees.map((t) => t.km),
          borderColor: c.emerald,
          backgroundColor: c.emerald + '22',
          fill: true,
          tension: 0.3,
          borderWidth: 2,
          pointBackgroundColor: c.emerald,
          pointRadius: 4,
        }],
      },
      options: {
        responsive: true,
        plugins: { legend: { display: false } },
        scales: {
          y: { beginAtZero: true, grid: { color: c.divider } },
          x: { grid: { display: false } },
        },
      },
    });
  }

  function truncate(s, n) {
    if (!s) return '';
    return s.length > n ? s.slice(0, n - 1) + '…' : s;
  }

  // ---------- Render stat cards + tableau ----------
  function renderResults(tournees) {
    const totalTournees = tournees.length;
    const totalArrets = tournees.reduce((s, t) => s + t.arrets, 0);
    const totalColis = tournees.reduce((s, t) => s + t.colisLivres, 0);
    const totalKm = tournees.reduce((s, t) => s + t.km, 0);
    const totalDuree = tournees.reduce((s, t) => s + t.dureeMin, 0);

    document.getElementById('statTournees').textContent = totalTournees;
    document.getElementById('statArrets').textContent = totalArrets;
    document.getElementById('statColis').textContent = totalColis;
    document.getElementById('statKm').textContent = totalKm.toFixed(0);
    document.getElementById('statDuree').textContent = formatDureeMin(totalDuree);

    document.getElementById('bannerSummary').textContent =
      `${totalTournees} tournee${totalTournees > 1 ? 's' : ''}`;

    // Tableau
    const tbody = document.querySelector('#dataTable tbody');
    tbody.innerHTML = '';
    for (const t of tournees) {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td class="mono">${escapeHtml(t.date)}</td>
        <td>${escapeHtml(t.nom)}</td>
        <td><span class="badge ${statutBadgeClass(t.statut)}">${escapeHtml(t.statut)}</span></td>
        <td class="num">${t.arrets}</td>
        <td class="num">${t.colisLivres}</td>
        <td class="num">${t.km.toFixed(1)}</td>
        <td class="num">${t.dureeMin}</td>
        <td class="num">${t.pauseMin}</td>
      `;
      tbody.appendChild(tr);
    }

    renderCharts(tournees);

    document.getElementById('uploadZone').classList.add('hidden');
    document.getElementById('results').classList.remove('hidden');
  }

  function escapeHtml(s) {
    return String(s || '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  // ---------- File handlers ----------
  function handleFile(file) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const rows = parseCSV(e.target.result);
        const tournees = rowsToTournees(rows);
        if (tournees.length === 0) {
          alert('Le CSV est vide ou ne contient aucune tournee.');
          return;
        }
        renderResults(tournees);
      } catch (err) {
        alert('Erreur de parsing : ' + err.message);
      }
    };
    reader.readAsText(file, 'utf-8');
  }

  // ---------- Wiring ----------
  document.addEventListener('DOMContentLoaded', () => {
    const dropZone = document.getElementById('uploadZone');
    const fileInput = document.getElementById('fileInput');

    if (!dropZone || !fileInput) return;

    dropZone.addEventListener('click', () => fileInput.click());

    fileInput.addEventListener('change', (e) => {
      if (e.target.files && e.target.files[0]) handleFile(e.target.files[0]);
    });

    ['dragenter', 'dragover'].forEach((ev) => {
      dropZone.addEventListener(ev, (e) => {
        e.preventDefault();
        e.stopPropagation();
        dropZone.classList.add('dragover');
      });
    });

    ['dragleave', 'drop'].forEach((ev) => {
      dropZone.addEventListener(ev, (e) => {
        e.preventDefault();
        e.stopPropagation();
        dropZone.classList.remove('dragover');
      });
    });

    dropZone.addEventListener('drop', (e) => {
      e.preventDefault();
      e.stopPropagation();
      const files = e.dataTransfer && e.dataTransfer.files;
      if (files && files[0]) handleFile(files[0]);
    });

    // Reset
    const resetBtn = document.getElementById('resetBtn');
    if (resetBtn) {
      resetBtn.addEventListener('click', (e) => {
        e.preventDefault();
        destroyCharts();
        document.getElementById('results').classList.add('hidden');
        document.getElementById('uploadZone').classList.remove('hidden');
        fileInput.value = '';
      });
    }

    // Imprimer
    const printBtn = document.getElementById('printBtn');
    if (printBtn) {
      printBtn.addEventListener('click', () => window.print());
    }

    // Re-telecharger en CSV propre (re-encode trie)
    const dlBtn = document.getElementById('downloadXlsxBtn');
    if (dlBtn) {
      dlBtn.addEventListener('click', () => {
        const rows = Array.from(document.querySelectorAll('#dataTable tr'));
        const csv = rows.map((tr) =>
          Array.from(tr.querySelectorAll('th, td'))
            .map((td) => {
              let v = td.textContent.trim();
              if (v.includes(',') || v.includes('"') || v.includes('\n')) {
                v = '"' + v.replace(/"/g, '""') + '"';
              }
              return v;
            })
            .join(',')
        ).join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = 'opti_route-stats-' + new Date().toISOString().slice(0, 10) + '.csv';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      });
    }

    // Exemple
    const exampleBtn = document.getElementById('loadExample');
    if (exampleBtn) {
      exampleBtn.addEventListener('click', (e) => {
        e.preventDefault();
        const example = `date,nom,statut,arrets,colis_livres,distance_km,duree_min,pause_min
2026-05-08,"Lundi matin",terminee,12,18,45.3,180,15
2026-05-09,"Mardi sud",terminee,15,22,52.1,210,20
2026-05-10,"Mercredi pro",terminee,8,12,31.7,120,10
2026-05-11,"Jeudi extra",terminee,18,28,68.4,250,25
2026-05-12,"Vendredi matin",en_cours,10,5,22.0,95,5
2026-05-13,"Vendredi aprem",optimisee,14,0,0.0,0,0`;
        try {
          const rows = parseCSV(example);
          const tournees = rowsToTournees(rows);
          renderResults(tournees);
        } catch (err) {
          alert('Erreur : ' + err.message);
        }
      });
    }
  });

})();
