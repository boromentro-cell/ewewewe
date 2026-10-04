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
                
                var file_size = 0;
                if (file_exists(selected_path))
                {
                    var f = file_bin_open(selected_path, 0);
                    file_size = file_bin_size(f);
                    file_bin_close(f);
                }
                
                if (file_size > 512000)
                {
                    show_message_async("IMAGEN MUY GRANDE (MAX 500KB)");
                }
                else
                {
                    profile_image_loading = 1;
                    request_upload_image = scr_upload_profile_image(selected_path);
                }
                
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

if (instance_exists(obj_perfil_iconos))
    exit;

// mouse en coords del armado nativo
var mx = mouse_x;
var my = mouse_y;
var _lx = (mx - perfil_ox) / perfil_sc;
var _ly = (my - perfil_oy) / perfil_sc;

var _hv = (_lx >= 10 && _lx <= 62 && _ly >= 10 && _ly <= 30);
hover_volver_a = clamp(hover_volver_a + (_hv ? 0.18 : -0.18), 0, 1);
var _hc = (_lx >= 290 && _lx <= 374 && _ly >= 10 && _ly <= 30);
hover_cerrar_a = clamp(hover_cerrar_a + (_hc ? 0.18 : -0.18), 0, 1);

if (mouse_check_button_pressed(mb_left))
{
    if (_hv)
    {
        room_goto(rm_Titulo);
        exit;
    }
    
    if (_hc)
    {
        scr_supabase_logout();
        room_goto(rm_Titulo);
        exit;
    }
}

if (loading)
{
    if (request_profile == -1 && request_levels == -1 && request_badges == -1 && request_stats == -1)
        loading = 0;
}

if (loading)
    exit;

insig_rects = [];
var _bx = 10;
var _by = 146;
if (!sec_insig_col)
{
    for (var i = 0; i < ds_list_size(my_badges); i++)
    {
        var badge = ds_list_find_value(my_badges, i);
        var badge_name = ds_map_find_value(badge, "name");
        var _bw = (string_length(badge_name) * 11) div 2 + 16;
        if (_bx + _bw > 374)
        {
            _bx = 10;
            _by += 28;
        }
        array_push(insig_rects, { x: _bx, y: _by, w: _bw });
        _bx += _bw + 6;
    }

    // el mas va despues de la ultima insignia
    if (ds_list_size(my_badges) == 0)
    {
        insig_add_x = 140;
        insig_add_y = 146;
    }
    else
    {
        if (_bx + 22 > 374)
        {
            _bx = 10;
            _by += 28;
        }
        insig_add_x = _bx;
        insig_add_y = _by;
    }
    niveles_y = _by + 30;
}
else
    niveles_y = 146;

var _hbi = (_lx >= 10 && _lx <= 374 && _ly >= 130 && _ly <= 141);
hover_sec_insig_a = clamp(hover_sec_insig_a + (_hbi ? 0.18 : -0.18), 0, 1);
var _hbn = (_lx >= 10 && _lx <= 246 && _ly >= niveles_y && _ly <= niveles_y + 11);
hover_sec_niveles_a = clamp(hover_sec_niveles_a + (_hbn ? 0.18 : -0.18), 0, 1);

// con un popup abierto las barras no se tocan
if (mouse_check_button_pressed(mb_left) && !show_discord_popup && !show_add_badge_menu)
{
    if (_hbi)
        sec_insig_col = !sec_insig_col;
    else if (_hbn)
        sec_niveles_col = !sec_niveles_col;
}

if (show_discord_popup)
{
    var popup_w = 350;
    var popup_h = 200;
    var popup_x = centro_x - (popup_w / 2);
    var popup_y = 150;
    var close_popup_x = (popup_x + popup_w) - 30;
    var close_popup_y = popup_y + 5;
    
    if (mouse_check_button_pressed(mb_left))
    {
        if (mx > close_popup_x && mx < (close_popup_x + 25) && my > close_popup_y && my < (close_popup_y + 25))
            show_discord_popup = 0;
        
        var copy_x = (popup_x + (popup_w / 2)) - 60;
        var copy_y = popup_y + 140;
        
        if (mx > copy_x && mx < (copy_x + 120) && my > copy_y && my < (copy_y + 35))
        {
            clipboard_set_text(discord_link_code);
            show_message_async("¡Código copiado al portapapeles!");
        }
    }
    
    exit;
}

if (show_add_badge_menu)
{
    var menu_w = 220;
    var menu_h = 40 + (ds_list_size(all_badges) * 35);
    var menu_x = centro_x - (menu_w / 2);
    var menu_y = 180;
    var close_x = (menu_x + menu_w) - 25;
    var close_y = menu_y + 5;
    var close_size = 20;
    
    if (mouse_check_button_pressed(mb_left))
    {
        if (mx > close_x && mx < (close_x + close_size) && my > close_y && my < (close_y + close_size))
        {
            show_add_badge_menu = 0;
        }
        else if (mx > menu_x && mx < (menu_x + menu_w) && my > (menu_y + 30) && my < (menu_y + menu_h))
        {
            var i = 0;
            
            while (i < ds_list_size(all_badges))
            {
                var all_badge_y = menu_y + 35 + (i * 35);
                
                if (my > all_badge_y && my < (all_badge_y + 30) && mx > (menu_x + 10) && mx < ((menu_x + menu_w) - 10))
                {
                    var all_badge = ds_list_find_value(all_badges, i);
                    var badge_id_target = ds_map_find_value(all_badge, "id");
                    request_award_badge = scr_award_badge(global.user_id, badge_id_target);
                    show_add_badge_menu = 0;
                    break;
                }
                else
                {
                    i++;
                    continue;
                }
            }
        }
    }
    
    exit;
}

var discord_hover_timer_threshold = game_get_speed(gamespeed_fps) * 0.4;
var _hd = (_lx >= 278 && _lx <= 374 && _ly >= niveles_y - 3 && _ly <= niveles_y + 14);
hover_discord_a = clamp(hover_discord_a + (_hd ? 0.18 : -0.18), 0, 1);

if (discord_linked && _hd)
{
    discord_hover_timer += 1;
    
    if (discord_hover_timer >= discord_hover_timer_threshold)
        show_discord_tooltip = 1;
}
else
{
    discord_hover_timer = 0;
    show_discord_tooltip = 0;
}

if (mouse_check_button_pressed(mb_left))
{
    if (_hd && !discord_linked)
        request_discord_link = scr_request_discord_link();

    // tocar el avatar abre el menu de iconos, el selector de archivo
    // queda en el boton MI FOTO de ahi adentro
    if (_lx >= 18 && _lx <= 53 && _ly >= 48 && _ly <= 84)
        scr_perfil_menu_abrir();
}

// hover de insignias para el tooltip y el borrado de admins
var current_hover = -1;
for (var i = 0; i < array_length(insig_rects); i++)
{
    var _r = insig_rects[i];
    if (_lx >= _r.x && _lx <= _r.x + _r.w && _ly >= _r.y && _ly <= _r.y + 22)
    {
        current_hover = i;
        
        if (mouse_check_button_pressed(mb_left) && global.user_is_admin)
        {
            var badge = ds_list_find_value(my_badges, i);
            var badge_name = ds_map_find_value(badge, "name");
            var user_badge_id = ds_map_find_value(badge, "user_badge_id");
            
            if (show_question("¿Eliminar la medalla '" + badge_name + "'?"))
                request_remove_badge = scr_remove_badge(user_badge_id);
        }
    }
}

if (current_hover != -1)
{
    if (current_hover == badge_hover_index)
    {
        badge_hover_timer += 1;
        
        if (badge_hover_timer >= badge_hover_threshold)
        {
            show_badge_tooltip = 1;
            tooltip_badge_index = current_hover;
        }
    }
    else
    {
        badge_hover_index = current_hover;
        badge_hover_timer = 0;
        show_badge_tooltip = 0;
    }
}
else
{
    badge_hover_index = -1;
    badge_hover_timer = 0;
    show_badge_tooltip = 0;
}

if (global.user_is_admin && !sec_insig_col)
{
    if (mouse_check_button_pressed(mb_left))
    {
        if (_lx >= insig_add_x && _lx <= insig_add_x + 22 && _ly >= insig_add_y && _ly <= insig_add_y + 23)
        {
            show_add_badge_menu = 1;
            
            if (!all_badges_loaded)
                request_all_badges = scr_get_all_badges();
        }
    }
}
