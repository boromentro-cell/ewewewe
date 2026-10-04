// config
// urls de supabase y de los workers, la anonkey y el estado del usuario
// deja armadas todas las globals del online de una sola pasada: urls, key, datos del usuario
// en blanco y los request id en -1. tambien arranca los rate limits y la cola de reintentos.
function scr_supabase_init()
{
    global.supabase_url = "https://hgjbmbvfmytmfdxrftks.supabase.co";
    global.supabase_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhnamJtYnZmbXl0bWZkeHJmdGtzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc5NzgwODYsImV4cCI6MjA4MzU1NDA4Nn0.hhiQVPcAHRIf7mFjC1_RAcj8328RYCnD9-SYqcT9tfw";
    global.r2_levels_url = "https://cdn.sm4j.pp.ua";
    global.r2_thumbnails_url = "https://thumb.sm4j.pp.ua";
    global.r2_textures_url = "https://texcdn.sm4j.pp.ua";
    global.r2_profile_url = "https://pic.sm4jhub.pp.ua";
    global.r2_worlds_url = "https://cdnworlds.sm4jhub.pp.ua";
    global.worker_upload_url = "https://sm4j-upload.boromentro.workers.dev";
    global.worker_profile_url = "https://profiles.sm4jhub.pp.ua";
    global.worker_worlds_url = "https://worlds.sm4jhub.pp.ua";
    global.worker_worlds_cache_url = "https://worldscache.sm4jhub.pp.ua";
    global.worker_telegram_url = "https://sm4j.pp.ua";
    global.worker_textures_bridge_url = "https://tex.sm4j.pp.ua";
    global.cloudinary_cloud_name = "doagskcjw";
    global.cloudinary_upload_preset = "sm4jprofiles";
    global.r2_bucket_levels = "sm4j-levels";
    global.r2_bucket_thumbnails = "sm4j-thumbnails";
    global.user_token = "";
    global.user_refresh_token = "";
    global.user_id = "";
    global.user_name = "";
    global.user_logged_in = 0;
    global.session_loaded = 0;
    global.last_login_email = "";
    global.last_login_pass = "";
    global.user_profile_image = "";
    global.user_bio = "";
    global.user_discord_linked = 0;
    global.request_refresh = -1;
    global.request_login = -1;
    global.request_register = -1;
    global.request_levels = -1;
    global.request_upload = -1;
    global.request_like = -1;
    global.request_check_discord = -1;
    global.request_upload_world = -1;
    global.request_worlds_list = -1;
    global.request_world_download = -1;
    global.playing_online_level = 0;
    global.current_online_level_id = -1;
    global.online_level_attempt_registered = 0;
    global.online_level_play_registered = 0;
    global.delete_world_card_id = -1;
    global.cold_storage_ids = ds_list_create();
	global.catbox_userhash = "61b2608df8b0c7c33454ab9f7";
    global.last_attempt_request = -1;
    global.last_play_request = -1;
    global.last_victory_request = -1;
    global.last_telemetry_request = -1;
    scr_rate_limit_init();
    scr_retry_queue_init();
    ds_map_add(global.rate_cooldowns, "telemetry", 2000);
    // si el juego se cerro con una partida abierta, aca se levanta de nuevo
    scr_online_session_recover();
    return 1;
}





// cola de reintentos
// cuando una peticion importante puede fallar se encola una copia antes de mandarla.
// si la original vuelve bien la copia se tira, y si falla la cola la reintenta sola con
// backoff, de a una por vez para no llenar la red.
// cola vacia, sin request activo y tope de 20 entradas para que no crezca al infinito.
function scr_retry_queue_init()
{
    global.retry_queue = ds_list_create();
    global.retry_active_request = -1;
    global.retry_active_index = -1;
    global.retry_max_queue_size = 20;
    return 1;
}
// encola una copia de la peticion pero todavia no la manda. queda marcada como esperando hasta
// que se sepa como salio la original.
function scr_retry_queue_add(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
{
    if (!variable_global_exists("retry_queue"))
        scr_retry_queue_init();
    
    // con la cola llena se descarta, se pierde el reintento pero no se come la memoria
    if (ds_list_size(global.retry_queue) >= global.retry_max_queue_size)
    {
        scr_debug_log("RETRY QUEUE: Cola llena, descartando: " + arg4);
        return -1;
    }
    
    // el ds_map de headers lo destruye el que llamo apenas manda, asi que
    // aca se guarda serializado y se rearma al reintentar
    var headers_json = "{";
    var key = ds_map_find_first(arg2);
    var first = true;
    
    while (!is_undefined(key))
    {
        var val = ds_map_find_value(arg2, key);
        
        if (!first)
            headers_json += ",";
        
        headers_json += ("\"" + string(key) + "\":\"" + string(val) + "\"");
        first = false;
        key = ds_map_find_next(arg2, key);
    }
    
    headers_json += "}";
    var entry = ds_map_create();
    ds_map_add(entry, "url", arg0);
    ds_map_add(entry, "method", arg1);
    ds_map_add(entry, "headers_json", headers_json);
    ds_map_add(entry, "body", arg3);
    ds_map_add(entry, "tag", arg4);
    ds_map_add(entry, "retry_count", 0);
    ds_map_add(entry, "max_retries", arg5);
    ds_map_add(entry, "next_retry_time", 0);
    ds_map_add(entry, "backoff_ms", 3000);
    ds_map_add(entry, "original_request_id", arg6);
    // hasta saber como salio la peticion original esta entrada se saltea
    ds_map_add(entry, "waiting_for_original", true);
    ds_list_add(global.retry_queue, entry);
    scr_debug_log("RETRY QUEUE: Encolado '" + arg4 + "' esperando resultado de request #" + string(arg6));
    return 1;
}
// la original volvio bien, se saca la copia de la cola y no se reintenta nada.
function scr_retry_queue_original_succeeded(arg0)
{
    if (!variable_global_exists("retry_queue"))
        return 0;
    
    var i = ds_list_size(global.retry_queue) - 1;
    
    while (i >= 0)
    {
        var entry = ds_list_find_value(global.retry_queue, i);
        
        if (!ds_exists(entry, ds_type_map))
        {
            ds_list_delete(global.retry_queue, i);
        }
        else
        {
            var orig_id = ds_map_find_value(entry, "original_request_id");
            
            if (orig_id == arg0)
            {
                var tag = ds_map_find_value(entry, "tag");
                scr_debug_log("RETRY CANCELLED: '" + tag + "' - original succeeded");
                ds_map_destroy(entry);
                ds_list_delete(global.retry_queue, i);
                return 1;
            }
        }
        
        i--;
    }
    
    return 0;
}
// la original fallo, la copia queda habilitada y a partir de ahi la maneja la cola sola.
function scr_retry_queue_original_failed(arg0)
{
    if (!variable_global_exists("retry_queue"))
        return 0;
    
    for (var i = 0; i < ds_list_size(global.retry_queue); i++)
    {
        var entry = ds_list_find_value(global.retry_queue, i);
        
        if (!ds_exists(entry, ds_type_map))
            continue;
        
        var orig_id = ds_map_find_value(entry, "original_request_id");
        
        if (orig_id == arg0)
        {
            var tag = ds_map_find_value(entry, "tag");
            ds_map_replace(entry, "waiting_for_original", false);
            ds_map_replace(entry, "next_retry_time", current_time + 3000);
            scr_debug_log("RETRY ACTIVATED: '" + tag + "' - original failed, retry in 3s");
            return 1;
        }
    }
    
    return 0;
}
// va en el step. lanza un reintento por vez y si ya hay uno en vuelo no toca nada, asi nunca
// hay dos peticiones de la cola dando vueltas juntas.
function scr_retry_queue_update()
{
    if (!variable_global_exists("retry_queue"))
        return 0;
    
    if (ds_list_size(global.retry_queue) == 0)
        return 0;
    
    // una sola peticion de la cola en vuelo por vez
    if (global.retry_active_request != -1)
        return 0;
    
    var now = current_time;
    
    for (var i = 0; i < ds_list_size(global.retry_queue); i++)
    {
        var entry = ds_list_find_value(global.retry_queue, i);
        
        if (!ds_exists(entry, ds_type_map))
        {
            ds_list_delete(global.retry_queue, i);
            i--;
        }
        else
        {
            var waiting = ds_map_find_value(entry, "waiting_for_original");
            
            // rama vacia a proposito, sigue esperando el resultado de la original
            if (waiting)
            {
            }
            else
            {
                var next_time = ds_map_find_value(entry, "next_retry_time");
                
                if (now >= next_time)
                {
                    var url = ds_map_find_value(entry, "url");
                    var _method = ds_map_find_value(entry, "method"); // ¡Cambiado a _method!
                    var headers_json = ds_map_find_value(entry, "headers_json");
                    var body = ds_map_find_value(entry, "body");
                    var tag = ds_map_find_value(entry, "tag");
                    var retry_count = ds_map_find_value(entry, "retry_count");
                    var headers = scr_retry_parse_headers(headers_json);
                    
                    if (ds_map_exists(headers, "Authorization"))
                    {
                        var auth_val = ds_map_find_value(headers, "Authorization");
                        
                        // el token pudo vencer desde que se encolo, se pisa con el actual salvo
                        // que la peticion vaya con la key anonima
                        if (auth_val != ("Bearer " + global.supabase_key) && global.user_token != "")
                            ds_map_replace(headers, "Authorization", "Bearer " + global.user_token);
                    }
                    
                    scr_debug_log("RETRY #" + string(retry_count + 1) + ": " + tag);
                    global.retry_active_request = http_request(url, _method, headers, body); // ¡Cambiado a _method!
                    // se guarda el indice para saber a quien corresponde la respuesta
                    global.retry_active_index = i;
                    ds_map_destroy(headers);
                    ds_map_replace(entry, "retry_count", retry_count + 1);
                    var backoff = ds_map_find_value(entry, "backoff_ms");
                    // se duplica en cada intento y se planta en 30s
                    ds_map_replace(entry, "backoff_ms", min(backoff * 2, 30000));
                    break;  
                }
            }
        }
    }
    
    return 1;
}
// tiene que llamarse al principio del async http. devuelve true cuando el evento era de un
// reintento, para que el que llama corte y no lo procese como si fuera su peticion.
function scr_retry_queue_handle_async(arg0)
{
    if (!variable_global_exists("retry_queue"))
        return false;
    
    if (global.retry_active_request == -1)
        return false;
    
    var request_id = ds_map_find_value(arg0, "id");
    
    if (request_id != global.retry_active_request)
        return false;
    
    var status = ds_map_find_value(arg0, "status");
    
    // 1 es en curso, todavia no hay nada que decidir
    if (status == 1)
        return true;
    
    global.retry_active_request = -1;
    var idx = global.retry_active_index;
    global.retry_active_index = -1;
    
    if (idx < 0 || idx >= ds_list_size(global.retry_queue))
        return true;
    
    var entry = ds_list_find_value(global.retry_queue, idx);
    
    if (!ds_exists(entry, ds_type_map))
        return true;
    
    var tag = ds_map_find_value(entry, "tag");
    var retry_count = ds_map_find_value(entry, "retry_count");
    var max_retries = ds_map_find_value(entry, "max_retries");
    
    // salio bien, se saca de la cola
    if (status == 0)
    {
        scr_debug_log("RETRY SUCCESS: " + tag + " (intento #" + string(retry_count) + ")");
        ds_map_destroy(entry);
        ds_list_delete(global.retry_queue, idx);
    }
    // se agotaron los intentos, esa peticion se pierde
    else if (retry_count >= max_retries)
    {
        scr_debug_log("RETRY FAILED: " + tag + " después de " + string(max_retries) + " intentos");
        ds_map_destroy(entry);
        ds_list_delete(global.retry_queue, idx);
    }
    else
    {
        var backoff = ds_map_find_value(entry, "backoff_ms");
        // queda encolada con la hora del proximo intento, update la agarra sola
        ds_map_replace(entry, "next_retry_time", current_time + backoff);
        scr_debug_log("RETRY SCHEDULED: " + tag + " en " + string(backoff) + "ms (" + string(retry_count) + "/" + string(max_retries) + ")");
    }
    
    return true;
}
// rearma el ds_map de headers a partir del texto que dejo scr_retry_queue_add.
// va de a pares de comillas, no es un parser de json y no banca valores con comillas adentro.
function scr_retry_parse_headers(arg0)
{
    var headers = ds_map_create();
    var temp = arg0;
    
    // saca las llaves de los bordes y despues va de a cuatro comillas:
    // las dos de la clave y las dos del valor
    if (string_char_at(temp, 1) == "{")
        temp = string_copy(temp, 2, string_length(temp) - 2);
    
    while (string_length(temp) > 0)
    {
        var q1 = string_pos("\"", temp);
        
        if (q1 == 0)
            break;
        
        temp = string_copy(temp, q1 + 1, string_length(temp) - q1);
        var q2 = string_pos("\"", temp);
        
        if (q2 == 0)
            break;
        
        var h_key = string_copy(temp, 1, q2 - 1);
        temp = string_copy(temp, q2 + 1, string_length(temp) - q2);
        var q3 = string_pos("\"", temp);
        
        if (q3 == 0)
            break;
        
        temp = string_copy(temp, q3 + 1, string_length(temp) - q3);
        var q4 = string_pos("\"", temp);
        
        if (q4 == 0)
        {
            ds_map_add(headers, h_key, temp);
            temp = "";
        }
        else
        {
            var h_val = string_copy(temp, 1, q4 - 1);
            temp = string_copy(temp, q4 + 1, string_length(temp) - q4);
            ds_map_add(headers, h_key, h_val);
        }
    }
    
    return headers;
}
// manda la peticion y la encola en el mismo paso, para no tener que escribir las dos cosas.
function scr_make_retryable(arg0, arg1, arg2, arg3, arg4)
{
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    
    if (global.user_logged_in && global.user_token != "")
        ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    else
        ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    
    var request = http_request(arg0, arg1, headers, arg2);
    scr_retry_queue_add(arg0, arg1, headers, arg2, arg3, arg4, 0);
    ds_map_destroy(headers);
    return request;
}





// rate limits
// cooldown minimo entre acciones repetidas del mismo tipo, para no spamear el server desde
// el cliente cuando alguien clickea como loco.
// cooldown en ms de cada tipo de accion.
function scr_rate_limit_init()
{
    global.rate_limits = ds_map_create();
    global.rate_cooldowns = ds_map_create();
    ds_map_add(global.rate_cooldowns, "like", 2000);
    ds_map_add(global.rate_cooldowns, "attempt", 3000);
    ds_map_add(global.rate_cooldowns, "victory", 5000);
    ds_map_add(global.rate_cooldowns, "play", 2000);
    ds_map_add(global.rate_cooldowns, "comment", 10000);
    ds_map_add(global.rate_cooldowns, "download", 2000);
    ds_map_add(global.rate_cooldowns, "search", 1500);
    ds_map_add(global.rate_cooldowns, "like_texture", 2000);
    ds_map_add(global.rate_cooldowns, "upload", 30000);
    ds_map_add(global.rate_cooldowns, "refresh", 5000);
    return 1;
}
// si la accion no tiene cooldown definido pasa siempre.
function scr_rate_limit_check(arg0)
{
    if (!variable_global_exists("rate_limits"))
        scr_rate_limit_init();
    
    var now = current_time;
    var last_time = ds_map_find_value(global.rate_limits, arg0);
    
    if (is_undefined(last_time))
        return true;
    
    var cooldown = ds_map_find_value(global.rate_cooldowns, arg0);
    
    if (is_undefined(cooldown))
        cooldown = 1000;
    
    return (now - last_time) >= cooldown;
}
function scr_rate_limit_register(arg0)
{
    if (!variable_global_exists("rate_limits"))
        scr_rate_limit_init();
    
    if (ds_map_exists(global.rate_limits, arg0))
        ds_map_replace(global.rate_limits, arg0, current_time);
    else
        ds_map_add(global.rate_limits, arg0, current_time);
    
    return 1;
}
// cuantos ms faltan para poder repetir la accion, para mostrarlo en pantalla.
function scr_rate_limit_remaining(arg0)
{
    if (!variable_global_exists("rate_limits"))
        return 0;
    
    var now = current_time;
    var last_time = ds_map_find_value(global.rate_limits, arg0);
    
    if (is_undefined(last_time))
        return 0;
    
    var cooldown = ds_map_find_value(global.rate_cooldowns, arg0);
    
    if (is_undefined(cooldown))
        cooldown = 1000;
    
    var elapsed = now - last_time;
    
    if (elapsed >= cooldown)
        return 0;
    
    return cooldown - elapsed;
}


// lectura de json
// convierte un array json en una ds_list de ds_map.
function scr_json_parse_array(arg0)
{
    var _result_list = ds_list_create();
    
    if (is_undefined(arg0) || arg0 == "" || arg0 == "[]" || string_length(arg0) < 3)
        return _result_list;
    
    // aca si sirve json_parse porque viene el array entero, para leer un campo
    // suelto de un texto a medio armar no
    var _array = json_parse(arg0);
    var _size = array_length(_array);
    
    for (var i = 0; i < _size; i++)
    {
        var _struct = _array[i];
        var _map = ds_map_create();
        var _names = variable_struct_get_names(_struct);
        var _names_len = array_length(_names);
        
        for (var j = 0; j < _names_len; j++)
        {
            var _key = _names[j];
            var _val = variable_struct_get(_struct, _key);
            
            // lo anidado se guarda como texto y se vuelve a parsear cuando haga falta,
            // el ds_map no soporta arrays adentro. se serializa con json_stringify asi
            // queda json valido siempre: el catalogo estatico trae custom_objects_used
            // como array de verdad y el rpc lo trae como texto, y por los dos caminos
            // termina siendo un string que json_parse acepta
            if (is_array(_val) || is_struct(_val))
            {
                _val = json_stringify(_val);
            }
            else if (!is_undefined(_val))
            {
                _val = string(_val);
            }
            
            ds_map_add(_map, _key, _val);
        }
        
        // cada map de la lista lo tiene que destruir el que llamo
        ds_list_add(_result_list, _map);
    }
    
    return _result_list;
}
// saca el valor de una clave llevando la cuenta de corchetes y llaves, por eso banca objetos y
// arrays anidados. la clave se busca por texto, si aparece dentro de un string se confunde.
function scr_json_get_value(arg0, arg1)
{
    var _search = "\"" + arg1 + "\":";
    var _pos = string_pos(_search, arg0);
    
    if (_pos == 0)
        return undefined;
    
    var _start = _pos + string_length(_search);
    var _char = string_char_at(arg0, _start);
    
    // si arranca con comilla es un string y se corta en la comilla que cierra,
    // sin ponerse a contar llaves
    if (_char == "\"")
    {
        _start++;
        _end_pos = _start;
        
        while (string_char_at(arg0, _end_pos) != "\"" && _end_pos < string_length(arg0))
            _end_pos++;
        
        return string_copy(arg0, _start, _end_pos - _start);
    }
    
    var _end_pos = _start;
    var _brackets = 0;
    var _braces = 0;
    var _in_quote = false;
    
    while (_end_pos <= string_length(arg0))
    {
        var _c = string_char_at(arg0, _end_pos);
        
        // dentro de comillas no se cuentan corchetes ni llaves, si no un texto
        // con simbolos rompe el conteo
        if (_c == "\"")
            _in_quote = !_in_quote;
        
        if (!_in_quote)
        {
            if (_c == "[")
                _brackets++;
            
            if (_c == "]")
                _brackets--;
            
            if (_c == "{")
                _braces++;
            
            if (_c == "}")
                _braces--;
            
            if (_brackets == 0 && _braces == 0)
            {
                if (_c == "," || _c == "}" || _c == "]")
                    break;
            }
        }
        
        _end_pos++;
    }
    
    var _value = string_copy(arg0, _start, _end_pos - _start);
    
    // a los arrays no se les sacan los espacios, adentro puede haber texto
    // con espacios de verdad
    if (string_pos("[", _value) == 0)
        _value = string_replace_all(_value, " ", "");
    
    return _value;
}



// cache
// guarda listados enteros en un archivo para poder mostrar algo mientras se baja lo nuevo.
// guarda el json en un archivo y la fecha en cache_info.ini para saber si esta viejo.
function scr_save_list_cache(arg0, arg1)
{
    var file_name = "cache_" + arg0 + ".json";
    var file = file_text_open_write(file_name);
    file_text_write_string(file, arg1);
    file_text_close(file);
    ini_open("cache_info.ini");
    ini_write_real("fechas", arg0, date_current_datetime());
    ini_close();
    scr_debug_log("CACHÉ GUARDADO: " + arg0);
}
// devuelve el json cacheado, o string vacio si nunca se guardo.
function scr_load_list_cache(arg0)
{
    var file_name = "cache_" + arg0 + ".json";
    
    if (file_exists(file_name))
    {
        var file = file_text_open_read(file_name);
        var json_data = "";
        
        while (!file_text_eof(file))
        {
            json_data += file_text_read_string(file);
            file_text_readln(file);
        }
        
        file_text_close(file);
        scr_debug_log("CACHÉ CARGADO: " + arg0);
        return json_data;
    }
    
    return "";
}




// urls de r2
// arma la url de descarga de un nivel. devuelve exactamente lo mismo que scr_r2_get_level_url,
// quedaron las dos y cada una se usa desde un lado distinto.
function scr_r2_get_url(arg0)
{
    return global.r2_levels_url + "/" + string(arg0);
}
// alta de usuario contra auth/v1/signup. la respuesta cae en global.request_register.
function scr_supabase_register(arg0, arg1, arg2)
{
    var _url = global.supabase_url + "/auth/v1/signup";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{\"email\":\"" + string(arg0) + "\"," + "\"password\":\"" + string(arg1) + "\"," + "\"data\":{\"username\":\"" + string(arg2) + "\"}" + "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    global.request_register = _request;
    return _request;
}
function scr_r2_get_level_url(arg0)
{
    return global.r2_levels_url + "/" + string(arg0);
}
function scr_r2_get_thumbnail_url(arg0)
{
    return global.r2_thumbnails_url + "/" + string(arg0);
}
