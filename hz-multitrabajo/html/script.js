/* Desarrollado por HZ - CodigosParaJuegos - FivemSoluciones */

// Variables globales
let isUIOpen = false;
let currentJobData = null;
let playerJobs = [];
let dutyStatus = false;
let lastActivity = Date.now();
let framework = 'qbcore'; // Por defecto
let jobChangeHistory = []; // Historial de cambios de trabajo
let totalJobChanges = 0; // Contador total de cambios
let currentJobStartTime = null;
let jobTimeInterval = null;
let lastActivityTime = Date.now();
let jobTimers = {}; // Almacenar tiempo por trabajo
let jobTimeData = {};
let currentJobTime = 0;

// Configuración de audio (deshabilitado por ahora)
const audioConfig = {
    enabled: false,
    volume: 0.5
};

// Funciones de audio
function playSound(soundName) {
    if (!audioConfig.enabled) return;
    // Implementar sonidos aquí si es necesario
}

// Manejo de mensajes NUI
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'open':
        case 'openUI':
            openUI(data);
            break;
        case 'close':
        case 'closeUI':
            closeUI();
            break;
        case 'updateJobs':
            if (data.jobs) {
                playerJobs = data.jobs;
                populateJobs(data.jobs);
            }
            break;
        case 'updateCurrentJob':
            updateCurrentJob(data.job);
            break;
        case 'updateDutyStatus':
            updateDutyStatus(data.onduty);
            break;
        
        case 'updateJobData':
            if (data.currentJob) {
                updateCurrentJob(data.currentJob);
            }
            if (data.jobs) {
                playerJobs = data.jobs;
                populateJobs(data.jobs);
            }
            break;
        case 'showNotification':
            showNotification(data.message, data.type || 'info');
            break;
        case 'updateJobTime':
            if (data.jobName && data.totalTime !== undefined) {
                jobTimeData[data.jobName] = data.totalTime;
                updateTimeDisplay();
            }
            break;
    }
});

// Función para abrir la UI
function openUI(data) {
    if (isUIOpen) {
        return;
    }
    
    isUIOpen = true;
    
    // Asegurar que el fondo sea transparente
    document.body.style.background = 'transparent';
    
    // Mostrar solo el contenedor (sin overlay para evitar marco negro)
    const container = document.getElementById('multijob-ui');
    
    if (container) {
        container.style.display = 'block';
        container.style.visibility = 'visible';
        container.style.opacity = '1';
        container.style.position = 'fixed';
        container.style.top = '50%';
        container.style.left = '50%';
        container.style.transform = 'translate(-50%, -50%)';
        container.style.zIndex = '9999';
        
        // Forzar reflow y agregar clase de animación
        requestAnimationFrame(() => {
            container.classList.add('show');
        });
        
        // Cargar datos de tiempo de trabajo
        if (data.jobTimeData) {
            jobTimeData = { ...jobTimeData, ...data.jobTimeData };
        }
        
        if (data.currentJobTime) {
            currentJobTime = data.currentJobTime;
        }
        
        // Actualizar trabajo actual
        if (data.currentJob) {
            
            // Actualizar los datos básicos
            currentJobData = data.currentJob;
            
            const jobName = document.getElementById('current-job-name');
            const jobGrade = document.getElementById('current-job-grade');
            const jobSalary = document.getElementById('current-job-salary');
            
            if (jobName) {
                jobName.textContent = data.currentJob.label || data.currentJob.name || 'Desconocido';
            }
            
            if (jobGrade) {
                jobGrade.textContent = data.currentJob.grade_name || data.currentJob.gradeLabel || 'Sin Grado';
            }
            
            if (jobSalary) {
                jobSalary.style.display = 'none';
            }
        }
        
        // Actualizar lista de trabajos
        if (data.jobs) {
            playerJobs = data.jobs;
            populateJobs(data.jobs);
        }
        
        // Actualizar estado de duty desde currentJob si está disponible
        if (data.currentJob && data.currentJob.onduty !== undefined) {
            dutyStatus = data.currentJob.onduty;
            updateDutyStatus(data.currentJob.onduty);
        } else if (data.dutyStatus !== undefined) {
            dutyStatus = data.dutyStatus;
            updateDutyStatus(data.dutyStatus);
        }
        
        // Actualizar display de tiempo
        updateTimeDisplay();
        
        // Habilitar controles del cursor
        $.post('https://hz-multitrabajo/focus', JSON.stringify({ focus: true }));
        
        updateLastActivity();
    
    // Agregar event listener para el botón de duty
    const dutyButton = document.getElementById('duty-toggle');
    if (dutyButton) {
        dutyButton.onclick = toggleDuty;
    }
    

}
}

// Función para cerrar la UI
function closeUI() {
    if (!isUIOpen) {
        return;
    }
    
    isUIOpen = false;
    
    // Asegurar que el fondo sea transparente inmediatamente
    document.body.style.background = 'transparent';
    document.body.style.backgroundColor = 'transparent';
    
    // Ocultar el contenedor con animación
    const container = document.getElementById('multijob-ui');
    
    if (container) {
        container.classList.remove('show');
    }
    
    // Esperar a que termine la animación antes de ocultar completamente
    setTimeout(() => {
        if (container) {
            container.style.display = 'none';
            container.style.visibility = 'hidden';
        }
        // Forzar transparencia del fondo
        document.body.style.background = 'transparent';
        document.body.style.backgroundColor = 'transparent';
    }, 300);
    
    // Deshabilitar controles del cursor
    $.post('https://hz-multitrabajo/focus', JSON.stringify({ focus: false }));
    

    
    // Notificar al cliente que se cerró la UI
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

// Función para alternar el estado de duty
function toggleDuty() {
    
    fetch(`https://${GetParentResourceName()}/toggleDuty`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(data => {

        if (data.success) {
            // Actualizar el estado de duty en la UI
            const newDutyStatus = data.onduty === true || data.onduty === 1;
            updateDutyStatus(newDutyStatus);
            
            // Actualizar el texto de estado
            const statusContainer = document.getElementById('duty-status-text');
            const statusSpan = statusContainer ? statusContainer.querySelector('span') : null;
            if (statusSpan) {
                statusSpan.textContent = newDutyStatus ? 'En Servicio' : 'Fuera de Servicio';
            }
            
            showNotification(data.message || 'Estado de servicio cambiado', 'success');
        } else {
            showNotification(data.message || 'Error al cambiar estado de servicio', 'error');
        }
    })
    .catch(error => {

        showNotification('Error al cambiar estado de servicio', 'error');
    });
}

// Función para actualizar el estado de duty
function updateDutyStatus(status) {
    const previousStatus = dutyStatus;
    dutyStatus = status;
    
    const dutyIndicator = document.getElementById('duty-indicator');
    const statusText = document.getElementById('duty-status');
    
    if (dutyIndicator) {
        dutyIndicator.className = `indicator-dot ${status ? 'on' : 'off'}`;
    }
    
    if (statusText) {
        statusText.textContent = status ? 'En Servicio' : 'Fuera de Servicio';
    }
    
    updateDutyButton();
}

// Función para actualizar el botón de duty
function updateDutyButton() {
    const dutyButton = document.getElementById('duty-toggle');
    const dutyText = document.getElementById('duty-text');
    
    if (dutyButton) {
        if (dutyStatus) {
            dutyButton.classList.add('on-duty');
        } else {
            dutyButton.classList.remove('on-duty');
        }
    }
    
    if (dutyText) {
        dutyText.textContent = dutyStatus ? 'Salir de Servicio' : 'Entrar en Servicio';
    }
    
    // Manejar timer según el estado de duty
    if (status && !previousStatus) {
        // Entró en duty - iniciar timer
        startJobTimer();
    } else if (!status && previousStatus) {
        // Salió de duty - guardar tiempo acumulado y detener timer
        if (currentJobData && currentJobStartTime) {
            const sessionTime = Date.now() - currentJobStartTime;
            const jobName = currentJobData.name;
            if (jobName) {
                jobTimeData[jobName] = (jobTimeData[jobName] || 0) + sessionTime;
            }
        }
        stopJobTimer();
    }
    
    // Actualizar display de tiempo
    updateTimeDisplay();
    
    // Guardar el estado actual globalmente
    window.currentDutyStatus = status;
}

// Función para actualizar el botón de duty
function updateDutyButton() {
    const button = document.getElementById('duty-toggle-btn');
    const dutyText = document.getElementById('duty-text');
    
    if (!button || !dutyText) return;
    
    // Limpiar clases existentes
    button.className = 'duty-toggle-btn';
    
    if (dutyStatus) {
        // Si está en servicio, mostrar opción para salir
        dutyText.textContent = 'Salir de Servicio';
        button.classList.add('on-duty'); // Botón rojo para salir
    } else {
        // Si está fuera de servicio, mostrar opción para entrar
        dutyText.textContent = 'Entrar en Servicio';
        button.classList.remove('on-duty'); // Botón verde para entrar
    }
}

// Función para actualizar el trabajo actual
function updateCurrentJob(job) {
    
    if (!job) {

        return;
    }
    
    // Guardar tiempo del trabajo anterior si existe
    saveCurrentJobTime();
    
    // Detener timer actual
    stopJobTimer();
    
    currentJobData = job;
    
    const jobName = document.getElementById('current-job-name');
    const jobGrade = document.getElementById('current-job-grade');
    const jobSalary = document.getElementById('current-job-salary');
    
    if (jobName) {

        jobName.textContent = job.label || job.name || 'Desconocido';
    }
    
    if (jobGrade) {

        jobGrade.textContent = job.grade_name || job.gradeLabel || 'Sin Grado';
    }
    
    if (jobSalary) {
        jobSalary.style.display = 'none';
    }
    
    // Actualizar estado de duty si está disponible
    if (job.onduty !== undefined) {

        updateDutyStatus(job.onduty);
    }
    
    // Resetear el tiempo de inicio para el nuevo trabajo
    currentJobStartTime = null;
    
    // Iniciar timer para el nuevo trabajo si está en duty
    if (dutyStatus && job) {
        // Iniciar nuevo timer desde ahora
        currentJobStartTime = Date.now();
        startJobTimer();
    }
    
    // Actualizar display de tiempo inmediatamente
    updateTimeDisplay();
    
    // Actualizar la lista de trabajos para reflejar el cambio
    if (playerJobs && Array.isArray(playerJobs)) {
        populateJobs(playerJobs);
    }
}



// Función para poblar la lista de trabajos
function populateJobs(jobs) {
    
    // Validar que jobs sea un array
    if (!Array.isArray(jobs)) {

        jobs = [];
    }
    
    const container = document.getElementById('jobs-container');
    const jobCounter = document.querySelector('.job-counter');
    
    if (!container) {

        return;
    }
    
    // Actualizar contador
    if (jobCounter) {
        jobCounter.textContent = `${jobs.length} trabajos`;
    }
    
    // Limpiar contenedor
    container.innerHTML = '';
    
    if (jobs.length === 0) {
        container.innerHTML = `
            <div class="no-jobs">
                <i class="fas fa-briefcase"></i>
                <p>No tienes trabajos disponibles</p>
            </div>
        `;
        updateJobCounter(); // Actualizar contador incluso sin trabajos
        return;
    }
    

    
    jobs.forEach((job, index) => {
        try {
            // Verificar si es el trabajo actual
            const isCurrent = currentJobData && (
                (job.name === currentJobData.name) || 
                (job.label === currentJobData.label) ||
                (job.job === currentJobData.name)
            );
            
    
            
            const jobElement = document.createElement('div');
            jobElement.className = `job-item ${isCurrent ? 'current' : ''}`;
            
            const jobName = job.name || job.job;
            const jobLabel = job.label || job.name || 'Trabajo Desconocido';
            
            // Información de salario removida
            
            jobElement.innerHTML = `
                <div class="job-header">
                    <div class="job-info-item">
                        <h4>${jobLabel}</h4>
                        <p>Grado: ${job.grade_name || job.gradeLabel || job.grade?.name || `Grado ${job.grade || 0}`}</p>
                        <div class="job-salary-list" style="display: none;">
                        </div>
                    </div>
                    <div class="job-actions">
                        ${isCurrent ? 
                            '<div class="current-badge"><i class="fas fa-check"></i> Actual</div>' : 
                            `<button class="btn btn-primary switch-job-btn" data-job-name="${jobName}">
                                <i class="fas fa-exchange-alt"></i> Cambiar
                            </button>`
                        }
                        <button class="btn btn-danger remove-job-btn" data-job-id="${job.id}" data-job-name="${jobName}" data-job-label="${jobLabel}" ${isCurrent ? 'disabled' : ''}>
                            <i class="fas fa-trash"></i> Eliminar
                        </button>
                    </div>
                </div>
            `;
            
            // Agregar event listeners
            const switchBtn = jobElement.querySelector('.switch-job-btn');
            const removeBtn = jobElement.querySelector('.remove-job-btn');
            
            if (switchBtn) {
                switchBtn.addEventListener('click', () => {
                    switchJob(jobName);
                });
            }
            
            if (removeBtn && !isCurrent) {
                removeBtn.addEventListener('click', () => {
                    const jobId = removeBtn.getAttribute('data-job-id');
                    removeJob(jobId, jobName, jobLabel);
                });
            }
            
            container.appendChild(jobElement);
        } catch (error) {

        }
    });
    
    // Iniciar contador de tiempo si hay trabajo actual
    if (currentJobData) {
        startJobTimer();
    }
    
    // Actualizar contador de trabajos
    updateJobCounter();
}

// Sistema de notificaciones
function showNotification(message, type = 'info') {
    const container = document.querySelector('.notifications-container') || createNotificationContainer();
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const icons = {
        success: 'fas fa-check-circle',
        error: 'fas fa-exclamation-circle',
        warning: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };
    
    notification.innerHTML = `
        <i class="${icons[type] || icons.info}"></i>
        <span>${message}</span>
    `;
    
    container.appendChild(notification);
    
    // Mostrar notificación
    setTimeout(() => {
        notification.classList.add('show');
    }, 100);
    
    // Ocultar y eliminar después de 5 segundos
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
        }, 300);
    }, 5000);
}

// Crear contenedor de notificaciones si no existe
function createNotificationContainer() {
    const container = document.createElement('div');
    container.className = 'notifications-container';
    document.body.appendChild(container);
    return container;
}

// Función para guardar tiempo del trabajo actual
function saveCurrentJobTime() {
    if (currentJobData && currentJobStartTime && dutyStatus) {
        const sessionTime = Date.now() - currentJobStartTime;
        const jobName = currentJobData.name;
        if (jobName) {
            jobTimeData[jobName] = (jobTimeData[jobName] || 0) + sessionTime;

            // Reiniciar el tiempo de inicio para continuar acumulando desde este punto
            currentJobStartTime = Date.now();
        }
    }
}

// Función para cambiar de trabajo
function switchJob(jobName) {
    
    // Guardar tiempo del trabajo anterior si está en duty
    saveCurrentJobTime();
    
    // Detener timer actual
    stopJobTimer();
    
    // Buscar el trabajo en la lista para obtener datos completos
    const job = playerJobs.find(j => j.name === jobName);
    const previousJob = currentJobData;
    
    // Mostrar indicador de carga
    showNotification('Cambiando trabajo...', 'info');
    
    fetch(`https://${GetParentResourceName()}/switchJob`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ jobName: jobName, jobGrade: 0 })
    }).then(response => {
        if (response.ok) {
            // Agregar al historial con datos completos
            addJobChangeToHistory(previousJob, job, 'CAMBIO');
            
            showNotification(`Trabajo cambiado a: ${jobName}`, 'success');
            // Crear efectos visuales
            createJobChangeEffect();
            totalJobChanges++;
            updateJobCounter();
            
            // El timer se iniciará automáticamente cuando se actualice currentJobData
            // si el jugador está en duty
        } else {
            showNotification('Error al cambiar de trabajo', 'error');
        }
    }).catch(error => {

        showNotification('Error al cambiar de trabajo', 'error');
    });
}

// Función para agregar al historial de trabajos (versión legacy)
function addToJobHistory(fromJob, toJob) {
    const timestamp = new Date().toLocaleString();
    jobChangeHistory.unshift({
        from: fromJob,
        to: toJob,
        timestamp: timestamp
    });
    
    // Mantener solo los últimos 10 cambios
    if (jobChangeHistory.length > 10) {
        jobChangeHistory = jobChangeHistory.slice(0, 10);
    }
}

// Función para mostrar/ocultar historial de trabajos
function toggleJobHistory() {
    let historyElement = document.getElementById('job-history');
    
    if (historyElement) {
        historyElement.remove();
        return;
    }
    
    historyElement = document.createElement('div');
    historyElement.id = 'job-history';
    historyElement.className = 'job-history';
    
    let historyHTML = `
        <div class="history-header">
            <h4><i class="fas fa-history"></i> Historial de Cambios</h4>
            <button onclick="toggleJobHistory()" class="close-history">
                <i class="fas fa-times"></i>
            </button>
        </div>
        <div class="history-content">
    `;
    
    if (jobChangeHistory.length === 0) {
        historyHTML += '<p class="no-history">No hay cambios registrados</p>';
    } else {
        jobChangeHistory.forEach((change, index) => {
            historyHTML += `
                <div class="history-item">
                    <div class="history-info">
                        <span class="from-job">${change.from}</span>
                        <i class="fas fa-arrow-right"></i>
                        <span class="to-job">${change.to}</span>
                    </div>
                    <div class="history-time">${change.timestamp}</div>
                </div>
            `;
        });
    }
    
    historyHTML += '</div>';
    historyElement.innerHTML = historyHTML;
    
    const container = document.querySelector('.main-content');
    container.appendChild(historyElement);
    
    // Animación de entrada
    setTimeout(() => {
        historyElement.classList.add('show');
    }, 10);
}

// Función para eliminar trabajo mejorada
function removeJob(jobId, jobName, jobLabel) {

    
    // Verificar parámetros
    if (!jobId || !jobName) {

        showNotification('Error: Datos del trabajo incompletos', 'error');
        return;
    }
    
    // Verificar si es el trabajo actual
    if (currentJobData && (currentJobData.name === jobName || currentJobData.label === jobName)) {
        showNotification('No puedes eliminar tu trabajo actual', 'error');
        return;
    }
    
    const displayName = jobLabel || jobName;
    
    showConfirmDialog(
        'Confirmar eliminación',
        `¿Estás seguro de que quieres eliminar el trabajo "${displayName}"?`,
        () => {
    
            
            // Confirmar eliminación
            fetch(`https://${GetParentResourceName()}/removeJob`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ jobId: jobId })
            })
            .then(response => {
    
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                
                if (data && data.success) {
                    // Agregar al historial la eliminación
                    const removedJob = { name: jobName, label: jobLabel };
                    addJobChangeToHistory(removedJob, null, 'ELIMINADO');
                    
                    showNotification(`Trabajo "${displayName}" eliminado correctamente`, 'success');
                    // Actualizar la lista de trabajos
                    const jobElement = document.querySelector(`[data-job-name="${jobName}"]`);
                    if (jobElement) {
                        jobElement.remove();
                    }
                    // Actualizar contador de trabajos
                     updateJobCounter();
                } else {
                    const errorMsg = data?.message || 'Error desconocido al eliminar el trabajo';
                    
                    showNotification(errorMsg, 'error');
                }
            })
            .catch(error => {
                showNotification(`Error de conexión: ${error.message}`, 'error');
            });
        },
        () => {
   
        }
    );
}

// Función para actualizar la última actividad
function updateLastActivity() {
    lastActivity = Date.now();
}

// Actualizar última actividad cada 30 segundos
setInterval(updateLastActivity, 30000);

// Guardar tiempo del trabajo actual cada 10 segundos para evitar pérdidas
setInterval(() => {
    if (currentJobData && currentJobStartTime && dutyStatus) {
        saveCurrentJobTime();
    }
}, 10000);





// Función para obtener el tiempo en el trabajo actual
function getTimeInCurrentJob() {
    if (!currentJobData || !currentJobData.name) return '00:00:00';
    
    const jobName = currentJobData.name;
    
    // Obtener tiempo total guardado para este trabajo específico
    const savedTime = jobTimeData[jobName] || 0;

    
    // Si está en duty y hay tiempo de inicio, agregar tiempo de la sesión actual
    let currentSessionTime = 0;
    if (dutyStatus && currentJobStartTime) {
        currentSessionTime = Date.now() - currentJobStartTime;

    }
    
    const totalMs = savedTime + currentSessionTime;
    const hours = Math.floor(totalMs / (1000 * 60 * 60));
    const minutes = Math.floor((totalMs % (1000 * 60 * 60)) / (1000 * 60));
    const seconds = Math.floor((totalMs % (1000 * 60)) / 1000);
    
    const timeString = `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

    
    return timeString;
}

// Función para actualizar el display de tiempo mejorado
function updateTimeDisplay() {
    const timeStatsContainer = document.getElementById('job-time-stats');
    if (!timeStatsContainer) return;
    
    if (currentJobData) {
        const elapsedTime = getTimeInCurrentJob();
        const jobLabel = currentJobData.label || currentJobData.name || 'Trabajo Actual';
        const jobGrade = currentJobData.grade_label || currentJobData.grade_name || currentJobData.gradeLabel || `Grado ${currentJobData.grade || 0}`;
        const dutyText = dutyStatus ? 'En Servicio' : 'Fuera de Servicio';
        
        timeStatsContainer.innerHTML = `
            <div class="time-label">Tiempo Total Trabajado</div>
            <div class="time-display">${elapsedTime}</div>
            <div class="job-name-display">${jobLabel} - ${jobGrade}</div>
            <div class="duty-status-display">${dutyText}</div>
        `;
    } else {
        timeStatsContainer.innerHTML = `
            <div class="time-label">Tiempo Total Trabajado</div>
            <div class="time-display">00:00:00</div>
            <div class="job-name-display">Sin trabajo activo</div>
        `;
    }
}

// Función para actualizar el contador de trabajos
function updateJobCounter() {
    const jobCounter = document.querySelector('.job-counter');
    const jobItems = document.querySelectorAll('.job-item');
    
    if (jobCounter) {
        jobCounter.textContent = `${jobItems.length} trabajos`;
    }
}

// Función para iniciar el contador de tiempo
function startJobTimer() {
    if (!dutyStatus || !currentJobData) {

        return; // Solo iniciar si está en duty y hay trabajo actual
    }
    
    // Solo iniciar nuevo timer si no hay uno activo para este trabajo
    if (!currentJobStartTime) {
        currentJobStartTime = Date.now();
    
    }
    
    // Limpiar intervalo anterior si existe
    if (jobTimeInterval) {
        clearInterval(jobTimeInterval);
        jobTimeInterval = null;
    }
    
    // Actualizar cada segundo con validación mejorada
    jobTimeInterval = setInterval(() => {
        try {
            if (dutyStatus && currentJobData && currentJobStartTime) {
                updateTimeDisplay();
            } else {
    
                stopJobTimer();
            }
        } catch (error) {
            stopJobTimer();
        }
    }, 1000);
    
    // Actualizar inmediatamente
    updateTimeDisplay();
}

// Función para detener el contador de tiempo
function stopJobTimer() {
    if (jobTimeInterval) {
        clearInterval(jobTimeInterval);
        jobTimeInterval = null;
    }
    currentJobStartTime = null;
    updateTimeDisplay(); // Actualizar una vez más al detener
}

// Función para mostrar estadísticas avanzadas
function showAdvancedStats() {
    const avgTimePerJob = totalJobChanges > 0 ? Math.round((Date.now() - (currentJobStartTime || Date.now())) / totalJobChanges / 1000 / 60) : 0;
    const mostUsedJob = getMostUsedJob();
    
    showNotification(`Estadísticas: ${totalJobChanges} cambios, Promedio: ${avgTimePerJob}min/trabajo, Más usado: ${mostUsedJob}`, 'info');
}

// Función para obtener el trabajo más usado
function getMostUsedJob() {
    if (jobChangeHistory.length === 0) return 'N/A';
    
    const jobCount = {};
    jobChangeHistory.forEach(change => {
        jobCount[change.to] = (jobCount[change.to] || 0) + 1;
    });
    
    return Object.keys(jobCount).reduce((a, b) => jobCount[a] > jobCount[b] ? a : b);
}

// Función para exportar estadísticas
function exportStats() {
    const stats = {
        totalJobs: playerJobs ? playerJobs.length : 0,
        currentJob: currentJobData ? currentJobData.label || currentJobData.name : 'Ninguno',
        totalChanges: totalJobChanges,
        timeInCurrentJob: getTimeInCurrentJob(),
        history: jobChangeHistory,
        exportDate: new Date().toISOString()
    };
    

    showNotification('Estadísticas exportadas a consola', 'success');
}

// Función para manejar el logo del servidor
function initializeServerLogo() {
    const logoImg = document.querySelector('.server-logo img');
    if (logoImg) {
        logoImg.onerror = function() {
    
            this.style.display = 'none';
            const fallback = this.parentElement.querySelector('.logo-fallback');
            if (!fallback) {
                const fallbackDiv = document.createElement('div');
                fallbackDiv.className = 'logo-fallback';
                fallbackDiv.innerHTML = '🏢';
                fallbackDiv.style.cssText = `
                    font-size: 35px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    width: 100%;
                    height: 100%;
                    color: #ffffff;
                `;
                this.parentElement.appendChild(fallbackDiv);
            }
        };
        
        logoImg.onload = function() {
    
            this.style.display = 'block';
            const fallback = this.parentElement.querySelector('.logo-fallback');
            if (fallback) {
                fallback.remove();
            }
        };
        
        // Verificar si la imagen ya está cargada
        if (logoImg.complete) {
            if (logoImg.naturalWidth === 0) {
                logoImg.onerror();
            } else {
                logoImg.onload();
            }
        }
    }
}

// Inicialización cuando el documento esté listo
$(document).ready(function() {

    
    // Inicializar logo del servidor
    initializeServerLogo();
    
    // Ocultar UI inicialmente
    const appContainer = document.getElementById('multijob-ui');
    
    if (appContainer) {
        appContainer.style.display = 'none';
    }
    
    // Crear contenedor de notificaciones si no existe
    if (!document.querySelector('.notifications-container')) {
        const notificationsContainer = document.createElement('div');
        notificationsContainer.className = 'notifications-container';
        document.body.appendChild(notificationsContainer);
    }
    
    // Event listeners
    document.addEventListener('click', function(e) {

        
        if (e.target.id === 'close-button' || e.target.closest('#close-button')) {

            closeUI();
        } else if (e.target.id === 'duty-toggle-btn' || e.target.closest('#duty-toggle-btn')) {

            toggleDuty();
        } else if (e.target.id === 'history-toggle-btn' || e.target.closest('#history-toggle-btn')) {

            toggleHistoryView();
        }
    });
    
    // Cerrar UI con ESC y atajos de teclado
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape' && isUIOpen) {

            closeUI();
        }
        // Atajos de teclado adicionales
        if (e.ctrlKey && e.key === 's') {
            e.preventDefault();
            showAdvancedStats();
        }
        if (e.ctrlKey && e.key === 'e') {
            e.preventDefault();
            exportStats();
        }
    });
    
    // Actualizar la última actividad cada minuto
    setInterval(updateLastActivity, 60000);
    
    // Mostrar mensaje de bienvenida
    setTimeout(() => {
        // Notificación de carga removida
    }, 1000);
    

});

// Función para obtener el nombre del recurso padre
function GetParentResourceName() {
    return 'hz-multitrabajo';
}



// Función para mostrar confirmación elegante
function showConfirmDialog(title, message, onConfirm, onCancel) {
    const overlay = document.createElement('div');
    overlay.className = 'confirm-overlay';
    overlay.innerHTML = `
        <div class="confirm-dialog">
            <div class="confirm-header">
                <i class="fas fa-question-circle"></i>
                <h4>${title}</h4>
            </div>
            <div class="confirm-content">
                <p>${message}</p>
            </div>
            <div class="confirm-actions">
                <button class="btn-cancel" onclick="closeConfirmDialog()">Cancelar</button>
                <button class="btn-confirm" onclick="confirmAction()">Confirmar</button>
            </div>
        </div>
    `;
    
    document.body.appendChild(overlay);
    
    // Agregar funciones globales temporales
    window.closeConfirmDialog = function() {
        overlay.remove();
        if (onCancel) onCancel();
        delete window.closeConfirmDialog;
        delete window.confirmAction;
    };
    
    window.confirmAction = function() {
        overlay.remove();
        if (onConfirm) onConfirm();
        delete window.closeConfirmDialog;
        delete window.confirmAction;
    };
    
    // Mostrar con animación
    setTimeout(() => overlay.classList.add('show'), 10);
}

// Función para agregar efectos de partículas al cambiar trabajo
function createJobChangeEffect() {
    const container = document.querySelector('.container');
    if (!container) return;
    
    for (let i = 0; i < 20; i++) {
        const particle = document.createElement('div');
        particle.className = 'job-particle';
        particle.style.left = Math.random() * 100 + '%';
        particle.style.animationDelay = Math.random() * 2 + 's';
        container.appendChild(particle);
        
        // Remover partícula después de la animación
        setTimeout(() => {
            if (particle.parentNode) {
                particle.parentNode.removeChild(particle);
            }
        }, 3000);
    }
}

// Funciones del Historial de Cambios
function addJobChangeToHistory(fromJob, toJob, changeType = 'CAMBIO') {
    const historyEntry = {
        id: Date.now(),
        timestamp: new Date(),
        fromJob: fromJob ? {
            name: fromJob.name || fromJob.label,
            label: fromJob.label || fromJob.name,
            grade: fromJob.grade_name || fromJob.gradeLabel
        } : null,
        toJob: toJob ? {
            name: toJob.name || toJob.label,
            label: toJob.label || toJob.name,
            grade: toJob.grade_name || toJob.gradeLabel
        } : null,
        changeType: changeType
    };
    
    jobChangeHistory.unshift(historyEntry);
    
    // Mantener solo los últimos 50 cambios
    if (jobChangeHistory.length > 50) {
        jobChangeHistory = jobChangeHistory.slice(0, 50);
    }
    
    totalJobChanges++;
    
    // Actualizar la UI del historial si está visible
    updateHistoryDisplay();
}

function toggleHistoryView() {
    const historyContainer = document.getElementById('history-container');
    const toggleBtn = document.getElementById('history-toggle-btn');
    
    if (!historyContainer || !toggleBtn) return;
    
    const isVisible = historyContainer.style.display !== 'none';
    
    if (isVisible) {
        historyContainer.style.display = 'none';
        toggleBtn.innerHTML = '<i class="fas fa-eye"></i> Ver';
    } else {
        historyContainer.style.display = 'block';
        toggleBtn.innerHTML = '<i class="fas fa-eye-slash"></i> Ocultar';
        updateHistoryDisplay();
    }
}

function updateHistoryDisplay() {
    const historyList = document.getElementById('history-list');
    if (!historyList) return;
    
    if (jobChangeHistory.length === 0) {
        historyList.innerHTML = `
            <div class="no-history">
                <i class="fas fa-clock"></i>
                <p>No hay cambios registrados</p>
            </div>
        `;
        return;
    }
    
    let historyHTML = '';
    
    jobChangeHistory.forEach(entry => {
        const timeAgo = getTimeAgo(entry.timestamp);
        const changeTypeClass = entry.changeType.toLowerCase();
        
        let changeDescription = '';
        if (entry.changeType === 'CAMBIO' && entry.fromJob && entry.toJob) {
            changeDescription = `Cambió de <span class="history-job-name">${entry.fromJob.label}</span> a <span class="history-job-name">${entry.toJob.label}</span>`;
        } else if (entry.changeType === 'INICIO' && entry.toJob) {
            changeDescription = `Inició trabajo como <span class="history-job-name">${entry.toJob.label}</span>`;
        } else if (entry.changeType === 'ELIMINADO' && entry.fromJob) {
            changeDescription = `Eliminó el trabajo <span class="history-job-name">${entry.fromJob.label}</span>`;
        } else {
            changeDescription = 'Cambio de trabajo';
        }
        
        historyHTML += `
            <div class="history-item">
                <div class="history-item-header">
                    <span class="history-change-type ${changeTypeClass}">${entry.changeType}</span>
                    <span class="history-timestamp">${timeAgo}</span>
                </div>
                <div class="history-details">
                    ${changeDescription}
                </div>
            </div>
        `;
    });
    
    historyList.innerHTML = historyHTML;
}

function getTimeAgo(timestamp) {
    const now = new Date();
    const diff = now - new Date(timestamp);
    const minutes = Math.floor(diff / 60000);
    const hours = Math.floor(diff / 3600000);
    const days = Math.floor(diff / 86400000);
    
    if (days > 0) {
        return `hace ${days} día${days > 1 ? 's' : ''}`;
    } else if (hours > 0) {
        return `hace ${hours} hora${hours > 1 ? 's' : ''}`;
    } else if (minutes > 0) {
        return `hace ${minutes} minuto${minutes > 1 ? 's' : ''}`;
    } else {
        return 'hace un momento';
    }
}

function clearJobHistory() {
    showConfirmDialog(
        'Limpiar Historial',
        '¿Estás seguro de que quieres eliminar todo el historial de cambios?',
        () => {
            jobChangeHistory = [];
            totalJobChanges = 0;
            updateHistoryDisplay();
            showNotification('Historial limpiado correctamente', 'success');
        }
    );
}