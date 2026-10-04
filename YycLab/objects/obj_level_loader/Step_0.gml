scr_retry_queue_update();
if (!variable_instance_exists(id, "music_started"))
{
    music_started = true;
    if (audio_is_playing(snd_music_Tittlescreen))
    {
        audio_stop_sound(snd_music_Tittlescreen);
    }
    if (!audio_is_playing(snd_level_browser))
    {
        audio_stop_all();
        audio_play_sound(snd_level_browser, 1, true);
    }
    else
    {
        audio_stop_sound(snd_music_Tittlescreen);
    }
}

// cooldwon
if (variable_global_exists("thumb_cooldown") && global.thumb_cooldown > 0)
    global.thumb_cooldown--;
if (variable_instance_exists(id, "tab_cooldown") && tab_cooldown > 0)
    tab_cooldown--;

depth = -50;
var mx = mouse_x;
var my = mouse_y;

if (!variable_instance_exists(id, "request_cooldown"))
    request_cooldown = 0;

if (request_cooldown > 0)
    request_cooldown--;

// si esta abierto, no hacemos nada
if (instance_exists(obj_comments_window))
    exit;

if (instance_exists(obj_user_profile_view))
    exit;

// reinicio de la room
if (pending_room_restart)
{
    restart_delay -= 1;
    
    if (restart_delay <= 0)
    {
        global.thumb_downloading = false;
        global.thumb_current_request = -1;
        ds_list_clear(global.thumb_queue);
        featured_thumb_downloading = false;
        featured_thumb_current_request = -1;
        room_restart();
        exit;
    }
}

if (refresh_cooldown > 0)
    refresh_cooldown--;

// el boton de refrescar
var ref_x = room_width - 45;
var ref_y = header_height - 55;
var ref_r = 16;
refresh_hover = point_distance(mx, my, ref_x, ref_y) < ref_r && !loading && !cleanup_active && refresh_cooldown <= 0;
refresh_hover_progress = lerp(refresh_hover_progress, refresh_hover ? 1 : 0, 0.15);

if (refresh_spinning)
{
    refresh_spin_angle -= 12;
    
    if (refresh_spin_angle <= -360)
    {
        refresh_spin_angle = 0;
        refresh_spinning = false;
    }
}

// refrescar tira todo y vuelve a pedir desde la pagina cero, con un cd de 120 frames pa que no spameen
if (refresh_hover && mouse_check_button_pressed(mb_left))
{
    scr_debug_log("REFRESH: Recargando niveles desde servidor...");
    refresh_spinning = true;
    refresh_spin_angle = 0;
    refresh_cooldown = 120;
    
    if (variable_global_exists("preload_data_ready"))
        global.preload_data_ready = false;
    
    if (variable_global_exists("preloaded_data") && ds_exists(global.preloaded_data, ds_type_list))
        ds_list_clear(global.preloaded_data);
    
    used_preloaded_data = false;
    event_user(0);
}


// pendiente portear la busqueda
if (instance_exists(obj_search_panel))
    exit;

if (cleanup_active && ds_list_size(cleanup_queue) > 0)
{
    for (var cleaned = 0; cleaned < cleanup_per_frame && ds_list_size(cleanup_queue) > 0; cleaned += 1)
    {
        var inst_to_destroy = ds_list_find_value(cleanup_queue, 0);
        ds_list_delete(cleanup_queue, 0);
        
        if (instance_exists(inst_to_destroy))
            instance_destroy(inst_to_destroy);
    }
    
    if (ds_list_size(cleanup_queue) == 0)
    {
        cleanup_active = false;
        
        if (pending_category_change == 0)
        {
            view_mode = 0;
            global.sort = "recent";
            get = scr_supabase_get_levels(global.page, levels_per_page, global.sort, global.name_s, global.autor_s);
        }
        else if (pending_category_change == 1)
        {
            view_mode = 1;
            admin_featured_loading = true;
            request_admin_featured = scr_get_admin_featured_levels();
        }
        else if (pending_category_change == 2)
        {
            view_mode = 2;
            global.sort = "total_likes";
            get = scr_supabase_get_levels(0, levels_per_page, global.sort, "", "");
        }
        else if (pending_category_change == 3)
        {
            view_mode = 3;
            request_hardest = scr_get_hardest_levels(levels_per_page, 0);
        }
        else if (pending_category_change == 5)
        {
            view_mode = 5;
            global.sort = "reported";
            get = scr_supabase_get_reported_levels(0, levels_per_page);
        }
        
        pending_category_change = -1;
    }
    
    exit;
}

// parseo del json
if (variable_instance_exists(id, "parse_pending") && parse_pending && parse_levels_list != -1)
{
    var timer_inicio = get_timer();
    var time_budget = 6000;
    
    while (parse_index < parse_count && (get_timer() - timer_inicio) < time_budget)
    {
        var level_map = ds_list_find_value(parse_levels_list, parse_index);
        var level_id = ds_map_find_value(level_map, "id");
        var level_name = ds_map_find_value(level_map, "name");
        var level_desc = ds_map_find_value(level_map, "description");
        var level_author = ds_map_find_value(level_map, "author_name");
        var level_author_id = ds_map_find_value(level_map, "author_id");
        var level_file_name = ds_map_find_value(level_map, "file_name");
        var level_thumb_name = ds_map_find_value(level_map, "thumbnail_name");
        var level_likes = 0;
        var t_likes = ds_map_find_value(level_map, "total_likes");
        
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
        
        if (is_undefined(tex_used) || tex_used == "null" || tex_used == "")
            tex_used = "vanilla";
        
        if (is_string(level_total_plays) && level_total_plays != "")
            level_total_plays = real(level_total_plays);
        else
            level_total_plays = 0;
        
        if (is_string(level_attempts) && level_attempts != "")
            level_attempts = real(level_attempts);
        else
            level_attempts = 0;
        
        if (is_string(level_victories) && level_victories != "")
            level_victories = real(level_victories);
        else
            level_victories = 0;
        
        if (is_string(level_unique_players) && level_unique_players != "")
            level_unique_players = real(level_unique_players);
        else
            level_unique_players = 0;
        
        if (is_string(level_downloads) && level_downloads != "")
            level_downloads = real(level_downloads);
        else
            level_downloads = 0;
        
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
        
        var tags_raw = ds_map_find_value(level_map, "tags");
        var tags_list_parsed = -1;
        
        if (!is_undefined(tags_raw))
        {
            if (is_string(tags_raw))
                tags_list_parsed = scr_parse_tags_json(tags_raw);
            else
                tags_list_parsed = ds_list_create();
        }
        else
        {
            tags_list_parsed = ds_list_create();
        }
        
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
        else if (_customs_used != "" && !is_string(_customs_used))
        {
            _customs_used = json_stringify(_customs_used);
        }
        
        ds_list_add(global.custom_objects_used_levels, _customs_used);
        ds_list_add(global.tags_levels, tags_list_parsed);
        ds_map_destroy(level_map);
        parse_index++;
    }
    
    if (parse_index >= parse_count)
    {
        ds_list_destroy(parse_levels_list);
        parse_levels_list = -1;
        parse_pending = false;
        total_levels_loaded = ds_list_size(global.id_levels);
        
        if (parse_count < levels_per_page && global.page == 0)
            global.end_of_results = true;
        else if (parse_count < levels_per_load && global.page > 0)
            global.end_of_results = true;
        
        if (!initial_load_complete)
        {
            var initial_cards_to_create = min(8, total_levels_loaded - parse_niveles_antes);
            
            for (var j = parse_niveles_antes; j < (parse_niveles_antes + initial_cards_to_create); j++)
            {
                var check_id = ds_list_find_value(global.id_levels, j);
                
                if (!is_undefined(check_id) && string(check_id) != "")
                {
                    var nueva_tarjeta = instance_create_depth(list_start_x, list_start_y + (j * card_height), 0, obj_level_file);
                    nueva_tarjeta.my_list_index = j;
                    nueva_tarjeta.is_liked = ds_list_find_value(global.is_liked_list, j);
                    nueva_tarjeta.is_admin_featured = ds_list_find_value(global.is_featured_list, j);
                    nueva_tarjeta.visible = false;
                    nueva_tarjeta.fade_alpha = 0;
                    nueva_tarjeta.fading_in = false;
                    ds_list_add(instancias_tarjetas, nueva_tarjeta);
                    ds_list_add(card_appear_queue, nueva_tarjeta);
                    total_cards_created++;
                }
            }
            
            initial_load_complete = true;
            global.difficulties_loaded = true;
            
            // los likes propios no vienen en el listado: el catalogo estatico es
            // el mismo para todos, asi que se piden aparte al terminar de cargar
            if (global.user_logged_in && ds_list_size(global.id_levels) > 0)
                get_likes_request = scr_supabase_get_user_likes(global.id_levels);
            else
                likes_loaded = true;
        }
        
        loading = false;
    }
    
    exit;
}

// las pestañas, la parte de los clicks. el dibujado esta en el draw, aca solo se mira
// donde cayo el mouse
var available_width = room_width - tab_reserved_space;
var total_gaps = tab_gap * (total_tabs - 1);
var single_tab_w = (available_width - total_gaps) / total_tabs;
var current_tab_y = header_height - 30;

for (var i = 0; i < total_tabs; i++)
{
    var tx = i * (single_tab_w + tab_gap);
    var ty = current_tab_y;
    
    if (mx > tx && mx < (tx + single_tab_w) && my > ty && my < (ty + tab_height))
    {
        if (mouse_check_button_pressed(mb_left))
        {
            var target_mode = tabs_data[i][1];
            
            if (view_mode != target_mode && !cleanup_active && tab_cooldown <= 0 && (!variable_instance_exists(id, "spam_message_active") || !spam_message_active))
            {
                tab_cooldown = 36;
                if (target_mode == 1)
                {
                    admin_featured_retry_count = 0;
                    admin_featured_failed = false;
                    admin_featured_retry_timer = 0;
                }
                
                scr_start_category_cleanup(target_mode);
            }
        }
    }
}

// pestaña de reportes, view mode 5
if (variable_global_exists("user_is_admin") && global.user_is_admin)
{
    var admin_tab_x = total_tabs * (single_tab_w + tab_gap);
    var admin_tab_w = 40;
    
    if (mx > admin_tab_x && mx < (admin_tab_x + admin_tab_w) && my > current_tab_y && my < (current_tab_y + tab_height))
    {
        if (mouse_check_button_pressed(mb_left))
        {
            if (view_mode != 5 && !cleanup_active && tab_cooldown <= 0 && (!variable_instance_exists(id, "spam_message_active") || !spam_message_active))
            {
                tab_cooldown = 36;
                scr_start_category_cleanup(5);
            }
        }
    }
}

// si los destacados fallan reintentamos unas veces mas antes de parar (3 veces)
if (view_mode == 1 && admin_featured_failed && admin_featured_retry_count < admin_featured_max_retries)
{
    admin_featured_retry_timer += 1;
    
    if (admin_featured_retry_timer >= admin_featured_retry_delay)
    {
        admin_featured_retry_timer = 0;
        admin_featured_retry_count += 1;
        admin_featured_failed = false;
        admin_featured_loading = true;
        loading = true;
        request_admin_featured = scr_get_admin_featured_levels();
    }
}

// el snapshot del mantenimiento llego con el browser abierto esperando... o se cancelo
if (mantenimiento_esperando_snapshot)
{
    if (global.mantenimiento_activo && scr_maintenance_tiene_snapshot_local())
    {
        mantenimiento_esperando_snapshot = false;
        scr_maintenance_poblar_browser(scr_load_list_cache("mantenimiento_full"));
    }
    else if (!global.mantenimiento_activo)
    {
        // el snapshot no llego o el flag se apago: camino normal
        mantenimiento_esperando_snapshot = false;
        get = scr_supabase_get_levels(global.page, levels_per_page, global.sort, global.name_s, global.autor_s);
    }
}

//  busqueda avanzada
if (view_mode == 4 && !loading && !initial_load_complete)
{
    // en mantenimiento la busqueda se hace local con el snapshot
    if (global.mantenimiento_activo)
    {
        scr_maintenance_aplicar_vista();
        exit;
    }
    
    loading = true;
    request_search = scr_supabase_search_levels(global.page, levels_per_page, global.name_s, global.autor_s, global.search_cr_min, global.search_cr_max, global.search_tags);
}

// los likes de la categoria que se este mirando. si no llegaron se vuelven a pedir
if (!likes_loaded && get_likes_request == -1 && initial_load_complete && !loading && !cleanup_active
    && !global.mantenimiento_activo
    && global.user_logged_in && ds_list_size(global.id_levels) > 0)
{
    get_likes_request = scr_supabase_get_user_likes(global.id_levels);
    
    if (get_likes_request == -1)
        likes_loaded = true;
}

// hay niveles cargados que todavia no tienen tarjeta, se van mandando a la cola de aparicion
if (total_cards_created < total_levels_loaded && !loading && initial_load_complete && !cleanup_active)
{
    var cards_to_create_this_frame = min(1, total_levels_loaded - total_cards_created);
    
    for (var c = 0; c < cards_to_create_this_frame; c++)
    {
        var idx = total_cards_created;
        var check_id = ds_list_find_value(global.id_levels, idx);
        
        if (!is_undefined(check_id) && string(check_id) != "")
        {
            var nueva_tarjeta = instance_create_depth(list_start_x, list_start_y + (idx * card_height), 0, obj_level_file);
            nueva_tarjeta.my_list_index = idx;
            nueva_tarjeta.is_liked = ds_list_find_value(global.is_liked_list, idx);
            nueva_tarjeta.is_admin_featured = ds_list_find_value(global.is_featured_list, idx);
            nueva_tarjeta.visible = false;
            nueva_tarjeta.fade_alpha = 0;
            nueva_tarjeta.fading_in = false;
            ds_list_add(instancias_tarjetas, nueva_tarjeta);
            ds_list_add(card_appear_queue, nueva_tarjeta);
            total_cards_created++;
        }
        else
        {
            total_cards_created++;
        }
    }
}

// las primeras cuatro tarjetas esperan a que la anterior termine de aparecer, de la quinta
// en adelante sale una cada tantos frames sin esperar nada
if (ds_list_size(card_appear_queue) > 0)
{
    var next_card = ds_list_find_value(card_appear_queue, 0);
    
    if (instance_exists(next_card))
    {
        var can_pop = true;
        
        // Si es uno de los primeros 4 niveles (índices 1, 2, 3), debe esperar al anterior
        if (next_card.my_list_index >= 1 && next_card.my_list_index <= 3)
        {
            var prev_card = ds_list_find_value(instancias_tarjetas, next_card.my_list_index - 1);
            
            if (instance_exists(prev_card))
            {
                var prev_finished = (prev_card.visible && !prev_card.fading_in && prev_card.fade_alpha >= 0.99);
                
                if (!prev_finished)
                    can_pop = false;
            }
        }
        
        if (can_pop)
        {
            if (next_card.my_list_index >= 4)
            {
                // A partir de la 5ta tarjeta, se cargan con un delay de 4 frames (staggered)
                card_appear_timer += 1;
                
                if (card_appear_timer >= 4)
                {
                    card_appear_timer = 0;
                    ds_list_delete(card_appear_queue, 0);
                    next_card.allowed_to_appear = true;
                }
            }
            else
            {
                // Para los primeros 4, aparecen secuencialmente de inmediato
                card_appear_timer = 0;
                ds_list_delete(card_appear_queue, 0);
                next_card.allowed_to_appear = true;
            }
        }
    }
    else
    {
        ds_list_delete(card_appear_queue, 0);
    }
}

// cola de miniaturas
if (ds_list_size(global.thumb_queue) > 0)
{
    var max_cached_loads_per_frame = 2;
    var cached_loaded = 0;
    var q_index = 0;
    
    while (q_index < ds_list_size(global.thumb_queue))
    {
        var next_inst = ds_list_find_value(global.thumb_queue, q_index);
        
        if (instance_exists(next_inst))
        {
            if (next_inst.imagen_nivel == -1 && next_inst.imagen_path != "")
            {
                if (file_exists(next_inst.imagen_path))
                {
                    // Cargar sprite en caché inmediatamente (con un presupuesto de 2 por frame para evitar lag)
                    next_inst.imagen_nivel = sprite_add(next_inst.imagen_path, 1, false, false, 0, 0);
                    next_inst.imagen_cargando = false;
                    ds_list_delete(global.thumb_queue, q_index);
                    cached_loaded++;
                    
                    if (cached_loaded >= max_cached_loads_per_frame)
                        break;
                }
                else
                {
                    // Requiere descarga, solo podemos iniciarla si no estamos descargando actualmente
                    if (!global.thumb_downloading && (!variable_global_exists("thumb_cooldown") || global.thumb_cooldown <= 0))
                    {
                        var req = http_get_file(next_inst.thumbnail_url_direct, next_inst.imagen_path);
                        if (req != -1)
                        {
                            global.thumb_downloading = true;
                            global.thumb_current_instance = next_inst;
                            global.thumb_current_request = req;
                            next_inst.thumbnail_download_id = req;
                            next_inst.imagen_cargando = true;
                            ds_list_delete(global.thumb_queue, q_index);
                            break;
                        }
                        else
                        {
                            next_inst.imagen_cargando = false;
                            next_inst.thumb_queued = false;
                            next_inst.thumb_retry_count++;
                            ds_list_delete(global.thumb_queue, q_index);
                        }
                    }
                    else
                    {
                        // Si ya hay una descarga en curso, saltamos este elemento y seguimos procesando sprites en caché
                        q_index++;
                    }
                }
            }
            else
            {
                ds_list_delete(global.thumb_queue, q_index);
            }
        }
        else
        {
            ds_list_delete(global.thumb_queue, q_index);
        }
    }
}

// scroll con la rueda, con el arrastre del dedo y con la inercia despues de soltar
if (mouse_wheel_up())
    scroll_momentum = -20;

if (mouse_wheel_down())
    scroll_momentum = 20;

if (mouse_check_button_pressed(mb_left))
{
    touch_y_start = device_mouse_y_to_gui(0);
    touch_y_prev = touch_y_start;
    scroll_momentum = 0;
}
else if (mouse_check_button(mb_left))
{
    if (touch_y_start != -1)
    {
        var current_gui_y = device_mouse_y_to_gui(0);
        var delta = touch_y_prev - current_gui_y;
        scroll_y += delta;
        touch_y_prev = current_gui_y;
        scroll_momentum = delta;
    }
}
else
{
    touch_y_start = -1;
    
    if (abs(scroll_momentum) > 0.5)
    {
        scroll_y += scroll_momentum;
        scroll_momentum *= 0.92;
    }
    else
    {
        scroll_momentum = 0;
    }
}

// las tarjetas se van acomodando una debajo de la otra
var current_y_pos = list_start_y;
var spacing = 8;
var size_list = ds_list_size(instancias_tarjetas);

for (var i = 0; i < size_list; i++)
{
    var inst = ds_list_find_value(instancias_tarjetas, i);
    
    if (instance_exists(inst))
    {
        inst.x = list_start_x;
        inst.y = current_y_pos - scroll_y;
        current_y_pos += (inst.current_height + spacing);
    }
}

total_content_height = current_y_pos - list_start_y;

// mientras carga se deja lugar de mas abajo para que entre el spinner
if (loading)
    total_content_height += 150;

var view_h = room_height - list_start_y;

if (total_content_height <= view_h)
    scroll_max = 0;
else
    scroll_max = (total_content_height - view_h) + 20;

scroll_y = clamp(scroll_y, 0, scroll_max);

if (scroll_max <= 0)
    scroll_y = 0;

// carga progresiva
// se pide mas cuando el scroll estuvo quieto un rato y falta poco para el final de lo cargado.
// en la pestaña de destacados no corre, esa lista viene entera de una vez
if (progressive_enabled && initial_load_complete && !loading && view_mode != 1)
{
    if (abs(scroll_y - progressive_last_scroll_y) < 2 && abs(scroll_momentum) < 1)
        progressive_idle_timer++;
    else
        progressive_idle_timer = 0;
    
    progressive_last_scroll_y = scroll_y;
    var visible_index = 0;
    var best_visibility = -9999;
    
    for (var i = 0; i < ds_list_size(instancias_tarjetas); i++)
    {
        var inst = ds_list_find_value(instancias_tarjetas, i);
        
        if (instance_exists(inst))
        {
            var card_center_y = inst.y + (inst.current_height / 2);
            var screen_center = list_start_y + (visible_height / 2);
            var visibility = -abs(card_center_y - screen_center);
            
            if (visibility > best_visibility && inst.y > (list_start_y - 50))
            {
                best_visibility = visibility;
                visible_index = i;
            }
        }
    }
    
    if (progressive_idle_timer >= progressive_idle_threshold)
    {
        progressive_load_timer++;
        
        if (progressive_load_timer >= progressive_load_delay)
        {
            progressive_load_timer = 0;
            var target_index = visible_index + progressive_target_ahead;
            
            if (total_cards_created >= (total_levels_loaded - 3) && !global.end_of_results && !progressive_loading && total_levels_loaded < (target_index + 5) && request_cooldown <= 0)
            {
                if (scr_online_request_check_spam())
                {
                    exit;
                }
                
                progressive_loading = true;
                global.page = total_levels_loaded / levels_per_load;
                
                if (view_mode == 0)
                    progressive_request = scr_supabase_get_levels(global.page, levels_per_load, global.sort, global.name_s, global.autor_s);
                else if (view_mode == 2)
                    progressive_request = scr_supabase_get_levels(global.page, levels_per_load, global.sort, "", "");
                else if (view_mode == 3)
                    progressive_request = scr_get_hardest_levels(levels_per_load, global.page * levels_per_load);
                else if (view_mode == 5)
                    progressive_request = scr_supabase_get_reported_levels(global.page, levels_per_load);
            }
        }
    }
}

// el mismo pedido pero cuando se llego al fondo de la lista de una
if (view_mode != 1 && initial_load_complete && !loading && !global.end_of_results)
{
    var visible_bottom = visible_height + 200;
    var last_card_bottom = 0;
    
    if (ds_list_size(instancias_tarjetas) > 0)
    {
        var last_card = ds_list_find_value(instancias_tarjetas, ds_list_size(instancias_tarjetas) - 1);
        
        if (instance_exists(last_card))
            last_card_bottom = last_card.y + last_card.current_height;
    }
    
    if (visible_bottom > last_card_bottom)
    {
        var levels_available = total_levels_loaded - total_cards_created;
        
        if (levels_available <= 0 && !loading && !progressive_loading && request_cooldown <= 0)
        {
            if (scr_online_request_check_spam())
            {
                exit;
            }
            
            if (view_mode == 0)
            {
                global.page = total_levels_loaded / levels_per_load;
                loading = true;
                get = scr_supabase_get_levels(global.page, levels_per_load, global.sort, global.name_s, global.autor_s);
            }
            else if (view_mode == 2)
            {
                global.page = total_levels_loaded / levels_per_load;
                loading = true;
                get = scr_supabase_get_levels(global.page, levels_per_load, global.sort, "", "");
            }
            else if (view_mode == 3)
            {
                global.page = total_levels_loaded / levels_per_load;
                loading = true;
                request_hardest = scr_get_hardest_levels(levels_per_load, global.page * levels_per_load);
            }
        }
    }
}

// la cruz del filtro por autor, saca el filtro y vuelve a pedir
if (view_mode == 0 && global.autor_s != "")
{
    if (mouse_check_button_pressed(mb_left))
    {
        var filter_draw_y = 105 - scroll_y;
        
        if (filter_draw_y > header_height)
        {
            if (mx > 320 && mx < 345 && my > filter_draw_y && my < (filter_draw_y + 30))
            {
                global.autor_s = "";
                event_user(0);
            }
        }
    }
}

// el thumb de la barra de scroll, el alto es proporcional a lo que se ve contra el total
var scrollbar_track_h = room_height - scrollbar_margin_top - scrollbar_margin_bottom;
view_h = room_height - list_start_y;
var total_content = max(total_content_height, 1);

if (total_content <= view_h || scroll_max <= 0)
{
    scrollbar_thumb_height = scrollbar_track_h;
    scrollbar_thumb_y = scrollbar_margin_top;
}
else
{
    var visible_ratio = view_h / total_content;
    visible_ratio = clamp(visible_ratio, 0.08, 1);
    scrollbar_thumb_height = max(scrollbar_track_h * visible_ratio, 30);
    var scroll_ratio = 0;
    
    if (scroll_max > 0)
        scroll_ratio = clamp(scroll_y / scroll_max, 0, 1);
    
    var available_track = scrollbar_track_h - scrollbar_thumb_height;
    scrollbar_thumb_y = scrollbar_margin_top + (available_track * scroll_ratio);
}

var sb_left = scrollbar_x - 4;
var sb_right = scrollbar_x + scrollbar_width + 4;
var sb_top = scrollbar_thumb_y;
var sb_bottom = scrollbar_thumb_y + scrollbar_thumb_height;
scrollbar_hover = mx >= sb_left && mx <= sb_right && my >= sb_top && my <= sb_bottom;
var track_hover = mx >= sb_left && mx <= sb_right && my >= scrollbar_margin_top && my <= (scrollbar_margin_top + scrollbar_track_h);

// arrastre de la barra. el offset guarda desde donde se agarro para que no salte
if (mouse_check_button_pressed(mb_left) && scrollbar_hover && !scrollbar_dragging)
{
    scrollbar_dragging = true;
    scrollbar_drag_offset = my - scrollbar_thumb_y;
}

if (scrollbar_dragging)
{
    if (mouse_check_button(mb_left))
    {
        var available_track = scrollbar_track_h - scrollbar_thumb_height;
        var new_thumb_y = my - scrollbar_drag_offset;
        new_thumb_y = clamp(new_thumb_y, scrollbar_margin_top, scrollbar_margin_top + available_track);
        var new_scroll_ratio = 0;
        
        if (available_track > 0)
            new_scroll_ratio = (new_thumb_y - scrollbar_margin_top) / available_track;
        
        scroll_y = scroll_max * new_scroll_ratio;
        scroll_y = clamp(scroll_y, 0, scroll_max);
        scroll_momentum = 0;
    }
    else
    {
        scrollbar_dragging = false;
    }
}

// click en la pista y no en el thumb, salta directo a esa altura
if (mouse_check_button_pressed(mb_left) && track_hover && !scrollbar_hover && !scrollbar_dragging)
{
    if (scroll_max > 0)
    {
        var click_ratio = clamp((my - scrollbar_margin_top) / scrollbar_track_h, 0, 1);
        scroll_y = scroll_max * click_ratio;
        scroll_y = clamp(scroll_y, 0, scroll_max);
        scroll_momentum = 0;
    }
}

// la barra se muestra mientras se scrollea o hay mouse encima y se apaga sola despues
if (scroll_max > 0 && (abs(scroll_momentum) > 0.5 || scrollbar_hover || scrollbar_dragging || track_hover))
{
    scrollbar_alpha_target = 1;
    scrollbar_fade_timer = scrollbar_fade_delay;
}
else if (scrollbar_fade_timer > 0)
{
    scrollbar_fade_timer--;
}
else
{
    scrollbar_alpha_target = (scroll_max > 0) ? 0.4 : 0;
}

scrollbar_alpha = lerp(scrollbar_alpha, scrollbar_alpha_target, 0.15);

// cuando llega la dificultad se recorren los niveles cargados y se le pasa a cada tarjeta
// su etiqueta, con la animacion de las estrellas en cola
if (global.difficulties_loaded && !global.difficulties_processed)
{
    global.difficulties_processed = true;
    ds_list_clear(difficulty_anim_queue);
    
    for (var i = 0; i < ds_list_size(instancias_tarjetas); i++)
    {
        var inst = ds_list_find_value(instancias_tarjetas, i);
        
        if (instance_exists(inst))
        {
            var is_visible = (inst.y + inst.current_height) > header_height && inst.y < room_height;
            
            if (is_visible)
            {
                ds_list_add(difficulty_anim_queue, inst);
                inst.diff_anim_state = 0;
            }
            else
            {
                inst.diff_anim_state = 2;
            }
        }
    }
    
    difficulty_anim_active = true;
    difficulty_anim_current = -4;
}

// las estrellas aparecen de a un nivel por vez, cuando termina uno sigue el siguiente
if (difficulty_anim_active)
{
    if (difficulty_anim_current == -4 && ds_list_size(difficulty_anim_queue) > 0)
    {
        difficulty_anim_current = ds_list_find_value(difficulty_anim_queue, 0);
        ds_list_delete(difficulty_anim_queue, 0);
        
        if (instance_exists(difficulty_anim_current))
            difficulty_anim_current.diff_anim_state = 1;
    }
    else if (instance_exists(difficulty_anim_current))
    {
        if (difficulty_anim_current.diff_anim_state == 2)
            difficulty_anim_current = -4;
    }
    else
    {
        difficulty_anim_current = -4;
    }
    
    if (ds_list_size(difficulty_anim_queue) == 0 && difficulty_anim_current == -4)
        difficulty_anim_active = false;
}
