var request_id = ds_map_find_value(async_load, "id");
var status = ds_map_find_value(async_load, "status");

if (request_id == request_catbox)
{
    request_catbox = -1;

    if (status == 0)
    {
        var _cb_result = ds_map_find_value(async_load, "result");
        catbox_file_id = scr_catbox_get_id(_cb_result);

        if (catbox_file_id != "")
            scr_debug_log("CATBOX OK -> " + catbox_file_id);
        else
            scr_debug_log("CATBOX FALLO (no fatal): " + string(_cb_result));
    }
    else
    {
        scr_debug_log("CATBOX error de red (no fatal)");
    }

    if (esperando_catbox_db)
    {
        esperando_catbox_db = false;
        cold_storage_id = scr_coldid_add_cb(cold_storage_id, catbox_file_id);
        request_create_db = scr_supabase_create_texture(texture_name, texture_description, r2_file_name, r2_thumb_name, tags_seleccionados, cold_storage_id, item_type);
    }
    exit;
}

if (request_id == request_upload_texture)
{
    request_upload_texture = -1;
    scr_debug_log("=== TEXTURE UPLOAD RESPONSE ===");
    scr_debug_log("Status: " + string(status));
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("RAW: " + string(result_str));
        
        try
        {
            var result_data = json_parse(result_str);
            
            if (variable_struct_exists(result_data, "success") && result_data.success)
            {
                cold_storage_id = variable_struct_exists(result_data, "cold_storage_id") ? result_data.cold_storage_id : "";
                scr_debug_log("cold_storage_id: " + cold_storage_id);
                upload_step = 2;
                // si la miniatura viajo en la misma request, saltamos directo a la db
                if (variable_struct_exists(result_data, "thumbName") && !is_undefined(result_data.thumbName) && result_data.thumbName != "")
                {
                    scr_debug_log("THUMB OK (mismo pack): " + string(result_data.thumbName));
                    scr_upload_continuar_db_textura(id);
                }
                else
                {
                    mensaje = "Subiendo miniatura...";
                    request_upload_thumb = scr_upload_file_to_r2(texture_image_path, r2_thumb_name, "thumbnails");
                }
            }
            else
            {
                loading = false;
                estado = 5;
                var err = variable_struct_exists(result_data, "error") ? result_data.error : "Error desconocido";
                mensaje = "Error: " + string(err);
                mensaje_color = 255;
            }
        }
        catch (e)
        {
            loading = false;
            estado = 5;
            mensaje = "Error al procesar respuesta";
            mensaje_color = 255;
        }
    }
    else
    {
        loading = false;
        estado = 5;
        mensaje = "Error de conexión";
        mensaje_color = 255;
    }
    
    exit;
}

if (request_id == request_upload_thumb)
{
    request_upload_thumb = -1;
    scr_debug_log("=== THUMB UPLOAD RESPONSE ===");
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        
        if (ds_map_find_value(async_load, "http_status") == 200 || string_pos("success", result_str) > 0)
        {
            scr_upload_continuar_db_textura(id);
        }
        else
        {
            loading = false;
            estado = 5;
            mensaje = "Error al subir miniatura";
            mensaje_color = 255;
        }
    }
    else
    {
        loading = false;
        estado = 5;
        mensaje = "Error de conexión (miniatura)";
        mensaje_color = 255;
    }
    
    exit;
}

if (request_id == request_create_db)
{
    request_create_db = -1;
    loading = false;
    scr_debug_log("=== DB RESPONSE ===");
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("DB RAW: " + string(result_str));
        
        try
        {
            var data = json_parse(result_str);
            var es_error = false;
            
            if (is_struct(data) && (variable_struct_exists(data, "error") || variable_struct_exists(data, "code")))
                es_error = true;
            
            if (is_array(data) && array_length(data) > 0)
            {
                var _first = data[0];
                if (is_struct(_first) && (variable_struct_exists(_first, "error") || variable_struct_exists(_first, "code")))
                    es_error = true;
            }
            
            if (es_error)
            {
                estado = 5;
                mensaje = "Error en base de datos";
                mensaje_color = 255;
            }
            else
            {
                estado = 4;
                mensaje = "¡Subida exitosa!";
                mensaje_color = 65280;
                
                if (file_exists(simplepack_path))
                    file_delete(simplepack_path);
                

                //  Escribir workshop_id.ini
                var _db_id = "";
                
                // Extraer el ID del registro creado
                if (is_array(data) && array_length(data) > 0)
                {
                    var _record = data[0];
                    if (variable_struct_exists(_record, "id"))
                        _db_id = string(_record.id);
                }
                else if (is_struct(data) && variable_struct_exists(data, "id"))
                {
                    _db_id = string(data.id);
                }
                
                if (_db_id != "" && texture_folder_path != "")
                {
                    var _ini_path = texture_folder_path;
                    
                    if (string_char_at(_ini_path, string_length(_ini_path)) != "/"
                        && string_char_at(_ini_path, string_length(_ini_path)) != "\\")
                        _ini_path += "/";
                    
                    _ini_path += "workshop_id.ini";
                    
                    ini_open(_ini_path);
                    ini_write_string("workshop", "id", _db_id);
                    ini_write_string("workshop", "name", texture_name);
                    ini_write_string("workshop", "author", global.user_name);
                    ini_write_string("workshop", "item_type", item_type);
                    ini_close();
                    
                    scr_debug_log("workshop_id.ini escrito en: " + _ini_path + " (ID: " + _db_id + ")");
                }
                else
                {
                    scr_debug_log("No se pudo escribir workshop_id.ini: db_id='" + _db_id + "' folder='" + texture_folder_path + "'");
                }
                // ========================================
            }
        }
        catch (e)
        {
            estado = 5;
            mensaje = "Respuesta inválida del servidor";
            mensaje_color = 255;
        }
    }
    else
    {
        estado = 5;
        mensaje = "Error de conexión (DB)";
        mensaje_color = 255;
    }
    
    exit;
}
