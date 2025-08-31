const App = (() => {
  const state = {
    payload: null,
    jobs: {},
    employees: [],
    view: 'home',
    empJob: null,
    chart: null,
    jd: { job: null, tab: 'employees' },
    scope: { mode: 'admin', job: null },
    recipes: {},
  };
  const $  = (sel) => document.querySelector(sel);
  const $$ = (sel) => document.querySelectorAll(sel);

  let collectShopItems = () => [];
  let collectTeleports = () => [];

  function renderShopItemsSection(box, items = []) {
    box.innerHTML = `
      <div id="shop-items"></div>
      <div class="row"><button class="btn" id="addShopItem">+ Añadir artículo</button></div>`;
    const wrap = box.querySelector('#shop-items');
    function addRow(data = {}) {
      const row = document.createElement('div');
      row.className = 'row shop-item';
      row.innerHTML = `
        <div><input class="input siname" placeholder="Ítem" value="${data.name || ''}"/></div>
        <div><input class="input siprice" placeholder="Precio" type="number" value="${data.price || 0}"/></div>
        <div><input class="input siamount" placeholder="Cantidad" type="number" value="${data.amount || 1}"/></div>
        <div><input class="input siinfo" placeholder='Metadata JSON' value='${data.info ? JSON.stringify(data.info) : ''}'/></div>
        <div><button class="btn danger del">X</button></div>`;
      wrap.appendChild(row);
      row.querySelector('.del').onclick = () => row.remove();
    }
    (items || []).forEach(addRow);
    box.querySelector('#addShopItem').onclick = () => addRow();
    collectShopItems = () => {
      const list = [];
      wrap.querySelectorAll('.shop-item').forEach((r) => {
        const name = r.querySelector('.siname').value.trim();
        if (!name) return;
        const price = Number(r.querySelector('.siprice').value) || 0;
        const amount = Number(r.querySelector('.siamount').value) || 1;
        const infoTxt = r.querySelector('.siinfo').value.trim();
        let info;
        if (infoTxt) { try { info = JSON.parse(infoTxt); } catch { info = infoTxt; } }
        list.push({ name, price, amount, info });
      });
      return list;
    };
  }

  function renderTeleportSection(box, items = []) {
    box.innerHTML = `
      <div id="tp-items"></div>
      <div class="row"><button class="btn" id="addTP">+ Destino</button></div>`;
    const wrap = box.querySelector('#tp-items');
    function addRow(data = {}) {
      const row = document.createElement('div');
      row.className = 'row tp-item';
      row.innerHTML = `
        <div><input class="input tplabel" placeholder="Nombre" value="${data.label || ''}"/></div>
        <div><input class="input tpx" placeholder="X" value="${data.x || ''}"/></div>
        <div><input class="input tpy" placeholder="Y" value="${data.y || ''}"/></div>
        <div><input class="input tpz" placeholder="Z" value="${data.z || ''}"/></div>
        <div><input class="input tpw" placeholder="Heading" value="${data.w || ''}"/></div>
        <div><button class="btn tpcoords">Usar mis coords</button></div>
        <div><button class="btn danger del">X</button></div>`;
      wrap.appendChild(row);
      row.querySelector('.del').onclick = () => row.remove();
      const setCoords = (c) => {
        if (!c) { toast('No se pudieron leer tus coords', 'error'); return; }
        if (c.x !== undefined) row.querySelector('.tpx').value = c.x;
        if (c.y !== undefined) row.querySelector('.tpy').value = c.y;
        if (c.z !== undefined) row.querySelector('.tpz').value = c.z;
        if (c.w !== undefined) row.querySelector('.tpw').value = c.w;
      };
      row.querySelector('.tpcoords').onclick = () => {
        postJ('getCoords', {}).then(setCoords);
      };
    }
    (items || []).forEach(addRow);
    if (!items || items.length === 0) addRow();
    box.querySelector('#addTP').onclick = () => addRow();
    collectTeleports = () => {
      const list = [];
      wrap.querySelectorAll('.tp-item').forEach((r) => {
        const label = r.querySelector('.tplabel').value.trim();
        const x = Number(r.querySelector('.tpx').value) || 0;
        const y = Number(r.querySelector('.tpy').value) || 0;
        const z = Number(r.querySelector('.tpz').value) || 0;
        const w = Number(r.querySelector('.tpw').value) || 0;
        list.push({ label, x, y, z, w });
      });
      return list;
    };
  }

  function renderIngredientSection(box, items = []) {
    box.innerHTML = `
      <div id="ing-items"></div>
      <div class="row"><button class="btn" id="addIng">+ Ingrediente</button></div>`;
    const wrap = box.querySelector('#ing-items');
    function addRow(data = {}) {
      const row = document.createElement('div');
      row.className = 'row ing-item';
      row.innerHTML = `
        <div><input class="input iname" placeholder="Ítem" value="${data.item || ''}"/></div>
        <div><input class="input iamnt" type="number" placeholder="Cantidad" value="${data.amount || 1}"/></div>
        <div><button class="btn danger del">X</button></div>`;
      wrap.appendChild(row);
      row.querySelector('.del').onclick = () => row.remove();
    }
    (items || []).forEach(addRow);
    box.querySelector('#addIng').onclick = () => addRow();
    return () => {
      const list = [];
      wrap.querySelectorAll('.ing-item').forEach((r) => {
        const item = r.querySelector('.iname').value.trim();
        const amount = Number(r.querySelector('.iamnt').value) || 0;
        if (item && amount > 0) list.push({ item, amount, label: item });
      });
      return list;
    };
  }

  // === Resource-aware NUI fetch helper ===
  const RESOURCE = (typeof GetParentResourceName === 'function')
    ? GetParentResourceName()
    : (window.resourceName || 'qb-jobcreator');

  window.resourceName = RESOURCE;

  const post = (name, data = {}) => {
    return fetch(`https://${RESOURCE}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=utf-8' },
      body: JSON.stringify(data),
    });
  };
  window.post = post;

  // --- Helper robusto para NUI JSON (evita "Unexpected end of JSON input")
  async function postJ(name, data = {}) {
    try {
      const r = await post(name, data);
      if (!r.ok) throw new Error(`${name} -> HTTP ${r.status}`);
      const txt = await r.text();              // algunas callbacks pueden no devolver body
      if (!txt) return null;                   // tratamos vacío como null
      try { return JSON.parse(txt); } catch { return null; }
    } catch (e) {
      console.log('[jobcreator] fetch fail ->', name, e);
      toast(`Error de conexión (${name})`, 'error');
      return null;
    }
  }

  function money(n) {
    return new Intl.NumberFormat('es-CO', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(n || 0);
  }

  // ===== Toasts =====
  let customNotify = null;
  function ensureToast() {
    if ($('#toast-wrap')) return;
    const w = document.createElement('div');
    w.id = 'toast-wrap';
    w.style.position = 'fixed';
    w.style.top = '16px';
    w.style.right = '16px';
    w.style.zIndex = '9999';
    w.style.display = 'flex';
    w.style.flexDirection = 'column';
    w.style.gap = '8px';
    document.body.appendChild(w);
  }
  function toast(msg, type = 'info') {
    if (typeof customNotify === 'function') {
      return customNotify(msg, type);
    }
    ensureToast();
    const t = document.createElement('div');
    t.textContent = msg;
    t.style.padding = '10px 12px';
    t.style.borderRadius = '8px';
    t.style.background = type === 'error' ? '#ff4d4f' : type === 'success' ? '#2ecc71' : '#3b82f6';
    t.style.color = '#fff';
    t.style.boxShadow = '0 8px 24px rgba(0,0,0,.25)';
    $('#toast-wrap').appendChild(t);
    setTimeout(() => {
      t.style.transition = 'opacity .25s';
      t.style.opacity = '0';
      setTimeout(() => t.remove(), 300);
    }, 1800);
  }
  window.jobCreatorToast = toast;
  window.setJobCreatorNotify = (fn) => { customNotify = typeof fn === 'function' ? fn : null; };

  function show() { $('#app').classList.remove('hidden'); }
  function hide() { $('#app').classList.add('hidden'); }

  document.addEventListener('DOMContentLoaded', () => { hide(); });

  window.addEventListener('message', (e) => {
    const { action, payload } = e.data || {};
    if (action === 'open') {
      const pay = (payload && typeof payload === 'object')
        ? payload
        : {
            ok: true,
            jobs: {},
            zones: [],
            totals: { jobs: 0, employees: 0, money: 0 },
            popular: [],
            branding: { Title: 'LatinLife RP', Logo: 'logo.png' },
            scope: { mode: 'admin' },
          };

      state.payload = pay;
      state.jobs    = pay.jobs || {};
      state.scope   = pay.scope || { mode: 'admin' };

      applyBranding(pay.branding);
      applyScope();

      postJ('getCraftingTable').then((r) => {
        if (Array.isArray(r)) { const o = {}; r.forEach((x) => { if (x && x.name) o[x.name] = x; }); state.recipes = o; }
        else { state.recipes = r || {}; }
      });

      // si viene como boss, entrar directo al panel del trabajo
      if (pay.scope && pay.scope.mode === 'boss' && pay.scope.job) {
        state.jd = { job: pay.scope.job, tab: 'employees' };
        $$('.view').forEach((vw) => vw.classList.add('hidden'));
        $('#view-jobdetail').classList.remove('hidden');
        $('#jd-title').textContent = (state.jobs[pay.scope.job]?.label || pay.scope.job) + ' · Panel';
      }

      renderAll();
      show();
      return;
    }
    if (action === 'update') {
      if (!payload) return;
      state.payload = payload;
      state.jobs = payload.jobs || state.jobs;
      if (payload.scope) state.scope = payload.scope;
      applyBranding(payload.branding);
      applyScope();
      postJ('getCraftingTable').then((r) => {
        if (Array.isArray(r)) { const o = {}; r.forEach((x) => { if (x && x.name) o[x.name] = x; }); state.recipes = o; }
        else { state.recipes = r || {}; }
      });
      renderAll();
      return;
    }
    if (action === 'craftingData') {
      const r = payload && payload.recipes;
      if (Array.isArray(r)) { const o = {}; r.forEach((x) => { if (x && x.name) o[x.name] = x; }); state.recipes = o; }
      else { state.recipes = r || {}; }
      return;
    }
    if (action === 'hide' || action === 'force-close') { hide(); return; }
  });

  function applyBranding(b) {
    if (!b) return;
    $('#brand-title').textContent = b.Title || 'LatinLife RP';
    if (b.Logo) $('#brand-logo').src = b.Logo;
  }

  function applyScope() {
    const boss = state.scope && state.scope.mode === 'boss';
    const sidebar = $$('.sidebar button');
    if (boss) {
      // ocultar navegación global; solo jobdetail
      sidebar.forEach((btn) => { if (!['jobdetail'].includes(btn.dataset.view)) btn.classList.add('hidden'); });
      if (state.scope.job) { state.jd.job = state.scope.job; selectView('jobdetail'); }
    } else {
      sidebar.forEach((btn) => btn.classList.remove('hidden'));
    }
  }

  document.addEventListener('keydown', (e) => { if (e.key === 'Escape') { post('close', {}); hide(); } });

  $$('.sidebar button').forEach((b) => b.addEventListener('click', () => selectView(b.dataset.view)));
  function selectView(v) {
    const boss = state.scope && state.scope.mode === 'boss';
    if (boss && v !== 'jobdetail') { return; } // bosses solo ven su panel
    state.view = v;
    $$('.sidebar button').forEach((b) => b.classList.toggle('active', b.dataset.view === v));
    $$('.view').forEach((vw) => vw.classList.add('hidden'));
    $(`#view-${v}`).classList.remove('hidden');
    if (v === 'home')      renderHome();
    if (v === 'jobs')      renderJobs();
    if (v === 'employees') renderEmployees();
    if (v === 'stats')     renderStats();
    if (v === 'crafting')  renderCrafting();
    if (v === 'jobdetail') renderJD();
  }

  function renderHome() {
    const t = state.payload.totals || { jobs: 0, employees: 0, money: 0 };
    $('#metric-jobs').textContent      = t.jobs;
    $('#metric-employees').textContent = t.employees;
    $('#metric-money').textContent     = money(t.money);
    $('#metric-top').textContent       = ((state.payload.popular || [])[0] && (state.payload.popular || [])[0].name) || '-';

    const labels = (state.payload.popular || []).slice(0, 10).map((x) => x.name);
    const data   = (state.payload.popular || []).slice(0, 10).map((x) => x.count);
    const ctx = document.getElementById('employeesChart');
    if (state.chart) state.chart.destroy();
    state.chart = new Chart(ctx, {
      type: 'bar',
      data: { labels, datasets: [{ label: 'Empleados', data }] },
      options: {
        plugins: { legend: { display: false } },
        scales: {
          x: { ticks: { color: '#9aa3b2' } },
          y: { ticks: { color: '#9aa3b2' } },
        },
      },
    });
  }

  $('#btn-addjob').addEventListener('click', () => openJobModal());
  $('#btn-export').addEventListener('click', () => {
    try {
      const arr = Object.values(state.jobs);
      const text = JSON.stringify(arr);
      if (navigator.clipboard?.writeText) {
        navigator.clipboard.writeText(text)
          .then(() => toast('Exportado al portapapeles', 'success'))
          .catch(() => { fallbackCopy(text); toast('Copiado con método alterno', 'success'); });
      } else { fallbackCopy(text); toast('Copiado con método alterno', 'success'); }
    } catch { toast('No se pudo exportar', 'error'); }
  });
  $('#btn-import').addEventListener('click', () => openImportModal());

  function fallbackCopy(text) {
    const ta = document.createElement('textarea');
    ta.value = text;
    document.body.appendChild(ta);
    ta.select();
    document.execCommand('copy');
    document.body.removeChild(ta);
  }

  function renderJobs() {
    const tb = $('#jobsTable tbody');
    tb.innerHTML = '';
    Object.values(state.jobs).forEach((j) => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td>${j.name}</td>
        <td>${j.label}</td>
        <td>${j.type || '-'}</td>
        <td>${j.whitelisted ? 'Sí' : 'No'}</td>
        <td>${Object.keys(j.grades || {}).length}</td>
        <td class="actions-inline">
          <button class="btn" data-act="manage">Gestionar</button>
          <button class="btn" data-act="dup">Duplicar</button>
          <button class="btn" data-act="grades">Rangos</button>
          <button class="btn danger" data-act="del">Borrar</button>
        </td>`;
      tr.querySelector('[data-act="del"]').addEventListener('click', () =>
        confirm(`¿Eliminar ${j.label}?`, () => { post('deleteJob', { name: j.name }); delete state.jobs[j.name]; renderJobs(); toast('Trabajo borrado', 'success'); }),
      );
      tr.querySelector('[data-act="dup"]').addEventListener('click', () =>
        promptModal('Duplicar Trabajo', `Nuevo nombre técnico para ${j.name}`, (val) => { post('duplicateJob', { name: j.name, newName: val }); toast('Trabajo duplicado', 'success'); }),
      );
      tr.querySelector('[data-act="grades"]').addEventListener('click', () => openGradesModal(j));
      tr.querySelector('[data-act="manage"]').addEventListener('click', () => openJobDetail(j));
      tb.appendChild(tr);
    });
  }

  function openJobModal() {
    const html = `
      <div class="row">
        <div><label>Nombre técnico</label><input id="jname" class="input"/></div>
        <div><label>Etiqueta</label><input id="jlabel" class="input"/></div>
      </div>
      <div class="row">
        <div><label>Tipo</label><input id="jtype" class="input" placeholder="gobierno, médico, mecánico..."/></div>
        <div><label>Whitelist</label><select id="jwl"><option value="0">No</option><option value="1">Sí</option></select></div>
      </div>`;
    modal('Agregar Trabajo', html, () => {
      const payload = {
        name: $('#jname').value,
        label: $('#jlabel').value,
        type: $('#jtype').value,
        whitelisted: $('#jwl').value === '1',
      };
      post('createJob', payload);
      closeModal();
      toast('Trabajo creado', 'success');
    });
  }

  function openGradesModal(job) {
    const grades = job.grades || {};
    const body = `
      <div id="grades-wrap"></div>
      <div class="row"><button class="btn" id="addGrade">+ Añadir rango</button></div>`;

    modal(`Rangos · ${job.label}`, body, () => {
      const wrap = $('#grades-wrap');
      const rows = wrap.querySelectorAll('.grade-row');
      const existing = { ...grades };
      const seen = {};
      const newGrades = {};
      rows.forEach((row) => {
        const k = row.dataset.k;
        const g = {
          label: row.querySelector('.g-label').value,
          name: row.querySelector('.g-name').value,
          payment: Number(row.querySelector('.g-pay').value) || 0,
          isboss: row.querySelector('.g-boss').checked,
        };
        newGrades[k] = g;
        if (existing[k]) {
          post('updateGrade', { job: job.name, grade: k, data: g });
        } else {
          post('addGrade', { job: job.name, grade: k, data: g });
        }
        seen[k] = true;
      });
      Object.keys(existing).forEach((k) => { if (!seen[k]) post('deleteGrade', { job: job.name, grade: k }); });
      job.grades = newGrades;
      closeModal();
      renderAll();
      toast('Rangos actualizados', 'success');
    });

    const wrap = $('#modal-content #grades-wrap');
    function addRow(k, g = {}) {
      const row = document.createElement('div');
      row.className = 'row grade-row';
      row.dataset.k = k;
      row.innerHTML = `
        <div><input class="input g-label" placeholder="Etiqueta" value="${g.label || ''}"/></div>
        <div><input class="input g-name" placeholder="Nombre" value="${g.name || ''}"/></div>
        <div><input class="input g-pay" type="number" placeholder="Salario" value="${g.payment || 0}"/></div>
        <div><label><input type="checkbox" class="g-boss" ${g.isboss ? 'checked' : ''}/> Jefe</label></div>
        <div><button class="btn danger g-del">X</button></div>`;
      row.querySelector('.g-del').onclick = () => row.remove();
      wrap.appendChild(row);
    }
    Object.keys(grades).forEach((k) => addRow(k, grades[k]));
    $('#modal-content #addGrade').onclick = () => {
      let nk = 0;
      while (wrap.querySelector(`[data-k="${nk}"]`)) nk++;
      addRow(String(nk));
    };
  }

  function openImportModal() {
    const html = `<textarea id="importArea" class="input" style="height:180px" placeholder='Pega JSON de trabajos...'></textarea>`;
    modal('Importar Trabajos', html, () => {
      try {
        const arr = JSON.parse($('#importArea').value);
        (arr || []).forEach((j) => post('createJob', j));
        closeModal();
        toast('Importado', 'success');
      } catch { toast('JSON inválido', 'error'); }
    });
  }

  // ====== EMPLEADOS ======
  function renderEmployees() {
    const sel = $('#employeesJob');
    sel.innerHTML = '';
    Object.values(state.jobs).forEach((j) => {
      const o = document.createElement('option');
      o.value = j.name;
      o.textContent = j.label;
      sel.appendChild(o);
    });
    sel.onchange = loadEmp;
    if (!state.empJob && sel.options[0]) { state.empJob = sel.options[0].value; }
    sel.value = state.empJob;
    loadEmp();
  }
  function loadEmp() {
    state.empJob = $('#employeesJob').value;
    postJ('getEmployees', { job: state.empJob }).then((list) => {
      state.employees = list || [];
      paintEmp();
    });
  }
  function paintEmp() {
    const tb = $('#empTable tbody');
    tb.innerHTML = '';
    const query = ($('#searchEmp').value || '').toLowerCase();
    let online = 0;
    state.employees
      .filter((e) => e.name.toLowerCase().includes(query))
      .forEach((e) => {
        if (e.online) online++;
        const tr = document.createElement('tr');
        tr.innerHTML = `
          <td>${e.name}</td>
          <td>${e.grade}</td>
          <td>${e.online ? '<span class="badge ok">Online</span>' : '<span class="badge off">Offline</span>'}</td>
          <td class="actions-inline">
            <button class="btn" data-r="${e.citizenid}">Rango</button>
            <button class="btn danger" data-cid="${e.citizenid}">Despedir</button>
          </td>`;
        tr.querySelector('button[data-cid]').onclick = () =>
          confirm(`¿Despedir a ${e.name}?`, () => { post('fire', { job: state.empJob, citizenid: e.citizenid }); loadEmp(); toast('Empleado despedido', 'success'); });
        tr.querySelector('button[data-r]').onclick = () => openSetGradeModal(state.empJob, e);
        tb.appendChild(tr);
      });
    $('#emp-summary').innerHTML = `
      <div class="card"><div class="h">Empleados</div><div class="b">${state.employees.length}</div></div>
      <div class="card"><div class="h">Online</div><div class="b">${online}</div></div>`;
  }
  $('#searchEmp').addEventListener('input', paintEmp);
  $('#btn-recruit').addEventListener('click', () => { openRecruitModal(state.empJob, () => setTimeout(loadEmp, 300)); });

  function openSetGradeModal(jobName, emp) {
    const html = `
      <div class="row">
        <div><label>Empleado</label><div class="input" style="background:#0b1220;color:#9aa3b2">${emp.name}</div></div>
        <div><label>Nuevo grado</label><input id="ngrade" class="input" value="${emp.grade}"/></div>
      </div>`;
    modal('Cambiar Rango', html, () => {
      const g = Number($('#ngrade').value) || 0;
      post('setGrade', { job: jobName, citizenid: emp.citizenid, grade: g }).then(() => {
        closeModal();
        toast('Rango actualizado', 'success');
        setTimeout(loadEmp, 250);
      });
    });
  }

  // ====== ESTADÍSTICAS / CUENTAS ======
  function renderStats() {
    const box = $('#accounts');
    box.innerHTML = '';
    Object.values(state.jobs).forEach((j) => {
      postJ('getAccount', { job: j.name }).then((bal) => {
        const balance = Number(bal) || 0;
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `
          <div class="card"><div class="h">${j.label}</div><div class="b">${money(balance)}</div></div>
          <div class="card"><label>Monto</label><input class="input" id="amt-${j.name}" placeholder="Cantidad"/></div>
          <div class="card"><label>Cuenta</label><select class="input" id="acc-${j.name}"><option value="cash">Efectivo</option><option value="bank">Banco</option></select></div>
          <div class="card"><div class="actions-inline"><button class="btn" data-a="dep">Depositar</button><button class="btn" data-a="wd">Retirar</button><button class="btn" data-a="wash">Lavar</button></div></div>`;
        row.querySelector('[data-a="dep"]').onclick = () => {
          const v = Number($(`#amt-${j.name}`).value) || 0;
          const a = $(`#acc-${j.name}`).value;
          post('deposit', { job: j.name, amount: v, from: a }).then(() => { toast('Depósito realizado', 'success'); setTimeout(renderStats, 350); });
        };
        row.querySelector('[data-a="wd"]').onclick = () => {
          const v = Number($(`#amt-${j.name}`).value) || 0;
          const a = $(`#acc-${j.name}`).value;
          post('withdraw', { job: j.name, amount: v, to: a }).then(() => { toast('Retiro realizado', 'success'); setTimeout(renderStats, 350); });
        };
        row.querySelector('[data-a="wash"]').onclick = () => {
          const v = Number($(`#amt-${j.name}`).value) || 0;
          post('wash', { job: j.name, amount: v }).then(() => { toast('Dinero lavado', 'success'); setTimeout(renderStats, 350); });
        };
        box.appendChild(row);
      });
    });
  }

  function renderCrafting() {
    const recBody = $('#recTable tbody');
    recBody.innerHTML = '';
    Object.values(state.recipes || {}).forEach((r) => {
      const tr = document.createElement('tr');
      const inputs = (r.inputs || []).map((i) => `${i.amount}x ${i.item}`).join(', ');
      const output = r.output ? `${r.output.amount || 1}x ${r.output.item}` : '';
      tr.innerHTML = `<td>${r.name}</td><td>${inputs}</td><td>${r.time || 0}</td><td>${output}</td>`;
      recBody.appendChild(tr);
    });
  }

  function refreshCrafting() {
    postJ('getCraftingTable').then((r) => {
      if (Array.isArray(r)) { const o = {}; r.forEach((x) => { if (x && x.name) o[x.name] = x; }); state.recipes = o; }
      else { state.recipes = r || {}; }
      renderCrafting();
    });
  }

  // ====== DETALLE DE TRABAJO ======
  function openJobDetail(job) {
    state.jd.job = job.name;
    $('#jd-title').textContent = job.label + ' · Panel';
    selectView('jobdetail');
    renderJD();
  }
  function renderJD() {
    const body = $('#jd-body');
    body.innerHTML = '';
    const tabs = { employees: renderJDEmployees, finance: renderJDFinance, zones: renderJDZones, actions: renderJDActions };
    (tabs[state.jd.tab] || tabs.employees)(body);
    $('#jd-tab-employees').onclick = () => { state.jd.tab = 'employees'; renderJD(); };
    $('#jd-tab-finance').onclick   = () => { state.jd.tab = 'finance';   renderJD(); };
    $('#jd-tab-zones').onclick     = () => { state.jd.tab = 'zones';     renderJD(); };
    $('#jd-tab-actions').onclick   = () => { state.jd.tab = 'actions';   renderJD(); };
  }

  function renderJDEmployees(body) {
    body.innerHTML = `<div class="toolbar"><button class="btn" id="jd-rec">Reclutar</button></div><div id="jd-elist"></div>`;
    $('#jd-rec').onclick = () => { openRecruitModal(state.jd.job, () => renderJD()); };
    postJ('getEmployees', { job: state.jd.job }).then((list) => {
      const wrap = document.createElement('div');
      wrap.className = 'panel';
      let html = '<table class="table"><thead><tr><th>Nombre</th><th>Rango</th><th>Estado</th><th></th></tr></thead><tbody>';
      (list || []).forEach((e) => {
        html += `<tr>
          <td>${e.name}</td>
          <td>${e.grade}</td>
          <td>${e.online ? '<span class="badge ok">Online</span>' : '<span class="badge off">Offline</span>'}</td>
          <td class="actions-inline"><button class="btn" data-r="${e.citizenid}">Rango</button><button class="btn danger" data-cid="${e.citizenid}">Despedir</button></td>
        </tr>`;
      });
      html += '</tbody></table>';
      wrap.innerHTML = html;
      body.appendChild(wrap);
      wrap.querySelectorAll('button[data-cid]').forEach((b) => {
        b.onclick = () => post('fire', { job: state.jd.job, citizenid: b.dataset.cid }).then(() => { toast('Empleado despedido', 'success'); renderJD(); });
      });
      wrap.querySelectorAll('button[data-r]').forEach((b) => {
        b.onclick = () => {
          const cid = b.dataset.r;
          const emp = (list || []).find((x) => x.citizenid === cid);
          openSetGradeModal(state.jd.job, emp);
        };
      });
    });
  }

  function renderJDFinance(body) {
    body.innerHTML = '';
    const p = document.createElement('div');
    p.className = 'panel';
    p.innerHTML = '<div id="jd-acc"></div>';
    body.appendChild(p);
    postJ('getAccount', { job: state.jd.job }).then((bal) => {
      const balance = Number(bal) || 0;
      p.innerHTML = `
        <div class="row">
          <div class="card"><div class="h">Saldo</div><div class="b">${money(balance)}</div></div>
          <div class="card"><label>Monto</label><input id="jd-amt" class="input" placeholder="Cantidad"/></div>
          <div class="card"><label>Cuenta</label><select id="jd-accsel" class="input"><option value="cash">Efectivo</option><option value="bank">Banco</option></select></div>
          <div class="card"><div class="actions-inline">
            <button class="btn" id="jd-dep">Depositar</button>
            <button class="btn" id="jd-wd">Retirar</button>
            <button class="btn" id="jd-wash">Lavar</button>
          </div></div>
        </div>`;
      $('#jd-dep').onclick = () => {
        const v = Number($('#jd-amt').value) || 0;
        const a = $('#jd-accsel').value;
        post('deposit', { job: state.jd.job, amount: v, from: a }).then(() => { toast('Depósito realizado', 'success'); renderJDFinance(body); });
      };
      $('#jd-wd').onclick = () => {
        const v = Number($('#jd-amt').value) || 0;
        const a = $('#jd-accsel').value;
        post('withdraw', { job: state.jd.job, amount: v, to: a }).then(() => { toast('Retiro realizado', 'success'); renderJDFinance(body); });
      };
      $('#jd-wash').onclick = () => {
        const v = Number($('#jd-amt').value) || 0;
        post('wash', { job: state.jd.job, amount: v }).then(() => { toast('Dinero lavado', 'success'); renderJDFinance(body); });
      };
    });
  }

  function renderJDZones(body) {
    body.innerHTML = `<div class="toolbar"><button class="btn" id="addz">+ Añadir Zona</button></div><div id="zlist" class="panel"></div>`;
    const list = document.getElementById('zlist');

    let zonesCache = [];
    function load() {
      postJ('getZones', { job: state.jd.job }).then((zs) => {
      const seen = Object.create(null), uniq = [];
      (zs || []).forEach((z) => { const k = String(z.id); if (!seen[k]) { seen[k] = 1; uniq.push(z); } });
      zonesCache = uniq;

      let html = `
        <table class="table">
          <thead><tr><th>ID</th><th>Tipo</th><th>Etiqueta</th><th>Radio</th><th>Extras</th><th></th></tr></thead>
          <tbody>`;
      uniq.forEach((z) => {
        html += `<tr>
          <td>${z.id}</td><td>${z.ztype}</td><td>${z.label||''}</td>
          <td>${z.radius}</td>
          <td>${(z.data && (z.data.vehicles || z.data.vehicle || '')) || ''}</td>
          <td><button class="btn" data-edit="${z.id}">Editar</button><button class="btn danger" data-id="${z.id}">Borrar</button></td>
        </tr>`;
      });
      html += '</tbody></table>';
      list.innerHTML = html;

      list.querySelectorAll('button[data-id]').forEach((b) => {
        b.onclick = () => post('deleteZone', { id: Number(b.dataset.id) }).then(() => load());
      });
      list.querySelectorAll('button[data-edit]').forEach((b) => {
        b.onclick = () => editZone(Number(b.dataset.edit));
      });
    });
    }
    load();

    function editZone(id) {
      const zone = zonesCache.find((z) => z.id === id);
      if (!zone) return;
      let coords = zone.coords;
      const base = `
        <div class="row">
          <div><label>Etiqueta</label><input id="zlabel" class="input" value="${zone.label || ''}"/></div>
          <div><label>Radio</label><input id="zrad" class="input" value="${zone.radius || 2.0}"/></div>
          <div><label>Limpieza (m)</label><input id="zclearrad" class="input" value="${(zone.data && zone.data.clearRadius) || 0}"/></div>
          <div><button id="zcoords" class="btn">Usar mis coords</button></div>
        </div>
        <div id="zextra"></div>`;
      modal('Editar ' + zone.ztype, base, () => {
        const t = zone.ztype;
        const data = {};
        if (t === 'boss')   data.minGrade = Number(document.getElementById('zmin')?.value || 0);
        if (t === 'stash') { data.slots  = Number(document.getElementById('zslots')?.value || 50);
                            data.weight = Number(document.getElementById('zweight')?.value || 400000); }
        if (t === 'garage'){ data.vehicles = document.getElementById('zveh')?.value || '';
                            data.vehicle  = document.getElementById('zvehdef')?.value || ''; }
        if (t === 'crafting') {
                            const cats = Array.from(document.getElementById('zcats')?.selectedOptions || []).map((o) => o.value);
                            const recs = Array.from(document.getElementById('zrecipes')?.selectedOptions || []).map((o) => o.value);
                            if (cats.length > 0) data.allowedCategories = cats; else data.recipes = recs;
                            const jobStr = document.getElementById('zjob')?.value || '';
                            if (jobStr.includes(',')) data.job = jobStr.split(',').map(s=>s.trim()).filter(s=>s);
                            else if (jobStr !== '') data.job = jobStr;
                            const icon = document.getElementById('zicon')?.value || '';
                            if (icon) data.icon = icon;
                            const colorPrimario = document.getElementById('zcpri')?.value || '';
                            const colorPrimarioAlt = document.getElementById('zcpria')?.value || '';
                            const colorSecundario = document.getElementById('zcsec')?.value || '';
                            const colorSecundarioAlt = document.getElementById('zcseca')?.value || '';
                            const titulo = document.getElementById('zctitle')?.value || '';
                            data.theme = { colorPrimario, colorPrimarioAlt, colorSecundario, colorSecundarioAlt, titulo };
                           }
        if (t === 'cloakroom') data.mode = (document.getElementById('zckmode')?.value || 'illenium').toLowerCase();
        if (t === 'shop')  { data.items = collectShopItems(); }
        if (t === 'collect'){ data.item = document.getElementById('zitem')?.value||'material';
                              data.amount = Number(document.getElementById('zamt')?.value||1);
                              data.time = Number(document.getElementById('ztime')?.value||3000);
                              data.dict = document.getElementById('zdict')?.value||'';
                              data.anim = document.getElementById('zanm')?.value||''; }
        if (t === 'spawner') data.prop = document.getElementById('zprop')?.value||'prop_toolchest_05';
        if (t === 'sell') { data.item = document.getElementById('zsitem')?.value||'material';
                            data.price = Number(document.getElementById('zsprice')?.value||10);
                            data.max = Number(document.getElementById('zsmax')?.value||10);
                            data.toSociety = (document.getElementById('zssoc')?.value||'true') !== 'false'; }
        if (t === 'register') { data.amount = Number(document.getElementById('zramt')?.value||100);
                                data.method = (document.getElementById('zrmethod')?.value||'bank').toLowerCase();
                                data.toSociety = (document.getElementById('zrsoc')?.value||'true') !== 'false'; }
        if (t === 'alarm') data.code = document.getElementById('zalcode')?.value||'panic';
        if (t === 'anim') { data.scenario = document.getElementById('zsc')?.value||'';
                            data.dict = document.getElementById('zdict')?.value||'';
                            data.anim = document.getElementById('zanm')?.value||'';
                            data.time = Number(document.getElementById('ztime')?.value||5000); }
        if (t === 'music') { data.url = document.getElementById('zurl')?.value||''; data.volume = Number(document.getElementById('zvol')?.value||0.5); const range = Number(document.getElementById('zrange')?.value||20); data.distance = range; data.range = range; data.name = document.getElementById('zname')?.value||''; }
        if (t === 'teleport') { data.to = collectTeleports(); }
        const cr = Number(document.getElementById('zclearrad')?.value || 0);
        data.clearArea = cr > 0;
        data.clearRadius = cr;
        post('updateZone', { id, data, label: document.getElementById('zlabel').value, radius: Number(document.getElementById('zrad').value) || 2.0, coords }).then(() => { closeModal(); load(); });
      });

      document.getElementById('zcoords').onclick = () => {
        postJ('getCoords', {}).then((c) => {
          if (!c) { toast('No se pudieron leer tus coords', 'error'); return; }
          coords = c;
          toast('Coordenadas actualizadas', 'success');
        });
      };

      const box = document.getElementById('zextra');
      function renderEditExtra() {
        const t = zone.ztype;
        const d = zone.data || {};

        const row = (inner) => `<div class="row">${inner}</div>`;
        const inp = (id, label, ph='', val='') => `<div><label>${label}</label><input id="${id}" class="input" placeholder="${ph}" value="${val}"/></div>`;
        const ta  = (id, label, ph='', val='') => `<div style="flex:1"><label>${label}</label><textarea id="${id}" class="input" style="height:120px" placeholder='${ph}'>${val}</textarea></div>`;

        collectShopItems = () => [];
        collectTeleports = () => [];
        if (t === 'boss') {
          box.innerHTML = row(inp('zmin','Mín. rango','0', d.minGrade || 0));
        } else if (t === 'stash') {
          box.innerHTML = row(inp('zslots','Slots','50', d.slots || '') + inp('zweight','Peso máximo','400000', d.weight || ''));
        } else if (t === 'garage') {
          box.innerHTML = inp('zveh','Vehículos (rango=modelo, separados por coma)','0=police,2=police2,4=ambulance', d.vehicles || '') +
                          row(inp('zvehdef','Modelo por defecto','police', d.vehicle || ''));
        } else if (t === 'crafting') {
          const catList = Array.from(new Set(Object.values(state.recipes || {}).map(r => r.category || 'General')));
          const catOpts = catList.map((c) => `<option value="${c}" ${(d.allowedCategories||[]).includes(c)?'selected':''}>${c}</option>`).join('');
          const recOpts = Object.keys(state.recipes || {}).map((r) => `<option value="${r}" ${(d.recipes||[]).includes(r)?'selected':''}>${r}</option>`).join('');
          const jobVal = Array.isArray(d.job) ? d.job.join(',') : (d.job || '');
          const th = d.theme || {};
          box.innerHTML = row(`<div style="flex:1"><label>Categorías</label><select id="zcats" class="input" multiple>${catOpts}</select></div>`) +
                        row(`<div style="flex:1"><label>Recetas</label><select id="zrecipes" class="input" multiple>${recOpts}</select></div>`) +
                        row(inp('zjob','Job Lock','', jobVal)) +
                        row(inp('zicon','Icono','fa-solid fa-hammer', d.icon || '')) +
                        row(inp('zcpri','Color Primario','#53a88c', th.colorPrimario || '') + inp('zcpria','Color Primario Alt','#53a88c', th.colorPrimarioAlt || '')) +
                        row(inp('zcsec','Color Secundario','#2f7a62', th.colorSecundario || '') + inp('zcseca','Color Secundario Alt','#2f7a62', th.colorSecundarioAlt || '') + inp('zctitle','Título','', th.titulo || ''));
        } else if (t === 'cloakroom') {
          box.innerHTML = row(inp('zckmode','Modo','illenium / qb-clothing', d.mode || ''));
        } else if (t === 'shop') {
          renderShopItemsSection(box, d.items || []);
        } else if (t === 'collect') {
          box.innerHTML = row(inp('zitem','Ítem','material', d.item || '') + inp('zamt','Cantidad','1', d.amount || '')) +
                          row(inp('ztime','Tiempo (ms)','3000', d.time || '') + inp('zdict','Anim dict','', d.dict || '') + inp('zanm','Anim nombre','', d.anim || ''));
        } else if (t === 'spawner') {
          box.innerHTML = row(inp('zprop','Modelo prop','prop_toolchest_05', d.prop || ''));
        } else if (t === 'sell') {
          box.innerHTML = row(inp('zsitem','Ítem','material', d.item || '') + inp('zsprice','Precio unidad','10', d.price || '') + inp('zsmax','Máx por venta','10', d.max || '')) +
                          row(inp('zssoc','A sociedad? (true/false)','true', String(d.toSociety ?? true)));
        } else if (t === 'register') {
          box.innerHTML = row(inp('zramt','Monto por defecto','100', d.amount || '') + inp('zrmethod','Método (cash/bank)','bank', d.method || '') + inp('zrsoc','A sociedad? (true/false)','true', String(d.toSociety ?? true)));
        } else if (t === 'alarm') {
          box.innerHTML = row(inp('zalcode','Código/Tipo','panic', d.code || ''));
        } else if (t === 'anim') {
          box.innerHTML = row(inp('zsc','Scenario','PROP_HUMAN_SEAT_CHAIR', d.scenario || '')) + row(inp('zdict','Anim dict','', d.dict || '') + inp('zanm','Anim nombre','', d.anim || '') + inp('ztime','Duración (ms)','5000', d.time || ''));
        } else if (t === 'music') {
          box.innerHTML = row(inp('zname','Nombre DJ','', d.name || '') + inp('zrange','Radio','20', d.range || d.distance || '')) +
                          row(inp('zurl','YouTube/URL','https://...', d.url || '') + inp('zvol','Volumen (0-1)','0.5', d.volume || ''));
        } else if (t === 'teleport') {
          renderTeleportSection(box, d.to || []);
        } else {
          box.innerHTML = '';
        }
      }
      renderEditExtra();
    }

    document.getElementById('addz').onclick = () => {
      const base = `
        <div class="row">
          <div>
            <label>Tipo</label>
            <select id="ztype" class="input">
              ${(window.Config?.ZoneTypes || ['blip', 'boss', 'stash', 'garage', 'crafting', 'cloakroom', 'shop', 'collect', 'spawner', 'sell', 'alarm', 'register', 'anim', 'music', 'teleport'])
                .map((t) => `<option>${t}</option>`).join('')}
            </select>
          </div>
          <div><label>Etiqueta</label><input id="zlabel" class="input"/></div>
        </div>
        <div class="row">
          <div><label>Radio</label><input id="zrad" class="input" value="2.0"/></div>
          <div><label>Limpieza (m)</label><input id="zclearrad" class="input" value="0"/></div>
          <div><label>Usar mis coords</label><div class="h">Se capturarán al guardar</div></div>
        </div>
        <div id="zextra"></div>`;
      modal('Nueva Zona', base, () => {
        postJ('getCoords', {}).then((c) => {
          if (!c) { toast('No se pudieron leer tus coords', 'error'); return; }
          const t = document.getElementById('ztype').value;
          const data = {};
          if (t === 'boss')   data.minGrade = Number(document.getElementById('zmin')?.value || 0);
          if (t === 'stash') { data.slots  = Number(document.getElementById('zslots')?.value || 50);
                              data.weight = Number(document.getElementById('zweight')?.value || 400000); }
          if (t === 'garage'){ data.vehicles = document.getElementById('zveh')?.value || '';
                              data.vehicle  = document.getElementById('zvehdef')?.value || ''; }
          if (t === 'crafting') {
            const cats = Array.from(document.getElementById('zcats')?.selectedOptions || []).map((o) => o.value);
            const recs = Array.from(document.getElementById('zrecipes')?.selectedOptions || []).map((o) => o.value);
            if (cats.length > 0) data.allowedCategories = cats; else data.recipes = recs;
            const jobStr = document.getElementById('zjob')?.value || '';
            if (jobStr.includes(',')) data.job = jobStr.split(',').map(s=>s.trim()).filter(s=>s);
            else if (jobStr !== '') data.job = jobStr;
            const icon = document.getElementById('zicon')?.value || '';
            if (icon) data.icon = icon;
            const colorPrimario = document.getElementById('zcpri')?.value || '';
            const colorPrimarioAlt = document.getElementById('zcpria')?.value || '';
            const colorSecundario = document.getElementById('zcsec')?.value || '';
            const colorSecundarioAlt = document.getElementById('zcseca')?.value || '';
            const titulo = document.getElementById('zctitle')?.value || '';
            data.theme = { colorPrimario, colorPrimarioAlt, colorSecundario, colorSecundarioAlt, titulo };
            }
          if (t === 'cloakroom') data.mode = (document.getElementById('zckmode')?.value || 'illenium').toLowerCase();
          if (t === 'shop')  { data.items = collectShopItems(); }
          if (t === 'collect'){ data.item = document.getElementById('zitem')?.value||'material';
                                data.amount = Number(document.getElementById('zamt')?.value||1);
                                data.time = Number(document.getElementById('ztime')?.value||3000);
                                data.dict = document.getElementById('zdict')?.value||'';
                                data.anim = document.getElementById('zanm')?.value||''; }
          if (t === 'spawner') data.prop = document.getElementById('zprop')?.value||'prop_toolchest_05';
          if (t === 'sell') { data.item = document.getElementById('zsitem')?.value||'material';
                              data.price = Number(document.getElementById('zsprice')?.value||10);
                              data.max = Number(document.getElementById('zsmax')?.value||10);
                              data.toSociety = (document.getElementById('zssoc')?.value||'true') !== 'false'; }
          if (t === 'register') { data.amount = Number(document.getElementById('zramt')?.value||100);
                                  data.method = (document.getElementById('zrmethod')?.value||'bank').toLowerCase();
                                  data.toSociety = (document.getElementById('zrsoc')?.value||'true') !== 'false'; }
          if (t === 'alarm') data.code = document.getElementById('zalcode')?.value||'panic';
          if (t === 'anim') { data.scenario = document.getElementById('zsc')?.value||'';
                              data.dict = document.getElementById('zdict')?.value||'';
                              data.anim = document.getElementById('zanm')?.value||'';
                              data.time = Number(document.getElementById('ztime')?.value||5000); }
          if (t === 'music') { data.url = document.getElementById('zurl')?.value||''; data.volume = Number(document.getElementById('zvol')?.value||0.5); const range = Number(document.getElementById('zrange')?.value||20); data.distance = range; data.range = range; data.name = document.getElementById('zname')?.value||''; }
          if (t === 'teleport') { data.to = collectTeleports(); }
          const cr = Number(document.getElementById('zclearrad')?.value || 0);
          data.clearArea = cr > 0;
          data.clearRadius = cr;
          const z = {
            job: state.jd.job,
            ztype: t,
            label: document.getElementById('zlabel').value,
            radius: Number(document.getElementById('zrad').value) || 2.0,
            coords: c,
            data,
          };
          post('createZone', z).then(() => { closeModal(); load(); });
        });
      });

      // campos dinámicos según tipo
      const extraBox = document.getElementById('zextra');
      function renderExtra() {
      const t = document.getElementById('ztype').value;
      const box = document.getElementById('zextra');

      const row = (inner) => `<div class="row">${inner}</div>`;
      const inp = (id, label, ph='') => `<div><label>${label}</label><input id="${id}" class="input" placeholder="${ph}"/></div>`;
      const ta  = (id, label, ph='') => `<div style="flex:1"><label>${label}</label><textarea id="${id}" class="input" style="height:120px" placeholder='${ph}'></textarea></div>`;

      collectShopItems = () => [];
      collectTeleports = () => [];
      if (t === 'boss') {
        box.innerHTML = row(inp('zmin','Mín. rango','0'));
      } else if (t === 'stash') {
        box.innerHTML = row(inp('zslots','Slots','50') + inp('zweight','Peso máximo','400000'));
      } else if (t === 'garage') {
        box.innerHTML = inp('zveh','Vehículos (rango=modelo, separados por coma)','0=police,2=police2,4=ambulance') +
                        row(inp('zvehdef','Modelo por defecto','police'));
      } else if (t === 'crafting') {
        const catList = Array.from(new Set(Object.values(state.recipes || {}).map(r => r.category || 'General')));
        const catOpts = catList.map((c) => `<option value="${c}">${c}</option>`).join('');
        const recOpts = Object.keys(state.recipes || {}).map((r) => `<option>${r}</option>`).join('');
        box.innerHTML = row(`<div style=\"flex:1\"><label>Categorías</label><select id=\"zcats\" class=\"input\" multiple>${catOpts}</select></div>`) +
                        row(`<div style=\"flex:1\"><label>Recetas</label><select id=\"zrecipes\" class=\"input\" multiple>${recOpts}</select></div>`) +
                        row(inp('zjob','Job Lock','')) +
                        row(inp('zicon','Icono','fa-solid fa-hammer')) +
                        row(inp('zcpri','Color Primario','#53a88c') + inp('zcpria','Color Primario Alt','#53a88c')) +
                        row(inp('zcsec','Color Secundario','#2f7a62') + inp('zcseca','Color Secundario Alt','#2f7a62') + inp('zctitle','Título',''));
      } else if (t === 'cloakroom') {
        box.innerHTML = row(inp('zckmode','Modo','illenium / qb-clothing'));
      } else if (t === 'shop') {
        renderShopItemsSection(box, []);
      } else if (t === 'collect') {
        box.innerHTML = row(inp('zitem','Ítem','material') + inp('zamt','Cantidad','1')) +
                        row(inp('ztime','Tiempo (ms)','3000') + inp('zdict','Anim dict','') + inp('zanm','Anim nombre',''));
      } else if (t === 'spawner') {
        box.innerHTML = row(inp('zprop','Modelo prop','prop_toolchest_05'));
      } else if (t === 'sell') {
        box.innerHTML = row(inp('zsitem','Ítem','material') + inp('zsprice','Precio unidad','10') + inp('zsmax','Máx por venta','10')) +
                        row(inp('zssoc','A sociedad? (true/false)','true'));
      } else if (t === 'register') {
        box.innerHTML = row(inp('zramt','Monto por defecto','100') + inp('zrmethod','Método (cash/bank)','bank') + inp('zrsoc','A sociedad? (true/false)','true'));
      } else if (t === 'alarm') {
        box.innerHTML = row(inp('zalcode','Código/Tipo','panic'));
      } else if (t === 'anim') {
        box.innerHTML = row(inp('zsc','Scenario','PROP_HUMAN_SEAT_CHAIR')) + row(inp('zdict','Anim dict','') + inp('zanm','Anim nombre','') + inp('ztime','Duración (ms)','5000'));
      } else if (t === 'music') {
        box.innerHTML = row(inp('zname','Nombre DJ','') + inp('zrange','Radio','20')) +
                        row(inp('zurl','YouTube/URL','https://...') + inp('zvol','Volumen (0-1)','0.5'));
      } else if (t === 'teleport') {
        renderTeleportSection(box, []);
      } else {
        box.innerHTML = '';
      }
    }
      document.getElementById('ztype').onchange = renderExtra;
      renderExtra();
    };
  }

  function renderJDActions(body) {
    body.innerHTML = '<p>Próximamente: switches para habilitar/inhabilitar acciones por trabajo.</p>';
  }

  // ====== MODALES ======
  function modal(title, inner, onSubmit) {
    $('#modal-title').textContent = title;
    $('#modal-content').innerHTML = inner;
    $('#modal').classList.remove('hidden');
    $('#modal-submit').onclick = onSubmit;
    $('#modal-cancel').onclick = closeModal;
  }
  function promptModal(title, placeholder, onOk) {
    const html = `<input id="pmval" class="input" placeholder="${placeholder}"/>`;
    modal(title, html, () => { onOk($('#pmval').value); closeModal(); });
  }
  function confirm(text, onOk) {
    const html = `<p>${text}</p>`;
    modal('Confirmar', html, () => { onOk(); closeModal(); });
  }
  function closeModal() { $('#modal').classList.add('hidden'); }

  // Modal Reclutar
  function openRecruitModal(jobName, onDone) {
    const skeleton = `
      <div class="row">
        <div><label>Jugador</label><select id="nearbySel" class="input"><option>Cargando...</option></select></div>
        <div><label>Grado</label><input id="nearbyGrade" class="input" placeholder="0" value="0"/></div>
      </div>`;
    modal('Reclutar', skeleton, () => {
      const sid   = Number($('#nearbySel').value);         // clave esperada por servidor (sid)
      const grade = Number($('#nearbyGrade').value) || 0;
      if (!sid || Number.isNaN(sid)) { closeModal(); return; }
      post('recruit', { job: jobName, sid, grade }).then(() => {
        closeModal(); toast('Reclutado', 'success'); if (onDone) onDone();
      });
    });

    postJ('getNearby', { job: jobName, radius: 3.0 }).then((list) => {
      if (!Array.isArray(list) || list.length === 0) {
        $('#modal-content').innerHTML = '<p>No hay jugadores cercanos disponibles.</p>';
        $('#modal-submit').onclick = () => closeModal();
        return;
      }
      const sel = $('#nearbySel');
      sel.innerHTML = list.map((p) => `<option value="${p.sid || p.id}">${p.name} [${p.sid || p.id}]</option>`).join('');
    }).catch(() => {
      $('#modal-content').innerHTML = '<p>No hay jugadores cercanos.</p>';
      $('#modal-submit').onclick = () => closeModal();
    });
  }

  function renderAll() {
    // si es boss, forzamos el panel del job
    applyScope();
    if (state.scope && state.scope.mode === 'boss') {
      selectView('jobdetail');
    } else {
      selectView('home');
      renderHome();
      renderJobs();
    }
  }

  return {};
})();


