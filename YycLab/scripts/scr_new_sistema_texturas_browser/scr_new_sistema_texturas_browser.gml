function scr_upload_texture_to_telegram(arg0, arg1, arg2, arg3, arg4)
{
    scr_debug_log("=== TEXTURE TELEGRAM UPLOAD START ===");
    scr_debug_log("file_path: " + string(arg0));
    scr_debug_log("file_name: " + string(arg1));
    scr_debug_log("texture_name: " + string(arg2));
    
    if (!file_exists(arg0))
    {
        scr_debug_log("ERROR: El archivo no existe!");
        return -1;
    }
    
    var _buffer = buffer_load(arg0);
    var _size = buffer_get_size(_buffer);
    scr_debug_log("file_size: " + string(_size) + " bytes");
    
    if (_size > 52428800)
    {
        buffer_delete(_buffer);
        scr_debug_log("ERROR: Archivo muy grande (max 50MB)");
        return -2;
    }
    
    var _base64 = buffer_base64_encode(_buffer, 0, _size);
    buffer_delete(_buffer);
    var _url = global.worker_textures_bridge_url;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", arg1);
    ds_map_add(_headers, "X-Texture-Name", arg2);
    ds_map_add(_headers, "X-Author-Name", arg3);
    ds_map_add(_headers, "X-Author-Id", arg4);
    ds_map_add(_headers, "X-Action", "upload");
    
    if (variable_global_exists("user_token") && global.user_token != "")
        ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    
    var _request = http_request(_url, "POST", _headers, _base64);
    ds_map_destroy(_headers);
    scr_debug_log("request ID: " + string(_request));
    scr_debug_log("=== TEXTURE UPLOAD REQUEST SENT ===");
    return _request;
}

function scr_request_texture_download_url(arg0, arg1)
{
    scr_debug_log("=== TEXTURE DOWNLOAD REQUEST ===");
    scr_debug_log("file_name: " + string(arg0));
    scr_debug_log("cold_storage_id: " + string(arg1));
    var _url = global.worker_textures_bridge_url;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "X-Action", "download");
    var _body = json_stringify(
    {
        file_name: string(arg0),
        cold_storage_id: string(arg1)
    });
    scr_debug_log("Body: " + _body);
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    scr_debug_log("request ID: " + string(_request));
    return _request;
}

function scr_collect_files_recursive(arg0, arg1)
{
    var _file = file_find_first(arg0 + "*", 0);
    
    while (_file != "")
    {
        var _full_path = arg0 + _file;
        if (!directory_exists(_full_path))
        {
            ds_list_add(arg1, _full_path);
        }
        _file = file_find_next();
    }
    
    file_find_close();
    var _dir = file_find_first(arg0 + "*", 16);
    var _dir_list = ds_list_create();
    
    while (_dir != "")
    {
        if (_dir != "." && _dir != "..")
        {
            var _full_dir_path = arg0 + _dir;
            if (directory_exists(_full_dir_path))
                ds_list_add(_dir_list, _dir);
        }
        
        _dir = file_find_next();
    }
    
    file_find_close();
    
    for (var i = 0; i < ds_list_size(_dir_list); i++)
    {
        var _sub_dir = ds_list_find_value(_dir_list, i);
        var _sub_path = arg0 + _sub_dir + "/";
        scr_collect_files_recursive(_sub_path, arg1);
    }
    
    ds_list_destroy(_dir_list);
}
