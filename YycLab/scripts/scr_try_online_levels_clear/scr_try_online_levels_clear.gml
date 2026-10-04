function editor_mark_modifiedx()
{
    with (obj_editor_manager)
    {
        level_modified_since_clear = true;
        level_cleared = false;
    }
}
function editor_try_upload_level()
{
    scr_debug_log("=== EDITOR UPLOAD DEBUG ===");
    scr_debug_log("variable_global_exists user_logged_in: " + string(variable_global_exists("user_logged_in")));
    
    if (variable_global_exists("user_logged_in"))
        scr_debug_log("global.user_logged_in valor: " + string(global.user_logged_in));
    else
        scr_debug_log("global.user_logged_in NO EXISTE");
    
    if (variable_global_exists("user_id"))
        scr_debug_log("global.user_id: " + string(global.user_id));
    else
        scr_debug_log("global.user_id NO EXISTE");
    
    if (variable_global_exists("user_name"))
        scr_debug_log("global.user_name: " + string(global.user_name));
    else
        scr_debug_log("global.user_name NO EXISTE");
    
    if (variable_global_exists("user_token"))
        scr_debug_log("global.user_token existe: " + string(variable_global_exists("user_token")));
    else
        scr_debug_log("global.user_token NO EXISTE");
    
    scr_debug_log("===========================");
    
    if (!variable_global_exists("user_logged_in"))
    {
        scr_debug_log("UPLOAD BLOQUEADO: user_logged_in no existe como variable");
        show_message_async("Debes iniciar sesión para subir niveles.");
        exit;
    }
    
    if (global.user_logged_in == 0 || global.user_logged_in == false)
    {
        scr_debug_log("UPLOAD BLOQUEADO: user_logged_in es falso/0, valor: " + string(global.user_logged_in));
        show_message_async("Debes iniciar sesión para subir niveles.");
        exit;
    }
    
    scr_debug_log("LOGIN OK - Procediendo con upload check");
    
    with (obj_editor_manager)
    {
        scr_debug_log("level_cleared: " + string(level_cleared));
        scr_debug_log("level_modified_since_clear: " + string(level_modified_since_clear));
        
        var _vh = editor_verify_hash_current();
        if (_vh == "")
        {
            editor_upload_invalidate();
            show_message_async("No se pudo guardar el nivel completo para subirlo.");
            return;
        }
        if (verify_active_hash != _vh)
        {
            clear_check_screenshot = "";
            screenshot_pending = false;
            upload_after_screenshot = false;
        }
        editor_verify_goals_scan();
        verify_tampered = false;
        
        var _record_ok = editor_verify_record_read(_vh);
        if (!_record_ok)
        {
            // no hay registro para este contenido (si antes habia, modifico el nivel)
            if (verify_active_hash != "" && verify_active_hash != _vh && verify_record_progress)
                verify_tampered = true;
            
            verify_record_progress = false;
        }
        
        verify_active_hash = _vh;
        editor_upload_remember_signature();
        
        var _todo_listo = false;
        
        if (array_length(verify_goals) > 0)
        {
            if (editor_verify_pending_count() == 0)
                _todo_listo = true;
        }
        else if (_record_ok && verify_record_hash == _vh)
            _todo_listo = true;
        
        if (_todo_listo)
        {
            scr_debug_log("Nivel ya verificado, yendo directo a upload");
            editor_prepare_upload();
            exit;
        }
        
        scr_debug_log("Nivel NO verificado, mostrando popup de clear check");
        upload_popup_visible = true;
        upload_popup_anim = 0;
        global.disable_editor_controls = 1;
    }
}

function editor_prepare_upload()
{
    if (!instance_exists(obj_editor_manager) || instance_exists(obj_editor_upload_level))
        return false;
    with (obj_editor_manager)
    {
        if (screenshot_pending && upload_after_screenshot)
            return true;
        // publicar conserva el inicio principal aunque la meta este en otra zona
        if (!editor_upload_select_start())
        {
            editor_upload_invalidate();
            show_message_async("No se pudo abrir la zona principal para preparar la subida.");
            return false;
        }
        var _hash = editor_verify_hash_current();
        if (_hash == "" || _hash != verify_active_hash || verify_record_hash != _hash
            || (array_length(verify_goals) > 0 && editor_verify_pending_count() > 0))
        {
            if (_hash != verify_active_hash)
                editor_upload_report_mismatch(verify_active_hash, _hash);
            editor_upload_invalidate();
            show_message_async("El nivel cambio o no esta verificado. Volve a probarlo antes de subirlo.");
            return false;
        }
        if (clear_check_screenshot == "" || !file_exists(clear_check_screenshot))
        {
            if (!editor_upload_select_start())
                return false;
            var spawn_y = 352;
            if (instance_exists(obj_editor_mario_spawn))
                spawn_y = obj_editor_mario_spawn.y;
            var cam = view_camera[0];
            screenshot_restore_x = camera_get_view_x(cam);
            screenshot_restore_y = camera_get_view_y(cam);
            screenshot_restore_w = camera_get_view_width(cam);
            screenshot_restore_h = camera_get_view_height(cam);
            var target_y = clamp(spawn_y - 108, 0, max(0, room_height - 216));
            camera_set_view_pos(cam, 0, target_y);
            camera_set_view_size(cam, 384, 216);
            clear_check_screenshot = working_directory + "Niveles/_upload_thumb.png";
            screenshot_pending = true;
            screenshot_delay = 2;
            upload_after_screenshot = true;
            global.disable_editor_controls = 1;
            return true;
        }
        verify_upload_file_hash = string_lower(md5_file(clear_check_temp_level));
        if (verify_upload_file_hash == "")
            return false;
        clear_check_mode = false;
        state = 0;
        global.disable_editor_controls = 0;
        upload_popup_visible = false;
        level_cleared = true;
        level_modified_since_clear = false;
        instance_create_depth(0, 0, -100, obj_editor_upload_level);
        scr_debug_log("Upload level UI creada con el proyecto verificado completo");
        return true;
    }
    return false;
}

function editor_start_clear_check()
{
    with (obj_editor_manager)
    {
        // la prueba arranca donde va a arrancar quien lo baje del browser
        if (!editor_upload_select_start())
        {
            show_message_async("No se pudo abrir la zona principal para verificar el nivel.");
            return false;
        }
        var _hash = editor_verify_hash_current();
        if (_hash == "")
        {
            editor_upload_invalidate();
            show_message_async("No se pudo guardar el nivel completo para verificarlo.");
            return false;
        }
        editor_verify_goals_scan();
        editor_verify_record_read(_hash);
        verify_active_hash = _hash;
        editor_upload_remember_signature();
        upload_popup_visible = false;
        clear_check_mode = true;
        clear_check_goal_idx = -1;
        clear_check_won = false;
        clear_check_finish_pending = false;
        upload_after_screenshot = false;
        state = 0;
        var spawn_x = 48;
        var spawn_y = 352;
        if (instance_exists(obj_editor_mario_spawn))
        {
            spawn_x = obj_editor_mario_spawn.x;
            spawn_y = obj_editor_mario_spawn.y;
        }
        verify_mario_x = spawn_x;
        verify_mario_y = spawn_y;
        var cam = view_camera[0];
        screenshot_restore_x = camera_get_view_x(cam);
        screenshot_restore_y = camera_get_view_y(cam);
        screenshot_restore_w = camera_get_view_width(cam);
        screenshot_restore_h = camera_get_view_height(cam);
        var target_y = clamp(spawn_y - 108, 0, max(0, room_height - 216));
        camera_set_view_pos(cam, 0, target_y);
        camera_set_view_size(cam, 384, 216);
        clear_check_screenshot = working_directory + "Niveles/_upload_thumb.png";
        if (file_exists(clear_check_screenshot))
            file_delete(clear_check_screenshot);
        screenshot_pending = true;
        screenshot_delay = 12;
        clear_check_play_pending = true;
        global._es_warp = false;
        global.disable_editor_controls = 1;
        return true;
    }
    return false;
}

function editor_save_level_to_path(arg0)
{
    var archivo = arg0;
    if (editor_upload_is_modern())
    {
        var _m = instance_find(obj_editor_manager, 0);
        if (_m.editor_rooms_internal_io)
            return false;
        var _ok = false;
        if (_m.editor_rooms_enabled)
        {
            // una zona que falta no se reemplaza por una vacia al publicar
            for (var _i = 0; _i < array_length(_m.editor_rooms); _i++)
            {
                if (_i == _m.editor_room_current)
                    continue;
                var _cache = _m.editor_rooms[_i].temp_file;
                if (!file_exists(_cache))
                    return false;
                ini_open(_cache);
                var _has_options = ini_section_exists("options");
                ini_close();
                if (!_has_options)
                    return false;
            }
            _ok = editor_rooms_save_bundle(archivo, false);
        }
        else
            _ok = editor_save_level(archivo);
        if (!_ok || !file_exists(archivo))
            return false;
        ini_open(archivo);
        var _valid = ini_read_string("options", "editor_version", "") == "4.0";
        if (_m.editor_rooms_enabled)
        {
            var _count = array_length(_m.editor_rooms);
            _valid = _valid && ini_read_real("rooms", "count", 0) == _count;
            for (var _i = 0; _i < _count; _i++)
            {
                var _suffix = (_i == 0) ? "" : ("_" + string(_i + 1));
                if (!ini_section_exists("options" + _suffix))
                    _valid = false;
            }
        }
        ini_close();
        if (_valid && _m.editor_rooms_enabled)
            _valid = editor_rooms_bundle_matches(archivo);
        return _valid;
    }
    // el guardado anterior queda reservado para el modo legacy
    if (file_exists(archivo))
        file_delete(archivo);
    show_debug_message("Guardando nivel temporal en: " + archivo);
    ini_open(archivo);
    ini_write_string("options", "editor_version", "3.0");
    
    with (obj_editor_manager)
    {
        ini_write_string("options", "room_x", string(room_width));
        ini_write_string("options", "room_y", string(room_height));
        ini_write_string("options", "background", string(background));
        ini_write_string("options", "bg", string(bg));
        ini_write_string("options", "musica", string(musica));
        ini_write_string("options", "musica_le", string(musica_le));
        ini_write_string("options", "modo", string(modo));
        ini_write_string("options", "storm", storm);
        ini_write_string("options", "tiempo", tiempo);
        ini_write_string("options", "tiempo_count", string(tiempo_count));
        ini_write_string("options", "walljump", walljump);
        ini_write_string("options", "cheepGen", cheepGen);
        ini_write_string("options", "snowGen", snowGen);
        ini_write_string("options", "niebla", niebla);
        ini_write_string("options", "angrysun", angrysun);
        ini_write_string("options", "health", vhealth);
        ini_write_string("options", "no_reserve", no_reserve);
        ini_write_string("options", "no_grab", no_grab);
        ini_write_string("options", "no_spinjump", no_spinjump);
        ini_write_string("options", "waterlvl", waterlvl);
        ini_write_string("options", "no_pull", no_pull);
        ini_write_string("options", "no_screen_limit", no_screen_limit);
        ini_write_string("options", "midari", midari);
        ini_write_string("options", "light", light);
        ini_write_string("options", "scroll_speed", string(scroll_speed));
        ini_write_string("options", "no_slide", no_slide);
    }
    
    if (instance_exists(obj_editor_mario_spawn))
    {
        ini_write_string("options", "mario_x", string(obj_editor_mario_spawn.x));
        ini_write_string("options", "mario_y", string(obj_editor_mario_spawn.y));
    }
    else
    {
        ini_write_string("options", "mario_x", "48");
        ini_write_string("options", "mario_y", "352");
    }
    
    var n0 = 0;
    var n1 = 0;
    
    with (obj_editor_colocado)
    {
        if (object != "" && isvalid)
        {
            ini_write_string("colocado", string(n0) + string(n1), object);
            n1++;
            ini_write_string("colocado", string(n0) + string(n1), string(floor(x)));
            n1++;
            ini_write_string("colocado", string(n0) + string(n1), string(floor(y)));
            n1++;
            ini_write_string("colocado", string(n0) + string(n1), string(depth));
            n0++;
            n1 = 0;
        }
    }
    
    var n9_0 = 0;
    var n9_1 = 0;
    
    with (obj_editor_solidcolocado)
    {
        if (object != "" && isvalid)
        {
            ini_write_string("colocado9", string(n9_0) + string(n9_1), object);
            n9_1++;
            ini_write_string("colocado9", string(n9_0) + string(n9_1), string(floor(x)));
            n9_1++;
            ini_write_string("colocado9", string(n9_0) + string(n9_1), string(floor(y)));
            n9_1++;
            ini_write_string("colocado9", string(n9_0) + string(n9_1), string(image_xscale));
            n9_1++;
            ini_write_string("colocado9", string(n9_0) + string(n9_1), string(image_yscale));
            n9_0++;
            n9_1 = 0;
        }
    }
    
    var n8_0 = 0;
    var n8_1 = 0;
    
    with (obj_editor_placedtile)
    {
        var key_base = string_add_zeros(n8_0, 2);
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(x)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(y)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(x_tile)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(x_tile_pos)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(y_tile)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(y_tile_pos)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(depth_tile)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(x_tile_scale));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(y_tile_scale));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(tile_width)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(tile_height)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(blend)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(alp));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(flipY)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(flipX)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(offsetY)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(floor(offsetX)));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), sprite_get_name(tile_bg_nuevo));
        n8_1++;
        var has_selection = variable_instance_exists(id, "selection_tiles_x") && array_length(selection_tiles_x) > 0;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(has_selection ? selection_width : 0));
        n8_1++;
        ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), string(has_selection ? selection_height : 0));
        n8_1++;
        
        if (has_selection)
        {
            var tiles_x_str = "";
            var tiles_y_str = "";
            
            for (var _t = 0; _t < array_length(selection_tiles_x); _t++)
            {
                if (_t > 0)
                {
                    tiles_x_str += ",";
                    tiles_y_str += ",";
                }
                
                tiles_x_str += string(selection_tiles_x[_t]);
                tiles_y_str += string(selection_tiles_y[_t]);
            }
            
            ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), tiles_x_str);
            n8_1++;
            ini_write_string("colocado8", key_base + string_add_zeros(n8_1, 2), tiles_y_str);
            n8_1++;
        }
        
        n8_0++;
        n8_1 = 0;
    }
    
    var nb_0 = 0;
    var nb_1 = 0;
    
    with (obj_editor_blockcolocado)
    {
        if (object != "" && isvalid)
        {
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), object);
            nb_1++;
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), string(floor(x)));
            nb_1++;
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), string(floor(y)));
            nb_1++;
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), string(depth));
            nb_1++;
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), string(block_content));
            nb_1++;
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), string(image_xscale));
            nb_1++;
            ini_write_string("colocadoblock", string(nb_0) + string(nb_1), string(image_yscale));
            nb_0++;
            nb_1 = 0;
        }
    }
    
    ini_write_string("options", "NewtilesetValues", "DON'T ERASE");
    ini_close();
    show_debug_message("Nivel temporal guardado en: " + archivo);
    return file_exists(archivo);
}

function editor_take_upload_screenshot()
{
    with (obj_editor_manager)
    {
        var screenshot_path = working_directory + "Niveles/_upload_thumb.png";
        var cam = view_camera[0];
        var old_x = camera_get_view_x(cam);
        var old_y = camera_get_view_y(cam);
        var old_w = camera_get_view_width(cam);
        var old_h = camera_get_view_height(cam);
        camera_set_view_pos(cam, 0, 0);
        camera_set_view_size(cam, 384, 216);
        clear_check_screenshot = screenshot_path;
        screenshot_pending = true;
        screenshot_restore_x = old_x;
        screenshot_restore_y = old_y;
        screenshot_restore_w = old_w;
        screenshot_restore_h = old_h;
        scr_debug_log("Screenshot programado para próximo frame: " + screenshot_path);
    }
}
// cuenta las salidas colocadas y arma la lista con el tipo y la posicion de cada una
function editor_verify_goals_scan()
{
    if (editor_upload_is_modern())
    {
        var _m = instance_find(obj_editor_manager, 0);
        _m.verify_goals = editor_upload_goals_file(_m.clear_check_temp_level);
        _m.verify_done = array_create(array_length(_m.verify_goals), false);
        return array_length(_m.verify_goals);
    }
    var _goals = [];
    var _editores = [obj_editor_colocado, obj_editor_blockcolocado, obj_editor_solidcolocado];
    
    for (var _e = 0; _e < array_length(_editores); _e++)
    {
        with (_editores[_e])
        {
            if (object != "" && isvalid)
            {
                if (object == "obj_goalgate" || object == "obj_flagpole" || object == "obj_boxpanel")
                    array_push(_goals, object + "|" + string(x) + "|" + string(y));
            }
        }
    }
    
    var _sorted = ds_list_create();
    
    for (var _i = 0; _i < array_length(_goals); _i++)
        ds_list_add(_sorted, _goals[_i]);
    
    ds_list_sort(_sorted, true);
    
    for (var _i = 0; _i < ds_list_size(_sorted); _i++)
        _goals[_i] = ds_list_find_value(_sorted, _i);
    
    ds_list_destroy(_sorted);
    
    with (obj_editor_manager)
    {
        verify_goals = _goals;
        verify_done = array_create(array_length(_goals), false);
        
        return array_length(_goals);
    }
    
    return 0;
}

function editor_verify_norm(arg0)
{
    var _s = string(arg0);
    var _len = string_length(_s);
    
    if (_len == 0)
        return "";
    
    var _dots = 0;
    var _digits = 0;
    var _ok = true;
    
    for (var _i = 1; _i <= _len; _i++)
    {
        var _c = string_ord_at(_s, _i);
        
        if (_c >= 48 && _c <= 57)
        {
            _digits++;
            continue;
        }
        
        if (_c == 45 && _i == 1)
            continue;
        
        if (_c == 46)
        {
            _dots++;
            
            if (_dots > 1)
            {
                _ok = false;
                break;
            }
            
            continue;
        }
        
        _ok = false;
        break;
    }
    
    if (!_ok || _digits == 0)
        return _s;
    
    var _r = real(_s);
    
    if (_r == floor(_r))
        return string(floor(_r));
    
    return string(_r);
}

// guardamos el nivel y generamos una identificador con el hash para ver si se modifico o no
function editor_verify_hash_current()
{
    var _dir = working_directory + "Niveles/";
    
    if (!directory_exists(_dir))
        directory_create(_dir);
    
    var _path = _dir + "_upload_temp.lvl";
    
    with (obj_editor_manager)
    {
        if (clear_check_temp_level != "")
            _path = clear_check_temp_level;
    }
    
    if (file_exists(_path))
        file_delete(_path);
    
    with (obj_editor_manager)
    {
        clear_check_temp_level = _path;
        verify_upload_file_hash = "";
    }
    if (!editor_save_level_to_path(_path))
        return "";
    if (editor_upload_is_modern())
        return editor_upload_hash_file(_path);
    
    if (!file_exists(_path))
        return "";
    
    var _lineas = ds_list_create();
    
    ini_open(_path);
    
    var _opkeys = ["editor_version", "room_x", "room_y", "background", "bg", "musica", "musica_le", "modo", "storm", "tiempo", "tiempo_count", "walljump", "cheepGen", "snowGen", "niebla", "angrysun", "health", "no_reserve", "no_grab", "no_spinjump", "waterlvl", "no_pull", "no_screen_limit", "midari", "light", "scroll_speed", "no_slide", "mario_x", "mario_y"];
    
    for (var _k = 0; _k < array_length(_opkeys); _k++)
        ds_list_add(_lineas, "options|" + _opkeys[_k] + "|" + editor_verify_norm(ini_read_string("options", _opkeys[_k], "")));
    
    var _n = 0;
    
    while (ini_key_exists("colocado", string(_n) + "0"))
    {
        ds_list_add(_lineas, "colocado|" + ini_read_string("colocado", string(_n) + "0", "") + "|" + editor_verify_norm(ini_read_string("colocado", string(_n) + "1", "")) + "|" + editor_verify_norm(ini_read_string("colocado", string(_n) + "2", "")));
        _n++;
    }
    
    _n = 0;
    
    while (ini_key_exists("colocado9", string(_n) + "0"))
    {
        var _l9 = "colocado9|" + ini_read_string("colocado9", string(_n) + "0", "");
        
        for (var _f = 1; _f <= 4; _f++)
            _l9 += "|" + editor_verify_norm(ini_read_string("colocado9", string(_n) + string(_f), ""));
        
        ds_list_add(_lineas, _l9);
        _n++;
    }
    
    _n = 0;
    
    while (ini_key_exists("colocadoblock", string(_n) + "0"))
    {
        var _lb = "colocadoblock|" + ini_read_string("colocadoblock", string(_n) + "0", "");
        _lb += "|" + editor_verify_norm(ini_read_string("colocadoblock", string(_n) + "1", ""));
        _lb += "|" + editor_verify_norm(ini_read_string("colocadoblock", string(_n) + "2", ""));
        _lb += "|" + editor_verify_norm(ini_read_string("colocadoblock", string(_n) + "4", ""));
        _lb += "|" + editor_verify_norm(ini_read_string("colocadoblock", string(_n) + "5", ""));
        _lb += "|" + editor_verify_norm(ini_read_string("colocadoblock", string(_n) + "6", ""));
        ds_list_add(_lineas, _lb);
        _n++;
    }
    
    _n = 0;
    
    while (ini_key_exists("colocado8", string_add_zeros(_n, 2) + "00"))
    {
        var _kb = string_add_zeros(_n, 2);
        var _l8 = "colocado8";
        
        for (var _f = 0; _f <= 19; _f++)
        {
            if (_f == 6)
                continue;
            
            _l8 += "|" + editor_verify_norm(ini_read_string("colocado8", _kb + string_add_zeros(_f, 2), ""));
        }
        
        var _selkey = _kb + string_add_zeros(20, 2);
        
        if (ini_key_exists("colocado8", _selkey))
        {
            _l8 += "|" + ini_read_string("colocado8", _selkey, "");
            _l8 += "|" + ini_read_string("colocado8", _kb + string_add_zeros(21, 2), "");
        }
        
        ds_list_add(_lineas, _l8);
        _n++;
    }
    
    ini_close();
    
    ds_list_sort(_lineas, true);
    
    var _blob = "";
    
    for (var _i = 0; _i < ds_list_size(_lineas); _i++)
        _blob += ds_list_find_value(_lineas, _i) + "\n";
    
    ds_list_destroy(_lineas);
    
    return string_lower(md5_string_unicode(_blob));
}

// lee el progreso guardado para el hash que le pasas (cada nivel tiene el suyo)

function editor_verify_record_read(arg0)
{
    if (arg0 == "" || !instance_exists(obj_editor_manager))
        return false;
    var _m = instance_find(obj_editor_manager, 0);
    _m.verify_record_hash = "";
    _m.verify_record_progress = false;
    var _path = working_directory + "Niveles/_sprcache.ini";
    if (!file_exists(_path))
        return false;
    ini_open(_path);
    var _count = 0;
    var _cs = scr_simple_decrypt(ini_read_string("sprites", "count", ""));
    if (_cs != "" && string_digits(_cs) == _cs)
        _count = real(_cs);
    var _idx = -1;
    for (var _i = 0; _i < _count; _i++)
    {
        if (scr_simple_decrypt(ini_read_string("sprites", "h" + string(_i), "")) == arg0)
        {
            _idx = _i;
            break;
        }
    }
    if (_idx == -1)
    {
        ini_close();
        return false;
    }
    var _sec = "r" + string(_idx);
    var _fs = scr_simple_decrypt(ini_read_string(_sec, "frames", ""));
    var _total = -1;
    if (_fs != "" && string_digits(_fs) == _fs)
        _total = real(_fs);
    var _entries = [];
    if (_total > 0)
    {
        for (var _i = 0; _i < _total; _i++)
            array_push(_entries, scr_simple_decrypt(ini_read_string(_sec, "f" + string(_i), "")));
    }
    ini_close();
    if (_total != array_length(_m.verify_goals))
        return false;
    var _done = array_create(_total, false);
    var _progress = false;
    for (var _i = 0; _i < _total; _i++)
    {
        var _last = string_last_pos("|", _entries[_i]);
        if (_last <= 0 || string_copy(_entries[_i], 1, _last - 1) != _m.verify_goals[_i])
            return false;
        var _flag = string_copy(_entries[_i], _last + 1, string_length(_entries[_i]) - _last);
        if (_flag != "0" && _flag != "1")
            return false;
        _done[_i] = (_flag == "1");
        if (_done[_i])
            _progress = true;
    }
    _m.verify_done = _done;
    _m.verify_record_hash = arg0;
    _m.verify_record_progress = _progress;
    return true;
}

// guarda el progreso de la verificacion atado al hash del nivel actual.

function editor_verify_record_write()
{
    if (!instance_exists(obj_editor_manager))
        return false;
    var _path = working_directory + "Niveles/_sprcache.ini";
    
    with (obj_editor_manager)
    {
        var _current_hash = editor_verify_hash_current();
        if (_current_hash == "" || _current_hash != verify_active_hash)
        {
            editor_upload_report_mismatch(verify_active_hash, _current_hash);
            return false;
        }
        verify_record_hash = _current_hash;
        
        ini_open(_path);
        var _count = 0;
        var _cs = scr_simple_decrypt(ini_read_string("sprites", "count", ""));
        
        if (_cs != "" && string_digits(_cs) == _cs)
            _count = real(_cs);
        
        var _idx = -1;
        
        for (var _i = 0; _i < _count; _i++)
        {
            if (scr_simple_decrypt(ini_read_string("sprites", "h" + string(_i), "")) == verify_record_hash)
            {
                _idx = _i;
                break;
            }
        }
        
        if (_idx == -1)
        {
            _idx = _count;
            _count++;
            ini_write_string("sprites", "count", scr_simple_encrypt(string(_count)));
            ini_write_string("sprites", "h" + string(_idx), scr_simple_encrypt(verify_record_hash));
        }
        
        var _sec = "r" + string(_idx);
        ini_write_string(_sec, "frames", scr_simple_encrypt(string(array_length(verify_goals))));
        
        for (var _i = 0; _i < array_length(verify_goals); _i++)
            ini_write_string(_sec, "f" + string(_i), scr_simple_encrypt(verify_goals[_i] + "|" + (verify_done[_i] ? "1" : "0")));
        
        ini_close();
    }
    return true;
}

// cuantas salidas faltan verificar
function editor_verify_pending_count()
{
    with (obj_editor_manager)
    {
        var _left = 0;
        
        for (var _i = 0; _i < array_length(verify_done); _i++)
        {
            if (!verify_done[_i])
                _left++;
        }
        
        return _left;
    }
    
    return 0;
}

// el texto extra del popup: avisa si hay varias salidas, cuantas quedan,
// o si el nivel cambio desde la ultima verificacion
function editor_verify_popup_text()
{
    with (obj_editor_manager)
    {
        var _total = array_length(verify_goals);
        var _left = editor_verify_pending_count();
        var _txt = "";
        
        if (verify_tampered)
            _txt = "Nivel modificado: verificacion de 0.";
        
        if (_total > 1)
        {
            if (_txt != "")
                _txt += "\n";
            
            _txt += "Este nivel tiene " + string(_total) + " salidas,\ntenes que verificar todas para publicarlo.";
        }
        
        if (_total > 0 && _left > 0 && _left < _total)
        {
            if (_txt != "")
                _txt += "\n";
            
            if (_left == 1)
                _txt += "Te queda verificar solo 1 salida.";
            else
                _txt += "Te quedan " + string(_left) + " salidas por verificar.";
        }
        
        return _txt;
    }
    
    return "";
}
// cuando ganamos el nivel anotamos por que salida fue y chequeamos si ya se habia ganado por esa antes

function editor_verify_capture_goal()
{
    with (obj_editor_manager)
    {
        if (!clear_check_mode || global.clear <= 0)
            return;
        clear_check_won = true;
        if (clear_check_goal_idx != -1)
            exit;

        // la posicion queda tomada antes de que mario se aleje de la bandera
        if (instance_exists(obj_mario))
        {
            verify_mario_x = obj_mario.x;
            verify_mario_y = obj_mario.y;
        }
        var _room_uid = editor_upload_is_modern() ? editor_rooms_current_uid() : 1;
        var _best = editor_upload_pick_goal(verify_goals, _room_uid, verify_mario_x, verify_mario_y);

        if (_best != -1)
        {
            clear_check_goal_idx = _best;
            verify_done[_best] = true;
            
            var _p = string_pos("|", verify_goals[_best]);
            var _oi = asset_get_index(string_copy(verify_goals[_best], 1, _p - 1));
            verify_toast_spr = -1;
            
            if (_oi != -1)
                verify_toast_spr = object_get_sprite(_oi);
            
            verify_toast_txt = "progreso " + string(array_length(verify_goals) - editor_verify_pending_count()) + "/" + string(array_length(verify_goals));
            verify_toast_time = 150;
            scr_debug_log("CLEAR CHECK: salida anotada, meta #" + string(_best + 1));
        }
    }
}

// la anim de victoria o muerte avisa cuando corresponde salir del play
function editor_verify_request_finish()
{
    if (!instance_exists(obj_editor_manager))
        return false;
    var _m = instance_find(obj_editor_manager, 0);
    if (_m.clear_check_finish_pending)
        return true;
    if (!_m.clear_check_mode)
        return false;
    if (global.clear > 0)
        editor_verify_capture_goal();
    _m.clear_check_finish_pending = true;
    editor_stop_playing(false);
    scr_level_reset_warp_state();
    return true;
}

// si mario muere o gana por una salida reiniciamos el nivel y actualizamos el progreso
// si ya gano con todas las salidas al tocar la ultima volvemos al editor y abrimos l subidor d niveles
function editor_verify_register_clear()
{
    with (obj_editor_manager)
    {
        if (!clear_check_mode && !clear_check_finish_pending)
            return;
        var _cleared = clear_check_won || global.clear > 0;
        if (_cleared && clear_check_goal_idx < 0 && global.clear > 0)
            editor_verify_capture_goal();
        var _idx = clear_check_goal_idx;
        var _already_stopped = clear_check_finish_pending;
        clear_check_finish_pending = false;
        clear_check_won = false;
        clear_check_mode = false;
        // pasamos un sec por el editor...
        if (!_already_stopped)
            editor_stop_playing(false);
        global.LE_play = 0;
        global.play_test_mode = false;
        global.clear = 0;
        scr_level_reset_warp_state();
        var _total = array_length(verify_goals);
        if (_cleared)
        {
            if (_total > 0 && (_idx < 0 || _idx >= _total))
            {
                level_cleared = false;
                show_message_async("No se pudo identificar la salida que tocaste. Volve a verificar desde Subir.");
                return;
            }
            if (_idx >= 0 && _idx < _total)
                verify_done[_idx] = true;
            if (!editor_verify_record_write())
            {
                editor_upload_invalidate();
                show_message_async("El nivel cambio durante la prueba. Volve a verificarlo.");
                return;
            }
            if (_total == 0 || editor_verify_pending_count() == 0)
            {
                editor_prepare_upload();
                return;
            }
        }
        // cada salida se comprueba desde el inicio publico, no desde la ultima zona
        if (!editor_upload_select_start())
        {
            editor_upload_invalidate();
            return;
        }
        level_cleared = false;
        clear_check_mode = true;
        clear_check_goal_idx = -1;
        if (instance_exists(obj_editor_mario_spawn))
        {
            verify_mario_x = obj_editor_mario_spawn.x;
            verify_mario_y = obj_editor_mario_spawn.y;
        }
        global._es_warp = false;
        editor_play_level();
    }
}

// popup de progreso
function editor_verify_draw_toast()
{
    with (obj_editor_manager)
    {
        if (verify_toast_anim <= 0)
            exit;
        
        draw_set_font(global.font);
        var _w = string_width(verify_toast_txt) + 34;
        var _h = 22;
        var _x = 384 - _w - 6;
        var _y = -(_h + 8) + ((_h + 16) * verify_toast_anim);
        draw_set_alpha(0.75 * verify_toast_anim);
        draw_set_color(c_black);
        draw_roundrect(_x, _y, _x + _w, _y + _h, false);
        draw_set_alpha(verify_toast_anim);
        draw_set_color(#FFF200);
        draw_roundrect(_x, _y, _x + _w, _y + _h, true);
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_text(_x + 6, _y + (_h / 2), verify_toast_txt);
        
        if (sprite_exists(verify_toast_spr))
            draw_sprite_stretched(verify_toast_spr, 0, _x + _w - 22, _y + 3, 16, 16);
        
        draw_set_valign(fa_top);
        draw_set_alpha(1);
    }
}


// la subida usa el proyecto completo, no una copia suelta de la zona visible
function editor_upload_is_modern()
{
    return instance_exists(obj_editor_manager) && !obj_editor_manager.is_legacy_level;
}

function editor_upload_select_start()
{
    if (editor_upload_is_modern() && obj_editor_manager.editor_rooms_enabled)
        return editor_rooms_switch(0, false);
    return true;
}

// leemos los nombres de las claves y dejamos que ini decodifique los valores
function editor_upload_ini_entries(_path)
{
    var _entries = [];
    if (!file_exists(_path))
        return _entries;
    var _in = file_text_open_read(_path);
    if (_in < 0)
        return _entries;
    var _section = "";
    while (!file_text_eof(_in))
    {
        var _line = string_trim(file_text_read_string(_in));
        file_text_readln(_in);
        if (string_char_at(_line, 1) == chr(65279))
            _line = string_delete(_line, 1, 1);
        var _len = string_length(_line);
        if (_len == 0)
            continue;
        var _first = string_char_at(_line, 1);
        if (_first == ";" || _first == "#")
            continue;
        if (_first == "[" && string_char_at(_line, _len) == "]")
        {
            _section = string_copy(_line, 2, _len - 2);
            continue;
        }
        var _eq = string_pos("=", _line);
        if (_section != "" && _eq > 1)
        {
            var _key = string_trim(string_copy(_line, 1, _eq - 1));
            array_push(_entries, { section: _section, key: _key, value: "" });
        }
    }
    file_text_close(_in);
    ini_open(_path);
    for (var _i = 0; _i < array_length(_entries); _i++)
        _entries[_i].value = ini_read_string(_entries[_i].section, _entries[_i].key, "");
    ini_close();
    return _entries;
}

function editor_upload_hash_part(_value)
{
    var _s = string(_value);
    return string(string_length(_s)) + ":" + _s;
}

// incluye opciones, capas, modulos, generadores y enlaces de todas las zonas
function editor_upload_hash_file(_path)
{
    var _signature = editor_upload_signature_entries(editor_upload_ini_entries(_path));
    if (instance_exists(obj_editor_manager))
        obj_editor_manager.verify_last_components = _signature.components;
    return _signature.hash;
}

function editor_upload_goals_file(_path)
{
    var _goals = [];
    if (!file_exists(_path))
        return _goals;
    ini_open(_path);
    var _count = max(1, floor(ini_read_real("rooms", "count", 1)));
    var _sections = ["colocado", "colocadoblock", "colocado9"];
    for (var _room = 0; _room < _count; _room++)
    {
        var _suffix = (_room == 0) ? "" : ("_" + string(_room + 1));
        var _uid = ini_read_real("rooms", string(_room) + "_uid", _room + 1);
        for (var _s = 0; _s < array_length(_sections); _s++)
        {
            var _section = _sections[_s] + _suffix;
            for (var _n = 0; ini_key_exists(_section, string(_n) + "0"); _n++)
            {
                var _object = ini_read_string(_section, string(_n) + "0", "");
                if (_object != "obj_goalgate" && _object != "obj_flagpole" && _object != "obj_boxpanel")
                    continue;
                var _x = ini_read_real(_section, string(_n) + "1", 0);
                var _y = ini_read_real(_section, string(_n) + "2", 0);
                array_push(_goals, _object + "|" + string(_x) + "|" + string(_y) + "|" + string(_uid));
            }
        }
    }
    ini_close();
    var _sorted = ds_list_create();
    for (var _i = 0; _i < array_length(_goals); _i++)
        ds_list_add(_sorted, _goals[_i]);
    ds_list_sort(_sorted, true);
    for (var _i = 0; _i < ds_list_size(_sorted); _i++)
        _goals[_i] = ds_list_find_value(_sorted, _i);
    ds_list_destroy(_sorted);
    return _goals;
}

function editor_upload_goal_info(_entry)
{
    var _parts = string_split(_entry, "|");
    if (array_length(_parts) < 3)
        return undefined;
    return {
        object: _parts[0],
        x: real(_parts[1]),
        y: real(_parts[2]),
        room_uid: (array_length(_parts) >= 4) ? real(_parts[3]) : 1
    };
}

function editor_upload_pick_goal(_goals, _room_uid, _x, _y)
{
    var _best = -1;
    var _best_d = 128;
    for (var _i = 0; _i < array_length(_goals); _i++)
    {
        var _g = editor_upload_goal_info(_goals[_i]);
        if (is_undefined(_g) || _g.room_uid != _room_uid)
            continue;
        var _d = point_distance(_x, _y, _g.x, _g.y);
        if (_d < _best_d)
        {
            _best_d = _d;
            _best = _i;
        }
    }
    return _best;
}

function editor_upload_invalidate()
{
    if (!instance_exists(obj_editor_manager))
        return;
    with (obj_editor_manager)
    {
        clear_check_mode = false;
        clear_check_won = false;
        clear_check_finish_pending = false;
        clear_check_play_pending = false;
        upload_after_screenshot = false;
        screenshot_pending = false;
        verify_upload_file_hash = "";
        verify_record_hash = "";
        verify_record_progress = false;
        verify_done = array_create(array_length(verify_goals), false);
        verify_tampered = true;
        level_cleared = false;
        level_modified_since_clear = true;
        global.disable_editor_controls = 0;
    }
}

// al publicar comprobamos los mismos bytes que quedaron aprobados
function editor_upload_file_is_verified(_path)
{
    if (!instance_exists(obj_editor_manager) || !file_exists(_path))
        return false;
    var _m = instance_find(obj_editor_manager, 0);
    return _path == _m.clear_check_temp_level
        && _m.verify_upload_file_hash != ""
        && _m.verify_record_hash == _m.verify_active_hash
        && string_lower(md5_file(_path)) == _m.verify_upload_file_hash;
}


function editor_upload_signature_number(_value)
{
    var _original = string(_value);
    var _s = _original;
    var _negative = false;
    var _first = string_char_at(_s, 1);
    if (_first == "-" || _first == "+")
    {
        _negative = (_first == "-");
        _s = string_delete(_s, 1, 1);
    }
    var _p = string_pos(".", _s);
    var _whole = _s;
    var _fraction = "";
    if (_p > 0)
    {
        _whole = string_copy(_s, 1, _p - 1);
        _fraction = string_copy(_s, _p + 1, string_length(_s) - _p);
    }
    if ((_whole == "" && _fraction == "")
        || string_digits(_whole) != _whole || string_digits(_fraction) != _fraction)
        return _original;
    while (string_length(_whole) > 1 && string_char_at(_whole, 1) == "0")
        _whole = string_delete(_whole, 1, 1);
    if (_whole == "") _whole = "0";
    while (_fraction != "" && string_char_at(_fraction, string_length(_fraction)) == "0")
        _fraction = string_delete(_fraction, string_length(_fraction), 1);
    if (_whole == "0" && _fraction == "") _negative = false;
    return (_negative ? "-" : "") + _whole + ((_fraction == "") ? "" : ("." + _fraction));
}


function editor_upload_signature_base(_section)
{
    var _p = string_last_pos("_", _section);
    if (_p > 0)
    {
        var _tail = string_copy(_section, _p + 1, string_length(_section) - _p);
        if (_tail != "" && string_digits(_tail) == _tail)
            return string_copy(_section, 1, _p - 1);
    }
    return _section;
}


function editor_upload_signature_address(_section, _key)
{
    var _base = editor_upload_signature_base(_section);
    var _a = { base: _base, row: "", field: _key, ignore: false };
    // estos contadores reservan ids para futuras ediciones, no cambian el mapa
    if ((_base == "rooms" && (_key == "next_uid" || _key == "next_warp_uid"))
        || (_base == "editor_warps" && _key == "next_uid"))
    {
        _a.ignore = true;
        return _a;
    }
    if (_base == "editor_warps" || _base == "colocado_modulo")
    {
        var _p = string_pos("_", _key);
        if (_p > 1)
        {
            var _prefix = string_copy(_key, 1, _p - 1);
            if (string_digits(_prefix) == _prefix)
            {
                _a.row = editor_upload_signature_number(_prefix);
                _a.field = string_copy(_key, _p + 1, string_length(_key) - _p);
                if (_base == "editor_warps"
                    && (_a.field == "geometry_status" || _a.field == "geometry_text"))
                    _a.ignore = true;
            }
        }
        return _a;
    }
    var _width = 0;
    switch (_base)
    {
        case "colocado":
        case "colocado9":
        case "colocadoblock":
        case "colocado_gen":
        case "colocado_dark":
        case "colocado_light":
            _width = 1;
            break;
        case "colocado8":
            _width = 2;
            break;
    }
    var _len = string_length(_key);
    if (_width > 0 && _len > _width && string_digits(_key) == _key)
    {
        _a.row = editor_upload_signature_number(string_copy(_key, 1, _len - _width));
        _a.field = editor_upload_signature_number(string_copy(_key, _len - _width + 1, _width));
    }
    return _a;
}


function editor_upload_signature_value(_address, _value)
{
    // las reglas conservan su orden, solo normalizamos sus numeros y booleanos
    if (_address.base == "colocado_modulo" && string_char_at(_address.field, 1) == "r")
    {
        var _index = string_delete(_address.field, 1, 1);
        if (_index != "" && string_digits(_index) == _index)
        {
            var _parts = string_split(_value, "|");
            if (array_length(_parts) == 8)
            {
                _parts[2] = editor_upload_signature_number(_parts[2]);
                _parts[5] = editor_upload_signature_number(_parts[5]);
                _parts[6] = editor_upload_signature_number(_parts[6]);
                if (_parts[7] == "true") _parts[7] = "1";
                if (_parts[7] == "false") _parts[7] = "0";
                var _result = _parts[0];
                for (var _i = 1; _i < 8; _i++)
                    _result += "|" + _parts[_i];
                return _result;
            }
        }
    }
    return editor_upload_signature_number(_value);
}


function editor_upload_signature_section(_line)
{
    var _p = string_pos(":", _line);
    var _len = real(string_copy(_line, 2, _p - 2));
    return string_copy(_line, _p + 1, _len);
}


function editor_upload_signature_entries(_entries)
{
    if (array_length(_entries) == 0)
        return { hash: "", components: [] };
    var _rows = ds_map_create();
    var _lines = ds_list_create();
    for (var _i = 0; _i < array_length(_entries); _i++)
    {
        var _e = _entries[_i];
        var _a = editor_upload_signature_address(_e.section, _e.key);
        if (_a.ignore)
            continue;
        var _field = editor_upload_hash_part(_a.field)
            + editor_upload_hash_part(editor_upload_signature_value(_a, _e.value));
        if (_a.row == "")
        {
            ds_list_add(_lines, "s" + editor_upload_hash_part(_e.section) + _field);
            continue;
        }
        var _key = editor_upload_hash_part(_e.section) + editor_upload_hash_part(_a.row);
        if (!ds_map_exists(_rows, _key))
            ds_map_add(_rows, _key, { section: _e.section, fields: ds_list_create() });
        var _row = ds_map_find_value(_rows, _key);
        ds_list_add(_row.fields, _field);
    }
    var _key = ds_map_find_first(_rows);
    while (!is_undefined(_key))
    {
        var _row = ds_map_find_value(_rows, _key);
        ds_list_sort(_row.fields, true);
        var _line = "r" + editor_upload_hash_part(_row.section);
        for (var _i = 0; _i < ds_list_size(_row.fields); _i++)
            _line += ds_list_find_value(_row.fields, _i);
        ds_list_add(_lines, _line);
        ds_list_destroy(_row.fields);
        _key = ds_map_find_next(_rows, _key);
    }
    ds_map_destroy(_rows);
    ds_list_sort(_lines, true);
    var _blob = "editor4-upload-v2\n";
    var _sections = ds_map_create();
    for (var _i = 0; _i < ds_list_size(_lines); _i++)
    {
        var _line = ds_list_find_value(_lines, _i) + "\n";
        _blob += _line;
        var _section = editor_upload_signature_section(_line);
        if (!ds_map_exists(_sections, _section))
            ds_map_add(_sections, _section, "");
        ds_map_replace(_sections, _section, ds_map_find_value(_sections, _section) + _line);
    }
    ds_list_destroy(_lines);
    var _components = [];
    var _key = ds_map_find_first(_sections);
    while (!is_undefined(_key))
    {
        array_push(_components, { section: _key, hash: string_lower(md5_string_unicode(ds_map_find_value(_sections, _key))) });
        _key = ds_map_find_next(_sections, _key);
    }
    ds_map_destroy(_sections);
    return { hash: string_lower(md5_string_unicode(_blob)), components: _components };
}


function editor_upload_remember_signature()
{
    if (!instance_exists(obj_editor_manager))
        return;
    var _m = instance_find(obj_editor_manager, 0);
    _m.verify_active_components = [];
    if (editor_upload_is_modern() && variable_instance_exists(_m, "verify_last_components"))
        _m.verify_active_components = _m.verify_last_components;
}


function editor_upload_report_mismatch(_expected, _actual)
{
    show_debug_message("CLEAR CHECK: huella esperada=" + _expected + " actual=" + _actual);
    if (_actual == "")
    {
        show_debug_message("CLEAR CHECK: no se pudo guardar o leer el proyecto completo");
        return;
    }
    if (!instance_exists(obj_editor_manager))
        return;
    var _m = instance_find(obj_editor_manager, 0);
    if (!variable_instance_exists(_m, "verify_active_components")
        || !variable_instance_exists(_m, "verify_last_components"))
        return;
    var _old = _m.verify_active_components;
    var _new = _m.verify_last_components;
    for (var _i = 0; _i < array_length(_old); _i++)
    {
        var _found = false;
        for (var _j = 0; _j < array_length(_new); _j++)
        {
            if (_old[_i].section != _new[_j].section)
                continue;
            _found = true;
            if (_old[_i].hash != _new[_j].hash)
                show_debug_message("CLEAR CHECK: cambio en [" + _old[_i].section + "]");
            break;
        }
        if (!_found)
            show_debug_message("CLEAR CHECK: falta [" + _old[_i].section + "]");
    }
    for (var _j = 0; _j < array_length(_new); _j++)
    {
        var _found = false;
        for (var _i = 0; _i < array_length(_old); _i++)
        {
            if (_old[_i].section == _new[_j].section)
            {
                _found = true;
                break;
            }
        }
        if (!_found)
            show_debug_message("CLEAR CHECK: se agrego [" + _new[_j].section + "]");
    }
}
