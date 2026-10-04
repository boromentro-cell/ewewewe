pepe = 3;
juana = "hola mundo";
resultado = (pepe + 5) * 2;
if (resultado > 8) {
    pepe = 10;
} else {
    pepe = 20;
}
for (i = 0; i < 5; i++) {
    pepe += i;
}
show_debug_message(string(pepe));