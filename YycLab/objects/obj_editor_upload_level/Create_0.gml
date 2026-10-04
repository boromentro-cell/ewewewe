if (!variable_global_exists("user_logged_in") || !global.user_logged_in)
{
    show_message_async("Debes iniciar sesión para subir niveles");
    instance_destroy();
    exit;
}

estado = 0;
level_path = "";
level_name = "";
level_description = "";
thumbnail_path = "";
r2_file_name = "";
r2_thumb_name = "";
cold_storage_id = "";
campo_activo = 1;
keyboard_string = "";

with (obj_editor_manager)
{
    other.level_path = clear_check_temp_level;
    other.thumbnail_path = clear_check_screenshot;
}

request_upload_level = -1;
request_upload_thumb = -1;
request_upload_db = -1;
request_catbox = -1;
catbox_file_id = "";
esperando_catbox_db = false;
db_tags_array = -1;
db_texture_value = "";
db_tex_ws_id = "";
db_customs_json = "[]";
limit_request = -1;
badges_request = -1;
discord_check_request = -1;
discord_check_retries = 3;
discord_check_timer = -1;
upload_step = 0;
loading = 0;
mensaje = "";
mensaje_color = 16777215;
color_fondo = 3936030;
color_campo = 5905970;
color_campo_activo = 7877190;
color_boton = 55295;
color_boton_hover = 16777215;
campo_w = 300;
campo_h = 30;
tags_disponibles = ds_list_create();
ds_list_add(tags_disponibles, "Tradicional");
ds_list_add(tags_disponibles, "Puzzle");
ds_list_add(tags_disponibles, "Speedrun");
ds_list_add(tags_disponibles, "Kaizo");
ds_list_add(tags_disponibles, "Corto");
ds_list_add(tags_disponibles, "Musica");
ds_list_add(tags_disponibles, "Troll");
ds_list_add(tags_disponibles, "Tematico");
tags_seleccionados = ds_list_create();
texture_enabled = false;
texture_search_text = "";
texture_selected_name = "";
texture_selected_author = "";
texture_selected_display = "";
texture_search_results = ds_list_create();
texture_search_request = -1;
texture_search_active = false;
texture_dropdown_open = false;
texture_search_timer = 0;
texture_hover_index = -1;
user_upload_count = -1;
user_upload_limit = 0;
discord_linked = -1;
auto_texture_detected = false;
auto_texture_workshop_id = "";
auto_texture_name = "";
auto_texture_author = "";
auto_customs_detected = [];

// Detectar textura activa
var _tex = scr_detect_workshop_texture();

if (_tex.found && _tex.workshop_id != "")
{
    auto_texture_detected = true;
    auto_texture_workshop_id = _tex.workshop_id;
    auto_texture_name = _tex.name;
    auto_texture_author = _tex.author;
    // Pre-llenar los campos del selector de textura
    texture_enabled = true;
    texture_selected_name = _tex.name;
    texture_selected_author = _tex.author;
    texture_selected_display = _tex.name + " - " + _tex.author;
    texture_search_text = texture_selected_display;
    scr_debug_log("AUTO: Textura detectada → " + _tex.name + " (ID:" + _tex.workshop_id + ")");
}

// Detectar custom objects usados en el nivel
auto_customs_detected = scr_detect_workshop_customs(level_path);

if (array_length(auto_customs_detected) > 0)
    scr_debug_log("AUTO: " + string(array_length(auto_customs_detected)) + " customs detectados");

if (!variable_global_exists("user_badges_owned"))
    global.user_badges_owned = ds_list_create();
else
    ds_list_clear(global.user_badges_owned);

limit_request = scr_supabase_get_my_level_count();
badges_request = scr_load_my_badges();
discord_check_request = scr_check_discord_linked();
global.disable_editor_controls = 1;

get_tag_data = function(arg0)
{
    var _tag = string_lower(arg0);
    var _col = 7890020;
    
    switch (_tag)
    {
        case "kaizo":
            _col = 3947720;
            break;
        case "puzzle":
            _col = 13122700;
            break;
        case "tradicional":
            _col = 3973180;
            break;
        case "speedrun":
            _col = 14443580;
            break;
        case "corto":
            _col = 3978460;
            break;
        case "musica":
            _col = 11822300;
            break;
        case "troll":
            _col = 5263440;
            break;
        case "tematico":
            _col = 14985728;
            break;
    }
    
    return { color: _col };
};
campo_activo_prev = -1;
texture_search_active_prev = false;
