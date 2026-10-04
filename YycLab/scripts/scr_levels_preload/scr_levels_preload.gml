/*
 precarga por categorias
 pide los cuatro listados del browser juntos y despues va bajando las miniaturas a cache_img.
 usa preload_phase, preload_queue y las listas preload_*_thumbs.
 deja la cola vacia y la fase en 0. las miniaturas van a cache_img dentro del working directory.
*/
function scr_preload_init2()
{
    var cache_path;
    
    if (scr_isWindows())
        cache_path = working_directory + "/cache_img/";
    else
        cache_path = getDire2("SM4J", "cache_img") + "/";
    
    if (!directory_exists(cache_path))
        directory_create(cache_path);
    
    // primero se cuenta cuantos png hay guardados
    var file_count = 0;
    var file_name = file_find_first(cache_path + "*.png", 0);
    
    while (file_name != "")
    {
        file_count += 1;
        file_name = file_find_next();
    }
    
    file_find_close();
   /*
   si hay mas de 100 borramos todo menos las fotos de perfil(no tiene sentido borrar las mas viejas nomas
   y asi vamos evitando que se le llenen de imgs que al par de dias ya no van a 
   ser utiles
   */
    if (file_count > 100)
    {
        show_debug_message("PRELOAD: Limpiando cache (" + string(file_count) + " archivos)");
        file_name = file_find_first(cache_path + "*.png", 0);
        
        while (file_name != "")
        {
            // las fotos de perfil no son miniaturas de niveles, no se borran
            if (string_pos("profile_", file_name) != 1)
                file_delete(cache_path + file_name);
            file_name = file_find_next();
        }
        
        file_find_close();
        show_debug_message("PRELOAD: Cache limpiado");
    }
    
    // de aca para abajo las globals del sistema por categorias. los -1 son
    // los request id, marcan que todavia no se pidio nada
    global.preload_queue = ds_list_create();
    global.preload_active = false;
    global.preload_current_request = -1;
    global.preload_current_path = "";
    global.preload_current_id = -1;
    global.preload_phase = 0;
    global.preload_data_loaded = false;
    global.preload_enabled = true;
    global.preload_request_featured = -1;
    global.preload_request_recent = -1;
    global.preload_request_popular = -1;
    global.preload_request_admin = -1;
    global.preload_featured_thumbs = ds_list_create();
    global.preload_recent_thumbs = ds_list_create();
    global.preload_popular_thumbs = ds_list_create();
    global.preload_admin_thumbs = ds_list_create();
    show_debug_message("PRELOAD: Sistema inicializado");
    return 1;
}
// manda los cuatro pedidos de categoria juntos y guarda cada request id en su global.
function scr_preload_start2()
{
    if (!global.preload_enabled)
        exit;
    
    if (!variable_global_exists("supabase_url"))
        exit;
    
    show_debug_message("PRELOAD: Iniciando carga de datos...");
    global.preload_request_featured = scr_get_featured_levels();
    global.preload_request_recent = scr_supabase_get_levels(0, 16, "recent", "", "");
    global.preload_request_popular = scr_supabase_get_levels(0, 16, "total_likes", "", "");
    global.preload_request_admin = scr_get_admin_featured_levels();
    return 1;
}
// baja la proxima miniatura de la cola. las que ya estan en cache_img se saltean, asi que en la
// segunda vuelta no descarga nada.
function scr_preload_step()
{
    if (!global.preload_enabled)
        exit;
    
    // fase 4 es terminado, de ahi no se vuelve
    if (global.preload_phase >= 4)
        exit;
    
    if (!global.preload_active && ds_list_size(global.preload_queue) > 0)
    {
        var next_item = ds_list_find_value(global.preload_queue, 0);
        ds_list_delete(global.preload_queue, 0);
        
        if (ds_exists(next_item, ds_type_map))
        {
            var thumb_url = ds_map_find_value(next_item, "url");
            var level_id = ds_map_find_value(next_item, "id");
            var thumb_path;
            
            if (scr_isWindows())
                thumb_path = working_directory + "/cache_img/level_" + string(level_id) + ".png";
            else
                thumb_path = getDire2("SM4J", "cache_img") + "/level_" + string(level_id) + ".png";
            
            // lo que ya esta en disco no se vuelve a pedir
            if (!file_exists(thumb_path))
            {
                global.preload_active = true;
                global.preload_current_path = thumb_path;
                global.preload_current_id = level_id;
                global.preload_current_request = http_get_file(thumb_url, thumb_path);
                show_debug_message("PRELOAD: Descargando thumbnail nivel " + string(level_id));
            }
            
            // el map se destruye se haya descargado o no, lo creo parse_levels
            ds_map_destroy(next_item);
        }
    }
    
    if (ds_list_size(global.preload_queue) == 0 && !global.preload_active && global.preload_data_loaded)
    {
        // las fases van una categoria por vez para no abrir cuatro descargas juntas,
        // recien se pasa a la siguiente cuando la cola quedo vacia
        global.preload_phase += 1;
        
        if (global.preload_phase == 1)
        {
            scr_preload_add_to_queue(global.preload_recent_thumbs);
            show_debug_message("PRELOAD: Fase 2 - Niveles recientes");
        }
        else if (global.preload_phase == 2)
        {
            scr_preload_add_to_queue(global.preload_popular_thumbs);
            show_debug_message("PRELOAD: Fase 3 - Niveles populares");
        }
        else if (global.preload_phase == 3)
        {
            scr_preload_add_to_queue(global.preload_admin_thumbs);
            show_debug_message("PRELOAD: Fase 4 - Niveles destacados admin");
        }
        else if (global.preload_phase >= 4)
        {
            show_debug_message("PRELOAD: ¡Completado!");
            // al terminar se sueltan las cuatro listas, las miniaturas ya quedaron en disco
            ds_list_destroy(global.preload_featured_thumbs);
            ds_list_destroy(global.preload_recent_thumbs);
            ds_list_destroy(global.preload_popular_thumbs);
            ds_list_destroy(global.preload_admin_thumbs);
        }
    }
}
// suma una lista de miniaturas a la cola y devuelve cuantas quedaron.
function scr_preload_add_to_queue(arg0)
{
    for (var i = 0; i < ds_list_size(arg0); i++)
    {
        var item = ds_list_find_value(arg0, i);
        
        if (ds_exists(item, ds_type_map))
        {
            var new_item = ds_map_create();
            ds_map_add(new_item, "url", ds_map_find_value(item, "url"));
            ds_map_add(new_item, "id", ds_map_find_value(item, "id"));
            ds_list_add(global.preload_queue, new_item);
        }
    }
    
    return ds_list_size(arg0);
}
// reparte todos los async de este sistema: los cuatro listados de categoria y las descargas de
// miniatura. compara el request id contra cada global para saber de cual se trata.
function scr_preload_async_http()
{
    var request_id = ds_map_find_value(async_load, "id");
    var status = ds_map_find_value(async_load, "status");
    
    // primero se descarta la descarga de miniatura, que es la que mas veces cae aca
    if (global.preload_active && request_id == global.preload_current_request)
    {
        global.preload_active = false;
        global.preload_current_request = -1;
        
        if (status == 0)
            show_debug_message("PRELOAD: Thumbnail " + string(global.preload_current_id) + " descargado");
        else
            show_debug_message("PRELOAD: Error descargando thumbnail " + string(global.preload_current_id));
        
        global.preload_current_path = "";
        global.preload_current_id = -1;
        exit;
    }
    
    // featured se parsea a mano abajo, las otras tres usan scr_preload_parse_levels
    if (request_id == global.preload_request_featured)
    {
        global.preload_request_featured = -1;
        
        if (status == 0)
        {
            var result = ds_map_find_value(async_load, "result");
            
            if (is_string(result) && result != "" && result != "[]")
            {
                var pos = 1;
                var len = string_length(result);
                
                while (pos < len)
                {
                    // engancha cada objeto por el campo id, que en esta respuesta siempre viene primero
                    var found = string_pos("{\"id\":", string_copy(result, pos, (len - pos) + 1));
                    
                    if (found == 0)
                    {
                        break;
                    }
                    else
                    {
                        pos = (pos + found) - 1;
                        var depthy = 0;
                        var obj_startx = pos;
                        var obj_end = pos;
                        var c = pos;
                        
                        while (c <= len)
                        {
                            var ch = string_char_at(result, c);
                            
                            if (ch == "{")
                                depthy += 1;
                            
                            if (ch == "}")
                                depthy -= 1;
                            
                            // cuenta llaves para cortar el objeto completo
                            if (depthy == 0)
                            {
                                obj_end = c;
                                break;
                            }
                            else
                            {
                                c++;
                                continue;
                            }
                        }
                        
                        var obj_str = string_copy(result, obj_startx, (obj_end - obj_startx) + 1);
                        var thumb_name = scr_json_get_value(obj_str, "thumbnail_name");
                        var level_id = scr_json_get_value(obj_str, "id");
                        
                        if (thumb_name != "" && level_id != "")
                        {
                            var thumb_url = scr_r2_get_thumbnail_url(thumb_name);
                            var item = ds_map_create();
                            ds_map_add(item, "url", thumb_url);
                            ds_map_add(item, "id", level_id);
                            ds_list_add(global.preload_featured_thumbs, item);
                        }
                        
                        pos = obj_end + 1;
                        continue;
                    }
                }
            }
            
            show_debug_message("PRELOAD: Featured cargados: " + string(ds_list_size(global.preload_featured_thumbs)));
        }
        
        // cada rama avisa al terminar, el flag se prende recien cuando volvieron las cuatro
        scr_preload_check_data_loaded();
        exit;
    }
    
    if (request_id == global.preload_request_recent)
    {
        global.preload_request_recent = -1;
        
        if (status == 0)
        {
            var result = ds_map_find_value(async_load, "result");
            scr_preload_parse_levels(result, global.preload_recent_thumbs);
            show_debug_message("PRELOAD: Recientes cargados: " + string(ds_list_size(global.preload_recent_thumbs)));
        }
        
        scr_preload_check_data_loaded();
        exit;
    }
    
    if (request_id == global.preload_request_popular)
    {
        global.preload_request_popular = -1;
        
        if (status == 0)
        {
            var result = ds_map_find_value(async_load, "result");
            scr_preload_parse_levels(result, global.preload_popular_thumbs);
            show_debug_message("PRELOAD: Populares cargados: " + string(ds_list_size(global.preload_popular_thumbs)));
        }
        
        scr_preload_check_data_loaded();
        exit;
    }
    
    if (request_id == global.preload_request_admin)
    {
        global.preload_request_admin = -1;
        
        if (status == 0)
        {
            var result = ds_map_find_value(async_load, "result");
            scr_preload_parse_levels(result, global.preload_admin_thumbs);
            show_debug_message("PRELOAD: Admin featured cargados: " + string(ds_list_size(global.preload_admin_thumbs)));
        }
        
        scr_preload_check_data_loaded();
        exit;
    }
}
// pasa la respuesta de un listado a la estructura que usa el browser y encola sus miniaturas.
function scr_preload_parse_levels(arg0, arg1)
{
    if (!is_string(arg0) || arg0 == "" || arg0 == "[]")
        exit;
    
    var levels_list = scr_json_parse_array(arg0);
    var count = ds_list_size(levels_list);
    
    for (var i = 0; i < count; i++)
    {
        var level_map = ds_list_find_value(levels_list, i);
        var thumb_name = ds_map_find_value(level_map, "thumbnail_name");
        var level_id = ds_map_find_value(level_map, "id");
        
        if (!is_undefined(thumb_name) && thumb_name != "" && !is_undefined(level_id) && level_id != "")
        {
            var thumb_url = scr_r2_get_thumbnail_url(thumb_name);
            var item = ds_map_create();
            ds_map_add(item, "url", thumb_url);
            ds_map_add(item, "id", level_id);
            ds_list_add(arg1, item);
        }
        
        // scr_json_parse_array crea un map por nivel, si no se destruyen quedan colgados
        ds_map_destroy(level_map);
    }
    
    ds_list_destroy(levels_list);
}
// prende preload_data_loaded recien cuando volvieron los cuatro pedidos.
function scr_preload_check_data_loaded()
{
    if (global.preload_request_featured == -1 && global.preload_request_recent == -1 && global.preload_request_popular == -1 && global.preload_request_admin == -1)
    {
        global.preload_data_loaded = true;
        scr_preload_add_to_queue(global.preload_featured_thumbs);
        show_debug_message("PRELOAD: Todos los datos cargados, iniciando descargas...");
        show_debug_message("PRELOAD: Fase 1 - Featured de la semana");
    }
}
// los niveles mas dificiles segun el analisis del server.
function scr_get_hardest_levels(arg0, arg1)
{
    var url = global.supabase_url + "/rest/v1/rpc/get_hardest_levels";
    var headers = ds_map_create();
    ds_map_add(headers, "apikey", global.supabase_key);
    ds_map_add(headers, "Authorization", "Bearer " + global.supabase_key);
    ds_map_add(headers, "Content-Type", "application/json");
    var body = json_stringify(
    {
        p_limit: int64(arg0),
        p_offset: int64(arg1)
    });
    var request = http_request(url, "POST", headers, body);
    ds_map_destroy(headers);
    return request;
}





// precarga por paginas
// el otro sistema. pide de a paginas de 16 y guarda todo en preloaded_data y preloaded_thumbs.
// no comparte ni una global con el de arriba y obj_level_loader llama a los dos, asi que
// no se pueden mezclar ni reemplazar uno por el otro.
// estado en 0, dos paginas de 16 y las estructuras vacias. no comparte ninguna global con el
// sistema por categorias.
function scr_preload_init()
{
    global.preload_state = 0;
    global.preload_page = 0;
    global.preload_max_pages = 2;
    global.preload_request = -1;
    global.preload_levels_per_page = 16;
    global.preloaded_data = ds_list_create();
    global.preload_data_ready = false;
    global.preload_thumb_queue = ds_list_create();
    global.preload_thumb_index = 0;
    global.preload_thumb_max = 12;
    global.preload_thumb_request = -1;
    global.preload_thumb_downloading = false;
    global.preloaded_thumbs = ds_map_create();
    global.preload_delay_timer = 0;
    global.preload_delay_frames = 30;
    global.preload_debug = true;
    
    if (global.preload_debug)
        show_debug_message("PRELOAD: Sistema inicializado");
    
    return 1;
}
// pasa el estado a 1 y pide la primera pagina.
function scr_preload_start()
{
    if (!variable_global_exists("preload_state"))
        scr_preload_init();
    
    if (global.preload_state != 0)
        return 0;
    
    if (!variable_global_exists("supabase_url"))
        scr_supabase_init();
    
    global.preload_state = 1;
    global.preload_page = 0;
    ds_list_clear(global.preloaded_data);
    
    if (global.preload_debug)
        show_debug_message("PRELOAD: Iniciando carga de datos...");
    
    global.preload_request = scr_preload_fetch_page(0);
    return 1;
}
// pide una pagina del listado ordenado por fecha.
function scr_preload_fetch_page(arg0)
{
    var _offset = arg0 * global.preload_levels_per_page;
    var _select = "id,name,description,author_id,author_name,file_name,thumbnail_name,downloads,created_at,attempts,victories,unique_players,total_plays,first_clear_user_id,first_clear_username,tags,total_likes,texture_used,cold_storage_id";
    var _url = global.supabase_url + "/rest/v1/levels?select=" + _select;
    _url += "&order=created_at.desc";
    _url += ("&limit=" + string(global.preload_levels_per_page));
    _url += ("&offset=" + string(_offset));
    var _headers = ds_map_create();
    ds_map_add(_headers, "apikey", global.supabase_key);
    ds_map_add(_headers, "Authorization", "Bearer " + global.supabase_key);
    var _request = http_request(_url, "GET", _headers, "");
    ds_map_destroy(_headers);
    
    if (global.preload_debug)
        show_debug_message("PRELOAD: Fetching page " + string(arg0) + " (offset " + string(_offset) + ")");
    
    return _request;
}
// reparte los async de este sistema. cuando termino de traer todas las paginas pasa al estado 2,
// que es el de bajar miniaturas.
function scr_preload_handle_async(arg0)
{
    // devolver 0 significa que el evento no era de aca y el que llamo sigue con lo suyo
    if (!variable_global_exists("preload_state"))
        return 0;
    
    var request_id = ds_map_find_value(arg0, "id");
    var status = ds_map_find_value(arg0, "status");
    
    if (global.preload_request != -1 && request_id == global.preload_request)
    {
        global.preload_request = -1;
        
        if (status == 0)
        {
            var result = ds_map_find_value(arg0, "result");
            scr_debug_log("=== RAW SUPABASE PRELOAD RESPONSE ===");
            var _cold_pos = string_pos("cold_storage_id", result);
            scr_debug_log("cold_storage_id encontrado en posicion: " + string(_cold_pos));
            
            if (_cold_pos > 0)
            {
                var _context = string_copy(result, _cold_pos, 150);
                scr_debug_log("Contexto: " + _context);
            }
            else
            {
                scr_debug_log("!!! cold_storage_id NO EXISTE en la respuesta de PRELOAD !!!");
                scr_debug_log("Primeros 500 chars: " + string_copy(result, 1, 500));
            }
            
            scr_debug_log("=== END RAW PRELOAD ===");
            
            if (!is_undefined(result) && is_string(result) && result != "" && result != "[]")
            {
                ds_list_add(global.preloaded_data, result);
                
                if (global.preload_debug)
                    show_debug_message("PRELOAD: Página " + string(global.preload_page) + " recibida (" + string(string_length(result)) + " bytes)");
                
                // las paginas se piden de a una, la que sigue arranca cuando baja el delay
                global.preload_page++;
                
                if (global.preload_page < global.preload_max_pages)
                {
                    global.preload_delay_timer = global.preload_delay_frames;
                }
                else
                {
                    // estado 2 es bajar miniaturas, 3 es terminado
                    global.preload_state = 2;
                    global.preload_data_ready = true;
                    scr_preload_prepare_thumbs();
                    
                    if (global.preload_debug)
                        show_debug_message("PRELOAD: Data completa! " + string(ds_list_size(global.preloaded_data)) + " páginas guardadas");
                }
            }
            else
            {
                global.preload_state = 2;
                global.preload_data_ready = true;
                scr_preload_prepare_thumbs();
            }
        }
        // en error no se pierde la pagina, se reintenta en 60 frames
        else if (status < 0)
        {
            if (global.preload_debug)
                show_debug_message("PRELOAD: Error en request, reintentando...");
            
            global.preload_delay_timer = 60;
        }
        
        return 1;
    }
    
    if (global.preload_thumb_request != -1 && request_id == global.preload_thumb_request)
    {
        global.preload_thumb_downloading = false;
        global.preload_thumb_request = -1;
        
        if (status == 0)
        {
            var current_id = ds_list_find_value(global.preload_thumb_queue, global.preload_thumb_index);
            var thumb_path = scr_preload_get_thumb_path(current_id);
            
            if (file_exists(thumb_path))
            {
                // los sprites quedan en memoria hasta cerrar el juego, por eso el tope
                // de preload_thumb_max
                var spr = sprite_add(thumb_path, 1, false, false, 0, 0);
                
                if (spr != -1)
                {
                    ds_map_add(global.preloaded_thumbs, string(current_id), spr);
                    
                    if (global.preload_debug)
                        show_debug_message("PRELOAD THUMB: " + string(current_id) + " cargado");
                }
            }
        }
        
        global.preload_thumb_index++;
        
        if (global.preload_thumb_index >= ds_list_size(global.preload_thumb_queue) || global.preload_thumb_index >= global.preload_thumb_max)
        {
            global.preload_state = 3;
            
            if (global.preload_debug)
                show_debug_message("PRELOAD: ¡COMPLETADO! " + string(ds_map_size(global.preloaded_thumbs)) + " thumbnails");
        }
        else
        {
            global.preload_delay_timer = 10;
        }
        
        return 1;
    }
    
    return 0;
}
// arma la cola de miniaturas a partir de lo que se termino de bajar.
function scr_preload_prepare_thumbs()
{
    ds_list_clear(global.preload_thumb_queue);
    
    for (var p = 0; p < ds_list_size(global.preloaded_data); p++)
    {
        var json_str = ds_list_find_value(global.preloaded_data, p);
        var levels_list = scr_json_parse_array(json_str);
        
        for (var i = 0; i < ds_list_size(levels_list); i++)
        {
            var level_map = ds_list_find_value(levels_list, i);
            var level_id = ds_map_find_value(level_map, "id");
            var thumb_name = ds_map_find_value(level_map, "thumbnail_name");
            
            if (!is_undefined(level_id) && !is_undefined(thumb_name))
            {
                var info = ds_map_create();
                ds_map_add(info, "id", level_id);
                ds_map_add(info, "thumb_name", thumb_name);
                ds_list_add(global.preload_thumb_queue, info);
            }
            
            // lo que interesa ya se copio al info de arriba, el map original se tira
            ds_map_destroy(level_map);
        }
        
        ds_list_destroy(levels_list);
    }
    
    global.preload_thumb_index = 0;
    
    if (global.preload_debug)
        show_debug_message("PRELOAD: " + string(ds_list_size(global.preload_thumb_queue)) + " thumbnails en queue");
}
function scr_preload_get_thumb_path(arg0)
{
    if (scr_isWindows())
    {
        if (!directory_exists(working_directory + "/cache_img"))
            directory_create(working_directory + "/cache_img");
        
        return working_directory + "/cache_img/" + string(arg0) + ".png";
    }
    else
    {
        return getDire2("SM4J", "cache_img") + "/" + string(arg0) + ".png";
    }
}
// el paso a paso, va en el step. baja una miniatura por frame para no clavar el juego, y las
// que ya estan en disco las carga directo como sprite sin pedir nada.
function scr_preload_update()
{
    if (!variable_global_exists("preload_state"))
        return 0;
    
    // 0 sin arrancar y 3 terminado, en los dos casos no hay nada que hacer
    if (global.preload_state == 0 || global.preload_state == 3)
        return 0;
    
    // el delay entre pedidos es para no dispararlos todos en el mismo frame
    if (global.preload_delay_timer > 0)
    {
        global.preload_delay_timer--;
        return 0;
    }
    
    if (global.preload_state == 1 && global.preload_request == -1)
    {
        if (global.preload_page < global.preload_max_pages)
            global.preload_request = scr_preload_fetch_page(global.preload_page);
    }
    
    if (global.preload_state == 2 && !global.preload_thumb_downloading)
    {
        if (global.preload_thumb_index < ds_list_size(global.preload_thumb_queue) && global.preload_thumb_index < global.preload_thumb_max)
        {
            var info = ds_list_find_value(global.preload_thumb_queue, global.preload_thumb_index);
            
            if (ds_exists(info, ds_type_map))
            {
                var level_id = ds_map_find_value(info, "id");
                var thumb_name = ds_map_find_value(info, "thumb_name");
                var thumb_path = scr_preload_get_thumb_path(level_id);
                
                // si ya esta en disco se carga y se avanza en el mismo frame, sin pedir nada
                if (file_exists(thumb_path))
                {
                    var spr = sprite_add(thumb_path, 1, false, false, 0, 0);
                    
                    if (spr != -1)
                        ds_map_add(global.preloaded_thumbs, string(level_id), spr);
                    
                    global.preload_thumb_index++;
                }
                else
                {
                    var thumb_url = scr_r2_get_thumbnail_url(thumb_name);
                    global.preload_thumb_downloading = true;
                    global.preload_thumb_request = http_get_file(thumb_url, thumb_path);
                }
            }
            else
            {
                global.preload_thumb_index++;
            }
        }
        else
        {
            global.preload_state = 3;
            
            if (global.preload_debug)
                show_debug_message("PRELOAD: ¡COMPLETADO!");
        }
    }
    
    return 1;
}
function scr_preload_has_data()
{
    if (!variable_global_exists("preload_data_ready"))
        return false;
    
    return global.preload_data_ready && ds_list_size(global.preloaded_data) > 0;
}
function scr_preload_get_thumb(arg0)
{
    if (!variable_global_exists("preloaded_thumbs"))
        return -1;
    
    if (!ds_exists(global.preloaded_thumbs, ds_type_map))
        return -1;
    
    var key = string(arg0);
    
    if (ds_map_exists(global.preloaded_thumbs, key))
        return ds_map_find_value(global.preloaded_thumbs, key);
    
    return -1;
}
