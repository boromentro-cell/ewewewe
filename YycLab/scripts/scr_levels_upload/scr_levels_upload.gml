/*
  subida de niveles y todo lo que arrastra: assets del workshop que usa el nivel,
  perfil propio y la descarga de los customs cuando alguien abre un nivel ajeno.
*/





// subida de niveles
// primero van el archivo y la miniatura al worker de r2, y recien despues se da de alta la
// fila en la tabla con los nombres que quedaron.
// da de alta la fila del nivel. el archivo y la miniatura ya tienen que estar arriba en r2
// aca nomas guardamos nombres
function scr_supabase_upload_level(arg0, arg1, arg2, arg3, arg4, arg5 = "vanilla", arg6 = "", arg7 = "", arg8 = "[]")
{
    var _url = global.supabase_url + "/rest/v1/levels";
    // los tags se pasan a string uno por uno, si viene un numero json_stringify
    // lo manda sin comillas y la columna lo rechaza
    var _safe_tags = [];
    
    if (is_array(arg4))
    {
        for (var i = 0; i < array_length(arg4); i++)
            array_push(_safe_tags, string(arg4[i]));
    }
    
    var _texture_used = (arg5 != "") ? string(arg5) : "vanilla";
    var _payload = 
    {
        name: string(arg0),
        description: string(arg1),
        author_id: global.user_id,
        author_name: global.user_name,
        file_name: string(arg2),
        thumbnail_name: string(arg3),
        tags: _safe_tags,
        likes: 0,
        downloads: 0,
        texture_used: _texture_used
    };
    
    if (arg6 != "" && arg6 != "null" && !is_undefined(arg6))
        variable_struct_set(_payload, "cold_storage_id", string(arg6));
    
    var _json_string = json_stringify(_payload);
    // gm es muy gracioso y los escribe como 0.0, y los interger necesitan 0
    _json_string = string_replace_all(_json_string, ":0.0,", ":0,");
    _json_string = string_replace_all(_json_string, ":0.0}", ":0}");
    
    var _extras = "";
    
    if (arg7 != "" && arg7 != "0")
        _extras += ",\"texture_workshop_id\":" + string(floor(real(arg7)));
    
    if (arg8 != "" && arg8 != "[]")
        _extras += ",\"custom_objects_used\":" + arg8;
    
    // estos dos se pegan a mano al json, se saca la llave del final y se cierra de nuevo
    if (_extras != "")
    {
        _json_string = string_copy(_json_string, 1, string_length(_json_string) - 1);
        _json_string += _extras + "}";
    }
    
    scr_debug_log("SUPABASE UPLOAD BODY: " + _json_string);
    
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/json");
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(_headers, "Prefer", "return=representation");
    var _request_id = http_request(_url, "POST", _headers, _json_string);
    ds_map_destroy(_headers);
    return _request_id;
}
// manda el archivo al worker como buffer crudo, no como json. el worker se encarga de ponerlo
// en el bucket que corresponda.
function scr_upload_file_to_r2(arg0, arg1, arg2)
{
    if (!file_exists(arg0))
    {
        show_debug_message("Error: El archivo no existe: " + arg0);
        return -1;
    }
    
    // el body va como buffer crudo, no como json
    var _buffer = buffer_load(arg0);
    var _url = global.worker_upload_url;
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", arg1);
    ds_map_add(_headers, "X-Bucket", arg2);
    
    if (variable_global_exists("user_token") && global.user_token != "")
        ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    
    var _request = http_request(_url, "POST", _headers, _buffer);
    ds_map_destroy(_headers);
    // se borra apenas se manda, http_request ya se quedo con lo suyo
    buffer_delete(_buffer);
    return _request;
}





// deteccion de assets del workshop
// antes de subir se mira que textura y que customs usa el nivel, para guardar sus workshop_id
// junto al nivel y que despues el que lo descargue se los baje solo.
function scr_detect_workshop_texture()
{
    var _result = { found: false, workshop_id: "", name: "", author: "" };
    
    // que textura esta cargada?
    if (!file_exists("textura_cargar.ini"))
    {
        scr_debug_log("DETECT TEX: No existe textura_cargar.ini");
        return _result;
    }
    
    ini_open("textura_cargar.ini");
    var _tex_name = ini_read_string("textura", "textura", "");
    ini_close();
    
    // vanilla no es un pack, se corta aca y el nivel sube sin textura asociada
    if (_tex_name == "" || string_lower(_tex_name) == "vanilla")
    {
        scr_debug_log("DETECT TEX: Textura vanilla o vacía");
        return _result;
    }
    
    scr_debug_log("DETECT TEX: Buscando workshop_id para '" + _tex_name + "'");
    var _clean = _tex_name;
    _clean = string_replace_all(_clean, ".zip", "");
    _clean = string_replace_all(_clean, ".ZIP", "");
    
    // paths posibles donde puede estar la textura
    // la textura puede estar suelta o extraida de un zip, se prueban los tres lugares
    var _paths = [];
    array_push(_paths, working_directory + "Texturas_manual/" + _tex_name + "/");
    array_push(_paths, working_directory + "Texturas_manual/" + _clean + "/");
    array_push(_paths, working_directory + "Texture_cache_extracted/" + _clean + "/");
    
    for (var i = 0; i < array_length(_paths); i++)
    {
        var _base = _paths[i];
        
        if (!directory_exists(_base))
            continue;
        
        // buscar workshop_id.ini en raiz
        if (file_exists(_base + "workshop_id.ini"))
        {
            ini_open(_base + "workshop_id.ini");
            _result.found = true;
            _result.workshop_id = ini_read_string("workshop", "id", "");
            _result.name = ini_read_string("workshop", "name", "");
            _result.author = ini_read_string("workshop", "author", "");
            ini_close();
            scr_debug_log("DETECT TEX: Encontrado en " + _base);
            return _result;
        }
        
        // buscar en subcarpeta 
        var _f = file_find_first(_base + "*", fa_directory);
        
        while (_f != "")
        {
            if (_f != "." && _f != "..")
            {
                var _sub = _base + _f + "/workshop_id.ini";
                
                if (file_exists(_sub))
                {
                    ini_open(_sub);
                    _result.found = true;
                    _result.workshop_id = ini_read_string("workshop", "id", "");
                    _result.name = ini_read_string("workshop", "name", "");
                    _result.author = ini_read_string("workshop", "author", "");
                    ini_close();
                    file_find_close();
                    scr_debug_log("DETECT TEX: Encontrado en subcarpeta " + _f);
                    return _result;
                }
            }
            
            _f = file_find_next();
        }
        
        file_find_close();
    }
    
    scr_debug_log("DETECT TEX: No se encontró workshop_id.ini para '" + _tex_name + "'");
    return _result;
}
// detecta si los customs del nivel estan subidos en la workshop
function scr_detect_workshop_customs(_level_path = "")
{
    var _objects = [];
    if (_level_path != "" && file_exists(_level_path))
    {
        // las zonas que no estan abiertas tambien pueden necesitar customs
        var _entries = editor_upload_ini_entries(_level_path);
        for (var _i = 0; _i < array_length(_entries); _i++)
        {
            var _e = _entries[_i];
            if (string_pos("colocado", _e.section) == 1)
                array_push(_objects, _e.value);
        }
    }
    else
    {
        // escanear todas las instancias colocadas en el editor
        with (obj_editor_colocado)
            array_push(_objects, object);
    }
    var _results = [];
    var _checked = ds_map_create(); // evitar duplicados
    for (var _i = 0; _i < array_length(_objects); _i++)
    {
        var _object = string(_objects[_i]);
        var _prefix = "";
        var _cid = "";
        if (string_pos("custom:", _object) == 1)
        {
            _prefix = "custom";
            _cid = string_delete(_object, 1, 7);
        }
        else if (string_pos("cenemy:", _object) == 1)
        {
            _prefix = "cenemy";
            _cid = string_delete(_object, 1, 7);
        }
        if (_cid == "" || _cid == "." || _cid == ".." || string_pos("/", _cid) > 0
            || string_pos("\\", _cid) > 0 || string_pos(":", _cid) > 0 || ds_map_exists(_checked, _cid))
            continue;
        ds_map_add(_checked, _cid, true);
        // buscar workshop_id.ini en la carpeta del custom
        var _custom_path = (os_type == os_android ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (working_directory + "custom/")) + _cid + "/workshop_id.ini";
        if (file_exists(_custom_path))
        {
            ini_open(_custom_path);
            var _ws_id = ini_read_string("workshop", "id", "");
            var _ws_name = ini_read_string("workshop", "name", _cid);
            var _ws_type = ini_read_string("workshop", "item_type", _prefix);
            ini_close();
            if (_ws_id != "")
            {
                array_push(_results, { workshop_id: _ws_id, name: _ws_name, type: _ws_type, folder: _cid });
                show_debug_message("DETECT CUSTOM: " + _cid + " -> workshop_id=" + _ws_id);
            }
        }
        else
            show_debug_message("DETECT CUSTOM: " + _cid + " no tiene workshop_id.ini (local)");
    }
    ds_map_destroy(_checked);
    scr_debug_log("DETECT CUSTOMS: " + string(array_length(_results)) + " con workshop_id");
    return _results;
}

function scr_write_workshop_id_after_download(_dest_folder, _item_index)
{
    if (_item_index < 0)
        return;
    
    var _id = "";
    var _name = "";
    var _author = "";
    var _type = "";
    
    // leer datos del item desde las listas globales
    if (ds_exists(global.texture_ids, ds_type_list) && _item_index < ds_list_size(global.texture_ids))
        _id = string(ds_list_find_value(global.texture_ids, _item_index));
    
    if (ds_exists(global.texture_names, ds_type_list) && _item_index < ds_list_size(global.texture_names))
        _name = string(ds_list_find_value(global.texture_names, _item_index));
    
    if (ds_exists(global.texture_authors, ds_type_list) && _item_index < ds_list_size(global.texture_authors))
        _author = string(ds_list_find_value(global.texture_authors, _item_index));
    
    if (variable_global_exists("texture_item_types") && ds_exists(global.texture_item_types, ds_type_list) 
        && _item_index < ds_list_size(global.texture_item_types))
        _type = string(ds_list_find_value(global.texture_item_types, _item_index));
    
    if (_id == "" || _id == "0")
    {
        show_debug_message("WORKSHOP_ID: No se pudo escribir, id vacío");
        return;
    }
    
    // asegurar que termina en /
    var _path = _dest_folder;
    
    if (string_char_at(_path, string_length(_path)) != "/" 
        && string_char_at(_path, string_length(_path)) != "\\")
        _path += "/";
    
    _path += "workshop_id.ini";
    
    ini_open(_path);
    ini_write_string("workshop", "id", _id);
    ini_write_string("workshop", "name", _name);
    ini_write_string("workshop", "author", _author);
    ini_write_string("workshop", "item_type", _type);
    ini_close();
    
    show_debug_message("workshop_id.ini escrito en: " + _path + " (ID: " + _id + ")");
}





// perfil propio
// sube la foto de perfil en base64. devuelve -2 si el archivo pesa mas de lo permitido.
function scr_upload_profile_image(arg0)
{
    if (!file_exists(arg0))
    {
        show_debug_message("PROFILE IMG: Archivo no existe");
        return -1;
    }
    
    var buffer = buffer_load(arg0);
    var size = buffer_get_size(buffer);
    
    // tope de 500kb, mas que eso lo rechaza el worker
    if (size > 512000)
    {
        buffer_delete(buffer);
        show_debug_message("PROFILE IMG: Archivo muy grande");
        return -2;
    }
    
    // este worker pide base64 y no buffer crudo, es el unico que va asi
    var base64 = buffer_base64_encode(buffer, 0, size);
    buffer_delete(buffer);
    // el nombre lleva la fecha para que no pise la foto anterior en la cache
    var file_name = global.user_id + "_" + string(floor(date_current_datetime() * 100000)) + ".png";
    var url = global.worker_profile_url;
    var headers = ds_map_create();
    ds_map_add(headers, "Content-Type", "application/octet-stream");
    ds_map_add(headers, "X-File-Name", file_name);
    var request = http_request(url, "POST", headers, base64);
    ds_map_destroy(headers);
    show_debug_message("PROFILE IMG: Subiendo " + file_name + ", request " + string(request));
    return request;
}
// guarda bio y foto en el perfil.
function scr_save_profile_to_supabase(arg0, arg1)
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/profiles?p_user_id=eq." + global.user_id;
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    ds_map_add(headers, "Content-Type", "application/json");
    ds_map_add(headers, "Prefer", "return=representation");
    var body = json_stringify(
    {
        profile_image: arg0,
        bio: arg1
    });
    var request = http_request(url, "PATCH", headers, body);
    ds_map_destroy(headers);
    return request;
}
// el perfil del usuario actual.
function scr_load_my_profile()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/profiles?p_user_id=eq." + global.user_id + "&select=*";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// los niveles del usuario actual.
function scr_load_my_levels()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/levels?author_id=eq." + global.user_id + "&select=id,name,description,file_name,thumbnail_name,downloads,created_at,level_likes(count)" + "&order=created_at.desc&limit=3";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
// los badges del usuario actual con nombre e icono.
function scr_load_my_badges()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/user_badges?ub_user_id=eq." + global.user_id + "&select=id,badge_id,awarded_at,awarded_by,badges(name,description,icon_name,color),profiles:awarded_by(username)";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}
function scr_hex_to_dec(arg0)
{
    arg0 = string_upper(arg0);
    var chars = "0123456789ABCDEF";
    var c1 = string_char_at(arg0, 1);
    var c2 = string_char_at(arg0, 2);
    var v1 = string_pos(c1, chars) - 1;
    var v2 = string_pos(c2, chars) - 1;
    var result = (v1 * 16) + v2;
    return result;
}
// descargas y likes de todos los niveles propios, para el total del perfil.
function scr_load_my_stats()
{
    if (!global.user_logged_in)
        return -1;
    
    var url = global.supabase_url + "/rest/v1/levels?author_id=eq." + global.user_id + "&select=id,downloads,level_likes(count)";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.user_token);
    var request = http_request(url, "GET", headers, "");
    ds_map_destroy(headers);
    return request;
}





// descarga de customs al abrir un nivel
// la contracara de la deteccion. obj_level_file va uno por uno por los customs que pide el
// nivel, baja el que falta y lo deja usable sin reiniciar el juego.
function scr_level_file_start_custom_process()
{
    custom_download_queue = [];
    custom_download_index = 0;
    custom_download_progress = 0;
    custom_total_to_download = 0;
    
    if (!variable_global_exists("custom_initialized") || !global.custom_initialized)
        custom_init();
    
    if (variable_global_exists("custom_load_complete") && !global.custom_load_complete)
        custom_load_flush();
    
    // leer custom_objects_used del nivel actual
    var _customs_raw = "";
    if (variable_global_exists("custom_objects_used_levels") 
        && ds_exists(global.custom_objects_used_levels, ds_type_list))
    {
        if (my_list_index < ds_list_size(global.custom_objects_used_levels))
        {
            _customs_raw = ds_list_find_value(global.custom_objects_used_levels, my_list_index);
        }
    }
    
    // si no hay customs, ir directo a transicion
    if (is_undefined(_customs_raw) || _customs_raw == "" 
        || _customs_raw == "null" || _customs_raw == "[]")
    {
        scr_debug_log("CUSTOMS: No hay customs en este nivel");
        download_state = 4;
        scr_level_file_trigger_transition();
        return;
    }
    
    // parsear el json
    try
    {
        var _data;
        if (is_string(_customs_raw))
            _data = json_parse(_customs_raw);
        else
            _data = _customs_raw; // ya es array/struct 
        
        if (!is_array(_data))
        {
            scr_debug_log("CUSTOMS: Datos no son array, saltando");
            download_state = 4;
            scr_level_file_trigger_transition();
            return;
        }
        
        var _custom_base = (os_type == os_android ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (working_directory + "custom/"));
        
        for (var i = 0; i < array_length(_data); i++)
        {
            var _c = _data[i];
            var _name = variable_struct_exists(_c, "name") ? string(_c.name) : "";
            var _ws_id = variable_struct_exists(_c, "workshop_id") ? string(_c.workshop_id) : "";
            var _type = variable_struct_exists(_c, "type") ? string(_c.type) : "custom";
            var _folder = variable_struct_exists(_c, "folder") ? string(_c.folder) : "";
            
            if (_name == "" || _ws_id == "")
                continue;
            
            if (_folder == "")
                _folder = scr_customs_find_folder_by_workshop_id(_ws_id);
            
            if (_folder != "")
            {
                // verificar si ya existe localmente
                var _custom_path = _custom_base + _folder + "/";
                
                if (directory_exists(_custom_path))
                {
                    // existe en disco, verificar si esta cargado en memoria
                    if (variable_global_exists("custom_objects") 
                        && !ds_map_exists(global.custom_objects, _folder))
                    {
                        // existe en disco pero no cargado, recargamos
                        custom_load_object(_folder, _custom_path);
                        scr_debug_log("CUSTOMS: Hot-reload '" + _folder + "' (ya en disco)");
                    }
                    else
                    {
                        scr_debug_log("CUSTOMS: '" + _folder + "' ya disponible");
                    }
                    
                    scr_customs_register_aliases(_folder, _name);
                    continue;
                }
            }
            
            // necesita descarga
            array_push(custom_download_queue, {
                workshop_id: _ws_id,
                name: _name,
                folder: _folder,
                type: _type,
                file_name: "",
                cold_storage_id: ""
            });
            scr_debug_log("CUSTOMS: '" + _name + "' (ws_id=" + _ws_id + ") necesita descarga");
        }
    }
    catch (e)
    {
        scr_debug_log("CUSTOMS: Error parseando JSON: " + e.message);
        download_state = 4;
        scr_level_file_trigger_transition();
        return;
    }
    
    // si no hay nada que descargar, ir a transicion
    if (array_length(custom_download_queue) == 0)
    {
        scr_debug_log("CUSTOMS: Todos los customs disponibles, iniciando nivel");
        download_state = 4;
        scr_level_file_trigger_transition();
        return;
    }
    
    // iniciar descarga 
    custom_total_to_download = array_length(custom_download_queue);
    scr_debug_log("CUSTOMS: " + string(custom_total_to_download) + " customs por descargar");
    download_state = 5;
    custom_download_index = 0;
    scr_level_file_search_next_custom();
}
// buscamos la info del proximo custom en la db
function scr_level_file_search_next_custom()
{
    if (custom_download_index >= array_length(custom_download_queue))
    {
        // todos descargados e instalados
        scr_debug_log("CUSTOMS: Todas las descargas completadas!");
        download_state = 4;
        scr_level_file_trigger_transition();
        return;
    }
    
    var _item = custom_download_queue[custom_download_index];
    scr_debug_log("CUSTOMS: Buscando workshop_id=" + _item.workshop_id 
        + " (" + _item.name + ") [" + string(custom_download_index + 1) 
        + "/" + string(custom_total_to_download) + "]");
    
    // buscar en tabla textures por id
    var _url = global.supabase_url + "/rest/v1/textures?id=eq." + _item.workshop_id 
        + "&select=file_name,cold_storage_id,name,author_name";
    
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(_headers, "Accept", "application/json");
    
    custom_search_request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    
    download_state = 5;
    custom_download_progress = 0;
}
// inicia la descarga custom
function scr_level_file_download_custom_file()
{
    var _item = custom_download_queue[custom_download_index];
    
    if (_item.file_name == "" && _item.cold_storage_id == "")
    {
        scr_debug_log("CUSTOMS: Sin archivo para '" + _item.name + "', saltando");
        custom_download_index++;
        scr_level_file_search_next_custom();
        return;
    }
    
    // armamos el path
    var _temp_path = (os_type == os_android ? game_save_id : working_directory) + "temp_custom_" + _item.workshop_id + ".simplepack";
    custom_temp_download_path = _temp_path;
    
    // preparamos la carpeta
    var _custom_dir = (os_type == os_android ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (working_directory + "custom/"));
    var _folder = variable_struct_exists(_item, "folder") ? _item.folder : "";
    if (_folder == "")
        _folder = _item.name;
    var _dest = _custom_dir + _folder + "/";
    if (!directory_exists(_custom_dir))
        directory_create(_custom_dir);
    custom_install_path = _dest;
    
    scr_debug_log("CUSTOMS: Descargando '" + _item.name + "' via worker bridge");
    scr_debug_log("  file_name: " + _item.file_name);
    scr_debug_log("  cold_storage_id: " + _item.cold_storage_id);
    
    // primero se prueba r2 directo, el bridge queda para cuando r2 no lo tiene
    custom_r2_directo = false;
    custom_download_source = "";
    
    if (_item.file_name != "")
    {
        custom_r2_directo = true;
        custom_download_request = http_get_file(global.r2_textures_url + "/" + _item.file_name, _temp_path);
        download_state = 5;
        custom_download_progress = 0;
        return;
    }
    
    // usar el mismo bridge que las texturas
    custom_bridge_request = scr_request_texture_download_url(_item.file_name, _item.cold_storage_id);
    download_state = 5;
    custom_download_progress = 0;
}

function scr_custom_hot_reload(_folder_name, _workshop_id, _name, _author)
{
    var _path = (os_type == os_android ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (working_directory + "custom/")) + _folder_name + "/";
    
    if (!directory_exists(_path))
    {
        scr_debug_log("CUSTOMS HOT-RELOAD: Carpeta no existe: " + _path);
        return;
    }
    
    // escribir workshop_id.ini
    var _ini_path = _path + "workshop_id.ini";
    ini_open(_ini_path);
    ini_write_string("workshop", "id", _workshop_id);
    ini_write_string("workshop", "name", _name);
    ini_write_string("workshop", "author", _author);
    ini_write_string("workshop", "item_type", "custom");
    ini_close();
    scr_debug_log("CUSTOMS: workshop_id.ini escrito en " + _ini_path);
    
    if (!variable_global_exists("custom_initialized") || !global.custom_initialized)
        custom_init();
    
    if (variable_global_exists("custom_load_complete") && !global.custom_load_complete)
        custom_load_flush();
    
    // si el sistema esta iniciado, cargamos el custom
    if (variable_global_exists("custom_initialized") && global.custom_initialized)
    {
        if (variable_global_exists("custom_objects") 
            && !ds_map_exists(global.custom_objects, _folder_name))
        {
            custom_load_object(_folder_name, _path);
            scr_debug_log("CUSTOMS HOT-RELOAD: '" + _folder_name + "' cargado en memoria!");
        }
        else
        {
            scr_debug_log("CUSTOMS HOT-RELOAD: '" + _folder_name + "' ya estaba cargado");
        }
        
        scr_customs_register_aliases(_folder_name, _name);
    }
    else
    {
        scr_debug_log("CUSTOMS HOT-RELOAD: Sistema custom no inicializado, se cargará al inicio");
    }
}
function scr_customs_find_folder_by_workshop_id(_ws_id)
{
    var _base = (os_type == os_android ? (getDire2("SM4J", "Custom") + "/custom_objects/") : (working_directory + "custom/"));
    
    if (!directory_exists(_base))
        return "";
    
    var _f = file_find_first(_base + "*", fa_directory);
    
    while (_f != "")
    {
        if (_f != "." && _f != "..")
        {
            var _ini = _base + _f + "/workshop_id.ini";
            
            if (file_exists(_ini))
            {
                ini_open(_ini);
                var _id = ini_read_string("workshop", "id", "");
                ini_close();
                
                if (_id == string(_ws_id))
                {
                    file_find_close();
                    return _f;
                }
            }
        }
        
        _f = file_find_next();
    }
    
    file_find_close();
    return "";
}

function scr_customs_register_aliases(_folder_name, _display_name)
{
    if (!variable_global_exists("custom_keys_lower"))
        return;
    
    if (!ds_map_exists(global.custom_objects, _folder_name))
        return;
    
    ds_map_replace(global.custom_keys_lower, string_lower(_display_name), _folder_name);
    ds_map_replace(global.custom_keys_lower, string_replace_all(string_lower(_display_name), " ", ""), _folder_name);
    ds_map_replace(global.custom_keys_lower, string_replace_all(string_lower(_folder_name), " ", ""), _folder_name);
}

function scr_simplepack_peek_file(_path, _wanted)
{
    if (!file_exists(_path))
        return "";
    
    var _b = buffer_load(_path);
    if (_b == -1)
        return "";
    
    var _size_total = buffer_get_size(_b);
    if (_size_total < 4)
    {
        buffer_delete(_b);
        return "";
    }
    
    var _count = buffer_read(_b, buffer_u32);
    if (_count > 10000)
    {
        buffer_delete(_b);
        return "";
    }
    
    var _result = "";
    
    for (var i = 0; i < _count; i++)
    {
        if ((buffer_tell(_b) + 2) > _size_total)
            break;
        
        var _nlen = buffer_read(_b, buffer_u16);
        
        if (_nlen <= 0 || _nlen > 255 || (buffer_tell(_b) + _nlen + 4) > _size_total)
            break;
        
        var _name = "";
        for (var c = 0; c < _nlen; c++)
            _name += chr(buffer_read(_b, buffer_u8));
        
        var _fsize = buffer_read(_b, buffer_u32);
        
        if ((buffer_tell(_b) + _fsize) > _size_total)
            break;
        
        if (_name == _wanted)
        {
            for (var j = 0; j < _fsize && j < 255; j++)
                _result += chr(buffer_read(_b, buffer_u8));
            break;
        }
        
        buffer_seek(_b, buffer_seek_relative, _fsize);
    }
    
    buffer_delete(_b);
    return _result;
}


// sube archivo y miniatura en una sola request. el body es un paquete binario
// con el tamano del archivo + archivo + miniatura, y el worker se ocupa de separarlo
function scr_upload_pack(_file_path, _thumb_path, _file_name, _thumb_name, _worker_url)
{
    if (!file_exists(_file_path))
    {
        show_debug_message("Error: El archivo no existe: " + _file_path);
        return -1;
    }
    
    var _b_file = buffer_load(_file_path);
    var _file_size = buffer_get_size(_b_file);
    
    var _b_thumb = -1;
    var _thumb_size = 0;
    if (_thumb_path != "" && file_exists(_thumb_path))
    {
        _b_thumb = buffer_load(_thumb_path);
        if (_b_thumb != -1)
            _thumb_size = buffer_get_size(_b_thumb);
    }
    
    var _pack = buffer_create(4 + _file_size + _thumb_size, buffer_fixed, 1);
    buffer_seek(_pack, buffer_seek_start, 0);
    buffer_write(_pack, buffer_u32, _file_size);
    buffer_copy(_b_file, 0, _file_size, _pack, 4);
    if (_thumb_size > 0)
        buffer_copy(_b_thumb, 0, _thumb_size, _pack, 4 + _file_size);
    
    var _headers = ds_map_create();
    ds_map_add(_headers, "Content-Type", "application/octet-stream");
    ds_map_add(_headers, "X-File-Name", _file_name);
    ds_map_add(_headers, "X-Thumb-Name", _thumb_name);
    ds_map_add(_headers, "X-Action", "upload");
    
    if (variable_global_exists("user_token") && global.user_token != "")
        ds_map_add(_headers, "Authorization", "Bearer " + global.user_token);
    
    scr_debug_log("UPLOAD PACK: " + _file_name + " + " + _thumb_name + " (" + string(_file_size) + " + " + string(_thumb_size) + " bytes)");
    
    var _request = http_request(_worker_url, "POST", _headers, _pack);
    ds_map_destroy(_headers);
    buffer_delete(_b_file);
    if (_b_thumb != -1)
        buffer_delete(_b_thumb);
    buffer_delete(_pack);
    return _request;
}

// una vez subidos, toca registrar el el nivel en la db
function scr_upload_continuar_db_nivel_editor(_inst)
{
    with (_inst)
    {
        upload_step = 3;
        mensaje = "Registrando en base de datos...";
        var tags_array = array_create(ds_list_size(tags_seleccionados));
        
        for (var i = 0; i < ds_list_size(tags_seleccionados); i++)
            tags_array[i] = ds_list_find_value(tags_seleccionados, i);
        
        var _texture_value = "vanilla";
        if (texture_enabled && texture_selected_display != "")
            _texture_value = texture_selected_display;
        else if (auto_texture_detected && auto_texture_name != "")
            _texture_value = auto_texture_name + " - " + auto_texture_author;
        
        // construir json de customs
        var _customs_json = "[]";
        if (array_length(auto_customs_detected) > 0)
        {
            _customs_json = "[";
            for (var i = 0; i < array_length(auto_customs_detected); i++)
            {
                if (i > 0) _customs_json += ",";
                var _c = auto_customs_detected[i];
                _customs_json += "{\"workshop_id\":" + _c.workshop_id
                    + ",\"name\":\"" + string_replace_all(_c.name, "\"", "\\\"") + "\""
                    + ",\"type\":\"" + _c.type + "\""
                    + ",\"folder\":" + json_stringify(_c.folder) + "}";
            }
            _customs_json += "]";
        }
        
        // workshop id de textura
        var _tex_ws_id = auto_texture_detected ? auto_texture_workshop_id : "";
        
        scr_debug_log("DB: cold_storage_id=" + cold_storage_id
            + " tex_ws_id=" + _tex_ws_id
            + " customs=" + string(array_length(auto_customs_detected)));
        
        db_tags_array = tags_array;
        db_texture_value = _texture_value;
        db_tex_ws_id = _tex_ws_id;
        db_customs_json = _customs_json;
        cold_storage_id = scr_coldid_add_cb(cold_storage_id, catbox_file_id);
        
        if (request_catbox != -1)
        {
            esperando_catbox_db = true;
            mensaje = "Esperando respaldo Catbox...";
            scr_debug_log("Esperando a Catbox antes de registrar...");
        }
        else
        {
            request_upload_db = scr_supabase_upload_level(
                level_name, level_description, r2_file_name, r2_thumb_name,
                tags_array, _texture_value, cold_storage_id,
                _tex_ws_id, _customs_json
            );
        }
    }
}

// lo mismo pero para el uploader fuera del editor (el debug)
function scr_upload_continuar_db_nivel_browser(_inst)
{
    with (_inst)
    {
        upload_step = 3;
        mensaje = "Registrando en base de datos...";
        var tags_array = array_create(ds_list_size(tags_seleccionados));
        
        for (var i = 0; i < ds_list_size(tags_seleccionados); i++)
            tags_array[i] = ds_list_find_value(tags_seleccionados, i);
        
        var _texture_value = "vanilla";
        
        if (texture_enabled && texture_selected_display != "")
            _texture_value = texture_selected_display;
        
        cold_storage_id = scr_coldid_add_cb(cold_storage_id, catbox_file_id);
        scr_debug_log("Registering in DB with cold_storage_id: " + cold_storage_id);
        db_tags_array = tags_array;
        db_texture_value = _texture_value;
        
        if (request_catbox != -1)
        {
            esperando_catbox_db = true;
            mensaje = "Esperando respaldo Catbox...";
            scr_debug_log("Esperando a Catbox antes de registrar...");
        }
        else
        {
            request_upload_db = scr_supabase_upload_level(level_name, level_description, r2_file_name, r2_thumb_name, tags_array, _texture_value, cold_storage_id);
        }
    }
}

// lo mismo para texturas y customs
function scr_upload_continuar_db_textura(_inst)
{
    with (_inst)
    {
        upload_step = 3;
        mensaje = "Registrando en base de datos...";
        
        if (request_catbox != -1)
        {
            esperando_catbox_db = true;
            mensaje = "Esperando respaldo Catbox...";
            scr_debug_log("Esperando a Catbox antes de registrar...");
        }
        else
        {
            cold_storage_id = scr_coldid_add_cb(cold_storage_id, catbox_file_id);
            request_create_db = scr_supabase_create_texture(texture_name, texture_description, r2_file_name, r2_thumb_name, tags_seleccionados, cold_storage_id, item_type);
        }
    }
}
