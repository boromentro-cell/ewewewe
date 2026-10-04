if (state == 0)
{
    alpha += fade_speed;
    
    if (alpha >= 1)
    {
        alpha = 1;
        state = 1;
        timer = wait_time;
    }
}
else if (state == 1)
{
    if (texture_to_apply != "" && !texture_applied && !texture_applying)
    {
        scr_debug_log("=== APLICANDO TEXTURA (pantalla negra) ===");
        scr_debug_log("Path: " + texture_to_apply);
        texture_applying = true;
        
        if (directory_exists(texture_to_apply))
        {
            // se escanea el nivel para cargar solo lo que usa
            var _lvl = "";
            
            if (instance_exists(level_file_instance))
                _lvl = level_file_instance.play_level;
            
            if (_lvl != "" && file_exists(_lvl))
                scr_tex_nivel_scan(_lvl);
            
            scr_texture_system_init();
            scr_texture_load_all_optimized(texture_to_apply + "/");
            
            // la version de la textura decide el hud
            scr_tex_hud_aplicar(texture_to_apply);
            
            if (file_exists("textura_cargar.ini"))
                file_delete("textura_cargar.ini");
            
            ini_open("textura_cargar.ini");
            ini_write_string("textura", "textura", texture_name);
            ini_close();
            scr_debug_log("Textura aplicada exitosamente");
        }
        else
        {
            scr_debug_log("ERROR: Directorio de textura no existe: " + texture_to_apply);
        }
        
        texture_applied = true;
        texture_applying = false;
    }
    
    timer -= 1;
    
    if (timer <= 0)
    {
        if (texture_to_apply == "" || texture_applied)
        {
            state = 2;
            
            if (instance_exists(level_file_instance))
            {
                with (level_file_instance)
                    scr_level_file_start_level();
            }
        }
        else
        {
            timer = 30;
        }
    }
}
else if (state == 2)
{
    if (room != target_room)
        room_goto(target_room);
    else
        state = 3;
}
else if (state == 3)
{
    if (room == target_room)
    {
        alpha -= fade_speed;
        
        if (alpha <= 0)
            instance_destroy();
    }
}
