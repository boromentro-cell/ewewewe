if enable = true
{
    with obj_level_file enable = false;
    is_loading = true;
}
if file_exists(play_level)
{
with obj_level_file enable = true;
is_loading = false;
show_message_extra("SE DESCARGO LA TEXTURA " + play_level + " CORRECTAMENTE!");
}
else
    alarm[2] = 1;

