const App = {
  locale: {},
  data: null,
  images: 'nui://ox_inventory/web/images/',
  filterText: '',
  selected: null
};

const $ = (sel) => document.querySelector(sel);

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'open') {
    App.locale = msg.locale || {};
    App.images = msg.images || App.images;
    $('#titleText').innerText = App.locale.ui_title || 'KITCHEN';
    $('#categoryTag').innerText = App.locale.ui_tab_food || 'FOOD';
    $('#pendingTitle').innerText = App.locale.queue_pending || 'PENDING ITEMS';
    $('#collectTitle').innerText = App.locale.queue_collect || 'ITEMS TO COLLECT';
    $('#btnLeaveAll').innerText = App.locale.leave_all || 'LEAVE ALL QUEUES';
    $('#searchInput').placeholder = App.locale.search || 'Search...';
    document.querySelector('.app').classList.remove('hidden');
  }
  if (msg.action === 'init') {
    App.data = msg.data; renderAll();
  }
  if (msg.action === 'update') {
    App.data = msg.data; renderSidebars();
  }
});

function renderAll(){
  renderCards();
  renderSidebars();
  setupSearch();
}

function iconPath(item){ return `${App.images}${item}.png`; }
function cardStateClass(status){ return status === 'all' ? 'state-all' : status === 'some' ? 'state-some' : 'state-none'; }

function renderCards(){
  const grid = document.getElementById('grid'); grid.innerHTML = '';
  const recipes = (App.data?.recipes || []).filter(r => {
    const t = (App.filterText||'').toLowerCase();
    if (!t) return true;
    return (r.label || r.item).toLowerCase().includes(t) || r.item.toLowerCase().includes(t);
  });

  for (const r of recipes){
    const card = document.createElement('div');
    card.className = `card ${cardStateClass(r.status)} ${(r.lockedByJob || r.lockedBySkill) ? 'locked' : ''}`;
    card.innerHTML = `
      <div class="img"><img src="${iconPath(r.item)}" onerror="this.style.opacity=.2"></div>
      <div class="title">${r.label || r.item}</div>
      <div class="hint">${App.locale.click_to_info || 'Click to view information'}</div>
      <div class="qtyRow">
        <button class="small dec">-</button>
        <input class="qtyInput" type="number" min="1" value="1">
        <button class="small inc">+</button>
      </div>
      <button class="btn primary craftBtn">${App.locale.craft || 'CRAFT'}</button>
      ${(r.lockedByJob || r.lockedBySkill) ? `<i class="fa-solid fa-lock lock" title="Locked"></i>` : ''}
    `;
    const qtyInput = card.querySelector('.qtyInput');
    card.querySelector('.dec').onclick = ()=> qtyInput.value = Math.max(1, Number(qtyInput.value)-1);
    card.querySelector('.inc').onclick = ()=> qtyInput.value = Number(qtyInput.value)+1;
    const openModal = () => showModal(r);
    card.querySelector('.img').onclick = openModal;
    card.querySelector('.title').onclick = openModal;
    card.querySelector('.craftBtn').onclick = ()=>{
      if (r.lockedByJob || r.lockedBySkill) return;
      fetchNui('craft', { item: r.item, amount: Number(qtyInput.value||1) });
    };
    grid.appendChild(card);
  }
}

function renderSidebars(){
  const q = App.data?.queue || [];
  const ready = App.data?.ready || [];

  const pending = document.getElementById('pendingList'); pending.innerHTML=''; pending.classList.toggle('empty', q.length===0);
  for (const it of q){
    const row = document.createElement('div');
    row.className='queueItem';
    row.innerHTML = `
      <img src="${iconPath(it.item)}" width="32" height="32" onerror="this.style.opacity=.2">
      <div>
        <div><b>${it.label}</b></div>
        <div class="badge">${it.amount}x</div>
      </div>
      <div class="badge">${App.locale.crafting || 'Crafting'}</div>
    `;
    pending.appendChild(row);
  }

  const cl = document.getElementById('collectList'); cl.innerHTML=''; cl.classList.toggle('empty', ready.length===0);
  for (const it of ready){
    const row = document.createElement('div');
    row.className='collectItem';
    row.innerHTML = `
      <img src="${iconPath(it.outputs?.[0]?.item || 'unknown')}" width="32" height="32" onerror="this.style.opacity=.2">
      <div>
        <div><b>${it.label}</b></div>
        <div class="badge">${new Date(it.timestamp*1000).toLocaleTimeString()}</div>
      </div>
      <button class="small collectBtn">${App.locale.collect || 'COLLECT'}</button>
    `;
    row.querySelector('.collectBtn').onclick = ()=> fetchNui('collect', { id: it.id });
    cl.appendChild(row);
  }
}

function setupSearch(){
  const s = document.getElementById('searchInput');
  s.oninput = () => { App.filterText = s.value.trim(); renderCards(); };
}

function showModal(r){
  App.selected = JSON.parse(JSON.stringify(r));
  document.getElementById('modalTitle').innerText = `${(App.locale.recipe_for||'RECIPE FOR')} ${r.label || r.item}`;
  const mats = document.getElementById('modalMats'); mats.innerHTML='';
  for (const m of r.materials||[]){
    const row = document.createElement('div');
    row.className='mat';
    row.innerHTML = `
      <img src="${iconPath(m.item)}" width="36" height="36" onerror="this.style.opacity=.2">
      <div>${m.item}</div>
      <div class="need">${m.have||0}/${m.need}${m.noConsume?' (tool)':''}</div>
    `;
    mats.appendChild(row);
  }
  const outs = document.getElementById('modalOuts'); outs.innerHTML='';
  for (const o of r.outputs||[]){
    const row = document.createElement('div');
    row.className='out';
    row.innerHTML = `
      <img src="${iconPath(o.item)}" width="36" height="36" onerror="this.style.opacity=.2">
      <div>${o.item}</div>
      <div class="need">x${o.amount}</div>
    `;
    outs.appendChild(row);
  }
  document.getElementById('qty').value = 1;
  document.querySelector('.modal').classList.remove('hidden');
}

document.getElementById('modalClose').onclick = ()=> document.querySelector('.modal').classList.add('hidden');
document.getElementById('dec').onclick = ()=> document.getElementById('qty').value = Math.max(1, Number(document.getElementById('qty').value)-1);
document.getElementById('inc').onclick = ()=> document.getElementById('qty').value = Number(document.getElementById('qty').value)+1;
document.getElementById('btnCraft').onclick = ()=>{
  if (!App.selected) return;
  fetchNui('craft', { item: App.selected.item, amount: Number(document.getElementById('qty').value||1) });
  document.querySelector('.modal').classList.add('hidden');
};

document.getElementById('btnLeaveAll').onclick = ()=> fetchNui('leaveAll', {});

function fetchNui(name, data){
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data||{})
  })
}

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape'){
    fetchNui('close', {}); document.querySelector('.app').classList.add('hidden'); document.querySelector('.modal').classList.add('hidden');
  }
});
