if (my_list_index == -1) exit;

var clip_top = 85;
if ((y + current_height) <= clip_top) exit;
if (y > (room_height + 50)) exit;

var _mx = mouse_x;
var _my = mouse_y;
var base_alpha = fade_alpha;
var card_w = 550;
// las primeras 8 entran desde mas lejos, se nota mas la entrada al abrir el browser
var slide_dist = (my_list_index < 8) ? -24 : -12;
var slide_offset = slide_dist * (1 - fade_alpha);
var draw_y = y + card_y_offset + slide_offset;
var thumb_w = 132;
var thumb_h = 74;
var thumb_margin = 5;

if (surface_exists(application_surface))
{
    if (surface_get_width(application_surface) < window_get_width())
        surface_resize(application_surface, window_get_width(), window_get_height());
}

// sombra y anims
draw_set_font(global.font);
var shadow_intensity = 0.15 + (hover_progress * 0.1) + (expand_progress * 0.1);
var shadow_dist = 4 + (hover_progress * 2) + (expand_progress * 3);

draw_set_alpha(shadow_intensity * base_alpha);
draw_set_color(color_shadow);
draw_roundrect_ext(x + shadow_dist, draw_y + shadow_dist, x + card_w + shadow_dist, draw_y + current_height + shadow_dist, 10, 10, false);

draw_set_alpha(base_alpha);
draw_set_color(color_card_dark);
draw_roundrect_ext(x, draw_y, x + card_w, draw_y + current_height, 10, 10, false);

var main_color = merge_colour(color_card, color_card_hover, hover_progress);
draw_set_color(main_color);
draw_roundrect_ext(x + 3, draw_y + 3, (x + card_w) - 3, (draw_y + current_height) - 3, 8, 8, false);

// chequamos las listas
if (my_list_index < ds_list_size(global.id_levels))
{
    var id_l = ds_list_find_value(global.id_levels, my_list_index);
    
    if (!is_undefined(id_l) && string(id_l) != "")
    {
        var aut_l = ds_list_find_value(global.autor_levels, my_list_index);
        var nam_l = ds_list_find_value(global.name_levels, my_list_index);
        var dat_l = ds_list_find_value(global.date_levels, my_list_index);
        var raw_likes = ds_list_find_value(global.likes_levels, my_list_index);
        var lik_l = is_string(raw_likes) ? real(raw_likes) : raw_likes;
        var attempts_val = 0;
        
        if (my_list_index < ds_list_size(global.attempts_levels))
        {
            attempts_val = ds_list_find_value(global.attempts_levels, my_list_index);
            if (is_string(attempts_val) && attempts_val != "") attempts_val = real(attempts_val);
            if (is_undefined(attempts_val) || attempts_val == "") attempts_val = 0;
        }
        
        var texture_used = "vanilla";
        if (variable_global_exists("texture_used_levels") && ds_exists(global.texture_used_levels, ds_type_list))
        {
            if (my_list_index < ds_list_size(global.texture_used_levels))
            {
                var tex_val = ds_list_find_value(global.texture_used_levels, my_list_index);
                if (!is_undefined(tex_val) && tex_val != "" && tex_val != "null")
                    texture_used = string(tex_val);
            }
        }
        
        var texture_display = texture_used;
        var dash_pos = string_pos(" - ", texture_used);
        if (dash_pos > 0) texture_display = string_copy(texture_used, 1, dash_pos - 1);
        
        var is_vanilla = string_lower(texture_display) == "vanilla";
        var tex_text, tex_color;
        if (is_vanilla) { tex_color = 11822300; tex_text = "VANILLA"; }
        else { tex_color = 14464100; tex_text = string_upper(texture_display); }
        
        var tex_scale = 0.65;
        var tex_text_w = string_width(tex_text) * tex_scale;
        var tex_padding = 8;
        var tex_full_w = tex_text_w + (tex_padding * 2);
        var tex_y_top = draw_y + 8;
        var tex_y_bottom = draw_y + 28;
        var tag_x = x + 10;
        
        draw_set_alpha(0.9 * base_alpha);
        draw_set_color(tex_color);
        draw_roundrect_ext(tag_x, tex_y_top, tag_x + tex_full_w, tex_y_bottom, 6, 6, false);
        draw_set_alpha(base_alpha);
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_text_transformed(tag_x + tex_padding, (tex_y_top + tex_y_bottom) / 2, tex_text, tex_scale, tex_scale, 0);
        draw_set_valign(fa_top);
        
        if (my_list_index < ds_list_size(global.difficulty_labels))
        {
            difficulty_label = ds_list_find_value(global.difficulty_labels, my_list_index);
            difficulty_confidence = ds_list_find_value(global.difficulty_confidences, my_list_index);
            difficulty_sessions = ds_list_find_value(global.difficulty_sessions, my_list_index);
            if (is_undefined(difficulty_label) || difficulty_label == "") difficulty_label = "unplayed";
            if (is_undefined(difficulty_confidence) || difficulty_confidence == "") difficulty_confidence = "none";
            if (is_undefined(difficulty_sessions) || difficulty_sessions == "") difficulty_sessions = 0;
            if (is_string(difficulty_sessions)) difficulty_sessions = real(difficulty_sessions);
        }
        
        var stars_x = tag_x + tex_full_w + 8;
        var stars_y = draw_y + 12;
        
        if (diff_alpha > 0) {
            draw_set_alpha(base_alpha);
            scr_draw_difficulty_stars(stars_x, stars_y, difficulty_label, difficulty_confidence, difficulty_sessions, pulse_timer, diff_alpha);
        }
        
        var stars_total_w = 60;
        var stars_hover = _mx > stars_x && _mx < (stars_x + stars_total_w) && _my > (stars_y - 2) && _my < (stars_y + 12);
        difficulty_tooltip_alpha = lerp(difficulty_tooltip_alpha, (stars_hover && diff_alpha >= 6) ? 1 : 0, 0.15);
        
        var titulo = string_upper(nam_l);
        var title_x = stars_x + stars_total_w + 6;
        var title_y = draw_y + 10;
        var title_max_w = (x + card_w) - title_x - 60;
        var title_actual_w = string_width(titulo) * 1.15;
        
        if (title_actual_w > title_max_w)
        {
            title_x = tag_x + tex_full_w + 8;
            title_y = draw_y + 10;
            stars_x = title_x;
            stars_y = draw_y + 24;
        }
        
        draw_set_alpha(0.5 * base_alpha);
        draw_set_color(c_black);
        draw_text_transformed(title_x + 1, title_y + 1, titulo, 1.15, 1.15, 0);
        draw_set_alpha(base_alpha);
        draw_set_color(c_white);
        draw_text_transformed(title_x, title_y, titulo, 1.15, 1.15, 0);
        
        var id_text = "#" + string(id_l);
        var id_x = (x + card_w) - 10;
        var id_y = draw_y + 12;
        draw_set_alpha(0.6 * base_alpha);
        draw_set_halign(fa_right);
        draw_set_color(color_text_secondary);
        draw_text_transformed(id_x, id_y, id_text, 0.8, 0.8, 0);
        
        var autor_text = "por " + aut_l;
        var autor_x = (x + card_w) - 10;
        var autor_y = draw_y + 28;
        draw_set_alpha(0.4 * base_alpha);
        draw_set_color(c_black);
        draw_text_transformed(autor_x + 1, autor_y + 1, autor_text, 0.85, 0.85, 0);
        draw_set_alpha(base_alpha);
        var autor_col = merge_colour(c_white, #96C8FF, autor_hover_progress);
        draw_set_color(autor_col);
        draw_text_transformed(autor_x, autor_y, autor_text, 0.85, 0.85, 0);
        draw_set_halign(fa_left);
        
        // miniatura (posicion y ajuste)
        var tx = x + 12;
        var ty = draw_y + 32;
        draw_set_color(#28282D);
        draw_rectangle(tx, ty, tx + thumb_w, ty + thumb_h, false);
        
        if (imagen_nivel != -1 && sprite_exists(imagen_nivel)) {
            var spr_w = sprite_get_width(imagen_nivel);
            var spr_h = sprite_get_height(imagen_nivel);
            var base_scale_x = thumb_w / spr_w;
            var base_scale_y = thumb_h / spr_h;
            var final_scale_x = base_scale_x * thumbnail_hover_scale;
            var final_scale_y = base_scale_y * thumbnail_hover_scale;
            var offset_x = (thumb_w * (thumbnail_hover_scale - 1)) / 2;
            var offset_y = (thumb_h * (thumbnail_hover_scale - 1)) / 2;
            draw_set_alpha(thumbnail_fade * base_alpha);
            gpu_set_texfilter(true);
            draw_sprite_ext(imagen_nivel, 0, tx - offset_x, ty - offset_y, final_scale_x, final_scale_y, 0, c_white, 1);
            gpu_set_texfilter(false);
            draw_set_alpha(base_alpha);
        } else if (imagen_cargando) {
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_set_color(#96969B);
            var dots = "";
            var dot_count = floor((pulse_timer * 2) % 4);
            repeat (dot_count + 1) dots += ".";
            draw_text(tx + (thumb_w / 2), ty + (thumb_h / 2), dots);
            draw_set_halign(fa_left); draw_set_valign(fa_top);
        }
        
        draw_set_color(c_black);
        draw_rectangle(tx, ty, tx + thumb_w, ty + thumb_h, true);
        
        // likes y anim
        var stats_x_base = tx + thumb_w + 10;
        var stats_y = ty + 2;
        var hx = stats_x_base + 10;
        var hy = stats_y + 8;
        var heart_hover = (b_like.hover > 0.1);
        
        if (my_list_index < ds_list_size(global.is_liked_list))
            is_liked = ds_list_find_value(global.is_liked_list, my_list_index);
        
        if (is_liked || heart_hover) {
            var glow_size = is_liked ? (14 + (sin(pulse_timer * 2) * 2)) : 12;
            draw_set_alpha((is_liked ? 0.25 : 0.15) * base_alpha);
            draw_set_color(color_heart);
            draw_circle(hx, hy, glow_size, false);
            draw_set_alpha(base_alpha);
        }
        
        var h_color = is_liked ? color_heart : (heart_hover ? merge_colour(color_heart_empty, color_heart, 0.4) : color_heart_empty);
        var hs = heart_scale;
        draw_set_color(h_color);
        draw_circle(hx - (4 * hs), hy - (2 * hs), 4.5 * hs, false);
        draw_circle(hx + (4 * hs), hy - (2 * hs), 4.5 * hs, false);
        draw_triangle(hx - (8.5 * hs), hy, hx + (8.5 * hs), hy, hx, hy + (10 * hs), false);
        
        if (is_liked) {
            draw_set_alpha(0.5 * base_alpha);
            draw_set_color(c_white);
            draw_circle(hx - 3, hy - 4, 2, false);
            draw_set_alpha(base_alpha);
        }
        
        for (var i = 0; i < ds_list_size(like_particles); i++) {
            var p = like_particles[| i];
            draw_set_alpha(p[4] * base_alpha);
            draw_set_color(color_heart);
            draw_circle(p[0], p[1], p[5], false);
        }
        draw_set_alpha(base_alpha);
        
        draw_set_alpha(0.4 * base_alpha);
        draw_set_color(c_black);
        draw_text_transformed(hx + 19, stats_y + 5, string(lik_l), 0.9, 0.9, 0);
        draw_set_alpha(base_alpha);
        draw_set_color(c_white);
        draw_text_transformed(hx + 18, stats_y + 4, string(lik_l), 0.9, 0.9, 0);
        
        var px = hx + 45;
        draw_set_color(color_plays);
        draw_triangle(px, stats_y + 3, px, stats_y + 13, px + 9, stats_y + 8, false);
        draw_set_alpha(0.4 * base_alpha);
        draw_set_color(c_black);
        draw_text_transformed(px + 16, stats_y + 5, string(attempts_val), 0.9, 0.9, 0);
        draw_set_alpha(base_alpha);
        draw_set_color(c_white);
        draw_text_transformed(px + 15, stats_y + 4, string(attempts_val), 0.9, 0.9, 0);
        
        // Clear Rate
        var preview_xp = 0;
        var cr_x = (x + card_w) - 10;
        var cr_y = autor_y + 18;
        
        if (my_list_index < ds_list_size(global.victories_levels))
        {
            var victories_val = ds_list_find_value(global.victories_levels, my_list_index);
            if (is_string(victories_val) && victories_val != "") victories_val = real(victories_val);
            if (is_undefined(victories_val) || victories_val == "") victories_val = 0;
            
            var rate = scr_get_clear_rate(attempts_val, victories_val);
            var rate_text = string_upper(scr_format_clear_rate(rate));
            var rate_color = scr_get_clear_rate_color(rate);
            preview_xp = scr_calculate_preview_xp(rate, attempts_val);
            
            draw_set_halign(fa_right);
            draw_set_color(rate_color);
            draw_text_transformed(cr_x, cr_y, "CLEAR RATE: " + rate_text, 0.75, 0.75, 0);
            
            var has_first = false;
            var first_name = "";
            if (variable_global_exists("first_clear_usernames") && my_list_index < ds_list_size(global.first_clear_usernames)) {
                first_name = ds_list_find_value(global.first_clear_usernames, my_list_index);
                if (!is_undefined(first_name) && first_name != "" && first_name != "null") {
                    first_name = scr_clean_json_string(string(first_name));
                    has_first = first_name != "" && first_name != "null";
                }
            }
            
            if (has_first) {
                draw_set_color(color_text_secondary);
                draw_text_transformed(cr_x, cr_y + 14, "FIRST CLEAR", 0.6, 0.6, 0);
                draw_set_color(color_accent);
                draw_text_transformed(cr_x, cr_y + 24, string_upper(first_name), 0.7, 0.7, 0);
            } else {
                draw_set_color(#FFA000);
                draw_text_transformed(cr_x, cr_y + 16, "(SIN CLEAR AUN)", 0.7, 0.7, 0);
            }
            draw_set_halign(fa_left);
        }
        
        // Tags
        if (variable_global_exists("tags_levels") && my_list_index < ds_list_size(global.tags_levels))
        {
            var my_tags = ds_list_find_value(global.tags_levels, my_list_index);
            if (ds_exists(my_tags, ds_type_list) && ds_list_size(my_tags) > 0)
            {
                var tag_x_pos = stats_x_base;
                var tag_y_pos = stats_y + 40;
                draw_set_halign(fa_left); draw_set_valign(fa_middle);
                
                for (var t = 0; t < min(3, ds_list_size(my_tags)); t++) {
                    var tname = ds_list_find_value(my_tags, t);
                    tname = string_replace_all(tname, "\"", "");
                    var tvis = scr_get_tag_visuals(tname);
                    var tcol = tvis[0];
                    var ttext = string_upper(tname);
                    var t_scale = 0.55;
                    var tw = string_width(ttext) * t_scale;
                    var th = 16;
                    var tpad = 6;
                    var total_w = tw + (tpad * 2);
                    draw_set_alpha(0.9 * base_alpha);
                    draw_set_color(tcol);
                    draw_roundrect_ext(tag_x_pos, tag_y_pos - (th / 2), tag_x_pos + total_w, tag_y_pos + (th / 2), 8, 8, false);
                    draw_set_alpha(base_alpha);
                    draw_set_color(c_white);
                    draw_text_transformed(tag_x_pos + tpad, tag_y_pos, ttext, t_scale, t_scale, 0);
                    tag_x_pos += (total_w + 5);
                }
                draw_set_valign(fa_top);
            }
        }

// parseamos el json de los customs y lo guardamos
if (!custom_objects_parsed)
{
    custom_objects_parsed = true;
    custom_objects_info = [];
    if (variable_global_exists("custom_objects_used_levels") 
        && ds_exists(global.custom_objects_used_levels, ds_type_list)
        && my_list_index < ds_list_size(global.custom_objects_used_levels))
    {
        var _customs_raw = ds_list_find_value(global.custom_objects_used_levels, my_list_index);
        if (!is_undefined(_customs_raw) && _customs_raw != "" && _customs_raw != "null" && _customs_raw != "[]")
        {
            try {
                var _data = is_string(_customs_raw) ? json_parse(_customs_raw) : _customs_raw;
                if (is_array(_data)) {
                    for (var ci = 0; ci < array_length(_data); ci++) {
                        var _c = _data[ci];
                        var _n = variable_struct_exists(_c, "name") ? string(_c.name) : "???";
                        array_push(custom_objects_info, _n);
                    }
                }
            } catch (e) { /* nada xdxd */ }
        }
    }
}

// el cartelito de cuantos objetos custom usa el nivel
if (array_length(custom_objects_info) > 0)
{
    var _badge_text = "CUSTOMS (" + string(array_length(custom_objects_info)) + ")";
    var _badge_scale = 0.55;
    var _badge_w = string_width(_badge_text) * _badge_scale;
    var _badge_pad = 6;
    var _badge_full_w = _badge_w + (_badge_pad * 2);
    var _badge_h = 16;
    var _badge_x = tx;
    var _badge_y = ty + thumb_h + 4;
    
    draw_set_alpha(0.85 * base_alpha);
    draw_set_color(#8B5CF6);
    draw_roundrect_ext(_badge_x, _badge_y, _badge_x + _badge_full_w, _badge_y + _badge_h, 6, 6, false);
    draw_set_alpha(base_alpha);
    draw_set_color(c_white);
    draw_set_halign(fa_left); draw_set_valign(fa_middle);
    draw_text_transformed(_badge_x + _badge_pad, _badge_y + (_badge_h / 2), _badge_text, _badge_scale, _badge_scale, 0);
    draw_set_valign(fa_top);
    
    var _badge_hovering = (_mx > _badge_x && _mx < (_badge_x + _badge_full_w) && _my > _badge_y && _my < (_badge_y + _badge_h));
    custom_tooltip_alpha = lerp(custom_tooltip_alpha, _badge_hovering ? 1 : 0, 0.15);
    
    if (custom_tooltip_alpha > 0.05)
    {
        var _tt_lines = "CUSTOM OBJECTS:";
        for (var ci = 0; ci < array_length(custom_objects_info); ci++)
            _tt_lines += "\n- " + string_upper(custom_objects_info[ci]);
        
        var _tt_scale = 0.6;
        var _tt_w = string_width(_tt_lines) * _tt_scale;
        var _tt_h = string_height(_tt_lines) * _tt_scale;
        var _tt_pad = 8;
        var _tt_x = _badge_x;
        var _tt_y = _badge_y + _badge_h + 4;
        
        draw_set_alpha(0.9 * custom_tooltip_alpha * base_alpha);
        draw_set_color(#1A1A2E);
        draw_roundrect_ext(_tt_x - _tt_pad, _tt_y - _tt_pad, _tt_x + _tt_w + _tt_pad, _tt_y + _tt_h + _tt_pad, 5, 5, false);
        draw_set_alpha(0.6 * custom_tooltip_alpha * base_alpha);
        draw_set_color(#8B5CF6);
        draw_roundrect_ext(_tt_x - _tt_pad, _tt_y - _tt_pad, _tt_x + _tt_w + _tt_pad, _tt_y + _tt_h + _tt_pad, 5, 5, true);
        draw_set_alpha(custom_tooltip_alpha * base_alpha);
        draw_set_color(#D8B4FE);
        draw_text_transformed(_tt_x, _tt_y, _tt_lines, _tt_scale, _tt_scale, 0);
    }
}


        // TARJETA EXPANDIDA Y BOTONES
        if (expand_progress > 0.01)
        {
            var border_alpha = expand_progress * (0.5 + (sin(pulse_timer) * 0.15));
            draw_set_alpha(border_alpha * base_alpha);
            draw_set_color(color_accent);
            draw_roundrect_ext(x + 2, draw_y + 2, (x + card_w) - 2, (draw_y + current_height) - 2, 9, 9, true);
            draw_set_alpha(base_alpha);
        }
        
        if (expand_progress > 0.02)
        {
            var slide_offset = (1 - stats_slide) * 15;
            
            draw_set_alpha(expand_progress * base_alpha);
            draw_set_halign(fa_right);
            draw_set_color(color_text_secondary);
            draw_text_transformed((x + card_w) - 12, draw_y + 110 + slide_offset, dat_l, 0.75, 0.75, 0);
            draw_set_halign(fa_left);
            
            var sep_y = draw_y + 120;
            var sep_width = 200 * expand_progress;
            draw_set_color(color_card_light);
            draw_set_alpha(0.5 * expand_progress * base_alpha);
            draw_line_width(x + 12, sep_y, x + 12 + sep_width, sep_y, 1);
            
            draw_set_alpha(expand_progress * base_alpha);
            draw_set_color(color_text_secondary);
            if (descripcion_cargada && descripcion != "") {
                var desc = descripcion;
                if (string_length(desc) > 160) desc = string_copy(desc, 1, 157) + "...";
                draw_text_ext(x + 15, draw_y + 129 + slide_offset, desc, 15, 350);
            }
            
            // boton jugar (estado 5 y 6)
            if (b_jugar.activo) {
                var btn_scale = 1 + (b_jugar.hover * 0.02);
                var btn_text = "JUGAR";
                var btn_color = merge_colour(color_accent, color_accent_hover, b_jugar.hover);
                var show_progress_bar = false;
                var progress_value = 0;
                var progress_text = "";
                
                if (download_state > 0 || level_downloading || unpacking_textures || custom_unpacking) {
                    switch (download_state) {
                        case 1: btn_text = "NIVEL"; progress_value = level_download_progress; progress_text = string(progress_value) + "%"; btn_color = 13143120; show_progress_bar = true; break;
                        case 2: btn_text = "TEXTURA"; progress_value = texture_download_progress; progress_text = string(progress_value) + "%"; btn_color = 5273780; show_progress_bar = true; break;
                        case 3: btn_text = "INSTALANDO"; progress_value = install_progress; progress_text = string(progress_value) + "%"; btn_color = 5289080; show_progress_bar = true; break;
                        case 4: btn_text = "INICIANDO..."; btn_color = 6604900; break;
                        // ESTADOS PARA CUSTOMS 
                        case 5:
                            var _prog_txt = "";
                            if (custom_total_to_download > 0)
                                _prog_txt = string(custom_download_index + 1) + "/" + string(custom_total_to_download);
                            btn_text = "CUSTOM " + _prog_txt;
                            progress_value = custom_download_progress;
                            progress_text = string(progress_value) + "%";
                            btn_color = #8B5CF6;
                            show_progress_bar = true;
                            break;
                        case 6:
                            btn_text = "INSTALANDO";
                            progress_value = custom_install_progress;
                            progress_text = string(progress_value) + "%";
                            btn_color = #7C3AED;
                            show_progress_bar = true;
                            break;
                        default:
                            if (level_downloading) { btn_text = "DESCARGANDO..."; btn_color = 13143120; break; }
                            if (unpacking_textures) { btn_text = "INSTALANDO"; progress_value = install_progress; progress_text = string(progress_value) + "%"; btn_color = 5289080; show_progress_bar = true; }
                            if (custom_unpacking) { btn_text = "INSTALANDO"; progress_value = custom_install_progress; progress_text = string(progress_value) + "%"; btn_color = #7C3AED; show_progress_bar = true; }
                    }
                }
                
                var alf_jugar = b_jugar.alpha_mult * base_alpha;
                
                draw_set_alpha((0.3 + (b_jugar.hover * 0.15)) * alf_jugar);
                draw_set_color(c_black);
                draw_roundrect_ext(b_jugar.x + 3, b_jugar.y + 4, b_jugar.x + b_jugar.w + 3, b_jugar.y + b_jugar.h + 4, 6, 6, false);
                
                draw_set_alpha(alf_jugar);
                draw_set_color(btn_color);
                draw_roundrect_ext(b_jugar.x, b_jugar.y, b_jugar.x + b_jugar.w, b_jugar.y + b_jugar.h, 6, 6, false);
                
                if (show_progress_bar) {
                    var bar_padding = 4;
                    var bar_x = b_jugar.x + bar_padding;
                    var bar_y_pos = (b_jugar.y + b_jugar.h) - 12;
                    var bar_w = b_jugar.w - (bar_padding * 2);
                    var bar_h = 6;
                    draw_set_alpha(0.3 * alf_jugar);
                    draw_set_color(c_black);
                    draw_roundrect_ext(bar_x, bar_y_pos, bar_x + bar_w, bar_y_pos + bar_h, 3, 3, false);
                    draw_set_alpha(0.9 * alf_jugar);
                    draw_set_color(c_white);
                    var fill_w = (bar_w * progress_value) / 100;
                    if (fill_w > 2) draw_roundrect_ext(bar_x, bar_y_pos, bar_x + fill_w, bar_y_pos + bar_h, 3, 3, false);
                    draw_set_alpha(alf_jugar);
                }
                
                draw_set_alpha((0.2 + (b_jugar.hover * 0.1)) * alf_jugar);
                draw_set_color(c_white);
                draw_roundrect_ext(b_jugar.x + 2, b_jugar.y + 2, (b_jugar.x + b_jugar.w) - 2, b_jugar.y + (b_jugar.h / 2), 5, 5, false);
                
                draw_set_alpha(alf_jugar);
                draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_set_color(c_white);
                
                if (show_progress_bar)
                    draw_text_transformed(b_jugar.x + (b_jugar.w / 2), (b_jugar.y + (b_jugar.h / 2)) - 6, btn_text, 0.9 * btn_scale, 0.9 * btn_scale, 0);
                else
                    draw_text_transformed(b_jugar.x + (b_jugar.w / 2), b_jugar.y + (b_jugar.h / 2), btn_text, 1.05 * btn_scale, 1.05 * btn_scale, 0);
                
                if (expand_progress > 0.8) {
                    var xp_scale = 0.8 + (sin(pulse_timer * 1.5) * 0.02);
                    draw_set_color(color_xp);
                    draw_text_transformed(b_jugar.x + (b_jugar.w / 2), b_jugar.y - 15, "+" + string(preview_xp) + " XP", xp_scale, xp_scale, 0);
                }
                draw_set_valign(fa_top); draw_set_halign(fa_left);
            }
            
            // boton de comentarios
            if (b_comentarios.activo) {
                var cb_color = merge_colour(#3C78B4, #64AAE6, b_comentarios.hover);
                var alf_com = b_comentarios.alpha_mult * base_alpha;
                draw_set_alpha(0.3 * alf_com);
                draw_set_color(c_black);
                draw_roundrect_ext(b_comentarios.x + 3, b_comentarios.y + 3, b_comentarios.x + b_comentarios.w + 3, b_comentarios.y + b_comentarios.h + 3, 6, 6, false);
                draw_set_alpha(alf_com);
                draw_set_color(cb_color);
                draw_roundrect_ext(b_comentarios.x, b_comentarios.y, b_comentarios.x + b_comentarios.w, b_comentarios.y + b_comentarios.h, 6, 6, false);
                var icon_scale = 1 + (b_comentarios.hover * 0.1);
                draw_set_color(c_white);
                var ccx = b_comentarios.x + (b_comentarios.w / 2);
                var ccy = (b_comentarios.y + (b_comentarios.h / 2)) - 2;
                draw_roundrect_ext(ccx - (9 * icon_scale), ccy - (7 * icon_scale), ccx + (9 * icon_scale), ccy + (5 * icon_scale), 3, 3, false);
                draw_triangle(ccx - (4 * icon_scale), ccy + (5 * icon_scale), ccx + (4 * icon_scale), ccy + (5 * icon_scale), ccx - (4 * icon_scale), ccy + (11 * icon_scale), false);
            }
            
            // botones de admin (meter / sacar de destacados y borrar nivel)
            if (b_eliminar.activo) {
                var del_col = merge_colour(#8C2828, #C83C3C, b_eliminar.hover);
                var alf_del = b_eliminar.alpha_mult * base_alpha;
                draw_set_alpha(0.3 * alf_del); draw_set_color(c_black);
                draw_roundrect_ext(b_eliminar.x + 3, b_eliminar.y + 3, b_eliminar.x + b_eliminar.w + 3, b_eliminar.y + b_eliminar.h + 3, 6, 6, false);
                draw_set_alpha(alf_del); draw_set_color(del_col);
                draw_roundrect_ext(b_eliminar.x, b_eliminar.y, b_eliminar.x + b_eliminar.w, b_eliminar.y + b_eliminar.h, 6, 6, false);
                draw_set_color(c_white); draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text_transformed(b_eliminar.x + (b_eliminar.w / 2), b_eliminar.y + (b_eliminar.h / 2), "X", 1.2, 1.2, 0);
            }
            
            if (b_destacar.activo) {
                var star_col = is_admin_featured ? 46335 : merge_colour(#785A00, #A07800, b_destacar.hover);
                var alf_star = b_destacar.alpha_mult * base_alpha;
                draw_set_alpha(0.3 * alf_star); draw_set_color(c_black);
                draw_roundrect_ext(b_destacar.x + 3, b_destacar.y + 3, b_destacar.x + b_destacar.w + 3, b_destacar.y + b_destacar.h + 3, 6, 6, false);
                draw_set_alpha(alf_star); draw_set_color(star_col);
                draw_roundrect_ext(b_destacar.x, b_destacar.y, b_destacar.x + b_destacar.w, b_destacar.y + b_destacar.h, 6, 6, false);
                draw_set_color(c_white); draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text_transformed(b_destacar.x + (b_destacar.w / 2), b_destacar.y + (b_destacar.h / 2) + 2, "*", 1.8, 1.8, star_rotation);
            }
            
            if (b_restaurar.activo) {
                var rest_col = merge_colour(#3C8C3C, #64B464, b_restaurar.hover);
                var alf_rest = b_restaurar.alpha_mult * base_alpha;
                draw_set_alpha(0.3 * alf_rest); draw_set_color(c_black);
                draw_roundrect_ext(b_restaurar.x + 3, b_restaurar.y + 3, b_restaurar.x + b_restaurar.w + 3, b_restaurar.y + b_restaurar.h + 3, 6, 6, false);
                draw_set_alpha(alf_rest); draw_set_color(rest_col);
                draw_roundrect_ext(b_restaurar.x, b_restaurar.y, b_restaurar.x + b_restaurar.w, b_restaurar.y + b_restaurar.h, 6, 6, false);
                draw_set_color(c_white); draw_set_halign(fa_center); draw_set_valign(fa_middle);
                draw_text_transformed(b_restaurar.x + (b_restaurar.w / 2), b_restaurar.y + (b_restaurar.h / 2), "R", 1.2, 1.2, 0);
            }
            draw_set_halign(fa_left); draw_set_valign(fa_top);
        }
        
        // boton de reportes
        if (b_reportar.activo && my_list_index < ds_list_size(global.victories_levels)) {
            var already_reported = ds_list_find_index(global.reported_levels_session, id_l) != -1;
            if (already_reported) draw_set_color(#646469);
            else draw_set_color(merge_colour(#C83C3C, #FF6464, b_reportar.hover));
            var r_final = b_reportar.r + (b_reportar.hover * 1.5);
            draw_set_alpha(base_alpha * b_reportar.alpha_mult);
            var slide_offset = (1 - stats_slide) * 15;
            var visual_y = draw_y + 46 + 48 + slide_offset;
            draw_circle(b_reportar.x, visual_y, r_final, false);
            draw_set_color(c_white);
            draw_set_halign(fa_center); draw_set_valign(fa_middle);
            draw_text_transformed(b_reportar.x, visual_y + 1, "!", 1, 1, 0);
            draw_set_halign(fa_left); draw_set_valign(fa_top);
        }
        
        //tooltip pa la dificultad
        if (difficulty_tooltip_alpha > 0.05)
        {
            var tt_label = scr_difficulty_get_label_text(difficulty_label);
            var tt_color = scr_difficulty_get_color(difficulty_label);
            var low_conf = scr_difficulty_is_low_confidence(difficulty_confidence, difficulty_sessions);
            var tt_text = "DIFICULTAD: " + tt_label;
            if (low_conf && difficulty_label != "unplayed") tt_text += "\n(POCOS DATOS - PUEDE VARIAR)";
            else if (difficulty_label == "unplayed") tt_text = "NADIE JUGO ESTE NIVEL AUN";
            var tt_scale = 0.65;
            var tt_w = string_width(tt_text) * tt_scale;
            var tt_h = string_height(tt_text) * tt_scale;
            var tt_padding = 6;
            var tt_x = stars_x;
            var tt_y = stars_y + 14;
            draw_set_alpha(0.85 * difficulty_tooltip_alpha * base_alpha);
            draw_set_color(c_black);
            draw_roundrect_ext(tt_x - tt_padding, tt_y - tt_padding, tt_x + tt_w + tt_padding, tt_y + tt_h + tt_padding, 4, 4, false);
            draw_set_alpha(0.6 * difficulty_tooltip_alpha * base_alpha);
            draw_set_color(tt_color);
            draw_roundrect_ext(tt_x - tt_padding, tt_y - tt_padding, tt_x + tt_w + tt_padding, tt_y + tt_h + tt_padding, 4, 4, true);
            draw_set_alpha(difficulty_tooltip_alpha * base_alpha);
            draw_set_color(tt_color);
            draw_set_halign(fa_left); draw_set_valign(fa_top);
            draw_text_transformed(tt_x, tt_y, tt_text, tt_scale, tt_scale, 0);
        }
        
        draw_set_alpha(base_alpha);
    }
}

// alineacion 
draw_set_alpha(1);
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

