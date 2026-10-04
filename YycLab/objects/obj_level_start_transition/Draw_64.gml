var _gui_w = display_get_gui_width();
var _gui_h = display_get_gui_height();
var _cx = _gui_w / 2;
var _cy = _gui_h / 2;
draw_set_alpha(alpha);
draw_set_color(col_fade_bg);
draw_rectangle(0, 0, _gui_w, _gui_h, false);

if (alpha > 0.9)
{
    draw_set_font(global.font);
    var _txt_title = string_upper(level_name);
    var _txt_author = string_upper("CREADO POR: " + level_author);
    var _scale_title = 0.8;
    var _scale_author = 0.55;
    var _padding_x = 120;
    var _rect_h = 45;
    draw_set_font(global.font);
    var _title_w = string_width(_txt_title) * _scale_title;
    var _rect_w = max(500, _title_w + (_padding_x * 2));
    var _rx1 = _cx - (_rect_w / 2);
    var _ry1 = _cy - (_rect_h / 2) - 60;
    var _rx2 = _cx + (_rect_w / 2);
    var _ry2 = _ry1 + _rect_h;
    var _slide_y = 0;
    
    if (state == 0)
        _slide_y = (1 - alpha) * 30;
    
    draw_set_color(col_band_shadow);
    draw_roundrect(_rx1 + 3, _ry1 + 3 + _slide_y, _rx2 + 3, _ry2 + 3 + _slide_y, false);
    draw_set_color(col_band);
    draw_roundrect(_rx1, _ry1 + _slide_y, _rx2, _ry2 + _slide_y, false);
    draw_set_color(c_white);
    draw_set_alpha(alpha * 0.6);
    draw_roundrect(_rx1 + 2, _ry1 + 2 + _slide_y, _rx2 - 2, (_ry2 - 2) + _slide_y, true);
    draw_set_alpha(alpha);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);
    draw_text_transformed(_cx + 2, ((_ry1 + _ry2) / 2) + _slide_y + 2, _txt_title, _scale_title, _scale_title, 0);
    draw_set_color(c_white);
    draw_text_transformed(_cx, ((_ry1 + _ry2) / 2) + _slide_y, _txt_title, _scale_title, _scale_title, 0);
    draw_set_valign(fa_top);
    draw_set_color(make_colour_rgb(30, 30, 40));
    draw_text_transformed(_cx + 1, _ry2 + 10 + _slide_y + 1, _txt_author, _scale_author, _scale_author, 0);
    draw_set_color(c_white);
    draw_text_transformed(_cx, _ry2 + 10 + _slide_y, _txt_author, _scale_author, _scale_author, 0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

draw_set_alpha(1);
draw_set_color(c_white);
