#gtk_editdlg.jl: Edit dialog
#-------------------------------------------------------------------------------


#==Types
===============================================================================#

mutable struct ExploreEditDlg <: AbstractDialog
	data::FieldViewEditData
	explore::ExploreWnd #Reference
	sel::ExploreSelection #Store desired selection (copied so it doesn't change)
	wnd::_Gtk.Window
	ent_fieldinfo::_Gtk.Entry
	frame_fieldview::_Gtk.Frame
	frame_shortdescr::_Gtk.Frame
	tv_shortdescr::_Gtk.TextView
	frame_descr::_Gtk.Frame
	tv_descr::_Gtk.TextView
	btn_ok::_Gtk.Button
	btn_apply::_Gtk.Button
end


#==Helper functions
===============================================================================#
function _apply(dlg::ExploreEditDlg)
	tb = dlg.tv_shortdescr.buffer[_Gtk.TextBuffer]
		dlg.data.shortdescr = get_gtk_property(tb, "text", String)
	tb = dlg.tv_descr.buffer[_Gtk.TextBuffer]
		dlg.data.descr = get_gtk_property(tb, "text", String)
	try
		_write(dlg.data, dlg.explore.db, dlg.sel)
	catch e
		@warn(e)
		return false
	end
	return true
end


#==Callback functions
===============================================================================#
@guarded function cb_wnddestroyed(w::Ptr{Gtk.GObject}, dlg::ExploreEditDlg)
	dlg.explore.editdlg = NoDialog()
	refresh!(dlg.explore)
	return #Known value
end
@guarded function cb_ok_clicked(w::Ptr{Gtk.GObject}, dlg::ExploreEditDlg)
	if _apply(dlg)
		close(dlg) #Only close if succeeds
	end
	return #Known value
end
@guarded function cb_cancel_clicked(w::Ptr{Gtk.GObject}, dlg::ExploreEditDlg)
	close(dlg)
	return #Known value
end
@guarded function cb_apply_clicked(w::Ptr{Gtk.GObject}, dlg::ExploreEditDlg)
	_apply(dlg)
	refresh!(dlg.explore)
	return #Known value
end


#==Constructors
===============================================================================#
function ExploreEditDlg(explore::ExploreWnd)
	border_width = 10
	_spacing = 10

	vbox = _Gtk.Box(true, _spacing) #Main vbox for all widgets
		set_gtk_property!(vbox, "border-width", border_width)

	#Textbox explaining which field we are changing:
	ent_fieldinfo = _Gtk.Entry()
		push!(vbox, ent_fieldinfo)
		set_gtk_property!(ent_fieldinfo, "editable", false)

	frame_fieldview = _Gtk.Frame()
		push!(vbox, frame_fieldview)
	vbox_fieldview = _Gtk.Box(true, 0) 
		push!(frame_fieldview, vbox_fieldview)

	#Short description
	frame_shortdescr = _Gtk.Frame()
		push!(vbox_fieldview, frame_shortdescr)
		set_gtk_property!(frame_shortdescr, "label", "Description (courte):")
		set_gtk_property!(frame_shortdescr, "border-width", border_width)
	vbox_pad = _Gtk.Box(true, 0)
		push!(frame_shortdescr, vbox_pad)
		set_gtk_property!(vbox_pad, "border-width", border_width)
	tv_shortdescr = _Gtk.TextView()
		push!(vbox_pad, tv_shortdescr)
		set_gtk_property!(tv_shortdescr, "editable", true)
		set_gtk_property!(tv_shortdescr, "wrap-mode", GtkWrapMode.WORD_CHAR)

	#Long description
	frame_descr = _Gtk.Frame()
		push!(vbox_fieldview, frame_descr)
		set_gtk_property!(frame_descr, "label", "Description:")
		set_gtk_property!(frame_descr, "border-width", border_width)
	vbox_pad = _Gtk.Box(true, 0)
		push!(frame_descr, vbox_pad)
		set_gtk_property!(vbox_pad, "border-width", border_width)
	tv_descr = _Gtk.TextView()
		push!(vbox_pad, tv_descr)
		set_gtk_property!(tv_descr, "editable", true)
		set_gtk_property!(tv_descr, "wrap-mode", GtkWrapMode.WORD_CHAR)
#		GAccessor.size_request(tv_descr, -1, 100)
		set_gtk_property!(tv_descr, "vexpand", true)
		set_gtk_property!(tv_descr, "vexpand-set", true)

	btnbox = _Gtk.Box(false, _spacing)
		push!(vbox, btnbox)
	filler = _Gtk.Box(true, 0)
		push!(btnbox, filler)
		set_gtk_property!(filler, "hexpand", true)
		set_gtk_property!(filler, "hexpand-set", true)
	btn_ok = _Gtk.Button("Ok")
		push!(btnbox, btn_ok)
	btn_apply = _Gtk.Button("Appliquer")
		push!(btnbox, btn_apply)
	btn_cancel = _Gtk.Button("Annuler")
		push!(btnbox, btn_cancel)
#	gtk_container_child_set_property #Wrapped in GAccessor.property:
#	GAccessor.property(btnbox, btn_ok, "pack-type", GtkPackType.END) #Crashes; expects ptr for value
#	GAccessor.property(btnbox, btn_cancel, "pack-type", GtkPackType.END)

	wnd = Gtk.Window(vbox, "", 400, 300)#, true)
		set_gtk_property!(wnd, "title", "ExploreCMEO")

	dlg = ExploreEditDlg(FieldViewEditData(),
		explore, ExploreSelection(), wnd,
		ent_fieldinfo, frame_fieldview,
		frame_shortdescr, tv_shortdescr, frame_descr, tv_descr, btn_ok, btn_apply
	)

	signal_connect(cb_wnddestroyed, wnd, "destroy", Nothing, (), false, dlg)
	signal_connect(cb_ok_clicked, btn_ok, "clicked", Nothing, (), false, dlg)
	signal_connect(cb_cancel_clicked, btn_cancel, "clicked", Nothing, (), false, dlg)
	signal_connect(cb_apply_clicked, btn_apply, "clicked", Nothing, (), false, dlg)

	return dlg
end


#==_show() algorithm
===============================================================================#
function _show(dlg::ExploreEditDlg)
	fieldview = _activefieldview(dlg.explore)
	dlg.sel = deepcopy(dlg.explore.sel) #Get new selection
	success = true
	try
		dlg.data = FieldViewEditData(fieldview) #Set appropriate type
		_read(dlg.data, dlg.explore.db, dlg.sel)
	catch e
		#rethrow(e) #for debug purposes
		success = false
	end
	fv_id = getlabelledid(fieldview, dlg.sel)

	#Update ent_fieldinfo:
	_subject = strip(dlg.sel.subject)
	labelfieldinfo = ""
	if isempty_subject(_subject)
		success = false
		labelfieldinfo = MSG_NOSUBJECT
	elseif !success
		labelfieldinfo = string(fv_id, ": ", MSG_CANNOTEDIT)
	else
		labelfieldinfo = string(
			"Sujet: ", _subject,
			", Niveau: ", getid_grade(dlg.sel.grade_idx),
		)
	end

	set_gtk_property!(dlg.ent_fieldinfo, "text", labelfieldinfo)
	set_gtk_property!(dlg.frame_fieldview, "label", fv_id)
	set_gtk_property!(dlg.frame_shortdescr, "visible", false)
	set_gtk_property!(dlg.frame_shortdescr, "no-show-all", !dlg.data.has_shortdescr)
	tb = dlg.tv_shortdescr.buffer[_Gtk.TextBuffer]
		set_gtk_property!(tb, "text", dlg.data.shortdescr)
	tb = dlg.tv_descr.buffer[_Gtk.TextBuffer]
		set_gtk_property!(tb, "text", dlg.data.descr)
		#tb.text[String] = "some text" #Could use this syntax - not sure if supported, though.
	set_gtk_property!(dlg.btn_ok, "sensitive", success) #Conditionaly disable
	set_gtk_property!(dlg.btn_apply, "sensitive", success) #Conditionaly disable

	Gtk.showall(dlg.wnd)
	refresh!(dlg.explore) #Just in case out of sync (might have created data)
	nothing
end


#==_show() wrapper (Create dialog if not registered with .editdlg)
===============================================================================#
_show_editdlg(explore::ExploreWnd, editdlg::ExploreEditDlg) = _show(editdlg)
function _show_editdlg(explore::ExploreWnd, editdlg) #Have not specified edit dialog yet
	explore.editdlg = ExploreEditDlg(explore)
	_show(explore.editdlg)
end
show_editdlg(explore::ExploreWnd) = _show_editdlg(explore, explore.editdlg)

#Last line
