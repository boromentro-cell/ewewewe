// primero los desempaquetados y despues las animaciones
var _mx = mouse_x;
var _my = mouse_y;

// si estan abiertos estos, no hacemos nada
if (instance_exists(obj_comments_window))
    exit;

if (instance_exists(obj_user_profile_view))
    exit;

depth = -10;

if (like_cooldown > 0)
    like_cooldown--;

// desempaquetado de texturas

if (unpacking_textures)
{
    if (!buffer_exists(unpack_buffer))
    {
        unpacking_textures = false;
        scr_debug_log("Error: Buffer perdido");
        download_state = 0;
        exit;
    }
    
    var _time_budget = 12000;
    var _start_time = get_timer();
    
    while (unpack_index < unpack_count && (get_timer() - _start_time) < _time_budget)
    {
        var name_len = buffer_read(unpack_buffer, buffer_u16);
        var file_name = "";
        
        for (var _c = 0; _c < name_len; _c++)
            file_name += chr(buffer_read(unpack_buffer, buffer_u8));
        
        var file_size_inner = buffer_read(unpack_buffer, buffer_u32);
        var full_path = unpack_target_dir + file_name;
        var dir_path = filename_dir(full_path);
        
        if (dir_path != "")
        {
            if (file_exists(dir_path))
                file_delete(dir_path);
            
            if (!directory_exists(dir_path))
                directory_create(dir_path);
        }
        
        buffer_save_ext(unpack_buffer, full_path, buffer_tell(unpack_buffer), file_size_inner);
        buffer_seek(unpack_buffer, buffer_seek_relative, file_size_inner);
        unpack_index++;
    }
    
    if (unpack_count > 0)
        install_progress = floor((unpack_index / unpack_count) * 100);
    
    if (unpack_index >= unpack_count)
    {
        buffer_delete(unpack_buffer);
        unpack_buffer = -1;
        unpacking_textures = false;
        
        if (file_exists(unpack_source_file))
            file_delete(unpack_source_file);
        
        scr_debug_log("Simplepack extraído: " + string(unpack_count) + " archivos");
        texture_downloaded = true;
        texture_applied = true;
        scr_level_file_start_custom_process();
    }
    
    exit;
}

// lo mismo para los objetos custom, cada uno con su propia carpeta de destino
if (custom_unpacking)
{
    if (!buffer_exists(custom_unpack_buffer))
    {
        custom_unpacking = false;
        scr_debug_log("CUSTOMS: Error - Buffer de unpack perdido");
        custom_download_index++;
        scr_level_file_search_next_custom();
        exit;
    }
    
    var _time_budget = 12000;
    var _start_time = get_timer();
    
    while (custom_unpack_index < custom_unpack_count && (get_timer() - _start_time) < _time_budget)
    {
        var name_len = buffer_read(custom_unpack_buffer, buffer_u16);
        var file_name = "";
        
        for (var _c = 0; _c < name_len; _c++)
            file_name += chr(buffer_read(custom_unpack_buffer, buffer_u8));
        
        var file_size_inner = buffer_read(custom_unpack_buffer, buffer_u32);
        var full_path = custom_unpack_target_dir + file_name;
        var dir_path = filename_dir(full_path);
        
        if (dir_path != "")
        {
            if (file_exists(dir_path))
                file_delete(dir_path);
            
            if (!directory_exists(dir_path))
                directory_create(dir_path);
        }
        
        buffer_save_ext(custom_unpack_buffer, full_path, buffer_tell(custom_unpack_buffer), file_size_inner);
        buffer_seek(custom_unpack_buffer, buffer_seek_relative, file_size_inner);
        custom_unpack_index++;
    }
    
    if (custom_unpack_count > 0)
        custom_install_progress = floor((custom_unpack_index / custom_unpack_count) * 100);
    
    if (custom_unpack_index >= custom_unpack_count)
    {
        buffer_delete(custom_unpack_buffer);
        custom_unpack_buffer = -1;
        custom_unpacking = false;
        
        if (file_exists(custom_unpack_source_file))
            file_delete(custom_unpack_source_file);
        
        scr_debug_log("CUSTOMS: Simplepack extraído: " + string(custom_unpack_count) + " archivos");
        var _item = custom_download_queue[custom_download_index];
        var _folder = _item.name;
        if (variable_struct_exists(_item, "folder") && _item.folder != "")
            _folder = _item.folder;
        scr_custom_hot_reload(_folder, _item.workshop_id, _item.name, "");
        custom_download_index++;
        scr_level_file_search_next_custom();
    }
    
    exit;
}

if (instance_exists(obj_comments_window))
    exit;

// anim de estrellas
pulse_timer += 0.08;

if (pulse_timer > (2 * pi))
    pulse_timer -= (2 * pi);

// la tarjeta espera a que el loader le de permiso y recien ahi arranca el fade de entrada
if (allowed_to_appear && !visible && !fading_in)
{
    if (imagen_nivel != -1 || load_wait_timer > 45)
    {
        var is_near_screen = (y > -200 && y < room_height + 200);
        
        if (is_near_screen)
        {
            visible = true;
            fade_alpha = 0;
            fading_in = true;
            fade_timer = 0;
        }
        else
        {
            visible = true;
            fade_alpha = 1;
            fading_in = false;
        }
    }
    else
    {
        load_wait_timer++;
    }
}

if (fading_in)
{
    if (my_list_index < 8)
    {
        fade_timer++;
        var t = clamp(fade_timer / 18, 0, 1);
        fade_alpha = t * (2 - t);
        
        if (fade_timer >= 18)
        {
            fade_alpha = 1;
            fading_in = false;
        }
    }
    else
    {
        fade_alpha += ((1 - fade_alpha) * 0.08);
        
        if (fade_alpha >= 0.99)
        {
            fade_alpha = 1;
            fading_in = false;
        }
    }
}

// la animacion de las estrellas, primero se cuentan de a una y despues quedan fijas
if (diff_anim_state == 1)
{
    diff_alpha += 0.3;
    
    if (diff_alpha >= 6)
    {
        diff_alpha = 6;
        diff_anim_state = 2;
    }
}
else if (diff_anim_state == 2)
{
    diff_alpha = 6;
}
else
{
    diff_alpha = 0;
}

// la miniatura entra con su propio fade cuando termina de cargar el sprite
if (imagen_nivel != -1 && thumbnail_fade < 1)
{
    thumbnail_fade += 0.08;
    
    if (thumbnail_fade > 1)
        thumbnail_fade = 1;
}

// anim del corazon cuando das like
if (heart_bounce > 0)
{
    heart_bounce -= 0.1;
    heart_scale = 1 + (sin(heart_bounce * pi) * 0.4);
}
else
{
    heart_scale = lerp(heart_scale, 1, 0.15);
}

var i = ds_list_size(like_particles) - 1;

while (i >= 0)
{
    var p = ds_list_find_value(like_particles, i);
    p[0] += p[2];
    p[1] += p[3];
    p[3] += 0.15;
    p[4] -= 0.03;
    
    if (p[4] <= 0)
        ds_list_delete(like_particles, i);
    else
        ds_list_set(like_particles, i, p);
    
    i--;
}

// el hover de la tarjeta
var card_left = x;
var card_right = x + 550;
var card_top = y;
var card_bottom = y + current_height;
var is_hovering = _mx >= card_left && _mx <= card_right && _my >= card_top && _my <= card_bottom;
hover_progress = lerp(hover_progress, is_hovering ? 1 : 0, 0.12);
card_y_offset = lerp(card_y_offset, is_hovering ? -2 : 0, 0.15);
highlight_alpha = lerp(highlight_alpha, is_hovering ? 0.12 : 0.06, 0.1);
title_glow = lerp(title_glow, is_hovering ? 0.3 : 0, 0.1);
var thumb_y_start = y + 30;
var thumb_hover = is_hovering && _mx < (x + 140) && _my > thumb_y_start;
thumbnail_hover_scale = lerp(thumbnail_hover_scale, thumb_hover ? 1.02 : 1, 0.1);
// abrir y cerrar la tarjeta, expand_progress acompaña a todo lo adentro
var target_height = expanded ? height_expanded : height_collapsed;
current_height = lerp(current_height, target_height, 0.15);

if (abs(current_height - target_height) < 0.5)
    current_height = target_height;

expand_progress = lerp(expand_progress, expanded ? 1 : 0, 0.12);
stats_slide = lerp(stats_slide, expanded ? 1 : 0, 0.1);

// el nombre del autor es clickeable, de ahi se abre el perfil
if (my_list_index >= 0 && my_list_index < ds_list_size(global.autor_levels))
{
    var aut_l = ds_list_find_value(global.autor_levels, my_list_index);
    var autor_w = string_width("por " + aut_l) * 0.9;
    var autor_h = 14;
    var autor_x = (x + 550) - 12 - autor_w;
    var autor_y = y + 28;
    var autor_hovering = _mx > autor_x && _mx < (autor_x + autor_w) && _my > (autor_y - 2) && _my < (autor_y + autor_h);
    autor_hover_progress = lerp(autor_hover_progress, autor_hovering ? 1 : 0, 0.15);
}

// la descripcion se pide la primera vez que se abre la tarjeta y despues queda guardada
if (expanded && !descripcion_cargada && my_list_index >= 0)
{
    if (my_list_index < ds_list_size(global.descriptions))
    {
        descripcion = ds_list_find_value(global.descriptions, my_list_index);
        
        if (is_undefined(descripcion) || descripcion == "")
            descripcion = "(Sin descripción)";
        
        descripcion_cargada = true;
    }
}

// se apagan todos los botones y se vuelven a prender los que correspondan segun el estado,
// asi no queda ninguno clickeable de un frame anterior
for (var bi = 0; bi < array_length(lista_botones); bi++)
{
    lista_botones[bi].activo = false;
    lista_botones[bi].click = false;
}

var base_y = y + card_y_offset;
var draw_cr_y = base_y + 28 + 18;

// la posicion de los botones se calcula solo con la tarjeta abierta
if (expanded && expand_progress > 0.01)
{
    var slide_offset = (1 - stats_slide) * 15;
    var bottom_y = ((base_y + current_height) - 55) + slide_offset;
    var margin_right = (x + 550) - 18;
    b_jugar.w = 180;
    b_jugar.h = 42;
    b_jugar.x = margin_right - b_jugar.w;
    b_jugar.y = bottom_y;
    b_jugar.alpha_mult = expand_progress;
    b_jugar.activo = true;
    b_comentarios.w = 42;
    b_comentarios.h = 42;
    b_comentarios.x = b_jugar.x - 12 - b_comentarios.w;
    b_comentarios.y = bottom_y;
    b_comentarios.alpha_mult = expand_progress;
    b_comentarios.activo = true;
    
    if (variable_global_exists("user_is_admin") && global.user_is_admin)
    {
        var admin_x = x + 15;
        b_eliminar.w = 42;
        b_eliminar.h = 42;
        b_eliminar.x = admin_x;
        b_eliminar.y = bottom_y;
        b_eliminar.alpha_mult = expand_progress;
        b_eliminar.activo = true;
        admin_x += 52;
        b_destacar.w = 42;
        b_destacar.h = 42;
        b_destacar.x = admin_x;
        b_destacar.y = bottom_y;
        b_destacar.alpha_mult = expand_progress;
        b_destacar.activo = true;
        admin_x += 52;
        
        if (instance_exists(obj_level_loader) && obj_level_loader.view_mode == 5)
        {
            b_restaurar.w = 42;
            b_restaurar.h = 42;
            b_restaurar.x = admin_x;
            b_restaurar.y = bottom_y;
            b_restaurar.alpha_mult = expand_progress;
            b_restaurar.activo = true;
        }
    }
    
    if (my_list_index < ds_list_size(global.victories_levels))
    {
        b_reportar.r = 12;
        b_reportar.x = (x + 550) - 25;
        b_reportar.y = draw_cr_y + 48;
        b_reportar.alpha_mult = 1;
        b_reportar.activo = true;
    }
}

// lo unico que mostramos con la tarjeta cerrada es el cora
b_like.x = x + 164;
b_like.y = base_y + 42;
b_like.r = 15;
b_like.activo = true;
var click_izq = mouse_check_button_pressed(mb_left);
var boton_presionado_este_frame = false;


for (var bi = 0; bi < array_length(lista_botones); bi++)
{
    var b = lista_botones[bi];
    
    if (!b.activo)
        continue;
    
    if ((b.id == "jugar" || b.id == "comentarios" || b.id == "eliminar" || b.id == "destacar" || b.id == "restaurar") && expanded && expand_progress <= 0.5)
        continue;
    
    if (b.id == "jugar" && download_state != 0 && download_state != 4)
        continue;
    
    var _is_hover = false;
    
    if (b.tipo == "rect")
        _is_hover = _mx > b.x && _mx < (b.x + b.w) && _my > b.y && _my < (b.y + b.h);
    else if (b.tipo == "circulo")
        _is_hover = point_distance(_mx, _my, b.x, b.y) < b.r;
    
    b.hover = lerp(b.hover, _is_hover ? 1 : 0, 0.18);
    
    // en modo party los miembros miran pero no tocan
    if (_is_hover && click_izq && !(variable_global_exists("party_bloqueado") && global.party_bloqueado))
    {
        b.click = true;
        boton_presionado_este_frame = true;
    }
}

if (b_destacar.hover > 0.1)
    star_rotation += 3;
else
    star_rotation = lerp(star_rotation, 0, 0.1);

// el like se dibuja al toque y despues se manda al server, si el server rechaza
// no se vuelve atras
if (b_like.click && like_cooldown <= 0)
{
    like_cooldown = 30;
    
    if (global.user_logged_in)
    {
        if (variable_global_exists("user_discord_linked") && global.user_discord_linked)
        {
            var id_l = ds_list_find_value(global.id_levels, my_list_index);
            var lik_l = ds_list_find_value(global.likes_levels, my_list_index);
            
            if (is_string(lik_l))
                lik_l = real(lik_l);
            
            if (!variable_global_exists("like_ultimo_nivel"))
            {
                global.like_ultimo_nivel = -1;
                global.like_ultimo_tiempo = -99999;
            }
            
            // si quedaron dos tarjetas apiladas el click cae en las dos, la de atras se descarta
            var _repetido = (global.like_ultimo_nivel == id_l) && ((current_time - global.like_ultimo_tiempo) < 400);
            
            if (!_repetido)
            {
                global.like_ultimo_nivel = id_l;
                global.like_ultimo_tiempo = current_time;
                // el estado que vale es el de la lista, el de la instancia puede estar viejo
                var _liked = is_liked;
                
                if (my_list_index < ds_list_size(global.is_liked_list))
                    _liked = ds_list_find_value(global.is_liked_list, my_list_index);
                
                show_debug_message("LIKE nivel=" + string(id_l) + " indice=" + string(my_list_index) + " estaba=" + string(_liked) + " listalikes=" + string(ds_list_size(global.is_liked_list)) + " niveles=" + string(ds_list_size(global.id_levels)) + " instancia=" + string(id));
                global.debug_like_request = scr_supabase_toggle_like(id_l, _liked);
                heart_bounce = 1;
                
                if (!_liked)
                {
                    for (var p = 0; p < 8; p++)
                    {
                        var angle = random(360);
                        var spd = 1.5 + random(2);
                        var particle = [b_like.x, b_like.y, lengthdir_x(spd, angle), lengthdir_y(spd, angle) - 1, 1, 1.5 + random(1.5)];
                        ds_list_add(like_particles, particle);
                    }
                    
                    is_liked = true;
                    lik_l += 1;
                }
                else
                {
                    is_liked = false;
                    lik_l = max(0, lik_l - 1);
                }
                
                ds_list_replace(global.is_liked_list, my_list_index, is_liked);
                ds_list_replace(global.likes_levels, my_list_index, lik_l);
            }
        }
        else
        {
            show_message_async("¡Vincula Discord para dar likes!");
        }
    }
    else
    {
        show_message_async("Inicia sesión para dar like");
    }
}

// descargas owo (user0)
if (b_jugar.click)
{
    // cada global del party se lee detras de su propia guarda: si la sesion
    // nunca inicializo el party no se puede tocar nada que no exista
    var _party_activo = variable_global_exists("party_activo") && global.party_activo;
    var _party_lider = variable_global_exists("party_soy_lider") && global.party_soy_lider;
    var _party_ocupado = variable_global_exists("party_preflight") && global.party_preflight;
    
    if (_party_activo && _party_lider && !_party_ocupado)
    {
        scr_party_invitar(id);
    }
    else
    {
        event_user(0);
    }
}

if (b_comentarios.click && !instance_exists(obj_comments_window))
{
    var win = instance_create_depth(0, 0, 0, obj_comments_window);
    win.content_type = 0;
    win.content_id = ds_list_find_value(global.id_levels, my_list_index);
    win.request_comments = scr_get_level_comments(win.content_id, win.comments_per_page, 0);
    win.request_count = scr_get_comment_count(win.content_id);
}

// botones de admin, borrar el nivel y ponerlo o sacarlo de destacados
if (b_eliminar.click)
{
    var id_l = ds_list_find_value(global.id_levels, my_list_index);
    
    if (show_question("¿Seguro que quieres ELIMINAR este nivel permanentemente?"))
        delete_request_id = scr_supabase_delete_level(id_l);
}

if (b_destacar.click)
{
    var level_id = ds_list_find_value(global.id_levels, my_list_index);
    var is_in_featured = false;
    
    if (instance_exists(obj_level_loader))
    {
        for (var s = 0; s < ds_list_size(obj_level_loader.admin_featured_ids); s++)
        {
            if (ds_list_find_value(obj_level_loader.admin_featured_ids, s) == level_id)
            {
                is_in_featured = true;
                break;
            }
        }
    }
    
    if (is_in_featured || is_admin_featured)
    {
        if (show_question("¿Quitar este nivel de destacados?"))
        {
            request_toggle_featured = scr_toggle_admin_featured(level_id, true);
            is_admin_featured = false;
            
            if (instance_exists(obj_level_loader))
            {
                for (var s = 0; s < ds_list_size(obj_level_loader.admin_featured_ids); s++)
                {
                    if (ds_list_find_value(obj_level_loader.admin_featured_ids, s) == level_id)
                    {
                        ds_list_delete(obj_level_loader.admin_featured_ids, s);
                        break;
                    }
                }
            }
        }
    }
    else
    {
        request_toggle_featured = scr_toggle_admin_featured(level_id, false);
        is_admin_featured = true;
        show_message_extra("¡Nivel agregado a destacados!");
        
        if (instance_exists(obj_level_loader))
            ds_list_add(obj_level_loader.admin_featured_ids, level_id);
    }
}

if (b_restaurar.click)
{
    var id_l = ds_list_find_value(global.id_levels, my_list_index);
    request_restore = scr_supabase_restore_level(id_l);
    show_message_async("Nivel restaurado. Se eliminaron los reportes.");
    instance_destroy();
}

// reportar. se guarda en una lista de la sesion para no dejar reportar dos veces lo mismo,
// y hay cinco minutos de espera entre un reporte y el prox
if (b_reportar.click)
{
    if (global.user_logged_in)
    {
        var aut_id = ds_list_find_value(global.author_ids, my_list_index);
        var my_uid = variable_global_exists("user_id") ? global.user_id : "";
        
        if (aut_id == my_uid && my_uid != "")
        {
            show_message_async("No puedes denunciar tu propio nivel.");
        }
        else
        {
            var id_l = ds_list_find_value(global.id_levels, my_list_index);
            var already_reported = ds_list_find_index(global.reported_levels_session, id_l) != -1;
            
            if (!already_reported)
            {
                var time_passed = current_time - global.last_report_time;
                
                if (time_passed < 300000)
                {
                    var remaining = ceil((300000 - time_passed) / 60000);
                    show_message_async("Espera " + string(remaining) + " min para otra denuncia.");
                }
                else
                {
                    request_report = scr_supabase_report_level(id_l, my_uid);
                    ds_list_add(global.reported_levels_session, id_l);
                    global.last_report_time = current_time;
                    show_message_async("Nivel denunciado correctamente.");
                }
            }
        }
    }
    else
    {
        show_message_async("Inicia sesión para denunciar niveles.");
    }
}

// click en cualquier otra parte de la tarjeta, abre o cierra. si hubo un boton apretado
// en este frame no se hace nada
if (mouse_check_button_pressed(mb_left))
{
    if (my_list_index >= 0 && my_list_index < ds_list_size(global.autor_levels))
    {
        var autor_name = ds_list_find_value(global.autor_levels, my_list_index);
        var autor_id = "";
        
        if (variable_global_exists("author_ids"))
        {
            if (my_list_index < ds_list_size(global.author_ids))
                autor_id = ds_list_find_value(global.author_ids, my_list_index);
        }
        
        var autor_w = (string_length(autor_name) * 7) + 15;
        var autor_x = (x + 550) - 12 - autor_w;
        var autor_y = y + 28;
        var autor_h = 16;
        
        if (_mx > autor_x && _mx < (autor_x + autor_w) && _my > autor_y && _my < (autor_y + autor_h))
        {
            if (autor_id != "" && !is_undefined(autor_id) && !instance_exists(obj_user_profile_view))
            {
                var profile_view = instance_create_depth(0, 0, 0, obj_user_profile_view);
                profile_view.target_user_id = autor_id;
                profile_view.target_username = autor_name;
                
                with (profile_view)
                    event_user(0);
                
                exit;
            }
        }
    }
    
    var dentro_tarjeta = _mx > x && _mx < (x + 550) && _my > y && _my < (y + current_height);
    
    if (dentro_tarjeta && !boton_presionado_este_frame && !unpacking_textures && !custom_unpacking)
    {
        var can_interact = download_state == 0 || download_state == 4;
        
        if (!expanded && can_interact)
        {
            with (obj_level_file)
            {
                if (id != other.id)
                    expanded = false;
            }
            
            expanded = true;

            // si soy el lider del party la tarjeta se abre para todos
            if (variable_global_exists("party_activo") && global.party_activo
                && variable_global_exists("party_soy_lider") && global.party_soy_lider
                && scr_party_transporte_listo())
            {
                scr_party_enviar(global.ws_socket,
                {
                    action: "PARTY_RELAY",
                    msg: { t: "card_open", idx: my_list_index }
                });
            }
        }
        else if (expanded && can_interact)
        {
            if (_my < (y + height_collapsed))
                expanded = false;
        }
    }
}

// chequeamos por las dudas las listas por si el loader las vacio por error
if (my_list_index >= 0 && my_list_index < ds_list_size(global.id_levels))
{
    var id_l = ds_list_find_value(global.id_levels, my_list_index);
    
    if (!is_undefined(id_l) && string(id_l) != "")
    {
        if (my_list_index < ds_list_size(global.thumbnail_urls))
        {
            var thumb_url = ds_list_find_value(global.thumbnail_urls, my_list_index);
            
            if (thumb_url != "" && !is_undefined(thumb_url) && thumbnail_url_direct != thumb_url)
            {
                thumbnail_url_direct = thumb_url;
                thumbnail_fade = 0;
                
                if (imagen_nivel != -1 && sprite_exists(imagen_nivel))
                {
                    sprite_delete(imagen_nivel);
                    imagen_nivel = -1;
                }
                
                if (scr_isWindows())
                {
                    if (!directory_exists(working_directory + "/cache_img"))
                        directory_create(working_directory + "/cache_img");
                    
                    imagen_path = working_directory + "/cache_img/" + string(id_l) + ".png";
                }
                else
                {
                    imagen_path = getDire2("SM4J", "cache_img") + "/" + string(id_l) + ".png";
                }
                
                thumb_queued = false;
            }
            
            if (imagen_nivel == -1 && imagen_path != "" && !imagen_cargando)
            {
                var is_near_screen = (y > -200 && y < room_height + 200);
                var is_active_loader = (allowed_to_appear || visible || fading_in);
                var is_initial_batch = (my_list_index < 8);
                
                if (is_near_screen || is_active_loader || is_initial_batch)
                {
                    var preloaded_spr = scr_preload_get_thumb(id_l);
                    
                    if (preloaded_spr != -1)
                    {
                        imagen_nivel = preloaded_spr;
                        imagen_cargando = false;
                        thumb_queued = true;
                    }
                    else if (!thumb_queued && variable_global_exists("thumb_queue") && thumb_retry_count < 3)
                    {
                        ds_list_add(global.thumb_queue, id);
                        thumb_queued = true;
                        imagen_cargando = true;
                    }
                }
            }
        }
    }
}
