ds_list_destroy(tags_disponibles);
ds_list_destroy(tags_seleccionados);
ds_list_destroy(pack_files);

if (preview_sprite != -1 && sprite_exists(preview_sprite))
    sprite_delete(preview_sprite);

if (buffer_exists(pack_buffer))
    buffer_delete(pack_buffer);

ds_list_destroy(tags_customs);
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