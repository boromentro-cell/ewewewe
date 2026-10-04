var _mx = mouse_x;
var _my = mouse_y;

if (!load_started)
{
    load_delay -= 1;
    
    if (load_delay <= 0)
    {
        load_started = 1;
        scr_texture_loader_start_loading();
    }
    
    exit;
}

if (load_phase < 2 || parsing_active || featured_textures_loading)
{
    loading_timer += 1;
    
    if (loading_timer >= 20)
    {
        loading_timer = 0;
        loading_dots += 1;
        
        if (loading_dots > 3)
            loading_dots = 0;
    }
}

if (textures_loaded && !likes_loaded && load_phase < 2)
    load_phase_text = "cargando likes...";

if (parsing_active && ds_exists(parsed_textures_list, ds_type_list))
{
    var _textures_to_parse = min(3, ds_list_size(parsed_textures_list) - parsing_index);
    var _start_index = ds_list_size(global.texture_ids);
    
    for (var p = 0; p < _textures_to_parse; p++)
    {
        if (parsing_index >= ds_list_size(parsed_textures_list))
            break;
        
        var _map = ds_list_find_value(parsed_textures_list, parsing_index);
        var _t_id = scr_clean_json_string(ds_map_find_value(_map, "id"));
        var _t_name = scr_clean_json_string(ds_map_find_value(_map, "name"));
        var _t_auth = scr_clean_json_string(ds_map_find_value(_map, "author_name"));
        var _t_auth_id = scr_clean_json_string(ds_map_find_value(_map, "author_id"));
        var _t_desc = scr_clean_json_string(ds_map_find_value(_map, "description"));
        var _t_file = scr_clean_json_string(ds_map_find_value(_map, "file_name"));
        var _t_thumb = scr_clean_json_string(ds_map_find_value(_map, "thumbnail_name"));
        var _t_likes = scr_clean_json_string(ds_map_find_value(_map, "likes"));
        var _t_dl = scr_clean_json_string(ds_map_find_value(_map, "downloads"));
        var _t_date = scr_clean_json_string(ds_map_find_value(_map, "created_at"));
        var _t_gh_url = scr_clean_json_string(ds_map_find_value(_map, "github_download_url"));
        ds_list_add(global.texture_ids, _t_id);
        ds_list_add(global.texture_names, _t_name);
        ds_list_add(global.texture_authors, _t_auth);
        ds_list_add(global.texture_author_ids, _t_auth_id);
        ds_list_add(global.texture_descs, _t_desc);
        ds_list_add(global.texture_files, _t_file);
        var _thumb_url = "";
        
        if (_t_thumb != "" && _t_thumb != "null")
            _thumb_url = scr_r2_get_thumbnail_url(_t_thumb);
        
        ds_list_add(global.texture_thumbs, _thumb_url);
        ds_list_add(global.texture_likes, _t_likes);
        ds_list_add(global.texture_downloads, _t_dl);
        ds_list_add(global.texture_dates, _t_date);
        var _t_github_url = scr_clean_json_string(ds_map_find_value(_map, "github_download_url"));
        ds_list_add(global.texture_github_urls, _t_github_url);
        var _t_cold_id = scr_clean_json_string(ds_map_find_value(_map, "cold_storage_id"));
        
        if (_t_cold_id == "null" || is_undefined(_t_cold_id))
            _t_cold_id = "";
        
        ds_list_add(global.texture_cold_storage_ids, _t_cold_id);
        var _t_item_type = scr_clean_json_string(ds_map_find_value(_map, "item_type"));
        
        if (_t_item_type == "null" || is_undefined(_t_item_type) || _t_item_type == "")
            _t_item_type = "texture";
        
        ds_list_add(global.texture_item_types, _t_item_type);
        var _t_tags_raw = ds_map_find_value(_map, "tags");
        var _t_tags_list = ds_list_create();
        
        if (!is_undefined(_t_tags_raw) && _t_tags_raw != "" && _t_tags_raw != "null" && _t_tags_raw != 0)
        {
            var _tags_str = string(_t_tags_raw);
            
            if (string_char_at(_tags_str, 1) == "[")
                _tags_str = string_copy(_tags_str, 2, string_length(_tags_str) - 2);
            
            if (string_char_at(_tags_str, 1) == "{")
                _tags_str = string_copy(_tags_str, 2, string_length(_tags_str) - 2);
            
            var _temp_tags = _tags_str;
            
            while (string_length(_temp_tags) > 0)
            {
                var _comma_pos = string_pos(",", _temp_tags);
                var _tag_val = "";
                
                if (_comma_pos > 0)
                {
                    _tag_val = string_copy(_temp_tags, 1, _comma_pos - 1);
                    _temp_tags = string_copy(_temp_tags, _comma_pos + 1, string_length(_temp_tags) - _comma_pos);
                }
                else
                {
                    _tag_val = _temp_tags;
                    _temp_tags = "";
                }
                
                _tag_val = string_replace_all(_tag_val, "\"", "");
                _tag_val = string_replace_all(_tag_val, "'", "");
                
                while (string_length(_tag_val) > 0 && string_char_at(_tag_val, 1) == " ")
                    _tag_val = string_copy(_tag_val, 2, string_length(_tag_val) - 1);
                
                while (string_length(_tag_val) > 0 && string_char_at(_tag_val, string_length(_tag_val)) == " ")
                    _tag_val = string_copy(_tag_val, 1, string_length(_tag_val) - 1);
                
                if (_tag_val != "")
                    ds_list_add(_t_tags_list, _tag_val);
            }
        }
        
        ds_list_add(global.texture_tags, _t_tags_list);
        ds_map_destroy(_map);
        parsing_index += 1;
    }
    
    var _end_index = ds_list_size(global.texture_ids);
    
    for (var k = _start_index; k < _end_index; k++)
        ds_list_add(cards_creation_queue, k);
    
    if (parsing_index >= ds_list_size(parsed_textures_list))
    {
        ds_list_destroy(parsed_textures_list);
        parsed_textures_list = -1;
        parsing_active = 0;
        parsing_index = 0;
        textures_loaded = 1;
        textures_retry_count = 0;
        load_phase = 1;
        load_phase_text = "creando tarjetas...";
    }
}

if (likes_loaded && ds_exists(cards_creation_queue, ds_type_list) && !ds_list_empty(cards_creation_queue))
{
    for (var _cards_created_this_frame = 0; !ds_list_empty(cards_creation_queue) && _cards_created_this_frame < cards_per_frame; _cards_created_this_frame++)
    {
        var _index_to_create = ds_list_find_value(cards_creation_queue, 0);
        ds_list_delete(cards_creation_queue, 0);
        var _new_card = instance_create_depth(0, 0, 0, obj_texture_file);
        _new_card.my_index = _index_to_create;
        _new_card.width = 550;
        _new_card.height_collapsed = 130;
        _new_card.current_height = 130;
        _new_card.visible = false;
        
        if (ds_exists(instancias_tarjetas, ds_type_list))
            ds_list_add(instancias_tarjetas, _new_card);
    }
    
    if (ds_list_empty(cards_creation_queue))
    {
        load_phase = 2;
        load_phase_text = "";
        featured_textures_loading = 0;
    }
}

var _current_y_draw = list_start_y - scroll_y;
var _total_height_acc = list_start_y;
var _card_x = (room_width - 550) / 2;

if (ds_exists(instancias_tarjetas, ds_type_list))
{
    var _size = ds_list_size(instancias_tarjetas);
    
    for (var i = 0; i < _size; i++)
    {
        var _card = ds_list_find_value(instancias_tarjetas, i);
        
        if (instance_exists(_card))
        {
            _card.x = _card_x;
            _card.y = _current_y_draw;
            
            if (_card.alpha < 1)
                _card.alpha = min(_card.alpha + 0.1, 1);
            
            if ((_card.y + _card.current_height) < -50 || _card.y > (room_height + 50))
                _card.visible = false;
            else
                _card.visible = true;
            
            var _espacio_ocupado = _card.current_height + card_spacing;
            _current_y_draw += _espacio_ocupado;
            _total_height_acc += _espacio_ocupado;
        }
    }
}

var _total_content_h = _total_height_acc + 50;
var _view_h = room_height;

if (_total_content_h > _view_h)
    scroll_max = _total_content_h - _view_h;
else
    scroll_max = 0;

if (scroll_max > 0)
{
    if (mouse_wheel_down())
        scroll_y = min(scroll_y + 40, scroll_max);
    
    if (mouse_wheel_up())
        scroll_y = max(scroll_y - 40, 0);

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
}
else
{
    scroll_y = 0;
}

if (mouse_check_button_pressed(mb_left))
{
    var _btn_y_real = btn_y - scroll_y;
    var _btn_back_y_real = btn_back_y - scroll_y;
    
    if (_btn_y_real > -btn_h)
    {
        var _cat_x = 20;
        
        for (var _cat_i = 0; _cat_i < 4; _cat_i++)
        {
            if (_mx > _cat_x && _mx < (_cat_x + btn_w) && _my > _btn_y_real && _my < (_btn_y_real + btn_h))
            {
                if (view_mode != _cat_i)
                {
                    view_mode = _cat_i;
                    scroll_y = 0;
                    
                    if (ds_exists(instancias_tarjetas, ds_type_list))
                    {
                        var _list_size = ds_list_size(instancias_tarjetas);
                        
                        for (var k = 0; k < _list_size; k++)
                        {
                            var _inst = ds_list_find_value(instancias_tarjetas, k);
                            
                            if (instance_exists(_inst))
                                instance_destroy(_inst);
                        }
                        
                        ds_list_clear(instancias_tarjetas);
                    }
                    
                    if (ds_exists(cards_creation_queue, ds_type_list))
                        ds_list_clear(cards_creation_queue);
                    
                    parsing_active = 0;
                    parsing_index = 0;
                    
                    if (variable_instance_exists(id, "parsed_textures_list") && ds_exists(parsed_textures_list, ds_type_list))
                    {
                        ds_list_destroy(parsed_textures_list);
                        parsed_textures_list = -1;
                    }
                    
                    current_page = 0;
                    has_more = 1;
                    
                    if (_cat_i == 3)
                    {
                        scr_texture_loader_start_loading_featured();
                    }
                    else
                    {
                        if (_cat_i == 0)
                            current_sort = "recent";
                        else if (_cat_i == 1)
                            current_sort = "likes";
                        else
                            current_sort = "downloads";
                        
                        scr_texture_loader_start_loading();
                    }
                }
                
                break;
            }
            
            _cat_x += (btn_w + 8);
        }
    }
    
    if (_btn_back_y_real > -btn_back_h)
    {
        var _back_hover = _mx > btn_back_x && _mx < (btn_back_x + btn_back_w) && _my > _btn_back_y_real && _my < (_btn_back_y_real + btn_back_h);
        
        if (_back_hover)
            room_goto_previous();
    }
}

if (textures_retry_timer > 0)
{
    textures_retry_timer -= 1;
    
    if (textures_retry_timer <= 0 && textures_retry_count < textures_max_retries)
    {
        textures_retry_count += 1;
        
        if (view_mode == 5)
            request_textures = scr_supabase_search_textures(current_page, items_per_page, global.texture_search_name, global.texture_search_author, global.texture_search_tags);
        else if (view_mode == 3)
            request_featured_textures = scr_get_featured_textures(items_per_page, current_page * items_per_page);
        else
            request_textures = scr_supabase_get_textures(current_page, items_per_page, current_sort, search_text);
    }
}

if (likes_retry_timer > 0)
{
    likes_retry_timer -= 1;
    
    if (likes_retry_timer <= 0 && likes_retry_count < likes_max_retries)
    {
        likes_retry_count += 1;
        request_my_likes = scr_get_my_texture_likes();
    }
}

if (load_phase == 0)
{
    var _queue_empty = 1;
    
    if (ds_exists(cards_creation_queue, ds_type_list))
        _queue_empty = ds_list_empty(cards_creation_queue);
    
    var _instances_empty = 1;
    
    if (ds_exists(instancias_tarjetas, ds_type_list))
        _instances_empty = ds_list_size(instancias_tarjetas) == 0;
    
    if (textures_loaded && likes_loaded && _queue_empty && _instances_empty && !parsing_active)
    {
        if (ds_exists(global.texture_ids, ds_type_list) && ds_list_size(global.texture_ids) == 0)
        {
            load_phase = 2;
            load_phase_text = "";
        }
    }
}

if (view_mode != 3 && view_mode != 5 && has_more && load_phase >= 2 && !parsing_active)
{
    var _queue_is_empty = 0;
    
    if (ds_exists(cards_creation_queue, ds_type_list))
        _queue_is_empty = ds_list_empty(cards_creation_queue);
    
    if (_queue_is_empty)
    {
        if (scroll_max > 0 && scroll_y >= (scroll_max - 50) && request_textures == -1)
        {
            current_page += 1;
            request_textures = scr_supabase_get_textures(current_page, items_per_page, current_sort, search_text);
        }
    }
}

if (view_mode == 3 && has_more && load_phase >= 2 && !featured_textures_loading && !parsing_active)
{
    var _queue_is_empty = 0;
    
    if (ds_exists(cards_creation_queue, ds_type_list))
        _queue_is_empty = ds_list_empty(cards_creation_queue);
    
    if (_queue_is_empty)
    {
        if (scroll_max > 0 && scroll_y >= (scroll_max - 50) && request_featured_textures == -1)
        {
            current_page += 1;
            request_featured_textures = scr_get_featured_textures(items_per_page, current_page * items_per_page);
        }
    }
}

if (view_mode == 5 && has_more && load_phase >= 2 && !parsing_active)
{
    var _queue_is_empty = 0;
    
    if (ds_exists(cards_creation_queue, ds_type_list))
        _queue_is_empty = ds_list_empty(cards_creation_queue);
    
    if (_queue_is_empty)
    {
        if (scroll_max > 0 && scroll_y >= (scroll_max - 50) && request_textures == -1)
        {
            current_page += 1;
            request_textures = scr_supabase_search_textures(current_page, items_per_page, global.texture_search_name, global.texture_search_author, global.texture_search_tags);
        }
    }
}
