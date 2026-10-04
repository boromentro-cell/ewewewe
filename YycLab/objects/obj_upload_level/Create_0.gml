if (!variable_global_exists("user_logged_in"))
    global.user_logged_in = 0;

if (!global.user_logged_in)
{
    show_message_async("Debes iniciar sesión para subir niveles");
    room_goto_previous();
    exit;
}

discord_check_timer = -1;
discord_check_retries = 3;
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
estado = 0;
level_path = "";
level_name = "";
level_description = "";
thumbnail_path = "";
has_thumbnail = 0;
r2_file_name = "";
r2_thumb_name = "";
campo_activo = 0;
cold_storage_id = "";
niveles_locales = ds_list_create();
niveles_scroll = 0;
nivel_seleccionado = -1;
request_upload_level = -1;
request_upload_thumb = -1;
request_upload_db = -1;
request_catbox = -1;
catbox_file_id = "";
esperando_catbox_db = false;
db_tags_array = -1;
db_texture_value = "";
limit_request = -1;
badges_request = -1;
discord_check_request = -1;
upload_step = 0;
loading = 0;
mensaje = "";
mensaje_timer = 0;
mensaje_color = 16777215;
color_fondo = 3936030;
color_campo = 5905970;
color_campo_activo = 7877190;
color_boton = 55295;
color_boton_hover = 16777215;
color_tarjeta = 6563900;
color_tarjeta_sel = 9848420;
campo_w = 400;
campo_h = 40;
centro_x = room_width / 2;
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
var path_niveles = working_directory + "Niveles/";

if (directory_exists(path_niveles))
{
    var file_found = file_find_first(path_niveles + "*.lvl", 0);
    
    while (file_found != "")
    {
        ds_list_add(niveles_locales, path_niveles + file_found);
        file_found = file_find_next();
    }
    
    file_find_close();
}

if (ds_list_size(niveles_locales) == 0)
{
    mensaje = "No hay niveles locales para subir";
    mensaje_color = 65535;
}

instance_deactivate_object(obj_aventura);
instance_deactivate_object(obj_carlosXDjav);
instance_deactivate_object(obj_otrosmodos);
instance_deactivate_object(obj_opciones);
instance_deactivate_object(obj_Hellomario_version);
instance_deactivate_object(obj_bganimator);
instance_deactivate_object(obj_cursor_menu);
instance_deactivate_object(obj_cursor_menu_manager);
instance_deactivate_object(obj_text_in_screen_Custom);
instance_deactivate_object(obj_text_Special);
instance_deactivate_object(obj_menu_eventos);
user_upload_count = -1;
user_upload_limit = 0;
discord_linked = -1;
discord_check_request = -1;
discord_check_retries = 3;
discord_check_timer = -1;

if (global.user_logged_in)
    discord_check_request = scr_check_discord_linked();

if (!variable_global_exists("user_badges_owned"))
    global.user_badges_owned = ds_list_create();
else
    ds_list_clear(global.user_badges_owned);

limit_request = scr_supabase_get_my_level_count();
badges_request = scr_load_my_badges();

if (global.user_logged_in)
    discord_check_request = scr_check_discord_linked();

get_tag_data = function(arg0)
{
    var _tag = string_lower(arg0);
    var _col = 7890020;
    var _spr = spr_mushroom;
    
    switch (_tag)
    {
        case "dificil":
        case "hard":
        case "kaizo":
            _col = 3947720;
            break;
        
        case "puzzle":
        case "enigma":
            _col = 13122700;
            break;
        
        case "tradicional":
        case "standard":
            _col = 3973180;
            break;
        
        case "speedrun":
        case "speed":
            _col = 14443580;
            break;
        
        case "corto":
        case "short":
            _col = 3978460;
            break;
        
        case "musica":
        case "music":
        case "muscal":
            _col = 11822300;
            break;
        
        case "troll":
            _col = 5263440;
            break;
        
        case "aventura":
        case "tematico":
            _col = 14985728;
            break;
    }
    
    return 
    {
        color: _col,
        sprite: _spr
    };
};
campo_activo_prev = -1;
texture_search_active_prev = false;
android_picking = false;
android_file_list = -1;
android_scroll = 0;
