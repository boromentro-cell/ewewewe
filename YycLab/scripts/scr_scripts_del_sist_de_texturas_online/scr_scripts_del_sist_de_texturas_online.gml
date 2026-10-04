function scr_supabase_textures_init()
{
    global.worker_textures_url = "https://sm4j-textures.boromentro.workers.dev";
    global.worker_textures_upload_url = "https://sm4j-textures-upload.boromentro.workers.dev";
    global.texture_ids = ds_list_create();
    global.texture_names = ds_list_create();
    global.texture_authors = ds_list_create();
    global.texture_author_ids = ds_list_create();
    global.texture_descs = ds_list_create();
    global.texture_files = ds_list_create();
    global.texture_thumbs = ds_list_create();
    global.texture_likes = ds_list_create();
    global.texture_downloads = ds_list_create();
    global.texture_dates = ds_list_create();
    global.texture_tags = ds_list_create();
    global.my_texture_likes = ds_list_create();
    global.texture_item_types = ds_list_create();
    global.texture_github_urls = ds_list_create();
    global.worker_textures_bridge_url = "https://sm4j-textures-bridge.boromentro.workers.dev/";
    global.texture_cold_storage_ids = ds_list_create();
    return 1;
}

function scr_supabase_get_textures(arg0, arg1, arg2, arg3, arg4 = false)
{
    // el catalogo estatico en r2: las listas sin busqueda salen del cdn y no
    // gastan supabase. arg4 fuerza supabase (lo usa el fallback cuando falla)
    var _catalog_key = "";
    
    if (!arg4 && arg3 == "" && arg0 < 3)
    {
        switch (arg2)
        {
            case "newest":
            case "recent":
                _catalog_key = "recent";
                break;
            
            case "likes":
                _catalog_key = "likes";
                break;
            
            case "downloads":
                _catalog_key = "downloads";
                break;
        }
    }
    
    if (_catalog_key != "")
    {
        var _headers_cat = ds_map_create();
        var _request_cat = http_request(global.r2_textures_url + "/catalog/" + _catalog_key + "_p" + string(arg0) + ".json", "GET", _headers_cat, "");
        ds_map_destroy(_headers_cat);
        textures_es_catalogo = true;
        scr_debug_log("GET TEXTURES: page=" + string(arg0) + " sort=" + arg2 + " (catalogo cdn)");
        return _request_cat;
    }
    
    textures_es_catalogo = false;
    var _url = global.supabase_url + "/rest/v1/rpc/get_textures_list";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{";
    _body += ("\"p_limit\":" + string(arg1) + ",");
    _body += ("\"p_offset\":" + string(arg0 * arg1) + ",");
    _body += ("\"p_sort\":\"" + string(arg2) + "\",");
    _body += "\"p_search\":";
    
    if (arg3 != "")
        _body += ("\"" + string(arg3) + "\"");
    else
        _body += "null";
    
    _body += "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    scr_debug_log("GET TEXTURES: page=" + string(arg0) + " sort=" + arg2);
    return _request;
}

function scr_supabase_search_textures(arg0, arg1, arg2, arg3, arg4)
{
    var _url = global.supabase_url + "/rest/v1/rpc/search_textures_advanced";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{";
    _body += ("\"p_limit\":" + string(arg1) + ",");
    _body += ("\"p_offset\":" + string(arg0 * arg1) + ",");
    
    if (arg2 != "")
        _body += ("\"p_name\":\"" + arg2 + "\",");
    else
        _body += "\"p_name\":null,";
    
    if (arg3 != "")
        _body += ("\"p_author\":\"" + arg3 + "\",");
    else
        _body += "\"p_author\":null,";
    
    if (ds_exists(arg4, ds_type_list) && ds_list_size(arg4) > 0)
    {
        _body += "\"p_tags\":[";
        
        for (var i = 0; i < ds_list_size(arg4); i++)
        {
            if (i > 0)
                _body += ",";
            
            var _tag = ds_list_find_value(arg4, i);
            _body += ("\"" + string(_tag) + "\"");
        }
        
        _body += "]";
    }
    else
    {
        _body += "\"p_tags\":null";
    }
    
    _body += "}";
    scr_debug_log("TEXTURE SEARCH: " + _body);
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_supabase_create_texture(arg0, arg1, arg2, arg3, arg4, arg5, arg6)
{
    if (!global.user_logged_in)
        return -1;
    
    arg1 = string_replace_all(arg1, "\"", "\\\"");
    arg1 = string_replace_all(arg1, "'", "");
    var _tags_json = "[";
    
    for (var i = 0; i < ds_list_size(arg4); i++)
    {
        if (i > 0)
            _tags_json += ",";
        
        _tags_json += ("\"" + ds_list_find_value(arg4, i) + "\"");
    }
    
    _tags_json += "]";
    var _url = global.supabase_url + "/rest/v1/textures";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "Prefer", "return=representation");
    var _body = "{";
    _body += ("\"name\":\"" + string(arg0) + "\",");
    _body += ("\"description\":\"" + string(arg1) + "\",");
    _body += ("\"author_id\":\"" + global.user_id + "\",");
    _body += ("\"author_name\":\"" + global.user_name + "\",");
    _body += ("\"file_name\":\"" + string(arg2) + "\",");
    _body += ("\"thumbnail_name\":\"" + string(arg3) + "\",");
    _body += ("\"cold_storage_id\":\"" + string(arg5) + "\",");
    _body += ("\"item_type\":\"" + string(arg6) + "\",");
    _body += ("\"tags\":" + _tags_json);
    _body += "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_texture_add_like(arg0)
{
    if (!global.user_logged_in)
    {
        scr_debug_log("TEXTURE LIKE: No logueado");
        return -1;
    }
    
    var _url = global.supabase_url + "/rest/v1/texture_likes";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "Prefer", "return=representation");
    var _body = "{\"texture_id\":" + string(arg0) + ",\"user_id\":\"" + global.user_id + "\"}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    scr_debug_log("TEXTURE LIKE: Adding like to texture " + string(arg0));
    return _request;
}

function scr_texture_remove_like(arg0)
{
    if (!global.user_logged_in)
    {
        scr_debug_log("TEXTURE UNLIKE: No logueado");
        return -1;
    }
    
    var _url = global.supabase_url + "/rest/v1/texture_likes?texture_id=eq." + string(arg0) + "&user_id=eq." + global.user_id;
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "DELETE", _headers, "");
    ds_map_destroy(_headers);
    scr_debug_log("TEXTURE UNLIKE: Removing like from texture " + string(arg0));
    return _request;
}

function scr_get_my_texture_likes()
{
    if (!global.user_logged_in)
        return -1;
    
    var _url = global.supabase_url + "/rest/v1/texture_likes?user_id=eq." + global.user_id + "&select=texture_id";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}

function scr_increment_texture_download(arg0)
{
    var _url = global.supabase_url + "/rest/v1/rpc/increment_texture_downloads";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{\"texture_id_param\":" + string(arg0) + "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_get_texture_tag_visuals(arg0)
{
    arg0 = string_upper(arg0);
    var _spr = 2561;
    var _col = 7890020;
    
    switch (arg0)
    {
        case "SMB1":
            _col = 5281510;
            break;
        
        case "SMB2":
            _col = 5263580;
            break;
        
        case "SMB3":
            _col = 15119440;
            break;
        
        case "SMW":
            _col = 6604900;
            break;
        
        case "NSMB":
            _col = 3328255;
            break;
        
        case "SMM":
            _col = 9851110;
            break;
        
        case "WONDER":
            _col = 13138175;
            break;
        
        case "HD":
            _col = 16737430;
            break;
    }
    
    var _result = array_create(2);
    _result[0] = _col;
    _result[1] = _spr;
    return _result;
}

function scr_json_parse_textures(arg0)
{
    var _result_list = ds_list_create();
    
    if (string_char_at(arg0, 1) == "[")
        arg0 = string_copy(arg0, 2, string_length(arg0) - 2);
    
    if (string_length(arg0) < 3)
        return _result_list;
    
    var _depth = 0;
    var _current_start = 1;
    var _i = 1;
    var _len = string_length(arg0);
    
    while (_i <= _len)
    {
        var _c = string_char_at(arg0, _i);
        
        if (_c == "{")
        {
            if (_depth == 0)
                _current_start = _i;
            
            _depth += 1;
        }
        else if (_c == "}")
        {
            _depth -= 1;
            
            if (_depth == 0)
            {
                var _obj_str = string_copy(arg0, _current_start, (_i - _current_start) + 1);
                var _obj_map = ds_map_create();
                ds_map_add(_obj_map, "id", scr_json_get_value(_obj_str, "id"));
                ds_map_add(_obj_map, "name", scr_json_get_value(_obj_str, "name"));
                ds_map_add(_obj_map, "description", scr_json_get_value(_obj_str, "description"));
                ds_map_add(_obj_map, "author_id", scr_json_get_value(_obj_str, "author_id"));
                ds_map_add(_obj_map, "author_name", scr_json_get_value(_obj_str, "author_name"));
                ds_map_add(_obj_map, "file_name", scr_json_get_value(_obj_str, "file_name"));
                ds_map_add(_obj_map, "thumbnail_name", scr_json_get_value(_obj_str, "thumbnail_name"));
                ds_map_add(_obj_map, "likes", scr_json_get_value(_obj_str, "likes"));
                ds_map_add(_obj_map, "downloads", scr_json_get_value(_obj_str, "downloads"));
                ds_map_add(_obj_map, "item_type", scr_json_get_value(_obj_str, "item_type"));
                ds_map_add(_obj_map, "created_at", scr_json_get_value(_obj_str, "created_at"));
                ds_map_add(_obj_map, "github_download_url", scr_json_get_value(_obj_str, "github_download_url"));
                ds_map_add(_obj_map, "tags", scr_json_get_array_value(_obj_str, "tags"));
                ds_map_add(_obj_map, "cold_storage_id", scr_json_get_value(_obj_str, "cold_storage_id"));
                ds_list_add(_result_list, _obj_map);
            }
        }
        
        _i += 1;
    }
    
    return _result_list;
}

function scr_texture_loader_start_loading()
{
    with (obj_texture_loader)
    {
        ds_list_clear(global.texture_ids);
        ds_list_clear(global.texture_names);
        ds_list_clear(global.texture_authors);
        
        if (variable_global_exists("texture_cold_storage_ids") && ds_exists(global.texture_cold_storage_ids, ds_type_list))
            ds_list_clear(global.texture_cold_storage_ids);
        
        ds_list_clear(global.texture_author_ids);
        ds_list_clear(global.texture_descs);
        
        if (variable_global_exists("texture_item_types"))
            ds_list_clear(global.texture_item_types);
        
        ds_list_clear(global.texture_files);
        ds_list_clear(global.texture_thumbs);
        ds_list_clear(global.texture_likes);
        ds_list_clear(global.texture_downloads);
        ds_list_clear(global.texture_dates);
        ds_list_clear(global.my_texture_likes);
        
        if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
            ds_list_clear(global.texture_github_urls);
        
        for (var i = 0; i < ds_list_size(global.texture_tags); i++)
        {
            var _sub = ds_list_find_value(global.texture_tags, i);
            
            if (ds_exists(_sub, ds_type_list))
                ds_list_destroy(_sub);
        }
        
        ds_list_clear(global.texture_tags);
        textures_loaded = 0;
        textures_retry_count = 0;
        textures_retry_timer = -1;
        likes_loaded = 0;
        likes_retry_count = 0;
        likes_retry_timer = -1;
        parsing_active = 0;
        parsing_index = 0;
        load_phase = 0;
        load_phase_text = "cargando texturas...";
        request_textures = scr_supabase_get_textures(current_page, items_per_page, current_sort, "");
        
        if (global.user_logged_in)
            request_my_likes = scr_get_my_texture_likes();
        else
            likes_loaded = 1;
    }
    
    return 1;
}

function scr_upload_texture_to_github(arg0, arg1, arg2, arg3, arg4)
{
    scr_debug_log("=== TEXTURE GITHUB UPLOAD START ===");
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
    scr_debug_log("file_size: " + string(_size) + " bytes (" + string(_size / 1024 / 1024) + " MB)");
    
    if (_size > 52428800)
    {
        buffer_delete(_buffer);
        scr_debug_log("ERROR: Archivo muy grande (max 50MB)");
        return -2;
    }
    
    var _base64 = buffer_base64_encode(_buffer, 0, _size);
    buffer_delete(_buffer);
    scr_debug_log("base64 length: " + string(string_length(_base64)));
    var _url = global.worker_textures_upload_url;
    scr_debug_log("upload URL: " + _url);
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", arg1);
    ds_map_add(_headers, "X-Texture-Name", arg2);
    ds_map_add(_headers, "X-Author-Name", arg3);
    ds_map_add(_headers, "X-Author-Id", arg4);
    var _request = http_request(_url, "POST", _headers, _base64);
    ds_map_destroy(_headers);
    scr_debug_log("request ID: " + string(_request));
    scr_debug_log("=== TEXTURE UPLOAD REQUEST SENT ===");
    return _request;
}

function scr_add_texture_comment(arg0, arg1)
{
    if (!global.user_logged_in)
        return -1;
    
    var _filtered_content = scr_filter_bad_words(arg1);
    _filtered_content = string_replace_all(_filtered_content, "\"", "\\\"");
    _filtered_content = string_replace_all(_filtered_content, "\\", "\\\\");
    var _url = global.supabase_url + "/rest/v1/rpc/add_texture_comment";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{";
    _body += ("\"arg_texture_id\":" + string(arg0) + ",");
    _body += ("\"arg_user_id\":\"" + global.user_id + "\",");
    _body += ("\"arg_content\":\"" + _filtered_content + "\"");
    _body += "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_get_texture_comments(arg0, arg1, arg2)
{
    var _url = global.supabase_url + "/rest/v1/rpc/get_texture_comments";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{\"p_texture_id\":" + string(arg0) + ",\"p_limit\":" + string(arg1) + ",\"p_offset\":" + string(arg2) + "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_get_texture_comment_count(arg0)
{
    var _url = global.supabase_url + "/rest/v1/rpc/get_texture_comment_count";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{\"p_texture_id\":" + string(arg0) + "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_delete_texture(arg0)
{
    if (!global.user_logged_in)
        return -1;
    
    var _url = global.supabase_url + "/rest/v1/rpc/delete_texture_safe";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{";
    _body += ("\"p_texture_id\":" + string(arg0) + ",");
    _body += ("\"p_user_id\":\"" + global.user_id + "\"");
    _body += "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_check_texture_is_featured(arg0)
{
    var _url = global.supabase_url + "/rest/v1/admin_featured_textures?texture_id=eq." + string(arg0) + "&select=id";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}

function scr_toggle_texture_featured(arg0, arg1)
{
    if (!global.user_logged_in)
        return -1;
    
    if (!global.user_is_admin)
        return -1;
    
    var _url = global.supabase_url + "/rest/v1/rpc/toggle_texture_featured";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{";
    _body += ("\"p_texture_id\":" + string(arg0) + ",");
    _body += ("\"p_user_id\":\"" + global.user_id + "\",");
    _body += "\"p_is_currently_featured\":";
    
    if (arg1)
        _body += "true";
    else
        _body += "false";
    
    _body += "}";
    scr_debug_log("TOGGLE FEATURED REQUEST: " + _body);
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_get_featured_textures(arg0, arg1)
{
    var _url = global.supabase_url + "/rest/v1/rpc/get_featured_textures";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{";
    _body += ("\"p_limit\":" + string(arg0) + ",");
    _body += ("\"p_offset\":" + string(arg1));
    _body += "}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}

function scr_texture_loader_start_loading_featured()
{
    with (obj_texture_loader)
    {
        ds_list_clear(global.texture_ids);
        
        if (variable_global_exists("texture_item_types"))
            ds_list_clear(global.texture_item_types);
        
        ds_list_clear(global.texture_names);
        ds_list_clear(global.texture_authors);
        ds_list_clear(global.texture_author_ids);
        ds_list_clear(global.texture_descs);
        
        if (variable_global_exists("texture_cold_storage_ids") && ds_exists(global.texture_cold_storage_ids, ds_type_list))
            ds_list_clear(global.texture_cold_storage_ids);
        
        ds_list_clear(global.texture_files);
        ds_list_clear(global.texture_thumbs);
        ds_list_clear(global.texture_likes);
        ds_list_clear(global.texture_downloads);
        ds_list_clear(global.texture_dates);
        ds_list_clear(global.my_texture_likes);
        
        if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
            ds_list_clear(global.texture_github_urls);
        
        for (var i = 0; i < ds_list_size(global.texture_tags); i++)
        {
            var _sub = ds_list_find_value(global.texture_tags, i);
            
            if (ds_exists(_sub, ds_type_list))
                ds_list_destroy(_sub);
        }
        
        ds_list_clear(global.texture_tags);
        textures_loaded = 0;
        textures_retry_count = 0;
        textures_retry_timer = -1;
        likes_loaded = 0;
        likes_retry_count = 0;
        likes_retry_timer = -1;
        parsing_active = 0;
        parsing_index = 0;
        load_phase = 0;
        load_phase_text = "cargando destacados...";
        featured_textures_loading = 1;
        current_page = 0;
        has_more = 1;
        request_featured_textures = scr_get_featured_textures(items_per_page, 0);
        
        if (global.user_logged_in)
            request_my_likes = scr_get_my_texture_likes();
        else
            likes_loaded = 1;
    }
    
    return 1;
}

function scr_execute_texture_search()
{
    var _search_name = "";
    var _search_author = "";
    
    if (instance_exists(obj_texture_search_panel))
    {
        if (obj_texture_search_panel.search_mode == 0)
            _search_name = obj_texture_search_panel.search_text;
        else
            _search_author = obj_texture_search_panel.search_text;
        
        if (ds_exists(global.texture_search_tags, ds_type_list))
            ds_list_clear(global.texture_search_tags);
        else
            global.texture_search_tags = ds_list_create();
        
        if (ds_exists(obj_texture_search_panel.tags_selected, ds_type_list))
        {
            for (var i = 0; i < ds_list_size(obj_texture_search_panel.tags_selected); i++)
                ds_list_add(global.texture_search_tags, ds_list_find_value(obj_texture_search_panel.tags_selected, i));
        }
    }
    
    global.texture_search_name = _search_name;
    global.texture_search_author = _search_author;
    
    if (instance_exists(obj_texture_loader))
    {
        with (obj_texture_loader)
        {
            if (ds_exists(instancias_tarjetas, ds_type_list))
            {
                var _list_size = ds_list_size(instancias_tarjetas);
                
                for (var k = 0; k < _list_size; k++)
                {
                    var _inst = ds_list_find_value(instancias_tarjetas, k);
                    
                    if (instance_exists(_inst))
                        instance_destroy(_inst);
                }
                
                ds_list_clear(instancias_tarjetas);
            }
            
            if (ds_exists(cards_creation_queue, ds_type_list))
                ds_list_clear(cards_creation_queue);
            
            ds_list_clear(global.texture_ids);
            ds_list_clear(global.texture_names);
            ds_list_clear(global.texture_authors);
            ds_list_clear(global.texture_author_ids);
            ds_list_clear(global.texture_descs);
            ds_list_clear(global.texture_files);
            ds_list_clear(global.texture_thumbs);
            ds_list_clear(global.texture_likes);
            ds_list_clear(global.texture_downloads);
            ds_list_clear(global.texture_dates);
            
            if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
                ds_list_clear(global.texture_github_urls);
            
            if (ds_exists(global.texture_tags, ds_type_list))
            {
                for (var k = 0; k < ds_list_size(global.texture_tags); k++)
                {
                    var _sub = ds_list_find_value(global.texture_tags, k);
                    
                    if (ds_exists(_sub, ds_type_list))
                        ds_list_destroy(_sub);
                }
                
                ds_list_clear(global.texture_tags);
            }
            
            parsing_active = 0;
            parsing_index = 0;
            
            if (variable_instance_exists(id, "parsed_textures_list") && ds_exists(parsed_textures_list, ds_type_list))
            {
                ds_list_destroy(parsed_textures_list);
                parsed_textures_list = -1;
            }
            
            view_mode = 5;
            current_page = 0;
            scroll_y = 0;
            has_more = 1;
            textures_loaded = 0;
            load_phase = 0;
            load_phase_text = "buscando...";
            request_textures = scr_supabase_search_textures(0, items_per_page, _search_name, _search_author, global.texture_search_tags);
            scr_debug_log("TEXTURE SEARCH: name=" + _search_name + " author=" + _search_author + " tags=" + string(ds_list_size(global.texture_search_tags)));
        }
    }
    
    return 1;
}

function scr_json_get_array_value(arg0, arg1)
{
    var _search = "\"" + arg1 + "\":";
    var _pos = string_pos(_search, arg0);
    
    if (_pos == 0)
        return "";
    
    var _start = _pos + string_length(_search);
    
    while (string_char_at(arg0, _start) == " ")
        _start++;
    
    var _c = string_char_at(arg0, _start);
    
    if (_c != "[")
    {
        if (string_copy(arg0, _start, 4) == "null")
            return "";
        
        return "";
    }
    
    var _bracket_depth = 0;
    var _len = string_length(arg0);
    var _end_pos;
    
    for (_end_pos = _start; _end_pos <= _len; _end_pos += 1)
    {
        _c = string_char_at(arg0, _end_pos);
        
        if (_c == "[")
        {
            _bracket_depth += 1;
        }
        else if (_c == "]")
        {
            _bracket_depth -= 1;
            
            if (_bracket_depth == 0)
                break;
        }
    }
    
    var _result = string_copy(arg0, _start, (_end_pos - _start) + 1);
    return _result;
}

function scr_sanitize_filename(arg0)
{
    var _result = string(arg0);
    _result = string_replace_all(_result, "\n", "");
    _result = string_replace_all(_result, "\r", "");
    var _bad_chars = ["/", "\\", ":", "*", "?", "\"", "<", ">", "|"];
    
    for (var i = 0; i < array_length(_bad_chars); i++)
        _result = string_replace_all(_result, _bad_chars[i], "_");
    
    _result = string_trim(_result);
    
    while (string_pos("  ", _result) > 0)
        _result = string_replace_all(_result, "  ", " ");
    
    _result = string_replace_all(_result, " ", "_");
    
    if (string_length(_result) > 50)
        _result = string_copy(_result, 1, 50);
    
    return _result;
}

function scr_search_textures_for_upload(arg0)
{
    var _url = global.supabase_url + "/rest/v1/textures?select=id,name,author_name";
    
    if (arg0 != "")
        _url += ("&name=ilike.*" + string(arg0) + "*");
    
    _url += "&order=name.asc&limit=10";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}

function scr_level_file_start_texture_process()
{
    scr_debug_log("=== INICIANDO PROCESO DE TEXTURA ===");
    
    if (texture_name == "" || string_lower(texture_name) == "vanilla")
    {
        scr_debug_log("Sin textura especial, iniciando nivel directamente");
        texture_downloaded = true;
        texture_applied = true;
        scr_level_file_start_custom_process();
        exit;
    }
    
    scr_debug_log("Textura original del nivel: " + texture_name);
    var texture_name_clean = texture_name;
    var dash_pos = string_pos(" - ", texture_name);
    
    if (dash_pos > 0)
    {
        texture_name_clean = string_copy(texture_name, 1, dash_pos - 1);
        scr_debug_log("Nombre de textura extraído: " + texture_name_clean);
    }
    
    while (string_char_at(texture_name_clean, 1) == " ")
        texture_name_clean = string_copy(texture_name_clean, 2, string_length(texture_name_clean) - 1);
    
    while (string_length(texture_name_clean) > 0 && string_char_at(texture_name_clean, string_length(texture_name_clean)) == " ")
        texture_name_clean = string_copy(texture_name_clean, 1, string_length(texture_name_clean) - 1);
    
    texture_name_for_search = texture_name_clean;
    scr_debug_log("Textura a buscar: " + texture_name_for_search);
    var texturas_path;
    
    if (scr_isWindows())
        texturas_path = working_directory + "Texturas_manual/";
    else
        texturas_path = getDire2("SM4J", "Texturas_manual") + "/";
    
    var safe_texture_name = scr_sanitize_filename(texture_name_for_search);
    texture_install_path = texturas_path + safe_texture_name;
    scr_debug_log("Buscando textura en: " + texture_install_path);
    
    if (directory_exists(texture_install_path))
    {
        scr_debug_log("¡Textura ya instalada! Saltando descarga");
        texture_downloaded = true;
        texture_needs_download = false;
        scr_level_file_start_custom_process();
        exit;
    }
    
    var alternative_names = [texture_name_for_search, string_replace_all(texture_name_for_search, " ", "_"), string_replace_all(texture_name_for_search, " ", "-"), string_lower(texture_name_for_search), string_replace_all(string_lower(texture_name_for_search), " ", "_")];
    
    for (var i = 0; i < array_length(alternative_names); i++)
    {
        var alt_path = texturas_path + scr_sanitize_filename(alternative_names[i]);
        
        if (directory_exists(alt_path))
        {
            scr_debug_log("¡Textura encontrada con nombre alternativo: " + alt_path);
            texture_install_path = alt_path;
            texture_downloaded = true;
            texture_needs_download = false;
            scr_level_file_start_custom_process();
            exit;
        }
    }
    
    scr_debug_log("Textura no encontrada localmente, buscando URL de descarga...");
    texture_github_url = "";
    texture_file_name = "";
    texture_cold_id = "";
    texture_needs_download = true;
    var _found = false;
    
    if (variable_global_exists("texture_names") && ds_exists(global.texture_names, ds_type_list))
    {
        for (var i = 0; i < ds_list_size(global.texture_names); i++)
        {
            var t_name = ds_list_find_value(global.texture_names, i);
            var t_name_clean = scr_clean_json_string(t_name);
            
            if (string_lower(t_name_clean) == string_lower(texture_name_for_search))
            {
                _found = true;
                
                if (variable_global_exists("texture_github_urls") && ds_exists(global.texture_github_urls, ds_type_list))
                {
                    if (i < ds_list_size(global.texture_github_urls))
                        texture_github_url = scr_clean_json_string(ds_list_find_value(global.texture_github_urls, i));
                }
                
                if (variable_global_exists("texture_files") && ds_exists(global.texture_files, ds_type_list))
                {
                    if (i < ds_list_size(global.texture_files))
                        texture_file_name = scr_clean_json_string(ds_list_find_value(global.texture_files, i));
                }
                
                if (variable_global_exists("texture_cold_storage_ids") && ds_exists(global.texture_cold_storage_ids, ds_type_list))
                {
                    if (i < ds_list_size(global.texture_cold_storage_ids))
                        texture_cold_id = scr_clean_json_string(ds_list_find_value(global.texture_cold_storage_ids, i));
                }
                
                if (texture_cold_id == "null")
                    texture_cold_id = "";
                
                break;
            }
        }
    }
    
    if (!_found || (texture_file_name == "" && texture_github_url == "" && texture_github_url == "null"))
    {
        scr_debug_log("URL no en cache, solicitando a Supabase...");
        texture_search_request = scr_get_texture_by_name(texture_name_for_search);
        exit;
    }
    
    scr_level_file_download_texture();
}

function scr_get_texture_by_name(arg0)
{
    var _url = global.supabase_url + "/rest/v1/textures?name=ilike.*" + string(arg0) + "*&select=id,name,file_name,cold_storage_id,github_download_url&limit=1";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    scr_debug_log("GET TEXTURE BY NAME: " + arg0 + " request=" + string(_request));
    return _request;
}

function scr_level_file_download_texture()
{
    if (texture_file_name == "" && (texture_github_url == "" || texture_github_url == "null"))
    {
        scr_debug_log("ERROR: No hay URL ni file_name de textura disponible");
        texture_downloaded = true;
        texture_applied = true;
        download_state = 4;
        scr_level_file_start_custom_process();
        exit;
    }
    
    scr_debug_log("=== INICIANDO DESCARGA DE TEXTURA ===");
    var texturas_path;
    
    if (scr_isWindows())
        texturas_path = working_directory + "Texturas_manual/";
    else
        texturas_path = getDire2("SM4J", "Texturas_manual") + "/";
    
    if (!directory_exists(texturas_path))
        directory_create(texturas_path);
    
    var safe_name = scr_sanitize_filename(texture_name_for_search);
    
    if (safe_name == "")
        safe_name = "Texture_" + string(current_time);
    
    scr_debug_log("Nombre de textura: " + safe_name);
    texture_download_path = texturas_path + safe_name + ".simplepack";
    texture_install_path = texturas_path + safe_name;
    scr_debug_log("Guardando en: " + texture_download_path);
    
    if (texture_file_name != "")
    {
        scr_debug_log("Llamando a bridge de texturas con file_name: " + texture_file_name);
        request_texture_bridge_url = scr_request_texture_download_url(texture_file_name, texture_cold_id);
    }
    else
    {
        scr_debug_log("Usando URL de GitHub: " + texture_github_url);
        var proxy_url = global.worker_textures_url + "/?url=" + texture_github_url;
        texture_download_request = http_get_file(proxy_url, texture_download_path);
    }
    
    texture_downloaded = false;
    texture_download_progress = 0;
    download_state = 2;
}

function scr_level_file_trigger_transition()
{
    // Preparacion de party: nivel, textura y customs ya terminaron, pero este
    // cliente no entra todavia. Reporta listo y espera al resto.
    if (variable_global_exists("party_preflight") && global.party_preflight)
    {
        if (texture_needs_download && !texture_downloaded)
            exit;
        
        if (!variable_instance_exists(id, "party_preflight_done") || !party_preflight_done)
        {
            party_preflight_done = true;
            var _party_cancelled = variable_global_exists("party_preflight_cancelled")
                && global.party_preflight_cancelled;
            
            if (_party_cancelled || !instance_exists(obj_party_hud))
            {
                global.party_preflight = false;
                global.party_preflight_cancelled = false;
                scr_debug_log("PARTY: preparacion tardia descartada");
            }
            else
            {
                var _party_card = id;
                scr_debug_log("PARTY: preparacion local completa");
                scr_party_preflight_terminado(_party_card);
            }
        }
        exit;
    }
    
    if (texture_transition_triggered)
        exit;
    
    if (texture_needs_download && !texture_downloaded)
    {
        scr_debug_log("TRANSICIÓN: Esperando descarga de textura...");
        exit;
    }
    
    texture_transition_triggered = true;
    scr_debug_log("=== DISPARANDO TRANSICIÓN ===");
    
    if (texture_name == "" || string_lower(texture_name) == "vanilla")
    {
        texture_install_path = "";
        scr_debug_log("Nivel Vanilla detectado, limpiando path de textura.");
    }
    
    scr_debug_log("Textura descargada: " + string(texture_downloaded));
    scr_debug_log("Path de textura: " + texture_install_path);
    var my_name = global.current_play_level;
    var my_author = global.current_play_autor;
    var _transition = instance_create_depth(0, 0, -9999, obj_level_start_transition);
    _transition.level_name = my_name;
    _transition.level_author = my_author;
    _transition.target_room = rm_new_level_editor_play;
    _transition.texture_to_apply = texture_install_path;
    _transition.texture_name = texture_name;
    _transition.level_file_instance = id;
    scr_debug_log("Transición creada, textura a aplicar: '" + texture_install_path + "'");
}

function scr_level_file_start_level()
{
    scr_debug_log("=== INICIANDO NIVEL ===");
    var my_id = global.current_play_id;
    var my_name = global.current_play_level;
    var my_author = global.current_play_autor;
    var level_load = working_directory + "temp_load.lvl";
    
    if (file_exists(level_load))
        file_delete(level_load);
    
    file_copy(play_level, level_load);
    // renovar todas las copias evita reintentar con zonas del nivel anterior
    scr_divide_rooms_nuevo(level_load);
    scr_level_reset_warp_state();
    global.play_test_mode = false;
    global.modo_editor = 0;
    global.net_area = "";
    global.net_load_id = 1;
    global.clear = 0;
    global.LE_play = 1;
    global.mapa_LE_play = level_load;
    global.file_nameA = filename_name(level_load);
    global.checkpoint = -4;
    global.checkpointroom_LE = 1;
    global.onoffblock = 0;
    global.onoffblock_prev = 0;
    global.nivel_actual = 1;
    global.muertos = 0;
    global.current_level_deaths = 0;
    
    if (is_string(my_id))
        scr_start_online_level(real(my_id));
    else
        scr_start_online_level(my_id);
    
    ini_open(level_load);
    var rw = ini_read_real("options", "room_x", 8000);
    var rh = ini_read_real("options", "room_y", 432);
    ini_close();
    room_set_width(rm_new_level_editor_play, rw);
    room_set_height(rm_new_level_editor_play, rh);
    scr_debug_log("Room size: " + string(rw) + "x" + string(rh));
    // solo queda el cargador de esta partida y siempre lee la zona principal
    with (obj_nivel_cargador)
        instance_destroy();
    with (obj_nivel_cargador_3)
        instance_destroy();
    var cargador = instance_create_layer(0, 0, "Instances", obj_nivel_cargador_3);
    cargador.room_number = "";
    cargador.nivel_ruta = level_load;
    cargador.persistent = true;
    cargador.estado = 1;
    scr_debug_log("Nivel listo para cargar");
}
