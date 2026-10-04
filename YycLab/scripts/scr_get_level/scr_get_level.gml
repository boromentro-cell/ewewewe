function scr_get_level() {
	var level = argument[0];
	var text = "noone";
	if string_pos("<i class=" + chr(34) + "tiny fa fa-star" + chr(34) + " aria-hidden=" + chr(34) + "true" + chr(34) + "></i> ",level)
	{
	level = string_replace_all(level,"<i class=" + chr(34) + "tiny fa fa-star" + chr(34) + " aria-hidden=" + chr(34) + "true" + chr(34) + "></i> ","")
	}
	repeat(argument[1])
	{
	text = string_copy(level,string_pos("file.php?id=",level),string_length(level) - string_pos("file.php?id=",level));
	text = string_copy(text,0,string_pos("<i class=" + chr(34) + "tiny fa fa-thumbs-up",text)+30);
	level = string_copy(level,string_pos("<i class=" + chr(34) + "tiny fa fa-thumbs-up",level)+30,string_length(level));
	};

	id_level = string_copy(text,13,string_pos(chr(34),text)-13);
	name_level = string_copy(text,string_pos("max-width:100%"+chr(34)+">",text)+16,string_pos("p>",text)-string_pos("max-width:100%"+chr(34)+">",text)-18);

	//show_message(text);

	views_level = string_copy(text,string_pos("></i>",text)+5,string_pos(" <i class=",text) - string_pos("></i>",text)-5)

	text = string_copy(text,string_pos("<p>",text),string_length(text)-string_pos("<p>",text))
	autor_level = string_copy(text,6,string_pos("</p>",text)-6);
	if string_pos("email",autor_level)
	    autor_level = "MISSING"
    
	text = string_copy(text,3,string_length(text)-3)
	text = string_copy(text,string_pos("<p>",text),string_length(text)-string_pos("<p>",text))

	date_level = string_copy(text,4,string_pos("</p>",text)-4);
	ds_list_add(global.id_levels,id_level);
	ds_list_add(global.autor_levels,autor_level);
	ds_list_add(global.name_levels,name_level);
	//Corrige el formato de la fecha
	            var new_dat = string_upper(date_level)
	            if string_pos(string_upper("January"),new_dat) new_dat = string_replace_all(new_dat,string_upper("January"),"01/");
	            if string_pos(string_upper("February"),new_dat) new_dat = string_replace_all(new_dat,string_upper("February"),"02/");
	            if string_pos(string_upper("March"),new_dat) new_dat = string_replace_all(new_dat,string_upper("March"),"03/");
	            if string_pos(string_upper("April"),new_dat) new_dat = string_replace_all(new_dat,string_upper("April"),"04/");
	            if string_pos(string_upper("May"),new_dat) new_dat = string_replace_all(new_dat,string_upper("May"),"05/");
	            if string_pos(string_upper("June"),new_dat) new_dat = string_replace_all(new_dat,string_upper("June"),"06/");
	            if string_pos(string_upper("July"),new_dat) new_dat = string_replace_all(new_dat,string_upper("July"),"07/");
	            if string_pos(string_upper("August"),new_dat) new_dat = string_replace_all(new_dat,string_upper("August"),"08/");
	            if string_pos(string_upper("September"),new_dat) new_dat = string_replace_all(new_dat,string_upper("September"),"09/");
	            if string_pos(string_upper("October"),new_dat) new_dat = string_replace_all(new_dat,string_upper("October"),"10/");
	            if string_pos(string_upper("November"),new_dat) new_dat = string_replace_all(new_dat,string_upper("November"),"11/");
	            if string_pos(string_upper("December"),new_dat) new_dat = string_replace_all(new_dat,string_upper("December"),"12/");
	            //Elimnar espacio y coma
	            new_dat = string_replace_all(new_dat," ","");
	            new_dat = string_replace_all(new_dat,",","/");
	ds_list_add(global.date_levels,new_dat);
	ds_list_add(global.views_levels,views_level);


	//show_message("ID: " + id_level + "#Name: " + name_level + "#Autor: " + autor_level + "#Date: " + date_level + "#Views: " + views_level);



}
