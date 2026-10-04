if (ds_map_find_value(async_load, "type") == "image_picker_result")
{
    var status = ds_map_find_value(async_load, "status");
    if (status == "success")
    {
        var picked_path = ds_map_find_value(async_load, "path");
        if (file_exists(picked_path))
        {
            thumbnail_path = picked_path;
            has_thumbnail = 1;
        }
    }
    else if (status == "error")
    {
        var error_msg = ds_map_find_value(async_load, "error");
        show_message_async("Error al seleccionar la captura: " + string(error_msg));
    }
}
