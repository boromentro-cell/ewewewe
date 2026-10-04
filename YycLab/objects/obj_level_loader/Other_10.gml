if (variable_global_exists("mantenimiento_activo") && global.mantenimiento_activo)
{
    scr_maintenance_aplicar_vista();
    exit;
}

ds_list_clear(global.id_levels);
ds_list_clear(global.cold_storage_ids);
ds_list_clear(global.autor_levels);
ds_list_clear(global.author_ids);
ds_list_clear(global.name_levels);
ds_list_clear(global.date_levels);
ds_list_clear(global.views_levels);
ds_list_clear(global.likes_levels);
ds_list_clear(global.file_urls);
ds_list_clear(global.thumbnail_urls);
ds_list_clear(global.descriptions);
ds_list_clear(global.is_liked_list);
ds_list_clear(global.attempts_levels);
ds_list_clear(global.victories_levels);
ds_list_clear(global.unique_players_levels);
ds_list_clear(global.total_plays_levels);
ds_list_clear(global.thumb_queue);
ds_list_clear(global.first_clear_user_ids);
ds_list_clear(global.first_clear_usernames);
ds_list_clear(global.texture_used_levels);
if (variable_global_exists("custom_objects_used_levels") && ds_exists(global.custom_objects_used_levels, ds_type_list))
    ds_list_clear(global.custom_objects_used_levels);

ds_list_clear(global.difficulty_labels);
ds_list_clear(global.difficulty_confidences);
ds_list_clear(global.difficulty_sessions);
global.difficulties_loaded = false;

for (var t = 0; t < ds_list_size(global.tags_levels); t++)
{
    var sublist = ds_list_find_value(global.tags_levels, t);
    
    if (ds_exists(sublist, ds_type_list))
        ds_list_destroy(sublist);
}

ds_list_clear(global.tags_levels);
ds_list_clear(card_appear_queue);
global.thumb_downloading = false;
global.thumb_current_instance = -1;
global.thumb_current_request = -1;

for (var k = 0; k < ds_list_size(instancias_tarjetas); k++)
{
    var inst_old = ds_list_find_value(instancias_tarjetas, k);
    
    if (instance_exists(inst_old))
        instance_destroy(inst_old);
}

ds_list_clear(instancias_tarjetas);
scroll_y = 0;
global.page = 0;
global.end_of_results = false;
loading = true;
initial_load_complete = false;
request_cooldown = 0;
spam_message_active = false;
total_levels_loaded = 0;
total_cards_created = 0;
card_appear_timer = 0;

if (view_mode == 4)
{
    scr_debug_log("INICIANDO BÚSQUEDA AVANZADA");
    request_search = scr_supabase_search_levels(global.page, levels_per_page, global.name_s, global.autor_s, global.search_cr_min, global.search_cr_max, global.search_tags);
}
else if (view_mode == 5)
{
    get = scr_supabase_get_reported_levels(global.page, levels_per_page);
}
else if (view_mode == 3)
{
    request_hardest = scr_get_hardest_levels(levels_per_page, 0);
}
else if (view_mode == 1)
{
    admin_featured_loading = true;
    admin_featured_retry_count = 0;
    admin_featured_failed = false;
    request_admin_featured = scr_get_admin_featured_levels();
}
else
{
    get = scr_supabase_get_levels(global.page, levels_per_page, global.sort, global.name_s, global.autor_s);
}
