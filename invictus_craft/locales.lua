Locales = {}

Locales['es'] = {
  ui_title = 'KITCHEN',
  ui_tab_food = 'FOOD',
  search = 'Buscar...',
  click_to_info = 'Click para ver información',
  craft = 'CRAFT',
  qty = 'Cant.',
  queue_pending = 'PENDING ITEMS',
  queue_collect = 'ITEMS TO COLLECT',
  leave_all = 'LEAVE ALL QUEUES',
  recipe_for = 'RECETA PARA',
  required_materials = 'MATERIALES REQUERIDOS:',
  you_will_receive = 'RECIBIRÁS:',
  time_left = 'Tiempo restante',
  crafting = 'Elaborando',
  collect = 'RECOGER',
  nothing_to_collect = 'No tienes objetos para recoger',
  in_queue = 'en cola',
  not_enough_mats = 'No tienes materiales suficientes',
  queued = 'Agregado a la cola',
  queue_full = 'La cola está llena',
  queue_limit = 'Has alcanzado el límite de cola',
  job_locked = 'Receta bloqueada por trabajo',
  skill_locked = 'Receta bloqueada por skill'
}

Locales['en'] = {
  ui_title = 'KITCHEN',
  ui_tab_food = 'FOOD',
  search = 'Search...',
  click_to_info = 'Click to view information',
  craft = 'CRAFT',
  qty = 'Qty',
  queue_pending = 'PENDING ITEMS',
  queue_collect = 'ITEMS TO COLLECT',
  leave_all = 'LEAVE ALL QUEUES',
  recipe_for = 'RECIPE FOR',
  required_materials = 'REQUIRED MATERIALS:',
  you_will_receive = 'YOU WILL RECEIVE:',
  time_left = 'Time left',
  crafting = 'Crafting',
  collect = 'COLLECT',
  nothing_to_collect = 'You have no items to collect',
  in_queue = 'in queue',
  not_enough_mats = 'Not enough materials',
  queued = 'Added to queue',
  queue_full = 'Station queue is full',
  queue_limit = 'You reached your personal queue limit',
  job_locked = 'Recipe locked by job',
  skill_locked = 'Recipe locked by skill'
}

function _L(key)
  local lang = (Config.language or 'en')
  return (Locales[lang] and Locales[lang][key]) or Locales['en'][key] or key
end
