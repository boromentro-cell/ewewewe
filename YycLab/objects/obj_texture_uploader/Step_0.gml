#region Android File Picking Step Logic
if (os_type == os_android && android_picking)
{
    var mx = mouse_x;
    var my = mouse_y;
    var panel_w = 400;
    var panel_h = 300;
    var panel_x = (room_width - panel_w) / 2;
    var panel_y = (room_height - panel_h) / 2;
    
    if (mouse_check_button_pressed(mb_left))
    {
        // Cancel button
        if (mx > (room_width / 2 - 60) && mx < (room_width / 2 + 60) && my > (panel_y + panel_h - 40) && my < (panel_y + panel_h - 10))
        {
            android_picking = false;
            if (ds_exists(android_file_list, ds_type_list))
            {
                ds_list_destroy(android_file_list);
                android_file_list = -1;
            }
            exit;
        }
        
        // Scroll buttons
        var list_size = ds_list_size(android_file_list);
        if (list_size > 5)
        {
            if (mx > (panel_x + panel_w - 30) && mx < (panel_x + panel_w - 10))
            {
                if (my > (panel_y + 60) && my < (panel_y + 90))
                {
                    android_scroll = max(android_scroll - 1, 0);
                }
                if (my > (panel_y + 180) && my < (panel_y + 210))
                {
                    android_scroll = min(android_scroll + 1, list_size - 5);
                }
            }
        }
        
        // List item selection
        var display_count = min(5, list_size - android_scroll);
        for (var i = 0; i < display_count; i++)
        {
            var y_pos = panel_y + 60 + (i * 35);
            if (mx > (panel_x + 10) && mx < (panel_x + panel_w - 10) && my > y_pos && my < (y_pos + 30))
            {
                var idx = android_scroll + i;
                var selected_path = ds_list_find_value(android_file_list, idx);
                
                // Set texture paths and load configuration name
                texture_folder_path = selected_path;
                var config_file = selected_path + "/config.txt";
                var preview_file = "";
                
                // Scan the folder for the first PNG image to use as preview/icon
                var png_found = file_find_first(selected_path + "/*.png", 0);
                if (png_found != "")
                {
                    preview_file = selected_path + "/" + png_found;
                    file_find_close();
                }
                
                if (preview_file != "")
                {
                    texture_image_path = preview_file;
                    if (preview_sprite != -1 && sprite_exists(preview_sprite))
                        sprite_delete(preview_sprite);
                    preview_sprite = sprite_add(preview_file, 1, false, false, 0, 0);
                }
                
                // Parse configuration name
                var folder_name = filename_name(selected_path);
                if (folder_name == "") folder_name = "Item";
                texture_name = folder_name;
                
                var _is_custom = string_pos("custom", item_type) > 0;
                if (_is_custom)
                {
                    var _found_parent = "generic";
                    if (file_exists(config_file))
                    {
                        var _f = file_text_open_read(config_file);
                        while (!file_text_eof(_f))
                        {
                            var _line = file_text_readln(_f);
                            if (string_pos("name", string_lower(_line)) > 0 && string_pos("=", _line) > 0)
                            {
                                var _eq = string_pos("=", _line);
                                var _val = string_copy(_line, _eq + 1, string_length(_line) - _eq);
                                _val = string_replace_all(string_replace_all(_val, "\n", ""), "\r", "");
                                while (string_length(_val) > 0 && string_char_at(_val, 1) == " ") _val = string_copy(_val, 2, string_length(_val) - 1);
                                while (string_length(_val) > 0 && string_char_at(_val, string_length(_val)) == " ") _val = string_copy(_val, 1, string_length(_val) - 1);
                                if (_val != "") texture_name = _val;
                            }
                            if (string_pos("parent", string_lower(_line)) > 0 && string_pos("=", _line) > 0)
                            {
                                var _eq = string_pos("=", _line);
                                var _val = string_copy(_line, _eq + 1, string_length(_line) - _eq);
                                _val = string_lower(string_replace_all(string_replace_all(_val, "\n", ""), "\r", ""));
                                while (string_length(_val) > 0 && string_char_at(_val, 1) == " ") _val = string_copy(_val, 2, string_length(_val) - 1);
                                while (string_length(_val) > 0 && string_char_at(_val, string_length(_val)) == " ") _val = string_copy(_val, 1, string_length(_val) - 1);
                                if (_val != "") _found_parent = _val;
                            }
                        }
                        file_text_close(_f);
                    }
                    item_type = "custom_" + _found_parent;
                }
                
                estado = 1;
                campo_activo = 1;
                
                android_picking = false;
                if (ds_exists(android_file_list, ds_type_list))
                {
                    ds_list_destroy(android_file_list);
                    android_file_list = -1;
                }
                break;
            }
        }
    }
    exit;
}
#endregion

var mx = mouse_x;
var my = mouse_y;

if (estado == 1)
{
    if (campo_activo != campo_activo_prev)
    {
        if (campo_activo > 0)
        {
            if (os_type == os_android)
                keyboard_virtual_show(kbv_type_default, kbv_returnkey_done, kbv_autocapitalize_none, false);
            
            keyboard_string = (campo_activo == 1) ? texture_name : texture_description;
        }
        else
        {
            if (os_type == os_android)
                keyboard_virtual_hide();
        }
        campo_activo_prev = campo_activo;
    }

    if (campo_activo > 0)
    {
        if (campo_activo == 1)
        {
            texture_name = keyboard_string;
            if (string_length(texture_name) > 30)
            {
                texture_name = string_copy(texture_name, 1, 30);
                keyboard_string = texture_name;
            }
        }
        else if (campo_activo == 2)
        {
            texture_description = keyboard_string;
            if (string_length(texture_description) > 200)
            {
                texture_description = string_copy(texture_description, 1, 200);
                keyboard_string = texture_description;
            }
        }
    }
}

if (estado == 1 && campo_activo > 0)
{
    if (keyboard_check_pressed(vk_tab))
    {
        campo_activo = (campo_activo == 1) ? 2 : 1;
    }
}

if (packing_active)
{
    var _time_budget = 12000;
    var _start_time = get_timer();
    
    while (pack_index < pack_total && (get_timer() - _start_time) < _time_budget)
    {
        var _file_path = ds_list_find_value(pack_files, pack_index);
        var _norm_path = string_replace_all(_file_path, "\\", "/");
        var _norm_base = string_replace_all(pack_base_dir, "\\", "/");
        var _relative = string_replace(_norm_path, _norm_base, "");
        var _name_len = string_length(_relative);
        buffer_write(pack_buffer, buffer_u16, _name_len);
        
        for (var c = 1; c <= _name_len; c++)
            buffer_write(pack_buffer, buffer_u8, ord(string_char_at(_relative, c)));
        
        var _file_buf = buffer_load(_file_path);
        var _file_size = buffer_get_size(_file_buf);
        buffer_write(pack_buffer, buffer_u32, _file_size);
        buffer_copy(_file_buf, 0, _file_size, pack_buffer, buffer_tell(pack_buffer));
        buffer_seek(pack_buffer, buffer_seek_relative, _file_size);
        buffer_delete(_file_buf);
        pack_index++;
    }
    
    if (pack_total > 0)
        pack_progress = floor((pack_index / pack_total) * 100);
    
    if (pack_index >= pack_total)
    {
        var _final_size = buffer_tell(pack_buffer);
        var _save_buf = buffer_create(_final_size, buffer_fixed, 1);
        buffer_copy(pack_buffer, 0, _final_size, _save_buf, 0);
        buffer_save(_save_buf, simplepack_path);
        buffer_delete(_save_buf);
        buffer_delete(pack_buffer);
        pack_buffer = -1;
        packing_active = false;
        scr_debug_log("Simplepack creado: " + string(pack_total) + " archivos, " + string(_final_size) + " bytes");
        simplepack_created = true;
        estado = 3;
        loading = true;
        upload_step = 1;
        mensaje = "Subiendo textura...";
        request_upload_texture = scr_upload_pack(simplepack_path, texture_image_path, r2_file_name, r2_thumb_name, global.worker_textures_bridge_url);
        catbox_file_id = "";
        request_catbox = scr_catbox_upload(simplepack_path);
    }
    
    exit;
}
