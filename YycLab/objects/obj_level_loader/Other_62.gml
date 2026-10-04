// cada scr_async_ mira si el id es suyo y devuelve true, ahi se corta. la cola de reintentos
// va primera para que pueda agarrar la respuesta antes que el resto
if (scr_retry_queue_handle_async(async_load))
    exit;

var request_id = ds_map_find_value(async_load, "id");
var status = ds_map_find_value(async_load, "status");

if (scr_handle_telemetry_async(request_id, status))
    exit;

if (scr_async_discord(request_id, status, async_load))
    exit;

if (scr_async_search_levels(request_id, status, async_load))
    exit;

if (scr_async_get_main(request_id, status, async_load))
    exit;

if (scr_async_admin_featured(request_id, status, async_load))
    exit;

if (scr_async_hardest(request_id, status, async_load))
    exit;

if (scr_async_thumbnail(request_id, status, async_load))
    exit;

if (scr_async_difficulties(request_id, status, async_load))
    exit;

if (scr_async_user_likes(request_id, status, async_load))
    exit;

// los destacados
if (request_id == request_check_featured)
{
    request_check_featured = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        
        if (is_undefined(result) || !is_string(result))
            result = "";
        
        ds_list_clear(admin_featured_ids);
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
                ds_list_add(admin_featured_ids, real(num_str));
        }
    }
}

// la tanda de la carga progresiva
if (variable_instance_exists(id, "progressive_request") && progressive_request != -1 && request_id == progressive_request)
{
    progressive_request = -1;
    progressive_loading = false;
    
    if (status == 0)
    {
// 429 es que se pidio de mas, se frena 10 segundos y se avisa. cualquier otro error frena 5 callado
        var http_status = ds_map_find_value(async_load, "http_status");
        
        if (!is_undefined(http_status) && http_status != 200 && http_status != 206)
        {
            if (http_status == 429)
            {
                request_cooldown = 600;
                show_message_async("SCROLL DEMASIADO RÁPIDO. Espera 10 segundos.");
            }
            else
            {
                request_cooldown = 300;
            }
            
            exit;
        }
        
        var result = ds_map_find_value(async_load, "result");
        
        if (!is_undefined(result) && is_string(result) && result != "" && result != "[]")
        {
// desde donde arranca el step a crear tarjetas
            var niveles_antes = ds_list_size(global.id_levels);
            var levels_list = scr_json_parse_array(result);
            var count = ds_list_size(levels_list);
            
            for (var i = 0; i < count; i++)
            {
                var level_map = ds_list_find_value(levels_list, i);
                var level_id = ds_map_find_value(level_map, "id");
                var level_name = ds_map_find_value(level_map, "name");
                var level_desc = ds_map_find_value(level_map, "description");
                var level_author = ds_map_find_value(level_map, "author_name");
                var level_author_id = ds_map_find_value(level_map, "author_id");
                var level_file_name = ds_map_find_value(level_map, "file_name");
                var level_thumb_name = ds_map_find_value(level_map, "thumbnail_name");
                var level_likes = 0;
                var t_likes = ds_map_find_value(level_map, "total_likes");
                
// los likes pueden venir de tres lados segun que devolvio el server
                if (is_undefined(t_likes) || t_likes == "" || t_likes == "null")
                    t_likes = ds_map_find_value(level_map, "likes");
                
                if (is_undefined(t_likes) || t_likes == "" || t_likes == "null")
                {
                    var likes_data = ds_map_find_value(level_map, "level_likes");
                    
                    if (is_string(likes_data) && likes_data != "")
                    {
                        var num_str = string_digits(likes_data);
                        
                        if (num_str != "")
                            t_likes = num_str;
                    }
                }
                
                if (!is_undefined(t_likes) && t_likes != "" && t_likes != "null")
                {
                    if (is_string(t_likes))
                        level_likes = real(t_likes);
                    else if (is_real(t_likes))
                        level_likes = t_likes;
                }
                
                var level_downloads = ds_map_find_value(level_map, "downloads");
                var level_attempts = ds_map_find_value(level_map, "attempts");
                var level_victories = ds_map_find_value(level_map, "victories");
                var level_unique_players = ds_map_find_value(level_map, "unique_players");
                var level_total_plays = ds_map_find_value(level_map, "total_plays");
                var tex_used = ds_map_find_value(level_map, "texture_used");
                
// si el nivel no dice que textura usa se toma como vanilla
                if (is_undefined(tex_used) || tex_used == "null" || tex_used == "")
                    tex_used = "vanilla";
                
// todo llega como texto, los contadores se pasan a numero aca o el clear rate da cualquier cosa
                if (is_string(level_downloads))
                    level_downloads = real(level_downloads);
                
                if (is_undefined(level_downloads) || level_downloads == "")
                    level_downloads = 0;
                
                if (is_string(level_attempts) && level_attempts != "")
                    level_attempts = real(level_attempts);
                else if (is_undefined(level_attempts) || level_attempts == "")
                    level_attempts = 0;
                
                if (is_string(level_victories) && level_victories != "")
                    level_victories = real(level_victories);
                else if (is_undefined(level_victories) || level_victories == "")
                    level_victories = 0;
                
                if (is_string(level_unique_players) && level_unique_players != "")
                    level_unique_players = real(level_unique_players);
                else if (is_undefined(level_unique_players) || level_unique_players == "")
                    level_unique_players = 0;
                
                if (is_string(level_total_plays) && level_total_plays != "")
                    level_total_plays = real(level_total_plays);
                else if (is_undefined(level_total_plays) || level_total_plays == "")
                    level_total_plays = 0;
                
                var first_clear_user_id = ds_map_find_value(level_map, "first_clear_user_id");
                var first_clear_username = ds_map_find_value(level_map, "first_clear_username");
                
                if (is_undefined(first_clear_user_id) || first_clear_user_id == "null")
                    first_clear_user_id = "";
                
                if (is_undefined(first_clear_username) || first_clear_username == "null")
                    first_clear_username = "";
                
                var level_date = ds_map_find_value(level_map, "created_at");
                
                if (is_undefined(level_date) || !is_string(level_date))
                    level_date = "";
                
                if (string_length(level_date) > 10)
                    level_date = string_copy(level_date, 1, 10);
                
// tags
                var tags_raw = ds_map_find_value(level_map, "tags");
                var tags_list_parsed = ds_list_create();
                
                if (!is_undefined(tags_raw) && is_string(tags_raw))
                    tags_list_parsed = scr_parse_tags_json(tags_raw);
                
// el cold id es el respaldo en tg, se usa cuando r2 no tiene el archivo
                var cold_id = ds_map_find_value(level_map, "cold_storage_id");
                
                if (is_undefined(cold_id) || cold_id == "null" || cold_id == "")
                    cold_id = "";
                
                var _is_liked = ds_map_find_value(level_map, "is_liked_by_me");
                
                if (is_undefined(_is_liked))
                    _is_liked = false;
                
                var _is_featured = ds_map_find_value(level_map, "is_admin_featured");
                
                if (is_undefined(_is_featured))
                    _is_featured = false;
                
                var _diff_label = ds_map_find_value(level_map, "difficulty_label");
                
                if (is_undefined(_diff_label) || _diff_label == "null")
                    _diff_label = "unplayed";
                
                var file_url = scr_r2_get_level_url(level_file_name);
                var thumb_url = scr_r2_get_thumbnail_url(level_thumb_name);
// los add a las listas paralelas. cada uno tiene que tener su par en el clear del user0,
// si falta uno las tarjetas muestran los datos corridos
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
                ds_list_add(global.is_featured_list, _is_featured);
                ds_list_add(global.difficulty_labels, _diff_label);
                ds_list_add(global.is_liked_list, _is_liked);
                ds_list_add(global.attempts_levels, level_attempts);
                ds_list_add(global.victories_levels, level_victories);
                ds_list_add(global.unique_players_levels, level_unique_players);
                ds_list_add(global.total_plays_levels, level_total_plays);
                ds_list_add(global.first_clear_user_ids, first_clear_user_id);
                ds_list_add(global.first_clear_usernames, first_clear_username);
                ds_list_add(global.cold_storage_ids, cold_id);
                
                if (variable_global_exists("texture_used_levels") && ds_exists(global.texture_used_levels, ds_type_list))
                    ds_list_add(global.texture_used_levels, tex_used);
                
                var _customs_used = ds_map_find_value(level_map, "custom_objects_used");
                
                if (is_undefined(_customs_used) || _customs_used == "null")
                    _customs_used = "";
                
                if (is_string(_customs_used) && _customs_used != "")
                {
                    if (string_char_at(_customs_used, 1) == "[" && string_char_at(_customs_used, string_length(_customs_used)) != "]")
                        _customs_used += "]";
                }
                
                ds_list_add(global.custom_objects_used_levels, _customs_used);
                ds_list_add(global.tags_levels, tags_list_parsed);
                ds_map_destroy(level_map);
            }
            
            ds_list_destroy(levels_list);
            total_levels_loaded = ds_list_size(global.id_levels);
            
            if (count < levels_per_load)
                global.end_of_results = true;
            
// llegaron las dificultades
            global.difficulties_loaded = true;
            likes_loaded = true;
        }
        else
        {
            global.end_of_results = true;
        }
    }
}
