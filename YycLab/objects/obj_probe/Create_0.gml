// ==== LAB 2: while / repeat / switch / arrays / with ====

// 1) while
cont_while = 0;
while (cont_while < 3) {
    cont_while += 1;
}

// 2) repeat
cont_repeat = 0;
repeat (4) {
    cont_repeat += 1;
}

// 3) switch
fruta = "banana";
switch (fruta) {
    case "banana":  valor_switch = 1; break;
    case "manzana": valor_switch = 2; break;
    default:        valor_switch = 3; break;
}

// 4) arrays
lista = array_create(3);
lista[0] = 10;
lista[1] = 20;
lista[2] = 30;
suma_lista = lista[0] + lista[2];

// 5) with
with (obj_probe) {
    pepe_lab2 = 99;
}

show_debug_message(string(suma_lista) + string(cont_while));