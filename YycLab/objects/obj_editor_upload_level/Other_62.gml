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
        scr_debug_log("Registering in DB with cold_storage_id: " + cold_storage_id);
        request_upload_db = scr_supabase_upload_level(
            level_name, level_description, r2_file_name, r2_thumb_name,
            db_tags_array, db_texture_value, cold_storage_id,
            db_tex_ws_id, db_customs_json
        );
    }
    exit;
}

// --- Texture search ---
if (request_id == texture_search_request)
{
    texture_search_request = -1;
    
    if (status == 0)
    {
        try
        {
            var _result_str = ds_map_find_value(async_load, "result");
            var _data = json_parse(_result_str);
            
            for (var i = 0; i < ds_list_size(texture_search_results); i++)
            {
                var _old_map = ds_list_find_value(texture_search_results, i);
                if (ds_exists(_old_map, ds_type_map))
                    ds_map_destroy(_old_map);
            }
            ds_list_clear(texture_search_results);
            
            if (is_array(_data))
            {
                for (var i = 0; i < array_length(_data); i++)
                {
                    var _item = _data[i];
                    var _new_map = ds_map_create();
                    ds_map_add(_new_map, "id", variable_struct_exists(_item, "id") ? _item.id : 0);
                    ds_map_add(_new_map, "name", variable_struct_exists(_item, "name") ? _item.name : "");
                    ds_map_add(_new_map, "author_name", variable_struct_exists(_item, "author_name") ? _item.author_name : "");
                    ds_list_add(texture_search_results, _new_map);
                }
            }
            texture_hover_index = -1;
        }
        catch (e)
        {
            scr_debug_log("Error parsing texture search: " + e.message);
        }
    }
    exit;
}

// --- Discord check ---
if (request_id == discord_check_request)
{
    discord_check_request = -1;
    var peticion_exitosa = false;
    
    if (status == 0)
    {
        var http_status = ds_map_find_value(async_load, "http_status");
        
        if (http_status == 200)
        {
            try
            {
                var result_str = ds_map_find_value(async_load, "result");
                var data = json_parse(result_str);
                
                if (is_array(data))
                {
                    if (array_length(data) > 0)
                    {
                        data = data[0];
                        
                        if (variable_struct_exists(data, "discord_id") && data.discord_id != pointer_null && data.discord_id != "")
                        {
                            discord_linked = 1;
                            peticion_exitosa = true;
                        }
                        else
                        {
                            discord_linked = 0;
                            peticion_exitosa = true;
                        }
                    }
                    else
                    {
                        discord_linked = 0;
                        peticion_exitosa = true;
                    }
                }
            }
            catch (e)
            {
                scr_debug_log("Discord check parse error: " + e.message);
            }
        }
        else
        {
            scr_debug_log("Discord check HTTP status: " + string(http_status));
        }
    }
    
    if (!peticion_exitosa)
    {
        if (discord_check_retries > 0)
        {
            discord_check_retries--;
            discord_check_timer = 60;
            discord_linked = -1;
            scr_debug_log("Reintentando Discord Check... Quedan: " + string(discord_check_retries));
        }
        else
        {
            discord_linked = 0;
            scr_debug_log("Discord check falló definitivamente.");
        }
    }
    exit;
}

// --- Limit request ---
if (request_id == limit_request)
{
    limit_request = -1;
    
    if (status == 0)
    {
        try
        {
            var result_str = ds_map_find_value(async_load, "result");
            var list = json_parse(result_str);
            user_upload_count = is_array(list) ? array_length(list) : 0;
            var current_lvl = variable_global_exists("user_level") ? global.user_level : 1;
            user_upload_limit = scr_calculate_upload_limit(current_lvl);
        }
        catch (e)
        {
            user_upload_count = -1;
        }
    }
    else
    {
        user_upload_count = -1;
    }
    exit;
}

// --- Badges request ---
if (request_id == badges_request)
{
    badges_request = -1;
    
    if (status == 0)
    {
        try
        {
            var result_str = ds_map_find_value(async_load, "result");
            var data = json_parse(result_str);
            
            if (!variable_global_exists("user_badges_owned"))
                global.user_badges_owned = ds_list_create();
            else
                ds_list_clear(global.user_badges_owned);
            
            if (is_array(data))
            {
                for (var i = 0; i < array_length(data); i++)
                {
                    var b = data[i];
                    if (variable_struct_exists(b, "badge_id"))
                        ds_list_add(global.user_badges_owned, b.badge_id);
                }
            }
            
            var current_lvl = variable_global_exists("user_level") ? global.user_level : 1;
            user_upload_limit = scr_calculate_upload_limit(current_lvl);
        }
        catch (e) {}
    }
    exit;
}

// --- Upload level ---
if (request_id == request_upload_level)
{
    request_upload_level = -1;
    scr_debug_log("=== EDITOR UPLOAD LEVEL RESPONSE ===");
    scr_debug_log("Status: " + string(status));
    scr_debug_log("HTTP Status: " + string(ds_map_find_value(async_load, "http_status")));
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("UPLOAD RAW RESPONSE: " + string(result_str));
        
        try
        {
            var result_data = json_parse(result_str);
            
            if (variable_struct_exists(result_data, "debug"))
            {
                var debug_arr = result_data.debug;
                if (is_array(debug_arr))
                {
                    scr_debug_log("--- WORKER DEBUG LOG ---");
                    for (var d = 0; d < array_length(debug_arr); d++)
                        scr_debug_log("  WORKER: " + string(debug_arr[d]));
                    scr_debug_log("--- END WORKER DEBUG ---");
                }
            }
            
            if (variable_struct_exists(result_data, "success") && result_data.success)
            {
                if (variable_struct_exists(result_data, "cold_storage_id"))
                    cold_storage_id = result_data.cold_storage_id;
                else
                    cold_storage_id = "";
                
                scr_debug_log("UPLOAD OK! cold_storage_id: " + cold_storage_id);
                upload_step = 2;
                // si la miniatura viajo en la misma request, saltamos directo a la db
                if (variable_struct_exists(result_data, "thumbName") && !is_undefined(result_data.thumbName) && result_data.thumbName != "")
                {
                    scr_debug_log("THUMB OK (mismo pack): " + string(result_data.thumbName));
                    scr_upload_continuar_db_nivel_editor(id);
                }
                else
                {
                    mensaje = "Subiendo imagen...";
                    request_upload_thumb = scr_upload_file_to_r2(thumbnail_path, r2_thumb_name, "thumbnails");
                }
            }
            else
            {
                loading = 0;
                estado = 4;
                var error_detail = "";
                
                if (variable_struct_exists(result_data, "telegram_description"))
                    error_detail = string(result_data.telegram_description);
                if (variable_struct_exists(result_data, "error") && error_detail == "")
                    error_detail = string(result_data.error);
                if (error_detail == "")
                    error_detail = "Error desconocido";
                
                scr_debug_log("UPLOAD ERROR: " + error_detail);
                mensaje = "Error: " + error_detail;
                mensaje_color = 255;
            }
        }
        catch (e)
        {
            scr_debug_log("UPLOAD JSON PARSE ERROR: " + e.message);
            
            if (ds_map_find_value(async_load, "http_status") == 200 || string_pos("success", result_str) > 0)
            {
                cold_storage_id = "";
                upload_step = 2;
                mensaje = "Subiendo imagen...";
                request_upload_thumb = scr_upload_file_to_r2(thumbnail_path, r2_thumb_name, "thumbnails");
            }
            else
            {
                loading = 0;
                estado = 4;
                mensaje = "Error al subir archivo .lvl";
                mensaje_color = 255;
            }
        }
    }
    else
    {
        scr_debug_log("UPLOAD CONNECTION ERROR");
        loading = 0;
        estado = 4;
        mensaje = "Error de conexión (Nivel).";
        mensaje_color = 255;
    }
    exit;
}

// --- Upload thumbnail ---
if (request_id == request_upload_thumb)
{
    request_upload_thumb = -1;
    scr_debug_log("=== EDITOR UPLOAD THUMB RESPONSE ===");
    scr_debug_log("Status: " + string(status));
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("THUMB RAW: " + string(result_str));
        
        if (ds_map_find_value(async_load, "http_status") == 200 || string_pos("success", result_str) > 0)
        {
            scr_upload_continuar_db_nivel_editor(id);
        }
        else
        {
            loading = 0;
            estado = 4;
            mensaje = "Error al subir imagen.";
            mensaje_color = 255;
        }
    }
    else
    {
        loading = 0;
        estado = 4;
        mensaje = "Error de conexión (Imagen).";
        mensaje_color = 255;
    }
    exit;
}

// --- Upload DB ---
if (request_id == request_upload_db)
{
    request_upload_db = -1;
    loading = 0;
    scr_debug_log("=== EDITOR UPLOAD DB RESPONSE ===");
    scr_debug_log("Status: " + string(status));
    
    if (status == 0)
    {
        var result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("DB RAW: " + string(result_str));
        
        try
        {
            var data = json_parse(result_str);
            var es_error = false;
            var error_msg = "Error desconocido";
            
            if (is_struct(data))
            {
                if (variable_struct_exists(data, "error") || variable_struct_exists(data, "code"))
                {
                    es_error = true;
                    if (variable_struct_exists(data, "message"))
                        error_msg = data.message;
                    else if (variable_struct_exists(data, "msg"))
                        error_msg = data.msg;
                    else
                        error_msg = string(result_str);
                }
            }
            
            if (es_error)
            {
                estado = 4;
                mensaje = "DB Error: " + error_msg;
                mensaje_color = 255;
                scr_debug_log("DB ERROR: " + error_msg);
            }
            else
            {
                estado = 3;
                mensaje = "¡Nivel subido exitosamente!";
                mensaje_color = 65280;
                scr_debug_log("UPLOAD COMPLETE SUCCESS!");
                
                if (user_upload_count != -1)
                    user_upload_count += 1;
            }
        }
        catch (e)
        {
            estado = 4;
            mensaje = "Respuesta inválida del servidor.";
            mensaje_color = 255;
            scr_debug_log("DB JSON ERROR: " + e.message);
        }
    }
    else
    {
        estado = 4;
        mensaje = "Error de conexión DB.";
        mensaje_color = 255;
    }
    exit;
}
