// la miniatura se borra aca, pero si el sprite salio del preload es el mismo que puede estar
// usando otra tarjeta, ahi el segundo delete se queda sin nada que borrar
if (imagen_nivel != -1 && sprite_exists(imagen_nivel))
{
    sprite_delete(imagen_nivel);
    imagen_nivel = -1;
}

if (instance_exists(profile_obj))
    instance_destroy(profile_obj);
