if enable = true
{
    with obj_level_file enable = false;
    is_loading = true;
}
if file_exists(play_level)
{
if scr_isWindows()
var level_root2 = working_directory + "/Mundos";
else
var level_root2 = getDire2("SM4J","Mundos");

zip_unzip(play_level, level_root2);
file_delete(play_level);
with obj_level_file enable = true;
is_loading = false;
show_message_extra("SE DESCARGO EL MUNDO " + play_level + " CORRECTAMENTE!");
}
else
    alarm[1] = 1;

