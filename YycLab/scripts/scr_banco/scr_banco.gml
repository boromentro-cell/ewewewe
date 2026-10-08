// =====================================================================
// BANCO DE TESTS YYC v2 — decompilador v33/v34 — BATERIA COMPLETA
// 75 funciones cubriendo TODOS los shapes residuales de empty ifs.
// Cada function compila a gml_Script_scr_tXX. Constantes unicas por
// funcion (0.4N/0.6N) para ubicarlas en el binario.
// NO simplificar los snippets: las repeticiones son intencionales.
// =====================================================================

// ============ GRUPO 1: && con instance_exists (basico) ============
function scr_t01() {
    var c = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (instance_exists(c) && c.type == 1) { hspeed = 0.51 }
}

function scr_t02() {
    if (instance_exists(collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)) && collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true).type == 1) { hspeed = 0.52 }
}

function scr_t03() {
    var c = collision_point(x, y, obj_a, false, true)
    if (c != noone && c.type == 2) { vspeed = 0.53 }
}

function scr_t04() {
    if (instance_exists(collision_line(x, y, x + 64, y + 64, obj_a, 0, 1))) { gravity = 0.54 }
}

function scr_t05() {
    var c = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (instance_exists(c)) { with (c) { image_speed = 0.55 } }
}

function scr_t23() {
    var c = collision_rectangle(x, y, x + 32, y + 32, obj_b, false, true)
    if (instance_exists(c) && c.type != 3) { hspeed = 0.56 }
}

function scr_t24() {
    var c = collision_rectangle(x, y, x + 32, y + 32, obj_c, false, true)
    if (instance_exists(c) && c.type == 1 && c.hspeed == 0) { vspeed = 0.57 }
}

// args por TEMP (cluster mario_Step_2)
function scr_t25() {
    var t1 = bbox_left
    var t2 = bbox_top
    var t3 = bbox_right
    var t4 = bbox_bottom
    var t5 = obj_a
    var t6 = true
    var t7 = false
    if (instance_exists(collision_rectangle(t1, t2, t3, t4, t5, t6, t7)) && collision_rectangle(t1, t2, t3, t4, t5, t6, t7).type == 1) { x = 0.58 }
}

// ============ GRUPO 2: ie(lava) && y-compare (cluster B, 125) ============
function scr_t26() {
    if (instance_exists(obj_lava) && y > obj_lava.y) { vspeed = 0.61 }
}

function scr_t27() {
    if (instance_exists(obj_lava) && (bbox_bottom - 8) > (obj_lava.y - 12)) { instance_create((x + (-12 * direct) - 8), (y - 8) + random(8), obj_f) }
}

function scr_t27b() {
    if (direct == 1) {
        if (instance_exists(obj_lava) && (bbox_bottom - 8) > (obj_lava.y - 12)) {
            instance_create((x + (-12 * direct) - 8), (y - 8) + random(8), obj_f)
        }
    }
}

// dentro del body de un || (el caso marioU del dispatch)
function scr_t29() {
    if (!place_meeting(x, y, obj_solid) && !place_meeting(x, y, obj_phys) || place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b)) {
        if (instance_exists(obj_lava) && y > obj_lava.y) { vspeed = 0.62 }
    }
}

function scr_t30() {
    if (instance_exists(obj_lava) && y > (obj_lava.y + 16) && global.bg_level == "forest" && global.modo_noche == 0) { hspeed = 0.63 }
}

// ============ GRUPO 3: ie(obj_mario) && ... (cluster C, 114) ============
function scr_t31() {
    if (instance_exists(obj_d) && ((!instance_exists(obj_e)) && ((global.powerup == -80) && (keyboard_check(vk_left) && (keyboard_check(vk_down) && ((global.yoshi == 0) && ((obj_d.state < 2) && ((obj_d.holding == 0) && ((obj_d.iamkicking == 0) && ((obj_d.disablecontrols == 0))))))))))) {
        return 1;
    } else {
        return 0;
    }
}

function scr_t32() {
    if (instance_exists(obj_d) && obj_d.x == x) { hspeed = 0.64 }
}

function scr_t33() {
    switch (global.apariencia) {
        case 0:
            if (instance_exists(obj_d) && obj_d.y < y + 32) { vspeed = 0.65 }
            break
        case 1:
            if (instance_exists(obj_d) && obj_d.y > y) { gravity = 0.66 }
            break
    }
}

function scr_t34() {
    if (instance_exists(obj_d)) { hspeed = 0.67 }
    else if (instance_exists(obj_e)) { hspeed = 0.68 }
    else { hspeed = 0.69 }
}

// ============ GRUPO 4: ie-otro (cluster D, 181) ============
function scr_t35() {
    var airmove = instance_nearest(x, y, obj_f)
    if (instance_exists(airmove)) { x = airmove.x + 0.70 }
}

function scr_t36() {
    var v = instance_nearest(x, y, obj_f)
    if (instance_exists(v) && v.something == 1) { y = 0.71 }
}

function scr_t37() {
    if (instance_exists(obj_f) && instance_exists(obj_d) || instance_exists(obj_e)) { gravity = 0.72 }
}

// ============ GRUPO 5: cadenas en SCRIPTS con default args (H, 262) ============
// replica scr_air_follow/scr_auto_tile: el staging de defaults interleavea
function scr_t38(a = 1, b = "x", c = 2.5) {
    if (global.bg_level == "underwater" || (global.modo_noche == 1 && global.bg_level == "sky") || (global.modo_noche == 1 && global.bg_level == "airship") || (instance_exists(obj_lava) && y > (obj_lava.y + 16) && global.bg_level == "forest" && global.modo_noche == 0)) {
        hspeed = (0.3 * a)
    } else {
        hspeed = (2 * a)
    }
    return b + string(c)
}

function scr_t39(air = 1, paracaidas = 0) {
    if (air == 1 && paracaidas == 0) {
        vspeed = 0.73
        if (global.bg_level != "underwater" && global.bg_level != "sky" && global.bg_level != "airship" && !(instance_exists(obj_lava) && (y + 8) > obj_lava.y)) {
            vspeed = (0.73 + 0.18)
        }
        if (instance_exists(obj_f)) { vspeed = 0.74 }
    }
    return air + paracaidas
}

// dos cadenas underwater seguidas con statements intermedios (air_follow exacto)
function scr_t40() {
    vspeed = 0.75
    if (air == 1 && paracaidas == 0) {
        if (global.bg_level == "underwater" || global.bg_level == "sky" || global.bg_level == "airship" || (instance_exists(obj_lava) && (y + 8) > obj_lava.y)) {
            vspeed = (0.75 + 0.1)
        } else {
            vspeed = (0.75 + 0.2)
        }
        sprite_index = 0
        if (global.bg_level == "underwater" || global.bg_level == "beach") {
            sprite_index = 1
        } else {
            sprite_index = 2
        }
    }
}

function scr_t41() {
    if (global.bg_level == "underwater" || (global.modo_noche == 1 && global.bg_level == "sky") || (global.modo_noche == 1 && global.bg_level == "airship")) { hspeed = 0.76 }
}

// cadena que usa arguments como coordenadas
function scr_t42(px, py) {
    if (!collision_rectangle(px, py, px + 16, py + 16, obj_a, true, false) && !collision_rectangle(px, py, px + 16, py + 16, obj_b, true, false)) { return 0.77 }
    return 0.78
}

// ============ GRUPO 6: marioU dispatch (|| con ie(collision) en el body) ============
function scr_t43() {
    if (!place_meeting(x, y + 1, obj_solid) && !place_meeting(x, y + 1, obj_phys) || place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b)) {
        var c = collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0)
        if (instance_exists(c) && c.type == 1) { hspeed = 0.81 }
        if (instance_exists(c) && c.type == 2) { vspeed = 0.82 }
    }
}

// marioU exacto: tres cadenas ie(collision)&&type consecutivas
function scr_t44() {
    if (instance_exists(collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0)) && collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0).type == 1) { sprite_index = 0.83 }
    if (instance_exists(collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0)) && collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0).type == 2) { sprite_index = 0.84 }
    if (instance_exists(collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0)) && collision_rectangle(bbox_left, bbox_bottom, bbox_right, bbox_bottom + 1, obj_c, 0, 0).type == 0) { sprite_index = 0.85 }
}

function scr_t45() {
    if (instance_exists(obj_d)) {
        switch (global.apariencia) {
            case 0:
                if (!place_meeting(x, y, obj_a) && !place_meeting(x, y, obj_b)) { hspeed = 0.86 }
                break
            case 1:
                var c = collision_rectangle(x, y, x + 16, y + 16, obj_c, false, true)
                if (instance_exists(c) && c.type == 1) { hspeed = 0.87 }
                break
        }
    }
}

// ============ GRUPO 7: soy-yo / col != id (G + muncher) ============
function scr_t06() {
    var col = collision_rectangle(x, y + 4, x + 32, y + 36, obj_phys, true, false)
    if (col && col != id) { hspeed = 0.88 }
    else {
        if (!collision_rectangle(x, y + 4, x + 32, y + 36, obj_b, true, false) && !collision_rectangle(x, y + 4, x + 32, y + 36, obj_c, true, false)) { vspeed = 0.89 }
    }
}

function scr_t07() {
    var col = collision_rectangle(x, y, x + 32, y + 32, obj_phys, true, false)
    if (col == id) { friction = 0.90 }
}

function scr_t08() {
    if (collision_rectangle(x, y + 4, x + 32, y + 36, obj_phys, true, false)) {
        if (collision_rectangle(x, y + 4, x + 32, y + 36, obj_phys, true, false) == id) { x += 0.91 }
    } else {
        y += 0.92
    }
}

function scr_t48() {
    var col = collision_rectangle(x, y, x + 32, y + 32, obj_phys, true, false)
    if (col && col != id) { x += col.hspeed; friction = col.friction }
}

function scr_t49() {
    var col = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (instance_exists(col)) {
        with (col) { hspeed = 0.93 }
    }
}

// idiom de movimiento: while con continue
function scr_t50() {
    while (collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_top, obj_solid, 1, 0)) {
        if (!place_meeting(x, y, obj_solid)) { y = (y + 1); continue }
    }
}

// ============ GRUPO 8: && negada con temps (F, mario_Step_2) ============
function scr_t51() {
    var t1 = bbox_left
    var t2 = bbox_top
    var t3 = bbox_right
    var t4 = bbox_top
    var t5 = obj_solid
    var t6 = true
    var t7 = false
    if (!collision_rectangle(t1, t2, t3, t4, t5, t6, t7) && !collision_rectangle(t1, t2, t3, t4, obj_phys, t6, t7)) { x = 0.94 }
}

function scr_t52() {
    if (!collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_solid, true, false) && collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_phys, true, false) && !place_meeting(x, y, obj_a)) { y = 0.95 }
}

// ============ GRUPO 9: or-chains residuales (E, 30) ============
function scr_t53() {
    if (place_meeting((x + 1), y, obj_solid) || place_meeting((x - 1), y, obj_phys) || place_meeting(x, (y + 1), obj_a)) { gravity = 0.96 }
}

function scr_t54() {
    if (global.bg_level != "underwater" && global.bg_level != "sky" || global.modo_noche != 1) { vspeed = 0.97 }
}

function scr_t55() {
    if (position_meeting(x, y, obj_a) || position_meeting(x + 16, y, obj_b) || position_meeting(x, y + 16, obj_c)) { hspeed = 0.98 }
}

// ============ GRUPO 10: otros (J) ============
function scr_t56() {
    if (variable_instance_exists(id, "energy") && energy != undefined) { energy = 0.110 }
}

function scr_t57() {
    if (x >= (camera_get_view_x(0) - 128)) { view_camera[0] = 0; if (x > (camera_get_view_x(0) + 640)) { y = 0.111 } }
}

function scr_t58() {
    if (ds_map_find_value(async_load, "id") == texto) { async_load = 0; if (ds_map_find_value(async_load, "status") == 1) { x = 0.112 } }
}

function scr_t59() {
    if ((ord(string_char_at(argument[0], 1)) >= 97) && (ord(string_char_at(argument[0], 1)) >= 48)) { return 0.113 }
    return 0.114
}

function scr_t60() {
    if (argument_count > 1 && argument[1] == 0) { return 0.115 }
    return 0.116
}

function scr_t61() {
    var t1 = x
    var t2 = y
    if ((position_meeting(t1, t2, obj_a) || position_meeting(t1 + 8, t2, obj_b)) || position_meeting(t1, t2 + 8, obj_c)) { with (obj_d) { hspeed = 0.117 } }
}

function scr_t62() {
    if ((round(y / 16) - 13) < 1) { if ((round(y / 16) - 13) != -1) { y = 0.118 } }
}

function scr_t63() {
    if (x < camera_get_view_x(0)) { hspeed = -0.119 }
    else if (x > camera_get_view_x(0) + camera_get_view_width(0)) { hspeed = 0.120 }
    else { hspeed = 0 }
}

function scr_t64() {
    switch (global.bg_level) {
        case "underwater":
            if (instance_exists(obj_lava) && y > obj_lava.y) { hspeed = 0.121 }
            break
        case "sky":
            if (global.modo_noche == 1 && instance_exists(obj_d)) { vspeed = 0.122 }
            break
        default:
            gravity = 0.123
            break
    }
}

// ============ GRUPO 11: contexto estructural ============
function scr_t65() {
    with (obj_a) {
        if (instance_exists(obj_lava) && y > obj_lava.y) { hspeed = 0.124 }
    }
}

function scr_t66() {
    for (var i = 0; i < 10; i += 1) {
        if (instance_exists(obj_lava) && y > obj_lava.y) { x += 0.125 }
    }
}

function scr_t67() {
    repeat (5) {
        if (!place_meeting(x, y, obj_solid) && !place_meeting(x, y, obj_phys)) { y += 0.126 }
    }
}

function scr_t68() {
    if (place_meeting(x, y, obj_a)) {
        if (instance_exists(obj_lava) && y > obj_lava.y) { vspeed = 0.127 }
    } else {
        if (!place_meeting(x, y, obj_b)) { vspeed = 0.128 }
    }
}

function scr_t69() {
    if (hspeed == 0) { friction = 0.129 }
    else if (hspeed > 0.5 && place_meeting(x, y, obj_a)) { friction = 0.130 }
    else if (hspeed < -0.5 || place_meeting(x, y, obj_b)) { friction = 0.131 }
}

function scr_t70() {
    if (instance_exists(obj_lava) && y > obj_lava.y) { scr_t26() }
}

// ============ GRUPO 12: returns y varsets compartidos ============
function scr_t71() {
    if (instance_exists(obj_d) && instance_exists(obj_lava)) { return 1 } else { return 0 }
}

function scr_t72() {
    if (global.bg_level == "underwater") { return "si" } else { return "no" }
}

function scr_t73() {
    if (instance_exists(obj_lava) && y > obj_lava.y) { hspeed = 0.132 } else { hspeed = 0.133 }
}

function scr_t74() {
    if (place_meeting(x, y, obj_a)) { hspeed = 0.134; vspeed = 0.135 } else { gravity = 0.136; friction = 0.137 }
}

function scr_t75() {
    if (instance_exists(obj_d)) {
        if (obj_d.x == x) { return 0.138 }
        else { return 0.139 }
    }
    return 0.140
}

// ============ GRUPO 13: regresion de todo lo ya arreglado ============
function scr_t09() {
    if (place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b) || place_meeting(x, y, obj_c)) { hspeed = 0.141 }
}

function scr_t10() {
    if (!place_meeting(x, y + 1, obj_solid) && !place_meeting(x, y + 1, obj_phys) || place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b)) { hspeed = 0.142 }
}

function scr_t11() {
    if (!collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_solid, true, false) && !collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_phys, true, false) && !collision_rectangle(bbox_left, bbox_top, bbox_right, bbox_bottom, obj_c, true, false)) { walljump = 0.143 }
}

function scr_t12() {
    if (global.bg_level == "underwater" || (global.modo_noche == 1 && global.bg_level == "sky") || (global.modo_noche == 1 && global.bg_level == "airship") || (instance_exists(obj_lava) && y > (obj_lava.y + 16) && global.bg_level == "forest" && global.modo_noche == 0)) { hspeed = (0.3 * direct) } else { hspeed = (2 * direct) }
}

function scr_t13() {
    if (place_meeting(x, y, obj_a) || place_meeting(x, y, obj_b)) { image_index = 1 } else { image_index = 2 }
}

function scr_t14() {
    if (global.bg_level == "sky" || global.bg_level == "airship" || global.bg_level == "beach") { vspeed = 0.144 }
}

function scr_t15() {
    if (swimming || (touch_ground && hurted == 0) || global.modo_noche == 1) { gravity = 0.145 }
}

function scr_t16() {
    angle -= (3.5 * sign(hspeed))
}

function scr_t17() {
    if (keyboard_check(vk_left)) { hspeed = -1 }
}

function scr_t18() {
    var q = collision_rectangle(x, y, x + 32, y + 32, obj_a, false, true)
    if (q.hspeed > 0) { x = x + q.hspeed }
}

function scr_t19() {
    if (variable_instance_exists(id, "energy") && energy != undefined) { energy = 0.146 }
}

function scr_t20() {
    if (instance_exists(obj_lava) && y > obj_lava.y) { vspeed = 0.147 }
}

function scr_t21() {
    if (hspeed == 0) { friction = 0.148 }
    else if (hspeed > 0) { friction = 0.149 }
    else { friction = 0.150 }
}

function scr_t22() {
    switch (global.apariencia) {
        case 0:
            if (touch_ground == 0 && hurted == 0) {
                if (!place_meeting(x, y + 1, obj_solid) || place_meeting(x, y, obj_a)) { hspeed = 0.151 }
            }
            break
        case 1:
            hspeed = 0.152
            break
    }
}
