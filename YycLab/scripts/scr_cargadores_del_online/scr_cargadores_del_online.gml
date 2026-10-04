// limpia las listas paralelas del browser. cuando se agrega una lista nueva va aca y no en
// los cuatro lugares que las limpiaban por separado
function scr_browser_clear_lists(_matar_tarjetas = false)
{
    var _nombres = [
        "id_levels", "autor_levels", "author_ids", "name_levels", "date_levels",
        "views_levels", "likes_levels", "file_urls", "thumbnail_urls", "descriptions",
        "is_liked_list", "is_featured_list", "difficulty_labels", "difficulty_confidences",
        "difficulty_sessions", "attempts_levels", "victories_levels", "unique_players_levels",
        "total_plays_levels", "first_clear_user_ids", "first_clear_usernames",
        "cold_storage_ids", "texture_used_levels", "custom_objects_used_levels", "thumb_queue"
    ];
    
    for (var i = 0; i < array_length(_nombres); i++)
    {
        if (!variable_global_exists(_nombres[i]))
            continue;
        
        var _l = variable_global_get(_nombres[i]);
        
        if (ds_exists(_l, ds_type_list))
            ds_list_clear(_l);
    }
    
    // los tags son una lista adentro de otra, hay que destruir cada sublista antes
    for (var t = 0; t < ds_list_size(global.tags_levels); t++)
    {
        var sublist = ds_list_find_value(global.tags_levels, t);
        
        if (ds_exists(sublist, ds_type_list))
            ds_list_destroy(sublist);
    }
    
    ds_list_clear(global.tags_levels);
    ds_list_clear(card_appear_queue);
    global.thumb_downloading = false;
    global.thumb_current_request = -1;
    
    if (!_matar_tarjetas)
        return;
    
    for (var k = 0; k < ds_list_size(instancias_tarjetas); k++)
    {
        var inst_old = ds_list_find_value(instancias_tarjetas, k);
        
        if (instance_exists(inst_old))
            instance_destroy(inst_old);
    }
    
    ds_list_clear(instancias_tarjetas);
    likes_loaded = false;
}


// pasa un nivel del json a las listas paralelas. las tres categorias hacian esto mismo cada una
// por su lado, ahora el orden de los add sale de un solo lado
function scr_num_or_zero(_v)
{
    if (is_real(_v))
        return _v;
    
    if (!is_string(_v))
        return 0;
    
    // los contadores llegan como texto y a veces como null, string_digits deja el numero solo
    var _d = string_digits(_v);
    
    if (_d == "")
        return 0;
    
    return real(_d);
}

function scr_browser_push_level(level_map, _destacado = false)
{
    var level_file_name = ds_map_find_value(level_map, "file_name");
    var level_thumb_name = ds_map_find_value(level_map, "thumbnail_name");
    var first_clear_user_id = ds_map_find_value(level_map, "first_clear_user_id");
    var first_clear_username = ds_map_find_value(level_map, "first_clear_username");
    var level_date = ds_map_find_value(level_map, "created_at");
    var tex_used = ds_map_find_value(level_map, "texture_used");
    var cold_id = ds_map_find_value(level_map, "cold_storage_id");
    var tags_raw = ds_map_find_value(level_map, "tags");
    var customs_used = ds_map_find_value(level_map, "custom_objects_used");
    
    if (is_undefined(tex_used) || tex_used == "null" || tex_used == "")
        tex_used = "vanilla";
    
    if (is_undefined(cold_id) || cold_id == "null")
        cold_id = "";
    
    if (is_undefined(first_clear_user_id) || first_clear_user_id == "null")
        first_clear_user_id = "";
    
    if (is_undefined(first_clear_username) || first_clear_username == "null")
        first_clear_username = "";
    
    if (is_undefined(level_date) || !is_string(level_date))
        level_date = "";
    
    if (string_length(level_date) > 10)
        level_date = string_copy(level_date, 1, 10);
    
    if (is_undefined(customs_used) || customs_used == "null")
        customs_used = "";
    
    if (customs_used != "" && !is_string(customs_used))
        customs_used = json_stringify(customs_used);
    
    // los likes pueden venir en likes, en total_likes o adentro de level_likes
    var t_likes = ds_map_find_value(level_map, "likes");
    
    if (is_undefined(t_likes) || t_likes == "" || t_likes == "null")
        t_likes = ds_map_find_value(level_map, "total_likes");
    
    if (is_undefined(t_likes) || t_likes == "" || t_likes == "null")
        t_likes = ds_map_find_value(level_map, "level_likes");
    
    var tags_list_parsed = ds_list_create();
    
    if (!is_undefined(tags_raw) && is_string(tags_raw))
        tags_list_parsed = scr_parse_tags_json(tags_raw);
    
    var _lid = ds_map_find_value(level_map, "level_id");
    
    if (is_undefined(_lid) || _lid == "" || _lid == "null")
        _lid = ds_map_find_value(level_map, "id");
    
    ds_list_add(global.id_levels, _lid);
    ds_list_add(global.name_levels, ds_map_find_value(level_map, "name"));
    ds_list_add(global.descriptions, ds_map_find_value(level_map, "description"));
    ds_list_add(global.autor_levels, ds_map_find_value(level_map, "author_name"));
    ds_list_add(global.author_ids, ds_map_find_value(level_map, "author_id"));
    ds_list_add(global.date_levels, level_date);
    ds_list_add(global.views_levels, scr_num_or_zero(ds_map_find_value(level_map, "downloads")));
    ds_list_add(global.likes_levels, scr_num_or_zero(t_likes));
    ds_list_add(global.file_urls, scr_r2_get_level_url(level_file_name));
    ds_list_add(global.thumbnail_urls, scr_r2_get_thumbnail_url(level_thumb_name));
    ds_list_add(global.is_liked_list, false);
    ds_list_add(global.is_featured_list, _destacado);
    ds_list_add(global.attempts_levels, scr_num_or_zero(ds_map_find_value(level_map, "attempts")));
    ds_list_add(global.victories_levels, scr_num_or_zero(ds_map_find_value(level_map, "victories")));
    ds_list_add(global.unique_players_levels, scr_num_or_zero(ds_map_find_value(level_map, "unique_players")));
    ds_list_add(global.total_plays_levels, scr_num_or_zero(ds_map_find_value(level_map, "total_plays")));
    ds_list_add(global.first_clear_user_ids, first_clear_user_id);
    ds_list_add(global.first_clear_usernames, first_clear_username);
    ds_list_add(global.cold_storage_ids, cold_id);
    ds_list_add(global.texture_used_levels, tex_used);
    ds_list_add(global.custom_objects_used_levels, customs_used);
    ds_list_add(global.tags_levels, tags_list_parsed);
    ds_map_destroy(level_map);
}


// crea las primeras tarjetas de la tanda que acaba de llegar, el resto las va creando el step
// a medida que se scrollea
function scr_browser_create_cards(_desde, _cuantas, _destacadas = false)
{
    for (var j = _desde; j < (_desde + _cuantas); j++)
    {
        var check_id = ds_list_find_value(global.id_levels, j);
        
        if (is_undefined(check_id) || string(check_id) == "")
            continue;
        
        var nueva_tarjeta = instance_create_depth(list_start_x, list_start_y + (j * card_height), 0, obj_level_file);
        nueva_tarjeta.my_list_index = j;
        nueva_tarjeta.is_liked = false;
        nueva_tarjeta.is_admin_featured = _destacadas;
        nueva_tarjeta.visible = false;
        nueva_tarjeta.fade_alpha = 0;
        nueva_tarjeta.fading_in = false;
        ds_list_add(instancias_tarjetas, nueva_tarjeta);
        ds_list_add(card_appear_queue, nueva_tarjeta);
        total_cards_created++;
    }
}


// telemetria
function scr_handle_telemetry_async(arg0, arg1)
{
    if (variable_global_exists("last_telemetry_request") && arg0 == global.last_telemetry_request)
    {
        if (arg1 == 1)
            return true;
        
        global.last_telemetry_request = -1;
        
        if (arg1 == 0)
        {
            scr_debug_log("TELEMETRY: OK");
            scr_retry_queue_original_succeeded(arg0);
        }
        else
        {
            scr_debug_log("TELEMETRY: FAILED (status " + string(arg1) + ") - activando retry");
            scr_retry_queue_original_failed(arg0);
        }
        
        return true;
    }
    
    if (variable_global_exists("last_victory_request") && arg0 == global.last_victory_request)
    {
        if (arg1 == 1)
            return true;
        
        global.last_victory_request = -1;
        
        if (arg1 == 0)
        {
            scr_debug_log("VICTORY: Registrada OK");
            scr_retry_queue_original_succeeded(arg0);
        }
        else
        {
            scr_debug_log("VICTORY: FAILED (status " + string(arg1) + ") - activando retry");
            scr_retry_queue_original_failed(arg0);
        }
        
        return true;
    }
    
    if (variable_global_exists("last_attempt_request") && arg0 == global.last_attempt_request)
    {
        if (arg1 == 1)
            return true;
        
        global.last_attempt_request = -1;
        
        if (arg1 == 0)
        {
            scr_debug_log("ATTEMPT: Registrado OK");
            scr_retry_queue_original_succeeded(arg0);
        }
        else
        {
            scr_debug_log("ATTEMPT: FAILED - activando retry");
            scr_retry_queue_original_failed(arg0);
        }
        
        return true;
    }
    
    return false;
}

// vinculo con discord

function scr_async_discord(arg0, arg1, arg2)
{
    if (!variable_global_exists("request_check_discord") || arg0 != global.request_check_discord)
        return false;
    
    // status 1
    if (arg1 == 1)
        return true;
    
    global.request_check_discord = -1;
    
    // se corto antes de llegar, no se sabe nada del vinculo
    if (arg1 != 0)
    {
        global.discord_chequeado_para = "";
        scr_debug_log("DISCORD STATUS: se corto la conexion, se pregunta de nuevo");
        return true;
    }
    
    var _http = ds_map_find_value(arg2, "http_status");
    
    if (is_undefined(_http))
        _http = 200;
    
    // que el status sea 0 no quiere decir que llego la fila. el 401 del token vencido cae por aca igual
    if (_http != 200)
    {
        global.discord_chequeado_para = "";
        scr_debug_log("DISCORD STATUS: respondio " + string(_http) + ", se pregunta de nuevo");
        return true;
    }
    
    var result = ds_map_find_value(arg2, "result");
    
    if (is_undefined(result))
        result = "";
    
    // se mira solo el discord_id, la fila trae tambien el discord_username
    var _did = scr_json_get_value(result, "discord_id");
    var _linked = false;
    
    if (!is_undefined(_did))
    {
        _did = string(_did);
        _did = string_replace_all(_did, "\"", "");
        
        // null es que nunca se vinculo
        if (_did != "" && _did != "null")
            _linked = true;
    }
    
    global.user_discord_linked = _linked;
    global.discord_chequeado_para = global.user_id;
    
    if (_linked)
        scr_debug_log("DISCORD STATUS: VINCULADO");
    else
        scr_debug_log("DISCORD STATUS: NO VINCULADO");
    
    return true;
}

// resultado de la busqueda avanzada

function scr_async_search_levels(arg0, arg1, arg2)
{
    if (variable_instance_exists(id, "request_search") && arg0 == request_search)
    {
        if (arg1 == 1)
            return true;
        
        request_search = -1;
        scr_debug_log("=== SEARCH RESPONSE ===");
        scr_debug_log("Status: " + string(arg1));
        
        if (arg1 == 0)
        {
            var result = ds_map_find_value(arg2, "result");
            scr_debug_log("=== RAW RESULT PREVIEW ===");
            scr_debug_log(string_copy(result, 1, 500));
            scr_debug_log("=== BUSCANDO cold_storage_id ===");
            var _cold_pos = string_pos("cold_storage_id", result);
            scr_debug_log("Posición de cold_storage_id en result: " + string(_cold_pos));
            
            if (_cold_pos > 0)
                scr_debug_log("Contexto: " + string_copy(result, _cold_pos, 120));
            
            scr_debug_log("Result preview: " + string_copy(result, 1, 300));
            
            if (is_undefined(result) || !is_string(result) || result == "" || result == "[]" || result == "null")
            {
                scr_debug_log("SEARCH: Sin resultados");
                loading = false;
                initial_load_complete = true;
                global.end_of_results = true;
                return true;
            }
            
            if (global.page == 0)
            {
                scr_browser_clear_lists(true);
                global.thumb_current_instance = self;
                scroll_y = 0;
                global.end_of_results = false;
                likes_loaded = false;
                total_levels_loaded = 0;
                total_cards_created = 0;
                initial_load_complete = false;
            }
            
            var niveles_antes = ds_list_size(global.id_levels);
            var levels_list = scr_json_parse_array(result);
            var count = ds_list_size(levels_list);
            scr_debug_log("SEARCH: Parseados " + string(count) + " niveles");
            
            if (count == 0)
            {
                global.end_of_results = true;
                loading = false;
                initial_load_complete = true;
                ds_list_destroy(levels_list);
                return true;
            }
            
            for (var i = 0; i < count; i++)
            {
                scr_browser_push_level(ds_list_find_value(levels_list, i));
            }
            
            ds_list_destroy(levels_list);
            var niveles_ahora = ds_list_size(global.id_levels);
            total_levels_loaded = niveles_ahora;
            
            if (count < levels_per_page)
                global.end_of_results = true;
            
            scr_browser_create_cards(niveles_antes, min(8, niveles_ahora - niveles_antes));
            
            initial_load_complete = true;
            loading = false;
            
            if (ds_list_size(global.id_levels) > 0 && !global.difficulties_loaded)
                global.difficulty_request = scr_get_difficulties_for_levels(global.id_levels);
            
            if (global.user_logged_in && ds_list_size(global.id_levels) > 0)
                get_likes_request = scr_supabase_get_user_likes(global.id_levels);
        }
        else
        {
            scr_debug_log("SEARCH ERROR: status = " + string(arg1));
            loading = false;
            initial_load_complete = true;
        }
        
        return true;
    }
    
    return false;
}

// destacados
function scr_async_admin_featured(arg0, arg1, arg2)
{
    if (arg0 == request_admin_featured)
    {
        if (arg1 == 1)
            return true;
        
        request_admin_featured = -1;
        admin_featured_loading = false;
        
        if (arg1 == 0)
        {
            var result = ds_map_find_value(arg2, "result");
            scr_debug_log("=== RAW RESULT PREVIEW ===");
            scr_debug_log(string_copy(result, 1, 500));
            scr_debug_log("=== BUSCANDO COLD_STORAGE_ID ===");
            var _cold_pos = string_pos("cold_storage_id", result);
            scr_debug_log("POSICIÓN DE COLD_STORAGE_ID EN RESULT: " + string(_cold_pos));
            
            if (_cold_pos > 0)
                scr_debug_log("CONTEXTO: " + string_copy(result, _cold_pos, 120));
            
            if (is_undefined(result) || !is_string(result))
            {
                loading = false;
                
                if (admin_featured_retry_count < admin_featured_max_retries)
                {
                    admin_featured_failed = true;
                }
                else
                {
                    initial_load_complete = true;
                    global.end_of_results = true;
                }
                
                return true;
            }
            
            if (result == "" || result == "[]" || result == "null")
            {
                loading = false;
                initial_load_complete = true;
                global.end_of_results = true;
                return true;
            }
            
            scr_browser_clear_lists(true);
            var levels_list = scr_json_parse_array(result);
            var count = ds_list_size(levels_list);
            
            for (var i = 0; i < count; i++)
            {
                scr_browser_push_level(ds_list_find_value(levels_list, i), true);
            }
            
            ds_list_destroy(levels_list);
            total_levels_loaded = ds_list_size(global.id_levels);
            total_cards_created = 0;
            global.end_of_results = true;
            scr_browser_create_cards(0, min(8, total_levels_loaded), true);
            
            initial_load_complete = true;
            loading = false;
            
            if (ds_list_size(global.id_levels) > 0 && !global.difficulties_loaded)
                global.difficulty_request = scr_get_difficulties_for_levels(global.id_levels);
            
            if (global.user_logged_in && ds_list_size(global.id_levels) > 0)
                get_likes_request = scr_supabase_get_user_likes(global.id_levels);
        }
        else
        {
            loading = false;
            
            if (admin_featured_retry_count < admin_featured_max_retries)
            {
                admin_featured_failed = true;
            }
            else
            {
                initial_load_complete = true;
                global.end_of_results = true;
            }
        }
        
        return true;
    }
    
    return false;
}

// el listado principal
// el unico que llena todas las listas paralelas
function scr_async_get_main(arg0, arg1, arg2)
{
    if (arg0 == get)
    {
        if (arg1 == 1)
            return true;
        
        // si fallo el catalogo estatico (falta el archivo o vino otra cosa del cdn),
        // reintenta la misma pagina contra supabase una sola vez
        if (variable_global_exists("catalog_inflight") && global.catalog_inflight)
        {
            global.catalog_inflight = false;
            
            var _cat_status = ds_map_find_value(arg2, "http_status");
            var _cat_result = ds_map_find_value(arg2, "result");
            
            if (arg1 != 0 || is_undefined(_cat_status) || (_cat_status != 200 && _cat_status != 206) || !is_string(_cat_result) || string_pos("[", _cat_result) != 1)
            {
                loading = true;
                get = scr_supabase_get_levels(global.page, levels_per_page, global.sort, global.name_s, global.autor_s, true);
                return true;
            }
        }
        
        var http_status = ds_map_find_value(arg2, "http_status");
        var conexion_ok = arg1 == 0 && (is_undefined(http_status) || http_status == 200 || http_status == 206);
        var result = "";
        var usando_cache = false;
        
        if (conexion_ok)
        {
            result = ds_map_find_value(arg2, "result");
            
            if (global.page == 0 && !is_undefined(result) && is_string(result) && result != "" && result != "[]")
                scr_save_list_cache("principal", result);
        }
        else
        {
            scr_debug_log("ERROR DE RED: STATUS " + string(arg1) + " / HTTP " + string(http_status));
            var msj_falla = "";
            var cooldown_time = 300;
            
            if (arg1 < 0 || is_undefined(http_status))
            {
                msj_falla = "SIN CONEXIÓN A INTERNET. ";
            }
            else if (http_status == 429)
            {
                msj_falla = "SCROLL DEMASIADO RÁPIDO. ";
                cooldown_time = 600;
            }
            else if (http_status >= 500)
            {
                msj_falla = "SERVIDORES SATURADOS. ";
            }
            else
            {
                msj_falla = "ERROR DE SERVIDOR (" + string(http_status) + "). ";
            }
            
            if (instance_exists(obj_level_loader))
                obj_level_loader.request_cooldown = cooldown_time;
            
            if (global.page == 0)
            {
                result = scr_load_list_cache("principal");
                
                if (result != "")
                {
                    usando_cache = true;
                    show_message_async(msj_falla + "MOSTRANDO NIVELES LOCALES.");
                }
                else
                {
                    show_message_async(msj_falla + "NO HAY DATOS GUARDADOS PARA MOSTRAR.");
                    loading = false;
                    return true;
                }
            }
            else
            {
                if (http_status == 429)
                    show_message_async(msj_falla + "Espera 10 segundos para seguir viendo niveles.");
                
                loading = false;
                return true;
            }
        }
        
        if (usando_cache)
            scr_debug_log("=== LEYENDO DESDE CACHÉ LOCAL ===");
        else
            scr_debug_log("=== RAW SUPABASE RESPONSE ===");
        
        var _cold_pos = string_pos("cold_storage_id", result);
        
        if (_cold_pos > 0)
            scr_debug_log("CONTEXTO: " + string_copy(result, _cold_pos, 150));
        
        if (global.page == 0)
        {
            scr_browser_clear_lists(true);
            scroll_y = 0;
            global.end_of_results = false;
            likes_loaded = false;
            total_levels_loaded = 0;
            total_cards_created = 0;
            initial_load_complete = false;
        }
        
        var niveles_antes = ds_list_size(global.id_levels);
        var levels_list = scr_json_parse_array(result);
        var count = ds_list_size(levels_list);
        
        if (count == 0)
        {
            global.end_of_results = true;
            
            if (global.page > 0)
                global.page -= 1;
            
            loading = false;
            initial_load_complete = true;
            ds_list_destroy(levels_list);
            return true;
        }
        
        if (instance_exists(obj_level_loader))
        {
            obj_level_loader.parse_levels_list = levels_list;
            obj_level_loader.parse_count = count;
            obj_level_loader.parse_index = 0;
            obj_level_loader.parse_niveles_antes = niveles_antes;
            obj_level_loader.parse_pending = true;
            obj_level_loader.loading = true;
        }
        else
        {
            ds_list_destroy(levels_list);
        }
        
        return true;
    }
    else if (arg0 == get && arg1 < 0)
    {
        loading = false;
        return true;
    }
    
    return false;
}


// niveles dificiles
function scr_async_hardest(arg0, arg1, arg2)
{
    if (arg0 == request_hardest)
    {
        if (arg1 == 1)
            return true;
        
        request_hardest = -1;
        
        if (arg1 == 0)
        {
            var result = ds_map_find_value(arg2, "result");
            
            if (is_undefined(result) || !is_string(result))
            {
                loading = false;
                initial_load_complete = true;
                global.end_of_results = true;
                return true;
            }
            
            if (result == "" || result == "[]" || result == "null")
            {
                loading = false;
                initial_load_complete = true;
                global.end_of_results = true;
                return true;
            }
            
            if (global.page == 0)
            {
                scr_browser_clear_lists(true);
            }
            
            var niveles_antes = ds_list_size(global.id_levels);
            var levels_list = scr_json_parse_array(result);
            var count = ds_list_size(levels_list);
            
            if (count == 0)
            {
                global.end_of_results = true;
                
                if (global.page > 0)
                    global.page -= 1;
            }
            
            for (var i = 0; i < count; i++)
            {
                scr_browser_push_level(ds_list_find_value(levels_list, i));
            }
            
            ds_list_destroy(levels_list);
            var niveles_ahora = ds_list_size(global.id_levels);
            total_levels_loaded = niveles_ahora;
            
            if (count < levels_per_page && global.page == 0)
                global.end_of_results = true;
            else if (count < levels_per_load && global.page > 0)
                global.end_of_results = true;
            
            if (!initial_load_complete)
            {
                scr_browser_create_cards(niveles_antes, min(8, niveles_ahora - niveles_antes));
                
                initial_load_complete = true;
            }
            else
            {
                scr_browser_create_cards(niveles_antes, min(4, niveles_ahora - niveles_antes));
            }
            
            loading = false;
            
            if (ds_list_size(global.id_levels) > 0 && !global.difficulties_loaded)
                global.difficulty_request = scr_get_difficulties_for_levels(global.id_levels);
            
            if (global.user_logged_in && ds_list_size(global.id_levels) > 0)
                get_likes_request = scr_supabase_get_user_likes(global.id_levels);
        }
        else if (arg1 < 0)
        {
            loading = false;
        }
        
        return true;
    }
    
    return false;
}

// miniaturas

function scr_async_thumbnail(arg0, arg1, arg2)
{
    if (arg0 == featured_thumb_current_request && featured_thumb_downloading)
    {
        featured_thumb_downloading = false;
        featured_thumb_current_request = -1;
        
        if (arg1 == 0)
        {
            if (featured_thumb_current_index >= 0 && featured_thumb_current_index < ds_list_size(featured_levels))
            {
                var feat_for_path = ds_list_find_value(featured_levels, featured_thumb_current_index);
                var feat_id_for_path = ds_map_find_value(feat_for_path, "id");
                
                if (is_string(feat_id_for_path) && feat_id_for_path != "")
                    feat_id_for_path = real(feat_id_for_path);
                
                var thumb_path_done = working_directory + "/cache_img/level_" + string(feat_id_for_path) + ".png";
                
                if (file_exists(thumb_path_done))
                {
                    var spr_new = sprite_add(thumb_path_done, 1, false, false, 0, 0);
                    
                    if (spr_new != -1 && spr_new != -4)
                    {
                        ds_list_replace(featured_thumbs, featured_thumb_current_index, spr_new);
                    }
                    else
                    {
                        if (file_exists(thumb_path_done))
                            file_delete(thumb_path_done);
                    }
                }
            }
        }
        
        ds_list_replace(featured_thumb_requests, featured_thumb_current_index, -1);
        featured_thumb_current_index = -1;
        return true;
    }
    
    if (global.thumb_downloading && arg0 == global.thumb_current_request)
    {
        global.thumb_downloading = false;
        global.thumb_current_request = -1;
        
        if (instance_exists(global.thumb_current_instance))
        {
            var inst_thumb = global.thumb_current_instance;
            inst_thumb.thumbnail_download_id = -1;
            
            var http_status = ds_map_find_value(arg2, "http_status");
            var request_ok = (arg1 == 0) && (!is_undefined(http_status) && (http_status == 200 || http_status == 206));
            
            if (!is_undefined(http_status) && http_status == 429)
            {
                global.thumb_cooldown = 300; // 5 segundos de pausa en descargas
            }
            
            if (request_ok && file_exists(inst_thumb.imagen_path))
            {
                if (inst_thumb.imagen_nivel != -1 && sprite_exists(inst_thumb.imagen_nivel))
                    sprite_delete(inst_thumb.imagen_nivel);
                
                var spr = sprite_add(inst_thumb.imagen_path, 1, false, false, 0, 0);
                if (spr != -1 && spr != -4)
                {
                    inst_thumb.imagen_nivel = spr;
                    inst_thumb.imagen_cargando = false;
                }
                else
                {
                    // Archivo corrupto (ej: HTML de error de Cloudflare, no existia la img)
                    if (file_exists(inst_thumb.imagen_path))
                        file_delete(inst_thumb.imagen_path);
                    inst_thumb.imagen_nivel = -1;
                    inst_thumb.imagen_cargando = false;
                    inst_thumb.thumb_queued = false;
                    inst_thumb.thumb_retry_count++;
                }
            }
            else
            {
                // Error de descarga o archivo inexistente
                if (file_exists(inst_thumb.imagen_path))
                    file_delete(inst_thumb.imagen_path);
                inst_thumb.imagen_nivel = -1;
                inst_thumb.imagen_cargando = false;
                inst_thumb.thumb_queued = false;
                inst_thumb.thumb_retry_count++;
            }
        }
        
        global.thumb_current_instance = -4;
        return true;
    }
    
    return false;
}

// los likes del usuario, se piden aparte del listado y despues se marca cada tarjeta
function scr_async_user_likes(arg0, arg1, arg2)
{
    if (arg0 == get_likes_request)
    {
        if (arg1 == 1)
            return true;
        
        get_likes_request = -1;
        
        if (arg1 == 0)
        {
            var result = ds_map_find_value(arg2, "result");
            
            if (is_undefined(result) || !is_string(result))
                result = "";
            
            var liked_ids = ds_list_create();
            var pos = 1;
            var len = string_length(result);
            
            while (pos < len)
            {
                var found = string_pos("\"level_id\":", string_copy(result, pos, (len - pos) + 1));
                
                if (found == 0)
                    break;
                
                pos = pos + found + 10;
                var num_str = "";
                var c = string_char_at(result, pos);
                
                while (ord(c) >= 48 && ord(c) <= 57 && pos <= len)
                {
                    num_str += c;
                    pos++;
                    c = string_char_at(result, pos);
                }
                
                if (num_str != "")
                    ds_list_add(liked_ids, real(num_str));
            }
            
            for (var i = 0; i < ds_list_size(global.id_levels); i++)
            {
                var lvl_id = ds_list_find_value(global.id_levels, i);
                
                if (is_string(lvl_id))
                    lvl_id = real(lvl_id);
                
                var is_liked = false;
                var j = 0;
                
                while (j < ds_list_size(liked_ids))
                {
                    if (ds_list_find_value(liked_ids, j) == lvl_id)
                    {
                        is_liked = true;
                        break;
                    }
                    else
                    {
                        j++;
                        continue;
                    }
                }
                
                ds_list_replace(global.is_liked_list, i, is_liked);
                for (var _ci = 0; _ci < ds_list_size(instancias_tarjetas); _ci++)
                {
                    var inst = ds_list_find_value(instancias_tarjetas, _ci);
                    
                    if (instance_exists(inst) && inst.my_list_index == i)
                    {
                        inst.is_liked = is_liked;
                        break;
                    }
                }
            }
            
            show_debug_message("LIKES del server: " + string(ds_list_size(liked_ids)) + " sobre " + string(ds_list_size(global.id_levels)) + " niveles, listalikes=" + string(ds_list_size(global.is_liked_list)));
            ds_list_destroy(liked_ids);
            likes_loaded = true;
            
            if (ds_list_size(global.id_levels) > 0 && !global.difficulties_loaded)
                global.difficulty_request = scr_get_difficulties_for_levels(global.id_levels);
        }
        
        return true;
    }
    
    return false;
}

// dificultad de varios niveles
function scr_async_difficulties(arg0, arg1, arg2)
{
    if (variable_global_exists("difficulty_request") && global.difficulty_request != -1 && arg0 == global.difficulty_request)
    {
        global.difficulty_request = -1;
        scr_debug_log("=== DIFFICULTY RESPONSE ===");
        
        if (arg1 == 1)
            return true;
        
        if (arg1 == 0)
        {
            var result = ds_map_find_value(arg2, "result");
            ds_list_clear(global.difficulty_labels);
            ds_list_clear(global.difficulty_confidences);
            ds_list_clear(global.difficulty_sessions);
            var id_count = ds_list_size(global.id_levels);
            
            for (var i = 0; i < id_count; i++)
            {
                ds_list_add(global.difficulty_labels, "unplayed");
                ds_list_add(global.difficulty_confidences, "none");
                ds_list_add(global.difficulty_sessions, 0);
            }
            
            if (!is_undefined(result) && is_string(result) && result != "" && result != "[]")
            {
                var search_pos = 1;
                var result_len = string_length(result);
                
                while (search_pos < result_len)
                {
                    var found = string_pos("\"level_id\":", string_copy(result, search_pos, (result_len - search_pos) + 1));
                    
                    if (found == 0)
                        break;
                    
                    var obj_startx = (search_pos + found) - 1;
                    
                    while (obj_startx > 1 && string_char_at(result, obj_startx) != "{")
                        obj_startx--;
                    
                    var obj_end = search_pos + found;
                    var depthx = 0;
                    
                    for (var ci = obj_startx; ci <= result_len; ci++)
                    {
                        var ch = string_char_at(result, ci);
                        
                        if (ch == "{")
                            depthx++;
                        
                        if (ch == "}")
                        {
                            depthx--;
                            
                            if (depthx == 0)
                            {
                                obj_end = ci;
                                break;
                            }
                        }
                    }
                    
                    var obj_str = string_copy(result, obj_startx, (obj_end - obj_startx) + 1);
                    var d_level_id = scr_json_get_value(obj_str, "level_id");
                    var d_label = scr_json_get_value(obj_str, "difficulty_label");
                    var d_confidence = scr_json_get_value(obj_str, "confidence");
                    var d_sessions = scr_json_get_value(obj_str, "total_sessions");
                    
                    if (!is_undefined(d_level_id) && d_level_id != "")
                    {
                        for (var j = 0; j < ds_list_size(global.id_levels); j++)
                        {
                            var check_id = ds_list_find_value(global.id_levels, j);
                            
                            if (string(check_id) == string(d_level_id))
                            {
                                if (!is_undefined(d_label) && d_label != "")
                                    ds_list_replace(global.difficulty_labels, j, d_label);
                                
                                if (!is_undefined(d_confidence) && d_confidence != "")
                                    ds_list_replace(global.difficulty_confidences, j, d_confidence);
                                
                                if (!is_undefined(d_sessions) && d_sessions != "")
                                    ds_list_replace(global.difficulty_sessions, j, real(d_sessions));
                                
                                break;
                            }
                        }
                    }
                    
                    search_pos = obj_end + 1;
                }
            }
            
            global.difficulties_loaded = true;
            global.difficulties_processed = false;
            scr_debug_log("=== END DIFFICULTY ===");
        }
        else
        {
            scr_debug_log("DIFFICULTY: REQUEST FAILED WITH STATUS " + string(arg1));
        }
        
        return true;
    }
    
    return false;
}

// cd antispam
function scr_online_request_check_spam()
{
    if (!variable_global_exists("request_times") || !ds_exists(global.request_times, ds_type_list))
        global.request_times = ds_list_create();
    
    var now = current_time;
    
    // Eliminar timestamps antiguos (más de 10 segundos)
    for (var i = ds_list_size(global.request_times) - 1; i >= 0; i--)
    {
        if (now - ds_list_find_value(global.request_times, i) >= 10000)
            ds_list_delete(global.request_times, i);
    }
    
    // Si ya hay 2 peticiones en los últimos 10 segundos, esta sería la 3ra, bloqueamos por 5s (300 frames)
    if (ds_list_size(global.request_times) >= 2)
    {
        if (instance_exists(obj_level_loader))
        {
            obj_level_loader.request_cooldown = 300;
            obj_level_loader.spam_message_active = true;
        }
        return true;
    }
    
    // Registrar el timestamp de la petición actual
    ds_list_add(global.request_times, now);
    return false;
}
