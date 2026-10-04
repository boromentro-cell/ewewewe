// likes
// level_likes tiene una fila por usuario y nivel. el cliente se guarda aparte cuales likeo
// en global.is_liked_list para pintar el corazon sin volver a preguntar.
// saca la fila de level_likes de este usuario en este nivel.
function scr_supabase_remove_like(arg0)
{
    if (!global.user_logged_in)
        return -1;
    
    if (!scr_rate_limit_check("like"))
    {
        show_debug_message("REMOVE LIKE: Rate limited");
        return -1;
    }
    
    var _url = global.supabase_url + "/rest/v1/level_likes?level_id=eq." + string(arg0) + "&user_id=eq." + global.user_id;
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "DELETE", _headers, "");
    ds_map_destroy(_headers);
    scr_rate_limit_register("like");
    return _request;
}
// agrega el like. corta antes si no hay token o no hay user id.
function scr_supabase_add_like(arg0)
{
    if (!global.user_logged_in)
    {
        show_debug_message("ADD LIKE: No logueado");
        return -1;
    }
    
    if (!scr_rate_limit_check("like"))
    {
        show_debug_message("ADD LIKE: Rate limited (" + string(scr_rate_limit_remaining("like")) + "ms restantes)");
        return -1;
    }
    
    if (global.user_token == "")
    {
        show_debug_message("ADD LIKE: Token vacío!");
        return -1;
    }
    
    if (global.user_id == "")
    {
        show_debug_message("ADD LIKE: User ID vacío!");
        return -1;
    }
    
    show_debug_message("ADD LIKE: user_id=" + global.user_id);
    var _url = global.supabase_url + "/rest/v1/level_likes";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "Prefer", "return=representation");
    var _body = json_stringify(
    {
        level_id: int64(arg0),
        user_id: global.user_id
    });
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    scr_rate_limit_register("like");
    return _request;
}
// arg1 es si ya estaba likeado, esta funcion no lo consulta, se lo tienen que decir.
function scr_supabase_toggle_like(arg0, arg1)
{
    if (!global.user_logged_in)
    {
        show_message_extra("Debes iniciar sesión para dar like");
        return -1;
    }
    
    show_debug_message("TOGGLE LIKE: level_id=" + string(arg0) + " currently_liked=" + string(arg1));
    
    if (arg1)
        return scr_supabase_remove_like(arg0);
    else
        return scr_supabase_add_like(arg0);
}
// todos los likes del usuario, sin filtrar por nivel.
function scr_supabase_get_my_likes()
{
    if (!global.user_logged_in)
        return -1;
    
    var _url = global.supabase_url + "/rest/v1/level_likes?select=level_id&user_id=eq." + global.user_id;
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    global.request_my_likes = _request;
    return _request;
}
// los likes del usuario pero solo sobre los niveles que se estan mostrando, arg0 es la lista de
// id. es lo que se usa al cargar una tanda de tarjetas.
function scr_supabase_get_user_likes(arg0)
{
    if (!global.user_logged_in || global.user_id == "")
        return -1;
    
    var _ids_string = "(";
    var _size = ds_list_size(arg0);
    
    for (var _i = 0; _i < _size; _i++)
    {
        if (_i > 0)
            _ids_string += ",";
        
        _ids_string += string(ds_list_find_value(arg0, _i));
    }
    
    _ids_string += ")";
    var _url = global.supabase_url + "/rest/v1/level_likes?select=level_id&user_id=eq." + global.user_id + "&level_id=in." + _ids_string;
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}





// descargas
// suma uno al contador de descargas del nivel.
function scr_supabase_increment_download(arg0)
{
    var _url = global.supabase_url + "/rest/v1/rpc/increment_downloads";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = json_stringify(
    {
        level_id_param: int64(arg0)
    });
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}





// comentarios
// trae los comentarios paginados.
function scr_get_level_comments(arg0, arg1, arg2)
{
    var url = global.supabase_url + "/rest/v1/rpc/get_level_comments";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_level_id: int64(arg0),
        p_limit: int64(arg1),
        p_offset: int64(arg2)
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// solo la cantidad, para el numerito del boton sin traer los comentarios.
function scr_get_comment_count(arg0)
{
    var url = global.supabase_url + "/rest/v1/rpc/get_comment_count";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_level_id: int64(arg0)
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// publica un comentario. el texto tendria que venir ya pasado por el filtro.
function scr_add_level_comment(arg0, arg1)
{
    if (!global.user_logged_in)
        return -1;
    
    if (!scr_rate_limit_check("comment"))
    {
        show_debug_message("COMMENT: Rate limited (" + string(scr_rate_limit_remaining("comment")) + "ms)");
        return -1;
    }
    
    var filtered_content = scr_filter_bad_words(arg1);
    filtered_content = string_replace_all(filtered_content, "\\", "\\\\");
    filtered_content = string_replace_all(filtered_content, "\"", "\\\"");
    var url = global.supabase_url + "/rest/v1/rpc/add_level_comment";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = "{";
    body += ("\"arg_level_id\":" + string(arg0) + ",");
    body += ("\"arg_user_id\":\"" + global.user_id + "\",");
    body += ("\"arg_content\":\"" + filtered_content + "\"");
    body += "}";
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    scr_rate_limit_register("comment");
    return request;
}





// tags
// sprite y color de cada tag.
function scr_get_tag_visuals(arg0)
{
    arg0 = string_lower(arg0);
    var spr = 2560;
    var col;
    
    switch (arg0)
    {
        case "dificil":
        case "hard":
        case "kaizo":
            col = 3947720;
            spr = 2560;
            break;
        
        case "puzzle":
        case "enigma":
            col = 13122700;
            spr = 2560;
            break;
        
        case "tradicional":
        case "standard":
            col = 3973180;
            spr = 2560;
            break;
        
        case "speedrun":
        case "speed":
            col = 14443580;
            spr = 2560;
            break;
        
        case "corto":
        case "short":
            col = 3978460;
            spr = 2560;
            break;
        
        case "musica":
        case "music":
            col = 11822300;
            spr = 2560;
            break;
        
        case "troll":
            col = 5263440;
            spr = 2560;
            break;
        
        case "aventura":
            col = 14985728;
            spr = 2560;
            break;
        
        default:
            col = 7890020;
            break;
    }
    
    var result = [col, spr];
    return result;
}
// devuelve una ds_list nueva cada vez. scr_parse_single_level la mete adentro de
// global.tags_levels, asi que al limpiar esa lista hay que destruir cada sublista primero o
// quedan colgadas en memoria.
function scr_parse_tags_json(arg0)
{
    var list = ds_list_create();
    
    if (is_undefined(arg0) || arg0 == "" || arg0 == "null" || arg0 == "[]")
        return list;
    
    var len = string_length(arg0);
    var in_quote = false;
    var current_word = "";
    
    for (var i = 1; i <= len; i++)
    {
        var char = string_char_at(arg0, i);
        
        if (char == "\"")
        {
            if (in_quote)
            {
                if (current_word != "")
                    ds_list_add(list, current_word);
                
                current_word = "";
                in_quote = false;
            }
            else
            {
                in_quote = true;
            }
        }
        else if (in_quote)
        {
            current_word += char;
        }
    }
    
    return list;
}





// validacion y cupo de subida
// antes de subir se chequea que el archivo sea un nivel de verdad y que al usuario le quede
// lugar. el cupo va subiendo con la cantidad de niveles que ya tiene publicados.
// abre el ini del nivel y chequea que tenga NewtilesetValues y un tamano de room valido, para
// no dejar subir un archivo que no es un nivel o que quedo cortado.
function scr_validate_level_file(arg0)
{
    var is_valid = 0;
    
    if (!file_exists(arg0))
        return 0;
    
    var f = file_bin_open(arg0, 0);
    var size = file_bin_size(f);
    file_bin_close(f);
    
    if (size < 100)
        return 0;
    
    ini_open(arg0);
    var check_val = ini_read_string("options", "NewtilesetValues", "ERROR");
    var check_w = ini_read_real("options", "room_x", 0);
    var check_h = ini_read_real("options", "room_y", 0);
    ini_close();
    
    if (check_val == "DON´T ERASE" && check_w > 0 && check_h > 0)
        is_valid = 1;
    
    return is_valid;
}
// cuantos niveles mas puede subir el usuario. el cupo arranca en 10 y va subiendo con los que
// ya tiene publicados. los admin y los que tienen el badge 1 no tienen tope.
function scr_calculate_upload_limit(arg0)
{
    if (variable_global_exists("user_is_admin") && global.user_is_admin)
        return 9999;
    
    if (variable_global_exists("user_badges_owned") && ds_exists(global.user_badges_owned, ds_type_list))
    {
        var list_size = ds_list_size(global.user_badges_owned);
        
        for (var i = 0; i < list_size; i++)
        {
            var badge_val = ds_list_find_value(global.user_badges_owned, i);
            
            if (real(badge_val) == 1)
                return 9999;
        }
    }
    
    if (arg0 < 10)
        return 10;
    
    if (arg0 < 20)
        return 15;
    
    if (arg0 < 30)
        return 20;
    
    if (arg0 < 40)
        return 30;
    
    if (arg0 < 50)
        return 45;
    
    return 9999;
}
// cuenta los niveles del usuario para saber en que escalon del cupo esta.
function scr_supabase_get_my_level_count()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/levels?select=id&author_id=eq." + global.user_id + "&limit=1000";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}





// filtro de insultos
// tapa las malas palabras dejando la primera letra y el resto en asteriscos.
function scr_filter_bad_words(arg0)
{
    static _bad_words_array = ["puta", "puto", "mierda", "verga", "pendejo", "pendeja", "idiota", "estupido", "estupida", "imbecil", "cabron", "cabrona", "chingar", "chingada", "culero", "culera", "marica", "maricon", "joto", "perra", "perro", "zorra", "bastardo", "bastarda", "cagar", "culo", "coger", "fuck", "shit", "bitch", "asshole", "dick", "pussy", "cock", "cunt", "whore", "slut", "nigger", "faggot", "nigga", "put4", "n1gga", "codigo"];
    
    if (!is_string(arg0))
        return arg0;
    
    var _result = arg0;
    var _text_lower = string_lower(arg0);
    var _count = array_length(_bad_words_array);
    
    for (var i = 0; i < _count; i++)
    {
        var _bad_word = _bad_words_array[i];
        var _pos = string_pos(_bad_word, _text_lower);
        
        while (_pos > 0)
        {
            var _len_word = string_length(_bad_word);
            var _replacement = string_char_at(_bad_word, 1);
            
            repeat (_len_word - 1)
                _replacement += "*";
            
            var _before = string_copy(_result, 1, _pos - 1);
            var _after = string_copy(_result, _pos + _len_word, string_length(_result));
            _result = _before + _replacement + _after;
            // se compara en minuscula pero se reemplaza sobre el texto original
            // para no romperle las mayusculas al que escribio
            _text_lower = string_lower(_result);
            _pos = string_pos(_bad_word, _text_lower);
        }
    }
    
    return _result;
}
