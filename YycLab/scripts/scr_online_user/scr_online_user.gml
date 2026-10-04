
// perfil de otro usuario
// lo que pide obj_user_profile_view cuando entras al perfil de alguien.
// deja presentable un valor que salio del json: le saca las comillas de los bordes, los saltos
// de linea y los espacios repetidos.
function scr_clean_json_string(arg0)
{
    if (is_undefined(arg0))
        return "";
    
    if (is_real(arg0))
        arg0 = string(arg0);
    
    if (!is_string(arg0))
        return "";
    
    if (string_char_at(arg0, 1) == "\"")
        arg0 = string_copy(arg0, 2, string_length(arg0) - 1);
    
    if (string_char_at(arg0, string_length(arg0)) == "\"")
        arg0 = string_copy(arg0, 1, string_length(arg0) - 1);
    
    while (string_char_at(arg0, 1) == " ")
        arg0 = string_copy(arg0, 2, string_length(arg0) - 1);
    
    while (string_char_at(arg0, string_length(arg0)) == " ")
        arg0 = string_copy(arg0, 1, string_length(arg0) - 1);
    
    arg0 = string_replace_all(arg0, "\n", "");
    arg0 = string_replace_all(arg0, "\r", "");
    arg0 = string_replace_all(arg0, "    ", " ");
    arg0 = string_replace_all(arg0, "\t", " ");
    
    // va en while porque cada pasada puede dejar dos espacios nuevos pegados
    while (string_pos("  ", arg0) > 0)
        arg0 = string_replace_all(arg0, "  ", " ");
    
    while (string_char_at(arg0, 1) == " ")
        arg0 = string_copy(arg0, 2, string_length(arg0) - 1);
    
    while (string_char_at(arg0, string_length(arg0)) == " ")
        arg0 = string_copy(arg0, 1, string_length(arg0) - 1);
    
    return arg0;
}
// trae el perfil completo de un usuario por id.
function scr_load_user_profile(arg0)
{
    var url = global.supabase_url + "/rest/v1/profiles?p_user_id=eq." + arg0 + "&select=*";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// trae los badges de un usuario con el nombre y el icono de cada uno.
function scr_load_user_badges(arg0)
{
    var url = global.supabase_url + "/rest/v1/user_badges?ub_user_id=eq." + arg0 + "&select=id,badge_id,awarded_at,awarded_by,badges(name,description,icon_name,color),profiles:awarded_by(username)";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// trae los niveles publicados por ese usuario.
function scr_load_user_levels(arg0)
{
    var url = global.supabase_url + "/rest/v1/levels?author_id=eq." + arg0 + "&select=id,name,description,file_name,thumbnail_name,downloads,created_at,level_likes(count)" + "&order=created_at.desc&limit=3";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// trae descargas y likes de todos sus niveles para sumarlos y mostrar el total.
function scr_load_user_stats(arg0)
{
    var url = global.supabase_url + "/rest/v1/levels?author_id=eq." + arg0 + "&select=id,downloads,level_likes(count)";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}

// badges
// la tabla badges tiene la definicion y user_badges quien lo tiene puesto.
// se asignan a mano desde el panel de admin.
// lista completa de badges que existen, para el panel de admin.
function scr_get_all_badges()
{
    var url = global.supabase_url + "/rest/v1/badges?select=id,name,icon_name,color&order=id.asc";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// le pone un badge a un usuario.
function scr_award_badge(arg0, arg1)
{
    if (!global.user_is_admin)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/user_badges";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    ds_map_add(headers, "Prefer", "return=representation");
    var body = json_stringify(
    {
        ub_user_id: arg0,
        badge_id: arg1,
        awarded_by: global.user_id
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// arg0 es el id de la fila de user_badges, no el id del badge.
function scr_remove_badge(arg0)
{
    if (!global.user_is_admin)
        return -1;
    
    arg0 = scr_clean_json_string(string(arg0));
    var url = global.supabase_url + "/rest/v1/user_badges?id=eq." + arg0;
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    ds_map_add(headers, "Prefer", "return=minimal");
    var request = http_request(url, "DELETE", headers, "");
    ds_map_destroy(headers);
    return request;
}
// los indices de sprite estan escritos a mano. si se reordenan los sprites del proyecto estos
// numeros dejan de apuntar a donde tienen que apuntar.
function scr_get_badge_sprite(arg0)
{
    arg0 = scr_clean_json_string(arg0);
    arg0 = string_lower(arg0);
    
    switch (arg0)
    {
        case "shield":
            return 2560;
        
        case "star":
            return 2579;
        
        case "layers":
            return 2579;
        
        case "heart":
            return 2583;
        
        case "crown":
            return 2561;
        
        default:
            return 2579;
    }
}
function scr_get_badge_color(arg0)
{
    arg0 = scr_clean_json_string(arg0);
    arg0 = string_lower(arg0);
    
    switch (arg0)
    {
        case "shield":
            return make_colour_rgb(100, 200, 255);
        
        case "star":
            return make_colour_rgb(255, 165, 0);
        
        case "layers":
            return make_colour_rgb(255, 165, 0);
        
        case "heart":
            return make_colour_rgb(148, 0, 211);
        
        case "crown":
            return make_colour_rgb(220, 20, 60);
        
        default:
            return make_colour_rgb(255, 215, 0);
    }
}





// sesion y datos
// pide un access token nuevo usando el refresh token guardado. es lo que mantiene la sesion
// viva entre partidas sin volver a pedir la pass(los tokens de supabase duran 1hr aprox, bastante poco)
// si el refresh token esta vacio o quedo en 0 marca al usuario como deslogueado y yata.
function scr_supabase_refresh_session()
{
    if (global.user_refresh_token == "" || global.user_refresh_token == "0")
    {
        show_debug_message("REFRESH: No hay refresh token válido.");
        global.user_logged_in = false;
        return -1;
    }
    
    var _url = global.supabase_url + "/auth/v1/token?grant_type=refresh_token";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{\"refresh_token\":\"" + string(global.user_refresh_token) + "\"}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    global.request_refresh = _request;
    show_debug_message("REFRESH: Enviando request " + string(_request));
    return _request;
}
// pregunta si el usuario esta en la tabla admins
function scr_supabase_check_is_admin()
{
    var _url = global.supabase_url + "/rest/v1/admins?user_id=eq." + global.user_id + "&select=user_id";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    global.request_check_admin = _request;
    return _request;
}
// un solo pedido que trae todo lo que hace falta al abrir el juego
function scr_supabase_get_startup_data()
{
    var _url = global.supabase_url + "/rest/v1/rpc/get_startup_data";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _request = http_request(_url, "POST", _headers, "");
    ds_map_destroy(_headers);
    global.request_startup_data = _request;
    show_debug_message("STARTUP: Enviando request " + string(_request));
    return _request;
}


// moderacion
function scr_supabase_delete_level(arg0)
{
    if (!global.user_is_admin)
    {
        show_message_extra("No tienes permisos de administrador.");
        return -1;
    }
    
    // el borrado va por rpc: el delete directo por rest no borraba la fila
    // (rls sin policy de delete o tablas hijas con fk) y devolvia 204 igual,
    // asi que parecia que andaba y no andaba
    var _url = global.supabase_url + "/rest/v1/rpc/delete_level";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _request = http_request(_url, "POST", _headers, "{\"p_level_id\":" + string(int64(arg0)) + "}");
    ds_map_destroy(_headers);
    return _request;
}



// sistema de baneos
// los bans viven en user_bans marcados con is_active. pueden ser permanentes o tener
// vencimiento en expires_at, y el chequeo contempla los dos casos.
// desbanear no borra la fila, nomas la apaga.
// trae el ban activo del usuario, si tiene. filtra por is_active y ademas descarta los que ya
// vencieron, asi que si devuelve algo el tipo esta baneado ahora mismo.
function scr_supabase_get_user_ban(arg0)
{
    var _url = global.supabase_url + "/rest/v1/user_bans?user_id=eq." + arg0 + "&is_active=eq.true&or=(expires_at.is.null,expires_at.gt.now())&select=reason,created_at,expires_at,profiles!user_bans_admin_id_fkey(username)";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}
// crea el ban con motivo y vencimiento. si el vencimiento va vacio el ban es permanente.
function scr_supabase_ban_user(arg0, arg1, arg2)
{
    if (!global.user_is_admin)
    {
        show_message_extra("No tienes permisos de administrador.");
        return -1;
    }
    
    var _url = global.supabase_url + "/rest/v1/user_bans";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "Prefer", "return=representation");
    var _body = ds_map_create();
    ds_map_add(_body, "user_id", arg0);
    ds_map_add(_body, "admin_id", global.user_id);
    ds_map_add(_body, "reason", arg1);
    
    if (arg2 != "")
        ds_map_add(_body, "expires_at", arg2);
    
    var _json_body = json_encode(_body);
    ds_map_destroy(_body);
    var _request = http_request(_url, "POST", _headers, _json_body);
    ds_map_destroy(_headers);
    return _request;
}
// apaga el ban poniendo is_active en false. la fila queda para tener el historial.
function scr_supabase_unban_user(arg0)
{
    var _url = global.supabase_url + "/rest/v1/user_bans?user_id=eq." + arg0 + "&is_active=eq.true";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = ds_map_create();
    ds_map_add(_body, "is_active", false);
    var _json_body = json_encode(_body);
    ds_map_destroy(_body);
    var _request = http_request(_url, "PATCH", _headers, _json_body);
    ds_map_destroy(_headers);
    return _request;
}
function scr_get_future_date_iso(days_to_add) 
{
    // calcula la fecha actual + los dias elegidos y la formatea para la base de datos
    var d = date_inc_day(date_current_datetime(), days_to_add);
    
    var yy = string(date_get_year(d));
    var mm = string_replace(string_format(date_get_month(d), 2, 0), " ", "0");
    var dd = string_replace(string_format(date_get_day(d), 2, 0), " ", "0");
    var hh = string_replace(string_format(date_get_hour(d), 2, 0), " ", "0");
    var mins = string_replace(string_format(date_get_minute(d), 2, 0), " ", "0");
    var ss = string_replace(string_format(date_get_second(d), 2, 0), " ", "0");

return yy + "-" + mm + "-" + dd + "T" + hh + ":" + mins + ":" + ss + "+00:00";
}
