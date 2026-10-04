if (!ds_exists(async_load, ds_type_map))
    exit;

var _request_id = ds_map_find_value(async_load, "id");
var _status = ds_map_find_value(async_load, "status");
var _http_status = ds_map_find_value(async_load, "http_status");

if (is_undefined(_request_id))
    exit;

if (_request_id == request_textures)
{
    request_textures = -1;
    
    if (_status == 0 && (_http_status == 200 || _http_status == 201))
    {
        var _result = ds_map_find_value(async_load, "result");
        scr_debug_log("TEXTURES RESPONSE: " + string_copy(string(_result), 1, 300));
        var _list = scr_json_parse_textures(_result);
        var _count = ds_list_size(_list);
        
        if (_count < items_per_page)
            has_more = 0;
        
        if (_count == 0 && current_page == 0)
        {
            if (_result == "" || _result == "[]" || _result == "null")
            {
                textures_loaded = 1;
                likes_loaded = 1;
                load_phase = 2;
                load_phase_text = "";
            }
            else
            {
                textures_retry_timer = 30;
            }
            
            ds_list_destroy(_list);
        }
        else
        {
            parsed_textures_list = _list;
            parsing_active = 1;
            parsing_index = 0;
            
            if (view_mode == 5)
                load_phase_text = "procesando resultados...";
            else
                load_phase_text = "procesando texturas...";
        }
    }
    else
    {
        scr_debug_log("TEXTURES ERROR: status=" + string(_status) + " http=" + string(_http_status));
        textures_retry_timer = 60 + (textures_retry_count * 30);
    }
    
    exit;
}

if (_request_id == request_featured_textures)
{
    if (_status == 1)
        exit;
    
    request_featured_textures = -1;
    
    if (_status == 0)
    {
        var _result = ds_map_find_value(async_load, "result");
        scr_debug_log("FEATURED TEXTURES RESPONSE: " + string_copy(string(_result), 1, 300));
        
        if (is_string(_result) && _result != "" && _result != "[]" && _result != "null")
        {
            var _textures_list = scr_json_parse_textures(_result);
            var _count = ds_list_size(_textures_list);
            
            if (_count < items_per_page)
                has_more = 0;
            
            if (_count > 0)
            {
                parsed_textures_list = _textures_list;
                parsing_active = 1;
                parsing_index = 0;
                load_phase_text = "procesando destacados...";
            }
            else
            {
                ds_list_destroy(_textures_list);
                textures_loaded = 1;
                likes_loaded = 1;
                load_phase = 2;
                load_phase_text = "";
                featured_textures_loading = 0;
            }
        }
        else
        {
            textures_loaded = 1;
            likes_loaded = 1;
            load_phase = 2;
            load_phase_text = "";
            featured_textures_loading = 0;
        }
    }
    else
    {
        scr_debug_log("FEATURED TEXTURES ERROR: status=" + string(_status));
        textures_retry_timer = 60;
    }
    
    exit;
}

if (_request_id == request_my_likes)
{
    request_my_likes = -1;
    
    if (global.likes_operation_pending)
        exit;
    
    if (_status == 0 && (_http_status == 200 || _http_status == 201))
    {
        var _result = ds_map_find_value(async_load, "result");
        ds_list_clear(global.my_texture_likes);
        
        if (is_string(_result) && _result != "" && _result != "[]" && _result != "null")
        {
            var _temp_result = _result;
            var _search_key = "\"texture_id\":";
            var _key_len = string_length(_search_key);
            var _found_pos = string_pos(_search_key, _temp_result);
            
            while (_found_pos > 0)
            {
                _temp_result = string_copy(_temp_result, _found_pos + _key_len, (string_length(_temp_result) - _found_pos - _key_len) + 1);
                
                while (string_char_at(_temp_result, 1) == " ")
                    _temp_result = string_copy(_temp_result, 2, string_length(_temp_result) - 1);
                
                var _num_str = "";
                var _c = string_char_at(_temp_result, 1);
                
                while (_c >= "0" && _c <= "9" && string_length(_temp_result) > 0)
                {
                    _num_str += _c;
                    _temp_result = string_copy(_temp_result, 2, string_length(_temp_result) - 1);
                    _c = string_char_at(_temp_result, 1);
                }
                
                if (_num_str != "")
                    ds_list_add(global.my_texture_likes, _num_str);
                
                _found_pos = string_pos(_search_key, _temp_result);
            }
        }
        
        likes_loaded = 1;
        likes_retry_count = 0;
    }
    else
    {
        likes_retry_timer = 45 + (likes_retry_count * 20);
    }
    
    exit;
}
