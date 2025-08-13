const App = (() => {
  const state = { payload: null, jobs: {}, employees: [], view: 'home', empJob: null, chart: null, jd: { job: null, tab: 'employees' }, scope: { mode:'admin', job:null } }
  const $ = sel => document.querySelector(sel)
  const $$ = sel => document.querySelectorAll(sel)

function post(name, data = {}) {
  const res = (typeof GetParentResourceName === 'function') ? GetParentResourceName() : 'qb-jobcreator';
  return fetch(`https://${res}/${name}`, { method: 'POST', body: JSON.stringify(data) });
}
  function money(n){ return new Intl.NumberFormat('es-CO', { style:'currency', currency:'USD', maximumFractionDigits:0 }).format(n||0) }

  // ===== Toasts =====
  function ensureToast(){ if($('#toast-wrap')) return; const w=document.createElement('div'); w.id='toast-wrap'; w.style.position='fixed'; w.style.top='16px'; w.style.right='16px'; w.style.zIndex='9999'; w.style.display='flex'; w.style.flexDirection='column'; w.style.gap='8px'; document.body.appendChild(w) }
  function toast(msg, type='info'){ ensureToast(); const t=document.createElement('div'); t.textContent=msg; t.style.padding='10px 12px'; t.style.borderRadius='8px'; t.style.background= type==='error'?'#ff4d4f': type==='success'?'#2ecc71':'#3b82f6'; t.style.color='#fff'; t.style.boxShadow='0 8px 24px rgba(0,0,0,.25)'; $('#toast-wrap').appendChild(t); setTimeout(()=>{ t.style.transition='opacity .25s'; t.style.opacity='0'; setTimeout(()=>t.remove(),300) }, 1800) }

  function show(){ $('#app').classList.remove('hidden') }
  function hide(){ $('#app').classList.add('hidden') }

  document.addEventListener('DOMContentLoaded', () => { hide() })

  window.addEventListener('message', (e) => {
    const { action, payload } = e.data || {}
    if (action === 'open') {
      const pay = payload && typeof payload === 'object' ? payload : { ok:true, jobs:{}, zones:[], totals:{ jobs:0, employees:0, money:0 }, popular:[], branding:{ title:'LatinLife RP', logo:'logo.png' }, scope:{ mode:'admin' } }
      state.payload = pay; state.jobs = pay.jobs || {}; state.scope = pay.scope || {mode:'admin'}; applyBranding(pay.branding); applyScope(); if (pay.scope && pay.scope.type === 'boss' && pay.scope.job) {
  // abre directo el panel del trabajo del jefe
  state.jd = { job: pay.scope.job, tab: 'employees' };
  // pintar inmediatamente la vista detalle
  $$('.view').forEach(vw => vw.classList.add('hidden'));
  $('#view-jobdetail').classList.remove('hidden');
  $('#jd-title').textContent = (state.jobs[pay.scope.job]?.label || pay.scope.job) + ' · Panel';} renderAll(); show(); return
    }
    if (action === 'update') {
      if (!payload) return; state.payload = payload; state.jobs = payload.jobs || state.jobs; if(payload.scope) state.scope = payload.scope; applyBranding(payload.branding); applyScope(); renderAll(); return
    }
    if (action === 'hide' || action === 'force-close') { hide(); return }
  })

  function applyBranding(b){ if(!b) return; $('#brand-title').textContent = b.Title || 'LatinLife RP'; if(b.Logo){ $('#brand-logo').src = b.Logo } }

  function applyScope(){
    const boss = state.scope && state.scope.mode === 'boss'
    const sidebar = $$('.sidebar button')
    if (boss) {
      // Ocultar navegación global
      sidebar.forEach(b=>{ if(!['jobdetail'].includes(b.dataset.view)) b.classList.add('hidden') })
      // Forzar panel del trabajo en cuestión
      if (state.scope.job) { state.jd.job = state.scope.job; selectView('jobdetail') }
    } else {
      sidebar.forEach(b=>b.classList.remove('hidden'))
    }
  }

  document.addEventListener('keydown', (e)=>{ if(e.key==='Escape'){ post('close',{}); hide(); }})

  $$('.sidebar button').forEach(b=>b.addEventListener('click',()=> selectView(b.dataset.view)))
  function selectView(v){
    const boss = state.scope && state.scope.mode === 'boss'
    if (boss && v !== 'jobdetail') { return } // bosses solo ven su panel
    state.view=v; $$('.sidebar button').forEach(b=>b.classList.toggle('active', b.dataset.view===v));
    $$('.view').forEach(vw=>vw.classList.add('hidden')); $(`#view-${v}`).classList.remove('hidden');
    if(v==='home') renderHome(); if(v==='jobs') renderJobs(); if(v==='employees') renderEmployees(); if(v==='stats') renderStats(); if(v==='config'){} if(v==='jobdetail') renderJD()
  }

  function renderHome(){ const t = state.payload.totals || { jobs:0, employees:0, money:0 }; $('#metric-jobs').textContent=t.jobs; $('#metric-employees').textContent=t.employees; $('#metric-money').textContent=money(t.money); $('#metric-top').textContent=((state.payload.popular||[])[0]&&(state.payload.popular||[])[0].name)||'-';
    const labels = (state.payload.popular||[]).slice(0,10).map(x=>x.name); const data = (state.payload.popular||[]).slice(0,10).map(x=>x.count)
    const ctx = document.getElementById('employeesChart'); if(state.chart){ state.chart.destroy() }
    state.chart = new Chart(ctx, { type:'bar', data:{ labels, datasets:[{ label:'Empleados', data }] }, options:{ plugins:{ legend:{ display:false } }, scales:{ x:{ ticks:{ color:'#9aa3b2' } }, y:{ ticks:{ color:'#9aa3b2' } } } } })
  }

  $('#btn-addjob').addEventListener('click', ()=> openJobModal())
  $('#btn-export').addEventListener('click', ()=>{
    try { const arr = Object.values(state.jobs); if (navigator.clipboard?.writeText) { navigator.clipboard.writeText(JSON.stringify(arr)).then(()=>toast('Exportado al portapapeles','success')).catch(()=>{fallbackCopy(JSON.stringify(arr)); toast('Copiado con método alterno','success')}) } else { fallbackCopy(JSON.stringify(arr)); toast('Copiado con método alterno','success') } } catch(e){ toast('No se pudo exportar','error') }
  })
  $('#btn-import').addEventListener('click', ()=> openImportModal())

  function fallbackCopy(text){ const ta=document.createElement('textarea'); ta.value=text; document.body.appendChild(ta); ta.select(); document.execCommand('copy'); document.body.removeChild(ta) }

  function renderJobs(){ const tb = $('#jobsTable tbody'); tb.innerHTML=''; Object.values(state.jobs).forEach(j=>{
    const tr = document.createElement('tr'); tr.innerHTML=`<td>${j.name}</td><td>${j.label}</td><td>${j.type||'-'}</td><td>${j.whitelisted?'Sí':'No'}</td><td>${Object.keys(j.grades||{}).length}</td>
    <td class="actions-inline"><button class="btn" data-act="manage">Gestionar</button><button class="btn" data-act="dup">Duplicar</button><button class="btn" data-act="grades">Rangos</button><button class="btn danger" data-act="del">Borrar</button></td>`
    tr.querySelector('[data-act="del"]').addEventListener('click',()=>confirm(`¿Eliminar ${j.label}?`,()=>{ post('deleteJob',{ name:j.name }); delete state.jobs[j.name]; renderJobs(); toast('Trabajo borrado','success') }))
    tr.querySelector('[data-act="dup"]').addEventListener('click',()=>{ promptModal('Duplicar Trabajo', `Nuevo nombre técnico para ${j.name}`, (val)=>{ post('duplicateJob',{ name:j.name, newName:val }); toast('Trabajo duplicado','success') }) })
    tr.querySelector('[data-act="grades"]').addEventListener('click',()=> openGradesModal(j))
    tr.querySelector('[data-act="manage"]').addEventListener('click',()=> openJobDetail(j))
    tb.appendChild(tr)
  })}

  function openJobModal(){
    const html = `<div class="row"><div><label>Nombre técnico</label><input id="jname" class="input"/></div><div><label>Etiqueta</label><input id="jlabel" class="input"/></div></div>
    <div class="row"><div><label>Tipo</label><input id="jtype" class="input" placeholder="gobierno, médico, mecánico..."/></div><div><label>Whitelist</label><select id="jwl"><option value="0">No</option><option value="1">Sí</option></select></div></div>`
    modal('Agregar Trabajo', html, ()=>{ const payload = { name:$('#jname').value, label:$('#jlabel').value, type:$('#jtype').value, whitelisted:$('#jwl').value==='1' }; post('createJob', payload); closeModal(); toast('Trabajo creado','success') })
  }

  function openGradesModal(job){ const grades = job.grades||{}; let body = ''
    Object.keys(grades).forEach(k=>{ const g = grades[k]; body += `<div class=\"row\"><div><label>${g.label||g.name||k}</label></div><div><label>Salario</label><input data-k=\"${k}\" class=\"input\" value=\"${g.payment||0}\"/></div></div>` })
    modal(`Rangos · ${job.label}`, body, ()=>{ $$('#modal-content input[data-k]').forEach(inp=>{ post('updateGradeSalary', { job: job.name, grade: inp.dataset.k, salary: Number(inp.value)||0 }) }); closeModal(); toast('Rangos actualizados','success') }) }

  function openImportModal(){ const html = `<textarea id="importArea" class="input" style="height:180px" placeholder='Pega JSON de trabajos...'></textarea>`; modal('Importar Trabajos', html, ()=>{ try{ const arr = JSON.parse($('#importArea').value); (arr||[]).forEach(j=> post('createJob', j)); closeModal(); toast('Importado','success') }catch(e){ toast('JSON inválido','error') } }) }

  // ====== EMPLEADOS ======
  function renderEmployees(){ const sel = $('#employeesJob'); sel.innerHTML=''; Object.values(state.jobs).forEach(j=>{ const o=document.createElement('option'); o.value=j.name; o.textContent=j.label; sel.appendChild(o) }); sel.onchange=loadEmp; if(!state.empJob && sel.options[0]){ state.empJob = sel.options[0].value } sel.value=state.empJob; loadEmp() }
  function loadEmp(){ state.empJob = $('#employeesJob').value; post('getEmployees', { job: state.empJob }).then(r=>r.json()).then(list=>{ state.employees=list||[]; paintEmp() }).catch(()=>{}) }
  function paintEmp(){ const tb=$('#empTable tbody'); tb.innerHTML=''; const query = ($('#searchEmp').value||'').toLowerCase(); let online=0
    state.employees.filter(e=> e.name.toLowerCase().includes(query)).forEach(e=>{ if(e.online) online++; const tr=document.createElement('tr'); tr.innerHTML=`<td>${e.name}</td><td>${e.grade}</td><td>${e.online?'<span class=\"badge ok\">Online</span>':'<span class=\"badge off\">Offline</span>'}</td><td class=\"actions-inline\"><button class=\"btn\" data-r=\"${e.citizenid}\">Rango</button><button class=\"btn danger\" data-cid=\"${e.citizenid}\">Despedir</button></td>`; tr.querySelector('button[data-cid]').onclick=()=>confirm(`¿Despedir a ${e.name}?`,()=>{ post('fire',{ job: state.empJob, citizenid: e.citizenid }); loadEmp(); toast('Empleado despedido','success') }); tr.querySelector('button[data-r]').onclick=()=>openSetGradeModal(state.empJob, e); tb.appendChild(tr) })
    $('#emp-summary').innerHTML = `<div class=\"card\"><div class=\"h\">Empleados</div><div class=\"b\">${state.employees.length}</div></div><div class=\"card\"><div class=\"h\">Online</div><div class=\"b\">${online}</div></div>`
  }
  $('#searchEmp').addEventListener('input', paintEmp)
  $('#btn-recruit').addEventListener('click', ()=>{ openRecruitModal(state.empJob, ()=>setTimeout(loadEmp,300)) })

  function openSetGradeModal(jobName, emp){ const html = `<div class=\"row\"><div><label>Empleado</label><div class=\"input\" style=\"background:#0b1220;color:#9aa3b2\">${emp.name}</div></div><div><label>Nuevo grado</label><input id=\"ngrade\" class=\"input\" value=\"${emp.grade}\"/></div></div>`; modal('Cambiar Rango', html, ()=>{ const g = Number($('#ngrade').value)||0; post('setGrade',{ job: jobName, citizenid: emp.citizenid, grade: g }).then(()=>{ closeModal(); toast('Rango actualizado','success'); setTimeout(loadEmp,250) }) }) }

  // ====== ESTADÍSTICAS / CUENTAS ======
  function renderStats(){ const box = $('#accounts'); box.innerHTML=''; Object.values(state.jobs).forEach(j=>{ post('getAccount', { job:j.name }).then(r=>r.json()).then(bal=>{ const row=document.createElement('div'); row.className='row'; row.innerHTML = `<div class=\"card\"><div class=\"h\">${j.label}</div><div class=\"b\">${money(bal)}</div></div>
      <div class=\"card\"><label>Monto</label><input class=\"input\" id=\"amt-${j.name}\" placeholder=\"Cantidad\"/></div>
      <div class=\"card\"><label>Cuenta</label><select class=\"input\" id=\"acc-${j.name}\"><option value=\"cash\">Efectivo</option><option value=\"bank\">Banco</option></select></div>
      <div class=\"card\"><div class=\"actions-inline\"><button class=\"btn\" data-a=\"dep\">Depositar</button><button class=\"btn\" data-a=\"wd\">Retirar</button><button class=\"btn\" data-a=\"wash\">Lavar</button></div></div>`
      row.querySelector('[data-a="dep"]').onclick=()=>{ const v=Number($('#amt-'+j.name).value)||0; const a=$('#acc-'+j.name).value; post('deposit',{ job:j.name, amount:v, from:a }).then(()=>{ toast('Depósito realizado','success'); setTimeout(renderStats,350) }) }
      row.querySelector('[data-a="wd"]').onclick=()=>{ const v=Number($('#amt-'+j.name).value)||0; const a=$('#acc-'+j.name).value; post('withdraw',{ job:j.name, amount:v, to:a }).then(()=>{ toast('Retiro realizado','success'); setTimeout(renderStats,350) }) }
      row.querySelector('[data-a="wash"]').onclick=()=>{ const v=Number($('#amt-'+j.name).value)||0; post('wash',{ job:j.name, amount:v }).then(()=>{ toast('Dinero lavado','success'); setTimeout(renderStats,350) }) }
      box.appendChild(row) }).catch(()=>{}) }) }

  // ====== DETALLE DE TRABAJO ======
  function openJobDetail(job){ state.jd.job = job.name; $('#jd-title').textContent = job.label + ' · Panel'; selectView('jobdetail'); renderJD() }
  function renderJD(){ const body = $('#jd-body'); body.innerHTML='';
    const tabs = { employees: renderJDEmployees, finance: renderJDFinance, zones: renderJDZones, actions: renderJDActions }
    ;(tabs[state.jd.tab]||tabs.employees)(body)
    $('#jd-tab-employees').onclick = ()=>{ state.jd.tab='employees'; renderJD() }
    $('#jd-tab-finance').onclick   = ()=>{ state.jd.tab='finance'; renderJD() }
    $('#jd-tab-zones').onclick     = ()=>{ state.jd.tab='zones'; renderJD() }
    $('#jd-tab-actions').onclick   = ()=>{ state.jd.tab='actions'; renderJD() }
  }
  function renderJDEmployees(body){ body.innerHTML = `<div class="toolbar"><button class="btn" id="jd-rec">Reclutar</button></div><div id="jd-elist"></div>`; $('#jd-rec').onclick=()=>{ openRecruitModal(state.jd.job, ()=>renderJD()) }; post('getEmployees',{ job: state.jd.job }).then(r=>r.json()).then(list=>{ const wrap=document.createElement('div'); wrap.className='panel'; let html='<table class="table"><thead><tr><th>Nombre</th><th>Rango</th><th>Estado</th><th></th></tr></thead><tbody>';
    list.forEach(e=>{ html+=`<tr><td>${e.name}</td><td>${e.grade}</td><td>${e.online?'<span class=\"badge ok\">Online</span>':'<span class=\"badge off\">Offline</span>'}</td><td class=\"actions-inline\"><button class=\"btn\" data-r=\"${e.citizenid}\">Rango</button><button class=\"btn danger\" data-cid=\"${e.citizenid}\">Despedir</button></td></tr>` })
    html+='</tbody></table>'; wrap.innerHTML=html; body.appendChild(wrap); wrap.querySelectorAll('button[data-cid]').forEach(b=>{ b.onclick=()=>post('fire',{ job: state.jd.job, citizenid: b.dataset.cid }).then(()=>{ toast('Empleado despedido','success'); renderJD() }) }); wrap.querySelectorAll('button[data-r]').forEach(b=>{ b.onclick=()=>{ const cid = b.dataset.r; const emp = list.find(x=>x.citizenid===cid); openSetGradeModal(state.jd.job, emp) } }) }) }
  function renderJDFinance(body){ body.innerHTML=''; const p=document.createElement('div'); p.className='panel'; p.innerHTML='<div id="jd-acc"></div>'; body.appendChild(p); post('getAccount',{ job: state.jd.job }).then(r=>r.json()).then(bal=>{ p.innerHTML = `<div class=\"row\"><div class=\"card\"><div class=\"h\">Saldo</div><div class=\"b\">${money(bal)}</div></div><div class=\"card\"><label>Monto</label><input id=\"jd-amt\" class=\"input\" placeholder=\"Cantidad\"/></div><div class=\"card\"><label>Cuenta</label><select id=\"jd-accsel\" class=\"input\"><option value=\"cash\">Efectivo</option><option value=\"bank\">Banco</option></select></div><div class=\"card\"><div class=\"actions-inline\"><button class=\"btn\" id=\"jd-dep\">Depositar</button><button class=\"btn\" id=\"jd-wd\">Retirar</button><button class=\"btn\" id=\"jd-wash\">Lavar</button></div></div></div>`; $('#jd-dep').onclick=()=>{ const v=Number($('#jd-amt').value)||0; const a=$('#jd-accsel').value; post('deposit',{ job: state.jd.job, amount:v, from:a }).then(()=>{ toast('Depósito realizado','success'); renderJDFinance(body) }) }; $('#jd-wd').onclick=()=>{ const v=Number($('#jd-amt').value)||0; const a=$('#jd-accsel').value; post('withdraw',{ job: state.jd.job, amount:v, to:a }).then(()=>{ toast('Retiro realizado','success'); renderJDFinance(body) }) }; $('#jd-wash').onclick=()=>{ const v=Number($('#jd-amt').value)||0; post('wash',{ job: state.jd.job, amount:v }).then(()=>{ toast('Dinero lavado','success'); renderJDFinance(body) }) } }) }
  function renderJDZones(body) {
   body.innerHTML = `<div class="toolbar"><button class="btn" id="addz">+ Añadir Zona</button></div><div id="zlist" class="panel"></div>`;
   const list = document.getElementById('zlist');

   function extrasText(z) {
     if (!z || !z.data) return '';
     if (z.ztype === 'garage') {
       if (z.data.vehicles) return String(z.data.vehicles);
       if (z.data.vehicle)  return String(z.data.vehicle);
       return '';
     }
     if (z.ztype === 'stash') {
       return `slots:${z.data.slots||50}, w:${z.data.weight||400000}`;
     }
     if (z.ztype === 'boss') {
       return `min:${z.data.minGrade || z.data.gradeMin || 0}`;
     }
     if (z.ztype === 'crafting') {
       return z.data.recipe || '';
     }
     return '';
   }

   function load() {
     post('getZones', { job: state.jd.job })
       .then(r => r.json())
       .then(zs => {
         let html = '<table class="table"><thead><tr><th>ID</th><th>Tipo</th><th>Etiqueta</th><th>Radio</th><th>Extras</th><th></th></tr></thead><tbody>';
         (zs || []).forEach(z => {
           html += `<tr>
             <td>${z.id}</td>
             <td>${z.ztype}</td>
             <td>${z.label || ''}</td>
             <td>${z.radius}</td>
             <td>${extrasText(z)}</td>
             <td><button class="btn danger" data-id="${z.id}">Borrar</button></td>
           </tr>`;
         });
         html += '</tbody></table>';
         list.innerHTML = html;
         list.querySelectorAll('button[data-id]').forEach(b => {
           b.onclick = () => post('deleteZone', { id: Number(b.dataset.id) })
             .then(() => load());
         });
       });
   }
   load();

   document.getElementById('addz').onclick = () => {
     const base = `
       <div class="row">
         <div>
           <label>Tipo</label>
           <select id="ztype" class="input">
             ${ (window.Config?.ZoneTypes || ['blip','boss','stash','garage','crafting','cloakroom','shop','collect','spawner','sell','alarm','register','anim','music','teleport'])
                 .map(t => `<option>${t}</option>`).join('') }
           </select>
         </div>
         <div><label>Etiqueta</label><input id="zlabel" class="input"/></div>
       </div>
       <div class="row">
         <div><label>Radio</label><input id="zrad" class="input" value="2.0"/></div>
         <div><label>Usar mis coords</label><div class="h">Se capturarán al guardar</div></div>
       </div>
       <div id="zextra"></div>
     `;
     modal('Nueva Zona', base, () => {
       // al guardar pedimos coords al cliente
       post('getCoords', {}).then(r => r.json()).then(c => {
         const t = document.getElementById('ztype').value;
         const data = {};
         if (t === 'boss')   data.minGrade = Number(document.getElementById('zmin')?.value || 0);
         if (t === 'stash') { data.slots = Number(document.getElementById('zslots')?.value || 50);
                              data.weight = Number(document.getElementById('zweight')?.value || 400000); }
         if (t === 'garage'){ data.vehicles = document.getElementById('zveh')?.value || '';
                              data.vehicle  = document.getElementById('zvehdef')?.value || ''; }
         if (t === 'crafting') data.recipe = document.getElementById('zrecipe')?.value || '';
         const z = {
           job: state.jd.job,
           ztype: t,
           label: document.getElementById('zlabel').value,
           radius: Number(document.getElementById('zrad').value) || 2.0,
           coords: c,
           data
         };
         post('createZone', z).then(() => { closeModal(); load(); });
       });
     });

     // campos dinámicos según el tipo seleccionado
     const extraBox = document.getElementById('zextra');
     function renderExtra() {
       const t = document.getElementById('ztype').value;
       if (t === 'boss') {
         extraBox.innerHTML = `
           <div class="row">
             <div><label>Mín. rango</label><input id="zmin" class="input" value="0"/></div>
           </div>`;
       } else if (t === 'stash') {
         extraBox.innerHTML = `
           <div class="row">
             <div><label>Slots</label><input id="zslots" class="input" value="50"/></div>
             <div><label>Peso máximo</label><input id="zweight" class="input" value="400000"/></div>
           </div>`;
       } else if (t === 'garage') {
         extraBox.innerHTML = `
           <div><label>Vehículos (rango=modelo, separados por coma)</label>
             <input id="zveh" class="input" placeholder="0=police, 2=police2, 4=ambulance3"/>
           </div>
           <div class="row">
             <div><label>Modelo por defecto</label>
               <input id="zvehdef" class="input" placeholder="police"/>
             </div>
           </div>`;
       } else if (t === 'crafting') {
         extraBox.innerHTML = `
           <div><label>Receta / clave</label>
             <input id="zrecipe" class="input" placeholder="bandage"/>
           </div>`;
       } else {
         extraBox.innerHTML = '';
       }
     }
     document.getElementById('ztype').onchange = renderExtra;
     renderExtra();
   };
 }
  function renderJDActions(body){ body.innerHTML = '<p>Próximamente: switches para habilitar/inhabilitar acciones por trabajo.</p>' }

  // ====== MODALES ======
  function modal(title, inner, onSubmit){ $('#modal-title').textContent=title; $('#modal-content').innerHTML=inner; $('#modal').classList.remove('hidden'); $('#modal-submit').onclick=onSubmit; $('#modal-cancel').onclick=closeModal }
  function promptModal(title, placeholder, onOk){ const html=`<input id=\"pmval\" class=\"input\" placeholder=\"${placeholder}\"/>`; modal(title, html, ()=>{ onOk($('#pmval').value); closeModal() }) }
  function confirm(text, onOk){ const html=`<p>${text}</p>`; modal('Confirmar', html, ()=>{ onOk(); closeModal() }) }
  function closeModal(){ $('#modal').classList.add('hidden') }

  // Modal Reclutar
  function openRecruitModal(jobName, onDone){
    const skeleton = `<div class=\"row\"><div><label>Jugador</label><select id=\"nearbySel\" class=\"input\"><option>Cargando...</option></select></div><div><label>Grado</label><input id=\"nearbyGrade\" class=\"input\" placeholder=\"0\" value=\"0\"/></div></div>`
    modal('Reclutar', skeleton, ()=>{
      const target = Number($('#nearbySel').value)
      const grade = Number($('#nearbyGrade').value) || 0
      if (!target || Number.isNaN(target)) { closeModal(); return }
      post('recruit', { job: jobName, target, grade }).then(()=>{ closeModal(); toast('Reclutado','success'); if(onDone) onDone() })
    })
    post('getNearby',{ job: jobName, radius: 3.0 }).then(r=>r.json()).then(list=>{
      if (!Array.isArray(list) || list.length === 0){ $('#modal-content').innerHTML = '<p>No hay jugadores cercanos disponibles.</p>'; $('#modal-submit').onclick = ()=> closeModal(); return }
      const sel = $('#nearbySel'); sel.innerHTML = list.map(p=>`<option value="${p.id}">${p.name} [${p.id}]</option>`).join('')
    }).catch(()=>{ $('#modal-content').innerHTML = '<p>No hay jugadores cercanos.</p>'; $('#modal-submit').onclick = ()=> closeModal() })
  }

  function renderAll(){
    // si es boss, forzamos el panel del job
    applyScope();
    if (state.scope && state.scope.mode === 'boss') {
      selectView('jobdetail')
    } else {
      selectView('home'); renderHome(); renderJobs()
    }
  }
  return {}
})()


 function toast(msg, kind='info') {
   let box = document.getElementById('toasts');
   if (!box) {
     box = document.createElement('div');
     box.id = 'toasts';
     Object.assign(box.style, { position:'fixed', right:'18px', bottom:'18px', display:'flex', flexDirection:'column', gap:'8px', zIndex: 99999 });
     document.body.appendChild(box);
   }
   const el = document.createElement('div');
   el.textContent = msg;
   Object.assign(el.style, { padding:'10px 14px', borderRadius:'10px', background: (kind==='error' ? '#7f1d1d' : (kind==='success' ? '#065f46' : '#1f2937')), color:'#e5e7eb', boxShadow:'0 10px 30px rgba(0,0,0,.25)' });
   box.appendChild(el);
   setTimeout(() => el.remove(), 2200);
 }