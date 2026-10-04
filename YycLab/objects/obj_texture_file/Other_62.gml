if (thumb_request == -1 && like_request == -1 && download_request == -1 && toggle_featured_request == -1 && featured_request == -1 && delete_request == -1 && request_bridge_download == -1)
    exit;

var _request_id = ds_map_find_value(async_load, "id");

if (_request_id != thumb_request && _request_id != like_request && _request_id != download_request && _request_id != toggle_featured_request && _request_id != featured_request && _request_id != delete_request && _request_id != request_bridge_download)
    exit;

var _status = ds_map_find_value(async_load, "status");
var _http_status = ds_map_find_value(async_load, "http_status");

if (_request_id == request_bridge_download)
{
    scr_debug_log("=== TEXTURE BRIDGE RESPONSE ===");
    scr_debug_log("Status: " + string(_status));
    
    if (_status == 1)
        exit;
    
    request_bridge_download = -1;
    
    if (_status == 0)
    {
        var _result_str = ds_map_find_value(async_load, "result");
        scr_debug_log("BRIDGE RAW: " + string(_result_str));
        
        try
        {
            var _result_data = json_parse(_result_str);
            
            if (variable_struct_exists(_result_data, "debug"))
            {
                var _debug_arr = _result_data.debug;
                
                if (is_array(_debug_arr))
                {
                    for (var _d = 0; _d < array_length(_debug_arr); _d++)
                        scr_debug_log("  BRIDGE: " + string(_debug_arr[_d]));
                }
            }
            
            if (variable_struct_exists(_result_data, "success") && _result_data.success)
            {
                var _download_url = _result_data.url;
                var _source = variable_struct_exists(_result_data, "source") ? _result_data.source : "unknown";
                scr_debug_log("Download URL: " + _download_url);
                scr_debug_log("Source: " + _source);
                download_request = http_get_file(_download_url, download_save_path);
                scr_debug_log("File download started: " + string(download_request));
            }
            else
            {
                var _error = variable_struct_exists(_result_data, "error") ? string(_result_data.error) : "Error desconocido";
                scr_debug_log("BRIDGE ERROR: " + _error);
                var _t_github_url = "";
                
                if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_github_urls))
                        _t_github_url = ds_list_find_value(global.texture_github_urls, my_index);
                }
                
                if (_t_github_url != "" && _t_github_url != "null")
                {
                    scr_debug_log("Fallback a GitHub proxy...");
                    var _proxy_url = global.worker_textures_url + "/?url=" + _t_github_url;
                    download_request = http_get_file(_proxy_url, download_save_path);
                }
                else
                {
                    download_status = "error";
                    download_error = _error;
                    downloading = 0;
                }
            }
        }
        catch (e)
        {
            scr_debug_log("BRIDGE PARSE ERROR: " + e.message);
            var _t_github_url = "";
            
            if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
            {
                if (my_index < ds_list_size(global.texture_github_urls))
                    _t_github_url = ds_list_find_value(global.texture_github_urls, my_index);
            }
            
            if (_t_github_url != "" && _t_github_url != "null")
            {
                scr_debug_log("Fallback a GitHub proxy...");
                var _proxy_url = global.worker_textures_url + "/?url=" + _t_github_url;
                download_request = http_get_file(_proxy_url, download_save_path);
            }
            else
            {
                download_status = "error";
                download_error = "Error de respuesta";
                downloading = 0;
            }
        }
    }
    else
    {
        scr_debug_log("BRIDGE CONNECTION ERROR: " + string(_status));
        var _t_github_url = "";
        
        if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
        {
            if (my_index < ds_list_size(global.texture_github_urls))
                _t_github_url = ds_list_find_value(global.texture_github_urls, my_index);
        }
        
        if (_t_github_url != "" && _t_github_url != "null")
        {
            scr_debug_log("Fallback a GitHub proxy...");
            var _proxy_url = global.worker_textures_url + "/?url=" + _t_github_url;
            download_request = http_get_file(_proxy_url, download_save_path);
        }
        else
        {
            download_status = "error";
            download_error = "Sin conexión";
            downloading = 0;
        }
    }
    
    exit;
}

if (_request_id == thumb_request)
{
    if (_status == 1)
        exit;
    
    thumb_request = -1;
    thumb_loading = 0;
    
    if (_status == 0)
    {
        var _t_id = ds_list_find_value(global.texture_ids, my_index);
        var _cache_name = "texture_thumb_" + string(_t_id) + ".png";
        
        if (file_exists(_cache_name))
        {
            thumb_sprite = sprite_add(_cache_name, 1, false, false, 0, 0);
            
            if (thumb_sprite != -1)
            {
                thumb_loaded = 1;
            }
            else
            {
                file_delete(_cache_name);
                
                if (thumb_retry_count < thumb_max_retries)
                    thumb_retry_timer = 30;
                else
                    thumb_failed = 1;
            }
        }
        else if (thumb_retry_count < thumb_max_retries)
        {
            thumb_retry_timer = 30;
        }
        else
        {
            thumb_failed = 1;
        }
    }
    else if (thumb_retry_count < thumb_max_retries)
    {
        thumb_retry_timer = 45;
    }
    else
    {
        thumb_failed = 1;
    }
    
    exit;
}

if (_request_id == like_request)
{
    if (_status == 1)
        exit;
    
    like_request = -1;
    global.likes_operation_pending = 0;
    var _is_success = 0;
    
    if (_status == 0 || _http_status == 204)
    {
        if (_http_status == 200 || _http_status == 201 || _http_status == 204)
            _is_success = 1;
        
        var _result = ds_map_find_value(async_load, "result");
        
        if (is_string(_result) && string_pos("\"error\"", _result) > 0)
            _is_success = 0;
    }
    
    if (!_is_success)
    {
        scr_debug_log("TEXTURE LIKE: Failed, reverting...");
        var _t_id = ds_list_find_value(global.texture_ids, my_index);
        var _t_id_str = string(floor(real(_t_id)));
        var _current_likes = real(ds_list_find_value(global.texture_likes, my_index));
        
        if (is_liked)
        {
            for (var i = 0; i < ds_list_size(global.my_texture_likes); i++)
            {
                if (string(floor(real(ds_list_find_value(global.my_texture_likes, i)))) == _t_id_str)
                {
                    ds_list_delete(global.my_texture_likes, i);
                    break;
                }
            }
            
            ds_list_replace(global.texture_likes, my_index, string(max(0, _current_likes - 1)));
            is_liked = 0;
        }
        else
        {
            ds_list_add(global.my_texture_likes, _t_id_str);
            ds_list_replace(global.texture_likes, my_index, string(_current_likes + 1));
            is_liked = 1;
        }
    }
    
    exit;
}

if (_request_id == download_request)
{
    if (_status == 1)
    {
        var _content_length = ds_map_find_value(async_load, "contentLength");
        var _size_downloaded = ds_map_find_value(async_load, "sizeDownloaded");
        
        if (!is_undefined(_content_length) && !is_undefined(_size_downloaded))
        {
            if (_content_length > 0 && _size_downloaded > 0)
                download_progress = floor((_size_downloaded / _content_length) * 100);
        }
        
        exit;
    }
    
    download_request = -1;
    download_end_time = current_time;
    download_time_ms = download_end_time - download_start_time;
    
    if (_status == 0)
    {
        if (file_exists(download_save_path))
        {
            var _f = file_bin_open(download_save_path, 0);
            var _file_size = file_bin_size(_f);
            var _byte1 = file_bin_read_byte(_f);
            var _byte2 = file_bin_read_byte(_f);
            file_bin_close(_f);
            var _is_zip = _byte1 == 80 && _byte2 == 75;
            
            if (_file_size < 100)
            {
                download_status = "error";
                download_error = "Archivo corrupto (" + string(_file_size) + " bytes)";
                file_delete(download_save_path);
                scr_debug_log("ERROR: Archivo muy pequeño: " + string(_file_size) + " bytes");
                exit;
            }
            
            if (_file_size < 500000)
            {
                var _check_buf = buffer_load(download_save_path);
                var _first_bytes = buffer_peek(_check_buf, 0, buffer_string);
                buffer_delete(_check_buf);
                
                if (string_pos("<!DOCTYPE", _first_bytes) > 0 || string_pos("<html", _first_bytes) > 0)
                {
                    download_status = "error";
                    download_error = "Servidor devolvió error 404";
                    file_delete(download_save_path);
                    scr_debug_log("ERROR: Archivo descargado es HTML (404)");
                    exit;
                }
            }
            
            scr_debug_log("Textura descargada OK: " + string(_file_size) + " bytes en " + string(download_time_ms) + "ms");
            scr_debug_log("Source: " + download_source);
            var _t_name_safe = filename_change_ext(filename_name(download_save_path), "");
            var _target_dir = filename_dir(download_save_path) + "/" + _t_name_safe + "/";
            
            var _pk_item_type = "";
            if (variable_global_exists("texture_item_types") && ds_exists(global.texture_item_types, ds_type_list) && my_index < ds_list_size(global.texture_item_types))
                _pk_item_type = string(ds_list_find_value(global.texture_item_types, my_index));
            
            if (string_pos("custom", _pk_item_type) > 0)
            {
                var _pk_orig = scr_simplepack_peek_file(download_save_path, "__folder__.txt");
                
                if (_pk_orig != "")
                {
                    var _pk_id = "";
                    if (variable_global_exists("texture_ids") && ds_exists(global.texture_ids, ds_type_list) && my_index < ds_list_size(global.texture_ids))
                        _pk_id = string(ds_list_find_value(global.texture_ids, my_index));
                    
                    _t_name_safe = scr_sanitize_filename(_pk_orig);
                    
                    if (_pk_id != "")
                        _t_name_safe += "_id" + _pk_id;
                    
                    _target_dir = filename_dir(download_save_path) + "/" + _t_name_safe + "/";
                    scr_debug_log("CUSTOM: carpeta desde pack: " + _t_name_safe);
                }
            }
            
            if (_is_zip)
            {
                if (!directory_exists(_target_dir))
                    directory_create(_target_dir);
                
                var _files_unzipped = zip_unzip(download_save_path, _target_dir);
                
                if (_files_unzipped > 0)
                {
                    if (file_exists(download_save_path))
                        file_delete(download_save_path);
                    
                    download_status = "installed";
                    is_installed = 1;
                    downloading = 0;
                    download_progress = 100;
                    check_install_done = 1;
                    installed_path = _target_dir;
					scr_write_workshop_id_after_download(_target_dir, my_index);
                    scr_debug_log("ZIP instalado: " + string(_files_unzipped) + " archivos en " + _target_dir);
                }
                else
                {
                    download_status = "error";
                    download_error = "Error al descomprimir ZIP";
                    
                    if (file_exists(download_save_path))
                        file_delete(download_save_path);
                }
            }
            else
            {
                unpack_buffer = buffer_load(download_save_path);
                
                if (buffer_get_size(unpack_buffer) < 4)
                {
                    download_status = "error";
                    download_error = "Formato desconocido";
                    buffer_delete(unpack_buffer);
                    exit;
                }
                
                unpack_count = buffer_read(unpack_buffer, buffer_u32);
                
                if (unpack_count > 10000)
                {
                    download_status = "error";
                    download_error = "Header invalido";
                    buffer_delete(unpack_buffer);
                    exit;
                }
                
                unpack_index = 0;
                unpack_base_dir = _target_dir;
                
                if (!directory_exists(unpack_base_dir))
                    directory_create(unpack_base_dir);
                
                download_status = "unpacking";
                download_progress = 0;
                scr_debug_log("STARTING UNPACK: " + string(unpack_count) + " files");
            }
        }
        else
        {
            download_status = "error";
            download_error = "Archivo no guardado";
        }
    }
    else
    {
        download_status = "error";
        
        if (_http_status == 0)
            download_error = "Sin conexión";
        else
            download_error = "Error HTTP " + string(_http_status);
    }
    
    exit;
}

if (_request_id == toggle_featured_request)
{
    if (_status == 1)
        exit;
    
    toggle_featured_request = -1;
    var _result = ds_map_find_value(async_load, "result");
    var _is_success = 0;
    
    if (_status == 0 && (_http_status == 200 || _http_status == 201))
    {
        if (is_string(_result) && _result != "")
        {
            var _success_val = scr_json_get_value(_result, "success");
            _success_val = scr_clean_json_string(_success_val);
            
            if (_success_val == "true")
            {
                _is_success = 1;
                var _action_val = scr_json_get_value(_result, "action");
                _action_val = scr_clean_json_string(_action_val);
                
                if (_action_val == "added")
                    is_featured = 1;
                else if (_action_val == "removed")
                    is_featured = 0;
            }
        }
    }
    
    if (!_is_success)
        is_featured = !is_featured;
    
    exit;
}

if (_request_id == featured_request)
{
    if (_status == 1)
        exit;
    
    featured_request = -1;
    var _result = ds_map_find_value(async_load, "result");
    
    if (_status == 0 && (_http_status == 200 || _http_status == 201))
    {
        if (is_string(_result) && string_pos("[", _result) > 0 && string_length(_result) > 2)
            is_featured = 1;
        else
            is_featured = 0;
    }
    
    exit;
}

if (_request_id == delete_request)
{
    if (_status == 1)
        exit;
    
    delete_request = -1;
    
    if (_status == 0)
    {
        var _result = ds_map_find_value(async_load, "result");
        var _success_val = scr_json_get_value(_result, "success");
        _success_val = scr_clean_json_string(_success_val);
        
        if (_success_val == "true")
        {
            if (my_index >= 0 && my_index < ds_list_size(global.texture_ids))
            {
                ds_list_delete(global.texture_ids, my_index);
                ds_list_delete(global.texture_names, my_index);
                ds_list_delete(global.texture_authors, my_index);
                ds_list_delete(global.texture_author_ids, my_index);
                ds_list_delete(global.texture_descs, my_index);
                ds_list_delete(global.texture_files, my_index);
                ds_list_delete(global.texture_thumbs, my_index);
                ds_list_delete(global.texture_likes, my_index);
                ds_list_delete(global.texture_downloads, my_index);
                ds_list_delete(global.texture_dates, my_index);
                
                if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_github_urls))
                        ds_list_delete(global.texture_github_urls, my_index);
                }
                
                if (variable_global_exists("texture_cold_storage_ids") && ds_exists(global.texture_cold_storage_ids, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_cold_storage_ids))
                        ds_list_delete(global.texture_cold_storage_ids, my_index);
                }
                
                if (variable_global_exists("texture_tags") && ds_exists(global.texture_tags, ds_type_list))
                {
                    if (my_index < ds_list_size(global.texture_tags))
                    {
                        var _sub = ds_list_find_value(global.texture_tags, my_index);
                        
                        if (ds_exists(_sub, ds_type_list))
                            ds_list_destroy(_sub);
                        
                        ds_list_delete(global.texture_tags, my_index);
                    }
                }
                
                with (obj_texture_file)
                {
                    if (my_index > other.my_index)
                        my_index -= 1;
                }
            }
            
            if (sprite_exists(thumb_sprite))
                sprite_delete(thumb_sprite);
            
            instance_destroy();
        }
        else
        {
            var _error_msg = scr_json_get_value(_result, "error");
            _error_msg = scr_clean_json_string(_error_msg);
            show_message_async("Error: " + _error_msg);
        }
    }
    else
    {
        show_message_async("Error de conexión al eliminar");
    }
    
    exit;
}
