// listado de niveles
// listado principal del browser. arg2 es el orden (recent, downloads o total_likes), y arg3 y
// arg4 filtran por nombre y por autor si vienen con algo.
// las listas sin filtros salen del catalogo estatico en r2 (no gastan supabase).
// arg5 fuerza supabase: lo usa el fallback cuando el catalogo falla
function scr_supabase_get_levels(arg0, arg1, arg2, arg3 = "", arg4 = "", arg5 = false)
{
    // si se acaba de borrar un nivel, por un rato todo se pide en vivo y no
    // del catalogo estatico del cdn, que tarda en regenerarse tras un borrado
    if (variable_global_exists("browser_forzar_fresco") && global.browser_forzar_fresco > current_time)
        arg5 = true;
    
    var _offset = arg0 * arg1;
    var _catalog_key = "";
    
    if (!arg5 && arg3 == "" && arg4 == "" && arg0 < 3)
    {
        switch (arg2)
        {
            case "popular":
            case "downloads":
                _catalog_key = "downloads";
                break;
            
            case "likes":
            case "total_likes":
                _catalog_key = "likes";
                break;
            
            default:
                _catalog_key = "recent";
                break;
        }
    }
    
    var _url;
    
    if (_catalog_key != "")
        _url = global.r2_levels_url + "/catalog/" + _catalog_key + "_p" + string(arg0) + ".json";
    else
    {
        _url = global.supabase_url + "/rest/v1/rpc/get_levels_browser?select=*";
        
        switch (arg2)
        {
            case "popular":
            case "downloads":
                _url += "&order=downloads.desc";
                break;
            
            case "likes":
            case "total_likes":
                _url += "&order=total_likes.desc";
                break;
            
            default:
                _url += "&order=created_at.desc";
                break;
        }
        
        if (arg3 != "")
            _url += ("&name=ilike.*" + string(arg3) + "*");
        
        if (arg4 != "")
            _url += ("&author_name=ilike.*" + string(arg4) + "*");
        
        _url += ("&limit=" + string(arg1));
        _url += ("&offset=" + string(_offset));
    }
    
    var _headers = ds_map_create();
    
    if (_catalog_key == "")
    {
        ds_map_add(_headers, "apikey", global.supabase_key);
        
        if (variable_global_exists("user_logged_in") && global.user_logged_in)
            ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
        else
            ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    }
    
    //troll
    ds_map_add(_headers, "User-Agent", "SM4J_Anti_Cheat_System_v9.0_OWO");
    ds_map_add(_headers, "X-Secret-Token-DONT-SHARE", "bW1tX21hbl9pX2RvX2xvdmVfZmlkZGxlcg==");
    ds_map_add(_headers, "X-Message", "hola :d");
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    global.request_levels = _request;
    global.catalog_inflight = (_catalog_key != "");
    return _request;
}





// reportes
// se acumulan en level_reports y el panel de admin los lee ordenados por cantidad.
// suma un reporte al nivel con el motivo que puso el usuario.
function scr_supabase_report_level(arg0, arg1)
{
    var _url = global.supabase_url + "/rest/v1/level_reports";
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    
    if (variable_global_exists("user_logged_in") && global.user_logged_in)
        ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    else
        ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "Prefer", "return=minimal");
    var _body = "{\"level_id\":" + string(arg0) + ",\"reporter_user_id\":\"" + string(arg1) + "\"}";
    var _request = http_request(_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}
// borra todos los reportes del nivel. no restaura el nivel en si, el nivel nunca se borro:
// lo que hace es sacarlo de la lista de reportados del panel.
function scr_supabase_restore_level(arg0)
{
    if (!variable_global_exists("user_is_admin") || !global.user_is_admin)
    {
        show_message_extra("No tienes permisos de administrador.");
        return -1;
    }
    
    var _url = global.supabase_url + "/rest/v1/level_reports?level_id=eq." + string(arg0);
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(_url, "DELETE", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}
// lista de reportados ordenada por cantidad de reportes, paginada.
function scr_supabase_get_reported_levels(arg0, arg1)
{
    var _offset = arg0 * arg1;
    var _url = global.supabase_url + "/rest/v1/reported_levels_view?select=*";
    _url += "&order=report_count.desc";
    _url += ("&limit=" + string(arg1));
    _url += ("&offset=" + string(_offset));
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    
    if (variable_global_exists("user_logged_in") && global.user_logged_in)
        ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    else
        ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}


// cold storage en telegram
// los niveles que no quedan en r2 se guardan en telegram a traves de un worker propio.
// de ahi salen los cold_storage_id que aparecen en el listado.
// manda el archivo al worker de telegram. el body va como buffer crudo, no como json, por eso
// carga el archivo con buffer_load y lo borra despues de mandarlo.
function scr_upload_level_to_telegram(arg0, arg1)
{
    if (!file_exists(arg0))
    {
        show_debug_message("Error: El archivo no existe: " + arg0);
        return -1;
    }
    
    var _buffer = buffer_load(arg0);
    var _url = global.worker_telegram_url;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", arg1);
    ds_map_add(_headers, "X-Action", "upload");
    
    if (variable_global_exists("user_token") && global.user_token != "")
        ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    
    var _request = http_request(_url, "POST", _headers, _buffer);
    ds_map_destroy(_headers);
    buffer_delete(_buffer);
    return _request;
}
// pide al worker la url de descarga de un nivel que quedo guardado en telegram.
function scr_request_level_download_url(arg0, arg1, arg2 = false)
{
    var _url = global.worker_telegram_url;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", string(arg0));
    ds_map_add(_headers, "X-Action", "download");
    
    if (arg1 != "" && !is_undefined(arg1) && arg1 != "null")
        ds_map_add(_headers, "X-Cold-Storage-Id", string(arg1));

    if (arg2)
        ds_map_add(_headers, "X-Skip-Catbox", "1");
    
    var _request = http_request(_url, "POST", _headers, "");
    ds_map_destroy(_headers);
    return _request;
}



// relleno de r2 cuando una descarga salio de catbox. el worker no puede hablar con
// catbox desde cloudflare, asi que el que la bajo la devuelve una vez y de ahi en
// mas sale de r2. la respuesta no se espera, se manda y se olvida
function scr_r2_cache_fill(arg0, arg1, arg2)
{
    if (!file_exists(arg0))
        return -1;
    
    // sin login no hay cachefill: el worker pide token
    if (!variable_global_exists("user_logged_in") || !global.user_logged_in)
        return -1;
    
    var _buffer = buffer_load(arg0);
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", arg1);
    ds_map_add(_headers, "X-Action", "cachefill");
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    var _request = http_request(arg2, "POST", _headers, _buffer);
    ds_map_destroy(_headers);
    buffer_delete(_buffer);
    return _request;
}


// pide al worker todo lo frio de un nivel en una sola request: el archivo,
// la textura y los customs. el worker busca cada cosa en r2 y lo que
// falte lo baja del frio el mismo, asi la jugada fria entera cuesta una
// request y todo queda caliente para el siguiente
function scr_bundle_request(arg0, arg1)
{
    var _body = "{\"file_name\":\"" + arg0 + "\",\"cold_storage_id\":\"" + arg1 + "\"}";
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "X-Action", "bundle");
    var _request = http_request(global.worker_telegram_url, "POST", _headers, _body);
    ds_map_destroy(_headers);
    return _request;
}



// modo mantenimiento
/*
cada vez abrimos el juego, se pregunta al bucket de r2 si estamos en modo mantenimiento (ya que eso es algo que nunca se puede caer)
se consulta un archivo llamado flags.json, adentro simplemente ava a haber un true o un false. si estamos en modo mantenimiento
cargamos el backup de TODA la lista de niveles para que aun asi se puedan jugar
*/
// pide el flag de mantenimiento al cdn
function scr_maintenance_check()
{
    show_debug_message("MANTENIMIENTO: consultando flag al inicio...");
    var _headers = ds_map_create();
    ds_map_add(_headers, "Cache-Control", "no-cache");
    var _req = http_request(global.r2_levels_url + "/catalog/flags.json", "GET", _headers, "");
    ds_map_destroy(_headers);
    return _req;
}

// consultamos la snapshot con toda la info de los niveles
function scr_maintenance_download_full()
{
    var _headers = ds_map_create();
    var _req = http_request(global.r2_levels_url + "/catalog/full.json", "GET", _headers, "");
    ds_map_destroy(_headers);
    return _req;
}

// true si el snapshot de esta ventana ya se bajo y sigue en eldisco
function scr_maintenance_tiene_snapshot_local()
{
    ini_open("cache_info.ini");
    var _ya = ini_read_real("flags", "mant_full", 0);
    ini_close();
    
    if (_ya != 1)
        return false;
    
    return scr_load_list_cache("mantenimiento_full") != "";
}

// marca si el snapshot de esta ventana ya se bajo
function scr_maintenance_marcar_snapshot(arg0)
{
    ini_open("cache_info.ini");
    
    if (arg0)
        ini_write_real("flags", "mant_full", 1);
    else
        ini_write_real("flags", "mant_full", 0);
    
    ini_close();
}


function scr_maintenance_async_boot(arg0)
{
    if (!variable_global_exists("mantenimiento_request_flags"))
        return false;
    
    var _id = ds_map_find_value(arg0, "id");
    var _status = ds_map_find_value(arg0, "status");
    
    // la respuesta del flag
    if (global.mantenimiento_request_flags != -1 && _id == global.mantenimiento_request_flags)
    {
        if (_status == 1)
            return true;
        
        global.mantenimiento_request_flags = -1;
        var _result = ds_map_find_value(arg0, "result");
        
        if (_status == 0 && is_string(_result) && string_pos("\"mantenimiento\":true", string_replace_all(_result, " ", "")) > 0)
        {
            global.mantenimiento_activo = true;
            show_debug_message("MANTENIMIENTO: flag prendido al inicio");
            
            // el snapshot se baja una sola vez por ventana, al arrancar
            if (!scr_maintenance_tiene_snapshot_local())
            {
                show_debug_message("MANTENIMIENTO: bajando snapshot");
                global.mantenimiento_request_full = scr_maintenance_download_full();
            }
        }
        else
        {
            global.mantenimiento_activo = false;
            show_debug_message("MANTENIMIENTO: flag apagado, modo normal");
            
            // si la snapshot es vieja reemplazamos
            if (scr_maintenance_tiene_snapshot_local())
            {
                scr_maintenance_marcar_snapshot(false);
                scr_save_list_cache("mantenimiento_full", "");
                show_debug_message("MANTENIMIENTO: flag apagado, snapshot limpiado");
            }
        }
        
        return true;
    }
    
    // la respuesta de la snapshot
    if (global.mantenimiento_request_full != -1 && _id == global.mantenimiento_request_full)
    {
        if (_status == 1)
            return true;
        
        global.mantenimiento_request_full = -1;
        var _result2 = ds_map_find_value(arg0, "result");
        var _http_st = ds_map_find_value(arg0, "http_status");
        
        if (is_undefined(_http_st))
            _http_st = 200;
        
        if (_status == 0 && _http_st == 200 && is_string(_result2) && string_pos("[", _result2) == 1)
        {
            scr_save_list_cache("mantenimiento_full", _result2);
            scr_maintenance_marcar_snapshot(true);
            global.mantenimiento_raw = _result2;
            show_debug_message("MANTENIMIENTO: snapshot guardado");
        }
        else
        {
            // si la snapshot falla se apaga el modo y el browser va por el camino normal
            global.mantenimiento_activo = false;
            show_debug_message("MANTENIMIENTO: fallo el snapshot, camino normal");
        }
        
        return true;
    }
    
    return false;
}

// entra la snapshot (de la red o del disco) y deja el browser trabajando local
function scr_maintenance_poblar_browser(arg0)
{
    global.mantenimiento_raw = arg0;
    scr_maintenance_aplicar_vista();
    show_debug_message("MANTENIMIENTO: browser local con " + string(ds_list_size(global.id_levels)) + " niveles");
    show_message_async("Estamos en mantenimiento, mientras tanto podes jugar los niveles ya subidos");
}

// llena el browser desde el snapshot local sin consultar la db
function scr_maintenance_aplicar_vista()
{
    if (!variable_global_exists("mantenimiento_raw"))
        exit;
    
    with (obj_level_loader)
    {
        scr_browser_clear_lists(true);
        scroll_y = 0;
        global.page = 0;
        total_cards_created = 0;
        total_levels_loaded = 0;
        
        var _lista = scr_json_parse_array(global.mantenimiento_raw);
        var _count = ds_list_size(_lista);
        
        // orden local
        if (global.sort == "total_likes" || global.sort == "likes" || global.sort == "downloads" || global.sort == "popular")
        {
            var _campo = "downloads";
            
            if (global.sort == "total_likes" || global.sort == "likes")
                _campo = "total_likes";
            
            for (var _i = 0; _i < _count - 1; _i++)
            {
                for (var _j = 0; _j < _count - _i - 1; _j++)
                {
                    var _a = ds_list_find_value(_lista, _j);
                    var _b = ds_list_find_value(_lista, _j + 1);
                    
                    if (scr_num_or_zero(ds_map_find_value(_a, _campo)) < scr_num_or_zero(ds_map_find_value(_b, _campo)))
                    {
                        ds_list_replace(_lista, _j, _b);
                        ds_list_replace(_lista, _j + 1, _a);
                    }
                }
            }
        }
        
        // filtro local por nombre y autor
        var _nf = string_lower(global.name_s);
        var _af = string_lower(global.autor_s);
        
        for (var _i = 0; _i < _count; _i++)
        {
            var _m = ds_list_find_value(_lista, _i);
            var _nom = string_lower(string(ds_map_find_value(_m, "name")));
            var _aut = string_lower(string(ds_map_find_value(_m, "author_name")));
            
            if (_nf != "" && string_pos(_nf, _nom) == 0)
                continue;
            
            if (_af != "" && string_pos(_af, _aut) == 0)
                continue;
            
            scr_browser_push_level(_m);
        }
        
        ds_list_destroy(_lista);
        
        total_levels_loaded = ds_list_size(global.id_levels);
        global.end_of_results = true; // esta todo local, el scroll no pide mas
        loading = false;
        initial_load_complete = true;
        scr_browser_create_cards(0, min(8, total_levels_loaded));
    }
}
