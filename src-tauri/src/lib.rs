use chrono::{NaiveDate, Local};
use serde::Serialize;

#[derive(Serialize)]
pub struct Stats {
    pub percentage: i32,
    pub worked: i64,
    pub remaining: i64,
}

#[tauri::command]
fn get_journey_stats() -> Stats {
    // FECHAS: 11 Mayo al 14 Noviembre 2026
    let salida = NaiveDate::from_ymd_opt(2026, 5, 11).expect("Err");
    let regreso = NaiveDate::from_ymd_opt(2026, 11, 14).expect("Err");
    let hoy = Local::now().date_naive();

    let total = regreso.signed_duration_since(salida).num_days();
    let transcurridos = hoy.signed_duration_since(salida).num_days().max(0).min(total);
    let faltantes = regreso.signed_duration_since(hoy).num_days().max(0);
    
    // Si hoy es 14 de Mayo, debería dar aprox 1.6%
    let porcentaje = (transcurridos as f64 / total as f64) * 100.0;

    Stats {
        percentage: porcentaje.round() as i32,
        worked: transcurridos,
        remaining: faltantes,
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        // ESTO ES CLAVE: Aquí se registra la función para que el HTML la encuentre
        .invoke_handler(tauri::generate_handler![get_journey_stats])
        .run(tauri::generate_context!())
        .expect("error");
}