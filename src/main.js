// Filtro inteligente para no tronar en la Web si no existe Tauri
let invoke = null;
if (typeof window !== 'undefined' && window.__TAURI__ && window.__TAURI__.core) {
    invoke = window.__TAURI__.core.invoke;
}

async function updateStats() {
  try {
    let stats = { percentage: 0, worked: 0, remaining: 0 };

    if (invoke) {
      // MODO APP: Si Tauri está vivo, le pedimos los datos nativos a Rust
      stats = await invoke('get_journey_stats');
    } else {
      // MODO WEB: Si estamos en navegador, calculamos el avance con el calendario real de Beto
      console.log("Corriendo en modo Web: Calculando métricas en vivo con fechas de Beto...");
      
      const fechaInicio = new Date('2026-05-11'); // Salida real de Beto
      const fechaFin = new Date('2026-11-14');    // Regreso real de Beto
      const hoy = new Date();

      // Cálculo exacto de la diferencia en días
      const totalDias = Math.ceil((fechaFin - fechaInicio) / (1000 * 60 * 60 * 24));
      let transcurridos = Math.ceil((hoy - fechaInicio) / (1000 * 60 * 60 * 24));
      
      // Validaciones quirúrgicas de seguridad para no desbordar los límites (0% a 100%)
      if (transcurridos < 0) transcurridos = 0;
      if (transcurridos > totalDias) transcurridos = totalDias;

      stats.worked = transcurridos;
      stats.remaining = totalDias - transcurridos;
      stats.percentage = Math.round((transcurridos / totalDias) * 100);
    }
    
    // Actualizamos los textos en el HTML con los nodos del proyecto
    if (document.getElementById('pc')) document.getElementById('pc').innerText = stats.percentage + '%';
    if (document.getElementById('work')) document.getElementById('work').innerText = stats.worked;
    if (document.getElementById('rem')) document.getElementById('rem').innerText = stats.remaining;
    
    // Movemos al monito por la pendiente de la pantalla
    const beto = document.getElementById('beto-obj');
    if (beto) {
      const posX = stats.percentage * 0.72; 
      const posY = 8 + (stats.percentage * 1.15);
      
      beto.style.left = posX + '%';
      beto.style.bottom = posY + 'px';
    }
    
  } catch (error) {
    console.error("Error al procesar las estadísticas de la jornada:", error);
  }
}

// Ejecutar cuando el contenido de la página web esté cargado por completo
window.addEventListener('DOMContentLoaded', updateStats);
