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
    draw_text(room_width / 2, panel_y + 10, "SELECCIONAR FOTO DE PERFIL");
    
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

if (surface_exists(application_surface))
{
    if (surface_get_width(application_surface) < window_get_width())
        surface_resize(application_surface, window_get_width(), window_get_height());
}

draw_set_font(global.font);

var _sc = perfil_sc;
var _ox = perfil_ox;
var _oy = perfil_oy;
draw_sprite_ext(spr_perfil_fondo, 0, _ox, _oy, _sc, _sc, 0, c_white, 1);

draw_sprite_ext(spr_perfil_boton_volver, 0, _ox + 10 * _sc, _oy + 10 * _sc, _sc, _sc, 0, c_white, 1);
if (hover_volver_a > 0)
    draw_sprite_ext(spr_perfil_boton_volver, 0, _ox + 10 * _sc, _oy + 10 * _sc, _sc, _sc, 0, c_black, 0.25 * hover_volver_a);
draw_sprite_ext(spr_perfil_flecha_volver, 0, _ox + 15 * _sc, _oy + 16 * _sc, _sc, _sc, 0, c_white, 1);

var _cs_col = merge_colour(make_colour_rgb(150, 50, 50), c_white, 0.3 * hover_cerrar_a);
scr_perfil_nine_slice(spr_insignia_base, _ox + 290 * _sc, _oy + 10 * _sc, 84 * _sc, 20 * _sc, _sc, 1, 1, 1, 3, _cs_col);

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text_transformed(_ox + 192 * _sc, _oy + 14 * _sc, "MI PERFIL", _sc, _sc, 0);
draw_text_transformed(_ox + 42 * _sc, _oy + 20 * _sc, "VOLVER", 0.8 * _sc, 0.8 * _sc, 0);
draw_text_transformed(_ox + 332 * _sc, _oy + 20 * _sc, "CERRAR SESION", 0.8 * _sc, 0.8 * _sc, 0);

if (loading)
{
    draw_set_color(color_accent);
    draw_text_transformed(_ox + 192 * _sc, _oy + 100 * _sc, "CARGANDO...", _sc, _sc, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    exit;
}

// ---- name card ----
scr_perfil_nine_slice(spr_perfil_panel, _ox + 10 * _sc, _oy + 36 * _sc, 364 * _sc, 64 * _sc, _sc, 1, 1, 1, 3);

// la tarjeta equipada va de fondo, recortada al alto de la card y dentro
// del marco del panel (1px arriba y a los lados, 3 abajo)
var _tar = scr_tarjeta_actual_spr();
if (_tar >= 0)
{
    draw_sprite_general(_tar, 0, 0, 11, 110, 18, _ox + 11 * _sc, _oy + 37 * _sc, (362 * _sc) / 110, (60 * _sc) / 18, 0, c_white, c_white, c_white, c_white, 1);
    scr_perfil_nine_slice(spr_perfil_seleccion, _ox + 8 * _sc, _oy + 34 * _sc, 368 * _sc, 68 * _sc, _sc, 2, 2, 2, 2);
}

// el avatar es la celda de icono, tocandolo se abre el menu de iconos
draw_sprite_ext(spr_perfil_celda_icono, 0, _ox + 18 * _sc, _oy + 48 * _sc, _sc, _sc, 0, c_white, 1);
var _icono_sel = scr_icono_actual_spr();

if (_icono_sel >= 0)
{
    draw_sprite_stretched(_icono_sel, 0, _ox + 18 * _sc, _oy + 48 * _sc, 35 * _sc, 35 * _sc);
}
else if (profile_image_sprite != -1 && sprite_exists(profile_image_sprite))
{
    var spr_w = sprite_get_width(profile_image_sprite);
    var spr_h = sprite_get_height(profile_image_sprite);
    
    if (spr_w > 0 && spr_h > 0)
    {
        gpu_set_texfilter(true);
        draw_sprite_stretched(profile_image_sprite, 0, _ox + 18 * _sc, _oy + 48 * _sc, 35 * _sc, 35 * _sc);
        gpu_set_texfilter(false);
    }
}
else if (profile_image_loading)
{
    draw_set_color(c_gray);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(_ox + 35 * _sc, _oy + 65 * _sc, "...", 0.8 * _sc, 0.8 * _sc, 0);
}

var _lx = (mx - _ox) / _sc;
var _ly = (my - _oy) / _sc;
if (_lx >= 18 && _lx <= 53 && _ly >= 48 && _ly <= 84)
{
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(_ox + 18 * _sc, _oy + 48 * _sc, _ox + 53 * _sc - 1, _oy + 83 * _sc - 1, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(_ox + 35 * _sc, _oy + 65 * _sc, "CAMBIAR", 0.45 * _sc, 0.45 * _sc, 0);
}

// nombre y handle
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(color_accent);
draw_text_transformed(_ox + 60 * _sc, _oy + 45 * _sc, string_upper(global.user_name), 1.2 * _sc, 1.2 * _sc, 0);

if (discord_linked && discord_username != "")
{
    draw_set_color(c_ltgray);
    draw_text_transformed(_ox + 60 * _sc, _oy + 60 * _sc, "@" + string_upper(discord_username), 0.8 * _sc, 0.8 * _sc, 0);
}

// caja de nivel con icono placeholder segun el rango
scr_perfil_nine_slice(spr_perfil_retrato, _ox + 258 * _sc, _oy + 44 * _sc, 108 * _sc, 47 * _sc, _sc, 0, 0, 0, 1);
var _spr_nivel = spr_fireflower;
if (user_current_level <= 10)
    _spr_nivel = spr_mushroom;
draw_sprite_stretched(_spr_nivel, 0, _ox + 264 * _sc, _oy + 52 * _sc, 20 * _sc, 20 * _sc);

var level_color = scr_get_level_color(user_current_level);
draw_set_color(level_color);
draw_text_transformed(_ox + 290 * _sc, _oy + 49 * _sc, "NIVEL " + string(user_current_level), 0.9 * _sc, 0.9 * _sc, 0);

var xp_for_current = scr_get_total_xp_for_level(user_current_level);
var xp_for_next = scr_get_xp_for_level(user_current_level);
var xp_progress = user_total_xp - xp_for_current;
var xp_percent = 0;

if (xp_for_next > 0)
    xp_percent = clamp(xp_progress / xp_for_next, 0, 1);

scr_perfil_nine_slice(spr_perfil_scroll_canal, _ox + 290 * _sc, _oy + 64 * _sc, 68 * _sc, 7 * _sc, _sc, 1, 1, 1, 1);
if (xp_percent > 0.01)
{
    draw_set_color(level_color);
    draw_rectangle(_ox + 291 * _sc, _oy + 65 * _sc, _ox + (290 + floor(66 * xp_percent)) * _sc - 1, _oy + 70 * _sc - 1, false);
}

draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_top);
if (user_current_level >= 50)
    draw_text_transformed(_ox + 312 * _sc, _oy + 76 * _sc, "MAX", 0.7 * _sc, 0.7 * _sc, 0);
else
    draw_text_transformed(_ox + 312 * _sc, _oy + 76 * _sc, string(floor(xp_progress)) + " / " + string(xp_for_next), 0.7 * _sc, 0.7 * _sc, 0);

// ---- barra de stats ----
scr_perfil_nine_slice(spr_perfil_panel, _ox + 10 * _sc, _oy + 106 * _sc, 364 * _sc, 18 * _sc, _sc, 1, 1, 1, 3);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_text_transformed(_ox + 18 * _sc, _oy + 111 * _sc, "MIEMBRO DESDE: ", 0.8 * _sc, 0.8 * _sc, 0);
var _w1 = string_width("MIEMBRO DESDE: ") * 0.8;
draw_text_transformed(_ox + (18 + _w1) * _sc, _oy + 111 * _sc, string_upper(member_since), 0.8 * _sc, 0.8 * _sc, 0);
draw_text_transformed(_ox + 210 * _sc, _oy + 111 * _sc, "NIVELES SUBIDOS: ", 0.8 * _sc, 0.8 * _sc, 0);
var _w2 = string_width("NIVELES SUBIDOS: ") * 0.8;
draw_text_transformed(_ox + (210 + _w2) * _sc, _oy + 111 * _sc, string(levels_count), 0.8 * _sc, 0.8 * _sc, 0);

// ---- insignias ----
    scr_perfil_nine_slice(spr_perfil_barra_categoria, _ox + 10 * _sc, _oy + 130 * _sc, 364 * _sc, 11 * _sc, _sc, 1, 1, 1, 2, c_white, 0.22 * hover_sec_insig_a);
draw_set_color(c_white);
draw_text_transformed(_ox + 16 * _sc, _oy + 132 * _sc, "INSIGNEAS", _sc, _sc, 0);
if (sec_insig_col)
    draw_sprite_ext(spr_perfil_signo_mas, 0, _ox + 365 * _sc, _oy + 132 * _sc, _sc, _sc, 0, c_white, 1);
else
    draw_sprite_ext(spr_perfil_signo_menos, 0, _ox + 365 * _sc, _oy + 134 * _sc, _sc, _sc, 0, c_white, 1);

if (!sec_insig_col)
{
    if (ds_list_size(my_badges) == 0)
    {
        draw_set_color(c_white);
        draw_text_transformed(_ox + 10 * _sc, _oy + 146 * _sc, "NO TENES INSIGNIAS AUN", 0.8 * _sc, 0.8 * _sc, 0);
    }
    else
    {
        var _n = min(array_length(insig_rects), ds_list_size(my_badges));
        for (var i = 0; i < _n; i++)
        {
            var _r = insig_rects[i];
            var badge = ds_list_find_value(my_badges, i);
            var badge_name = ds_map_find_value(badge, "name");
            var icon_name = ds_map_find_value(badge, "icon_name");
            var badge_color_real = scr_get_badge_color(icon_name);
            var _tin = badge_color_real;

            if (badge_hover_index == i)
                _tin = merge_colour(badge_color_real, c_white, 0.3);

            scr_perfil_nine_slice(spr_insignia_base, _ox + _r.x * _sc, _oy + _r.y * _sc, _r.w * _sc, 22 * _sc, _sc, 1, 1, 1, 3, _tin);

            draw_set_color(c_white);
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            draw_text_transformed(_ox + (_r.x + 8) * _sc, _oy + (_r.y + 10) * _sc, string_upper(badge_name), 0.8 * _sc, 0.8 * _sc, 0);

            if (badge_hover_index == i && global.user_is_admin)
            {
                draw_set_color(c_red);
                draw_set_halign(fa_center);
                draw_text_transformed(_ox + (_r.x + _r.w - 8) * _sc, _oy + (_r.y + 10) * _sc, "X", 0.8 * _sc, 0.8 * _sc, 0);
            }
        }
    }

    // el mas para agregar, solo admins
    if (global.user_is_admin)
    {
        scr_perfil_nine_slice(spr_perfil_celda_icono, _ox + insig_add_x * _sc, _oy + insig_add_y * _sc, 22 * _sc, 23 * _sc, _sc, 0, 0, 0, 1);
        draw_sprite_ext(spr_perfil_signo_mas, 0, _ox + (insig_add_x + 8) * _sc, _oy + (insig_add_y + 8) * _sc, _sc, _sc, 0, c_white, 1);
    }
}

if (show_badge_tooltip && tooltip_badge_index >= 0 && tooltip_badge_index < ds_list_size(my_badges))
{
    var badge = ds_list_find_value(my_badges, tooltip_badge_index);
    var awarded_by_name = ds_map_find_value(badge, "awarded_by_name");
    var awarded_at = ds_map_find_value(badge, "awarded_at");
    
    if (is_undefined(awarded_by_name) || awarded_by_name == "")
        awarded_by_name = "Sistema";
    
    if (is_undefined(awarded_at) || awarded_at == "")
        awarded_at = "???";
    
    var tooltip_text = "OTORGADO POR " + string_upper(awarded_by_name) + " EL " + string_upper(awarded_at);
    var tooltip_x = mx + 10;
    var tooltip_y = my - 25;
    var tooltip_w = (string_length(tooltip_text) * 7) + 16;
    var tooltip_h = 22;
    
    if ((tooltip_x + tooltip_w) > room_width)
        tooltip_x = room_width - tooltip_w - 5;
    
    draw_set_color(make_colour_rgb(30, 30, 30));
    draw_set_alpha(0.9);
    draw_roundrect(tooltip_x, tooltip_y, tooltip_x + tooltip_w, tooltip_y + tooltip_h, 0);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(tooltip_x + 8, tooltip_y + (tooltip_h / 2), tooltip_text);
}

// ---- niveles recientes ----
scr_perfil_nine_slice(spr_perfil_barra_categoria, _ox + 10 * _sc, _oy + niveles_y * _sc, 236 * _sc, 11 * _sc, _sc, 1, 1, 1, 2);
if (hover_sec_niveles_a > 0)
    scr_perfil_nine_slice(spr_perfil_barra_categoria, _ox + 10 * _sc, _oy + niveles_y * _sc, 236 * _sc, 11 * _sc, _sc, 1, 1, 1, 2, c_white, 0.22 * hover_sec_niveles_a);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text_transformed(_ox + 16 * _sc, _oy + (niveles_y + 2) * _sc, "MIS NIVELES RECIENTES", _sc, _sc, 0);
if (sec_niveles_col)
    draw_sprite_ext(spr_perfil_signo_mas, 0, _ox + 237 * _sc, _oy + (niveles_y + 2) * _sc, _sc, _sc, 0, c_white, 1);
else
    draw_sprite_ext(spr_perfil_signo_menos, 0, _ox + 237 * _sc, _oy + (niveles_y + 4) * _sc, _sc, _sc, 0, c_white, 1);

// boton de discord a la derecha de la barra
var _dis_col = merge_colour(make_colour_rgb(88, 101, 242), c_white, 0.3 * hover_discord_a);
scr_perfil_nine_slice(spr_perfil_boton_foto, _ox + 278 * _sc, _oy + (niveles_y - 3) * _sc, 96 * _sc, 17 * _sc, _sc, 1, 1, 1, 2, _dis_col);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
if (discord_linked)
    draw_text_transformed(_ox + 326 * _sc, _oy + (niveles_y + 5) * _sc, "VINCULADO", 0.8 * _sc, 0.8 * _sc, 0);
else
    draw_text_transformed(_ox + 326 * _sc, _oy + (niveles_y + 5) * _sc, "VINCULAR DISCORD", 0.8 * _sc, 0.8 * _sc, 0);

if (discord_linked && show_discord_tooltip && discord_username != "")
{
    var discord_tooltip_text = "DISCORD: " + string_upper(discord_username);
    var discord_tooltip_w = (string_length(discord_tooltip_text) * 7) + 16;
    var discord_tooltip_h = 22;
    var discord_tooltip_x = mx + 10;
    var discord_tooltip_y = my - 25;
    
    if ((discord_tooltip_x + discord_tooltip_w) > room_width)
        discord_tooltip_x = room_width - discord_tooltip_w - 5;
    
    draw_set_color(make_colour_rgb(54, 57, 63));
    draw_set_alpha(0.95);
    draw_roundrect(discord_tooltip_x, discord_tooltip_y, discord_tooltip_x + discord_tooltip_w, discord_tooltip_y + discord_tooltip_h, 0);
    draw_set_color(make_colour_rgb(88, 101, 242));
    draw_roundrect(discord_tooltip_x, discord_tooltip_y, discord_tooltip_x + discord_tooltip_w, discord_tooltip_y + discord_tooltip_h, 1);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(discord_tooltip_x + 8, discord_tooltip_y + (discord_tooltip_h / 2), discord_tooltip_text);
}

// tarjetas de niveles
if (!sec_niveles_col)
{
    var _cards_y = niveles_y + 17;
    var _cx = 10;
    var _cy = _cards_y;

    if (ds_list_size(my_levels) == 0)
    {
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_text_transformed(_ox + 10 * _sc, _oy + _cy * _sc, "NO SUBISTE NIVELES AUN", 0.8 * _sc, 0.8 * _sc, 0);
    }
    else
    {
        for (var i = 0; i < ds_list_size(my_levels); i++)
        {
            var lvl = ds_list_find_value(my_levels, i);
            var lvl_name = ds_map_find_value(lvl, "name");

            scr_perfil_nine_slice(spr_perfil_panel, _ox + _cx * _sc, _oy + _cy * _sc, 118 * _sc, 20 * _sc, _sc, 1, 1, 1, 3);

            draw_set_color(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            var name_display = lvl_name;

            if (string_length(name_display) > 19)
                name_display = string_copy(name_display, 1, 18) + "..";

            draw_text_transformed(_ox + (_cx + 59) * _sc, _oy + (_cy + 9) * _sc, string_upper(name_display), 0.8 * _sc, 0.8 * _sc, 0);
            _cx += 123;

            if (_cx + 118 > 374)
            {
                _cx = 10;
                _cy += 24;
            }
        }
    }
}

if (show_add_badge_menu)
{
    var menu_w = 220;
    var menu_h = 40 + (ds_list_size(all_badges) * 35);
    var menu_x = centro_x - (menu_w / 2);
    var menu_y = 180;
    draw_set_color(c_black);
    draw_set_alpha(0.8);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);
    draw_set_color(color_panel);
    draw_roundrect(menu_x, menu_y, menu_x + menu_w, menu_y + menu_h, 0);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(menu_x + (menu_w / 2), menu_y + 8, "AGREGAR MEDALLA");
    var close_x = (menu_x + menu_w) - 25;
    var close_y = menu_y + 5;
    var close_size = 20;
    var close_hover = mx > close_x && mx < (close_x + close_size) && my > close_y && my < (close_y + close_size);
    
    if (close_hover)
        draw_set_color(c_red);
    else
        draw_set_color(make_colour_rgb(180, 50, 50));
    
    draw_rectangle(close_x, close_y, close_x + close_size, close_y + close_size, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(close_x + (close_size / 2), close_y + (close_size / 2), "X");
    
    for (var i = 0; i < ds_list_size(all_badges); i++)
    {
        var all_badge = ds_list_find_value(all_badges, i);
        var all_badge_name = ds_map_find_value(all_badge, "name");
        var all_icon_name = ds_map_find_value(all_badge, "icon_name");
        var all_badge_y = menu_y + 35 + (i * 35);
        var item_hover = mx > (menu_x + 10) && mx < ((menu_x + menu_w) - 10) && my > all_badge_y && my < (all_badge_y + 30);
        var badge_color_real = scr_get_badge_color(all_icon_name);
        var badge_sprite = scr_get_badge_sprite(all_icon_name);
        
        if (item_hover)
            draw_set_color(merge_colour(badge_color_real, c_white, 0.3));
        else
            draw_set_color(badge_color_real);
        
        draw_roundrect(menu_x + 10, all_badge_y, (menu_x + menu_w) - 10, all_badge_y + 30, 0);
        
        if (sprite_exists(badge_sprite))
        {
            var icon_scale = 22 / sprite_get_width(badge_sprite);
            draw_sprite_ext(badge_sprite, 0, menu_x + 18, all_badge_y + 4, icon_scale, icon_scale, 0, c_white, 1);
        }
        
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_text(menu_x + 45, all_badge_y + 15, string_upper(all_badge_name));
    }
}

if (show_discord_popup)
{
    var popup_w = 350;
    var popup_h = 200;
    var popup_x = centro_x - (popup_w / 2);
    var popup_y = 150;
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(0, 0, room_width, room_height, false);
    draw_set_alpha(1);
    draw_set_color(make_colour_rgb(54, 57, 63));
    draw_roundrect(popup_x, popup_y, popup_x + popup_w, popup_y + popup_h, 0);
    draw_set_color(make_colour_rgb(88, 101, 242));
    draw_roundrect(popup_x, popup_y, popup_x + popup_w, popup_y + popup_h, 1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text(popup_x + (popup_w / 2), popup_y + 15, "VINCULAR DISCORD");
    draw_set_color(make_colour_rgb(185, 187, 190));
    draw_text(popup_x + (popup_w / 2), popup_y + 45, "USA ESTE CODIGO EN DISCORD:");
    draw_set_color(make_colour_rgb(88, 101, 242));
    draw_text_transformed(popup_x + (popup_w / 2), popup_y + 80, discord_link_code, 2, 2, 0);
    draw_set_color(make_colour_rgb(185, 187, 190));
    draw_text(popup_x + (popup_w / 2), popup_y + 115, "ESCRIBE: /vincular " + discord_link_code);
    var copy_x = (popup_x + (popup_w / 2)) - 60;
    var copy_y = popup_y + 140;
    var copy_hover = mx > copy_x && mx < (copy_x + 120) && my > copy_y && my < (copy_y + 35);
    
    if (copy_hover)
        draw_set_color(make_colour_rgb(108, 121, 255));
    else
        draw_set_color(make_colour_rgb(88, 101, 242));
    
    draw_roundrect(copy_x, copy_y, copy_x + 120, copy_y + 35, 0);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(copy_x + 60, copy_y + 17, "COPIAR");
    var close_popup_x = (popup_x + popup_w) - 30;
    var close_popup_y = popup_y + 5;
    var close_popup_hover = mx > close_popup_x && mx < (close_popup_x + 25) && my > close_popup_y && my < (close_popup_y + 25);
    
    if (close_popup_hover)
        draw_set_color(c_red);
    else
        draw_set_color(make_colour_rgb(150, 150, 150));
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(close_popup_x + 12, close_popup_y + 12, "X");
    draw_set_color(make_colour_rgb(120, 120, 120));
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_text(popup_x + (popup_w / 2), (popup_y + popup_h) - 10, "EL CODIGO EXPIRA EN 10 MINUTOS");
}

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
