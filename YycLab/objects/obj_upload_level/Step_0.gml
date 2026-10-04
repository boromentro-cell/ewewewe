#region Android File Picking Step Logic
if (os_type == os_android && android_picking)
{
    var mx = mouse_x;
    var my = mouse_y;
    var panel_w = 400;
    var panel_h = 300;
    var panel_x = (room_width - panel_w) / 2;
    var panel_y = (room_height - panel_h) / 2;
    
    if (mouse_check_button_pressed(mb_left))
    {
        // Cancel button
        if (mx > (room_width / 2 - 60) && mx < (room_width / 2 + 60) && my > (panel_y + panel_h - 40) && my < (panel_y + panel_h - 10))
        {
            android_picking = false;
            if (ds_exists(android_file_list, ds_type_list))
            {
                ds_list_destroy(android_file_list);
                android_file_list = -1;
            }
            exit;
        }
        
        // Scroll buttons
        var list_size = ds_list_size(android_file_list);
        if (list_size > 5)
        {
            if (mx > (panel_x + panel_w - 30) && mx < (panel_x + panel_w - 10))
            {
                if (my > (panel_y + 60) && my < (panel_y + 90))
                {
                    android_scroll = max(android_scroll - 1, 0);
                }
                if (my > (panel_y + 180) && my < (panel_y + 210))
                {
                    android_scroll = min(android_scroll + 1, list_size - 5);
                }
            }
        }
        
        // List item selection
        var display_count = min(5, list_size - android_scroll);
        for (var i = 0; i < display_count; i++)
        {
            var y_pos = panel_y + 60 + (i * 35);
            if (mx > (panel_x + 10) && mx < (panel_x + panel_w - 10) && my > y_pos && my < (y_pos + 30))
            {
                var idx = android_scroll + i;
                var selected_path = ds_list_find_value(android_file_list, idx);
                
                thumbnail_path = selected_path;
                has_thumbnail = 1;
                
                android_picking = false;
                if (ds_exists(android_file_list, ds_type_list))
                {
                    ds_list_destroy(android_file_list);
                    android_file_list = -1;
                }
                break;
            }
        }
    }
    exit;
}
#endregion

#region Teclado Virtual y Sincronizacion
// Detección de cambio de foco para campos de texto básicos (estado == 1)
if (estado == 1)
{
    if (campo_activo != campo_activo_prev)
    {
        if (campo_activo > 0)
        {
            if (os_type == os_android)
                keyboard_virtual_show(kbv_type_default, kbv_returnkey_done, kbv_autocapitalize_none, false);
            
            keyboard_string = (campo_activo == 1) ? level_name : level_description;
        }
        else
        {
            if (os_type == os_android)
                keyboard_virtual_hide();
        }
        campo_activo_prev = campo_activo;
    }

    if (campo_activo > 0)
    {
        if (campo_activo == 1)
        {
            level_name = keyboard_string;
            if (string_length(level_name) > 30)
            {
                level_name = string_copy(level_name, 1, 30);
                keyboard_string = level_name;
            }
        }
        else if (campo_activo == 2)
        {
            level_description = keyboard_string;
            if (string_length(level_description) > 200)
            {
                level_description = string_copy(level_description, 1, 200);
                keyboard_string = level_description;
            }
        }
    }
}

// Detección de cambio de foco para buscador de texturas (estado == 5)
if (estado == 5 && texture_enabled)
{
    if (texture_search_active != texture_search_active_prev)
    {
        if (texture_search_active)
        {
            if (os_type == os_android)
                keyboard_virtual_show(kbv_type_default, kbv_returnkey_done, kbv_autocapitalize_none, false);
            
            keyboard_string = texture_search_text;
        }
        else
        {
            if (os_type == os_android)
                keyboard_virtual_hide();
        }
        texture_search_active_prev = texture_search_active;
    }

    if (texture_search_active)
    {
        var prev_search = texture_search_text;
        texture_search_text = keyboard_string;
        if (string_length(texture_search_text) > 30)
        {
            texture_search_text = string_copy(texture_search_text, 1, 30);
            keyboard_string = texture_search_text;
        }
        if (texture_search_text != prev_search)
        {
            texture_search_timer = 15;
            texture_dropdown_open = true;
            texture_selected_name = "";
            texture_selected_author = "";
            texture_selected_display = "";
        }
    }
}
#endregion

if (estado == 1 && campo_activo > 0)
{
    if (keyboard_check_pressed(vk_tab))
    {
        campo_activo = (campo_activo == 1) ? 2 : 1;
    }
}

if (estado == 5 && texture_enabled && texture_search_active)
{
    if (keyboard_check_pressed(vk_escape))
    {
        texture_search_active = false;
        texture_dropdown_open = false;
    }
    
    if (texture_dropdown_open && ds_list_size(texture_search_results) > 0)
    {
        if (keyboard_check_pressed(vk_down))
            texture_hover_index = min(texture_hover_index + 1, ds_list_size(texture_search_results) - 1);
        
        if (keyboard_check_pressed(vk_up))
            texture_hover_index = max(texture_hover_index - 1, 0);
        
        if (keyboard_check_pressed(vk_enter) && texture_hover_index >= 0)
        {
            var _map = ds_list_find_value(texture_search_results, texture_hover_index);
            
            if (ds_exists(_map, ds_type_map))
            {
                texture_selected_name = ds_map_find_value(_map, "name");
                texture_selected_author = ds_map_find_value(_map, "author_name");
                texture_selected_display = texture_selected_name + " - " + texture_selected_author;
                texture_search_text = texture_selected_display;
                texture_dropdown_open = false;
                texture_search_active = false;
            }
        }
    }
}

if (texture_search_timer > 0)
{
    texture_search_timer--;
    
    if (texture_search_timer == 0 && texture_enabled && texture_search_text != "")
        texture_search_request = scr_search_textures_for_upload(texture_search_text);
}

if (!texture_enabled)
{
    texture_search_text = "";
    texture_selected_name = "";
    texture_selected_author = "";
    texture_selected_display = "";
    texture_dropdown_open = false;
    texture_search_active = false;
}

if (discord_check_timer > 0)
{
    discord_check_timer--;
    
    if (discord_check_timer == 0)
    {
        if (global.user_logged_in)
            discord_check_request = scr_check_discord_linked();
    }
}