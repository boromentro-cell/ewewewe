if (profile_image_sprite != -1 && sprite_exists(profile_image_sprite))
    sprite_delete(profile_image_sprite);

for (var i = 0; i < ds_list_size(my_levels); i++)
{
    var lvl = ds_list_find_value(my_levels, i);
    
    if (ds_exists(lvl, ds_type_map))
        ds_map_destroy(lvl);
}

ds_list_destroy(my_levels);

for (var i = 0; i < ds_list_size(my_badges); i++)
{
    var badge = ds_list_find_value(my_badges, i);
    
    if (ds_exists(badge, ds_type_map))
        ds_map_destroy(badge);
}

ds_list_destroy(my_badges);

for (var i = 0; i < ds_list_size(all_badges); i++)
{
    var badge = ds_list_find_value(all_badges, i);
    
    if (ds_exists(badge, ds_type_map))
        ds_map_destroy(badge);
}

ds_list_destroy(all_badges);
instance_activate_object(obj_aventura);
instance_activate_object(obj_carlosXDjav);
instance_activate_object(obj_otrosmodos);
instance_activate_object(obj_opciones);
instance_activate_object(obj_Hellomario_version);
instance_activate_object(obj_bganimator);
instance_activate_object(obj_cursor_menu);
instance_activate_object(obj_cursor_menu_manager);
instance_activate_object(obj_text_in_screen_Custom);
instance_activate_object(obj_text_Special);
instance_activate_object(obj_menu_eventos);
