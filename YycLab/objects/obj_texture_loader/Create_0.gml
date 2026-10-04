if (!variable_global_exists("worker_textures_url"))
    scr_supabase_textures_init();

ds_list_clear(global.texture_ids);
ds_list_clear(global.texture_names);
ds_list_clear(global.texture_authors);
ds_list_clear(global.texture_author_ids);
ds_list_clear(global.texture_descs);
ds_list_clear(global.texture_files);
ds_list_clear(global.texture_thumbs);
ds_list_clear(global.texture_likes);
ds_list_clear(global.texture_downloads);
ds_list_clear(global.texture_dates);
ds_list_clear(global.my_texture_likes);
obj_texture_search_button = obj_mushroom;

if (ds_exists(global.texture_tags, ds_type_list))
{
    for (var i = 0; i < ds_list_size(global.texture_tags); i++)
    {
        var _sub = ds_list_find_value(global.texture_tags, i);
        
        if (ds_exists(_sub, ds_type_list))
            ds_list_destroy(_sub);
    }
    
    ds_list_clear(global.texture_tags);
}

global.texture_search_name = "";
global.texture_search_author = "";
global.texture_search_tags = ds_list_create();
cards_creation_queue = ds_list_create();
cards_per_frame = 2;
load_phase = 0;
load_phase_text = "conectando...";
textures_loaded = 0;
textures_retry_count = 0;
textures_retry_timer = -1;
textures_max_retries = 5;
likes_loaded = 0;
likes_retry_count = 0;
likes_retry_timer = -1;
likes_max_retries = 5;
parsing_active = 0;
parsing_index = 0;
parsed_textures_list = -1;
scroll_y = 0;
scroll_max = 0;
touch_y_start = -1;
touch_y_prev = -1;
scroll_momentum = 0;
items_per_page = 10;
current_page = 0;
current_sort = "recent";
search_text = "";
has_more = 1;
list_start_y = 130;
card_spacing = 12;
instancias_tarjetas = ds_list_create();
request_textures = -1;
request_my_likes = -1;
request_featured_textures = -1;
featured_textures_loading = 0;
col_bg = 1968655;
col_accent = 14438580;
btn_w = 90;
btn_h = 32;
btn_y = 70;
btn_back_x = room_width - 120;
btn_back_y = 20;
btn_back_w = 100;
btn_back_h = 36;
loading_dots = 0;
loading_timer = 0;
global.likes_operation_pending = 0;
load_delay = 3;
load_started = 0;
view_mode = 0;

if (instance_exists(obj_cursor_menu))
    instance_deactivate_object(obj_cursor_menu);
