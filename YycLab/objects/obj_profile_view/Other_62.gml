var request_id = ds_map_find_value(async_load, "id");
var status = ds_map_find_value(async_load, "status");
var http_status = ds_map_find_value(async_load, "http_status");

if (request_id == request_xp_stats)
{
    request_xp_stats = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        var temp_xp = scr_json_get_value(result, "total_xp");
        var temp_level = scr_json_get_value(result, "current_level");
        
        if (temp_xp != "" && temp_xp != "null" && temp_xp != "undefined")
        {
            user_total_xp = real(temp_xp);
            
            if (user_total_xp != user_total_xp)
                user_total_xp = 0;
            
            if (user_total_xp < 0)
                user_total_xp = 0;
        }
        else
        {
            user_total_xp = 0;
        }
        
        if (temp_level != "" && temp_level != "null" && temp_level != "undefined")
        {
            user_current_level = real(temp_level);
            
            if (user_current_level != user_current_level)
                user_current_level = 1;
            
            if (user_current_level < 1)
                user_current_level = 1;
        }
        else
        {
            user_current_level = 1;
        }
        
        user_xp_loaded = 1;
    }
}

if (request_id == request_profile)
{
    request_profile = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        profile_image_url = scr_json_get_value(result, "profile_image");
        bio = scr_json_get_value(result, "bio");
        member_since = scr_json_get_value(result, "created_at");
        
        if (string_length(member_since) > 10)
            member_since = string_copy(member_since, 1, 10);
        
        if (profile_image_loaded == 0 && profile_image_url != "" && profile_image_url != "0" && profile_image_url != "null")
        {
            profile_image_loading = 1;
            var img_path = working_directory + "/cache_img/profile_" + global.user_id + ".png";
            
            if (file_exists(img_path))
            {
                if (profile_image_sprite != -1 && sprite_exists(profile_image_sprite))
                    sprite_delete(profile_image_sprite);
                
                profile_image_sprite = sprite_add(img_path, 1, false, false, 0, 0);
                
                if (profile_image_sprite != -1)
                {
                    profile_image_loading = 0;
                    profile_image_loaded = 1;
                }
                else
                {
                    file_delete(img_path);
                    image_retry_count = 0;
                    profile_image_request = http_get_file(profile_image_url, img_path + ".dl");
                }
            }
            else
            {
                image_retry_count = 0;
                profile_image_request = http_get_file(profile_image_url, img_path + ".dl");
            }
        }
        
        global.user_profile_image = profile_image_url;
        global.user_bio = bio;
    }
}

if (request_id == request_stats)
{
    request_stats = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        levels_count = 0;
        total_likes = 0;
        total_downloads = 0;
        var pos = 1;
        var len = string_length(result);
        
        while (pos < len)
        {
            var found = string_pos("\"id\":", string_copy(result, pos, (len - pos) + 1));
            
            if (found == 0)
            {
                break;
            }
            else
            {
                levels_count += 1;
                pos = pos + found;
                var level_end = string_pos("},{", string_copy(result, pos, (len - pos) + 1));
                
                if (level_end == 0)
                    level_end = string_pos("}]", string_copy(result, pos, (len - pos) + 1));
                
                if (level_end == 0)
                    level_end = 500;
                
                var level_section = string_copy(result, pos, level_end + 1);
                var dl_pos = string_pos("\"downloads\":", level_section);
                
                if (dl_pos > 0)
                {
                    var num_start = dl_pos + 12;
                    var num_str = "";
                    var ch = string_char_at(level_section, num_start);
                    
                    while (ch == " ")
                    {
                        num_start += 1;
                        ch = string_char_at(level_section, num_start);
                    }
                    
                    while (ord(ch) >= 48 && ord(ch) <= 57)
                    {
                        num_str += ch;
                        num_start += 1;
                        ch = string_char_at(level_section, num_start);
                    }
                    
                    if (num_str != "")
                        total_downloads += real(num_str);
                }
                
                var likes_pos = string_pos("\"level_likes\":", level_section);
                
                if (likes_pos > 0)
                {
                    var likes_section = string_copy(level_section, likes_pos, 60);
                    var count_pos = string_pos("\"count\":", likes_section);
                    
                    if (count_pos > 0)
                    {
                        var num_start = count_pos + 8;
                        var num_str = "";
                        var ch = string_char_at(likes_section, num_start);
                        
                        while (ch == " ")
                        {
                            num_start += 1;
                            ch = string_char_at(likes_section, num_start);
                        }
                        
                        while (ord(ch) >= 48 && ord(ch) <= 57)
                        {
                            num_str += ch;
                            num_start += 1;
                            ch = string_char_at(likes_section, num_start);
                        }
                        
                        if (num_str != "")
                            total_likes += real(num_str);
                    }
                }
                
                pos += 10;
                continue;
            }
        }
        
        stats_loaded = 1;
    }
}

if (request_id == request_levels)
{
    request_levels = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        var levels_list = scr_json_parse_array(result);
        var count = ds_list_size(levels_list);
        
        for (var i = 0; i < count; i++)
        {
            var lvl = ds_list_find_value(levels_list, i);
            ds_list_add(my_levels, lvl);
        }
        
        ds_list_destroy(levels_list);
        my_levels_loaded = 1;
    }
}

if (request_id == request_badges)
{
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        
        for (var i = 0; i < ds_list_size(my_badges); i++)
        {
            var badge = ds_list_find_value(my_badges, i);
            
            if (ds_exists(badge, ds_type_map))
                ds_map_destroy(badge);
        }
        
        ds_list_clear(my_badges);
        
        if (string_pos("\"code\":", result) > 0)
        {
            if (badges_retry_count < badges_max_retries)
            {
                badges_retry_count += 1;
                show_debug_message("REINTENTANDO MEDALLAS (Error Code): " + string(badges_retry_count));
                request_badges = scr_load_my_badges();
                exit;
            }
            else
            {
                my_badges_loaded = 1;
                request_badges = -1;
                exit;
            }
        }
        
        var pos = 1;
        var len = string_length(result);
        
        while (pos < len)
        {
            var found = string_pos("{\"id\":", string_copy(result, pos, (len - pos) + 1));
            
            if (found == 0)
            {
                break;
            }
            else
            {
                pos = (pos + found) - 1;
                var next_obj = string_pos("{\"id\":", string_copy(result, pos + 5, len - pos - 4));
                var obj_end;
                
                if (next_obj > 0)
                    obj_end = next_obj + 3;
                else
                    obj_end = len - pos;
                
                var section = string_copy(result, pos, obj_end);
                var last_brace = 0;
                var temp_pos = string_length(section);
                
                while (temp_pos > 0)
                {
                    if (string_char_at(section, temp_pos) == "}")
                    {
                        last_brace = temp_pos;
                        break;
                    }
                    else
                    {
                        temp_pos -= 1;
                        continue;
                    }
                }
                
                if (last_brace > 0)
                    section = string_copy(section, 1, last_brace);
                
                var badge = ds_map_create();
                var user_badge_id = scr_json_get_value(section, "id");
                ds_map_add(badge, "user_badge_id", user_badge_id);
                var badge_id = scr_json_get_value(section, "badge_id");
                ds_map_add(badge, "badge_id", badge_id);
                var awarded_at = scr_json_get_value(section, "awarded_at");
                
                if (string_length(awarded_at) > 10)
                    awarded_at = string_copy(awarded_at, 1, 10);
                
                ds_map_add(badge, "awarded_at", awarded_at);
                var badges_pos = string_pos("\"badges\":", section);
                var badge_name, icon_name, badge_color;
                
                if (badges_pos > 0)
                {
                    var badges_section = string_copy(section, badges_pos, (string_length(section) - badges_pos) + 1);
                    badge_name = scr_json_get_value(badges_section, "name");
                    icon_name = scr_json_get_value(badges_section, "icon_name");
                    badge_color = scr_json_get_value(badges_section, "color");
                    badge_name = scr_clean_json_string(badge_name);
                    icon_name = scr_clean_json_string(icon_name);
                    badge_color = scr_clean_json_string(badge_color);
                }
                else
                {
                    badge_name = "BADGE";
                    icon_name = "star";
                    badge_color = "#FFD700";
                }
                
                ds_map_add(badge, "name", badge_name);
                ds_map_add(badge, "icon_name", icon_name);
                ds_map_add(badge, "color", badge_color);
                var profiles_pos = string_pos("\"profiles\":", section);
                var awarded_by_name;
                
                if (profiles_pos > 0)
                {
                    var profiles_section = string_copy(section, profiles_pos, 150);
                    awarded_by_name = scr_json_get_value(profiles_section, "username");
                    awarded_by_name = scr_clean_json_string(awarded_by_name);
                }
                else
                {
                    awarded_by_name = "Sistema";
                }
                
                ds_map_add(badge, "awarded_by_name", awarded_by_name);
                ds_list_add(my_badges, badge);
                pos += string_length(section);
                continue;
            }
        }
        
        my_badges_loaded = 1;
        badges_retry_count = 0;
        request_badges = -1;
    }
    else if (badges_retry_count < badges_max_retries)
    {
        badges_retry_count += 1;
        show_debug_message("REINTENTANDO MEDALLAS (Network Error): " + string(badges_retry_count));
        request_badges = scr_load_my_badges();
    }
    else
    {
        my_badges_loaded = 1;
        request_badges = -1;
    }
}

if (request_id == request_all_badges)
{
    request_all_badges = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        
        for (var i = 0; i < ds_list_size(all_badges); i++)
        {
            var badge = ds_list_find_value(all_badges, i);
            
            if (ds_exists(badge, ds_type_map))
                ds_map_destroy(badge);
        }
        
        ds_list_clear(all_badges);
        var pos = 1;
        
        while (pos < string_length(result))
        {
            var found = string_pos("\"id\":", string_copy(result, pos, (string_length(result) - pos) + 1));
            
            if (found == 0)
            {
                break;
            }
            else
            {
                pos = pos + found;
                var section = string_copy(result, pos - 1, 150);
                var badge = ds_map_create();
                ds_map_add(badge, "id", scr_json_get_value(section, "id"));
                ds_map_add(badge, "name", scr_json_get_value(section, "name"));
                ds_map_add(badge, "icon_name", scr_json_get_value(section, "icon_name"));
                ds_map_add(badge, "color", scr_json_get_value(section, "color"));
                ds_list_add(all_badges, badge);
                pos += 20;
                continue;
            }
        }
        
        all_badges_loaded = 1;
    }
}

if (request_id == request_award_badge || request_id == request_remove_badge)
{
    var is_award = request_id == request_award_badge;
    
    if (is_award)
        request_award_badge = -1;
    else
        request_remove_badge = -1;
    
    if (status == 0 || (!is_award && status == -1))
    {
        for (var i = 0; i < ds_list_size(my_badges); i++)
        {
            var badge = ds_list_find_value(my_badges, i);
            
            if (ds_exists(badge, ds_type_map))
                ds_map_destroy(badge);
        }
        
        ds_list_clear(my_badges);
        my_badges_loaded = 0;
        request_badges = scr_load_my_badges();
    }
}

if (request_id == request_upload_image)
{
    request_upload_image = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        
        if (string_pos("\"success\":true", result) > 0)
        {
            var name_pos = string_pos("\"fileName\":\"", result);
            
            if (name_pos > 0)
            {
                var name_start = name_pos + 12;
                var temp_str = string_copy(result, name_start, 200);
                var name_end = string_pos("\"", temp_str);
                var file_name = string_copy(temp_str, 1, name_end - 1);
                var new_url = global.r2_profile_url + "/" + file_name;
                profile_image_url = new_url;
                global.user_profile_image = new_url;
                request_save_profile = scr_save_profile_to_supabase(profile_image_url, bio);
                
                // la foto ya se esta mostrando desde el cache local, solo se
                // baja si por algun motivo no habia quedado cargada
                if (profile_image_loaded == 0)
                {
                    var img_path = working_directory + "/cache_img/profile_" + global.user_id + ".png";
                    
                    image_retry_count = 0;
                    profile_image_request = http_get_file(profile_image_url, img_path + ".dl");
                    profile_image_loading = 1;
                }
                else
                    profile_image_loading = 0;
            }
            else
            {
                profile_image_loading = 0;
            }
        }
        else
        {
            profile_image_loading = 0;
        }
    }
    else
    {
        profile_image_loading = 0;
    }
}

if (request_id == profile_image_request)
{
    var failed_image = 0;
    // la bajada va a un archivo aparte y el cache bueno solo se pisa con
    // un archivo ya verificado, una bajada fallida nunca lo rompe
    var img_path = working_directory + "/cache_img/profile_" + global.user_id + ".png";
    var img_dl = img_path + ".dl";
    show_debug_message("FOTO PERFIL: bajada status=" + string(status) + " http=" + string(ds_map_find_value(async_load, "http_status")));
    
    if (status == 0)
    {
        if (file_exists(img_dl))
        {
            var file_size = 0;
            var f = file_bin_open(img_dl, 0);
            
            if (f != -1)
            {
                file_size = file_bin_size(f);
                file_bin_close(f);
            }
            
            if (file_size > 100)
            {
                var _spr = sprite_add(img_dl, 1, false, false, 0, 0);
                
                if (_spr != -1)
                {
                    if (profile_image_sprite != -1 && sprite_exists(profile_image_sprite))
                        sprite_delete(profile_image_sprite);
                    
                    profile_image_sprite = _spr;
                    if (file_exists(img_path))
                        file_delete(img_path);
                    file_rename(img_dl, img_path);
                    profile_image_loaded = 1;
                    profile_image_loading = 0;
                    profile_image_request = -1;
                    image_retry_count = 0;
                }
                else
                {
                    failed_image = 1;
                    file_delete(img_dl);
                }
            }
            else
            {
                failed_image = 1;
                file_delete(img_dl);
            }
        }
        else
        {
            failed_image = 1;
        }
    }
    else
    {
        failed_image = 1;
    }
    
    if (failed_image)
    {
        if (image_retry_count < image_max_retries)
        {
            image_retry_count += 1;
            show_debug_message("REINTENTANDO IMAGEN DE PERFIL: " + string(image_retry_count));
            
            if (file_exists(img_dl))
                file_delete(img_dl);
            
            profile_image_request = http_get_file(scr_foto_url_http(profile_image_url), img_dl);
            profile_image_loading = 1;
        }
        else
        {
            profile_image_request = -1;
            profile_image_loading = 0;
            if (file_exists(img_dl))
                file_delete(img_dl);
            show_debug_message("FALLÓ IMAGEN PERFIL TRAS REINTENTOS");
        }
    }
}

if (request_id == request_save_profile)
    request_save_profile = -1;

if (request_id == request_discord_check)
{
    request_discord_check = -1;
    
    if (status == 0)
    {
        var result = ds_map_find_value(async_load, "result");
        var temp_discord_id = scr_json_get_value(result, "discord_id");
        var temp_discord_username = scr_json_get_value(result, "discord_username");
        temp_discord_id = scr_clean_json_string(temp_discord_id);
        temp_discord_username = scr_clean_json_string(temp_discord_username);
        
        if (temp_discord_id != "" && temp_discord_id != "null" && !is_undefined(temp_discord_id))
        {
            discord_linked = 1;
            discord_id = temp_discord_id;
            discord_username = temp_discord_username;
        }
    }
}

if (request_id == request_discord_link)
{
    request_discord_link = -1;
    
    // solo se lee el codigo si el insert salio bien, sino devuelve un json con el error
    if (status == 0 && (http_status == 200 || http_status == 201))
    {
        var result = ds_map_find_value(async_load, "result");
        
        if (string_pos("\"code\":", result) > 0)
        {
            discord_link_code = scr_json_get_value(result, "code");
            discord_link_code = scr_clean_json_string(discord_link_code);
            show_discord_popup = 1;
        }
    }
    else
    {
        show_debug_message("LINK CODE FAIL http=" + string(http_status) + " result: " + string(ds_map_find_value(async_load, "result")));
        show_message_async("Error al generar código. Intentá de nuevo.");
    }
}
