var mx = mouse_x;
var my = mouse_y;

// miniaturas en HD
if (surface_exists(application_surface))
{
    if (surface_get_width(application_surface) < window_get_width())
        surface_resize(application_surface, window_get_width(), window_get_height());
}

var top_limit = header_height;
draw_set_font(global.font);
var previous_depth = gpu_get_depth();
gpu_set_depth(-255);
// el bg de arriba
var bgs = [bg_night_01, bg_night_02, bg_night_03, bg_night_04];
var anim_index = floor((current_time / 125) % array_length(bgs));
var current_spr = bgs[anim_index];

if (sprite_exists(current_spr))
{
    var spr_w = sprite_get_width(current_spr);
    
    for (var ix = 0; ix < room_width; ix += spr_w)
        draw_sprite_part(current_spr, 0, 0, 0, spr_w, header_height, ix, -1);
}
else
{
    var header_bg_color = 16118514;
    draw_set_color(header_bg_color);
    draw_set_alpha(1);
    draw_rectangle(0, -1, room_width, header_height, false);
}

// el ancho de cada pestaña
var available_width = room_width - tab_reserved_space;
var total_gaps = tab_gap * (total_tabs - 1);
var single_tab_w = (available_width - total_gaps) / total_tabs;
var current_tab_y = top_limit - 30;

// primero las pestañas que no estan activas
for (var i = 0; i < total_tabs; i++)
{
    var t_mode = tabs_data[i][1];
    
    if (view_mode == t_mode)
        continue;
    
    var tx = i * (single_tab_w + tab_gap);
    var is_hover = mx > tx && mx < (tx + single_tab_w) && my > current_tab_y && my < (current_tab_y + tab_height);
    var col_blend = is_hover ? 12632256 : 16777215;
    draw_sprite_stretched_ext(spr_boton_test, 1, tx, current_tab_y, single_tab_w, tab_height, col_blend, 1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_ltgray);
    draw_text(tx + (single_tab_w / 2), current_tab_y + (tab_height / 2), tabs_data[i][0]);
}

// y despues la activa sola, asi queda dibujada arriba de las otras y no la tapa el borde
for (var i = 0; i < total_tabs; i++)
{
    var t_mode = tabs_data[i][1];
    
    if (view_mode != t_mode)
        continue;
    
    var tx = i * (single_tab_w + tab_gap);
    draw_sprite_stretched(spr_boton_test, 0, tx, current_tab_y, single_tab_w, tab_height);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text_color(tx + (single_tab_w / 2) + 1, current_tab_y + (tab_height / 2) + 1, tabs_data[i][0], c_black, c_black, c_black, c_black, 0.4);
    draw_text(tx + (single_tab_w / 2), current_tab_y + (tab_height / 2), tabs_data[i][0]);
}

// la pestaña de reportados
if (variable_global_exists("user_is_admin") && global.user_is_admin)
{
    var admin_tab_x = total_tabs * (single_tab_w + tab_gap);
    var admin_tab_w = 40;
    var admin_hover = mx > admin_tab_x && mx < (admin_tab_x + admin_tab_w) && my > current_tab_y && my < (current_tab_y + tab_height);
    var admin_col = admin_hover ? 9211135 : 6579430;
    
    if (view_mode == 5)
        admin_col = 3289855;
    
    draw_set_color(admin_col);
    draw_roundrect_ext(admin_tab_x, current_tab_y, admin_tab_x + admin_tab_w, current_tab_y + tab_height, 6, 6, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(admin_tab_x + (admin_tab_w / 2), current_tab_y + (tab_height / 2), "!", 1.2, 1.2, 0);
}

gpu_set_depth(previous_depth);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
// los carteles de lista vacia. se muestran solo cuando ya termino de cargar
var separator_y = (header_height + tab_height + 15) - scroll_y;

if (separator_y > top_limit && separator_y < room_height)
{
    if (view_mode == 1)
    {
        draw_set_color(#3C3C41);
        
        if (ds_list_size(global.id_levels) == 0 && !loading)
        {
            draw_set_halign(fa_center);
            draw_set_color(#646469);
            draw_text(room_width / 2, separator_y + 100, "No hay niveles destacados todavía");
        }
    }
    else if (view_mode == 2)
    {
        if (ds_list_size(global.id_levels) == 0 && !loading)
        {
            draw_set_halign(fa_center);
            draw_set_color(#646469);
            draw_text(room_width / 2, separator_y + 100, "No hay niveles para mostrar");
        }
    }
    else if (view_mode == 3)
    {
        if (ds_list_size(global.id_levels) == 0 && !loading)
        {
            draw_set_halign(fa_center);
            draw_set_color(#646469);
            draw_text(room_width / 2, separator_y + 100, "No hay niveles difíciles todavía");
        }
    }
    else if (view_mode == 5)
    {
        if (ds_list_size(global.id_levels) == 0 && !loading)
        {
            draw_set_halign(fa_center);
            draw_set_color(#646469);
            draw_text(room_width / 2, separator_y + 100, "No hay niveles denunciados");
        }
    }
}

draw_set_color(c_white);

if (loading)
{
    var num = ds_list_size(global.id_levels);
    var loader_y = ((list_start_y + (num * card_height)) - scroll_y) + 60;
    var loader_x = room_width / 2;
    loading_rotation -= 5;
    
    if (sprite_exists(loading_sprite))
        draw_sprite_ext(loading_sprite, 0, loader_x, loader_y, 1, 1, loading_rotation, c_white, 1);
    
    draw_set_halign(fa_center);
    draw_set_color(#3C3C41);
    draw_text(loader_x, loader_y + 40, "CARGANDO...");
}

// el mismo cartel sirve para el cooldown normal y para el freno por spam, cambia el texto
if (variable_instance_exists(id, "request_cooldown") && request_cooldown > 0)
{
    var warning_x = room_width / 2;
    var warning_y = room_height - 35;
    
    draw_set_halign(fa_center);
    draw_set_color(c_white);
    
    if (variable_instance_exists(id, "spam_message_active") && spam_message_active)
    {
        draw_text(warning_x, warning_y, "no vayas tan rapido, ya vas a encontrar lo que estas buscando");
    }
    else
    {
        draw_text(warning_x, warning_y, "ESPERA " + string(ceil(request_cooldown / 60)) + "s...");
    }
}

draw_set_halign(fa_left);

if (view_mode == 0 && global.autor_s != "")
{
    var current_tab_y_fijo = header_height - 30;
    var filter_y = (current_tab_y_fijo + tab_height + 20) - scroll_y;
    
    if (filter_y > top_limit)
    {
        draw_set_color(#00B4C8);
        draw_roundrect(10, filter_y, 350, filter_y + 30, 0);
        draw_set_color(c_white);
        draw_text(20, filter_y + 8, "NIVELES DE: " + string_upper(global.autor_s));
        draw_set_color(#C83C3C);
        draw_rectangle(320, filter_y + 3, 345, filter_y + 27, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(332, filter_y + 15, "X");
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
}

// la barra de scroll
if (scroll_max > 0)
{
    var sb_track_h = room_height - scrollbar_margin_top - scrollbar_margin_bottom;
    draw_set_alpha(scrollbar_alpha * 0.3);
    draw_set_color(scrollbar_track_color);
    draw_roundrect_ext(scrollbar_x, scrollbar_margin_top, scrollbar_x + scrollbar_width, scrollbar_margin_top + sb_track_h, 4, 4, false);
    var thumb_color = scrollbar_color;
    
    if (scrollbar_dragging)
        thumb_color = scrollbar_color_drag;
    else if (scrollbar_hover)
        thumb_color = scrollbar_color_hover;
    
    draw_set_alpha(scrollbar_alpha);
    draw_set_color(thumb_color);
    draw_roundrect_ext(scrollbar_x, scrollbar_thumb_y, scrollbar_x + scrollbar_width, scrollbar_thumb_y + scrollbar_thumb_height, 4, 4, false);
    draw_set_alpha(scrollbar_alpha * 0.3);
    draw_set_color(c_black);
    draw_roundrect_ext(scrollbar_x, scrollbar_thumb_y, scrollbar_x + scrollbar_width, scrollbar_thumb_y + scrollbar_thumb_height, 4, 4, true);
}

draw_set_color(c_white);
// el boton de refrescar
var ref_x = room_width - 45;
var ref_y = header_height - 55;
var ref_r = 16;
var ref_alpha = (loading || cleanup_active || refresh_cooldown > 0) ? 0.3 : (0.6 + (refresh_hover_progress * 0.4));
var ref_col = merge_colour(#96969B, c_white, refresh_hover_progress);
draw_set_alpha(ref_alpha);
draw_set_color(merge_colour(#28282D, #3C3C41, refresh_hover_progress));
draw_circle(ref_x, ref_y, ref_r + (refresh_hover_progress * 2), false);
var icon_angle = refresh_spinning ? refresh_spin_angle : 0;
var arrow_segments = 10;
var arrow_radius = 9 + (refresh_hover_progress * 1);
draw_set_color(ref_col);


for (var i = 0; i < arrow_segments; i++)
{
    var a1 = icon_angle + 30 + (i * 27);
    var a2 = icon_angle + 30 + ((i + 1) * 27);
    var x1 = ref_x + lengthdir_x(arrow_radius, a1);
    var y1 = ref_y + lengthdir_y(arrow_radius, a1);
    var x2 = ref_x + lengthdir_x(arrow_radius, a2);
    var y2 = ref_y + lengthdir_y(arrow_radius, a2);
    draw_line_width(x1, y1, x2, y2, 2);
}

var tip_angle = icon_angle + 30;
var tip_x = ref_x + lengthdir_x(arrow_radius, tip_angle);
var tip_y = ref_y + lengthdir_y(arrow_radius, tip_angle);
draw_triangle(tip_x + lengthdir_x(6, tip_angle - 90), tip_y + lengthdir_y(6, tip_angle - 90), tip_x + lengthdir_x(6, tip_angle + 150), tip_y + lengthdir_y(6, tip_angle + 150), tip_x + lengthdir_x(6, tip_angle + 30), tip_y + lengthdir_y(6, tip_angle + 30), false);
draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
