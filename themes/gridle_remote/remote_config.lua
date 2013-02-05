--
-- Setup for Gridle- Remote, just a derivate of Gridle- Customview
-- Without the need for a navigator
-- 
local grid_stepx = 2;
local grid_stepy = 2;

local stepleft, stepup, stepdown, stepright, show_config, setup_customview;

customview = {};

-- map resource-finder properties with their respective name in the editor dialog
local remaptbl = {};
remaptbl["bezel"]       = "bezels";
remaptbl["screenshot"]  = "screenshots";
remaptbl["marquee"]     = "marquees";
remaptbl["overlay"]     = "overlay";
remaptbl["bezel"]       = "bezels";
remaptbl["backdrop"]    = "backdrops";
remaptbl["movie"]       = "movies";
remaptbl["controlpanel"]= "controlpanels";
remaptbl["boxart"]      = "boxart";

-- list of the currently allowed modes (size, position, opacity, orientation)
customview.position_modes_default  = {"position", "size", "opacity", "orientation"};
customview.position_modes_3d       = {"position3d", "rotate3d"};
customview.axis = 0;
customview.orderind = 1;
customview.temporary = {};
customview.temporary_models = {};

helplbls = {};
helplbls["position"] = {
	"Position",
	"(LEFT/RIGHT/UP/DOWN) to move",
	"(SWITCH_VIEW) to switch mode",
	"(SELECT) to save",
	"(ESCAPE) to cancel"
};

helplbls["position3d"] = {
	"Position (3D), Axis: 0",
	"(LEFT/RIGHT) to increase/decrease angle",
	"(UP/DOWN) to switch active axis",
	"(SWITCH_VIEW) to switch mode",
	"(SELECT) to save",
	"(ESCAPE) to cancel"
};

helplbls["rotate3d"] = {
	"Rotate (3D), Axis: 0",
	"(SWITCH_VIEW) to switch mode",
	"(MENU_UP/DOWN) to switch active axis",
	"(SELECT) to save",
	"(ESCAPE) to cancel"
};

helplbls["size"] = {
	"Scale",
	"(RIGHT/DOWN) to increase size",
	"(LEFT/UP) to decrease size",
	"(SWITCH_VIEW) to switch mode",
	"(SELECT) to save",
	"(ESCAPE) to cancel"
};

helplbls["opacity"] = {
	"Blend",
	"(LEFT/RIGHT) increase / decrease opacity",
	"(UP/DOWN) increase / decrease Z-order",
	"(SWITCH_VIEW) to switch mode",
	"(SELECT) to save",
	"(ESCAPE) to cancel"
};

helplbls["orientation"] = {
	"Rotate",
	"(UP/DOWN) aligned step (45 deg.)",
	"(LEFT/RIGHT) increase / decrease angle",
	"(SWITCH_VIEW) to switch mode",
	"(SELECT) to save",
	"(ESCAPE) to cancel"
};

-- set "step size" for moving markers in configuration based on
-- the dimensions of the display
while (VRESW / grid_stepx > 100) do
	grid_stepx = grid_stepx + 2;
end

while (VRESH / grid_stepy > 100) do
	 grid_stepy = grid_stepy + 2;
end

-- inject a submenu into a main one
-- dstlbls : array of strings to insert into
-- dstptrs : hashtable keyed by label for which to insert the spawn function
-- label   : to use for dstlbls/dstptrs
-- lbls    : array of strings used in the submenu (typically from gen_num, gen_tbl)
-- ptrs    : hashtable keyed by label that acts as triggers (typically from gen_num, gen_tbl)
function add_submenu(dstlbls, dstptrs, label, key, lbls, ptrs)
	if (dstlbls == nil or dstptrs == nil or #lbls == 0) then return; end
	
	table.insert(dstlbls, label);
	
	dstptrs[label] = function()
		local fmts = {};
		local ind = tostring(settings[key]);
	
		if (ind) then
			fmts[ ind ] = settings.colourtable.notice_fontstr;
			if(get_key(key)) then
				fmts[ get_key(key) ] = settings.colourtable.alert_fontstr;
			end
		end
		
		menu_spawnmenu(lbls, ptrs, fmts);
	end
end

-- create and display a listview setup with the menu defined by the arguments.
-- list    : array of strings that make up the menu
-- listptr : hashtable keyed by list labels
-- fmtlist : hashtable keyed by list labels, on match, will be prepended when rendering (used for icons, highlights etc.)
function menu_spawnmenu(list, listptr, fmtlist)
	if (#list < 1) then
		return nil;
	end

	local parent = current_menu;
	local props = image_surface_resolve_properties(current_menu.cursorvid);
	local windsize = VRESH;

	local yofs = 0;
	if (props.y + windsize > VRESH) then
		yofs = VRESH - windsize;
	end

	current_menu = listview_create(list, windsize, VRESW / 3, fmtlist);
	current_menu.parent = parent;
	current_menu.ptrs = listptr;
	current_menu.updatecb = parent.updatecb;
	current_menu:show();
	move_image( current_menu.anchor, props.x + props.width + 6, props.y);
	
	local xofs = 0;
	local yofs = 0;
	
-- figure out where the window is going to be.
	local aprops_l = image_surface_properties(current_menu.anchor, settings.fadedelay);
	local wprops_l = image_surface_properties(current_menu.window, settings.fadedelay);
	local dx = aprops_l.x;
	local dy = aprops_l.y;
	
	local winw = wprops_l.width;
	local winh = wprops_l.height;
	
	if (dx + winw > VRESW) then
		dx = dx + (VRESW - (dx + winw));
	end
	
	if (dy + winh > VRESH) then
		dy = dy + (VRESH - (dy + winh));
	end

	move_image( current_menu.anchor, math.floor(dx), math.floor(dy), settings.fadedelay );
	return current_menu;
end

function build_globmenu(globstr, cbfun, globmask)
	local lists = glob_resource(globstr, globmask);
	local resptr = {};
	
	for i = 1, #lists do
		resptr[ lists[i] ] = cbfun;
	end
	
	return lists, resptr;
end

-- name     : settings[name] to store under
-- tbl      : array of string with labels of possible values
-- isstring : treat value as string or convert to number before sending to store_key
function gen_tbl_menu(name, tbl, triggerfun, isstring)
	local reslbl = {};
	local resptr = {};

	local basename = function(label, save)
		settings.iodispatch["MENU_ESCAPE"](nil, nil, true);
		settings[name] = isstring and label or tonumber(label);

		if (save) then
			store_key(name, isstring and label or tonumber(label));
		else
		end

		if (triggerfun) then triggerfun(label); end
	end

	for key,val in ipairs(tbl) do
		table.insert(reslbl, val);
		resptr[val] = basename;
	end

	return reslbl, resptr;
end

-- traversed to root node, updating visibility for each menu on the way
function cascade_visibility(menu, val)
	if (menu.parent) then
		cascade_visibility(menu.parent, val);
	end

	if (val > 0.9) then
		if (infowin) then
			infowin:destroy();
			infowin = nil;
		end
	end
	
	blend_image(menu.anchor, val);
	menu:push_to_front();
end

-- change the label shown 
local function update_infowin()
	if (infowin) then
		infowin:destroy();
	end

-- used in the setup/edit/mode. Position a quadrant away from the current item, and show the appropriate help text 
	infowin = listview_create( helplbls[customview.position_modes[customview.position_marker]], VRESW / 2, VRESH / 2 );
	local xpos = (customview.ci.x < VRESW / 2) and (VRESW / 2) or 0;
	local ypos = (customview.ci.y < VRESH / 2) and (VRESH / 2) or 0;
	infowin:show();
	move_image(infowin.anchor, math.floor(xpos), math.floor(ypos));
end

-- used in the setup/edit/mode.
local function position_toggle()
-- don't allow any other mode to be used except position until we have an upper left boundary
	customview.position_marker = (customview.position_marker + 1 > #customview.position_modes) and 1 or (customview.position_marker + 1);
	update_infowin();
end

-- used in the setup/edit mode, whenever user-input changes the state of the current item
local function update_object(imgvid)
	resize_image(imgvid, customview.ci.width, customview.ci.height);
	move_image(imgvid, customview.ci.x, customview.ci.y);
	blend_image(imgvid, customview.ci.opa);
	rotate_image(imgvid, customview.ci.ang);
	order_image(imgvid, customview.ci.zv);

	if (customview.ci.tiled) then
		local props = image_surface_initial_properties(imgvid);
		image_scale_txcos(imgvid, customview.ci.width / props.width, customview.ci.height / props.height);
	end
	
end

local function update_object3d(model)
	move3d_model(model, customview.ci.pos[1], customview.ci.pos[2], customview.ci.pos[3]);
	rotate3d_model(model, customview.ci.ang[1], customview.ci.ang[2], customview.ci.ang[3], 0, ROTATE_ABSOLUTE);
end

-- used whenever a shader is toggled for the 'background' label, applied in both edit and view mode.
local function update_bgshdr()
	local dst = nil;
	
	if (customview.in_config) then
		for ind, val in ipairs(customview.itemlist) do
			if (val.kind == "background") then
				dst = val.vid;
				val.shader = customview.bgshader_label;
				break
			end
		end
	else
		dst = customview.background;
	end

	if (dst) then
		local props = image_surface_properties(dst);
		shader_uniform(customview.bgshader, "display", "ff", PERSIST, props.width, props.height);
		image_shader(dst, customview.bgshader);
	end
end

-- used in edit / scale 
local function cursor_step(vid, x, y)
	customview.ci.width  = customview.ci.width + x;
	customview.ci.height = customview.ci.height + y;

	if (customview.ci.width <= 0)  then customview.ci.width  = 1; end
	if (customview.ci.height <= 0) then customview.ci.height = 1; end
	
	update_object(vid);
end

-- used in edit / positioning 
local function cursor_slide(vid, x, y)
	customview.ci.x = customview.ci.x + x;
	customview.ci.y = customview.ci.y + y;
	
	update_object(vid);
end

-- used in edit / rotate
local function orientation_rotate(vid, ang, align)
	customview.ci.ang = customview.ci.ang + ang;

	if (align) then
		local rest = customview.ci.ang % 45;
		customview.ci.ang = (rest > 22.5) and (customview.ci.ang - rest) or (customview.ci.ang + rest);
	end
	
	update_object(vid);
end

-- used in edit / blend
local function order_increment(vid, val)
	customview.ci.zv = customview.ci.zv + val;
	if (customview.ci.zv < 1) then customview.ci.zv = 1; end
	if (customview.ci.zv >= customview.orderind) then customview.ci.zv = customview.orderind - 1; end
	
	update_object(vid);
end

-- used in edit / blend
local function opacity_increment(vid, byval)
	customview.ci.opa = customview.ci.opa + byval;
	
	if (customview.ci.opa < 0.0) then customview.ci.opa = 0.0; end
	if (customview.ci.opa > 1.0) then customview.ci.opa = 1.0; end
	
	update_object(vid);
end

local function cursor_rotate3d(model, step)
	customview.ci.ang[ customview.axis+1 ] = customview.ci.ang[ customview.axis+1 ] + step;
	update_object3d(model);
end

local function cursor_position3d(model, step)
	customview.ci.pos[ customview.axis+1 ] = customview.ci.pos[ customview.axis+1 ] + step;
	update_object3d(model);
end

local function cursor_axis3d(model)
	customview.axis = (customview.axis + 1) % 3;
	helplbls["position3d"][1] = "Position (3D), Axis: " .. tostring(customview.axis);
	helplbls["rotate3d"][1] = "Rotate (3D), Axis: " .. tostring(customview.axis);
	update_infowin();
	update_object3d(model);
end

-- used in edit mode, depending on source object type etc. a list of acceptable labels
-- is set to position modes, this function connects these to the regular menu input labels
customview.position_item = function(vid, trigger, lbls)
-- as the step size is rather small, enable keyrepeat (won't help for game controllers though,
-- would need state tracking and hook to the clock 
	cascade_visibility(current_menu, 0.0);
	toggle_mouse_grab(MOUSE_GRABON);
	
	customview.position_modes  = lbls and lbls or customview.position_modes_default;
	customview.position_marker = 1;
	
	position_dispatch = settings.iodispatch;
	settings.iodispatch = {};

	settings.iodispatch["MOUSE_X"] = function(label, tbl)
		local lbl = customview.position_modes[customview.position_marker];
		if (tbl.samples[2] == nil or tbl.samples[2] == 0) then return; end
		if     (lbl == "size")        then cursor_step(vid, tbl.samples[2], 0);
		elseif (lbl == "orientation") then orientation_rotate(vid, 0.1 * tbl.samples[2], false);
		elseif (lbl == "position")    then cursor_slide(vid, tbl.samples[2], 0);
		elseif (lbl == "opacity")     then opacity_increment(vid, 0.01 * tbl.samples[2]);
		elseif (lbl == "rotate3d")    then cursor_rotate3d(vid, tbl.samples[2]);
		elseif (lbl == "position3d")  then cursor_position3d(vid, 0.01 * tbl.samples[2]); end
	end

	settings.iodispatch["MOUSE_Y"] = function(label, tbl)
		local lbl = customview.position_modes[customview.position_marker];
		if (tbl.samples[2] == nil or tbl.samples[2] == 0) then return; end
		if     (lbl == "size")        then cursor_step(vid, 0, tbl.samples[2]);
		elseif (lbl == "position")    then cursor_slide(vid, 0, tbl.samples[2]); end
	end
	
	settings.iodispatch["MENU_LEFT"]   = function()
		local lbl = customview.position_modes[customview.position_marker];
		if     (lbl == "size")        then cursor_step(vid, grid_stepx * -1, 0);
		elseif (lbl == "orientation") then orientation_rotate(vid,-2, false);
		elseif (lbl == "opacity")     then opacity_increment(vid, 0.1);
		elseif (lbl == "position")    then cursor_slide(vid, grid_stepx * -1, 0); 
		elseif (lbl == "rotate3d")    then cursor_rotate3d(vid, -20);
		elseif (lbl == "position3d")  then cursor_position3d(vid, -0.2);
		end
	end

	settings.iodispatch["MENU_RIGHT"]  = function() 
		local lbl = customview.position_modes[customview.position_marker];
		if     (lbl == "size")        then cursor_step(vid,grid_stepx, 0);
		elseif (lbl == "orientation") then orientation_rotate(vid, 2, false);
		elseif (lbl == "opacity")     then opacity_increment(vid, -0.1);
		elseif (lbl == "position")    then cursor_slide(vid, grid_stepx, 0);
		elseif (lbl == "rotate3d")    then cursor_rotate3d(vid, 20);
		elseif (lbl == "position3d")  then cursor_position3d(vid, 0.2);
		end
	end

	settings.iodispatch["MENU_UP"]     = function()
		local lbl = customview.position_modes[customview.position_marker];
		if     (lbl == "size")        then cursor_step(vid,0, grid_stepy * -1);
		elseif (lbl == "orientation") then orientation_rotate(vid, -45, true);
		elseif (lbl == "opacity")     then order_increment(vid,1); 
		elseif (lbl == "position")    then cursor_slide(vid, 0, grid_stepy * -1);
		elseif (lbl == "rotate3d")    then cursor_axis3d(vid);
		elseif (lbl == "position3d")  then cursor_axis3d(vid);
		end
	end

	settings.iodispatch["MENU_DOWN"]   = function() 
		local lbl = customview.position_modes[customview.position_marker];
		if     (lbl == "size")        then cursor_step(vid,0, grid_stepy);
		elseif (lbl == "orientation") then orientation_rotate(vid, 45, true);
		elseif (lbl == "opacity")     then order_increment(vid,-1); 
		elseif (lbl == "position")    then cursor_slide(vid, 0, grid_stepy); 
		elseif (lbl == "rotate3d")    then cursor_axis3d(vid);
		elseif (lbl == "position3d")  then cursor_axis3d(vid);
		end 
	end
	
	settings.iodispatch["MENU_ESCAPE"] = function() toggle_mouse_grab(MOUSE_GRABOFF); trigger(false, vid); end
	settings.iodispatch["SWITCH_VIEW"] = function() position_toggle();   end
	settings.iodispatch["MENU_SELECT"] = function() toggle_mouse_grab(MOUSE_GRABOFF); trigger(true, vid);  end

	update_infowin();
end

customview.new_item = function(vid, dstgroup, dstkey)
	local props = image_surface_properties(vid);

	customview.ci = {};
	customview.ci.width = (props.width  > VRESW * 0.5) and VRESW * 0.5 or props.width;
	customview.ci.height= (props.height > VRESH * 0.5) and VRESH * 0.5 or props.height;
	customview.ci.x     = 0.5 * (VRESW - customview.ci.width);
	customview.ci.y     = 0.5 * (VRESH - customview.ci.height);
	customview.ci.opa   = 1.0;
	customview.ci.ang   = 0;
	customview.ci.kind  = dstgroup;
	customview.ci.res   = dstkey;
	
	customview.ci.zv    = customview.orderind;
	customview.orderind = customview.orderind + 1;
end

customview.new_item3d = function(model, dstgroup, dstkey)
	customview.ci = {};

	customview.ci.ang = {0.0, 0.0, 0.0};
	customview.ci.pos = {-1.0, 0.0, -4.0};
-- not really used, just so infowin have something to work with 
	customview.ci.x   = 0;
	customview.ci.y   = 0;
	customview.ci.opa = 1.0;
	
	customview.ci.zv  = customview.orderind;
	customview.orderind = customview.orderind + 1;
	
	customview.ci.kind = dstgroup;
	customview.ci.res  = dstkey;
end

local function to_menu()
	customview.ci = nil;
	settings.iodispatch = position_dispatch;
	settings.iodispatch["MENU_ESCAPE"]("", false, false);
	cascade_visibility(current_menu, 1.0);
	kbd_repeat(settings.repeatrate);
end

local function save_item(state, vid)
	if (state) then
		customview.ci.vid = vid;
		table.insert(customview.itemlist, customview.ci);
	else
		delete_image(vid);
	end

	to_menu();
end

local function save_item_bg(state, vid)
	if (state == false) then
		delete_image(vid);
		to_menu();
		return;
	end
	
	local found = false;
	customview.ci.vid = vid;
	
	for ind, val in ipairs(customview.itemlist) do
		if val.kind == "background" then
			delete_image(customview.itemlist[ind].vid);
			customview.itemlist[ind] = customview.ci; 
			found = true;
			break
		end
	end

	if (found == false) then
		table.insert(customview.itemlist, customview.ci);
	end

	video_3dorder(ORDER_LAST);
	to_menu();
end

local function positionfun(label)
	vid = load_image("images/" .. label);
	
	if (vid ~= BADID) then
		customview.new_item(vid, "static_media", label);
		customview.ci.res = "images/" .. label;

		update_object(vid);
		customview.position_item(vid, save_item);
	end
end

local function effecttrig(label)
	local shdr = load_shader("shaders/fullscreen/default.vShader", "shaders/bgeffects/" .. label, "bgeffect", {});
	customview.bgshader = shdr;
	customview.bgshader_label = label;

	update_bgshdr();
	settings.iodispatch["MENU_ESCAPE"]();
end

local function get_identimg(label)
	local vid = BADID;
	
	if (resource("images/placeholders/" .. string.lower(label) .. ".png")) then
		vid = load_image("images/placeholders/" .. string.lower(label) .. ".png");
	end
	
	if (vid == BADID) then
-- as a fallback, generate a label
		vid = render_text(settings.colourtable.label_fontstr .. label);
		switch_default_texmode(TEX_REPEAT, TEX_REPEAT, vid);
		return vid, true;
	else
		return vid, false;
	end
end

local function positiondynamic(label)
	if (label == "Model") then
		local model = load_model("placeholder");

		if (model) then
			local vid = model.vid;
			customview.new_item3d(vid, "model", string.lower(label));
			orient3d_model(model.vid, 0, -90, 0);
			customview.position_item(vid, save_item, customview.position_modes_3d);
			show_image(vid);
			update_object3d(vid);
			return;
		end
	end
		
	local vid, tiled = get_identimg(label);

	if (label == "Vidcap") then
		customview.new_item(vid, "vidcap", string.lower(label));
		customview.ci.index = 0;
	else
		customview.new_item(vid, "dynamic_media", string.lower(label));
	end

	customview.ci.tiled = tiled;
	customview.ci.width  = VRESW * 0.3;
	customview.ci.height = VRESH * 0.3;
	update_object(vid);
	customview.position_item(vid, save_item);
end

local function positionlabel(label)
	vid = render_text(settings.colourtable.label_fontstr .. label);
	customview.new_item(vid, "label", string.lower(label));
	update_object(vid);
	customview.position_item(vid, save_item);
end

-- stretch to fit screen, only opa change allowed
local function positionbg(label)
	local tiled = false;
	local vid = load_image("backgrounds/" .. label);
	if (vid == BADID) then return; end

	customview.ci = {};
	customview.ci.tiled  = tiled;
	local props = image_surface_properties(vid);

	switch_default_texmode( TEX_REPEAT, TEX_REPEAT, vid );

	-- threshold for tiling rather than stretching
	if (props.width < VRESW / 2 or props.height < VRESH / 2) then
		customview.ci.tiled  = true;
	end

	customview.ci.width  = VRESW;
	customview.ci.height = VRESH;
	customview.ci.zv     = 0;
	customview.ci.x      = 0;
	customview.ci.y      = 0;
	customview.ci.opa    = 1.0;
	customview.ci.ang    = 0;
	customview.ci.kind   = "background";
	customview.ci.shader = customview.bgshader_label;
	customview.ci.res    = "backgrounds/" .. label;

	if (customview.ci.tiled) then
		local props = image_surface_initial_properties(vid);
		image_scale_txcos(vid, customview.ci.width / props.width, customview.ci.height / props.height);
	end

	update_object(vid);
	customview.position_item(vid, save_item_bg);
end

-- take the custom view and dump to a .lua config
local function save_config()
	open_rawresource("layout_cfg.lua");
	write_rawresource("local cview = {};\n");
	write_rawresource("cview.static = {};\n");
	write_rawresource("cview.dynamic = {};\n");
	write_rawresource("cview.models  = {};\n");
	write_rawresource("cview.dynamic_labels = {};\n");
	write_rawresource("cview.vidcap = {};\n");
	write_rawresource("cview.aspect = " .. tostring( VRESW / VRESH ) .. ";\n");
	
	for ind, val in ipairs(customview.itemlist) do
		if (val.kind == "model") then
			write_rawresource("local item = {};\n");
			write_rawresource("item.pos = {" .. tostring(val.pos[1]) .. ", " .. tostring(val.pos[2]) .. ", " .. tostring(val.pos[3]) .. "};\n");
			write_rawresource("item.ang = {" .. tostring(val.ang[1]) .. ", " .. tostring(val.ang[2]) .. ", " .. tostring(val.ang[3]) .. "};\n");

-- "options" for each item aren't definable yet, so hard- code in the necessary ones here 
			write_rawresource("item.dir_light = {1.0, 0.0, 0.0};\n");
			write_rawresource("item.ambient   = {0.3, 0.3, 0.3};\n");
			write_rawresource("item.diffuse   = {0.6, 0.6, 0.6};\n");

			write_rawresource("table.insert(cview.models, item);\n");
		else
			write_rawresource("local item = {};\n");
			write_rawresource("item.x      = " .. tostring( val.x / VRESW ) .. ";\n");
			write_rawresource("item.y      = " .. tostring( val.y / VRESH ) .. ";\n");
			write_rawresource("item.order  = " .. val.zv .. ";\n");
			write_rawresource("item.opa    = " .. val.opa .. ";\n");
			write_rawresource("item.ang    = " .. val.ang .. ";\n");
			write_rawresource("item.width  = " .. tostring(val.width / VRESW ) .. ";\n");
			write_rawresource("item.height = " .. tostring(val.height / VRESH ) .. ";\n");
			write_rawresource("item.tiled  = " .. tostring(val.tiled == true) .. ";\n");
		
			if val.kind == "static_media" then
				write_rawresource("item.res    = \"" .. val.res .. "\";\n");
				write_rawresource("table.insert(cview.static, item);\n");

			elseif val.kind == "dynamic_media" then
				write_rawresource("item.res    = \"" .. val.res .. "\";\n");
				write_rawresource("table.insert(cview.dynamic, item);\n");

			elseif val.kind == "vidcap" then
				write_rawresource("item.index  = " .. val.index .. ";\n");
				write_rawresource("table.insert(cview.vidcap, item);\n");
	
			elseif val.kind == "label" then
				write_rawresource("item.res    = \"" .. val.res .. "\";\n");
				write_rawresource("item.font   = [[\\ffonts/multilang.ttf,]];\n");
				write_rawresource("table.insert(cview.dynamic_labels, item);\n");
			
			elseif val.kind == "background" then
				write_rawresource("item.res    = \"" .. val.res .."\";\n");
				if (val.shader) then
					write_rawresource("item.shader = \"" .. val.shader .. "\";\n");
				end
				write_rawresource("cview.background = item;\n");
			else
				print("[customview:save_config] warning, unknown kind: " .. val.kind);
			end
		end

	end
	
	write_rawresource("return cview;\n");
	close_rawresource();
	
	while current_menu ~= nil do
		current_menu:destroy();
		current_menu = current_menu.parent;
	end
		
	settings.iodispatch = customview_display;
	pop_video_context();
	gridleremote_customview(lasttrigger);
end

-- reuse by other menu functions
function menu_defaultdispatch()
	if (not settings.iodispatch["MENU_UP"]) then
		settings.iodispatch["MENU_UP"] = function(iotbl) 
			current_menu:move_cursor(-1, true); 
		end
	end

	if (not settings.iodispatch["MENU_DOWN"]) then
			settings.iodispatch["MENU_DOWN"] = function(iotbl)
			current_menu:move_cursor(1, true); 
		end
	end
	
	if (not settings.iodispatch["MENU_SELECT"]) then
		settings.iodispatch["MENU_SELECT"] = function(iotbl)
			selectlbl = current_menu:select();
			if (current_menu.ptrs[selectlbl]) then
				current_menu.ptrs[selectlbl](selectlbl, false);
				if (current_menu and current_menu.updatecb) then
					current_menu.updatecb();
				end
			end
		end
	end
	
-- figure out if we should modify the settings table
	if (not settings.iodispatch["FLAG_FAVORITE"]) then
		settings.iodispatch["FLAG_FAVORITE"] = function(iotbl)
				selectlbl = current_menu:select();
				if (current_menu.ptrs[selectlbl]) then
					current_menu.ptrs[selectlbl](selectlbl, true);
					if (current_menu and current_menu.updatecb) then
						current_menu.updatecb();
					end
				end
			end
	end
	
	if (not (settings.iodispatch["MENU_ESCAPE"])) then
		settings.iodispatch["MENU_ESCAPE"] = function(iotbl, restbl, silent)
		current_menu:destroy();

		if (current_menu.parent ~= nil) then
			current_menu = current_menu.parent;
		else -- top level
			settings.iodispatch = griddispatch;
		end
		end
	end
	
	if (not settings.iodispatch["MENU_RIGHT"]) then
		settings.iodispatch["MENU_RIGHT"] = settings.iodispatch["MENU_SELECT"];
	end
	
	if (not settings.iodispatch["MENU_LEFT"]) then
		settings.iodispatch["MENU_LEFT"]  = settings.iodispatch["MENU_ESCAPE"];
	end
end

local function show_config()
	customview_display = settings.iodispatch;
	settings.iodispatch = {};
	customview.itemlist = {};
	
	menu_defaultdispatch();
	local escape_menu = function(label, save, sound)
		if (current_menu.parent ~= nil) then
			current_menu:destroy();
			current_menu = current_menu.parent;
		end
	end
	
	settings.iodispatch["MENU_LEFT"]   = escape_menu;
	settings.iodispatch["MENU_ESCAPE"] = escape_menu;
	
	local mainlbls = {};
	local mainptrs = {};

	add_submenu(mainlbls, mainptrs, "Backgrounds...", "ignore", build_globmenu("backgrounds/*.png", positionbg, ALL_RESOURCES));
	add_submenu(mainlbls, mainptrs, "Background Effects...", "ignore", build_globmenu("shaders/bgeffects/*.fShader", effecttrig, THEME_RESOURCES));
	add_submenu(mainlbls, mainptrs, "Images...", "ignore", build_globmenu("images/*.png", positionfun, THEME_RESOURCES));
	add_submenu(mainlbls, mainptrs, "Dynamic Media...", "ignore", gen_tbl_menu("ignore",	{"Screenshot", "Movie", "Bezel", "Marquee", "Flyer", "Boxart", "Vidcap", "Model"}, positiondynamic));
	add_submenu(mainlbls, mainptrs, "Dynamic Labels...", "ignore", gen_tbl_menu("ignore", {"Title", "Year", "Players", "Target", "Genre", "Subgenre", "Setname", "Buttons", "Manufacturer", "System"}, positionlabel));
	
	table.insert(mainlbls, "---");
	table.insert(mainlbls, "Save");
	
	mainptrs["Save"] = save_config;
	
	current_menu = listview_create(mainlbls, VRESH * 0.9, VRESW / 3);
	current_menu.ptrs = mainptrs;
	current_menu.parent = nil;
	customview.root_menu = current_menu;

	current_menu:show();
	move_image(current_menu.anchor, 10, VRESH * 0.1, settings.fadedelay);
end

local function place_item( vid, tbl )
	local x = math.floor(tbl.x     * VRESW);
	local y = math.floor(tbl.y     * VRESH);
	local w = math.floor(tbl.width * VRESW);
	local h = math.floor(tbl.height* VRESH);

  move_image(vid, x, y);
	rotate_image(vid, tbl.ang);
	resize_image(vid, w, h);
	order_image(vid, tbl.order);
	blend_image(vid, tbl.opa);
end

local function place_model(modelid, pos, ang)
	move3d_model(modelid, pos[1], pos[2], pos[3]);
	rotate3d_model(modelid, ang[1], ang[2], ang[3]);
	show_image(modelid);
end

function gridleremote_updatedynamic(newtbl)
	if (newtbl == nil or newtbl == customview.lasttbl) then
		return;
	end

	customview.lasttbl = newtbl;
--	toggle_led(newtbl.players, newtbl.buttons, "")	;

-- this table is maintained for every newly selected item, and just tracks everything to delete.
	for ind, val in ipairs(customview.temporary) do
		if (valid_vid(val)) then delete_image(val); end 
	end

	for ind, val in ipairs(customview.temporary_models) do
		if (valid_vid(val.vid)) then delete_image(val.vid); end
	end
	
	customview.temporary = {};
	customview.temporary_models = {};

	local restbl = resourcefinder_search( newtbl, true );

	if (restbl) then
		if (customview.current.models and #customview.current.models > 0) then
			local modelstr = find_cabinet_model(newtbl);
			local model  = modelstr and setup_cabinet_model(modelstr, restbl, {}) or nil;

			if (model) then
				local shdr = customview.light_shader;
	
				table.insert(customview.temporary_models, model);
				table.insert(customview.temporary, model.vid);

				local cm = customview.current.models[1];
				
				image_shader(model.vid, customview.light_shader);
				place_model(model.vid, cm.pos, cm.ang);

				local ld = cm.dir_light and cm.dir_light or {1.0, 0.0, 0.0};
				shader_uniform(shdr, "wlightdir", "fff", PERSIST, ld[1], ld[2], ld[3]);

				local la = cm.ambient and cm.ambient or {0.3, 0.3, 0.3};
				shader_uniform(shdr, "wambient",  "fff", PERSIST, la[1], la[2], la[3]);
				
				ld = cm.diffuse and cm.diffuse or {0.6, 0.6, 0.6};
				shader_uniform(shdr, "wdiffuse",  "fff", PERSIST, 0.6, 0.6, 0.6);
	
-- reuse the model for multiple instances
				for i=2,#customview.current.models do
					local nid = instance_image(model.vid);
					image_mask_clear(nid, MASK_POSITION);
					image_mask_clear(nid, MASK_ORIENTATION);
					place_model(nid, customview.current.models[i].pos, customview.current.models[i].ang);
				end
			end
		end

		for ind, val in ipairs(customview.current.dynamic) do
			reskey = remaptbl[val.res];
			
			if (reskey and restbl[reskey] and #restbl[reskey] > 0) then
				if (reskey == "movies") then
					vid, aid = load_movie(restbl[reskey][1], FRAMESERVER_LOOP, function(source, status)
						place_item(source, val);
						play_movie(source);
					end)
					table.insert(customview.temporary, vid);	
				else
					vid = load_image_asynch(restbl[reskey][1], function(source, status)
						place_item(source, val);
					end);
					table.insert(customview.temporary, vid);
				end
	
			end
		end

		for ind, val in ipairs(customview.current.dynamic_labels) do
			local dststr = newtbl[val.res];
			
			if (type(dststr) == "number") then dststr = tostring(dststr); end
			
			if (dststr and string.len( dststr ) > 0) then
				local capvid = fill_surface(math.floor( VRESW * val.width), math.floor( VRESH * val.height ), 0, 0, 0);
				vid = render_text(val.font .. math.floor( VRESH * val.height ) .. " " .. dststr);
				link_image(vid, capvid);
				image_mask_clear(vid, MASK_OPACITY);
				place_item(capvid, val);

				hide_image(capvid);
				show_image(vid);
				resize_image(vid, 0, VRESH * val.height);
				order_image(vid, val.order);
				table.insert(customview.temporary, capvid);
				table.insert(customview.temporary, vid);
			end
			
		end
		
	end
end

local function setup_customview(triggerfun)
	local background = nil;
	for ind, val in ipairs( customview.current.static ) do
		local vid = load_image( val.res );
		place_item( vid, val );
	end

-- video capture devices, can either be instances of the same vidcap OR multiple devices based on index 
	customview.current.vidcap_instances = {};
	for ind, val in ipairs( customview.current.vidcap ) do
		inst = customview.current.vidcap_instances[val.index];
		
		if (valid_vid(inst)) then
			inst = instance_image(inst);
			image_mask_clearall(inst);
			place_item( inst, val );
		else
			local vid = load_movie("vidcap:" .. tostring(val.index), FRAMESERVER_LOOP, function(source, status)
				place_item(source, val);
				play_movie(source);
			end);
		
			customview.current.vidcap_instances[val.index] = vid;
		end
	end

-- load background effect 
	if (customview.current.background) then
		vid = load_image( customview.current.background.res );
		switch_default_texmode(TEX_REPEAT, TEX_REPEAT, vid);

		customview.background = vid;

		place_item(vid, customview.current.background);
		customview.bgshader_label = customview.current.background.shader;

		local props  = image_surface_properties(vid);
		local iprops = image_surface_initial_properties(vid);

		if (customview.current.background.tiled) then
			image_scale_txcos(vid, props.width / iprops.width, props.height / iprops.height);
		end
		
		if (customview.bgshader_label) then
			customview.bgshader = load_shader("shaders/fullscreen/default.vShader", "shaders/bgeffects/" .. customview.bgshader_label, "bgeffect", {});
			update_bgshdr();
		end
	end

-- remap I/O functions to fit navigator
	olddispatch = settings.iodispatch;
	settings.iodispatch = {};
	
	customview.dispatchtbl = settings.iodispatch;
end

local function customview_3dbase()
	local lshdr = load_shader("shaders/dir_light.vShader", "shaders/dir_light.fShader", "cvdef3d");
	shader_uniform(lshdr, "map_diffuse", "i"  , PERSIST, 0);
	customview.light_shader = lshdr;
end

function gridleremote_customview(triggerfun)
	local disptbl;
	lasttrigger = triggerfun;
	
-- try to load a preexisting configuration file, if no one is found
-- launch in configuration mode -- to reset this procedure, delete any 
-- customview_cfg.lua and reset customview.in_config
	setup_3dsupport();
	customview_3dbase();

	if (resource("layout_cfg.lua")) then
		customview.background    = nil;
		customview.bgshader      = nil;
		customview.current       = system_load("layout_cfg.lua")();
	
		if (customview.current) then
			customview.in_customview = true;
			customview.in_config = false;
			setup_customview();
			triggerfun();
		end

	else
		customview.in_config = true;
		video_3dorder(ORDER_LAST);
		disptbl = show_config();
	end
	
end