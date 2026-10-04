var _keep_data = (variable_global_exists("browser_return_valid") && global.browser_return_valid == true);

scr_debug_log("LOADER DESTROY: keep_data=" + string(_keep_data));

for (var f = 0; f < ds_list_size(featured_levels); f++)
{
    var feat = ds_list_find_value(featured_levels, f);
    
    if (ds_exists(feat, ds_type_map))
        ds_map_destroy(feat);
}

ds_list_destroy(featured_levels);

for (var f = 0; f < ds_list_size(featured_thumbs); f++)
{
    var spr = ds_list_find_value(featured_thumbs, f);
    
    if (spr != -1 && sprite_exists(spr))
        sprite_delete(spr);
}

if (ds_exists(difficulty_anim_queue, ds_type_list))
    ds_list_destroy(difficulty_anim_queue);

if (!_keep_data)
{
    ds_list_destroy(global.difficulty_labels);
    ds_list_destroy(global.difficulty_confidences);
    ds_list_destroy(global.difficulty_sessions);
    
    if (ds_exists(global.texture_used_levels, ds_type_list))
        ds_list_destroy(global.texture_used_levels);
    
    if (ds_exists(global.custom_objects_used_levels, ds_type_list))
        ds_list_destroy(global.custom_objects_used_levels);
}

ds_list_destroy(featured_thumbs);
ds_list_destroy(featured_thumb_requests);
ds_list_destroy(featured_thumb_queue);
ds_list_destroy(admin_featured_ids);
ds_list_destroy(cleanup_queue);
if (!_keep_data)
{
    if (ds_exists(global.request_times, ds_type_list))
        ds_list_destroy(global.request_times);
    
    // tags
    for (var t = 0; t < ds_list_size(global.tags_levels); t++)
    {
        var sublist = ds_list_find_value(global.tags_levels, t);
        
        if (ds_exists(sublist, ds_type_list))
            ds_list_destroy(sublist);
    }
    
    ds_list_destroy(global.tags_levels);
}

if (ds_exists(parse_objects, ds_type_list))
    ds_list_destroy(parse_objects);

if (ds_exists(bg_color_sequence, ds_type_list))
    ds_list_destroy(bg_color_sequence);

if (ds_exists(bg_color_sequence, ds_type_list))
    ds_list_destroy(bg_color_sequence);

if (audio_is_playing(snd_level_browser))
    audio_stop_sound(snd_level_browser);
