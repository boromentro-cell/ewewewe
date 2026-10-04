// login y registro
// entrada unica de auth: arg0 elige si es login o registro y cada rama va a un endpoint
// distinto. las dos dejan escritos last_login_email y last_login_pass, que es de donde los
// agarra el quick login para guardar la cuenta despues.
function scr_supabase_auth(arg0, arg1, arg2, arg3 = "")
{
    var _url, _body;
    
    switch (arg0)
    {
        case "login":
            _url = global.supabase_url + "/auth/v1/token?grant_type=password";
            _body = json_stringify(
            {
                email: arg1,
                password: arg2
            });
            // quedan guardados para que save_session pueda escribir la cuenta despues.
            // en el registro no hacen falta porque el login viene atras
            global.last_login_email = arg1;
            global.last_login_pass = arg2;
            break;
        
        case "register":
            _url = global.supabase_url + "/auth/v1/signup";
            _body = json_stringify(
            {
                email: arg1,
                password: arg2,
                data: 
                {
                    username: arg3
                }
            });
            break;
        
        default:
            show_debug_message("ERROR: Modo inválido en scr_supabase_auth");
            return -1;
    }
    
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    
    // cada modo deja su request en una global distinta, el async las compara
    // para saber cual volvio
    if (arg0 == "login")
        global.request_login = _request;
    else
        global.request_register = _request;
    
    return _request;
}





// sesion guardada
// la sesion vive en user_session.ini. el access token dura poco, asi que lo que realmente
// sirve al abrir el juego es el refresh token.
// borra las globals del usuario y vacia user_session.ini. no toca las cuentas del quick login.
function scr_supabase_logout()
{
    global.user_token = "";
    global.user_id = "";
    global.user_name = "";
    global.user_logged_in = false;
	global.user_is_admin = false
    ini_open("user_session.ini");
    ini_write_string("session", "token", "");
    ini_write_string("session", "user_id", "");
    ini_write_string("session", "user_name", "");
    ini_close();
    return 1;
}
// guarda la sesion en user_session.ini y ademas suma la cuenta a la lista del quick login.
function scr_supabase_save_session()
{
    ini_open("user_session.ini");
    ini_write_string("session", "token", global.user_token);
    ini_write_string("session", "refresh_token", global.user_refresh_token);
    ini_write_string("session", "user_id", global.user_id);
    ini_write_string("session", "user_name", global.user_name);
    ini_close();
    var _is_admin = false;
    
    if (variable_global_exists("user_is_admin"))
        _is_admin = global.user_is_admin;
    
    ini_open("saved_accounts.ini");
    // los usuarios comunes llegan hasta dos cuentas guardadas, los admin no tienen tope
    var _count = ini_read_real("accounts", "count", 0);
    ini_close();
    
    if (_is_admin || _count < 2)
    {
        var _has_valid_data = global.user_name != "" && variable_global_exists("last_login_pass") && global.last_login_pass != "";
        
        if (_has_valid_data)
        {
            ini_open("saved_accounts.ini");
            var _found = -1;
            
            for (var _i = 0; _i < _count; _i++)
            {
                var _saved_user = ini_read_string("account_" + string(_i), "user_name", "");
                
                // si ya estaba se pisa la entrada en vez de sumar una repetida
                if (string_lower(_saved_user) == string_lower(global.user_name))
                {
                    _found = _i;
                    break;
                }
            }
            
            if (_found == -1)
            {
                if (_is_admin || _count < 2)
                {
                    _found = _count;
                    ini_write_real("accounts", "count", _count + 1);
                }
            }
            
            if (_found != -1)
            {
                var _section = "account_" + string(_found);
                // el login del juego es por nombre de usuario, el mail se arma solo
                // para no tener que pedir que se registren con mail
                var _fake_email = string_lower(global.user_name) + "@sm4j.game";
                ini_write_string(_section, "email", _fake_email);
                ini_write_string(_section, "pass", scr_simple_encrypt(global.last_login_pass));
                ini_write_string(_section, "user_name", global.user_name);
                ini_write_string(_section, "user_id", global.user_id);
            }
            
            ini_close();
            scr_register_device_account();
        }
    }
    
    return 1;
}
// levanta la sesion del ini al abrir el juego y devuelve el request del refresh, porque el
// token guardado casi siempre ya vencio.
function scr_supabase_load_session()
{
    ini_open("user_session.ini");
    global.user_token = ini_read_string("session", "token", "");
    global.user_refresh_token = ini_read_string("session", "refresh_token", "");
    global.user_id = ini_read_string("session", "user_id", "");
    global.user_name = ini_read_string("session", "user_name", "");
    ini_close();
    
    if (global.user_refresh_token != "" && global.user_id != "")
    {
        global.user_logged_in = true;
        var _refresh_request = scr_supabase_check_and_refresh();
        return _refresh_request;
    }
    
    global.user_logged_in = false;
    global.user_token = "";
    global.user_refresh_token = "";
    global.user_id = "";
    global.user_name = "";
    return -1;
}



// quick login
// las cuentas ya usadas quedan en saved_accounts.ini para poder entrar sin escribir la pass.
// van numeradas de 0 en adelante y la contraseña se guarda ofuscada.
// corre cada caracter 47 lugares y lo pasa a base64. es solo para que la pass no quede a la
// vista abriendo el ini con un bloc de notas, no es seguridad de verdad.
function scr_simple_encrypt(arg0)
{
    var _result = "";
    var _key = 47;
    
    for (var _i = 1; _i <= string_length(arg0); _i++)
    {
        var _c = ord(string_char_at(arg0, _i));
        _c = _c + _key;
        _result += chr(_c);
    }
    
    return base64_encode(_result);
}
function scr_simple_decrypt(arg0)
{
    var _decoded = base64_decode(arg0);
    var _result = "";
    var _key = 47;
    
    for (var _i = 1; _i <= string_length(_decoded); _i++)
    {
        var _c = ord(string_char_at(_decoded, _i));
        _c = _c - _key;
        _result += chr(_c);
    }
    
    return _result;
}
// devuelve una ds_list de ds_map con las cuentas guardadas. las pass vienen encriptadas, hay
// que pasarlas por scr_simple_decrypt antes de usarlas.
function scr_get_saved_accounts()
{
    var _accounts = ds_list_create();
    ini_open("saved_accounts.ini");
    var _count = ini_read_real("accounts", "count", 0);
    
    for (var _i = 0; _i < _count; _i++)
    {
        var _section = "account_" + string(_i);
        var _acc = ds_map_create();
        ds_map_add(_acc, "email", ini_read_string(_section, "email", ""));
        ds_map_add(_acc, "pass", ini_read_string(_section, "pass", ""));
        ds_map_add(_acc, "user_name", ini_read_string(_section, "user_name", ""));
        ds_map_add(_acc, "index", _i);
        ds_list_add(_accounts, _acc);
    }
    
    ini_close();
    return _accounts;
}
// entra con una cuenta guardada, desencriptando la pass primero.
function scr_quick_login(arg0)
{
    var _email = ds_map_find_value(arg0, "email");
    var _pass_encrypted = ds_map_find_value(arg0, "pass");
    var _pass = scr_simple_decrypt(_pass_encrypted);
    global.last_login_email = _email;
    global.last_login_pass = _pass;
    return scr_supabase_login(_email, _pass);
}
// borra una cuenta y corre todas las de abajo un lugar, asi no quedan huecos en la numeracion
// de las secciones del ini.
function scr_remove_saved_account(arg0)
{
    ini_open("saved_accounts.ini");
    var count = ini_read_real("accounts", "count", 0);
    
    if (arg0 < 0 || arg0 >= count)
    {
        ini_close();
        return 0;
    }
    
    for (var i = arg0; i < (count - 1); i++)
    {
        var next_email = ini_read_string("account_" + string(i + 1), "email", "");
        var next_pass = ini_read_string("account_" + string(i + 1), "pass", "");
        var next_name = ini_read_string("account_" + string(i + 1), "user_name", "");
        ini_write_string("account_" + string(i), "email", next_email);
        ini_write_string("account_" + string(i), "pass", next_pass);
        ini_write_string("account_" + string(i), "user_name", next_name);
    }
    
    ini_write_real("accounts", "count", count - 1);
    ini_close();
    return 1;
}
// login directo con mail y pass.
function scr_supabase_login(arg0, arg1)
{
    global.last_login_email = arg0;
    global.last_login_pass = arg1;
    var _url = global.supabase_url + "/auth/v1/token?grant_type=password";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Content-Type", "application/json");
    var _body = "{\"email\":\"" + string(arg0) + "\",\"password\":\"" + string(arg1) + "\"}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    global.request_login = _request;
    return _request;
}



// refresh del token
// lo llamamos en el peersistent cuando abrimos el juego (o bueno, el persistent crea el manager)
// si no hay refresh token guardado devuelve -2 y hay que mandar al login,
// si hay dispara el refresh y devuelve el request.
function scr_supabase_check_and_refresh()
{
    if (global.user_refresh_token == "" || global.user_refresh_token == "0")
    {
        global.user_logged_in = false;
        return -2;
    }
    
    return scr_supabase_refresh_session();
}



// device id
// outdated, tengo que rehacerlo mejor en algun momento, no es muy bueno xd.
function scr_get_device_id()
{
    var device_id = "";
    ini_open("device_info.ini");
    device_id = ini_read_string("device", "id", "");
    ini_close();
    
    if (device_id == "")
    {
        var base_string = "";
        base_string += string(os_type);
        base_string += string(os_version);
        base_string += "-1";
        base_string += string(display_get_width());
        base_string += string(display_get_height());
        base_string += string(current_time);
        // se genera una vez y queda en el ini, es lo que ata las cuentas al aparato
        base_string += string(random(999999));
        device_id = md5_string_unicode(base_string);
        ini_open("device_info.ini");
        ini_write_string("device", "id", device_id);
        ini_close();
    }
    
    return device_id;
}
// trae que cuentas hay atadas a este aparato, para cortar el registro si son demasiadas.
function scr_check_device_limit()
{
    var device_id = scr_get_device_id();
    var url = global.supabase_url + "/rest/v1/device_accounts?select=user_id&device_id=eq." + device_id;
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// ata la cuenta recien creada al device id. lo llama scr_supabase_save_session al final.
function scr_register_device_account()
{
    if (!global.user_logged_in)
        return -1;
    
    var device_id = scr_get_device_id();
    var url = global.supabase_url + "/rest/v1/device_accounts";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    ds_map_add(headers, "Prefer", "return=minimal");
    var body = json_stringify(
    {
        device_id: device_id,
        user_id: global.user_id
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// borra las cuentas atadas al aparato y ademas resetea el device id y la lista de guardadas,
// o sea que deja todo como recien instalado.
function scr_clear_device_accounts()
{
    var device_id = scr_get_device_id();
    var url = global.supabase_url + "/rest/v1/device_accounts?device_id=eq." + device_id;
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "DELETE", headers, "");
    ds_map_destroy(headers);
    ini_open("device_info.ini");
    ini_write_string("device", "id", "");
    ini_close();
    ini_open("saved_accounts.ini");
    ini_write_real("accounts", "count", 0);
    ini_close();
    show_debug_message("ADMIN: Device ID limpiado");
    return request;
}



// discord y recupero de contraseña
// el vinculo con discord se hace con un codigo de un solo uso que el bot lee del otro lado.
// para cambiar la contraseña se hace lo mismo... en otra tabla

// genera un codigo, lo manda a la rpc que borra el viejo y guarda el nuevo en discord_link_codes.
// el usuario lo pega en el bot y el vinculo se cierra del lado del server.
function scr_request_discord_link()
{
    if (!global.user_logged_in)
        return -1;
    
    var code = scr_generate_link_code();
    global.discord_link_code = code;
    var url = global.supabase_url + "/rest/v1/rpc/request_link_code";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_code: code
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// pregunta si el perfil ya tiene discord vinculado.
function scr_check_discord_linked()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/profiles?p_user_id=eq." + global.user_id + "&select=discord_id,discord_username";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    global.request_check_discord = request;
    return request;
}
// solo devuelve el codigo si no fue usado todavia y no vencio.
// pasa por rpc porque la tabla no se puede leer mas directo
function scr_verify_reset_code(arg0)
{
    arg0 = string_upper(arg0);
    var url = global.supabase_url + "/rest/v1/rpc/verify_reset_code";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_code: arg0
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// marcamos el codigo para que no se pueda usar dos veces.
// pasa por rpc porque la tabla no se puede tocar mas directo
function scr_mark_reset_code_used(arg0)
{
    arg0 = string_upper(arg0);
    var url = global.supabase_url + "/rest/v1/rpc/mark_reset_code_used";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_code: arg0
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
// cambia la pass con el codigo ya verificado.
function scr_reset_password(arg0, arg1)
{
    var url = global.supabase_url + "/functions/v1/reset-password";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        code: arg0,
        new_password: arg1
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}
function scr_generate_link_code()
{
    // sin esto los codigos salen siempre en el mismo orden y chocan en la tabla
    randomize();
    var chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    var code = "";
    var len = string_length(chars);
    
    for (var i = 0; i < 6; i++)
    {
        var random_index = irandom(len - 1) + 1;
        code += string_char_at(chars, random_index);
    }
    
    return code;
}
