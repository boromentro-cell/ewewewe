var _mx = mouse_x;
var _my = mouse_y;
var _draw_y_offset = -scroll_y;
draw_set_color(col_bg);
draw_rectangle(0, 0, room_width, room_height, false);
draw_set_font(global.font);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text_transformed(20, 20 + _draw_y_offset, "texturas online", 1.5, 1.5, 0);
var _category_names = ["recientes", "populares", "descargas", "destacados"];
var _cat_x = 20;

for (var _cat_i = 0; _cat_i < 4; _cat_i++)
{
    var _current_btn_y = btn_y + _draw_y_offset;
    var _is_selected;
    
    if (view_mode == 5)
        _is_selected = 0;
    else
        _is_selected = view_mode == _cat_i;
    
    var _is_hover = _mx > _cat_x && _mx < (_cat_x + btn_w) && _my > _current_btn_y && _my < (_current_btn_y + btn_h);
    var _btn_col;
    
    if (_is_selected)
        _btn_col = col_accent;
    else if (_is_hover)
        _btn_col = 5918800;
    else
        _btn_col = 2959400;
    
    draw_set_color(_btn_col);
    draw_roundrect(_cat_x, _current_btn_y, _cat_x + btn_w, _current_btn_y + btn_h, false);
    
    if (_is_selected)
    {
        draw_set_color(c_white);
        draw_roundrect(_cat_x, _current_btn_y, _cat_x + btn_w, _current_btn_y + btn_h, true);
    }
    
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_cat_x + (btn_w / 2), _current_btn_y + (btn_h / 2), _category_names[_cat_i]);
    _cat_x += (btn_w + 8);
}

var _current_back_y = btn_back_y + _draw_y_offset;
var _back_hover = _mx > btn_back_x && _mx < (btn_back_x + btn_back_w) && _my > _current_back_y && _my < (_current_back_y + btn_back_h);

if (_back_hover)
    draw_set_color(#C85050);
else
    draw_set_color(#963232);

draw_roundrect(btn_back_x, _current_back_y, btn_back_x + btn_back_w, _current_back_y + btn_back_h, false);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(btn_back_x + (btn_back_w / 2), _current_back_y + (btn_back_h / 2), "volver");

if (load_phase < 2 || parsing_active || featured_textures_loading)
{
    var _loading_text = string_lower(load_phase_text);
    
    repeat (loading_dots)
        _loading_text += ".";
    
    draw_set_color(c_ltgray);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text_transformed(room_width / 2, room_height / 2, _loading_text, 1.2, 1.2, 0);
}

if (load_phase >= 2 && !parsing_active && !featured_textures_loading && ds_list_size(global.texture_ids) == 0)
{
    draw_set_color(c_gray);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    var _empty_msg;
    
    if (view_mode == 5)
        _empty_msg = "no se encontraron resultados";
    else if (view_mode == 3)
        _empty_msg = "no hay texturas destacadas";
    else
        _empty_msg = "no hay texturas disponibles";
    
    draw_text_transformed(room_width / 2, room_height / 2, _empty_msg, 1.1, 1.1, 0);
    
    if (view_mode == 3 && variable_global_exists("user_is_admin") && global.user_is_admin)
    {
        draw_set_color(#787878);
        draw_text(room_width / 2, (room_height / 2) + 40, "usa el boton * en las tarjetas para destacar texturas");
    }
}

draw_set_halign(fa_right);
draw_set_valign(fa_top);
draw_set_color(#969696);
var _mode_text;

switch (view_mode)
{
    case 0:
        _mode_text = "ordenado por: fecha";
        break;
    
    case 1:
        _mode_text = "ordenado por: likes";
        break;
    
    case 2:
        _mode_text = "ordenado por: descargas";
        break;
    
    case 3:
        _mode_text = "* destacados por admins";
        break;
    
    case 5:
        _mode_text = "resultados de busqueda";
        break;
    
    default:
        _mode_text = "";
        break;
}

draw_text(room_width - 20, (list_start_y - 25) + _draw_y_offset, _mode_text);

if (view_mode == 5)
{
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(#00B4A0);
    var _search_info = "";
    
    if (global.texture_search_name != "")
        _search_info += ("nombre: " + global.texture_search_name + "  ");
    
    if (global.texture_search_author != "")
        _search_info += ("autor: " + global.texture_search_author + "  ");
    
    if (ds_exists(global.texture_search_tags, ds_type_list) && ds_list_size(global.texture_search_tags) > 0)
        _search_info += ("tags: " + string(ds_list_size(global.texture_search_tags)));
    
    if (_search_info != "")
        draw_text(20, (list_start_y - 25) + _draw_y_offset, _search_info);
}

if (scroll_max > 0)
{
    var _scrollbar_x = room_width - 10;
    var _scrollbar_y = 20;
    var _scrollbar_h = room_height - 40;
    var _thumb_h = max(30, _scrollbar_h * (room_height / (room_height + scroll_max)));
    var _thumb_y = _scrollbar_y + ((scroll_y / scroll_max) * (_scrollbar_h - _thumb_h));
    draw_set_color(#282828);
    draw_roundrect(_scrollbar_x - 4, _scrollbar_y, _scrollbar_x + 4, _scrollbar_y + _scrollbar_h, false);
    draw_set_color(col_accent);
    draw_roundrect(_scrollbar_x - 3, _thumb_y, _scrollbar_x + 3, _thumb_y + _thumb_h, false);
}

draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
