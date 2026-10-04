if (surface_exists(application_surface))
{
    if (surface_get_width(application_surface) < window_get_width())
        surface_resize(application_surface, window_get_width(), window_get_height());
}

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
    draw_text(room_width / 2, panel_y + 10, "SELECCIONAR CAPTURA DE NIVEL");
    
    // Draw instructions
    draw_set_color(c_gray);
    draw_text_transformed(room_width / 2, panel_y + 30, "Coloca tus fotos en la carpeta /SM4J/Images/ o usa capturas de pantalla.", 0.6, 0.6, 0);
    draw_set_color(c_white);
    
    // Draw list of files
    var list_size = ds_list_size(android_file_list);
    if (list_size == 0)
    {
        draw_set_color(c_yellow);
        draw_text_transformed(room_width / 2, panel_y + 120, "No se encontraron imagenes .PNG", 0.8, 0.8, 0);
        draw_text_transformed(room_width / 2, panel_y + 140, "Directorio: /SM4J/Images/", 0.6, 0.6, 0);
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
draw_set_color(color_fondo);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_font(global.font);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

if (estado == 0)
{
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);
    var info_text = "";
    var info_col = 16777215;
    
    if (user_upload_count == -1)
    {
        info_text = "Verificando cupo...";
        info_col = 8421504;
    }
    else if (user_upload_limit >= 9999)
    {
        info_text = "Niveles: " + string(user_upload_count) + " / ILIMITADO";
        info_col = 65280;
    }
    else
    {
        info_text = "Niveles: " + string(user_upload_count) + " / " + string(user_upload_limit);
        
        if (user_upload_count >= user_upload_limit)
            info_col = 255;
        else
            info_col = 16777215;
    }
    
    var text_w = string_width(info_text);
    draw_set_color(c_black);
    draw_set_alpha(0.5);
    draw_roundrect(room_width - text_w - 20, 10, room_width - 10, 35, false);
    draw_set_alpha(1);
    draw_set_color(info_col);
    draw_text(room_width - 15, 12, info_text);
    
    if (user_upload_limit < 9999 && user_upload_count != -1)
    {
        var bar_w = text_w;
        var bar_h = 4;
        var bar_x = room_width - 15 - bar_w;
        var bar_y = 30;
        var pct = clamp(user_upload_count / user_upload_limit, 0, 1);
        draw_set_color(c_dkgray);
        draw_rectangle(bar_x, bar_y, bar_x + bar_w, bar_y + bar_h, false);
        draw_set_color(info_col);
        draw_rectangle(bar_x, bar_y, bar_x + (bar_w * pct), bar_y + bar_h, false);
    }
    
    var discord_y = 40;
    var discord_text = "";
    var discord_col = 16777215;
    
    if (discord_linked == -1)
    {
        discord_text = "Discord: Verificando...";
        discord_col = 65535;
    }
    else if (discord_linked == 0)
    {
        discord_text = "Discord: NO VINCULADO";
        discord_col = 255;
    }
    else
    {
        discord_text = "Discord: OK";
        discord_col = 65280;
    }
    
    draw_set_halign(fa_right);
    draw_set_color(discord_col);
    draw_text(room_width - 15, discord_y, discord_text);
    
    if (discord_linked == 0)
    {
        var link_btn_x = room_width - 180;
        var link_btn_y = 55;
        var link_btn_w = 160;
        var link_btn_h = 30;
        var hover_link = mx > link_btn_x && mx < (link_btn_x + link_btn_w) && my > link_btn_y && my < (link_btn_y + link_btn_h);
        
        if (hover_link)
            draw_set_color(make_colour_rgb(88, 101, 242));
        else
            draw_set_color(make_colour_rgb(60, 70, 180));
        
        draw_roundrect(link_btn_x, link_btn_y, link_btn_x + link_btn_w, link_btn_y + link_btn_h, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(link_btn_x + (link_btn_w / 2), link_btn_y + (link_btn_h / 2), "VINCULAR DISCORD");
        
        if (mouse_check_button_pressed(mb_left) && hover_link)
            show_message_async("Ve a tu perfil para vincular Discord.");
    }
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 50, "SELECCIONAR NIVEL", 1.5, 1.5, 0);
    draw_set_color(c_ltgray);
    draw_text(centro_x, 100, "Elige un nivel de tu carpeta local");
    var num_niveles = ds_list_size(niveles_locales);
    
    if (num_niveles == 0)
    {
        draw_set_color(c_yellow);
        draw_text(centro_x, 200, "No hay niveles en tu carpeta local");
    }
    else
    {
        draw_set_halign(fa_left);
        
        for (var i = 0; i < min(5, num_niveles - niveles_scroll); i++)
        {
            var y_pos = 150 + (i * 60);
            var index_lista = niveles_scroll + i;
            var nivel_path_temp = ds_list_find_value(niveles_locales, index_lista);
            var nivel_nombre = filename_name(nivel_path_temp);
            nivel_nombre = string_replace(nivel_nombre, ".lvl", "");
            var hover_tarjeta = mx > (centro_x - 250) && mx < (centro_x + 250) && my > y_pos && my < (y_pos + 50);
            
            if (index_lista == nivel_seleccionado)
                draw_set_color(color_tarjeta_sel);
            else if (hover_tarjeta)
                draw_set_color(color_tarjeta_sel);
            else
                draw_set_color(color_tarjeta);
            
            draw_roundrect(centro_x - 250, y_pos, centro_x + 250, y_pos + 50, false);
            
            if (mouse_check_button_pressed(mb_left) && hover_tarjeta)
            {
                nivel_seleccionado = index_lista;
                level_path = nivel_path_temp;
                level_name = nivel_nombre;
            }
            
            draw_set_color(c_white);
            
            if (string_length(nivel_nombre) > 45)
                nivel_nombre = string_copy(nivel_nombre, 1, 45) + "...";
            
            draw_text(centro_x - 240, y_pos + 25, nivel_nombre);
        }
    }
    
    if (nivel_seleccionado >= 0)
    {
        var can_continue = discord_linked == 1 && (user_upload_count != -1 && user_upload_count < user_upload_limit);
        var btn_color = can_continue ? color_boton : 8421504;
        var btn_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > (room_height - 80) && my < (room_height - 40);
        
        if (can_continue && btn_hover)
            btn_color = color_boton_hover;
        
        draw_set_color(btn_color);
        draw_roundrect(centro_x - 100, room_height - 80, centro_x + 100, room_height - 40, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text(centro_x, room_height - 60, "CONTINUAR");
        
        if (mouse_check_button_pressed(mb_left) && btn_hover && can_continue)
        {
            estado = 1;
            campo_activo = 1;
        }
    }
    
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(70, 40, "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && back_hover)
        room_goto_previous();
}
else if (estado == 1)
{
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 40, "INFORMACIÓN DEL NIVEL", 1.3, 1.3, 0);
    draw_set_color(c_ltgray);
    draw_text(centro_x, 80, "Archivo: " + filename_name(level_path));
    draw_set_halign(fa_left);
    draw_set_color(c_ltgray);
    draw_text(centro_x - (campo_w / 2), 120, "Nombre del nivel:");
    draw_set_color((campo_activo == 1) ? color_campo_activo : color_campo);
    draw_roundrect(centro_x - (campo_w / 2), 140, centro_x + (campo_w / 2), 140 + campo_h, false);
    draw_set_color(c_white);
    draw_set_valign(fa_middle);
    var name_display = level_name + ((campo_activo == 1) ? "|" : "");
    draw_text((centro_x - (campo_w / 2)) + 10, 140 + (campo_h / 2), name_display);
    draw_set_valign(fa_top);
    draw_set_color(c_ltgray);
    draw_text(centro_x - (campo_w / 2), 200, "Descripción (opcional):");
    draw_set_color((campo_activo == 2) ? color_campo_activo : color_campo);
    draw_roundrect(centro_x - (campo_w / 2), 220, centro_x + (campo_w / 2), 320, false);
    draw_set_color(c_white);
    var desc_display = level_description + ((campo_activo == 2) ? "|" : "");
    draw_text_ext((centro_x - (campo_w / 2)) + 10, 230, desc_display, 16, campo_w - 20);
    
    if (mouse_check_button_pressed(mb_left))
    {
        if (mx > (centro_x - (campo_w / 2)) && mx < (centro_x + (campo_w / 2)))
        {
            if (my > 140 && my < (140 + campo_h))
            {
                campo_activo = 1;
            }
            else if (my > 220 && my < 320)
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
    var btn_next_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > 350 && my < 390;
    draw_set_color(btn_next_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 100, 350, centro_x + 100, 390, false);
    draw_set_color(c_white);
    draw_set_valign(fa_middle);
    draw_text(centro_x, 370, "SIGUIENTE >");
    
    if (mouse_check_button_pressed(mb_left) && btn_next_hover)
    {
        if (level_name != "")
            estado = 5;
        else
            show_message_async("El nombre es obligatorio.");
    }
    
    draw_set_valign(fa_top);
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_set_valign(fa_middle);
    draw_text(70, 40, "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && back_hover)
        estado = 0;
}
else if (estado == 5)
{
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 30, "ETIQUETAS, FOTO & TEXTURA", 1.3, 1.3, 0);
    draw_set_color(c_ltgray);
    draw_text(centro_x, 55, "Configura las opciones de tu nivel");
    var cols = 2;
    var tag_w = 180;
    var tag_h = 36;
    var start_y = 85;
    var spacing_x = 20;
    var spacing_y = 12;
    var total_w = (cols * tag_w) + ((cols - 1) * spacing_x);
    var start_x = centro_x - (total_w / 2);
    draw_set_valign(fa_middle);
    
    for (var i = 0; i < ds_list_size(tags_disponibles); i++)
    {
        var col = i % cols;
        var row = floor(i / cols);
        var tx = start_x + (col * (tag_w + spacing_x));
        var ty = start_y + (row * (tag_h + spacing_y));
        var t_name = ds_list_find_value(tags_disponibles, i);
        var index_sel = ds_list_find_index(tags_seleccionados, t_name);
        var is_selected = index_sel != -1;
        var visual_data = get_tag_data(t_name);
        var t_col = visual_data.color;
        var hover_tag = mx > tx && mx < (tx + tag_w) && my > ty && my < (ty + tag_h);
        
        if (mouse_check_button_pressed(mb_left) && hover_tag && !texture_dropdown_open)
        {
            if (is_selected)
                ds_list_delete(tags_seleccionados, index_sel);
            else if (ds_list_size(tags_seleccionados) < 3)
                ds_list_add(tags_seleccionados, t_name);
            else
                show_message_async("Máximo 3 etiquetas permitidas.");
        }
        
        if (is_selected)
        {
            draw_set_color(c_white);
            draw_roundrect(tx - 2, ty - 2, tx + tag_w + 2, ty + tag_h + 2, false);
            draw_set_color(t_col);
        }
        else if (hover_tag)
        {
            draw_set_color(merge_colour(t_col, c_black, 0.2));
        }
        else
        {
            draw_set_color(merge_colour(t_col, c_black, 0.6));
        }
        
        draw_roundrect(tx, ty, tx + tag_w, ty + tag_h, false);
        draw_set_halign(fa_center);
        draw_set_color(is_selected ? c_white : c_ltgray);
        draw_text(tx + (tag_w / 2), ty + (tag_h / 2), string_upper(t_name));
    }
    
    var texture_section_y = start_y + (ceil(ds_list_size(tags_disponibles) / cols) * (tag_h + spacing_y)) + 15;
    var checkbox_x = centro_x - 200;
    var checkbox_y = texture_section_y;
    var checkbox_size = 24;
    var hover_checkbox = mx > checkbox_x && mx < (checkbox_x + checkbox_size) && my > checkbox_y && my < (checkbox_y + checkbox_size);
    draw_set_color(hover_checkbox ? make_colour_rgb(80, 60, 120) : make_colour_rgb(50, 30, 90));
    draw_roundrect(checkbox_x, checkbox_y, checkbox_x + checkbox_size, checkbox_y + checkbox_size, false);
    draw_set_color(texture_enabled ? make_colour_rgb(100, 200, 100) : c_gray);
    draw_roundrect(checkbox_x, checkbox_y, checkbox_x + checkbox_size, checkbox_y + checkbox_size, true);
    
    if (texture_enabled)
    {
        draw_set_color(make_colour_rgb(100, 255, 100));
        draw_line_width(checkbox_x + 5, checkbox_y + 12, checkbox_x + 10, checkbox_y + 18, 2);
        draw_line_width(checkbox_x + 10, checkbox_y + 18, checkbox_x + 19, checkbox_y + 6, 2);
    }
    
    if (mouse_check_button_pressed(mb_left) && hover_checkbox && !texture_dropdown_open)
    {
        texture_enabled = !texture_enabled;
        
        if (!texture_enabled)
        {
            texture_search_text = "";
            texture_selected_name = "";
            texture_selected_author = "";
            texture_selected_display = "";
            texture_dropdown_open = false;
            texture_search_active = false;
        }
    }
    
    draw_set_halign(fa_left);
    draw_set_color(texture_enabled ? c_white : c_gray);
    draw_text(checkbox_x + checkbox_size + 10, checkbox_y + (checkbox_size / 2), "Usar textura personalizada");
    
    if (texture_enabled)
    {
        var search_x = centro_x - 200;
        var search_y = texture_section_y + 35;
        var search_w = 400;
        var search_h = 36;
        draw_set_color(texture_search_active ? color_campo_activo : color_campo);
        draw_roundrect(search_x, search_y, search_x + search_w, search_y + search_h, false);
        
        if (texture_selected_name != "")
        {
            draw_set_color(make_colour_rgb(100, 200, 100));
            draw_roundrect(search_x, search_y, search_x + search_w, search_y + search_h, true);
        }
        
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        var display_text = texture_search_text;
        
        if (display_text == "" && !texture_search_active)
        {
            draw_set_color(c_gray);
            display_text = "Buscar textura...";
        }
        else
        {
            draw_set_color(c_white);
            
            if (texture_search_active)
                display_text += "|";
        }
        
        draw_text(search_x + 10, search_y + (search_h / 2), display_text);
        var hover_search = mx > search_x && mx < (search_x + search_w) && my > search_y && my < (search_y + search_h);
        
        if (mouse_check_button_pressed(mb_left))
        {
            if (hover_search)
            {
                texture_search_active = true;
                campo_activo = 0;
                
                if (texture_search_text != "" && texture_selected_name == "")
                    texture_dropdown_open = true;
            }
            else if (!texture_dropdown_open)
            {
                texture_search_active = false;
            }
        }
        
        if (texture_dropdown_open && ds_list_size(texture_search_results) > 0)
        {
            var dropdown_y = search_y + search_h + 2;
            var item_h = 32;
            var dropdown_h = min(ds_list_size(texture_search_results), 5) * item_h;
            draw_set_color(make_colour_rgb(40, 25, 70));
            draw_roundrect(search_x, dropdown_y, search_x + search_w, dropdown_y + dropdown_h, false);
            
            for (var i = 0; i < min(ds_list_size(texture_search_results), 5); i++)
            {
                var item_y = dropdown_y + (i * item_h);
                var _map = ds_list_find_value(texture_search_results, i);
                
                if (ds_exists(_map, ds_type_map))
                {
                    var _name = ds_map_find_value(_map, "name");
                    var _author = ds_map_find_value(_map, "author_name");
                    var _display = string(_name) + " - " + string(_author);
                    var hover_item = mx > search_x && mx < (search_x + search_w) && my > item_y && my < (item_y + item_h);
                    
                    if (hover_item || i == texture_hover_index)
                    {
                        draw_set_color(make_colour_rgb(70, 50, 110));
                        draw_rectangle(search_x + 2, item_y, (search_x + search_w) - 2, (item_y + item_h) - 1, false);
                    }
                    
                    draw_set_color(c_white);
                    draw_set_halign(fa_left);
                    
                    if (string_length(_display) > 45)
                        _display = string_copy(_display, 1, 45) + "...";
                    
                    draw_text(search_x + 10, item_y + (item_h / 2), _display);
                    
                    if (mouse_check_button_pressed(mb_left) && hover_item)
                    {
                        texture_selected_name = _name;
                        texture_selected_author = _author;
                        texture_selected_display = string(_name) + " - " + string(_author);
                        texture_search_text = texture_selected_display;
                        texture_dropdown_open = false;
                        texture_search_active = false;
                    }
                }
            }
            
            draw_set_color(make_colour_rgb(100, 80, 140));
            draw_roundrect(search_x, dropdown_y, search_x + search_w, dropdown_y + dropdown_h, true);
        }
        
        if (texture_dropdown_open && ds_list_size(texture_search_results) == 0 && texture_search_text != "" && texture_search_request == -1)
        {
            var no_results_y = search_y + search_h + 5;
            draw_set_color(c_gray);
            draw_set_halign(fa_left);
            draw_text(search_x + 10, no_results_y, "No se encontraron texturas");
        }
        
        if (texture_search_request != -1)
        {
            var loading_y = search_y + search_h + 5;
            draw_set_color(c_yellow);
            draw_set_halign(fa_left);
            draw_text(search_x + 10, loading_y, "Buscando...");
        }
    }
    
    var thumb_y = texture_section_y + (texture_enabled ? 90 : 35);
    var btn_size = 40;
    var spacing = 10;
    var thumb_w = 260;
    var total_buttons_w = thumb_w + spacing + btn_size;
    var buttons_start_x = centro_x - (total_buttons_w / 2);
    var thumb_x = buttons_start_x;
    var hover_thumb = mx > thumb_x && mx < (thumb_x + thumb_w) && my > thumb_y && my < (thumb_y + btn_size);
    
    if (mouse_check_button_pressed(mb_left) && hover_thumb && !texture_dropdown_open)
    {
        if (os_type == os_android)
        {
            show_debug_message("Llamando al selector de imagenes nativo...");
            openImagePicker();
        }
        else
        {
            var img_path = get_open_filename("Imagenes PNG|*.png", "");
            
            if (img_path != "")
            {
                thumbnail_path = img_path;
                has_thumbnail = 1;
            }
        }
    }
    
    var thumb_text;
    
    if (has_thumbnail)
    {
        draw_set_color(c_lime);
        thumb_text = "FOTO: " + filename_name(thumbnail_path);
        
        if (string_length(thumb_text) > 25)
            thumb_text = string_copy(thumb_text, 1, 25) + "...";
    }
    else
    {
        draw_set_color(hover_thumb ? color_boton_hover : c_gray);
        thumb_text = "AGREGAR FOTO (REQUERIDO)";
    }
    
    draw_roundrect(thumb_x, thumb_y, thumb_x + thumb_w, thumb_y + btn_size, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(thumb_x + (thumb_w / 2), thumb_y + (btn_size / 2), thumb_text);
    var upload_btn_x = thumb_x + thumb_w + spacing;
    var upload_btn_y = thumb_y;
    var can_upload = ds_list_size(tags_seleccionados) > 0 && has_thumbnail && discord_linked == 1;
    
    if (texture_enabled && texture_selected_name == "")
        can_upload = false;
    
    var btn_color = can_upload ? color_boton : make_colour_rgb(64, 64, 64);
    var hover_upload = mx > upload_btn_x && mx < (upload_btn_x + btn_size) && my > upload_btn_y && my < (upload_btn_y + btn_size);
    
    if (can_upload && hover_upload)
        btn_color = color_boton_hover;
    
    draw_set_color(btn_color);
    draw_roundrect(upload_btn_x, upload_btn_y, upload_btn_x + btn_size, upload_btn_y + btn_size, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var arrow_cx = upload_btn_x + (btn_size / 2);
    var arrow_cy = upload_btn_y + (btn_size / 2);
    var arrow_size = 10;
    draw_triangle(arrow_cx - (arrow_size * 0.5), arrow_cy - arrow_size, arrow_cx - (arrow_size * 0.5), arrow_cy + arrow_size, arrow_cx + arrow_size, arrow_cy, false);
    
    if (mouse_check_button_pressed(mb_left) && hover_upload && can_upload && !texture_dropdown_open)
    {
        loading = 1;
        estado = 2;
        mensaje = "Iniciando carga...";
        var ext = filename_ext(level_path);
        var unique_id = string(global.user_id) + "_" + string(date_get_second_of_year(date_current_datetime()));
        r2_file_name = unique_id + ext;
        r2_thumb_name = unique_id + "_thumb.png";
        upload_step = 1;
        cold_storage_id = "";
        mensaje = "Subiendo archivo del nivel...";
        request_upload_level = scr_upload_pack(level_path, thumbnail_path, r2_file_name, r2_thumb_name, global.worker_telegram_url);
        catbox_file_id = "";
        request_catbox = scr_catbox_upload(level_path);
    }
    
    var back_hover = mx > 20 && mx < 120 && my > 20 && my < 60;
    draw_set_color(back_hover ? c_ltgray : c_gray);
    draw_roundrect(20, 20, 120, 60, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(70, 40, "ATRAS");
    
    if (mouse_check_button_pressed(mb_left) && back_hover && !texture_dropdown_open)
        estado = 1;
    
    var info_y = thumb_y + btn_size + 15;
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    if (!has_thumbnail)
    {
        draw_set_color(c_yellow);
        draw_text(centro_x, info_y, "* Debes agregar una foto");
    }
    else if (ds_list_size(tags_seleccionados) == 0)
    {
        draw_set_color(c_yellow);
        draw_text(centro_x, info_y, "* Selecciona al menos 1 etiqueta");
    }
    else if (texture_enabled && texture_selected_name == "")
    {
        draw_set_color(c_yellow);
        draw_text(centro_x, info_y, "* Selecciona una textura o desactiva la opción");
    }
    else if (discord_linked != 1)
    {
        draw_set_color(c_red);
        draw_text(centro_x, info_y, "* Vincula Discord para subir niveles");
    }
    else
    {
        draw_set_color(c_lime);
        draw_text(centro_x, info_y, "¡Listo para subir!");
    }
}
else if (estado == 2)
{
    draw_set_color(c_white);
    draw_text_transformed(centro_x, 150, "SUBIENDO NIVEL", 1.5, 1.5, 0);
    draw_set_color(color_boton);
    draw_text(centro_x, 220, mensaje);
    var loading_x = centro_x;
    var loading_y = 280;
    var angle = (current_time / 10) % 360;
    
    for (var j = 0; j < 8; j++)
    {
        var a = angle + (j * 45);
        var dist = 30;
        var px = loading_x + lengthdir_x(dist, a);
        var py = loading_y + lengthdir_y(dist, a);
        draw_set_alpha(1 - (j / 8));
        draw_circle(px, py, 5, false);
    }
    
    draw_set_alpha(1);
}
else if (estado == 3)
{
    draw_set_color(c_lime);
    draw_text_transformed(centro_x, 150, "¡NIVEL SUBIDO!", 2, 2, 0);
    draw_set_color(c_white);
    draw_text(centro_x, 220, "Tu nivel ya está disponible");
    var btn_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > 300 && my < 340;
    draw_set_color(btn_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 100, 300, centro_x + 100, 340, false);
    draw_set_color(c_white);
    draw_text(centro_x, 320, "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && btn_hover)
        room_goto_previous();
}
else if (estado == 4)
{
    draw_set_color(c_red);
    draw_text_transformed(centro_x, 120, "ERROR", 2, 2, 0);
    draw_set_color(c_white);
    draw_text_ext(centro_x, 180, mensaje, 16, 500);
    var btn_hover = mx > (centro_x - 100) && mx < (centro_x + 100) && my > 300 && my < 340;
    draw_set_color(btn_hover ? color_boton_hover : color_boton);
    draw_roundrect(centro_x - 100, 300, centro_x + 100, 340, false);
    draw_set_color(c_white);
    draw_text(centro_x, 320, "REINTENTAR");
    
    if (mouse_check_button_pressed(mb_left) && btn_hover)
        estado = 0;
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
