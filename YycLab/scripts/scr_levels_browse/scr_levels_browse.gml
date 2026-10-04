
// badges propios
// trae solo los id de badge del usuario actual, para dibujar los iconos al lado del nombre.
function scr_supabase_get_my_badges()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/user_badges?select=badge_id&ub_user_id=eq." + global.user_id;
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// pasa la respuesta de badges a una ds_list de id.
function scr_parse_badges_response(arg0)
{
    var result_list = ds_list_create();
    var search = "\"badge_id\":";
    var temp_str = arg0;
    var pos = string_pos(search, temp_str);
    
    while (pos > 0)
    {
        var val_start = pos + string_length(search);
        
        while (string_char_at(temp_str, val_start) == " ")
            val_start++;
        
        var val_end = val_start;
        var c = string_char_at(temp_str, val_end);
        
        while (c != "," && c != "}" && c != " " && c != "]" && val_end <= string_length(temp_str))
        {
            val_end++;
            c = string_char_at(temp_str, val_end);
        }
        
        var badge_id_str = string_copy(temp_str, val_start, val_end - val_start);
        
        if (badge_id_str != "")
            ds_list_add(result_list, real(badge_id_str));
        
        temp_str = string_copy(temp_str, val_end, (string_length(temp_str) - val_end) + 1);
        pos = string_pos(search, temp_str);
    }
    
    return result_list;
}





// parseo del listado
// aca se llenan las listas globales paralelas con las que despues se dibujan las tarjetas.
// todas tienen que terminar con el mismo largo: si una se saltea un add, el browser empieza
// a mostrar los datos de un nivel sobre la tarjeta de otro.
// corta un array json en sus objetos de primer nivel, sin mirar lo que tienen adentro.
function scr_json_split_objects(arg0)
{
    var result_list = ds_list_create();
    var pos = string_pos("[", arg0);
    
    if (pos == 0)
        return result_list;
    
    pos += 1;
    var len = string_length(arg0);
    var brace_depth = 0;
    var start_pos = 0;
    
    while (pos <= len)
    {
        var c = string_char_at(arg0, pos);
        
        // cuenta llaves para cortar los objetos de primer nivel, lo anidado
        // queda adentro del pedazo
        if (c == "{")
        {
            if (brace_depth == 0)
                start_pos = pos;
            
            brace_depth += 1;
        }
        else if (c == "}")
        {
            brace_depth -= 1;
            
            if (brace_depth == 0 && start_pos > 0)
            {
                var obj_str = string_copy(arg0, start_pos, (pos - start_pos) + 1);
                ds_list_add(result_list, obj_str);
                start_pos = 0;
            }
        }
        
        pos += 1;
    }
    
    return result_list;
}
// mete un nivel del json en las listas globales paralelas, en el orden fijo que espera el resto.
// cada ds_list_add de aca tiene que tener su par en el reset de listas, si no las tarjetas
// empiezan a mostrar los datos corridos.
function scr_parse_single_level(arg0)
{
    var level_id = scr_json_get_value(arg0, "id");
    var level_name = scr_json_get_value(arg0, "name");
    var level_desc = scr_json_get_value(arg0, "description");
    var level_author = scr_json_get_value(arg0, "author_name");
    var level_author_id = scr_json_get_value(arg0, "author_id");
    var level_file_name = scr_json_get_value(arg0, "file_name");
    var level_thumb_name = scr_json_get_value(arg0, "thumbnail_name");
    var t_likes = scr_json_get_value(arg0, "total_likes");
    var likes_data = scr_json_get_value(arg0, "level_likes");
    var level_likes = 0;
    
    if (t_likes != "" && t_likes != "null")
    {
        level_likes = real(t_likes);
    }
    // si no vino total_likes ya sumado, el numero se saca a mano de adentro
    // del objeto level_likes que devuelve supabase
    else if (likes_data != "")
    {
        var count_pos = string_pos("\"count\":", likes_data);
        
        if (count_pos > 0)
        {
            var num_start = count_pos + 8;
            var num_str = "";
            var ch = string_char_at(likes_data, num_start);
            
            while (ch == " ")
            {
                num_start++;
                ch = string_char_at(likes_data, num_start);
            }
            
            // lee digito por digito hasta que se corta
            while (ord(ch) >= 48 && ord(ch) <= 57)
            {
                num_str += ch;
                num_start++;
                ch = string_char_at(likes_data, num_start);
            }
            
            if (num_str != "")
                level_likes = real(num_str);
        }
    }
    
    var level_downloads = scr_json_get_value(arg0, "downloads");
    var level_attempts = scr_json_get_value(arg0, "attempts");
    var level_victories = scr_json_get_value(arg0, "victories");
    var level_unique_players = scr_json_get_value(arg0, "unique_players");
    var level_total_plays = scr_json_get_value(arg0, "total_plays");
    
    // todo lo que sale de scr_json_get_value es texto, los contadores se pasan
    // a numero aca o las cuentas del clear rate dan cualquier cosa
    if (is_string(level_attempts) && level_attempts != "")
        level_attempts = real(level_attempts);
    else if (level_attempts == "" || is_undefined(level_attempts))
        level_attempts = 0;
    
    if (is_string(level_victories) && level_victories != "")
        level_victories = real(level_victories);
    else if (level_victories == "" || is_undefined(level_victories))
        level_victories = 0;
    
    if (is_string(level_unique_players) && level_unique_players != "")
        level_unique_players = real(level_unique_players);
    else if (level_unique_players == "" || is_undefined(level_unique_players))
        level_unique_players = 0;
    
    if (is_string(level_total_plays) && level_total_plays != "")
        level_total_plays = real(level_total_plays);
    else if (level_total_plays == "" || is_undefined(level_total_plays))
        level_total_plays = 0;
    
    var first_clear_user_id = scr_json_get_value(arg0, "first_clear_user_id");
    var first_clear_username = scr_json_get_value(arg0, "first_clear_username");
    
    if (first_clear_user_id == "null" || is_undefined(first_clear_user_id))
        first_clear_user_id = "";
    
    if (first_clear_username == "null" || is_undefined(first_clear_username))
        first_clear_username = "";
    
    var level_date = scr_json_get_value(arg0, "created_at");
    
    if (is_undefined(level_date) || level_date == "null")
        level_date = "";
    
    if (string_length(level_date) > 10)
        level_date = string_copy(level_date, 1, 10);
    
    var tags_raw = scr_json_get_value(arg0, "tags");
    var tags_list_parsed;
    
    if (tags_raw != "" && tags_raw != "null")
        tags_list_parsed = scr_parse_tags_json(tags_raw);
    else
        tags_list_parsed = ds_list_create();
    
    var file_url = scr_r2_get_level_url(level_file_name);
    var thumb_url = scr_r2_get_thumbnail_url(level_thumb_name);
    // de aca para abajo van las listas paralelas. cada add tiene que tener su par
    // en el reset de scr_start_category_cleanup o las tarjetas salen con los datos corridos
    ds_list_add(global.id_levels, level_id);
    ds_list_add(global.name_levels, level_name);
    ds_list_add(global.descriptions, level_desc);
    ds_list_add(global.autor_levels, level_author);
    ds_list_add(global.author_ids, level_author_id);
    ds_list_add(global.date_levels, level_date);
    ds_list_add(global.views_levels, level_downloads);
    ds_list_add(global.likes_levels, level_likes);
    ds_list_add(global.file_urls, file_url);
    ds_list_add(global.thumbnail_urls, thumb_url);
    ds_list_add(global.is_liked_list, 0);
    ds_list_add(global.attempts_levels, level_attempts);
    ds_list_add(global.victories_levels, level_victories);
    ds_list_add(global.unique_players_levels, level_unique_players);
    ds_list_add(global.total_plays_levels, level_total_plays);
    ds_list_add(global.first_clear_user_ids, first_clear_user_id);
    ds_list_add(global.first_clear_usernames, first_clear_username);
    ds_list_add(global.tags_levels, tags_list_parsed);
    // level_map no existe en esta funcion, le queda del scope del que la llama
    var cold_id = ds_map_find_value(level_map, "cold_storage_id");
    
    if (is_undefined(cold_id) || cold_id == "null" || cold_id == "")
        cold_id = "";
    
    ds_list_add(global.cold_storage_ids, cold_id);
    return 1;
}





// busqueda
// busqueda con filtros contra el rpc search_levels_advanced: texto, tags y rango de clear rate.
// es distinta del listado normal, que filtra por url.
function scr_supabase_search_levels(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
{
    if (!scr_rate_limit_check("search"))
    {
        show_debug_message("SEARCH: Rate limited");
        return -1;
    }
    
    var url = global.supabase_url + "/rest/v1/rpc/search_levels_advanced";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    // va con la key anonima y no con el token, se puede buscar sin estar logueado
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{";
    body += ("\"p_limit\":" + string(arg1) + ",");
    body += ("\"p_offset\":" + string(arg0 * arg1) + ",");
    
    if (arg2 != "")
        body += ("\"p_name\":\"" + arg2 + "\",");
    else
        body += "\"p_name\":null,";
    
    if (arg3 != "")
        body += ("\"p_author\":\"" + arg3 + "\",");
    else
        body += "\"p_author\":null,";
    
    // el filtro de clear rate se manda solo si vienen los dos extremos,
    // si no van en null y el server no filtra por eso
    if (arg4 >= 0 && arg5 >= 0)
    {
        body += ("\"p_cr_min\":" + string(arg4) + ",");
        body += ("\"p_cr_max\":" + string(arg5) + ",");
    }
    else
    {
        body += "\"p_cr_min\":null,";
        body += "\"p_cr_max\":null,";
    }
    
    if (ds_exists(arg6, ds_type_list) && ds_list_size(arg6) > 0)
    {
        body += "\"p_tags\":[";
        
        for (var i = 0; i < ds_list_size(arg6); i++)
        {
            if (i > 0)
                body += ",";
            
            var tag = ds_list_find_value(arg6, i);
            body += ("\"" + string(tag) + "\"");
        }
        
        body += "]";
    }
    else
    {
        body += "\"p_tags\":null";
    }
    
    body += "}";
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    scr_rate_limit_register("search");
    return request;
}
// agarra lo que quedo cargado en obj_search_panel, lo pasa a las globals de busqueda y dispara
// el user event 0 del loader, que es el que sale a pedir.
function scr_execute_search()
{
    var search_mode_local, search_text_local;
    
    with (obj_search_panel)
    {
        search_text_local = search_text;
        search_mode_local = search_mode;
        var selected_cr = selected_clear_rate;
        
        if (variable_global_exists("search_tags") && ds_exists(global.search_tags, ds_type_list))
            ds_list_clear(global.search_tags);
        else
            global.search_tags = ds_list_create();
        
        for (var i = 0; i < ds_list_size(tags_selected); i++)
        {
            var tag = ds_list_find_value(tags_selected, i);
            ds_list_add(global.search_tags, tag);
        }
        
        if (selected_cr >= 0 && selected_cr <= 3)
        {
            global.search_cr_min = clear_rate_min[selected_cr];
            global.search_cr_max = clear_rate_max[selected_cr];
        }
        else
        {
            global.search_cr_min = -1;
            global.search_cr_max = -1;
        }
    }
    
    // 0 busca por nombre y 1 por autor, el resto de los filtros van igual en los dos
    if (search_mode_local == 0)
    {
        global.name_s = search_text_local;
        global.autor_s = "";
    }
    else
    {
        global.name_s = "";
        global.autor_s = search_text_local;
    }
    
    show_debug_message("=== EXECUTE SEARCH ===");
    show_debug_message("name_s: " + global.name_s);
    show_debug_message("autor_s: " + global.autor_s);
    show_debug_message("cr_min: " + string(global.search_cr_min));
    show_debug_message("cr_max: " + string(global.search_cr_max));
    show_debug_message("tags count: " + string(ds_list_size(global.search_tags)));
    show_debug_message("======================");
    
    if (instance_exists(obj_level_loader))
    {
        with (obj_level_loader)
        {
            view_mode = 4;
            event_user(0);
        }
    }
    
    return 1;
}





// destacados y categorias
// el browser tiene cuatro modos: recientes, destacados por admin, mas likeados y mas dificiles.
// cambiar de modo tira todas las tarjetas y arranca de cero.
// los destacados que arma el server solo, no los que elige un admin.
function scr_get_featured_levels()
{
    var url = global.supabase_url + "/rest/v1/rpc/get_featured_levels";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var request = http_request(url, "POST", headers, "{}");
    ds_map_destroy(headers);
    return request;
}
// marca que alguien abrio el nivel.
function scr_register_level_play(arg0)
{
    scr_debug_log("=== REGISTER LEVEL PLAY ===");
    scr_debug_log("level_id: " + string(arg0));
    
    if (arg0 <= 0)
    {
        scr_debug_log("ERROR: level_id inválido!");
        return -1;
    }
    
    var url = global.supabase_url + "/rest/v1/rpc/register_level_play";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{\"p_level_id\":" + string(arg0) + "}";
    scr_debug_log("PLAY: Body = " + body);
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    global.last_play_request = request;
    scr_debug_log("PLAY: Request ID = " + string(request));
    return request;
}
// pone o saca el nivel de los destacados por admin. arg1 dice si ya estaba destacado, de ahi
// sale si la peticion va como DELETE o como POST.
function scr_toggle_admin_featured(arg0, arg1)
{
    if (!global.user_is_admin)
        return -1;
    
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var request;
    
    if (arg1)
    {
        var url = global.supabase_url + "/rest/v1/admin_featured_levels?level_id=eq." + string(arg0);
        request = http_request(url, "DELETE", headers, "");
    }
    else
    {
        var url = global.supabase_url + "/rest/v1/admin_featured_levels";
        ds_map_add(headers, "Prefer", "return=representation");
        var body = json_stringify(
        {
            level_id: int64(arg0),
            featured_by: global.user_id
        });
        request = http_request(url, "POST", headers, body);
    }
    
    ds_map_destroy(headers);
    return request;
}
// los niveles destacados a mano por un admin, con todos los datos para armar las tarjetas.
function scr_get_admin_featured_levels()
{
    var url = global.supabase_url + "/rest/v1/rpc/get_admin_featured_levels";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var request = http_request(url, "POST", headers, "{}");
    ds_map_destroy(headers);
    return request;
}
// pregunta por un nivel solo, para saber como dibujar el boton en el panel.
function scr_check_level_is_featured(arg0)
{
    var url = global.supabase_url + "/rest/v1/admin_featured_levels?level_id=eq." + string(arg0) + "&select=id";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// solo los id, para marcar cuales ya estan destacados en una lista larga.
function scr_get_admin_featured_list_ids()
{
    var url = global.supabase_url + "/rest/v1/admin_featured_levels?select=level_id";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// cambia de categoria en el browser: mata las tarjetas que habia, limpia las listas globales,
// resetea la paginacion y pide la tanda nueva.
function scr_start_category_cleanup(arg0)
{
    with (obj_level_loader)
    {
        // en mantenimiento el cambio de categoria se hace local con el snapshot
        if (variable_global_exists("mantenimiento_activo") && global.mantenimiento_activo)
        {
            if (arg0 == 0)
            {
                view_mode = 0;
                global.sort = "recent";
                scr_maintenance_aplicar_vista();
            }
            else if (arg0 == 2)
            {
                view_mode = 2;
                global.sort = "total_likes";
                scr_maintenance_aplicar_vista();
            }
            else
                show_message_async("En modo mantenimiento solo se pueden ver recientes y populares.");
            
            exit;
        }
        
        pending_category_change = arg0;
        var count_to_destroy = ds_list_size(instancias_tarjetas);
        
        // hasta 12 tarjetas se destruyen en el acto. de ahi para arriba pasan a
        // cleanup_queue y el loader las va matando de a poco, si no se clava un frame entero
        if (count_to_destroy <= 12)
        {
            for (var k = 0; k < count_to_destroy; k++)
            {
                var inst_old = ds_list_find_value(instancias_tarjetas, k);
                
                if (instance_exists(inst_old))
                    instance_destroy(inst_old);
            }
            
            ds_list_clear(instancias_tarjetas);
            cleanup_active = false;
            ds_list_clear(global.id_levels);
            ds_list_clear(global.autor_levels);
            ds_list_clear(global.author_ids);
            ds_list_clear(global.name_levels);
            ds_list_clear(global.date_levels);
            ds_list_clear(global.views_levels);
            ds_list_clear(global.likes_levels);
            ds_list_clear(global.file_urls);
            ds_list_clear(global.thumbnail_urls);
            ds_list_clear(global.descriptions);
            ds_list_clear(global.is_liked_list);
            ds_list_clear(global.attempts_levels);
            ds_list_clear(global.victories_levels);
            ds_list_clear(global.unique_players_levels);
            ds_list_clear(global.thumb_queue);
            ds_list_clear(global.first_clear_user_ids);
            ds_list_clear(global.first_clear_usernames);
            ds_list_clear(card_appear_queue);
            global.thumb_downloading = false;
            global.thumb_current_instance = -1;
            global.thumb_current_request = -1;
            scroll_y = 0;
            global.page = 0;
            global.end_of_results = false;
            loading = true;
            initial_load_complete = false;
            total_levels_loaded = 0;
            total_cards_created = 0;
            
            // 0 recientes, 1 destacados por admin, 2 populares, 3 mas dificiles
            if (arg0 == 0)
            {
                view_mode = 0;
                global.sort = "recent";
                get = scr_supabase_get_levels(global.page, levels_per_page, global.sort, global.name_s, global.autor_s);
            }
            else if (arg0 == 1)
            {
                view_mode = 1;
                admin_featured_loading = true;
                request_admin_featured = scr_get_admin_featured_levels();
            }
            else if (arg0 == 2)
            {
                view_mode = 2;
                global.sort = "total_likes";
                get = scr_supabase_get_levels(0, levels_per_page, global.sort, "", "");
            }
            else if (arg0 == 3)
            {
                view_mode = 3;
                request_hardest = scr_get_hardest_levels(levels_per_page, 0);
            }
            
            pending_category_change = -1;
        }
        else
        {
            // el bloque de abajo repite el mismo reset, lo unico que cambia es que las
            // tarjetas van a la cola en vez de morir aca y la peticion sale cuando termina
            ds_list_clear(cleanup_queue);
            
            for (var k = 0; k < count_to_destroy; k++)
            {
                var inst_old = ds_list_find_value(instancias_tarjetas, k);
                
                if (instance_exists(inst_old))
                    ds_list_add(cleanup_queue, inst_old);
            }
            
            ds_list_clear(global.id_levels);
            ds_list_clear(global.autor_levels);
            ds_list_clear(global.author_ids);
            ds_list_clear(global.name_levels);
            ds_list_clear(global.date_levels);
            ds_list_clear(global.views_levels);
            ds_list_clear(global.likes_levels);
            ds_list_clear(global.file_urls);
            ds_list_clear(global.thumbnail_urls);
            ds_list_clear(global.descriptions);
            ds_list_clear(global.is_liked_list);
            ds_list_clear(global.attempts_levels);
            ds_list_clear(global.victories_levels);
            ds_list_clear(global.unique_players_levels);
            ds_list_clear(global.thumb_queue);
            ds_list_clear(global.first_clear_user_ids);
            ds_list_clear(global.first_clear_usernames);
            ds_list_clear(card_appear_queue);
            ds_list_clear(instancias_tarjetas);
            global.thumb_downloading = false;
            global.thumb_current_instance = -1;
            global.thumb_current_request = -1;
            scroll_y = 0;
            global.page = 0;
            global.end_of_results = false;
            loading = true;
            initial_load_complete = false;
            total_levels_loaded = 0;
            total_cards_created = 0;
            // el loader mira este flag y sigue el borrado por su cuenta
            cleanup_active = true;
        }
    }
    
    return 1;
}





// dificultad
// la dificultad la calcula el server con las partidas jugadas, el cliente solo la dibuja.
// con pocas partidas viene marcada como poco confiable y se muestra apagada.
// pide la dificultad de varios niveles en una sola peticion, arg0 es la lista de id.
function scr_get_difficulties_for_levels(arg0)
{
    if (!ds_exists(arg0, ds_type_list) || ds_list_size(arg0) == 0)
        return -1;
    
    var ids_string = "(";
    
    for (var i = 0; i < ds_list_size(arg0); i++)
    {
        if (i > 0)
            ids_string += ",";
        
        ids_string += string(ds_list_find_value(arg0, i));
    }
    
    ids_string += ")";
    var url = global.supabase_url + "/rest/v1/level_difficulty?level_id=in." + ids_string + "&select=level_id,difficulty_score,difficulty_label,confidence,total_sessions";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
function scr_difficulty_get_stars(arg0)
{
    arg0 = scr_clean_json_string(arg0);
    arg0 = string_lower(arg0);
    
    switch (arg0)
    {
        case "easy":
            return 1;
        
        case "normal":
            return 2;
        
        case "hard":
            return 3;
        
        case "very_hard":
            return 4;
        
        case "expert":
            return 5;
        
        case "kaizo":
            return 5;
        
        case "unplayed":
            return 0;
        
        default:
            return 0;
    }
}
function scr_difficulty_is_kaizo(arg0)
{
    arg0 = scr_clean_json_string(arg0);
    return string_lower(arg0) == "kaizo";
}
function scr_difficulty_get_color(arg0)
{
    arg0 = scr_clean_json_string(arg0);
    arg0 = string_lower(arg0);
    
    switch (arg0)
    {
        case "easy":
            return 5299280;
        
        case "normal":
            return 16752720;
        
        case "hard":
            return 46335;
        
        case "very_hard":
            return 5263615;
        
        case "expert":
            return 13107400;
        
        case "kaizo":
            return 200;
        
        case "unplayed":
            return 6579300;
        
        default:
            return 8421504;
    }
}
function scr_difficulty_get_label_text(arg0)
{
    arg0 = scr_clean_json_string(arg0);
    arg0 = string_lower(arg0);
    
    switch (arg0)
    {
        case "easy":
            return "FACIL";
        
        case "normal":
            return "NORMAL";
        
        case "hard":
            return "DIFICIL";
        
        case "very_hard":
            return "MUY DIFICIL";
        
        case "expert":
            return "EXPERTO";
        
        case "kaizo":
            return "KAIZO";
        
        case "unplayed":
            return "SIN DATOS";
        
        default:
            return "???";
    }
}
// marca la dificultad como poco confiable mientras el nivel tenga pocas partidas jugadas.
function scr_difficulty_is_low_confidence(arg0, arg1)
{
    arg0 = scr_clean_json_string(arg0);
    arg0 = string_lower(arg0);
    
    if (arg1 < 10)
        return true;
    
    if (arg0 == "very_low" || arg0 == "low" || arg0 == "none")
        return true;
    
    return false;
}
// dibuja las estrellas. tiene un argumento 7 opcional que no aparece en la firma y es el avance
// de la animacion de aparicion, por defecto arranca ya terminada.
function scr_draw_difficulty_stars(arg0, arg1, arg2, arg3, arg4, arg5)
{
    var anim_prog = (argument_count > 6) ? argument[6] : 5;
    var ext_alpha = draw_get_alpha();
    var stars_filled = scr_difficulty_get_stars(arg2);
    var star_color = scr_difficulty_get_color(arg2);
    var is_kaizo = scr_difficulty_is_kaizo(arg2);
    var low_confidence = scr_difficulty_is_low_confidence(arg3, arg4);
    var total_stars = 5;
    var star_spacing = 12;
    var script_base_alpha = low_confidence ? 0.45 : 1;
    var color_empty = 4275260;
    
    for (var i = 0; i < total_stars; i++)
    {
        var star_anim_mult = clamp((anim_prog - i) / 1.5, 0, 1);
        
        if (star_anim_mult <= 0)
            continue;
        
        var final_alpha = script_base_alpha * star_anim_mult * ext_alpha;
        var sx = arg0 + (i * star_spacing);
        var sy = arg1;
        var is_filled = i < stars_filled;
        
        if (is_filled)
        {
            if (is_kaizo)
            {
                var glow_alpha = 0.3 + (sin((arg5 * 3) + (i * 0.5)) * 0.15);
                draw_sprite_ext(spr_star_favorites, 0, sx - 2, sy - 2, 1.4, 1.4, 0, star_color, glow_alpha * final_alpha);
            }
            
            draw_sprite_ext(spr_star_favorites, 0, sx, sy, 1, 1, 0, star_color, final_alpha);
        }
        else
        {
            draw_sprite_ext(spr_star_favorites, 0, sx, sy, 1, 1, 0, color_empty, 0.3 * final_alpha);
        }
    }
}
