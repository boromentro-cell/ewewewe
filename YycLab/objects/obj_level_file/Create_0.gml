// la tarjeta no se guarda los datos del nivel, se guarda my_list_index y con ese numero lee
// las listas globales que armo el loader. si el indice no coincide muestra el nivel de al lado (es el fallback)
n = 1;
play_level = "";
my_list_index = -1;
y_real = y;
image_speed = 0;
depth = -10;
request_report = -1;
request_restore = -1;
star_rotation = 0;
is_admin_featured = false;
request_toggle_featured = -1;
delete_request_id = -1;
// la tarjeta se abre y se cierra, el expand_progress es lo que mueve todo lo de adentro
expanded = false;
height_collapsed = 110;
height_expanded = 230;
current_height = height_collapsed;
expand_progress = 0;
card_scale = 1;
card_y_offset = 0;
stats_slide = 0;
hover_progress = 0;
autor_hover_progress = 0;
highlight_alpha = 0;
title_glow = 0;
pulse_timer = 0;
// corazon
is_liked = false;
heart_scale = 1;
heart_bounce = 0;
like_particles = ds_list_create();
// la miniatura. imagen_id_actual guarda de que nivel es la que esta puesta, asi si la tarjeta
// se recicla
imagen_nivel = -1;
imagen_cargando = false;
imagen_path = "";
imagen_id_actual = "";
thumbnail_url_direct = "";
thumbnail_download_id = -1;
thumb_queued = false;
thumbnail_fade = 0;
thumbnail_hover_scale = 1;
// descarga del nivel
// download_state maneja el estado, 0 quieto, 1 descargando el nivel, 2 descargando la textura, 3 instalandola, 4 arrancando,
// 5 bajando customs, 6 instalando customs
downloading_level_id = -1;
level_download_id = -1;
level_downloading = false;
level_download_progress = 0;
level_type = 0;
temp_download_path = "";
request_download_url = -1;
bundle_request = -1;
bundle_file_name = "";
bundle_cold_id = "";
bridge_tried = false;
last_download_url = "";
last_download_source = "";
catbox_salteado = false;
download_state = 0;
// textura del nivel, puede venir del bridge si no esta en cloudflare, que lo saca de
// telegram, donde usamos el cold id, o de internet archive. una vez que lo descargamos se sube a cf
texture_name = "";
texture_name_for_search = "";
texture_file_name = "";
texture_cold_id = "";
texture_github_url = "";
texture_needs_download = false;
texture_download_request = -1;
request_texture_bridge_url = -1;
texture_r2_directo = false;
texture_download_source = "";
texture_search_request = -1;
texture_download_path = "";
texture_download_progress = 0;
texture_downloaded = false;
texture_applied = false;
texture_applying = false;
texture_install_path = "";
texture_transition_triggered = false;
// descomprimimos la textura despacio para no freezear
unpacking_textures = false;
unpack_buffer = -1;
unpack_count = 0;
unpack_index = 0;
unpack_target_dir = "";
unpack_source_file = "";
install_progress = 0;
zip_unpacking = false;
zip_buffer = -1;
zip_entries = [];
zip_entry_index = 0;
zip_total_entries = 0;
zip_target_dir = "";
zip_source_file = "";
// descripcion del nivel
descripcion = "";
descripcion_cargada = false;
profile_obj = -1;
profile_offset_y = 26;
// dificultad y clear rate.
clear_rate = -1;
difficulty_label = "unplayed";
difficulty_confidence = "none";
difficulty_sessions = 0;
difficulty_tooltip_visible = false;
difficulty_tooltip_alpha = 0;
diff_stars_count = 0;
diff_star_timer = 0;
diff_anim_state = 0;
diff_alpha = 0;
// paleta de la tarjeta
color_shadow = 0;
color_card_dark = 0;
color_card = 16250357;
color_card_hover = 16777215;
color_card_light = 14802140;
color_accent = 16024898;
color_accent_hover = 16752740;
color_text_title = 16777215;
color_text_secondary = 5918800;
color_heart = 5264367;
color_heart_empty = 12170420;
color_plays = 41215;
color_xp = 5287756;
clear_rate_color = 8421504;
// las tarjetas no aparecen de golpe, entran con un fade in
fade_alpha = 0;
fading_in = false;
fade_speed = 0.065;
fade_timer = 0;

// si la dificultad ya se habia procesado antes, la tarjeta nace con las estrellas puestas
// y no repite la animacion
if (variable_global_exists("difficulties_processed") && global.difficulties_processed)
{
    diff_anim_state = 2;
    diff_alpha = 6;
}

// los botones son structs y no objetos, asi el hover y el click se resuelven a mano
// dentro del step de la tarjeta y no hay una instancia por cada boton
lista_botones = [];

function crear_boton(arg0, arg1)
{
    var _btn = 
    {
        id: arg0,
        tipo: arg1,
        x: 0,
        y: 0,
        w: 0,
        h: 0,
        r: 0,
        hover: 0,
        alpha_mult: 1,
        activo: false,
        click: false
    };
    array_push(lista_botones, _btn);
    return _btn;
}

b_jugar = crear_boton("jugar", "rect");
b_comentarios = crear_boton("comentarios", "rect");
b_eliminar = crear_boton("eliminar", "rect");
b_destacar = crear_boton("destacar", "rect");
b_restaurar = crear_boton("restaurar", "rect");
b_reportar = crear_boton("reportar", "circulo");
b_like = crear_boton("like", "circulo");
like_cooldown = 0;
// objetos custom que usa el nivel, vienen como un json en la lista global
customs_used = "";
custom_search_request = -1;
custom_bridge_request = -1;
custom_download_request = -1;
custom_r2_directo = false;
custom_download_source = "";
custom_download_queue = [];
custom_download_index = 0;
custom_total_to_download = 0;
custom_download_progress = 0;
custom_temp_download_path = "";
custom_install_path = "";
custom_objects_data = [];
custom_unpacking = false;
custom_unpack_buffer = -1;
custom_unpack_count = 0;
custom_unpack_index = 0;
custom_unpack_target_dir = "";
custom_unpack_source_file = "";
custom_install_progress = 0;
custom_badge_hover = 0;
custom_tooltip_alpha = 0;
custom_objects_info = [];
custom_objects_parsed = false;
// hasta que el loader no la habilita la tarjeta no se dibuja ni responde a nada
allowed_to_appear = false;
load_wait_timer = 0;
thumb_retry_count = 0;
