/*
  telemetria de partida, analisis de dificultad y sistema de xp.
*/





// tracking de la partida
// guarda en que parte del nivel muere la gente para armar el mapa de calor.
// es el camino viejo: pega al mismo rpc que scr_online_session_end pero leyendo las globals
// de session_ y death_grid en vez de las de online_session_.
// pone en cero el tracking y crea el ds_map de la grilla de muertes.
function scr_init_session_tracking()
{
    global.session_start_time = current_time;
    global.session_furthest_x = 0;
    global.current_level_deaths = 0;
    global.current_level_was_deathless = true;
    
    if (variable_global_exists("death_grid") && ds_exists(global.death_grid, ds_type_map))
        ds_map_clear(global.death_grid);
    else
        global.death_grid = ds_map_create();
    
    scr_debug_log("SESSION TRACKING: Inicializado");
    return 1;
}
// suma una muerte a la celda de la grilla donde estaba el jugador.
function scr_record_death_zone()
{
    if (!instance_exists(obj_mario))
        return 0;
    
    // grilla de 64 pixeles, si fuera mas fina el mapa de calor queda con
    // mil celdas de una muerte cada una
    var cell_x = floor(obj_mario.x / 64);
    var cell_y = floor(obj_mario.y / 64);
    var key = string(cell_x) + "," + string(cell_y);
    
    if (!ds_exists(global.death_grid, ds_type_map))
        global.death_grid = ds_map_create();
    
    var current = ds_map_find_value(global.death_grid, key);
    
    if (is_undefined(current))
        ds_map_add(global.death_grid, key, 1);
    else
        ds_map_replace(global.death_grid, key, current + 1);
    
    if (obj_mario.x > global.session_furthest_x)
        global.session_furthest_x = floor(obj_mario.x);
    
    global.current_level_deaths++;
    global.current_level_was_deathless = false;
    return 1;
}
// pasa la grilla de muertes a json para mandarla. devuelve un array vacio si no hubo ninguna.
function scr_get_death_zones_json()
{
    if (!ds_exists(global.death_grid, ds_type_map))
        return "[]";
    
    if (ds_map_size(global.death_grid) == 0)
        return "[]";
    
    var result = "[";
    var key = ds_map_find_first(global.death_grid);
    var first = true;
    var count = 0;
    
    // tope de 50 celdas, si murio en mas lugares se manda solo lo que entro
    while (!is_undefined(key) && count < 50)
    {
        var deaths = ds_map_find_value(global.death_grid, key);
        var comma_pos = string_pos(",", key);
        var cx = string_copy(key, 1, comma_pos - 1);
        var cy = string_copy(key, comma_pos + 1, string_length(key) - comma_pos);
        
        if (!first)
            result += ",";
        
        result += ("{\"x\":" + cx + ",\"y\":" + cy + ",\"d\":" + string(deaths) + "}");
        first = false;
        count++;
        key = ds_map_find_next(global.death_grid, key);
    }
    
    result += "]";
    return result;
}
// manda la partida al rpc submit_play_session
function scr_send_session_telemetry(arg0)
{
    var level_id = scr_get_current_online_level();
    
    if (level_id <= 0)
        return -1;
    
    if (!global.user_logged_in || global.user_id == "")
        return -1;
    
    // aca si corta por rate, al reves que scr_online_session_end
    if (!scr_rate_limit_check("telemetry"))
    {
        scr_debug_log("TELEMETRY: Rate limited");
        return -1;
    }
    
    var time_played = 0;
    
    if (variable_global_exists("session_start_time"))
        time_played = floor((current_time - global.session_start_time) / 1000);
    
    var p_level = 1;
    
    if (variable_global_exists("user_current_level"))
        p_level = global.user_current_level;
    else if (variable_global_exists("user_level"))
        p_level = global.user_level;
    
    var qx = 0;
    var qy = 0;
    
    if (instance_exists(obj_mario))
    {
        qx = floor(obj_mario.x / 32);
        qy = floor(obj_mario.y / 32);
    }
    
    var fx = 0;
    
    if (variable_global_exists("session_furthest_x"))
        fx = global.session_furthest_x;
    
    var death_json = scr_get_death_zones_json();
    var url = global.supabase_url + "/rest/v1/rpc/submit_play_session";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{";
    body += ("\"p_level_id\":" + string(level_id) + ",");
    body += ("\"p_user_id\":\"" + global.user_id + "\",");
    body += ("\"p_completed\":" + (arg0 ? "true" : "false") + ",");
    body += ("\"p_deaths\":" + string(global.current_level_deaths) + ",");
    body += ("\"p_time_seconds\":" + string(time_played) + ",");
    body += ("\"p_death_zones\":" + death_json + ",");
    body += ("\"p_quit_x\":" + string(qx) + ",");
    body += ("\"p_quit_y\":" + string(qy) + ",");
    body += ("\"p_furthest_x\":" + string(fx) + ",");
    body += ("\"p_player_level\":" + string(p_level));
    body += "}";
    scr_debug_log("SESSION TELEMETRY: " + body);
    var request = http_request(url, "POST", headers, body);
    scr_retry_queue_add(url, "POST", headers, body, "telemetry_lvl" + string(level_id), 3, request);
    ds_map_destroy(headers);
    global.last_telemetry_request = request;
    scr_rate_limit_register("telemetry");
    
    // se limpia la grilla al mandar para que la proxima partida arranque de cero
    if (ds_exists(global.death_grid, ds_type_map))
        ds_map_clear(global.death_grid);
    
    return request;
}
// guarda la x mas lejana a la que llego el jugador. va en el step.
function scr_update_furthest_x()
{
    if (!variable_global_exists("session_furthest_x"))
        return 0;
    
    if (!variable_global_exists("playing_online_level"))
        return 0;
    
    if (!global.playing_online_level)
        return 0;
    
    if (instance_exists(obj_mario))
    {
        if (obj_mario.x > global.session_furthest_x)
            global.session_furthest_x = floor(obj_mario.x);
    }
    
    return 1;
}



// analisis de dificultad
// el calculo pesado lo hace el server con todas las partidas juntas, desde aca solo se pide
// el resultado o se dispara el recalculo.
// trae el analisis ya calculado de un nivel.
function scr_get_level_analysis(arg0)
{
    var url = global.supabase_url + "/rest/v1/level_analysis?level_id=eq." + string(arg0) + "&select=*";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// le pide al server que recalcule la dificultad de un nivel.
function scr_trigger_analysis(arg0)
{
    var url = global.supabase_url + "/rest/v1/rpc/analyze_level_difficulty";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{\"p_level_id\":" + string(arg0) + "}";
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// recalcula todo de una. es pesado, se usa desde el panel de admin.
function scr_analyze_all_levels()
{
    var url = global.supabase_url + "/rest/v1/rpc/analyze_all_levels";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var request = http_request(url, "POST", headers, "{}");
    ds_map_destroy(headers);
    return request;
}
// trae un nivel al azar pero filtrado por el server, no es un random puro.
function scr_get_curated_random(arg0)
{
    var url = global.supabase_url + "/rest/v1/rpc/get_curated_level";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{\"p_difficulty\":\"" + string(arg0) + "\",\"p_min_quality\":50}";
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}





// curva de xp
// cuanta xp cuesta cada nivel y con que color y titulo se muestra.
// cuanta xp falta para pasar de ese nivel al siguiente.
function scr_get_xp_for_level(arg0)
{
    if (arg0 >= 50)
        return 0;
    
    if (arg0 < 10)
        return 300 + (arg0 * 300);
    
    if (arg0 < 20)
        return 3600;
    
    if (arg0 < 25)
        return 5000;
    
    if (arg0 < 30)
        return 6500;
    
    if (arg0 < 40)
        return 10000;
    
    return 20000;
}
// xp acumulada desde cero hasta ese nivel. no confundir con scr_get_xp_for_level, que es solo
// el tramo de un nivel.
function scr_get_total_xp_for_level(arg0)
{
    var total = 0;
    
    for (var i = 1; i < min(arg0, 10); i++)
        total += (300 + (i * 300));
    
    if (arg0 <= 10)
        return total;
    
    total += ((min(arg0, 20) - 10) * 3600);
    
    if (arg0 <= 20)
        return total;
    
    total += ((min(arg0, 25) - 20) * 5000);
    
    if (arg0 <= 25)
        return total;
    
    total += ((min(arg0, 30) - 25) * 6500);
    
    if (arg0 <= 30)
        return total;
    
    total += ((min(arg0, 40) - 30) * 10000);
    
    if (arg0 <= 40)
        return total;
    
    total += ((min(arg0, 50) - 40) * 20000);
    return total;
}
function scr_get_level_color(arg0)
{
    if (arg0 >= 50)
        return make_colour_rgb(255, 0, 255);
    
    if (arg0 >= 40)
        return make_colour_rgb(255, 50, 50);
    
    if (arg0 >= 30)
        return make_colour_rgb(255, 100, 0);
    
    if (arg0 >= 20)
        return make_colour_rgb(180, 50, 255);
    
    if (arg0 >= 10)
        return make_colour_rgb(50, 150, 255);
    
    return make_colour_rgb(100, 255, 100);
}
function scr_get_level_title(arg0)
{
    if (arg0 >= 50)
        return "DIOS";
    
    if (arg0 >= 40)
        return "LEYENDA";
    
    if (arg0 >= 30)
        return "MAESTRO";
    
    if (arg0 >= 20)
        return "EXPERTO";
    
    if (arg0 >= 10)
        return "STEAMHAPPY";
    
    return "SPIRIT";
}
// estima cuanta xp daria el nivel, para mostrarlo antes de jugarlo.
function scr_calculate_preview_xp(arg0, arg1)
{
    var base_xp;
    
    if (arg0 <= 0 || is_undefined(arg0))
    {
        if (arg1 < 10)
            base_xp = 400;
        else if (arg1 < 50)
            base_xp = 600;
        else if (arg1 < 200)
            base_xp = 1200;
        else
            base_xp = 3000;
    }
    else if (arg0 > 50)
    {
        base_xp = 150;
    }
    else if (arg0 > 20)
    {
        base_xp = 300;
    }
    else if (arg0 > 5)
    {
        base_xp = 600;
    }
    else if (arg0 > 1)
    {
        base_xp = 1200;
    }
    else
    {
        base_xp = 3000;
    }
    
    return base_xp;
}



// xp de la partida
// al terminar un nivel el server devuelve cuanta xp se gano y si subiste de nivel.
// el desglose que se dibuja en la barra se arma en el cliente sobre variables de instancia
// de la pantalla de resultados, no sobre globals.
function scr_complete_level_with_xp(arg0, arg1, arg2, arg3 = false)
{
    show_debug_message("========== COMPLETE LEVEL XP ==========");
    show_debug_message("level_id: " + string(arg0));
    show_debug_message("user_attempts: " + string(arg1));
    show_debug_message("was_deathless: " + string(arg2));
    show_debug_message("user_logged_in: " + string(global.user_logged_in));
    show_debug_message("user_id: " + global.user_id);
    
    if (!global.user_logged_in || global.user_id == "")
    {
        show_debug_message("ERROR: Usuario no logueado!");
        return -1;
    }
    
    var url = global.supabase_url + "/rest/v1/rpc/complete_level_with_xp";
    show_debug_message("URL: " + url);
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    
    // armamos el body
    var body = "{";
    body += "\"p_level_id\":" + string(floor(real(arg0))) + ",";
    body += "\"p_user_id\":\"" + global.user_id + "\",";
    body += "\"p_user_attempts\":" + string(floor(real(arg1))) + ",";
    body += "\"p_was_deathless\":" + (arg2 ? "true" : "false");
    // el bono de grupo viaja solo cuando aplica: la funcion vieja de la db no
    // conoce el parametro y un campo de mas la haria fallar
    if (arg3)
        body += ",\"p_group_bonus\":true";
    body += "}";
    
    scr_debug_log("XP BODY: " + body);
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    
    scr_debug_log("XP REQUEST ID: " + string(request));
    return request;
}
// avisa la muerte a la db y resetea el contador local
function scr_register_user_death()
{
    var level_id = scr_get_current_online_level();
    
    if (level_id <= 0)
        return -1;
    
    if (!global.user_logged_in || global.user_id == "")
        return -1;
    
    scr_record_death_zone();
    
    if (!variable_global_exists("current_level_deaths"))
        global.current_level_deaths = 0;
    
    scr_debug_log("USER DEATH REGISTRADA LOCALMENTE: level=" + string(level_id) + " total_deaths=" + string(global.current_level_deaths));
    return 1;
}
// trae xp total y nivel actual del usuario.
function scr_load_my_xp_stats()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/profiles?p_user_id=eq." + global.user_id + "&select=total_xp,current_level";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// parte la xp ganada en los tramos que se dibujan en la barra de resultados, base, bonus por
// pasarlo sin morir, bonus por primera vez y descuento por las muertes acumuladas.
function scr_calculate_xp_components()
{
    show_debug_message("=== CALCULATE XP COMPONENTS ===");
    show_debug_message("old_level: " + string(old_level));
    show_debug_message("user_level: " + string(user_level));
    xp_for_current_level = scr_get_total_xp_for_level(old_level);
    xp_for_next_level = scr_get_xp_for_level(old_level);
    show_debug_message("xp_for_current_level: " + string(xp_for_current_level));
    show_debug_message("xp_for_next_level: " + string(xp_for_next_level));
    // cuanta xp tenia dentro del nivel actual, es donde arranca la barra
    var xp_in_level = user_xp_before - xp_for_current_level;
    
    if (xp_in_level < 0)
        xp_in_level = 0;
    
    show_debug_message("xp_in_level: " + string(xp_in_level));
    
    if (xp_for_next_level > 0)
        target_xp_current = (xp_in_level / xp_for_next_level) * bar_width;
    else
        target_xp_current = 0;
    
    show_debug_message("target_xp_current pixels: " + string(target_xp_current));
    var base_before_bonuses = xp_total_earned;
    
    if (was_deathless)
    {
        // xp_total_earned ya viene con los bonus aplicados, aca se sacan al reves
        // para poder dibujar cada tramo de la barra por separado
        base_before_bonuses = floor(xp_total_earned / 1.5);
        xp_deathless_multiplier = 1.5;
    }
    else
    {
        xp_deathless_multiplier = 1;
    }
    
    if (was_first_clear)
    {
        base_before_bonuses = floor(base_before_bonuses / 1.5);
        xp_first_clear_bonus = floor(base_before_bonuses * 0.5);
    }
    else
    {
        xp_first_clear_bonus = 0;
    }
    
    if (variable_global_exists("current_level_deaths"))
        xp_pity = global.current_level_deaths;
    else
        xp_pity = 0;
    
    xp_base = base_before_bonuses - xp_pity;
    
    // si el descuento por muertes se comio toda la base se muestra la base entera
    if (xp_base < 0)
        xp_base = base_before_bonuses;
    
    show_debug_message("xp_base: " + string(xp_base));
    show_debug_message("xp_pity: " + string(xp_pity));
    show_debug_message("xp_first_clear_bonus: " + string(xp_first_clear_bonus));
    // de aca para abajo cada tramo de xp se pasa a pixeles de la barra
    var pixels_per_xp = 0;
    
    if (xp_for_next_level > 0)
        pixels_per_xp = bar_width / xp_for_next_level;
    
    target_xp_base = xp_base * pixels_per_xp;
    target_xp_pity = xp_pity * pixels_per_xp;
    target_xp_first_clear = xp_first_clear_bonus * pixels_per_xp;
    show_debug_message("pixels_per_xp: " + string(pixels_per_xp));
    show_debug_message("target_xp_base pixels: " + string(target_xp_base));
    
    if (new_level > old_level)
    {
        leveled_up = true;
        levels_gained = new_level - old_level;
        show_debug_message("LEVEL UP! Gained " + string(levels_gained) + " levels");
    }
    
    return 1;
}
// lo mismo pero de otro usuario, para el perfil de los demas
function scr_load_user_xp_stats(arg0)
{
    var url = global.supabase_url + "/rest/v1/profiles?p_user_id=eq." + arg0 + "&select=total_xp,current_level";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
