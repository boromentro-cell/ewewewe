if (ds_map_find_value(async_load, "type") == "image_picker_result")
{
    var status = ds_map_find_value(async_load, "status");
    if (status == "success")
    {
        var picked_path = ds_map_find_value(async_load, "path");
        if (file_exists(picked_path))
        {
            var file_size = 0;
            var f = file_bin_open(picked_path, 0);
            file_size = file_bin_size(f);
            file_bin_close(f);
            
            if (file_size > 512000)
            {
                show_message_async("IMAGEN MUY GRANDE (MAX 500KB)");
            }
            else
            {
                profile_image_loading = 1;
                request_upload_image = scr_upload_profile_image(picked_path);
            }
        }
    }
    else if (status == "error")
    {
        var error_msg = ds_map_find_value(async_load, "error");
        show_message_async("Error al seleccionar la imagen: " + string(error_msg));
    }
}
