if (instance_exists(obj_texture_search_button))
    instance_destroy(obj_texture_search_button);

if (instance_exists(obj_texture_search_panel))
    instance_destroy(obj_texture_search_panel);

for (var i = 0; i < ds_list_size(instancias_tarjetas); i++)
{
    var _inst = ds_list_find_value(instancias_tarjetas, i);
    
    if (instance_exists(_inst))
        instance_destroy(_inst);
}

ds_list_destroy(instancias_tarjetas);

if (variable_instance_exists(id, "cards_creation_queue"))
    ds_list_destroy(cards_creation_queue);

if (variable_instance_exists(id, "parsed_textures_list") && ds_exists(parsed_textures_list, ds_type_list))
{
    for (var i = 0; i < ds_list_size(parsed_textures_list); i++)
    {
        var _map = ds_list_find_value(parsed_textures_list, i);
        
        if (ds_exists(_map, ds_type_map))
            ds_map_destroy(_map);
    }
    
    ds_list_destroy(parsed_textures_list);
}

ds_list_destroy(global.texture_ids);
ds_list_destroy(global.texture_names);
ds_list_destroy(global.texture_authors);
ds_list_destroy(global.texture_author_ids);
ds_list_destroy(global.texture_descs);
ds_list_destroy(global.texture_files);
ds_list_destroy(global.texture_thumbs);
ds_list_destroy(global.texture_likes);
ds_list_destroy(global.texture_downloads);
ds_list_destroy(global.texture_dates);
ds_list_destroy(global.texture_github_urls);
ds_list_destroy(global.my_texture_likes);

if (ds_exists(global.texture_tags, ds_type_list))
{
    for (var i = 0; i < ds_list_size(global.texture_tags); i++)
    {
        var _sub = ds_list_find_value(global.texture_tags, i);
        
        if (ds_exists(_sub, ds_type_list))
            ds_list_destroy(_sub);
    }
    
    ds_list_destroy(global.texture_tags);
}

if (ds_exists(global.texture_search_tags, ds_type_list))
    ds_list_destroy(global.texture_search_tags);

instance_activate_object(obj_cursor_menu);
