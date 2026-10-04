// cada pedido que sale de esta tarjeta vuelve por aca. todos preguntan por su propio id y
// ademas si la variable existe, porque la tarjeta puede haberse creado despues del pedido
var request_id = ds_map_find_value(async_load, "id");
var status = ds_map_find_value(async_load, "status");

// respuesta del bundle
if (variable_instance_exists(id, "bundle_request") && bundle_request != -1 && request_id == bundle_request)
{
    if (status == 1)
        exit;
    
    bundle_request = -1;
    var bundle_ok = false;
    
    if (status == 0)
    {
        try
        {
            var bundle_raw = ds_map_find_value(async_load, "result");
            if (is_undefined(bundle_raw))
                bundle_raw = "";
            var bundle_data = json_parse(bundle_raw);
            
            if (variable_struct_exists(bundle_data, "success") && bundle_data.success && variable_struct_exists(bundle_data, "level"))
            {
                var bundle_lvl = bundle_data.level;
                
                if (is_struct(bundle_lvl) && variable_struct_exists(bundle_lvl, "url") && string(bundle_lvl.url) != "")
                {
                    var bundle_tex = "sin textura";
                    if (variable_struct_exists(bundle_data, "texture") && is_struct(bundle_data.texture))
                        bundle_tex = string(bundle_data.texture.source);
                    var bundle_cust = 0;
                    if (variable_struct_exists(bundle_data, "customs") && is_array(bundle_data.customs))
                        bundle_cust = array_length(bundle_data.customs);
                    
                    scr_debug_log("BUNDLE OK: nivel=" + string(bundle_lvl.source) + " textura=" + bundle_tex + " customs=" + string(bundle_cust) + " (todo en una request)");
                    last_download_url = string(bundle_lvl.url);
                    last_download_source = "bundle";
                    level_download_id = http_get_file(last_download_url, temp_download_path);
                    bundle_ok = true;
                }
            }
        }
        catch (e)
        {
            scr_debug_log("BUNDLE PARSE ERROR: " + e.message);
        }
    }
    
    // si el bundle no sirvio se cae al bridge de siempre
    if (!bundle_ok)
    {
        scr_debug_log("BUNDLE fallo, cayendo al bridge comun...");
        request_download_url = scr_request_level_download_url(bundle_file_name, bundle_cold_id);
    }
    
    exit;
}

if (variable_instance_exists(id, "request_download_url") && request_download_url != -1 && request_id == request_download_url)
{
    scr_debug_log("=== BRIDGE DOWNLOAD RESPONSE ===");
    scr_debug_log("Status: " + string(status));
    
    if (status == 1)
        exit;
    
    request_download_url = -1;
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("BRIDGE RAW: " + string(result_str));
        
        try
        {
            var result_data = json_parse(result_str);
            
            if (variable_struct_exists(result_data, "success") && result_data.success)
            {
                var download_url = result_data.url;
                scr_debug_log("Download URL Worker: " + download_url);
                last_download_url = download_url;
                last_download_source = "";
                
                if (variable_struct_exists(result_data, "source"))
                    last_download_source = string(result_data.source);
                level_download_id = http_get_file(download_url, temp_download_path);
            }
            else
            {
                scr_debug_log("BRIDGE ERROR");
                show_message_extra("Error del servidor (Telegram Cold Storage).");
                level_downloading = false;
                download_state = 0;
            }
        }
        catch (e)
        {
            scr_debug_log("BRIDGE PARSE ERROR: " + e.message);
            show_message_extra("Error procesando la respuesta del servidor.");
            level_downloading = false;
            download_state = 0;
        }
    }
    else
    {
        scr_debug_log("BRIDGE CONNECTION ERROR: " + string(status));
        show_message_extra("Error de conexión al intentar recuperar el nivel.");
        level_downloading = false;
        download_state = 0;
    }
    
    exit;
}

// llego el nivel
// si r2 contesto 404 o 403 el archivo no esta ahi y se reintenta por el worker
// usando el cold_storage_id. si no hay cold id, el worker reintenta en IA (internet archive, ya me da paja escribirlo)
// ahi deberia estar siempre, y cuando la descarga sale bien se anota el hash y el tamaño en descargas.ini, eso es
// contra lo que se compara la proxima vez
if (variable_instance_exists(id, "level_download_id") && level_download_id != -1 && request_id == level_download_id)
{
    var http_status = ds_map_find_value(async_load, "http_status");
    scr_debug_log("DOWNLOAD RESPONSE: status=" + string(status) + " http=" + string(http_status) + " inst=" + string(id) + " dl_id=" + string(level_download_id));
    
    if (status == 1)
    {
        var content_length = ds_map_find_value(async_load, "contentLength");
        var size_downloaded = ds_map_find_value(async_load, "sizeDownloaded");
        
        if (!is_undefined(content_length) && !is_undefined(size_downloaded) && content_length > 0)
        {
            level_download_progress = floor((size_downloaded / content_length) * 100);
            download_state = 1;
        }
        
        exit;
    }
    
    level_download_id = -1;
    
    if (status == 0 && (is_undefined(http_status) || http_status == 200 || http_status == 206))
    {
        level_download_progress = 100;
        scr_debug_log("DOWNLOAD OK: Verificando archivo temporal...");
        
        if (variable_instance_exists(id, "temp_download_path") && file_exists(temp_download_path))
        {
            if (file_exists(play_level))
                file_delete(play_level);
            
            file_copy(temp_download_path, play_level);
            file_delete(temp_download_path);
            
            if (file_exists(play_level))
            {
                var file_hash = string_lower(md5_file(play_level));
                var buff = buffer_load(play_level);
                var file_size = buffer_get_size(buff);
                buffer_delete(buff);
                scr_debug_log("DESCARGA NIVEL OK. ID: " + string(downloading_level_id));
                
                if (file_hash != "" && file_size > 0)
                {
                    ini_open("descargas.ini");
                    
                    if (variable_instance_exists(id, "downloading_level_id"))
                    {
                        ini_write_string(string(downloading_level_id), "hash", file_hash);
                        ini_write_real(string(downloading_level_id), "size", file_size);
                    }
                    
                    ini_close();
                }
            }
            
            level_downloading = false;
            nivel_es_viejo = false;
            
            ini_open(play_level);
            
            if (ini_section_exists("options"))
                nivel_es_viejo = !ini_key_exists("options", "editor_version");
            
            ini_close();
            
            // si el nivel salio de catbox no quedo copia en r2, se devuelve para que quede
            if (last_download_source == "catbox")
            {
                scr_debug_log("CACHE FILL: devolviendo el nivel a r2...");
                cachefill_request = scr_r2_cache_fill(play_level, fallback_file_name, global.worker_telegram_url);
            }
            
            if (texture_name != "" && string_lower(texture_name) != "vanilla")
            {
                download_state = 2;
                texture_download_progress = 0;
                scr_level_file_start_texture_process();
            }
            else
            {
                texture_downloaded = true;
                texture_applied = true;
                scr_level_file_start_custom_process();
            }
        }
        else
        {
            scr_debug_log("ERROR: Archivo temporal no existe en: " + string(temp_download_path));
            show_message_extra("Error: El archivo temporal no se encuentra.");
            level_downloading = false;
            download_state = 0;
        }
    }
    else
    {
        scr_debug_log("DOWNLOAD FAIL: status=" + string(status) + " http_status=" + string(http_status));
        var is_fallback_needed = status < 0 || http_status == 404 || http_status == 403;
        
        if (is_fallback_needed)
        {
            scr_debug_log("R2 MISS / ERROR (Status: " + string(http_status) + "). Iniciando fallback a Worker...");
            
            if (file_exists(temp_download_path))
                file_delete(temp_download_path);
            
            var mi_cold_id = "";
            var mi_file_name = "";
            
            if (variable_instance_exists(id, "fallback_cold_storage_id"))
                mi_cold_id = fallback_cold_storage_id;
            
            if (variable_instance_exists(id, "fallback_file_name"))
                mi_file_name = fallback_file_name;
            
            if (bridge_tried)
            {
                if (!catbox_salteado && string_pos("files.catbox.moe", last_download_url) > 0)
                {
                    scr_debug_log("Catbox directo fallo, pidiendo bridge sin Catbox...");
                    catbox_salteado = true;
                    download_state = 1;
                    level_download_progress = 0;
                    request_download_url = scr_request_level_download_url(mi_file_name, mi_cold_id, true);
                }
                else
                {
                    scr_debug_log("DOWNLOAD FAIL FINAL: todos los respaldos fallaron.");
                    show_message_extra("Error: El nivel no se pudo descargar (todos los respaldos fallaron).");
                    level_downloading = false;
                    download_state = 0;
                }
            }
            else if (mi_cold_id != "" && mi_cold_id != "null")
            {
                bridge_tried = true;
                download_state = 1;
                level_download_progress = 0;
                // una jugada fria sale en una sola request: el worker resuelve
                // el nivel y de paso la textura y los customs que le falten a r2
                bundle_file_name = mi_file_name;
                bundle_cold_id = mi_cold_id;
                bundle_request = scr_bundle_request(mi_file_name, mi_cold_id);
            }
            else
            {
                show_message_extra("Error: El nivel no se pudo descargar (Sin Backup ID).");
                level_downloading = false;
                download_state = 0;
            }
        }
        else
        {
            show_message_extra("Error de descarga. Código: " + string(status));
            level_downloading = false;
            download_state = 0;
            
            if (file_exists(temp_download_path))
                file_delete(temp_download_path);
        }
    }
    
    exit;
}

// busca la textura en el listado para saber el nombre del archivo y su respaldo
if (variable_instance_exists(id, "texture_search_request") && texture_search_request != -1 && request_id == texture_search_request)
{
    if (status == 1)
        exit;
    
    texture_search_request = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        
        if (is_string(result) && result != "" && result != "[]" && result != "null")
        {
            texture_github_url = scr_clean_json_string(scr_json_get_value(result, "github_download_url"));
            texture_file_name = scr_clean_json_string(scr_json_get_value(result, "file_name"));
            texture_cold_id = scr_clean_json_string(scr_json_get_value(result, "cold_storage_id"));
            
            if (texture_cold_id == "null")
                texture_cold_id = "";
            
            if (texture_file_name != "" || (texture_github_url != "" && texture_github_url != "null"))
            {
                download_state = 2;
                texture_download_progress = 0;
                
                // la textura se prueba primero contra r2, si no esta recien ahi va al bridge
                texture_r2_directo = false;
                
                if (texture_file_name != "")
                {
                    texture_r2_directo = true;
                    texture_download_source = "";
                    
                    if (texture_download_path == "")
                        texture_download_path = (os_type == os_android ? game_save_id : working_directory) + "temp_tex_" + texture_file_name;
                    
                    scr_debug_log("TEXTURA R2 DIRECTO: " + global.r2_textures_url + "/" + texture_file_name);
                    texture_download_request = http_get_file(global.r2_textures_url + "/" + texture_file_name, texture_download_path);
                    exit;
                }
                
                scr_level_file_download_texture();
                exit;
            }
        }
    }
    
    texture_downloaded = true;
    texture_applied = true;
    scr_level_file_start_custom_process();
    exit;
}

// el bridge devuelve de donde bajar la textura, puede ser r2 o tg pasando por el proxy
if (variable_instance_exists(id, "request_texture_bridge_url") && request_texture_bridge_url != -1 && request_id == request_texture_bridge_url)
{
    if (status == 1)
        exit;
    
    request_texture_bridge_url = -1;
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        
        try
        {
            var result_data = json_parse(result_str);
            
            if (variable_struct_exists(result_data, "success") && result_data.success)
            {
                texture_download_source = "";
                
                if (variable_struct_exists(result_data, "source"))
                    texture_download_source = string(result_data.source);
                
                texture_download_request = http_get_file(result_data.url, texture_download_path);
            }
            else if (texture_github_url != "" && texture_github_url != "null")
            {
                var proxy_url = global.worker_textures_url + "/?url=" + texture_github_url;
                texture_download_request = http_get_file(proxy_url, texture_download_path);
            }
            else
            {
                texture_downloaded = true;
                texture_applied = true;
                scr_level_file_start_custom_process();
            }
        }
        catch (e)
        {
            texture_downloaded = true;
            texture_applied = true;
            scr_level_file_start_custom_process();
        }
    }
    else
    {
        texture_downloaded = true;
        texture_applied = true;
        scr_level_file_start_custom_process();
    }
    
    exit;
}

// llego el pack de texturas, se guarda y arranca el desempaquetado que sigue en el step
if (variable_instance_exists(id, "texture_download_request") && texture_download_request != -1 && request_id == texture_download_request)
{
    if (status == 1)
    {
        var content_length = ds_map_find_value(async_load, "contentLength");
        var size_downloaded = ds_map_find_value(async_load, "sizeDownloaded");
        
        if (!is_undefined(content_length) && !is_undefined(size_downloaded) && content_length > 0)
        {
            texture_download_progress = floor((size_downloaded / content_length) * 100);
            download_state = 2;
        }
        
        exit;
    }
    
    texture_download_request = -1;
    
    // el tiro directo a r2 fallo, se cae al bridge que la busca en el frio
    if (texture_r2_directo)
    {
        var _http_r2 = ds_map_find_value(async_load, "http_status");
        
        if (status != 0 || _http_r2 == 404 || _http_r2 == 403)
        {
            scr_debug_log("TEXTURA R2 MISS (http=" + string(_http_r2) + "), cayendo al bridge...");
            texture_r2_directo = false;
            
            if (file_exists(texture_download_path))
                file_delete(texture_download_path);
            
            download_state = 2;
            texture_download_progress = 0;
            scr_level_file_download_texture();
            exit;
        }
    }
    
    texture_r2_directo = false;
    
    if (status == 0)
    {
        texture_download_progress = 100;
        
        if (file_exists(texture_download_path))
        {
            var file_size = 0;
            var buf_check = buffer_load(texture_download_path);
            
            if (buf_check != -1)
            {
                file_size = buffer_get_size(buf_check);
                buffer_delete(buf_check);
            }
            
            if (file_size < 100)
            {
                file_delete(texture_download_path);
                texture_downloaded = true;
                texture_applied = true;
                scr_level_file_start_custom_process();
                exit;
            }
            
            // si salio de catbox no quedo en r2, se devuelve una copia
            if (texture_download_source == "catbox")
            {
                scr_debug_log("CACHE FILL: devolviendo la textura a r2...");
                cachefill_request = scr_r2_cache_fill(texture_download_path, texture_file_name, global.worker_textures_bridge_url);
            }
            
            var target_dir = texture_install_path + "/";
            
            if (!directory_exists(target_dir))
                directory_create(target_dir);
            
            download_state = 3;
            install_progress = 0;
            unpack_buffer = buffer_load(texture_download_path);
            
            if (unpack_buffer == -1)
            {
                file_delete(texture_download_path);
                texture_downloaded = true;
                texture_applied = true;
                scr_level_file_start_custom_process();
                exit;
            }
            
            unpack_count = buffer_read(unpack_buffer, buffer_u32);
            unpack_index = 0;
            unpack_target_dir = target_dir;
            unpack_source_file = texture_download_path;
            unpacking_textures = true;
        }
        else
        {
            texture_downloaded = true;
            texture_applied = true;
            scr_level_file_start_custom_process();
        }
    }
    else
    {
        texture_downloaded = true;
        texture_applied = true;
        download_state = 0;
        scr_level_file_start_custom_process();
    }
    
    exit;
}

// borrar nivel (se saca de una, si es admin se borra del db, sino no pasa nada)
if (variable_instance_exists(id, "delete_request_id") && delete_request_id != -1 && request_id == delete_request_id)
{
    delete_request_id = -1;
    var _http = ds_map_find_value(async_load, "http_status");
    var _res = ds_map_find_value(async_load, "result");
    scr_debug_log("DELETE NIVEL: http=" + string(_http) + " result=" + string(_res));
    
    if (_http == 200 && string(_res) == "true")
    {
        // si eliminamos un nivel, recargamos y regeneramos el cache
        global.browser_forzar_fresco = current_time + 90000;
        if (variable_global_exists("preload_data_ready"))
            global.preload_data_ready = false;
        if (variable_global_exists("preloaded_data") && ds_exists(global.preloaded_data, ds_type_list))
            ds_list_clear(global.preloaded_data);
        if (variable_global_exists("browser_return_valid"))
            global.browser_return_valid = false;
        
        level_download_id = -1;
        level_downloading = false;
        thumbnail_download_id = -1;
        imagen_cargando = false;
        download_state = 0;
        
        if (instance_exists(obj_level_loader))
        {
            obj_level_loader.pending_room_restart = true;
            obj_level_loader.restart_delay = 3;
        }
        
        show_message_extra("¡Nivel eliminado!");
        instance_destroy();
    }
    else
    {
        show_message_extra("No se pudo borrar el nivel: " + string(_res));
    }
    exit;
}

// el reporte y la restauracion se miran por http_status y no por el body
var _id_async = ds_map_find_value(async_load, "id");
var _status_http = ds_map_find_value(async_load, "http_status");

if (_id_async == request_report)
{
    if (_status_http == 201 || _status_http == 204 || _status_http == 200)
    {
        scr_debug_log("Reporte enviado correctamente.");
    }
    else
    {
        scr_debug_log("Error al enviar reporte. Status: " + string(_status_http));
        var id_l = ds_list_find_value(global.id_levels, my_list_index);
        var idx = ds_list_find_index(global.reported_levels_session, id_l);
        
        if (idx != -1)
            ds_list_delete(global.reported_levels_session, idx);
        
        show_message_async("Hubo un error al enviar tu reporte.");
    }
    
    request_report = -1;
}

if (_id_async == request_restore)
{
    if (_status_http == 200 || _status_http == 204)
    {
        scr_debug_log("Nivel restaurado correctamente.");
    }
    else
    {
        scr_debug_log("Error al restaurar nivel. Status: " + string(_status_http));
        show_message_async("Error al restaurar el nivel.");
    }
    
    request_restore = -1;
}

// customs
// primero se pregunta por cada objeto para saber su archivo, despues se pide la url
// y al final se baja. la cola avanza de a uno
if (variable_instance_exists(id, "custom_search_request") && custom_search_request != -1 && request_id == custom_search_request)
{
    if (status == 1)
        exit;
    
    custom_search_request = -1;
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("CUSTOMS SEARCH RAW: " + string(result_str));
        
        try
        {
            var _parsed = json_parse(result_str);
            var _item_data = undefined;
            
            if (is_array(_parsed) && array_length(_parsed) > 0)
                _item_data = _parsed[0];
            else if (is_struct(_parsed))
                _item_data = _parsed;
            
            if (!is_undefined(_item_data))
            {
                var _file_name = variable_struct_exists(_item_data, "file_name") ? string(_item_data.file_name) : "";
                var _cold_id = variable_struct_exists(_item_data, "cold_storage_id") ? string(_item_data.cold_storage_id) : "";
                
                if (_cold_id == "null")
                    _cold_id = "";
                
                if (custom_download_index < array_length(custom_download_queue))
                {
                    custom_download_queue[custom_download_index].file_name = _file_name;
                    custom_download_queue[custom_download_index].cold_storage_id = _cold_id;
                    scr_debug_log("CUSTOMS: Encontrado file='" + _file_name + "' cold_id='" + _cold_id + "'");
                    
                    if (_file_name != "" || _cold_id != "")
                    {
                        scr_level_file_download_custom_file();
                        exit;
                    }
                }
            }
        }
        catch (e)
        {
            scr_debug_log("CUSTOMS SEARCH ERROR: " + e.message);
        }
    }
    
    scr_debug_log("CUSTOMS: No se pudo obtener info, saltando al siguiente");
    custom_download_index++;
    scr_level_file_search_next_custom();
    exit;
}

if (variable_instance_exists(id, "custom_bridge_request") && custom_bridge_request != -1 && request_id == custom_bridge_request)
{
    if (status == 1)
        exit;
    
    custom_bridge_request = -1;
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("CUSTOMS BRIDGE RAW: " + string(result_str));
        
        try
        {
            var result_data = json_parse(result_str);
            
            if (variable_struct_exists(result_data, "success") && result_data.success)
            {
                scr_debug_log("CUSTOMS: URL obtenida, descargando...");
                custom_download_source = "";
                
                if (variable_struct_exists(result_data, "source"))
                    custom_download_source = string(result_data.source);
                
                custom_download_request = http_get_file(result_data.url, custom_temp_download_path);
                exit;
            }
        }
        catch (e)
        {
            scr_debug_log("CUSTOMS BRIDGE PARSE ERROR: " + e.message);
        }
    }
    
    scr_debug_log("CUSTOMS: Bridge falló, saltando");
    custom_download_index++;
    scr_level_file_search_next_custom();
    exit;
}

// llego un custom, se descomprime y se sigue con el que viene. cuando se termina la cola
// arranca el nivel
if (variable_instance_exists(id, "custom_download_request") && custom_download_request != -1 && request_id == custom_download_request)
{
    if (status == 1)
    {
        var content_length = ds_map_find_value(async_load, "contentLength");
        var size_downloaded = ds_map_find_value(async_load, "sizeDownloaded");
        
        if (!is_undefined(content_length) && !is_undefined(size_downloaded) && content_length > 0)
        {
            custom_download_progress = floor((size_downloaded / content_length) * 100);
            download_state = 5;
        }
        
        exit;
    }
    
    custom_download_request = -1;
    var http_status = ds_map_find_value(async_load, "http_status");
    
    if (status == 0 && (is_undefined(http_status) || http_status == 200 || http_status == 206))
    {
        custom_download_progress = 100;
        custom_r2_directo = false;
        
        if (file_exists(custom_temp_download_path))
        {
            scr_debug_log("CUSTOMS: Archivo descargado, instalando...");
            var buf_check = buffer_load(custom_temp_download_path);
            
            if (buf_check != -1)
            {
                var file_size = buffer_get_size(buf_check);
                buffer_delete(buf_check);
                
                if (file_size < 100)
                {
                    scr_debug_log("CUSTOMS: Archivo muy pequeño (" + string(file_size) + "b), saltando");
                    file_delete(custom_temp_download_path);
                    custom_download_index++;
                    scr_level_file_search_next_custom();
                    exit;
                }
            }
            
            var _item = custom_download_queue[custom_download_index];
            
            // si bajo de catbox no quedo en r2, se devuelve una copia
            if (custom_download_source == "catbox")
            {
                scr_debug_log("CACHE FILL: devolviendo el custom a r2...");
                cachefill_request = scr_r2_cache_fill(custom_temp_download_path, _item.file_name, global.worker_textures_bridge_url);
            }
            var _custom_dir = (os_type == os_android ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (working_directory + "custom/"));
            var _folder = "";
            if (variable_struct_exists(_item, "folder"))
                _folder = _item.folder;
            if (_folder == "")
            {
                var _orig = scr_simplepack_peek_file(custom_temp_download_path, "__folder__.txt");
                if (_orig != "")
                    _folder = scr_sanitize_filename(_orig) + "_id" + string(_item.workshop_id);
            }
            if (_folder == "")
                _folder = _item.name;
            _item.folder = _folder;
            var _dest = _custom_dir + _folder + "/";
            
            if (!directory_exists(_custom_dir))
                directory_create(_custom_dir);
            
            if (!directory_exists(_dest))
                directory_create(_dest);
            
            download_state = 6;
            custom_install_progress = 0;
            custom_unpack_buffer = buffer_load(custom_temp_download_path);
            
            if (custom_unpack_buffer == -1)
            {
                scr_debug_log("CUSTOMS: Error cargando buffer");
                file_delete(custom_temp_download_path);
                custom_download_index++;
                scr_level_file_search_next_custom();
                exit;
            }
            
            custom_unpack_count = buffer_read(custom_unpack_buffer, buffer_u32);
            custom_unpack_index = 0;
            custom_unpack_target_dir = _dest;
            custom_unpack_source_file = custom_temp_download_path;
            custom_unpacking = true;
            scr_debug_log("CUSTOMS: Simplepack con " + string(custom_unpack_count) + " archivos");
        }
        else
        {
            scr_debug_log("CUSTOMS: Archivo temporal no encontrado");
            custom_download_index++;
            scr_level_file_search_next_custom();
        }
    }
    else
    {
        scr_debug_log("CUSTOMS: Error descarga (status=" + string(status) + " http=" + string(http_status) + ")");
        
        if (file_exists(custom_temp_download_path))
            file_delete(custom_temp_download_path);
        
        // el tiro directo a r2 no lo encontro, una pasada por el bridge antes de saltar
        if (custom_r2_directo)
        {
            scr_debug_log("CUSTOM R2 MISS (http=" + string(http_status) + "), cayendo al bridge...");
            custom_r2_directo = false;
            var _item_r2 = custom_download_queue[custom_download_index];
            custom_bridge_request = scr_request_texture_download_url(_item_r2.file_name, _item_r2.cold_storage_id);
            exit;
        }
        
        custom_download_index++;
        scr_level_file_search_next_custom();
    }
    
    exit;
}


// la respuesta del relleno se anota nomas, para ver si el worker lo tomo o lo reboto
if (variable_instance_exists(id, "cachefill_request") && cachefill_request != -1 && request_id == cachefill_request)
{
    if (status == 1)
        exit;
    
    cachefill_request = -1;
    var _cf_http = ds_map_find_value(async_load, "http_status");
    var _cf_res = ds_map_find_value(async_load, "result");
    
    if (is_undefined(_cf_res))
        _cf_res = "";
    
    scr_debug_log("CACHE FILL RESPUESTA: http=" + string(_cf_http) + " body=" + string(_cf_res));
    exit;
}
