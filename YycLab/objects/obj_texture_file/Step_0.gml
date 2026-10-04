if (visible && should_load_thumb == 0)
    should_load_thumb = 1;

if (!visible && !should_load_thumb)
    exit;

var _mx = mouse_x;
var _my = mouse_y;
var _target_height = expanded ? height_expanded : height_collapsed;
current_height += ((_target_height - current_height) * 0.15);

if (variable_instance_exists(id, "heart_scale"))
    heart_scale += ((1 - heart_scale) * 0.15);

if (abs(current_height - _target_height) < 1)
    current_height = _target_height;

if (download_status == "unpacking")
{
    if (!variable_instance_exists(id, "unpack_buffer") || !buffer_exists(unpack_buffer))
    {
        download_status = "error";
        download_error = "Buffer error";
        exit;
    }
    
    var _time_budget = 10000;
    var _start_time = get_timer();
    var _buffer_size = buffer_get_size(unpack_buffer);
    
    while (unpack_index < unpack_count && (get_timer() - _start_time) < _time_budget)
    {
        if ((buffer_tell(unpack_buffer) + 2) > _buffer_size)
        {
            download_status = "error";
            download_error = "Archivo corrupto (EOF)";
            unpacking_textures = false;
            buffer_delete(unpack_buffer);
            exit;
        }
        
        var _name_len = buffer_read(unpack_buffer, buffer_u16);
        
        if (_name_len <= 0 || _name_len > 255)
        {
            download_status = "error";
            download_error = "Nombre invalido";
            unpacking_textures = false;
            buffer_delete(unpack_buffer);
            exit;
        }
        
        if ((buffer_tell(unpack_buffer) + _name_len + 4) > _buffer_size)
        {
            download_status = "error";
            download_error = "Archivo corrupto (EOF Nombre)";
            unpacking_textures = false;
            buffer_delete(unpack_buffer);
            exit;
        }
        
        var _file_name = "";
        
        for (var i = 0; i < _name_len; i++)
            _file_name += chr(buffer_read(unpack_buffer, buffer_u8));
        
        var _file_size = buffer_read(unpack_buffer, buffer_u32);
        
        if ((buffer_tell(unpack_buffer) + _file_size) > _buffer_size)
        {
            download_status = "error";
            download_error = "Archivo corrupto (EOF Datos)";
            unpacking_textures = false;
            buffer_delete(unpack_buffer);
            exit;
        }
        
        var _full_path = unpack_base_dir + _file_name;
        var _dir_part = filename_dir(_full_path);
        
        if (_dir_part != "")
        {
            if (file_exists(_dir_part))
                file_delete(_dir_part);
            
            if (!directory_exists(_dir_part))
                directory_create(_dir_part);
        }
        
        buffer_save_ext(unpack_buffer, _full_path, buffer_tell(unpack_buffer), _file_size);
        buffer_seek(unpack_buffer, buffer_seek_relative, _file_size);
        unpack_index++;
    }
    
    if (unpack_count > 0)
        download_progress = floor((unpack_index / unpack_count) * 100);
    
    if (unpack_index >= unpack_count)
    {
        buffer_delete(unpack_buffer);
        unpack_buffer = -1;
        
        if (file_exists(download_save_path))
            file_delete(download_save_path);
        
        download_status = "installed";
        is_installed = 1;
        downloading = 0;
        download_progress = 100;
        check_install_done = 1;
        installed_path = unpack_base_dir;
		scr_write_workshop_id_after_download(unpack_base_dir, my_index);
        show_debug_message("UNPACK COMPLETE: " + string(unpack_count) + " files.");
    }
    
    exit;
}

if (my_index >= 0 && !author_checked)
{
    author_checked = 1;
    can_delete = 0;
    
    if (variable_global_exists("user_is_admin") && global.user_is_admin)
    {
        can_delete = 1;
    }
    else if (global.user_logged_in)
    {
        if (my_index < ds_list_size(global.texture_author_ids))
        {
            var _t_author_id = ds_list_find_value(global.texture_author_ids, my_index);
            _t_author_id = scr_clean_json_string(_t_author_id);
            
            if (_t_author_id == global.user_id)
                can_delete = 1;
        }
    }
}

if (variable_global_exists("user_is_admin") && global.user_is_admin)
{
    if (!featured_checked && my_index >= 0 && featured_request == -1)
    {
        if (instance_exists(obj_texture_loader) && obj_texture_loader.view_mode == 3)
        {
            is_featured = 1;
            featured_checked = 1;
        }
        else
        {
            var _t_id = ds_list_find_value(global.texture_ids, my_index);
            
            if (_t_id != "" && !is_undefined(_t_id))
                featured_request = scr_check_texture_is_featured(floor(real(_t_id)));
            
            featured_checked = 1;
        }
    }
}

if (my_index >= 0 && !check_install_done && download_status == "")
{
    check_install_done = 1;
    var _t_id = ds_list_find_value(global.texture_ids, my_index);
    var _t_name = ds_list_find_value(global.texture_names, my_index);
    var _safe_name = scr_sanitize_filename(_t_name);
    
    if (_safe_name == "")
        _safe_name = "Item_" + string(_t_id);
    
    var _is_custom = false;
    
    if (variable_global_exists("texture_item_types") && ds_exists(global.texture_item_types, ds_type_list))
    {
        if (my_index < ds_list_size(global.texture_item_types))
        {
            var _type_str = string(ds_list_find_value(global.texture_item_types, my_index));
            
            if (string_pos("custom", _type_str) > 0)
                _is_custom = true;
        }
    }
    
    if (_is_custom)
        _safe_name += ("_id" + string(_t_id));
    
    var _base_path;
    
    if (scr_isWindows())
        _base_path = working_directory + (_is_custom ? "custom/" : "Texturas_manual/");
    else
        _base_path = getDire2("SM4J", _is_custom ? "Custom/custom_objects" : "Texturas_manual") + "/";
    
    installed_path = _base_path + _safe_name;
    
    if (directory_exists(installed_path))
    {
        is_installed = 1;
        download_status = "installed";
    }
}

if (expanded && !descripcion_cargada && my_index >= 0)
{
    if (my_index < ds_list_size(global.texture_descs))
    {
        descripcion = ds_list_find_value(global.texture_descs, my_index);
        
        if (is_undefined(descripcion) || descripcion == "" || descripcion == "null")
            descripcion = "(Sin descripción)";
        
        descripcion_cargada = 1;
    }
}

if (thumb_retry_timer > 0)
{
    thumb_retry_timer--;
    
    if (thumb_retry_timer <= 0 && thumb_retry_count < thumb_max_retries)
    {
        thumb_retry_count++;
        thumb_loading = 0;
        scr_debug_log("THUMB RETRY: Texture " + string(my_index) + " attempt " + string(thumb_retry_count));
    }
}

if (should_load_thumb && !thumb_loaded && !thumb_loading && !thumb_failed)
{
    var _thumb_url = ds_list_find_value(global.texture_thumbs, my_index);
    
    if (_thumb_url == "" || _thumb_url == "null")
    {
        thumb_loaded = 1;
    }
    else
    {
        var _t_id = ds_list_find_value(global.texture_ids, my_index);
        var _cache_name = "texture_thumb_" + string(_t_id) + ".png";
        
        if (file_exists(_cache_name))
        {
            thumb_sprite = sprite_add(_cache_name, 1, false, false, 0, 0);
            
            if (thumb_sprite != -1)
            {
                thumb_loaded = 1;
            }
            else
            {
                file_delete(_cache_name);
                thumb_request = http_get_file(_thumb_url, _cache_name);
                thumb_loading = 1;
            }
        }
        else
        {
            thumb_request = http_get_file(_thumb_url, _cache_name);
            thumb_loading = 1;
        }
    }
}

if (visible && alpha >= 0.5)
{
    var _in_bounds = _mx > x && _mx < (x + width) && _my > y && _my < (y + current_height);
    hovered = _in_bounds;
}
else
{
    hovered = 0;
}

if (like_cooldown > 0)
    like_cooldown--;

if (star_cooldown > 0)
    star_cooldown--;

var _text_x = x + 15 + 100 + 15;
var _stats_y = y + 78;
var _real_heart_x = _text_x;
var _real_heart_y = _stats_y + 6;
var _heart_hitbox_x1 = _real_heart_x - 5;
var _heart_hitbox_y1 = _real_heart_y - 10;
var _heart_hitbox_x2 = _real_heart_x + heart_size + 35;
var _heart_hitbox_y2 = _real_heart_y + 18;
like_hover = _mx > _heart_hitbox_x1 && _mx < _heart_hitbox_x2 && _my > _heart_hitbox_y1 && _my < _heart_hitbox_y2 && visible && alpha >= 0.8;

if (like_request == -1 && like_cooldown <= 0 && visible)
{
    var _t_id = ds_list_find_value(global.texture_ids, my_index);
    var _t_id_str = string(floor(real(_t_id)));
    is_liked = 0;
    
    if (variable_global_exists("my_texture_likes") && ds_exists(global.my_texture_likes, ds_type_list))
    {
        var _list_size = ds_list_size(global.my_texture_likes);
        
        for (var i = 0; i < _list_size; i++)
        {
            var _liked_id = ds_list_find_value(global.my_texture_likes, i);
            
            if (string(floor(real(_liked_id))) == _t_id_str)
            {
                is_liked = 1;
                break;
            }
        }
    }
}

if (like_hover && mouse_check_button_pressed(mb_left) && like_request == -1 && like_cooldown <= 0)
{
    if (!global.user_logged_in)
    {
        show_message_async("Debes iniciar sesión para dar like");
    }
    else
    {
        if (variable_instance_exists(id, "heart_scale"))
            heart_scale = 1.6;
        
        like_cooldown = 30;
        global.likes_operation_pending = 1;
        var _t_id = ds_list_find_value(global.texture_ids, my_index);
        var _texture_id_num = floor(real(_t_id));
        var _t_id_str = string(_texture_id_num);
        
        if (is_liked)
        {
            like_request = scr_texture_remove_like(_texture_id_num);
            
            for (var i = 0; i < ds_list_size(global.my_texture_likes); i++)
            {
                if (string(floor(real(ds_list_find_value(global.my_texture_likes, i)))) == _t_id_str)
                {
                    ds_list_delete(global.my_texture_likes, i);
                    break;
                }
            }
            
            var _current_likes = real(ds_list_find_value(global.texture_likes, my_index));
            ds_list_replace(global.texture_likes, my_index, string(max(0, _current_likes - 1)));
            is_liked = 0;
        }
        else
        {
            like_request = scr_texture_add_like(_texture_id_num);
            ds_list_add(global.my_texture_likes, _t_id_str);
            var _current_likes = real(ds_list_find_value(global.texture_likes, my_index));
            ds_list_replace(global.texture_likes, my_index, string(_current_likes + 1));
            is_liked = 1;
        }
    }
}

autor_hover = 0;

if (visible && alpha >= 0.8 && my_index >= 0)
{
    var _thumb_size = 100;
    var _text_x_autor = x + 15 + _thumb_size + 15;
    var _autor_y = y + 38;
    var _t_author = ds_list_find_value(global.texture_authors, my_index);
    var _autor_text = "por: " + string_lower(string(_t_author));
    draw_set_font(global.font);
    var _autor_w = string_width(_autor_text) + 10;
    var _autor_h = 18;
    
    if (_mx > _text_x_autor && _mx < (_text_x_autor + _autor_w) && _my > _autor_y && _my < (_autor_y + _autor_h))
        autor_hover = 1;
}

if (mouse_check_button_pressed(mb_left) && visible && alpha >= 0.8 && my_index >= 0)
{
    var _thumb_size = 100;
    var _text_x_autor = x + 15 + _thumb_size + 15;
    var _autor_y = y + 38;
    var _t_author = ds_list_find_value(global.texture_authors, my_index);
    var _autor_text = "por: " + string_lower(string(_t_author));
    draw_set_font(global.font);
    var _autor_w = string_width(_autor_text) + 10;
    var _autor_h = 18;
    
    if (_mx > _text_x_autor && _mx < (_text_x_autor + _autor_w) && _my > _autor_y && _my < (_autor_y + _autor_h))
    {
        var _t_author_id = "";
        
        if (my_index < ds_list_size(global.texture_author_ids))
            _t_author_id = ds_list_find_value(global.texture_author_ids, my_index);
        
        _t_author_id = scr_clean_json_string(_t_author_id);
        
        if (_t_author_id != "" && !is_undefined(_t_author_id) && _t_author_id != "null")
        {
            if (!instance_exists(obj_user_profile_view))
            {
                var _profile_view = instance_create_depth(0, 0, 0, obj_user_profile_view);
                _profile_view.target_user_id = _t_author_id;
                _profile_view.target_username = _t_author;
                
                with (_profile_view)
                    event_user(0);
                
                exit;
            }
        }
    }
}

download_btn_w = 140;
download_btn_h = 36;
download_btn_x = (x + width) - download_btn_w - 15;
download_btn_y = (y + current_height) - download_btn_h - 15;
comments_btn_size = download_btn_h;
comments_btn_x = download_btn_x - comments_btn_size - 15;
comments_btn_y = download_btn_y;
delete_btn_size = 28;
delete_btn_x = x + 15;
delete_btn_y = (y + current_height) - delete_btn_size - 15;
star_btn_size = 28;
star_btn_x = delete_btn_x + delete_btn_size + 10;
star_btn_y = delete_btn_y;
hover_button = 0;

if (expanded && current_height > (height_collapsed + 20))
{
    if (_mx > download_btn_x && _mx < (download_btn_x + download_btn_w) && _my > download_btn_y && _my < (download_btn_y + download_btn_h))
        hover_button = 1;
}

hover_comments = 0;

if (expanded && current_height > (height_collapsed + 20))
{
    if (_mx > comments_btn_x && _mx < (comments_btn_x + comments_btn_size) && _my > comments_btn_y && _my < (comments_btn_y + comments_btn_size))
        hover_comments = 1;
}

hover_delete = 0;

if (expanded && current_height > (height_collapsed + 20) && can_delete)
{
    if (_mx > delete_btn_x && _mx < (delete_btn_x + delete_btn_size) && _my > delete_btn_y && _my < (delete_btn_y + delete_btn_size))
        hover_delete = 1;
}

hover_star = 0;

if (variable_global_exists("user_is_admin") && global.user_is_admin)
{
    if (expanded && current_height > (height_collapsed + 20))
    {
        if (_mx > star_btn_x && _mx < (star_btn_x + star_btn_size) && _my > star_btn_y && _my < (star_btn_y + star_btn_size))
            hover_star = 1;
    }
    
    if (hover_star)
    {
        show_tooltip = 1;
        tooltip_text = is_featured ? "Quitar de destacados" : "Agregar a destacados";
        tooltip_alpha = min(tooltip_alpha + 0.15, 1);
    }
    else
    {
        tooltip_alpha = max(tooltip_alpha - 0.15, 0);
        
        if (tooltip_alpha <= 0)
            show_tooltip = 0;
    }
    
    if (hover_star && mouse_check_button_pressed(mb_left) && toggle_featured_request == -1 && star_cooldown <= 0)
    {
        star_cooldown = 45;
        var _t_id = ds_list_find_value(global.texture_ids, my_index);
        toggle_featured_request = scr_toggle_texture_featured(floor(real(_t_id)), is_featured);
        is_featured = !is_featured;
    }
}

if (expanded && !tags_loaded && my_index >= 0)
{
    tags_loaded = 1;
    
    if (variable_global_exists("texture_tags") && ds_exists(global.texture_tags, ds_type_list))
    {
        if (my_index < ds_list_size(global.texture_tags))
        {
            var _source_tags = ds_list_find_value(global.texture_tags, my_index);
            
            if (ds_exists(_source_tags, ds_type_list))
                ds_list_copy(my_tags, _source_tags);
        }
    }
}

if (hover_delete && mouse_check_button_pressed(mb_left) && delete_request == -1 && !delete_pending)
{
    delete_pending = 1;
    var _t_name = ds_list_find_value(global.texture_names, my_index);
    show_question_async("¿Seguro que quieres ELIMINAR el item '" + string(_t_name) + "'?#Esta acción NO se puede deshacer.");
}

if (hover_comments && mouse_check_button_pressed(mb_left) && !instance_exists(obj_comments_window))
{
    var _t_id = ds_list_find_value(global.texture_ids, my_index);
    var _t_name = ds_list_find_value(global.texture_names, my_index);
    var _win = instance_create_depth(0, 0, -100, obj_comments_window);
    _win.content_type = 2;
    _win.content_id = floor(real(_t_id));
    _win.content_name = _t_name;
    _win.level_id = floor(real(_t_id));
    _win.level_name = _t_name;
    _win.request_comments = scr_get_texture_comments(_win.content_id, _win.comments_per_page, 0);
    _win.request_count = scr_get_texture_comment_count(_win.content_id);
}

var _clicking_other = 0;

if (mouse_check_button_pressed(mb_left) && hovered && visible && alpha >= 0.8)
{
    _clicking_other = 0;
    
    if (like_hover || autor_hover)
        _clicking_other = 1;
    
    if (expanded)
    {
        if (hover_comments || hover_delete || hover_star)
            _clicking_other = 1;
        
        if (hover_button)
        {
            _clicking_other = 1;
            
            if (download_status == "installed")
            {
                show_message_async("Este item ya está instalado");
            }
            else if (download_status == "" || download_status == "error")
            {
                downloading = 1;
                download_status = "downloading";
                download_error = "";
                download_progress = 0;
                download_start_time = current_time;
                var _t_id = ds_list_find_value(global.texture_ids, my_index);
                var _t_name = ds_list_find_value(global.texture_names, my_index);
                var _t_cold_id = "";
                
                if (variable_global_exists("texture_cold_storage_ids") && ds_exists(global.texture_cold_storage_ids, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_cold_storage_ids))
                    {
                        _t_cold_id = ds_list_find_value(global.texture_cold_storage_ids, my_index);
                        
                        if (is_undefined(_t_cold_id) || string_pos("null", _t_cold_id) > 0)
                            _t_cold_id = "";
                    }
                }
                
                var _t_github_url = "";
                
                if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_github_urls))
                        _t_github_url = ds_list_find_value(global.texture_github_urls, my_index);
                }
                
                var _safe_name = scr_sanitize_filename(_t_name);
                
                if (_safe_name == "")
                    _safe_name = "Item_" + string(_t_id);
                
                var _is_custom = false;
                
                if (variable_global_exists("texture_item_types") && ds_exists(global.texture_item_types, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_item_types))
                    {
                        var _type_str = string(ds_list_find_value(global.texture_item_types, my_index));
                        
                        if (string_pos("custom", _type_str) > 0)
                            _is_custom = true;
                    }
                }
                
                if (_is_custom)
                    _safe_name += ("_id" + string(_t_id));
                
                var _save_dir;
                
                if (scr_isWindows())
                    _save_dir = working_directory + (_is_custom ? "custom/" : "Texturas_manual/");
                else
                    _save_dir = getDire2("SM4J", _is_custom ? "Custom/custom_objects" : "Texturas_manual") + "/";
                
                if (!directory_exists(_save_dir))
                    directory_create(_save_dir);
                
                var _t_file = ds_list_find_value(global.texture_files, my_index);
                download_save_path = _save_dir + _safe_name + ".simplepack";
                download_source = "";
                scr_debug_log("=== ITEM DOWNLOAD START ===");
                scr_debug_log("Item: " + string(_t_name) + " | Type: " + (_is_custom ? "Custom" : "Texture"));
                scr_debug_log("cold_storage_id: " + string(_t_cold_id));
                scr_debug_log("file_name: " + string(_t_file));
                
                if (_t_cold_id != "")
                {
                    scr_debug_log("Usando bridge para descarga...");
                    download_source = "bridge";
                    request_bridge_download = scr_request_texture_download_url(_t_file, _t_cold_id);
                }
                else if (_t_github_url != "" && _t_github_url != "null")
                {
                    scr_debug_log("Fallback a GitHub proxy...");
                    download_source = "github";
                    var _proxy_url = global.worker_textures_url + "/?url=" + _t_github_url;
                    download_request = http_get_file(_proxy_url, download_save_path);
                }
                else
                {
                    downloading = 0;
                    download_status = "error";
                    download_error = "URL no disponible";
                    scr_debug_log("ERROR: Sin cold_storage_id ni github_url");
                }
                
                var _current_downloads = real(ds_list_find_value(global.texture_downloads, my_index));
                ds_list_replace(global.texture_downloads, my_index, string(_current_downloads + 1));
                scr_increment_texture_download(floor(real(_t_id)));
            }
        }
    }
    
    if (!_clicking_other)
    {
        if (!expanded)
        {
            with (obj_texture_file)
            {
                if (id != other.id)
                    expanded = 0;
            }
            
            expanded = 1;
        }
        else if (_my < (y + height_collapsed))
        {
            expanded = 0;
        }
    }
}
