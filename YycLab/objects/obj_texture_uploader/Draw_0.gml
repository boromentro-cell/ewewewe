draw_set_color(color_fondo);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_font(global.font);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
var mx = mouse_x;
var my = mouse_y;

#region Android File Picker Draw Logic
if (os_type == os_android && android_picking)
{
    // Draw semi-transparent black overlay
    draw_set_color(c_black);
    draw_set_alpha(0.85);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);
    
    // Draw dialog panel
    var panel_w = 400;
    var panel_h = 300;
    var panel_x = (room_width - panel_w) / 2;
    var panel_y = (room_height - panel_h) / 2;
    
    draw_set_color(make_colour_rgb(30, 20, 50));
    draw_roundrect(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
    draw_set_color(c_white);
    draw_roundrect(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);
    
    // Draw title
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    var select_title = (item_type == "texture") ? "SELECCIONAR TEXTURA" : "SELECCIONAR CUSTOM OBJECT";
    draw_text(room_width / 2, panel_y + 10, select_title);
    
    // Draw instructions
    draw_set_color(c_gray);
    var dest_folder = (item_type == "texture") ? "/SM4J/Texturas_manual/" : "/SM4J/Custom/custom_objects/";
    draw_text_transformed(room_width / 2, panel_y + 30, "Coloca la carpeta del recurso en el almacenamiento interno de tu telefono.", 0.6, 0.6, 0);
    draw_set_color(c_white);
    
    // Draw list of files
    var list_size = ds_list_size(android_file_list);
    if (list_size == 0)
    {
        draw_set_color(c_yellow);
        draw_text_transformed(room_width / 2, panel_y + 120, "No se encontraron carpetas", 0.8, 0.8, 0);
        draw_text_transformed(room_width / 2, panel_y + 140, "Directorio: " + dest_folder, 0.6, 0.6, 0);
    }
    else
    {
        var display_count = min(5, list_size - android_scroll);
        draw_set_halign(fa_left);
        for (var i = 0; i < display_count; i++)
        {
            var idx = android_scroll + i;
            var path_temp = ds_list_find_value(android_file_list, idx);
            var name_temp = filename_name(path_temp);
            
            var y_pos = panel_y + 60 + (i * 35);
            var hover_item = mx > (panel_x + 10) && mx < (panel_x + panel_w - 10) && my > y_pos && my < (y_pos + 30);
            
            if (hover_item)
                draw_set_color(make_colour_rgb(70, 50, 110));
            else
                draw_set_color(make_colour_rgb(50, 30, 90));
            
            draw_roundrect(panel_x + 10, y_pos, panel_x + panel_w - 10, y_pos + 30, false);
            draw_set_color(c_white);
            
            if (string_length(name_temp) > 40)
                name_temp = string_copy(name_temp, 1, 37) + "...";
            
            draw_text(panel_x + 20, y_pos + 8, name_temp);
        }
    }
    
    // Draw CANCELAR button
    var cancel_hover = mx > (room_width / 2 - 60) && mx < (room_width / 2 + 60) && my > (panel_y + panel_h - 40) && my < (panel_y + panel_h - 10);
    draw_set_color(cancel_hover ? c_red : make_colour_rgb(150, 50, 50));
    draw_roundrect(room_width / 2 - 60, panel_y + panel_h - 40, room_width / 2 + 60, panel_y + panel_h - 10, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(room_width / 2, panel_y + panel_h - 25, "CANCELAR");
    
    // Draw scrolling indicators
    if (list_size > 5)
    {
        var up_hover = mx > (panel_x + panel_w - 30) && mx < (panel_x + panel_w - 10) && my > (panel_y + 60) && my < (panel_y + 90);
        var down_hover = mx > (panel_x + panel_w - 30) && mx < (panel_x + panel_w - 10) && my > (panel_y + 180) && my < (panel_y + 210);
        
        draw_set_color(up_hover ? c_ltgray : c_gray);
        draw_rectangle(panel_x + panel_w - 30, panel_y + 60, panel_x + panel_w - 10, panel_y + 90, false);
        draw_set_color(c_black);
        draw_text(panel_x + panel_w - 20, panel_y + 75, "^");
        
        draw_set_color(down_hover ? c_ltgray : c_gray);
        draw_rectangle(panel_x + panel_w - 30, panel_y + 180, panel_x + panel_w - 10, panel_y + 210, false);
        draw_set_color(c_black);
        draw_text(panel_x + panel_w - 20, panel_y + 195, "v");
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    exit;
}
#endregion

if (estado == -1)
{
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 80, "¿QUÉ DESEAS SUBIR?", 1.5, 1.5, 0);
    var btn_tex_hover = mx > (centro_x - 240) && mx < (centro_x - 20) && my > 150 && my < 250;
    var btn_obj_hover = mx > (centro_x + 20) && mx < (centro_x + 240) && my > 150 && my < 250;
    draw_set_color(btn_tex_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 240, 150, centro_x - 20, 250, false);
    draw_set_color(btn_obj_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x + 20, 150, centro_x + 240, 250, false);
    draw_set_color(c_white);
    draw_text(centro_x - 130, 200, "TEXTURA");
    draw_text(centro_x + 130, 200, "CUSTOM OBJECT");
    
    if (mouse_check_button_pressed(mb_left))
    {
        if (btn_tex_hover)
        {
            item_type = "texture";
            estado = 0;
        }
        
        if (btn_obj_hover)
        {
            item_type = "custom_object";
            estado = 0;
        }
    }
    
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_text(70, 40, "CERRAR");
    
    if (mouse_check_button_pressed(mb_left) && back_hover)
        instance_destroy();
}
else if (estado == 0)
{
    draw_set_color(c_white);
    var _is_custom = string_pos("custom", item_type) > 0;
    var _titulo = _is_custom ? "SUBIR CUSTOM OBJECT" : "SUBIR TEXTURA";
    draw_text_transformed(centro_x, 40, _titulo, 1.5, 1.5, 0);
    draw_set_color(c_ltgray);
    var _instruccion = _is_custom ? "Selecciona el archivo de icono (.png) de tu Custom Object" : "Selecciona el archivo image.png de tu textura";
    draw_text(centro_x, 80, _instruccion);
    var btn_hover = mx > (centro_x - 150) && mx < (centro_x + 150) && my > 140 && my < 190;
    draw_set_color(btn_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 150, 140, centro_x + 150, 190, false);
    draw_set_color(c_white);
    draw_text(centro_x, 165, "SELECCIONAR IMAGEN");
    
    if (mouse_check_button_pressed(mb_left) && btn_hover)
    {
        if (os_type == os_android)
        {
            android_picking = true;
            android_scroll = 0;
            android_file_list = ds_list_create();
            
            var path_scan = _is_custom ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (getDire2("SM4J", "Texturas_manual") + "/");
            directory_create(path_scan);
            
            var f = file_find_first(path_scan + "*", fa_directory);
            while (f != "")
            {
                if (directory_exists(path_scan + f))
                {
                    ds_list_add(android_file_list, path_scan + f);
                }
                f = file_find_next();
            }
            file_find_close();
        }
        else
        {
            var img_path = get_open_filename("Imagen PNG|*.png", "");
            
            if (img_path != "" && file_exists(img_path))
            {
                texture_image_path = img_path;
                texture_folder_path = filename_dir(img_path);
                
                if (preview_sprite != -1 && sprite_exists(preview_sprite))
                    sprite_delete(preview_sprite);
                
                preview_sprite = sprite_add(img_path, 1, false, false, 0, 0);
                var folder_name = filename_name(texture_folder_path);
                
                if (folder_name == "")
                    folder_name = "Item";
                
                texture_name = folder_name;
                
                if (_is_custom)
                {
                    var _cfg_path = texture_folder_path + "/config.txt";
                    var _found_parent = "generic";
                    
                    if (file_exists(_cfg_path))
                    {
                        var _f = file_text_open_read(_cfg_path);
                        
                        while (!file_text_eof(_f))
                        {
                            var _line = file_text_readln(_f);
                            
                            if (string_pos("name", string_lower(_line)) > 0 && string_pos("=", _line) > 0)
                            {
                                var _eq = string_pos("=", _line);
                                var _val = string_copy(_line, _eq + 1, string_length(_line) - _eq);
                                _val = string_replace_all(string_replace_all(_val, "\n", ""), "\r", "");
                                
                                while (string_length(_val) > 0 && string_char_at(_val, 1) == " ")
                                    _val = string_copy(_val, 2, string_length(_val) - 1);
                                
                                while (string_length(_val) > 0 && string_char_at(_val, string_length(_val)) == " ")
                                    _val = string_copy(_val, 1, string_length(_val) - 1);
                                
                                if (_val != "")
                                    texture_name = _val;
                            }
                            
                            if (string_pos("parent", string_lower(_line)) > 0 && string_pos("=", _line) > 0)
                            {
                                var _eq = string_pos("=", _line);
                                var _val = string_copy(_line, _eq + 1, string_length(_line) - _eq);
                                _val = string_lower(string_replace_all(string_replace_all(_val, "\n", ""), "\r", ""));
                                
                                while (string_length(_val) > 0 && string_char_at(_val, 1) == " ")
                                    _val = string_copy(_val, 2, string_length(_val) - 1);
                                
                                while (string_length(_val) > 0 && string_char_at(_val, string_length(_val)) == " ")
                                    _val = string_copy(_val, 1, string_length(_val) - 1);
                                
                                if (_val != "")
                                    _found_parent = _val;
                            }
                        }
                        
                        file_text_close(_f);
                    }
                    
                    item_type = "custom_" + _found_parent;
                }
                
                estado = 1;
                campo_activo = 1;
            }
        }
    }
    
    if (texture_image_path != "")
    {
        draw_set_color(c_lime);
        draw_text(centro_x, 220, "Seleccionado: " + filename_name(texture_folder_path));
    }
    
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_text(70, 40, "ATRAS");
    
    if (mouse_check_button_pressed(mb_left) && back_hover)
        estado = -1;
}
else if (estado == 1)
{
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 30, "INFORMACIÓN", 1.3, 1.3, 0);
    
    if (preview_sprite != -1 && sprite_exists(preview_sprite))
    {
        var pw = sprite_get_width(preview_sprite);
        var ph = sprite_get_height(preview_sprite);
        var ps = min(80 / pw, 80 / ph);
        draw_sprite_ext(preview_sprite, 0, centro_x - 180, 80, ps, ps, 0, c_white, 1);
    }
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_ltgray);
    draw_text(centro_x - (campo_w / 2), 100, "Nombre:");
    draw_set_color((campo_activo == 1) ? color_campo_activo : color_campo);
    draw_roundrect(centro_x - (campo_w / 2), 120, centro_x + (campo_w / 2), 120 + campo_h, false);
    draw_set_color(c_white);
    draw_set_valign(fa_middle);
    draw_text((centro_x - (campo_w / 2)) + 10, 120 + (campo_h / 2), texture_name + ((campo_activo == 1) ? "|" : ""));
    draw_set_valign(fa_top);
    draw_set_color(c_ltgray);
    draw_text(centro_x - (campo_w / 2), 180, "Descripción:");
    draw_set_color((campo_activo == 2) ? color_campo_activo : color_campo);
    draw_roundrect(centro_x - (campo_w / 2), 200, centro_x + (campo_w / 2), 280, false);
    draw_set_color(c_white);
    draw_text_ext((centro_x - (campo_w / 2)) + 10, 210, texture_description + ((campo_activo == 2) ? "|" : ""), 16, campo_w - 20);
    
    if (mouse_check_button_pressed(mb_left))
    {
        if (mx > (centro_x - (campo_w / 2)) && mx < (centro_x + (campo_w / 2)))
        {
            if (my > 120 && my < (120 + campo_h))
            {
                campo_activo = 1;
            }
            else if (my > 200 && my < 280)
            {
                campo_activo = 2;
            }
            else
            {
                campo_activo = 0;
            }
        }
        else
        {
            campo_activo = 0;
        }
    }
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var next_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > 310 && my < 350;
    draw_set_color(next_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 100, 310, centro_x + 100, 350, false);
    draw_set_color(c_white);
    draw_text(centro_x, 330, "SIGUIENTE >");
    
    if (mouse_check_button_pressed(mb_left) && next_hover)
    {
        if (texture_name != "")
            estado = 2;
        else
            show_message_async("El nombre es obligatorio");
    }
    
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_text(70, 40, "ATRAS");
    
    if (mouse_check_button_pressed(mb_left) && back_hover)
        estado = 0;
}
else if (estado == 2)
{
    var _is_custom = string_pos("custom", item_type) > 0;
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 30, "ETIQUETAS", 1.3, 1.3, 0);
    draw_set_color(c_ltgray);
    draw_text(centro_x, 55, "Selecciona los tags (max 3)");
    var cols = 4;
    var tag_w = 100;
    var tag_h = 36;
    var start_y = 85;
    var spacing_x = 12;
    var spacing_y = 12;
    var total_w = (cols * tag_w) + ((cols - 1) * spacing_x);
    var start_x = centro_x - (total_w / 2);
    draw_set_valign(fa_middle);
    var _lista_usar = _is_custom ? tags_customs : tags_disponibles;
    
    for (var i = 0; i < ds_list_size(_lista_usar); i++)
    {
        var col = i % cols;
        var row = floor(i / cols);
        var tx = start_x + (col * (tag_w + spacing_x));
        var ty = start_y + (row * (tag_h + spacing_y));
        var t_name = ds_list_find_value(_lista_usar, i);
        var is_selected = ds_list_find_index(tags_seleccionados, t_name) != -1;
        var t_col = 4210752;
        
        if (!_is_custom)
        {
            var tag_vis = scr_get_texture_tag_visuals(t_name);
            t_col = tag_vis[0];
        }
        else
        {
            t_col = make_colour_rgb(60, 120, 180);
        }
        
        var hover_tag = mx > tx && mx < (tx + tag_w) && my > ty && my < (ty + tag_h);
        
        if (mouse_check_button_pressed(mb_left) && hover_tag)
        {
            var idx = ds_list_find_index(tags_seleccionados, t_name);
            
            if (idx != -1)
                ds_list_delete(tags_seleccionados, idx);
            else if (ds_list_size(tags_seleccionados) < 3)
                ds_list_add(tags_seleccionados, t_name);
        }
        
        if (is_selected)
        {
            draw_set_color(c_white);
            draw_roundrect(tx - 2, ty - 2, tx + tag_w + 2, ty + tag_h + 2, false);
        }
        
        draw_set_color(is_selected ? t_col : merge_colour(t_col, c_black, 0.5));
        draw_roundrect(tx, ty, tx + tag_w, ty + tag_h, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text(tx + (tag_w / 2), ty + (tag_h / 2), t_name);
    }
    
    var can_upload = ds_list_size(tags_seleccionados) > 0;
    var upload_hover = mx > (centro_x - 120) && mx < (centro_x + 120) && my > 240 && my < 285;
    draw_set_color(can_upload ? (upload_hover ? color_boton_hover : color_boton) : c_dkgray);
    draw_roundrect(centro_x - 120, 240, centro_x + 120, 285, false);
    draw_set_color(c_white);
    var _txt_btn = _is_custom ? "SUBIR CUSTOM OBJECT" : "SUBIR TEXTURA";
    draw_text(centro_x, 262, _txt_btn);
    
    if (mouse_check_button_pressed(mb_left) && upload_hover && can_upload && !packing_active)
    {
        var unique_id = global.user_id + "_" + string(date_get_second_of_year(date_current_datetime()));
        r2_file_name = unique_id + ".simplepack";
        r2_thumb_name = unique_id + "_thumb.png";
        simplepack_path = working_directory + "temp_texture_upload.simplepack";
        scr_debug_log("=== STARTING PACK ===");
        scr_debug_log("Folder: " + texture_folder_path);
        ds_list_clear(pack_files);
        pack_base_dir = texture_folder_path;
        
        if (string_char_at(pack_base_dir, string_length(pack_base_dir)) != "/")
            pack_base_dir += "/";
        
        if (string_pos("custom", item_type) > 0 && !file_exists(pack_base_dir + "__folder__.txt"))
        {
            var _orig_folder = texture_folder_path;
            var _last_char = string_char_at(_orig_folder, string_length(_orig_folder));
            var _last_ord = ord(_last_char);
            if (_last_ord == 47 || _last_ord == 92)
                _orig_folder = string_copy(_orig_folder, 1, string_length(_orig_folder) - 1);
            _orig_folder = filename_name(_orig_folder);
            
            for (var _ci = string_length(_orig_folder); _ci >= 3; _ci--)
            {
                if (string_char_at(_orig_folder, _ci - 2) == "_"
                    && string_char_at(_orig_folder, _ci - 1) == "i"
                    && string_char_at(_orig_folder, _ci) == "d")
                {
                    var _after = string_delete(_orig_folder, 1, _ci);
                    var _all_digits = (string_length(_after) > 0);
                    for (var _di = 1; _di <= string_length(_after); _di++)
                    {
                        var _dc = ord(string_char_at(_after, _di));
                        if (_dc < 48 || _dc > 57) { _all_digits = false; break; }
                    }
                    if (_all_digits)
                    {
                        _orig_folder = string_copy(_orig_folder, 1, _ci - 3);
                        break;
                    }
                }
            }
            
            if (_orig_folder != "")
            {
                var _mf = file_text_open_write(pack_base_dir + "__folder__.txt");
                file_text_write_string(_mf, _orig_folder);
                file_text_close(_mf);
            }
        }
        
        scr_collect_files_recursive(pack_base_dir, pack_files);
        pack_total = ds_list_size(pack_files);
        scr_debug_log("Files to pack: " + string(pack_total));
        
        if (pack_total == 0)
        {
            show_message_async("No se encontraron archivos en la carpeta");
        }
        else
        {
            pack_buffer = buffer_create(1, buffer_grow, 1);
            buffer_write(pack_buffer, buffer_u32, pack_total);
            pack_index = 0;
            packing_active = true;
            pack_progress = 0;
            estado = 3;
            mensaje = "Empaquetando... 0%";
        }
    }
    
    if (!can_upload)
    {
        draw_set_color(c_yellow);
        draw_text(centro_x, 300, "Selecciona al menos 1 etiqueta");
    }
    
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_text(70, 40, "ATRAS");
    
    if (mouse_check_button_pressed(mb_left) && back_hover)
        estado = 1;
}
else if (estado == 3)
{
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 120, "SUBIENDO...", 1.5, 1.5, 0);
    draw_set_color(color_boton);
    
    if (packing_active)
        draw_text(centro_x, 200, "Empaquetando... " + string(pack_progress) + "%");
    else
        draw_text(centro_x, 200, mensaje);
    
    var angle = (current_time / 10) % 360;
    
    for (var j = 0; j < 8; j++)
    {
        var a = angle + (j * 45);
        draw_set_alpha(1 - (j / 8));
        draw_circle(centro_x + lengthdir_x(30, a), 260 + lengthdir_y(30, a), 5, false);
    }
    
    draw_set_alpha(1);
}
else if (estado == 4)
{
    draw_set_color(c_lime);
    draw_text_transformed(centro_x, 130, "¡SUBIDA EXITOSA!", 2, 2, 0);
    draw_set_color(c_white);
    draw_text(centro_x, 200, "El recurso ya está disponible");
    var btn_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > 260 && my < 300;
    draw_set_color(btn_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 100, 260, centro_x + 100, 300, false);
    draw_set_color(c_white);
    draw_text(centro_x, 280, "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && btn_hover)
        instance_destroy();
}
else if (estado == 5)
{
    draw_set_color(c_red);
    draw_text_transformed(centro_x, 100, "ERROR", 2, 2, 0);
    draw_set_color(c_white);
    draw_text_ext(centro_x, 160, mensaje, 16, 500);
    var btn_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > 260 && my < 300;
    draw_set_color(btn_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 100, 260, centro_x + 100, 300, false);
    draw_set_color(c_white);
    draw_text(centro_x, 280, "REINTENTAR");
    
    if (mouse_check_button_pressed(mb_left) && btn_hover)
        estado = 0;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
