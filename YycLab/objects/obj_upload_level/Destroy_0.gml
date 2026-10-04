if (ds_exists(niveles_locales, ds_type_list))
    ds_list_destroy(niveles_locales);

if (ds_exists(tags_disponibles, ds_type_list))
    ds_list_destroy(tags_disponibles);

if (ds_exists(tags_seleccionados, ds_type_list))
    ds_list_destroy(tags_seleccionados);

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
texture_enabled = false;
texture_search_text = "";
texture_selected_name = "";
texture_selected_author = "";
texture_selected_display = "";
texture_search_results = ds_list_create();
texture_search_request = -1;
texture_search_active = false;
texture_dropdown_open = false;
texture_search_timer = 0;
texture_hover_index = -1;
