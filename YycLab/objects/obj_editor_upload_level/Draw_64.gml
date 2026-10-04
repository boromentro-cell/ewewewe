var mx = device_mouse_x_to_gui(0);
var my = device_mouse_y_to_gui(0);
var cx = 192;
draw_set_color(#1A1A2E);
draw_set_alpha(0.95);
draw_rectangle(0, 0, 384, 216, false);
draw_set_alpha(1);
draw_set_font(global.font);

if (estado == 0)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(#FFF200);
    draw_text(cx, 8, "SUBIR NIVEL");
    draw_set_color(c_white);
    draw_text(cx, 22, "Nivel verificado! Completa la info:");
    draw_set_halign(fa_right);
    var info_col = 16777215;
    var info_text = "";
    
    if (user_upload_count == -1)
    {
        info_text = "Verificando...";
        info_col = 8421504;
    }
    else if (user_upload_limit >= 9999)
    {
        info_text = "Niveles: " + string(user_upload_count) + " / INF";
        info_col = 65280;
    }
    else
    {
        info_text = "Niveles: " + string(user_upload_count) + " / " + string(user_upload_limit);
        info_col = (user_upload_count >= user_upload_limit) ? 255 : 16777215;
    }
    
    draw_set_color(info_col);
    draw_text(380, 8, info_text);
    
    if (discord_linked == 0)
    {
        draw_set_color(c_red);
        draw_text(380, 18, "Discord: NO VINCULADO");
    }
    else if (discord_linked == 1)
    {
        draw_set_color(c_lime);
        draw_text(380, 18, "Discord: OK");
    }
    
    draw_set_halign(fa_left);
    draw_set_color(c_ltgray);
    draw_text(cx - (campo_w / 2), 42, "Nombre:");
    draw_set_color((campo_activo == 1) ? color_campo_activo : color_campo);
    draw_roundrect(cx - (campo_w / 2), 54, cx + (campo_w / 2), 54 + campo_h, false);
    draw_set_color(c_white);
    draw_set_valign(fa_middle);
    var name_display = level_name + ((campo_activo == 1) ? "|" : "");
    draw_text((cx - (campo_w / 2)) + 4, 54 + (campo_h / 2), name_display);
    draw_set_valign(fa_top);
    draw_set_color(c_ltgray);
    draw_text(cx - (campo_w / 2), 90, "Descripcion (opcional):");
    draw_set_color((campo_activo == 2) ? color_campo_activo : color_campo);
    draw_roundrect(cx - (campo_w / 2), 102, cx + (campo_w / 2), 160, false);
    draw_set_color(c_white);
    var desc_display = level_description + ((campo_activo == 2) ? "|" : "");
    draw_text_ext((cx - (campo_w / 2)) + 4, 106, desc_display, 12, campo_w - 8);
    
    if (mouse_check_button_pressed(mb_left))
    {
        if (point_in_rectangle(mx, my, cx - (campo_w / 2), 54, cx + (campo_w / 2), 54 + campo_h))
        {
            campo_activo = 1;
        }
        else if (point_in_rectangle(mx, my, cx - (campo_w / 2), 102, cx + (campo_w / 2), 160))
        {
            campo_activo = 2;
        }
        else
        {
            campo_activo = 0;
        }
    }
    
    var btn_nx = cx - 40;
    var btn_ny = 170;
    var btn_nw = 80;
    var btn_nh = 22;
    var hover_next = point_in_rectangle(mx, my, btn_nx, btn_ny, btn_nx + btn_nw, btn_ny + btn_nh);
    draw_set_color(hover_next ? color_boton_hover : color_boton);
    draw_roundrect(btn_nx, btn_ny, btn_nx + btn_nw, btn_ny + btn_nh, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(btn_nx + (btn_nw / 2), btn_ny + (btn_nh / 2), "SIGUIENTE >");
    
    if (mouse_check_button_pressed(mb_left) && hover_next)
    {
        if (level_name != "")
            estado = 1;
        else
            show_message_async("El nombre es obligatorio.");
    }
    
    var btn_cx = 8;
    var btn_cy = 8;
    var btn_cw = 50;
    var btn_ch = 18;
    var hover_cancel = point_in_rectangle(mx, my, btn_cx, btn_cy, btn_cx + btn_cw, btn_cy + btn_ch);
    draw_set_color(hover_cancel ? c_ltgray : c_gray);
    draw_roundrect(btn_cx, btn_cy, btn_cx + btn_cw, btn_cy + btn_ch, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(btn_cx + (btn_cw / 2), btn_cy + (btn_ch / 2), "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && hover_cancel)
        instance_destroy();
}
else if (estado == 1)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(#FFF200);
    draw_text(cx, 6, "ETIQUETAS & TEXTURA");
    var cols = 4;
    var tag_w = 80;
    var tag_h = 20;
    var spacing_x = 8;
    var spacing_y = 6;
    var total_w = (cols * tag_w) + ((cols - 1) * spacing_x);
    var start_x = cx - (total_w / 2);
    var start_y = 24;
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
        var hover_tag = point_in_rectangle(mx, my, tx, ty, tx + tag_w, ty + tag_h);
        
        if (mouse_check_button_pressed(mb_left) && hover_tag && !texture_dropdown_open)
        {
            if (is_selected)
                ds_list_delete(tags_seleccionados, index_sel);
            else if (ds_list_size(tags_seleccionados) < 3)
                ds_list_add(tags_seleccionados, t_name);
        }
        
        if (is_selected)
        {
            draw_set_color(c_white);
            draw_roundrect(tx - 1, ty - 1, tx + tag_w + 1, ty + tag_h + 1, false);
        }
        
        draw_set_color(is_selected ? t_col : merge_colour(t_col, c_black, 0.5));
        draw_roundrect(tx, ty, tx + tag_w, ty + tag_h, false);
        draw_set_halign(fa_center);
        draw_set_color(is_selected ? c_white : c_ltgray);
        draw_text(tx + (tag_w / 2), ty + (tag_h / 2), string_upper(t_name));
    }
    
    var tex_y = start_y + (ceil(ds_list_size(tags_disponibles) / cols) * (tag_h + spacing_y)) + 8;
    
    // ========================================
    // TEXTURA: Auto-detectada o manual
    // ========================================
    if (auto_texture_detected)
    {
        // --- Textura auto-detectada: badge verde ---
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(c_lime);
        
        var _det_text = "Textura: " + auto_texture_name;
        if (string_length(_det_text) > 38)
            _det_text = string_copy(_det_text, 1, 38) + "...";
        
        draw_text(cx - 140, tex_y + 8, _det_text);
        
        // Botón "Cambiar" para volver al selector manual
        var _chg_x = cx + 90;
        var _chg_y = tex_y;
        var _chg_w = 52;
        var _chg_h = 16;
        var hover_change = point_in_rectangle(mx, my, _chg_x, _chg_y, _chg_x + _chg_w, _chg_y + _chg_h);
        draw_set_color(hover_change ? c_yellow : c_gray);
        draw_roundrect(_chg_x, _chg_y, _chg_x + _chg_w, _chg_y + _chg_h, false);
        draw_set_color(c_black);
        draw_set_halign(fa_center);
        draw_text(_chg_x + (_chg_w / 2), _chg_y + (_chg_h / 2), "Cambiar");
        
        if (mouse_check_button_pressed(mb_left) && hover_change)
        {
            auto_texture_detected = false;
            auto_texture_workshop_id = "";
            texture_enabled = false;
            texture_selected_name = "";
            texture_selected_author = "";
            texture_selected_display = "";
            texture_search_text = "";
        }
        
        tex_y += 22;
    }
    else
    {
        // --- Selector manual de textura (checkbox + buscador) ---
        var cb_x = cx - 140;
        var cb_size = 16;
        var hover_cb = point_in_rectangle(mx, my, cb_x, tex_y, cb_x + cb_size, tex_y + cb_size);
        draw_set_color(hover_cb ? #503C78 : #321E5A);
        draw_roundrect(cb_x, tex_y, cb_x + cb_size, tex_y + cb_size, false);
        draw_set_color(texture_enabled ? #64C864 : c_gray);
        draw_roundrect(cb_x, tex_y, cb_x + cb_size, tex_y + cb_size, true);
        
        if (texture_enabled)
        {
            draw_set_color(#64FF64);
            draw_line_width(cb_x + 3, tex_y + 8, cb_x + 7, tex_y + 12, 1.5);
            draw_line_width(cb_x + 7, tex_y + 12, cb_x + 13, tex_y + 4, 1.5);
        }
        
        if (mouse_check_button_pressed(mb_left) && hover_cb && !texture_dropdown_open)
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
        draw_text(cb_x + cb_size + 6, tex_y + (cb_size / 2), "Textura personalizada");
        
        if (texture_enabled)
        {
            var search_x = cx - 140;
            var search_y = tex_y + 22;
            var search_w = 280;
            var search_h = 22;
            draw_set_color(texture_search_active ? color_campo_activo : color_campo);
            draw_roundrect(search_x, search_y, search_x + search_w, search_y + search_h, false);
            
            if (texture_selected_name != "")
            {
                draw_set_color(#64C864);
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
            
            draw_text(search_x + 4, search_y + (search_h / 2), display_text);
            var hover_search = point_in_rectangle(mx, my, search_x, search_y, search_x + search_w, search_y + search_h);
            
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
                var dropdown_y = search_y + search_h + 1;
                var item_h = 20;
                var dd_count = min(ds_list_size(texture_search_results), 4);
                var dropdown_h = dd_count * item_h;
                draw_set_color(#281946);
                draw_roundrect(search_x, dropdown_y, search_x + search_w, dropdown_y + dropdown_h, false);
                
                for (var i = 0; i < dd_count; i++)
                {
                    var item_y = dropdown_y + (i * item_h);
                    var _map = ds_list_find_value(texture_search_results, i);
                    
                    if (ds_exists(_map, ds_type_map))
                    {
                        var _name = ds_map_find_value(_map, "name");
                        var _author = ds_map_find_value(_map, "author_name");
                        var _display = string(_name) + " - " + string(_author);
                        var hover_item = point_in_rectangle(mx, my, search_x, item_y, search_x + search_w, item_y + item_h);
                        
                        if (hover_item || i == texture_hover_index)
                        {
                            draw_set_color(#46326E);
                            draw_rectangle(search_x + 1, item_y, (search_x + search_w) - 1, (item_y + item_h) - 1, false);
                        }
                        
                        draw_set_color(c_white);
                        draw_set_halign(fa_left);
                        
                        if (string_length(_display) > 40)
                            _display = string_copy(_display, 1, 40) + "...";
                        
                        draw_text(search_x + 4, item_y + (item_h / 2), _display);
                        
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
            }
        }
        
        tex_y += 48;
    }
    
    if (array_length(auto_customs_detected) > 0)
    {
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(#64C8FF);
        draw_text(cx - 140, tex_y + 4, "Custom Objects (" + string(array_length(auto_customs_detected)) + "):");
        tex_y += 14;
        
        var _max_show = min(array_length(auto_customs_detected), 3);
        
        for (var i = 0; i < _max_show; i++)
        {
            var _c = auto_customs_detected[i];
            draw_set_color(c_white);
            
            var _cname = _c.name;
            if (string_length(_cname) > 30)
                _cname = string_copy(_cname, 1, 30) + "...";
            
            draw_text(cx - 130, tex_y + 4, "• " + _cname);
            tex_y += 12;
        }
        
        if (array_length(auto_customs_detected) > 3)
        {
            draw_set_color(c_gray);
            draw_text(cx - 130, tex_y + 4, "+" + string(array_length(auto_customs_detected) - 3) + " más...");
            tex_y += 12;
        }
    }

    
    var can_upload = ds_list_size(tags_seleccionados) > 0 && discord_linked == 1 && (user_upload_count != -1 && user_upload_count < user_upload_limit);
    
    if (texture_enabled && texture_selected_name == "" && !auto_texture_detected)
        can_upload = false;
    
    var btn_ux = cx - 40;
    var btn_uy = 185;
    var btn_uw = 80;
    var btn_uh = 22;
    var hover_upload = point_in_rectangle(mx, my, btn_ux, btn_uy, btn_ux + btn_uw, btn_uy + btn_uh);
    draw_set_color(can_upload ? (hover_upload ? color_boton_hover : color_boton) : c_dkgray);
    draw_roundrect(btn_ux, btn_uy, btn_ux + btn_uw, btn_uy + btn_uh, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(btn_ux + (btn_uw / 2), btn_uy + (btn_uh / 2), "SUBIR");
    
    if (mouse_check_button_pressed(mb_left) && hover_upload && can_upload && !texture_dropdown_open)
    {
        if (!editor_upload_file_is_verified(level_path))
        {
            show_message_async("El archivo cambio. Cerra el subidor y volve a verificar el nivel.");
            exit;
        }
        loading = 1;
        estado = 2;
        mensaje = "Iniciando carga...";
        var unique_id = string(global.user_id) + "_" + string(date_get_second_of_year(date_current_datetime()));
        r2_file_name = unique_id + ".lvl";
        r2_thumb_name = unique_id + "_thumb.png";
        upload_step = 1;
        cold_storage_id = "";
        mensaje = "Subiendo archivo del nivel...";
        request_upload_level = scr_upload_pack(level_path, thumbnail_path, r2_file_name, r2_thumb_name, global.worker_telegram_url);
        catbox_file_id = "";
        request_catbox = scr_catbox_upload(level_path);
    }
    
    var btn_bx = 8;
    var btn_by = 8;
    var btn_bw = 50;
    var btn_bh = 18;
    var hover_back = point_in_rectangle(mx, my, btn_bx, btn_by, btn_bx + btn_bw, btn_by + btn_bh);
    draw_set_color(hover_back ? c_ltgray : c_gray);
    draw_roundrect(btn_bx, btn_by, btn_bx + btn_bw, btn_by + btn_bh, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(btn_bx + (btn_bw / 2), btn_by + (btn_bh / 2), "ATRAS");
    
    if (mouse_check_button_pressed(mb_left) && hover_back && !texture_dropdown_open)
        estado = 0;
    
    draw_set_valign(fa_top);
    var info_y = btn_uy - 14;
    draw_set_halign(fa_center);
    
    if (ds_list_size(tags_seleccionados) == 0)
    {
        draw_set_color(c_yellow);
        draw_text(cx, info_y, "* Selecciona al menos 1 etiqueta");
    }
    else if (texture_enabled && texture_selected_name == "" && !auto_texture_detected)
    {
        draw_set_color(c_yellow);
        draw_text(cx, info_y, "* Selecciona una textura");
    }
    else if (discord_linked != 1)
    {
        draw_set_color(c_red);
        draw_text(cx, info_y, "* Vincula Discord para subir");
    }
    else if (can_upload)
    {
        draw_set_color(c_lime);
        draw_text(cx, info_y, "Listo para subir!");
    }
}
else if (estado == 2)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(cx, 90, "SUBIENDO NIVEL...");
    draw_set_color(color_boton);
    draw_text(cx, 110, mensaje);
    var angle = (current_time / 10) % 360;
    
    for (var j = 0; j < 8; j++)
    {
        var a = angle + (j * 45);
        var px = cx + lengthdir_x(20, a);
        var py = 140 + lengthdir_y(20, a);
        draw_set_alpha(1 - (j / 8));
        draw_set_color(color_boton);
        draw_circle(px, py, 3, false);
    }
    
    draw_set_alpha(1);
}
else if (estado == 3)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_lime);
    draw_text(cx, 80, "NIVEL SUBIDO!");
    draw_set_color(c_white);
    draw_text(cx, 100, "Tu nivel ya esta disponible online");
    var btn_vx = cx - 40;
    var btn_vy = 130;
    var btn_vw = 80;
    var btn_vh = 22;
    var hover_vol = point_in_rectangle(mx, my, btn_vx, btn_vy, btn_vx + btn_vw, btn_vy + btn_vh);
    draw_set_color(hover_vol ? color_boton_hover : color_boton);
    draw_roundrect(btn_vx, btn_vy, btn_vx + btn_vw, btn_vy + btn_vh, false);
    draw_set_color(c_white);
    draw_text(btn_vx + (btn_vw / 2), btn_vy + (btn_vh / 2), "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && hover_vol)
        instance_destroy();
}
else if (estado == 4)
{
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_red);
    draw_text(cx, 80, "ERROR");
    draw_set_color(c_white);
    draw_text_ext(cx, 100, mensaje, 12, 300);
    var btn_rx = cx - 40;
    var btn_ry = 150;
    var btn_rw = 80;
    var btn_rh = 22;
    var hover_retry = point_in_rectangle(mx, my, btn_rx, btn_ry, btn_rx + btn_rw, btn_ry + btn_rh);
    draw_set_color(hover_retry ? color_boton_hover : color_boton);
    draw_roundrect(btn_rx, btn_ry, btn_rx + btn_rw, btn_ry + btn_rh, false);
    draw_set_color(c_white);
    draw_text(btn_rx + (btn_rw / 2), btn_ry + (btn_rh / 2), "VOLVER");
    
    if (mouse_check_button_pressed(mb_left) && hover_retry)
        instance_destroy();
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1);
