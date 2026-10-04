// ==== LAB 3 ====

// 1) funciones script con argumentos
resultado_fn = lab3_sumar(7, 11);
doble_fn = lab3_duplicar(6);

// 2) struct literal + acceso con punto
inv = { oro: 10, nombre: "pepe" };
oro_total = inv.oro;
nombre_inv = inv.nombre;

// 3) struct con accessor $
clave_texto = "oro";
valor_dollar = inv[$ clave_texto];

// 4) ds_map y ds_list
mapa = ds_map_create();
ds_map_add(mapa, "vida", 100);
vida_mapa = ds_map_find_value(mapa, "vida");
lista_ds = ds_list_create();
ds_list_add(lista_ds, 5);
item_ds = ds_list_find_value(lista_ds, 0);
ds_map_destroy(mapa);
ds_list_destroy(lista_ds);

// 5) global
global.vida = 100;
vida_global = global.vida;

// 6) array 2D + array_length
matriz = array_create(3, 3);
matriz[1][2] = 42;
leer_2d = matriz[1][2];
largo_matriz = array_length(matriz);

// 7) do-until
cont_do = 0;
do {
    cont_do += 1;
} until (cont_do >= 3);

// 8) break y continue
suma_bc = 0;
for (j = 0; j < 10; j++) {
    if (j == 3) continue;
    if (j == 8) break;
    suma_bc += j;
}

// 9) switch numerico
codigo = 2;
switch (codigo) {
    case 1: texto_sw = "uno"; break;
    case 2: texto_sw = "dos"; break;
    default: texto_sw = "otro"; break;
}

// 10) ternario
etiqueta = (codigo == 2) ? "es dos" : "no es dos";

// 11) method variable
mover = function(dx) { return dx * 2; };
result_method = mover(4);

// 12) variables builtin de instancia
mi_x = x;
nueva_y = y + 10;