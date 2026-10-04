if (!variable_instance_exists(id, "delete_pending"))
    exit;

if (!delete_pending)
    exit;

var _dialog_result = ds_map_find_value(async_load, "status");
scr_debug_log("TEXTURE DELETE DIALOG: result=" + string(_dialog_result));
delete_pending = 0;

if (_dialog_result == 1)
{
    var _t_id = ds_list_find_value(global.texture_ids, my_index);
    scr_debug_log("TEXTURE DELETE: Iniciando eliminación de textura " + string(_t_id));
    delete_request = scr_delete_texture(floor(real(_t_id)));
}
else
{
    scr_debug_log("TEXTURE DELETE: Cancelado por usuario");
}
