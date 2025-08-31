const CraftApp = {
  locale: {},
  data: null,
  images: 'nui://ox_inventory/web/images/',
  filterText: '',
  selected: null
};

const $ = (sel) => document.querySelector(sel);

window.addEventListener('message', (e) => {
  const msg = e.data || {};
  if (msg.action === 'openCraft') {
    CraftApp.locale = msg.locale || {};
    CraftApp.images = msg.images || CraftApp.images;
    const th = msg.theme || {};
    const varMap = {
      colorPrimario: '--bg',
      colorPrimarioAlt: '--bg-alt',
      colorSecundario: '--accent',
      colorSecundarioAlt: '--accent-alt'
    };
    Object.entries(varMap).forEach(([k, v]) => {
      if (th[k]) document.documentElement.style.setProperty(v, th[k]);
    });
    $('#craftTitleText').innerText = msg.title || th.titulo || CraftApp.locale.ui_title || 'KITCHEN';
    $('#craftCategoryTag').innerText = msg.category || CraftApp.locale.ui_tab_food || 'FOOD';
    $('#craftPendingTitle').innerText = CraftApp.locale.queue_pending || 'PENDING ITEMS';
    $('#craftCollectTitle').innerText = CraftApp.locale.queue_collect || 'ITEMS TO COLLECT';
    $('#craftBtnLeaveAll').innerText = CraftApp.locale.leave_all || 'LEAVE ALL QUEUES';
    $('#craftSearchInput').placeholder = CraftApp.locale.search || 'Search...';
    document.getElementById('craftApp').classList.remove('hidden');
  }
  if (msg.action === 'init') {
    CraftApp.data = msg.data; renderAll();
  }
  if (msg.action === 'update') {
    CraftApp.data = msg.data; renderSidebars();
  }
});

function renderAll(){
  renderCards();
  renderSidebars();
  setupSearch();
}

function iconPath(img){
  if(!img) return `${CraftApp.images}placeholder.png`;
  if(!img.includes('.')) img = `${img}.png`;
  return `${CraftApp.images}${img}`;
}
function cardStateClass(status){ return status === 'all' ? 'state-all' : status === 'some' ? 'state-some' : 'state-none'; }

function renderCards(){
  const grid = document.getElementById('craftGrid'); grid.innerHTML = '';
  const recipes = (CraftApp.data?.recipes || []).filter(r => {
    const t = (CraftApp.filterText||'').toLowerCase();
    if (!t) return true;
    return (r.label || r.item).toLowerCase().includes(t) || r.item.toLowerCase().includes(t);
  });

  for (const r of recipes){
    const card = document.createElement('div');
    card.className = `card ${cardStateClass(r.status)} ${(r.lockedByJob || r.lockedBySkill) ? 'locked' : ''}`;
    const imgSrc = iconPath(r.image);
    const errSrc = iconPath('placeholder');
    card.innerHTML = `
      <div class="img"><img src="${imgSrc}" width="96" height="96" loading="lazy" onerror="this.src='${errSrc}'"></div>
      <div class="title">${r.label || r.item}</div>
      <div class="hint">${CraftApp.locale.click_to_info || 'Click to view information'}</div>
      <div class="qtyRow">
        <button class="small dec">-</button>
        <input class="qtyInput" type="number" min="1" value="1">
        <button class="small inc">+</button>
      </div>
      <button class="btn primary craftBtn">${CraftApp.locale.craft || 'CRAFT'}</button>
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
  const q = CraftApp.data?.queue || [];
  const ready = CraftApp.data?.ready || [];

  const pending = document.getElementById('craftPendingList'); pending.innerHTML=''; pending.classList.toggle('empty', q.length===0);
  for (const it of q){
    const row = document.createElement('div');
    row.className='queueItem';
    const imgSrc = iconPath(it.item);
    const errSrc = iconPath('placeholder');
    row.innerHTML = `
      <img src="${imgSrc}" width="32" height="32" loading="lazy" onerror="this.src='${errSrc}'">
      <div>
        <div><b>${it.label}</b></div>
        <div class="badge">${it.amount}x</div>
      </div>
      <div class="badge">${CraftApp.locale.crafting || 'Crafting'}</div>
    `;
    pending.appendChild(row);
  }

  const cl = document.getElementById('craftCollectList'); cl.innerHTML=''; cl.classList.toggle('empty', ready.length===0);
  for (const it of ready){
    const row = document.createElement('div');
    row.className='collectItem';
    const imgSrc = iconPath(it.outputs?.[0]?.item || 'unknown');
    const errSrc = iconPath('placeholder');
    row.innerHTML = `
      <img src="${imgSrc}" width="32" height="32" loading="lazy" onerror="this.src='${errSrc}'">
      <div>
        <div><b>${it.label}</b></div>
        <div class="badge">${new Date(it.timestamp*1000).toLocaleTimeString()}</div>
      </div>
      <button class="small collectBtn">${CraftApp.locale.collect || 'COLLECT'}</button>
    `;
    row.querySelector('.collectBtn').onclick = ()=> fetchNui('collect', { id: it.id });
    cl.appendChild(row);
  }
}

function setupSearch(){
  const s = document.getElementById('craftSearchInput');
  s.oninput = () => { CraftApp.filterText = s.value.trim(); renderCards(); };
}

function showModal(r){
  CraftApp.selected = JSON.parse(JSON.stringify(r));
  document.getElementById('craftModalTitle').innerText = `${(CraftApp.locale.recipe_for||'RECIPE FOR')} ${r.label || r.item}`;
  const mats = document.getElementById('craftModalMats'); mats.innerHTML='';
  for (const m of r.materials||[]){
    const row = document.createElement('div');
    row.className='mat';
    const imgSrc = iconPath(m.item);
    const errSrc = iconPath('placeholder');
    row.innerHTML = `
      <img src="${imgSrc}" width="36" height="36" loading="lazy" onerror="this.src='${errSrc}'">
      <div>${m.item}</div>
      <div class="need">${m.have||0}/${m.need}${m.noConsume?' (tool)':''}</div>
    `;
    mats.appendChild(row);
  }
  const outs = document.getElementById('craftModalOuts'); outs.innerHTML='';
  for (const o of r.outputs||[]){
    const row = document.createElement('div');
    row.className='out';
    const imgSrc = iconPath(o.item);
    const errSrc = iconPath('placeholder');
    row.innerHTML = `
      <img src="${imgSrc}" width="36" height="36" loading="lazy" onerror="this.src='${errSrc}'">
      <div>${o.item}</div>
      <div class="need">x${o.amount}</div>
    `;
    outs.appendChild(row);
  }
  document.getElementById('craftQty').value = 1;
  document.getElementById('craftModal').classList.remove('hidden');
}

document.getElementById('craftModalClose').onclick = ()=> document.getElementById('craftModal').classList.add('hidden');
document.getElementById('craftDec').onclick = ()=> document.getElementById('craftQty').value = Math.max(1, Number(document.getElementById('craftQty').value)-1);
document.getElementById('craftInc').onclick = ()=> document.getElementById('craftQty').value = Number(document.getElementById('craftQty').value)+1;
document.getElementById('craftBtnCraft').onclick = ()=>{
  if (!CraftApp.selected) return;
  fetchNui('craft', { item: CraftApp.selected.item, amount: Number(document.getElementById('craftQty').value||1) });
  document.getElementById('craftModal').classList.add('hidden');
};

document.getElementById('craftBtnLeaveAll').onclick = ()=> fetchNui('leaveAll', {});

function fetchNui(name, data){
  fetch(`https://${GetParentResourceName()}/${name}`, {
    method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data||{})
  })
}

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape'){
    fetchNui('close', {}); document.getElementById('craftApp').classList.add('hidden'); document.getElementById('craftModal').classList.add('hidden');
  }
});
