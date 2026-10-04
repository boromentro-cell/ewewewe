if (surface_exists(application_surface))
{
    if (surface_get_width(application_surface) < window_get_width())
        surface_resize(application_surface, window_get_width(), window_get_height());
}

if (my_index < 0)
    exit;

if (!visible)
    exit;

var _alpha_extra = (current_height - height_collapsed) / (height_expanded - height_collapsed);
_alpha_extra = clamp(_alpha_extra, 0, 1);
draw_set_alpha(alpha);
var _xx = x;
var _yy = y;
var _t_name = ds_list_find_value(global.texture_names, my_index);
var _t_author = ds_list_find_value(global.texture_authors, my_index);
var _t_likes = ds_list_find_value(global.texture_likes, my_index);
var _t_downloads = ds_list_find_value(global.texture_downloads, my_index);
draw_set_font(global.font);
draw_set_color(c_black);
draw_set_alpha(alpha * 0.4);
draw_roundrect(_xx + 6, _yy + 8, _xx + width + 6, _yy + current_height + 8, false);
draw_set_alpha(alpha);
draw_set_color(col_bg);
draw_roundrect(_xx, _yy, _xx + width, _yy + current_height, false);

if (hovered || expanded)
    draw_set_color(col_card_hover);
else
    draw_set_color(col_card);

draw_roundrect(_xx + 3, _yy + 3, (_xx + width) - 3, (_yy + current_height) - 3, false);

if (expanded)
{
    draw_set_color(col_accent);
    draw_roundrect(_xx + 3, _yy + 3, (_xx + width) - 3, (_yy + current_height) - 3, true);
}

var _thumb_size = 100;
var _thumb_x = _xx + 15;
var _thumb_y = _yy + 15;

if (sprite_exists(thumb_sprite))
{
    var _scale = _thumb_size / max(sprite_get_width(thumb_sprite), sprite_get_height(thumb_sprite));
    var _sw = sprite_get_width(thumb_sprite) * _scale;
    var _sh = sprite_get_height(thumb_sprite) * _scale;
    var _tx = _thumb_x + ((_thumb_size - _sw) / 2);
    var _ty = _thumb_y + ((_thumb_size - _sh) / 2);
    draw_sprite_ext(thumb_sprite, 0, _tx, _ty, _scale, _scale, 0, c_white, alpha);
    draw_set_color(c_black);
    draw_set_alpha(alpha * 0.5);
    draw_rectangle(_tx - 1, _ty - 1, _tx + _sw + 1, _ty + _sh + 1, true);
    draw_set_color(make_colour_rgb(60, 60, 80));
    draw_set_alpha(alpha);
    draw_rectangle(_tx - 2, _ty - 2, _tx + _sw + 2, _ty + _sh + 2, true);
}
else
{
    draw_set_color(make_colour_rgb(30, 20, 50));
    draw_rectangle(_thumb_x, _thumb_y, _thumb_x + _thumb_size, _thumb_y + _thumb_size, false);
    
    if (thumb_loading)
    {
        draw_set_color(c_gray);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_thumb_x + (_thumb_size / 2), _thumb_y + (_thumb_size / 2), "...");
    }
    else
    {
        draw_set_color(c_ltgray);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(_thumb_x + (_thumb_size / 2), _thumb_y + (_thumb_size / 2), "ICONO");
    }
}

var _text_x = _xx + 15 + _thumb_size + 15;
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
var _t_type_str = "Textura";

if (variable_global_exists("texture_item_types") && ds_exists(global.texture_item_types, ds_type_list))
{
    if (my_index < ds_list_size(global.texture_item_types))
    {
        var _raw_type = ds_list_find_value(global.texture_item_types, my_index);
        
        if (is_string(_raw_type) && string_pos("custom", _raw_type) > 0)
        {
            var _sub = string_replace(_raw_type, "custom_", "");
            
            if (_sub == "object" || _sub == "generic")
                _sub = "Generic";
            else if (_sub == "enemy")
                _sub = "Enemy";
            else if (_sub == "block")
                _sub = "Block";
            else if (string_length(_sub) > 0)
                _sub = string_char_at(string_upper(_sub), 1) + string_copy(_sub, 2, string_length(_sub) - 1);
            
            _t_type_str = "Custom " + _sub;
        }
    }
}

var _display_name = string(_t_name) + " | " + _t_type_str;
_display_name = string_upper(_display_name);

if (string_length(_display_name) > 35 && !expanded)
    _display_name = string_copy(_display_name, 1, 35) + "...";

draw_text_transformed(_text_x, _yy + 12, _display_name, 1.1, 1.1, 0);
var _autor_text = "por: " + string_lower(string(_t_author));
var _autor_y_draw = _yy + 38;
var _autor_w_draw = string_width(_autor_text) + 10;

if (autor_hover)
    draw_set_color(make_colour_rgb(100, 200, 255));
else
    draw_set_color(make_colour_rgb(200, 200, 200));

draw_text(_text_x, _autor_y_draw, _autor_text);

if (autor_hover)
{
    var _text_width_autor = string_width(_autor_text);
    draw_line(_text_x, _autor_y_draw + 14, _text_x + _text_width_autor, _autor_y_draw + 14);
}

var _stats_y = _yy + 78;
var _stats_x = _text_x;
heart_x = _stats_x - 5;
heart_y = _stats_y - 5;
var _heart_col = make_colour_rgb(255, 80, 100);
var _hx = heart_x;
var _hy = heart_y;

if (sprite_exists(spr_like_lvl))
{
    var _spr_w = sprite_get_width(spr_like_lvl);
    var _mi_escala = variable_instance_exists(id, "heart_scale") ? heart_scale : 1;
    var _final_scale = (16 / _spr_w) * _mi_escala;
    var _color_to_use = is_liked ? _heart_col : 16777215;
    
    if (!is_liked && !like_hover)
        _color_to_use = make_colour_rgb(180, 180, 180);
    
    draw_sprite_ext(spr_like_lvl, 0, _hx + 8, _hy + 6, _final_scale, _final_scale, 0, _color_to_use, alpha);
}

draw_set_halign(fa_left);
draw_set_valign(fa_middle);

if (is_liked)
    draw_set_color(make_colour_rgb(255, 100, 120));
else
    draw_set_color(make_colour_rgb(200, 200, 200));

var _text_like_x = _stats_x + 24;
var _text_like_y = _stats_y + 8;
draw_text(_text_like_x, _text_like_y, string(_t_likes));
var _dl_x = _stats_x + 20 + string_width(string(_t_likes)) + 25;
var _dl_y = _stats_y + 6;
var _ts = 8;
draw_set_color(make_colour_rgb(80, 220, 120));
draw_triangle(_dl_x - _ts, _dl_y, _dl_x + (_ts * 0.5), _dl_y - _ts, _dl_x + (_ts * 0.5), _dl_y + _ts, false);
draw_set_color(make_colour_rgb(200, 200, 200));
draw_text(_dl_x + _ts + 8, _dl_y + 2, string(_t_downloads));

if (is_installed && !expanded)
{
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);
    draw_set_color(col_success);
    draw_text((_xx + width) - 15, _yy + 10, "DESCARGADO");
}

if (_alpha_extra > 0.05)
{
    draw_set_alpha(alpha * _alpha_extra);
    var _desc_y = _yy + height_collapsed + 5;
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    
    if (descripcion_cargada && descripcion != "")
    {
        var _desc_show = string_upper(descripcion);
        var _max_chars = 200;
        
        if (string_length(_desc_show) > _max_chars)
            _desc_show = string_copy(_desc_show, 1, _max_chars) + "...";
        
        draw_text_ext(_xx + 20, _desc_y, _desc_show, 16, width - 40);
    }
    
    if (is_installed)
        download_status = "installed";
    
    var _btn_col, _btn_text;
    
    switch (download_status)
    {
        case "":
            if (is_installed)
            {
                _btn_col = col_success;
                _btn_text = "DESCARGADO";
            }
            else
            {
                if (hover_button)
                    _btn_col = col_btn_hover;
                else
                    _btn_col = col_btn;
                
                _btn_text = "DESCARGAR";
            }
            
            break;
        
        case "downloading":
            _btn_col = col_accent;
            
            if (download_progress > 0)
                _btn_text = "BAJANDO " + string(download_progress) + "%";
            else
                _btn_text = "DESCARGANDO...";
            
            break;
        
        case "installed":
            _btn_col = col_success;
            _btn_text = "DESCARGADO";
            break;
        
        case "error":
            _btn_col = col_error;
            _btn_text = "REINTENTAR";
            break;
        
        default:
            _btn_col = col_btn;
            _btn_text = "DESCARGAR";
    }
    
    draw_set_color(_btn_col);
    draw_roundrect(download_btn_x, download_btn_y, download_btn_x + download_btn_w, download_btn_y + download_btn_h, false);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(download_btn_x + (download_btn_w / 2), download_btn_y + (download_btn_h / 2), _btn_text);
    
    if (download_status == "error" && download_error != "")
    {
        draw_set_color(col_error);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        var _err_msg = string_upper(download_error);
        
        if (string_length(_err_msg) > 25)
            _err_msg = string_copy(_err_msg, 1, 25) + "...";
        
        draw_text(download_btn_x + (download_btn_w / 2), download_btn_y + download_btn_h + 5, _err_msg);
    }
    
    if (hover_comments)
        draw_set_color(make_colour_rgb(100, 200, 255));
    else
        draw_set_color(make_colour_rgb(60, 150, 200));
    
    draw_roundrect(comments_btn_x, comments_btn_y, comments_btn_x + comments_btn_size, comments_btn_y + comments_btn_size, false);
    draw_set_color(c_white);
    draw_roundrect(comments_btn_x + 8, comments_btn_y + 8, (comments_btn_x + comments_btn_size) - 8, (comments_btn_y + comments_btn_size) - 12, false);
    draw_triangle(comments_btn_x + 12, (comments_btn_y + comments_btn_size) - 12, comments_btn_x + 20, (comments_btn_y + comments_btn_size) - 12, comments_btn_x + 12, (comments_btn_y + comments_btn_size) - 4, false);
    
    if (can_delete)
    {
        if (hover_delete)
            draw_set_color(make_colour_rgb(255, 80, 80));
        else
            draw_set_color(make_colour_rgb(180, 50, 50));
        
        draw_roundrect(delete_btn_x, delete_btn_y, delete_btn_x + delete_btn_size, delete_btn_y + delete_btn_size, false);
        draw_set_color(c_white);
        var _cx = delete_btn_x + (delete_btn_size / 2);
        var _cy = delete_btn_y + (delete_btn_size / 2);
        var _xs = 6;
        draw_line_width(_cx - _xs, _cy - _xs, _cx + _xs, _cy + _xs, 2);
        draw_line_width(_cx + _xs, _cy - _xs, _cx - _xs, _cy + _xs, 2);
    }
    
    if (variable_global_exists("user_is_admin") && global.user_is_admin)
    {
        var _star_col;
        
        if (is_featured)
            _star_col = make_colour_rgb(255, 200, 50);
        else if (hover_star)
            _star_col = make_colour_rgb(200, 200, 200);
        else
            _star_col = make_colour_rgb(100, 100, 100);
        
        if (sprite_exists(spr_star))
        {
            var _star_scale = star_btn_size / sprite_get_width(spr_star);
            draw_sprite_ext(spr_star, 0, star_btn_x, star_btn_y, _star_scale, _star_scale, 0, _star_col, alpha * _alpha_extra);
        }
        else
        {
            draw_set_color(_star_col);
            draw_circle(star_btn_x + (star_btn_size / 2), star_btn_y + (star_btn_size / 2), (star_btn_size / 2) - 2, false);
        }
        
        if (toggle_featured_request != -1)
        {
            draw_set_color(c_black);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text(star_btn_x + (star_btn_size / 2), star_btn_y + (star_btn_size / 2), "...");
        }
        
        if (show_tooltip && tooltip_alpha > 0)
        {
            draw_set_alpha(tooltip_alpha * alpha * _alpha_extra);
            var _tt_x = star_btn_x + star_btn_size + 10;
            var _tt_y = star_btn_y + (star_btn_size / 2);
            var _tt_w = string_width(tooltip_text) + 16;
            var _tt_h = 24;
            draw_set_color(make_colour_rgb(30, 30, 30));
            draw_roundrect(_tt_x, _tt_y - (_tt_h / 2), _tt_x + _tt_w, _tt_y + (_tt_h / 2), false);
            draw_set_color(make_colour_rgb(100, 100, 100));
            draw_roundrect(_tt_x, _tt_y - (_tt_h / 2), _tt_x + _tt_w, _tt_y + (_tt_h / 2), true);
            draw_set_color(c_white);
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            draw_text(_tt_x + 8, _tt_y, string_upper(tooltip_text));
            draw_set_alpha(alpha * _alpha_extra);
        }
    }
    
    if (ds_exists(my_tags, ds_type_list) && ds_list_size(my_tags) > 0)
    {
        var _tag_x = (_xx + width) - 15;
        var _tag_y = download_btn_y - 15;
        var _tag_h = 20;
        var _tag_spacing = 4;
        var _tag_count = min(ds_list_size(my_tags), 3);
        var t = _tag_count - 1;
        
        while (t >= 0)
        {
            var _tag_name = ds_list_find_value(my_tags, t);
            var _tag_visuals = scr_get_texture_tag_visuals(_tag_name);
            var _tag_col = _tag_visuals[0];
            
            if (variable_global_exists("texture_item_types") && ds_exists(global.texture_item_types, ds_type_list) && my_index < ds_list_size(global.texture_item_types))
            {
                var _my_type = ds_list_find_value(global.texture_item_types, my_index);
                
                if (is_string(_my_type) && string_pos("custom", _my_type) > 0)
                    _tag_col = make_colour_rgb(60, 120, 180);
            }
            
            var _tag_text = string_upper(_tag_name);
            var _tag_text_w = string_width(_tag_text);
            var _tag_w = _tag_text_w + 12;
            var _tx1 = _tag_x - _tag_w;
            var _ty1 = _tag_y - ((_tag_count - t) * (_tag_h + _tag_spacing));
            var _tx2 = _tag_x;
            var _ty2 = _ty1 + _tag_h;
            draw_set_alpha(alpha * _alpha_extra * 0.85);
            draw_set_color(_tag_col);
            draw_roundrect(_tx1, _ty1, _tx2, _ty2, false);
            draw_set_alpha(alpha * _alpha_extra);
            draw_set_color(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text((_tx1 + _tx2) / 2, (_ty1 + _ty2) / 2, _tag_text);
            t--;
        }
        
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
    }
    
    draw_set_alpha(alpha);
}

if (delete_request != -1)
{
    draw_set_alpha(0.8);
    draw_set_color(c_black);
    draw_rectangle(_xx, _yy, _xx + width, _yy + current_height, false);
    draw_set_alpha(1);
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(_xx + (width / 2), _yy + (current_height / 2), "ELIMINANDO...");
}

draw_set_alpha(1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
