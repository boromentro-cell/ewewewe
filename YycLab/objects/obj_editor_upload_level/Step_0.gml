#region Teclado Virtual y Sincronizacion
// Detección de cambio de foco para campos de texto básicos (estado == 0)
if (estado == 0)
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

// Detección de cambio de foco para buscador de texturas (estado == 1)
if (estado == 1 && texture_enabled)
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

if (estado == 0 && campo_activo > 0)
{
    if (keyboard_check_pressed(vk_tab))
    {
        campo_activo = (campo_activo == 1) ? 2 : 1;
    }
}

if (estado == 1 && texture_enabled && texture_search_active)
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

// NUEVO: Discord check retry timer
if (discord_check_timer > 0)
{
    discord_check_timer--;
    if (discord_check_timer == 0)
    {
        if (global.user_logged_in)
            discord_check_request = scr_check_discord_linked();
    }
}

if (keyboard_check_pressed(vk_escape) && estado < 2)
    instance_destroy();
