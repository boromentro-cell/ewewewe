if (!variable_global_exists("supabase_url"))
    scr_supabase_init();

var _restore_browser = false;

if (variable_global_exists("browser_return_pending") && variable_global_exists("browser_return_valid")
    && global.browser_return_pending == true && global.browser_return_valid == true)
{
    if (variable_global_exists("browser_return_room") && global.browser_return_room == room)
    {
        if (global.browser_return_view == 0 || global.browser_return_view == 2 || global.browser_return_view == 3)
            _restore_browser = true;
    }
}

if (variable_global_exists("browser_return_pending"))
    global.browser_return_pending = false;

// volviendo de un nivel la victoria se resetea siempre, aunque haya sido en
// solitario: si el flag de salida hecha se queda pegado, el proximo nivel no
// puede volver nunca mas
global.party_win_exit_done = false;
global.party_win_activo = false;
global.party_win_listo = false;
global.party_win_yo = false;
global.party_win_ventana = false;
global.party_win_bajada = false;
global.party_win_saliendo = false;
global.party_win_ganadores = [];
global.party_win_xp_listos = [];
global.party_win_level_id = -1;

// con party vivo se reabre la navegacion: el hud sigue de antes
if (variable_global_exists("party_activo") && global.party_activo)
{
    global.party_mp_activo = false;
    // la invitacion anterior ya cerro: el lider tiene que poder jugar de nuevo
    global.party_bloqueado = false;
    scr_debug_log("BROWSER: volvi con el party. ws=" + string(variable_global_exists("ws_socket") ? global.ws_socket : -1)
        + " lider=" + string(global.party_soy_lider)
        + " hud=" + string(instance_exists(obj_party_hud))
        + " p2p=" + string(instance_exists(obj_p2p_core)));

    if (!instance_exists(obj_party_hud))
        instance_create_depth(0, 0, -999999, obj_party_hud);

    // el core tambien revive: si se murio en la salida el party se quedaba
    // sin p2p para siempre. recien creado se rearma solo: stun, intercambio
    // de ips y punch salen de los globales que siguen vivos
    if (!instance_exists(obj_p2p_core))
    {
        instance_create_depth(0, 0, -999998, obj_p2p_core);
        scr_debug_log("BROWSER: p2p_core recreado al volver, rearmando mesh");
    }

    // un latido apenas piso el browser: si el proxy corto el ws durante el
    // nivel esto lo destapa en el momento y no cuando el lider mueve la mano
    if (scr_party_transporte_listo())
    {
        scr_party_enviar(global.ws_socket, { action: "PARTY_RELAY", msg: { t: "kp" } });
        scr_debug_log("BROWSER: latido mandado al volver");
    }
    else
    {
        scr_debug_log("BROWSER: el ws esta caido al volver, no hay navegacion compartida");
    }
}

if (!_restore_browser && variable_global_exists("browser_return_valid"))
    global.browser_return_valid = false;

scr_debug_log("LOADER CREATE: restore=" + string(_restore_browser) + " room=" + room_get_name(room));

// estado de los botones
refresh_hover = false;
refresh_hover_progress = 0;
refresh_spinning = false;
refresh_spin_angle = 0;
refresh_cooldown = 0;
report_hover_progress = 0;
restore_hover_progress = 0;
request_report = -1;
request_restore = -1;
parse_levels_list = -1;
parse_count = 0;
parse_niveles_antes = 0;
if (!variable_global_exists("last_report_time"))
    global.last_report_time = -300000;

if (!variable_global_exists("reported_levels_session"))
    global.reported_levels_session = ds_list_create();

// listas globales paralelas
// todas se leen con el mismo my_list_index desde las tarjetas
global.lvl_on = 1;
global.world_online = 0;
var _listas_browser = ["id_levels", "autor_levels", "is_featured_list", "difficulty_labels", "author_ids", "texture_used_levels", "custom_objects_used_levels", "name_levels", "date_levels", "views_levels", "likes_levels", "file_urls", "thumbnail_urls", "descriptions", "is_liked_list", "attempts_levels", "victories_levels", "unique_players_levels", "total_plays_levels", "first_clear_user_ids", "first_clear_usernames", "thumb_queue", "request_times", "cold_storage_ids", "difficulty_confidences", "difficulty_sessions"];

if (_restore_browser)
{
    for (var _li = 0; _li < array_length(_listas_browser); _li++)
    {
        var _nm = _listas_browser[_li];
        
        if (!variable_global_exists(_nm) || !ds_exists(variable_global_get(_nm), ds_type_list))
            variable_global_set(_nm, ds_list_create());
    }
    
    ds_list_clear(variable_global_get("thumb_queue"));
    
    if (!variable_global_exists("tags_levels") || !ds_exists(global.tags_levels, ds_type_list))
        global.tags_levels = ds_list_create();
}
else
{
    for (var _li = 0; _li < array_length(_listas_browser); _li++)
    {
        var _nm = _listas_browser[_li];
        
        if (variable_global_exists(_nm) && ds_exists(variable_global_get(_nm), ds_type_list))
            ds_list_clear(variable_global_get(_nm));
        else
            variable_global_set(_nm, ds_list_create());
    }
    
    if (variable_global_exists("tags_levels") && ds_exists(global.tags_levels, ds_type_list))
    {
        for (var _t = 0; _t < ds_list_size(global.tags_levels); _t++)
        {
            var _sub = ds_list_find_value(global.tags_levels, _t);
            
            if (ds_exists(_sub, ds_type_list))
                ds_list_destroy(_sub);
        }
        
        ds_list_clear(global.tags_levels);
    }
    else
        global.tags_levels = ds_list_create();
}
global.thumb_downloading = false;
global.thumb_current_instance = -1;
global.thumb_current_request = -1;
global.thumb_cooldown = 0;
// las horas de los ultimos pedidos
if (!variable_global_exists("request_times") || !ds_exists(global.request_times, ds_type_list))
    global.request_times = ds_list_create();
spam_message_active = false;
global.autor_s = "";
global.name_s = "";
global.sort = "recent";
global.end_of_results = false;
global.page = 0;

obj_test_profile = 2;
obj_search_panel = 2;
// la primera tanda pide 24 y la carga progresiva trae 16, asi el scroll no se queda sin nada
levels_per_page = 24;
levels_per_load = 16;
total_levels_loaded = 0;
total_cards_created = 0;
scroll_y = 0;
scroll_max = 0;
touch_y_start = -1;
touch_y_prev = 0;
scroll_momentum = 0;
// alto de una tarjeta
card_height = 120;
visible_height = room_height - 100;
// 0 recientes, 1 destacados por admin, 2 populares, 3 mas dificiles, 4 busqueda, 5 reportados
view_mode = 0;
// destacados
request_admin_featured = -1;
admin_featured_loading = false;
admin_featured_ids = ds_list_create();
request_check_featured = -1;
admin_featured_retry_count = 0;
admin_featured_max_retries = 3;
admin_featured_retry_timer = 0;
admin_featured_retry_delay = 60;
admin_featured_failed = false; 

featured_section_height = 0;
featured_loaded = true;
featured_loading = false;
featured_levels = ds_list_create();
featured_thumbs = ds_list_create();
featured_thumb_requests = ds_list_create();
featured_hover = -1;
featured_glow_angle = 0;
request_featured = -1;
featured_retry_count = 0;
featured_max_retries = 0;
featured_retry_timer = 0;
featured_retry_delay = 90;
featured_failed = false;
featured_card_alpha[0] = 0;
featured_card_alpha[1] = 0;
featured_card_alpha[2] = 0;
featured_card_visible[0] = false;
featured_card_visible[1] = false;
featured_card_visible[2] = false;
featured_card_queue = 0;
featured_fade_timer = 0;
featured_fade_delay = 15;
featured_all_visible = true;
featured_thumb_queue = ds_list_create();
featured_thumb_downloading = false;
featured_thumb_current_request = -1;
featured_thumb_current_index = -1;
// las tarjetas vivas
instancias_tarjetas = ds_list_create();
// anim de carga
loading = true;
loading_rotation = 0;
loading_sprite = 3926;
initial_load_complete = false;

card_appear_queue = ds_list_create();
card_appear_timer = 0;
card_appear_delay = 3;
get = -1;
get_likes_request = -1;
likes_loaded = false;

cleanup_queue = ds_list_create();
cleanup_active = false;
cleanup_per_frame = 8;
pending_category_change = -1;
request_hardest = -1;

if (global.user_logged_in)
{
    if (!variable_global_exists("discord_chequeado_para"))
        global.discord_chequeado_para = "";
    
    if (global.discord_chequeado_para != global.user_id)
    {
        global.request_check_discord = scr_check_discord_linked();
        
        if (global.request_check_discord >= 0)
            global.discord_chequeado_para = global.user_id;
    }
}
else
{
    global.user_discord_linked = false;
}

global.chequeado = 1;
pending_room_restart = false;
restart_delay = 0;
// el parseo del json se corta por frames, parse_pending dice que quedo a medio hacer
parse_pending = false;
parse_raw_result = "";
parse_index = 0;
parse_total = 0;
parse_objects = ds_list_create();
parse_per_frame = 2;
request_search = -1;
mantenimiento_esperando_snapshot = false;

// filtros de la busqueda avanzada, en -1 quiere decir sin filtro de clear rate
if (!variable_global_exists("search_cr_min"))
    global.search_cr_min = -1;

if (!variable_global_exists("search_cr_max"))
    global.search_cr_max = -1;

if (!variable_global_exists("search_tags"))
    global.search_tags = ds_list_create();


rm_worlds_browser = 349;
pastel_colors[0] = 12695295;
pastel_colors[1] = 15130800;
pastel_colors[2] = 12180223;
pastel_colors[3] = 14524637;
pastel_colors[4] = 10025880;
pastel_colors[5] = 12255231;
pastel_colors[6] = 15122150;
pastel_colors[7] = 15658671;
pastel_colors_count = 8;
levels_per_color_zone = 10;
bg_color_sequence = ds_list_create();
var last_color_index = -1;

for (var i = 0; i < 50; i++)
{
    var new_index = irandom(pastel_colors_count - 1);
    
    while (new_index == last_color_index && pastel_colors_count > 1)
        new_index = irandom(pastel_colors_count - 1);
    
    ds_list_add(bg_color_sequence, pastel_colors[new_index]);
    last_color_index = new_index;
}

bg_color = ds_list_find_value(bg_color_sequence, 0);

header_height = 85;
tab_height = 30;
tab_gap = 3;
tab_reserved_space = 50;
tab_y = header_height;
list_start_x = 32;
list_start_y = header_height + tab_height + 15;

tabs_data[0][0] = "RECIENTES";
tabs_data[0][1] = 0;
tabs_data[1][0] = "POPULAR";
tabs_data[1][1] = 2;
tabs_data[2][0] = "DESTACADOS";
tabs_data[2][1] = 1;
tabs_data[3][0] = "DIFICILES";
tabs_data[3][1] = 3;
total_tabs = 4;
depth = -255;
// carga progresiva

progressive_enabled = true;
progressive_idle_timer = 0;
progressive_idle_threshold = 30;
progressive_last_scroll_y = 0;
progressive_load_timer = 0;
progressive_load_delay = 6;
progressive_target_ahead = 15;
progressive_request = -1;
progressive_loading = false;
progressive_last_visible_index = 0;
used_preloaded_data = false;
// cuanto tiempo por frame se le deja al parseo, en microsegundos
parse_budget_us = 4000;

// si la pantalla anterior dejo niveles precargados se usan esos y no se pide nada.
if (_restore_browser)
{
    global.browser_return_valid = false;
    view_mode = global.browser_return_view;
    global.sort = global.browser_return_sort;
    global.name_s = global.browser_return_name_s;
    global.autor_s = global.browser_return_autor_s;
    global.page = 0;
    global.end_of_results = false;
    
    loading = false;
    likes_loaded = true;
    initial_load_complete = true;
    global.difficulties_loaded = true;
    total_levels_loaded = ds_list_size(global.id_levels);
    
    var _target_index = floor(global.browser_return_scroll / card_height);
    var _cards_needed = min(total_levels_loaded, _target_index + 25);
    
    while (total_cards_created < _cards_needed)
    {
        var _idx = total_cards_created;
        var _check_id = ds_list_find_value(global.id_levels, _idx);
        
        if (!is_undefined(_check_id) && string(_check_id) != "")
        {
            var _nueva = instance_create_depth(list_start_x, list_start_y + (_idx * card_height), 0, obj_level_file);
            _nueva.my_list_index = _idx;
            _nueva.is_liked = ds_list_find_value(global.is_liked_list, _idx);
            _nueva.is_admin_featured = ds_list_find_value(global.is_featured_list, _idx);
            _nueva.visible = true;
            _nueva.fade_alpha = 1;
            _nueva.fading_in = false;
            ds_list_add(instancias_tarjetas, _nueva);
        }
        
        total_cards_created++;
    }
    
    scroll_y = global.browser_return_scroll;
    progressive_last_scroll_y = scroll_y;
    
    scr_debug_log("LOADER: restaurado scroll=" + string(scroll_y) + " niveles=" + string(total_levels_loaded));
}
else if (scr_preload_has_data() && !used_preloaded_data)
{
    show_debug_message("LOADER: Usando data pre-cargada! Enviando a cola asíncrona...");
    used_preloaded_data = true;
    
    for (var p = 0; p < ds_list_size(global.preloaded_data); p++)
    {
        var json_str = ds_list_find_value(global.preloaded_data, p);
        ds_list_add(parse_objects, json_str);
    }
    
    parse_pending = true;
    parse_total = ds_list_size(parse_objects);
    parse_index = 0;
    loading = true;
    initial_load_complete = false;
}
else
{
    // si estamos en mantenimiento trabajamos con los datos locales
    if (variable_global_exists("mantenimiento_activo") && global.mantenimiento_activo)
    {
        if (scr_maintenance_tiene_snapshot_local())
            scr_maintenance_poblar_browser(scr_load_list_cache("mantenimiento_full"));
        else
        {
            // la snapshot se esta bajando al inicio, se espera a que llegue
            mantenimiento_esperando_snapshot = true;
            loading = true;
        }
    }
    else
    {
        // si se acaba de borrar un nivel la ventana de recarga en vivo esta
        // abierta: no se limpia aca, vence sola a los 90 segundos
        var _forzar_fresco = variable_global_exists("browser_forzar_fresco") && global.browser_forzar_fresco > current_time;
        get = scr_supabase_get_levels(global.page, levels_per_page, global.sort, global.name_s, global.autor_s, _forzar_fresco);
    }
}

// el fondo va aparte y bien atras para que las tarjetas queden arriba
instance_create_depth(0, 0, 200, obj_level_browser_bg);
scrollbar_x = room_width - 12;
scrollbar_width = 8;
scrollbar_margin_top = header_height + tab_height + 10;
scrollbar_margin_bottom = 10;
scrollbar_track_height = room_height - scrollbar_margin_top - scrollbar_margin_bottom;
scrollbar_thumb_height = 50;
scrollbar_thumb_y = scrollbar_margin_top;
scrollbar_alpha = 0;
scrollbar_alpha_target = 0;
scrollbar_fade_timer = 0;
scrollbar_fade_delay = 60;
scrollbar_dragging = false;
scrollbar_drag_offset = 0;
scrollbar_hover = false;
scrollbar_color = 12170420;
scrollbar_color_hover = 9866380;
scrollbar_color_drag = 7234660;
scrollbar_track_color = 15460070;
// dificultad
// la calcula el server con las partidas jugadas, el cliente solo la guarda y la dibuja
global.difficulty_confidences = ds_list_create();
global.difficulty_sessions = ds_list_create();
global.difficulty_request = -1;
global.difficulties_loaded = false;
// las estrellas aparecen animadas de a un nivel por vez
difficulty_anim_queue = ds_list_create();
difficulty_anim_active = false;
difficulty_anim_current = -4;
global.difficulties_processed = false;

// freno para que no se pueda saltar de pestana a lo loco
tab_cooldown = 0;

