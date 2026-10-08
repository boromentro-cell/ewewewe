// =====================================================================
// BANCO DE TESTS YYC — decompilador v33
// PEGAR TODO ESTO EN UN SOLO SCRIPT de GameMaker (GMS 2.3+), p.ej "scr_banco".
// Cada function compila a su propia funcion gml_Script_scr_tXX en el exe.
// NO simplificar ni "mejorar" los snippets: pegar tal cual (las repeticiones
// de llamadas son intencionales — replican el codigo real del juego).
// Requisitos: crear objetos dummy vacios: obj_a, obj_b, obj_c, obj_solid,
//   obj_phys, obj_lava. No hace falta room ni ejecutar nada.
// =====================================================================

// ---------- CLUSTER 1 (~295 en el juego): instance_exists(collision) ----------
// replica del caso real de obj_marioU_Other_19
function scr_t01() {
    var c = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (instance_exists(c) && c.type == 1) {
        hspeed = 0.51
    }
}

// la misma condicion SIN variable temporal (doble llamada)
function scr_t02() {
    if (instance_exists(collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)) && collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true).type == 1) {
        hspeed = 0.52
    }
}

function scr_t03() {
    var c = collision_point(x, y, obj_a, false, true)
    if (c != noone && c.type == 2) {
        vspeed = 0.53
    }
}

// solo el wrapper, sin member access
function scr_t04() {
    if (instance_exists(collision_line(x, y, x + 64, y + 64, obj_a, 0, 1))) {
        gravity = 0.54
    }
}

// wrapper + with
function scr_t05() {
    var c = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (instance_exists(c)) {
        with (c) {
            image_speed = 0.55
        }
    }
}

// ---------- CLUSTER 2 (~150): el patron "soy yo" (col != id) ----------
// replica del caso real de obj_muncher_Other_24
function scr_t06() {
    var col = collision_rectangle(x, y + 4, x + 32, y + 36, obj_phys, true, false)
    if (col && col != id) {
        hspeed = 0.61
    } else {
        if (!collision_rectangle(x, y + 4, x + 32, y + 36, obj_b, true, false) && !collision_rectangle(x, y + 4, x + 32, y + 36, obj_c, true, false)) {
            vspeed = 0.62
        }
    }
}

function scr_t07() {
    var col = collision_rectangle(x, y, x + 32, y + 32, obj_phys, true, false)
    if (col == id) {
        friction = 0.63
    }
}

// anidado como el muncher real
function scr_t08() {
    if (collision_rectangle(x, y + 4, x + 32, y + 36, obj_phys, true, false)) {
        if (collision_rectangle(x, y + 4, x + 32, y + 36, obj_phys, true, false) == id) {
            x += 0.64
        }
    } else {
        y += 0.65
    }
}

// ---------- BATERIA DE REGRESION (validar lo arreglado contra build conocido) ----------
function scr_t09() {
    if (place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b) || place_meeting(x, y, obj_c)) {
        hspeed = 0.71
    }
}

// grupo negado primero — el caso §49 (cooligan)
function scr_t10() {
    if (!place_meeting(x, y + 1, obj_solid) && !place_meeting(x, y + 1, obj_phys) || place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b)) {
        hspeed = 0.72
    }
}

// cadena && negada con colisiones de 7 args (staging largo) — el caso §43
function scr_t11() {
    if (!collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_solid, true, false) && !collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_phys, true, false) && !collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_c, true, false)) {
        walljump = 0.73
    }
}

// el idiom underwater COMPLETO con else — el caso §51/§53 (cooligan/grrrol)
function scr_t12() {
    if (global.bg_level == "underwater" || (global.modo_noche == 1 && global.bg_level == "sky") || (global.modo_noche == 1 && global.bg_level == "airship") || (instance_exists(obj_lava) && y > (obj_lava.y + 16) && global.bg_level == "forest" && global.modo_noche == 0)) {
        hspeed = (0.3 * direct)
    } else {
        hspeed = (2 * direct)
    }
}

function scr_t13() {
    if (place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b)) {
        image_index = 1
    } else {
        image_index = 2
    }
}

// comparaciones de string en cadena (el shape sete esi — §50)
function scr_t14() {
    if (global.bg_level == "sky" || global.bg_level == "airship" || global.bg_level == "beach") {
        vspeed = 0.74
    }
}

function scr_t15() {
    if (swimming || (touch_ground && hurted == 0) || global.modo_noche == 1) {
        gravity = 0.75
    }
}

// ---------- CASOS DE LEAKS (lineas colgantes en v33) ----------
// el leak de grrrol: (angle - ((? > 0) * 3.5))
function scr_t16() {
    angle -= (3.5 * sign(hspeed))
}

// el varset de cola con -1 (el caso `hspeed = self` de superball)
function scr_t17() {
    if (keyboard_check(vk_left)) {
        hspeed = -1
    }
}

// member access sobre resultado de colision
function scr_t18() {
    var q = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (q.hspeed > 0) {
        x = x + q.hspeed
    }
}

// ---------- CLUSTER RESIDUAL "otro" ----------
// el caso empeorado de galoomba_Alarm_10
function scr_t19() {
    if (variable_instance_exists(id, "energy") && energy != undefined) {
        energy = 0.91
    }
}

// el caso que queda en boomboom
function scr_t20() {
    if (instance_exists(obj_lava) && y > obj_lava.y) {
        vspeed = 0.92
    }
}

// else-if clasico
function scr_t21() {
    if (hspeed == 0) {
        friction = 0.93
    } else if (hspeed > 0) {
        friction = 0.94
    } else {
        friction = 0.95
    }
}

// cadenas DENTRO de un case de switch (el entorno de cooligan case 0)
function scr_t22() {
    switch (global.apariencia) {
        case 0:
            if (touch_ground == 0 && hurted == 0) {
                if (!place_meeting(x, y + 1, obj_solid) || place_meeting(x, y, obj_a)) {
                    hspeed = 0.96
                }
            }
            break
        case 1:
            hspeed = 0.97
            break
    }
}
