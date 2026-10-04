/*
  lo que pasa mientras jugas un nivel online. dos sistemas que corren juntos:
  la sesion nueva, que junta todo y lo manda de una al terminar, y el registro viejo
  de jugada, intento y victoria por separado, que es de donde sale el clear rate.
*/





// sesion de partida
// lleva la cuenta de todo lo que pasa mientras jugas: intentos, muertes, hasta donde llegaste
// y si lo terminaste. al final sale todo junto en un solo pedido.
// se espeja en online_session.ini para no perderla si el juego se cierra mal.
// arranca la sesion. si ya hay una abierta del mismo nivel no la pisa, solo suma un intento,
// asi morir y reintentar no cuenta como partida nueva.
// los ini de tracking van al lado del exe y no a la carpeta de guardado. si dos
// copias del juego corren en la misma pc comparten la carpeta de guardado, y el
// que termina primero le pisa el nivel activo al otro: el segundo se quedaba
// con level_id -1 y sin xp
function scr_online_ini_nivel()
{
    return working_directory + "online_level_temp.ini";
}

function scr_online_ini_sesion()
{
    return working_directory + "online_session.ini";
}

function scr_online_session_start(arg0)
{
    if (variable_global_exists("online_session_active") && global.online_session_active && variable_global_exists("online_session_level_id") && global.online_session_level_id == arg0)
    {
        // mismo nivel con la sesion abierta es un reintento, no una partida nueva
        global.online_session_attempts++;
        scr_debug_log("SESSION: Reintento #" + string(global.online_session_attempts) + " para nivel " + string(arg0));
        return 1;
    }
    
    global.online_session_active = true;
    global.online_session_level_id = arg0;
    global.online_session_start_time = current_time;
    global.online_session_deaths = 0;
    global.online_session_attempts = 1;
    global.online_session_furthest_x = 0;
    global.online_session_completed = false;
    global.online_session_spawn_x = 0;
    global.online_session_spawn_y = 0;
    global.online_session_goal_x = 0;
    global.online_session_goal_y = 0;
    global.online_session_room_w = room_width;
    global.online_session_room_h = room_height;
    
    if (variable_global_exists("online_session_death_grid") && ds_exists(global.online_session_death_grid, ds_type_map))
        ds_map_clear(global.online_session_death_grid);
    else
        global.online_session_death_grid = ds_map_create();
    
    // el spawn sale del objeto de inicio, y si no esta se toma donde arranco mario
    if (instance_exists(obj_mario_start_P1))
    {
        global.online_session_spawn_x = floor(obj_mario_start_P1.x);
        global.online_session_spawn_y = floor(obj_mario_start_P1.y);
    }
    else if (instance_exists(obj_mario))
    {
        global.online_session_spawn_x = floor(obj_mario.x);
        global.online_session_spawn_y = floor(obj_mario.y);
    }
    
    scr_online_session_find_goal();
    scr_online_session_read_room_size();
    // se espeja en disco en cada cambio, es lo que deja recuperar la partida
    // si el juego se cierra sin pasar por session_end
    ini_open(scr_online_ini_sesion());
    ini_write_real("session", "active", 1);
    ini_write_real("session", "level_id", arg0);
    ini_write_real("session", "start_time", global.online_session_start_time);
    ini_write_real("session", "deaths", 0);
    ini_write_real("session", "attempts", 1);
    ini_write_real("session", "furthest_x", 0);
    ini_write_real("session", "spawn_x", global.online_session_spawn_x);
    ini_write_real("session", "spawn_y", global.online_session_spawn_y);
    ini_write_real("session", "goal_x", global.online_session_goal_x);
    ini_write_real("session", "goal_y", global.online_session_goal_y);
    ini_write_real("session", "room_w", global.online_session_room_w);
    ini_write_real("session", "room_h", global.online_session_room_h);
    ini_close();
    scr_debug_log("SESSION START: nivel " + string(arg0));
    scr_debug_log("  Spawn: " + string(global.online_session_spawn_x) + "," + string(global.online_session_spawn_y));
    scr_debug_log("  Goal: " + string(global.online_session_goal_x) + "," + string(global.online_session_goal_y));
    scr_debug_log("  Room: " + string(global.online_session_room_w) + "x" + string(global.online_session_room_h));
    return 1;
}
// busca donde termina el nivel probando goalgate, flagpole, goalmario y endboss en ese orden.
// lo necesita el calculo de progreso para saber contra que medir.
function scr_online_session_find_goal()
{
    global.online_session_goal_x = 0;
    global.online_session_goal_y = 0;
    
    // el orden importa: goalgate, flagpole, goalmario y endboss, y corta
    // en el primero que aparezca
    if (instance_exists(obj_goalgate))
    {
        var best_x = 0;
        var best_y = 0;
        
        with (obj_goalgate)
        {
            // si hay varias metas del mismo tipo gana la que este mas a la derecha
            if (x > best_x)
            {
                best_x = x;
                best_y = y;
            }
        }
        
        global.online_session_goal_x = floor(best_x);
        global.online_session_goal_y = floor(best_y);
        return 1;
    }
    
    if (instance_exists(obj_flagpole))
    {
        var best_x = 0;
        var best_y = 0;
        
        with (obj_flagpole)
        {
            if (x > best_x)
            {
                best_x = x;
                best_y = y;
            }
        }
        
        global.online_session_goal_x = floor(best_x);
        global.online_session_goal_y = floor(best_y);
        return 1;
    }
    
    if (instance_exists(obj_goalmario))
    {
        global.online_session_goal_x = floor(obj_goalmario.x);
        global.online_session_goal_y = floor(obj_goalmario.y);
        return 1;
    }
    
    if (instance_exists(obj_endboss_FIX))
    {
        global.online_session_goal_x = floor(obj_endboss_FIX.x);
        global.online_session_goal_y = floor(obj_endboss_FIX.y);
        return 1;
    }
    
    return 0;
}
// guarda el tamano del room, que despues se usa para normalizar las coordenadas de muerte.
function scr_online_session_read_room_size()
{
    var temp_prefix = (os_type == os_android ? "" : working_directory);
    var level_file = temp_prefix + "temp_load.lvl";
    
    if (file_exists(level_file))
    {
        ini_open(level_file);
        global.online_session_room_w = ini_read_real("options", "room_x", room_width);
        global.online_session_room_h = ini_read_real("options", "room_y", room_height);
        ini_close();
    }
    else
    {
        global.online_session_room_w = room_width;
        global.online_session_room_h = room_height;
    }
    
    return 1;
}
// suma una muerte y guarda donde fue.
function scr_online_session_record_death()
{
    if (!variable_global_exists("online_session_active") || !global.online_session_active)
        return 0;
    
    global.online_session_deaths++;
    
    if (instance_exists(obj_mario))
    {
        var cell_x = floor(obj_mario.x / 64);
        var cell_y = floor(obj_mario.y / 64);
        var key = string(cell_x) + "," + string(cell_y);
        
        if (!ds_exists(global.online_session_death_grid, ds_type_map))
            global.online_session_death_grid = ds_map_create();
        
        var current = ds_map_find_value(global.online_session_death_grid, key);
        
        if (is_undefined(current))
            ds_map_add(global.online_session_death_grid, key, 1);
        else
            ds_map_replace(global.online_session_death_grid, key, current + 1);
        
        if (obj_mario.x > global.online_session_furthest_x)
            global.online_session_furthest_x = floor(obj_mario.x);
    }
    
    ini_open(scr_online_ini_sesion());
    ini_write_real("session", "deaths", global.online_session_deaths);
    ini_write_real("session", "attempts", global.online_session_attempts);
    ini_write_real("session", "furthest_x", global.online_session_furthest_x);
    ini_close();
    scr_debug_log("SESSION DEATH #" + string(global.online_session_deaths) + " (attempt " + string(global.online_session_attempts) + ")");
    return 1;
}
// actualiza hasta donde llego el jugador. va en el step.
function scr_online_session_update_progress()
{
    if (!variable_global_exists("online_session_active") || !global.online_session_active)
        return 0;
    
    if (instance_exists(obj_mario))
    {
        if (obj_mario.x > global.online_session_furthest_x)
            global.online_session_furthest_x = floor(obj_mario.x);
    }
    
    return 1;
}
// progreso como avance horizontal entre el spawn y la meta.
function scr_online_session_calc_progress()
{
    var spawn_x = global.online_session_spawn_x;
    var goal_x = global.online_session_goal_x;
    var furthest = global.online_session_furthest_x;
    
    if (goal_x <= spawn_x)
        // sin meta detectada se toma el borde derecho del room como referencia
        goal_x = global.online_session_room_w - 32;
    
    var total_distance = goal_x - spawn_x;
    
    if (total_distance <= 0)
        return 0;
    
    var player_distance = furthest - spawn_x;
    
    if (player_distance <= 0)
        return 0;
    
    var progress = (player_distance / total_distance) * 100;
    progress = clamp(progress, 0, 100);
    return progress;
}
// cierra la sesion y manda todo junto al rpc submit_play_session: intentos, muertes, progreso,
// tiempo y las zonas de muerte en un solo pedido.
function scr_online_session_end(arg0)
{
    if (!variable_global_exists("online_session_active") || !global.online_session_active)
        return -1;
    
    // sin usuario no hay a quien atribuirle la partida, se limpia y se corta
    if (!global.user_logged_in || global.user_id == "")
    {
        scr_online_session_clear();
        return -1;
    }
    
    var level_id = global.online_session_level_id;
    var total_deaths = global.online_session_deaths;
    var total_attempts = global.online_session_attempts;
    var time_played = floor((current_time - global.online_session_start_time) / 1000);
    var furthest_x = global.online_session_furthest_x;
    var completed = arg0;
    var progress;
    
    // si lo termino el progreso es 100 fijo, no se calcula
    if (completed)
        progress = 100;
    else
        progress = scr_online_session_calc_progress();
    
    var death_json = scr_online_session_get_death_json();
    var qx = 0;
    var qy = 0;
    
    // donde abandono, en celdas de 32. si lo termino queda en 0,0
    if (!completed && instance_exists(obj_mario))
    {
        qx = floor(obj_mario.x / 32);
        qy = floor(obj_mario.y / 32);
    }
    
    var p_level = 1;
    
    if (variable_global_exists("user_current_level"))
        p_level = global.user_current_level;
    else if (variable_global_exists("user_level"))
        p_level = global.user_level;
    
    var spawn_x = global.online_session_spawn_x;
    var spawn_y = global.online_session_spawn_y;
    var goal_x = global.online_session_goal_x;
    var goal_y = global.online_session_goal_y;
    var room_w = global.online_session_room_w;
    var room_h = global.online_session_room_h;
    scr_debug_log("========== SESSION END ==========");
    scr_debug_log("Level: " + string(level_id));
    scr_debug_log("Completed: " + string(completed));
    scr_debug_log("Deaths: " + string(total_deaths));
    scr_debug_log("Attempts: " + string(total_attempts));
    scr_debug_log("Time: " + string(time_played) + "s");
    scr_debug_log("Furthest X: " + string(furthest_x));
    scr_debug_log("Progress: " + string(progress) + "%");
    scr_debug_log("Spawn: " + string(spawn_x) + "," + string(spawn_y));
    scr_debug_log("Goal: " + string(goal_x) + "," + string(goal_y));
    scr_debug_log("Room: " + string(room_w) + "x" + string(room_h));
    scr_debug_log("=================================");
    
    // el cierre se manda igual aunque este pasado de rate, si no se pierde
    // la partida entera
    if (!scr_rate_limit_check("telemetry"))
        scr_debug_log("SESSION END: Rate limited, forzando envío...");
    
    var url = global.supabase_url + "/rest/v1/rpc/submit_play_session";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{";
    body += ("\"p_level_id\":" + string(level_id) + ",");
    body += ("\"p_user_id\":\"" + global.user_id + "\",");
    body += ("\"p_completed\":" + (completed ? "true" : "false") + ",");
    body += ("\"p_deaths\":" + string(total_deaths) + ",");
    body += ("\"p_time_seconds\":" + string(time_played) + ",");
    body += ("\"p_death_zones\":" + death_json + ",");
    body += ("\"p_quit_x\":" + string(qx) + ",");
    body += ("\"p_quit_y\":" + string(qy) + ",");
    body += ("\"p_furthest_x\":" + string(furthest_x) + ",");
    body += ("\"p_player_level\":" + string(p_level) + ",");
    body += ("\"p_attempts\":" + string(total_attempts) + ",");
    body += ("\"p_spawn_x\":" + string(spawn_x) + ",");
    body += ("\"p_spawn_y\":" + string(spawn_y) + ",");
    body += ("\"p_goal_x\":" + string(goal_x) + ",");
    body += ("\"p_goal_y\":" + string(goal_y) + ",");
    body += ("\"p_room_width\":" + string(room_w) + ",");
    body += ("\"p_room_height\":" + string(room_h) + ",");
    body += ("\"p_progress_percent\":" + string(progress));
    body += "}";
    var request = http_request(url, "POST", headers, body);
    // la victoria se reintenta 5 veces y el abandono 3
    scr_retry_queue_add(url, "POST", headers, body, "session_lvl" + string(level_id) + (completed ? "_WIN" : "_QUIT"), completed ? 5 : 3, request);
    ds_map_destroy(headers);
    global.last_telemetry_request = request;
    scr_rate_limit_register("telemetry");
    
    if (completed)
        // la victoria se registra aparte, va a otra tabla
        scr_register_level_victory();
    
    scr_online_session_clear();
    return request;
}
// arma el json de las zonas de muerte con las coordenadas ya normalizadas.
function scr_online_session_get_death_json()
{
    if (!variable_global_exists("online_session_death_grid") || !ds_exists(global.online_session_death_grid, ds_type_map))
        return "[]";
    
    if (ds_map_size(global.online_session_death_grid) == 0)
        return "[]";
    
    var result = "[";
    var key = ds_map_find_first(global.online_session_death_grid);
    var first = true;
    var count = 0;
    
    while (!is_undefined(key) && count < 50)
    {
        var deaths = ds_map_find_value(global.online_session_death_grid, key);
        var comma_pos = string_pos(",", key);
        var cx = string_copy(key, 1, comma_pos - 1);
        var cy = string_copy(key, comma_pos + 1, string_length(key) - comma_pos);
        
        if (!first)
            result += ",";
        
        result += ("{\"x\":" + cx + ",\"y\":" + cy + ",\"d\":" + string(deaths) + "}");
        first = false;
        count++;
        key = ds_map_find_next(global.online_session_death_grid, key);
    }
    
    result += "]";
    return result;
}
// limpia la sesion y borra el ini, para que no se recupere despues.
function scr_online_session_clear()
{
    global.online_session_active = false;
    global.online_session_level_id = -1;
    global.online_session_deaths = 0;
    global.online_session_attempts = 0;
    global.online_session_furthest_x = 0;
    global.online_session_completed = false;
    global.online_session_spawn_x = 0;
    global.online_session_spawn_y = 0;
    global.online_session_goal_x = 0;
    global.online_session_goal_y = 0;
    global.online_session_room_w = 0;
    global.online_session_room_h = 0;
    
    if (variable_global_exists("online_session_death_grid") && ds_exists(global.online_session_death_grid, ds_type_map))
        ds_map_clear(global.online_session_death_grid);
    
    ini_open(scr_online_ini_sesion());
    ini_write_real("session", "active", 0);
    ini_close();
    global.playing_online_level = false;
    global.current_online_level_id = -1;
    global.online_level_attempt_registered = false;
    global.online_level_play_registered = false;
    
    // tambien apaga el tracking viejo, que lleva su propio archivo
    if (file_exists(scr_online_ini_nivel()))
    {
        ini_open(scr_online_ini_nivel());
        ini_write_real("tracking", "active", 0);
        ini_write_real("tracking", "level_id", -1);
        ini_close();
    }
    
    scr_debug_log("SESSION CLEARED");
    return 1;
}
function scr_online_session_is_active()
{
    if (!variable_global_exists("online_session_active"))
        return false;
    
    return global.online_session_active;
}
// levanta la sesion que quedo escrita en el ini cuando el juego se cerro sin cerrarla, asi esa
// partida no se pierde del todo.
function scr_online_session_recover()
{
    if (!file_exists(scr_online_ini_sesion()))
        return 0;
    
    ini_open(scr_online_ini_sesion());
    var was_active = ini_read_real("session", "active", 0);
    var level_id = ini_read_real("session", "level_id", -1);
    ini_close();
    
    if (was_active && level_id > 0)
    {
        scr_debug_log("SESSION RECOVERY: Sesión huérfana encontrada para nivel " + string(level_id));
        scr_online_session_clear();
    }
    
    return 1;
}





// registro de jugadas y clear rate
// esto es aparte de la sesion y mas viejo: marca la jugada, el intento y la victoria cada uno
// por su lado. de esos numeros sale el clear rate que se muestra en la tarjeta.
// pone en cero los flags de jugada, intento y victoria del nivel actual.
function scr_init_online_level_tracking()
{
    if (!variable_global_exists("playing_online_level"))
        global.playing_online_level = false;
    
    if (!variable_global_exists("current_online_level_id"))
        global.current_online_level_id = -1;
    
    if (!variable_global_exists("online_level_attempt_registered"))
        global.online_level_attempt_registered = false;
    
    if (!variable_global_exists("online_level_play_registered"))
        global.online_level_play_registered = false;
    
    return 1;
}
// marca que se entro a un nivel online y registra la jugada unica si todavia no se registro.
function scr_start_online_level(arg0)
{
    show_debug_message("========== START ONLINE LEVEL ==========");
    show_debug_message("level_id recibido: " + string(arg0));
    scr_init_online_level_tracking();
    scr_set_current_online_level(arg0);
    scr_online_session_start(arg0);
    global.current_level_deaths = 0;
    global.current_level_was_deathless = true;
    show_debug_message("Llamando scr_register_level_play...");
    var play_req = scr_register_level_play(arg0);
    show_debug_message("Request ID de play: " + string(play_req));
    
    if (global.user_logged_in && global.user_id != "" && !global.online_level_play_registered)
    {
        show_debug_message("Registrando unique play...");
        scr_register_unique_play(arg0);
        global.online_level_play_registered = true;
    }
    
    show_debug_message("=========================================");
    return 1;
}
// cierra el tracking al salir del nivel.
function scr_end_online_level()
{
    if (file_exists(scr_online_ini_nivel()))
    {
        ini_open(scr_online_ini_nivel());
        ini_write_real("tracking", "active", 0);
        ini_write_real("tracking", "level_id", -1);
        ini_close();
    }
    
    global.playing_online_level = false;
    global.current_online_level_id = -1;
    global.online_level_attempt_registered = false;
    global.online_level_play_registered = false;
    
    if (variable_global_exists("death_grid") && ds_exists(global.death_grid, ds_type_map))
        ds_map_clear(global.death_grid);
    
    scr_debug_log("END ONLINE LEVEL - Tracking limpiado");
    return 1;
}
// borra el nivel actual de las globals, para volver al menu sin dejar basura.
function scr_clear_current_online_level()
{
    scr_end_online_level();
    return 1;
}
// cuenta al jugador una sola vez por nivel. es lo que separa jugadores unicos de partidas
// totales en las estadisticas.
function scr_register_unique_play(arg0)
{
    if (!global.user_logged_in || global.user_id == "")
        return -1;
    
    if (global.online_level_play_registered)
        return -1;
    
    global.online_level_play_registered = true;
    var url = global.supabase_url + "/rest/v1/rpc/register_unique_play";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_level_id: int64(arg0),
        p_user_id: global.user_id
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    scr_debug_log("UNIQUE PLAY: Registrando jugador único para nivel " + string(arg0));
    return request;
}
// suma un intento. es el denominador del clear rate.
function scr_register_level_attempt()
{
    if (!scr_online_session_is_active())
        return -1;
    
    global.online_session_attempts++;
    ini_open(scr_online_ini_sesion());
    ini_write_real("session", "attempts", global.online_session_attempts);
    ini_close();
    scr_debug_log("REINTENTO CONTABILIZADO: Total = " + string(global.online_session_attempts));
    return 1;
}
// suma una victoria. es el numerador del clear rate.
function scr_register_level_victory()
{
    var level_id = scr_get_current_online_level();
    
    if (level_id <= 0)
    {
        scr_debug_log("VICTORY ERROR: No hay nivel online activo");
        return -1;
    }
    
    if (!global.user_logged_in || global.user_id == "")
    {
        scr_debug_log("VICTORY ERROR: Usuario no logueado");
        return -1;
    }
    
    if (!scr_rate_limit_check("victory"))
    {
        scr_debug_log("VICTORY: Rate limited");
        return -1;
    }
    
    scr_debug_log("========== VICTORY ==========");
    scr_debug_log("VICTORY: level_id = " + string(level_id));
    scr_debug_log("VICTORY: user_id = " + global.user_id);
    var url = global.supabase_url + "/rest/v1/rpc/register_level_victory";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{\"p_level_id\":" + string(level_id) + ",\"p_user_id\":\"" + global.user_id + "\"}";
    scr_debug_log("VICTORY: Body = " + body);
    var request = http_request(url, "POST", headers, body);
    // 5 reintentos, es de las pocas cosas que no se puede perder
    scr_retry_queue_add(url, "POST", headers, body, "victory_lvl" + string(level_id), 5, request);
    ds_map_destroy(headers);
    global.last_victory_request = request;
    scr_rate_limit_register("victory");
    scr_debug_log("VICTORY: Request ID = " + string(request));
    scr_debug_log("=============================");
    return request;
}
// victorias sobre intentos, en porcentaje.
function scr_get_clear_rate(arg0, arg1)
{
    if (arg0 <= 0)
        return 0;
    
    var rate = (arg1 / arg0) * 100;
    return rate;
}
function scr_get_clear_rate_color(arg0)
{
    arg0 = clamp(arg0, 0, 100);
    var r, g, b;
    
    if (arg0 <= 50)
    {
        var t = arg0 / 50;
        r = 255;
        g = 50 + (150 * t);
        b = 50;
    }
    else
    {
        var t = (arg0 - 50) / 50;
        r = 255 - (205 * t);
        g = 200 + (20 * t);
        b = 50 + (100 * t);
    }
    
    return make_colour_rgb(r, g, b);
}
// formatea el clear rate para mostrarlo. abajo de 0.01 muestra el simbolo de menor en vez de
// redondear a 0%, para que no parezca que nadie lo paso nunca.
function scr_format_clear_rate(arg0)
{
    if (arg0 < 0)
        return "0%";
    
    if (arg0 == 0)
        return "0%";
    
    if (arg0 > 0 && arg0 < 0.01)
        return "<0.01%";
    
    if (arg0 >= 100)
        return "100%";
    
    var formatted;
    
    if (arg0 >= 10)
        formatted = string_format(arg0, 0, 1) + "%";
    else if (arg0 >= 1)
        formatted = string_format(arg0, 0, 2) + "%";
    else
        formatted = string_format(arg0, 0, 2) + "%";
    
    return formatted;
}
function scr_set_current_online_level(arg0)
{
    ini_open(scr_online_ini_nivel());
    ini_write_real("tracking", "level_id", arg0);
    ini_write_real("tracking", "active", 1);
    ini_close();
    scr_init_online_level_tracking();
    global.playing_online_level = true;
    global.current_online_level_id = arg0;
    // copia en memoria para la victoria: el disco lo puede pisar la otra copia
    global.party_win_level_id = arg0;
    global.online_level_attempt_registered = false;
    show_debug_message("SET ONLINE LEVEL: " + string(arg0));
    return 1;
}
function scr_get_current_online_level()
{
    ini_open(scr_online_ini_nivel());
    var active = ini_read_real("tracking", "active", 0);
    var level_id = ini_read_real("tracking", "level_id", -1);
    ini_close();
    
    if (active == 1 && level_id > 0)
        return level_id;
    
    return -1;
}
