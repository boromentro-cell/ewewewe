// descarga del nivel texturas y customs

if (my_list_index == -1)
    exit;

if (!variable_global_exists("id_levels"))
    exit;

if (!ds_exists(global.id_levels, ds_type_list))
    exit;

// chequear listas
if (my_list_index >= ds_list_size(global.id_levels))
    exit;

// ya hay una descarga en curso, un segundo click no tiene que hacer nada
if (download_state > 0 && download_state < 4)
{
    scr_debug_log("PLAY BLOQUEADO: descarga en curso (state=" + string(download_state) + ")");
    exit;
}
if (level_downloading)
{
    scr_debug_log("PLAY BLOQUEADO: level_downloading=true");
    exit;
}
if (unpacking_textures)
{
    scr_debug_log("PLAY BLOQUEADO: unpacking_textures=true");
    exit;
}
if (custom_unpacking)
{
    scr_debug_log("PLAY BLOQUEADO: custom_unpacking=true");
    exit;
}

// los datos se leen recien ahora de las listas globales, la tarjeta no los tenia guardados
var my_id = ds_list_find_value(global.id_levels, my_list_index);
var my_name = ds_list_find_value(global.name_levels, my_list_index);
var my_author = ds_list_find_value(global.autor_levels, my_list_index);
var file_url = ds_list_find_value(global.file_urls, my_list_index);

if (is_undefined(my_id) || string(my_id) == "")
    exit;

if (is_undefined(file_url) || string(file_url) == "")
{
    scr_debug_log("PLAY ERROR: file_url vacío para index " + string(my_list_index));
    exit;
}

scr_debug_log("=== PLAY NIVEL ONLINE ===");
scr_debug_log("ID: " + string(my_id));
scr_debug_log("Nombre: " + string(my_name));
scr_debug_log("Autor: " + string(my_author));
scr_debug_log("URL: " + string(file_url));

if (instance_exists(obj_level_loader))
{
    global.browser_return_valid = true;
    global.browser_return_room = room;
    global.browser_return_scroll = obj_level_loader.scroll_y;
    global.browser_return_loaded = obj_level_loader.total_levels_loaded;
    global.browser_return_view = obj_level_loader.view_mode;
    global.browser_return_sort = global.sort;
    global.browser_return_name_s = global.name_s;
    global.browser_return_autor_s = global.autor_s;
    global.browser_return_level_id = my_id;
    // reset x las dudas, se guarda de nuevo cuando el nivel aplica su textura
    global.tex_skin_prev_level = "";
}
// reset x las dudas
download_state = 0;
level_download_progress = 0;
texture_download_progress = 0;
install_progress = 0;
texture_name = "";

// Reset custom state
custom_download_queue = [];
custom_download_index = 0;
custom_total_to_download = 0;
custom_download_progress = 0;
custom_install_progress = 0;
custom_search_request = -1;
custom_bridge_request = -1;
custom_download_request = -1;
custom_unpacking = false;
custom_r2_directo = false;
custom_download_source = "";

// que textura pide el nivel? si dice vanilla no hay nada que hacer nada porque no usa textura
if (variable_global_exists("texture_used_levels") && ds_exists(global.texture_used_levels, ds_type_list))
{
    if (my_list_index < ds_list_size(global.texture_used_levels))
    {
        var tex_val = ds_list_find_value(global.texture_used_levels, my_list_index);
        
        if (!is_undefined(tex_val) && tex_val != "" && tex_val != "null" && string_lower(tex_val) != "vanilla")
        {
            texture_name = tex_val;
            scr_debug_log("Textura del nivel: " + texture_name);
        }
    }
}

customs_used = "";
// leemos eljson de los customs
if (variable_global_exists("custom_objects_used_levels") && ds_exists(global.custom_objects_used_levels, ds_type_list))
{
    if (my_list_index < ds_list_size(global.custom_objects_used_levels))
    {
        var cust_val = ds_list_find_value(global.custom_objects_used_levels, my_list_index);
        if (!is_undefined(cust_val) && cust_val != "" && cust_val != "null" && cust_val != "[]")
            customs_used = string(cust_val);
    }
}
scr_debug_log("Customs del nivel: '" + customs_used + "'");

// directorio
var level_root;

if (scr_isWindows())
{
    level_root = working_directory + "/Niveles";
    
    if (!directory_exists(level_root))
        directory_create(level_root);
}
else
{
    level_root = getDire2("SM4J", "Niveles");
}

var safe_name = string(my_name);
safe_name = string_replace_all(safe_name, ":", "-");
safe_name = string_replace_all(safe_name, "/", "-");
safe_name = string_replace_all(safe_name, "\\", "-");
safe_name = string_replace_all(safe_name, "*", "");
safe_name = string_replace_all(safe_name, "?", "");
safe_name = string_replace_all(safe_name, "<", "");
safe_name = string_replace_all(safe_name, ">", "");
safe_name = string_replace_all(safe_name, "|", "");
safe_name = string_replace_all(safe_name, "\"", "");
var file_lev = level_root + "/" + safe_name + " - ID " + string(my_id) + ".lvl";
var need_download = true;

// el nivel ya esta descargado
// se compara el hash y el tamaño contra lo que quedo anotado en descargas.ini. si no coincide
// el archivo se toco por fuera del juego y se baja de nuevo desde cero
if (file_exists(file_lev))
{
    ini_open(file_lev);
    var valid_ini = ini_section_exists("options");
    ini_close();
    
    if (!valid_ini)
    {
        scr_debug_log("SEGURIDAD: Archivo corrupto o inválido (INI).");
        file_delete(file_lev);
    }
    else
    {
        var current_hash = string_lower(md5_file(file_lev));
        var buff = buffer_load(file_lev);
        var current_size = buffer_get_size(buff);
        buffer_delete(buff);
        ini_open("descargas.ini");
        var stored_hash = string_lower(ini_read_string(string(my_id), "hash", ""));
        var stored_size = ini_read_real(string(my_id), "size", -1);
        ini_close();
        scr_debug_log("--- VERIFICACIÓN DE SEGURIDAD ID: " + string(my_id) + " ---");
        scr_debug_log("Hash Local: " + string(current_hash) + " | Hash Guardado: " + string(stored_hash));
        scr_debug_log("Size Local: " + string(current_size) + " | Size Guardado: " + string(stored_size));
        
        if (stored_hash != "" && stored_hash == current_hash && stored_size != -1 && stored_size == current_size)
        {
            need_download = false;
        }
        else
        {
            scr_debug_log("!!! CHEAT DETECTADO O ARCHIVO MODIFICADO !!!");
            show_message_extra("Archivo modificado detectado. Se descargará nuevamente.");
            file_delete(file_lev);
            need_download = true;
        }
    }
}

scr_debug_log("need_download: " + string(need_download));

// desde aca ya se sabe que nivel se va a jugar, se avisa a las globals que lee el resto
play_level = file_lev;
global.current_play_level = my_name;
global.current_play_autor = my_author;
global.current_play_id = my_id;
global.online_level_id = my_id;

// el cargador se elige por el formato del nivel: los viejos no traen editor_version en options
nivel_es_viejo = false;

if (file_exists(play_level))
{
    ini_open(play_level);
    nivel_es_viejo = !ini_key_exists("options", "editor_version");
    ini_close();
}

texture_downloaded = false;
texture_applied = false;
texture_applying = false;
texture_transition_triggered = false;
texture_download_progress = 0;
texture_github_url = "";
texture_needs_download = false;
texture_r2_directo = false;
texture_download_source = "";

// el archivo ya estaba y esta sano, se salta la descarga y se sigue con la textura
if (!need_download)
{
    scr_debug_log("Archivo de nivel válido, verificando textura...");
    
    if (texture_name != "" && string_lower(texture_name) != "vanilla")
    {
        download_state = 2;
        texture_downloaded = false;
        scr_level_file_start_texture_process();
    }
    else
    {
        texture_downloaded = true;
        texture_applied = true;
        scr_level_file_start_custom_process();
    }
}
// no estaba o estaba mal, se pide a r2. si r2 no lo tiene, llamaamos al worker bridge que lo saca de tg o internet archive
else
{
    if (level_downloading)
        exit;
    
    scr_debug_log("Iniciando descarga del nivel...");
    level_type = 99;
    level_downloading = true;
    download_state = 1;
    level_download_progress = 0;
    var my_cold_id = "";
    
    if (variable_global_exists("cold_storage_ids") && ds_exists(global.cold_storage_ids, ds_type_list))
    {
        if (my_list_index < ds_list_size(global.cold_storage_ids))
        {
            my_cold_id = ds_list_find_value(global.cold_storage_ids, my_list_index);
            
            if (is_undefined(my_cold_id) || my_cold_id == "null")
                my_cold_id = "";
        }
    }
    
    var my_file_name = string(file_url);
    var slash_pos = string_last_pos("/", my_file_name);
    
    if (slash_pos > 0)
        my_file_name = string_copy(my_file_name, slash_pos + 1, string_length(my_file_name) - slash_pos);
    
    var temp_path = working_directory + "temp_download_" + string(my_id) + ".lvl";
    temp_download_path = temp_path;
    downloading_level_id = my_id;
    fallback_cold_storage_id = my_cold_id;
    fallback_file_name = my_file_name;
    scr_debug_log("Intentando descarga directa de R2...");
    scr_debug_log("URL completa: " + string(file_url));
    scr_debug_log("Temp path: " + temp_path);
    bridge_tried = false;
    last_download_url = "";
    last_download_source = "";
    catbox_salteado = false;
    request_download_url = -1;
    bundle_request = -1;
    level_download_id = http_get_file(file_url, temp_path);
    scr_debug_log("level_download_id asignado: " + string(level_download_id));
    if (!(variable_global_exists("party_preflight") && global.party_preflight))
        scr_supabase_increment_download(my_id);
    ini_open("descargas.ini");
    ini_write_string(string(my_id), "name", string(my_name));
    ini_write_string(string(my_id), "author", string(my_author));
    var date_val = ds_list_find_value(global.date_levels, my_list_index);
    
    if (!is_undefined(date_val))
        ini_write_string(string(my_id), "date", string(date_val));
    
    ini_close();
}
