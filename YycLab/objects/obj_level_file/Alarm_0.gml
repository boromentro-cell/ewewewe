if enable = true
{
    with obj_level_file enable = false;
    is_loading = true;
}
if file_exists(play_level)
{
    ini_open(play_level)
    if not ini_section_exists("options")
    {
    show_message_extra("Error, parece que el nivel esta corrupto, no se puede leer.");
    with obj_level_file enable = true;
    is_loading = false;
    ini_close();
    exit;
    };

    level_load = working_directory + "/temp_load.lvl";
    if file_exists(level_load)
        file_delete(level_load);
    
    file_new = file_copy(play_level,level_load)

    global.clear = 0
    global.LE_play = 1
    global.mapa_LE_play = level_load;//level_root+ "/"+str2+" id " + archivo+".lvl"
    ///cargar nuevas medidas
    ini_open(level_load)
    room_set_width(rm_level_editor_Restart,ini_read_real("options","room_x",8000))
    room_set_height(rm_level_editor_Restart,ini_read_real("options","room_y",432))
    ini_close()
    global.file_nameA = filename_name(level_load)
    
    //recomilacion de datos
    global.current_play_level = nam_l;
    global.current_play_autor = aut_l;
    global.current_play_id = id_l;
    
    //iniciar nivel
    room_goto(rm_level_editor_Restart)
}
else
    alarm[0] = 1;

