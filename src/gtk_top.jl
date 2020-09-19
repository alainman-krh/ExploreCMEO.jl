#gtk_top.jl: Top-level gtk functionnality
#-------------------------------------------------------------------------------


#==Types
===============================================================================#
abstract type WndState end #Identifies current state of the Explore window.
struct WSNormal <: WndState; end #Default state
struct WSUpdating <: WndState; end #Updating

mutable struct ExploreWnd
	state::WndState
	sel::ExploreSelection
	db::HDF5.HDF5File
	wnd::_Gtk.Window
	cb_subjects::_Gtk.ComboBoxText
	rb_grade_list::Vector{_Gtk.RadioButton}
	ent_sourcedoc::_Gtk.Entry
#	rg_grades::_Gtk.RadioButtonGroup
	ls_domains::_Gtk.ListStore
	tv_domains::_Gtk.TreeView
	ls_attentes::_Gtk.ListStore
	tv_attentes::_Gtk.TreeView
	ent_attentesdesc::_Gtk.Entry
end


#==GUI scanners/builders
===============================================================================#
function _scan(explore::ExploreWnd)
	sel = explore.sel #Alias
		sel.grade_idx = 0
		sel.domain_idx = 0
		sel.attente_idx = 0
#		sel.content_idx = 0

	sel_subject = GAccessor.active_text(explore.cb_subjects)
	sel.subject = (sel_subject != C_NULL) ? unsafe_string(sel_subject) : ""

	for (idx, rb) in enumerate(explore.rb_grade_list)
		if GAccessor.active(rb)
			sel.grade_idx = idx
			break
		end
	end
		#gtk_toggle_button_set_active(e, active::Bool)

	_sel = GAccessor.selection(explore.tv_domains)
	if Gtk.hasselection(_sel)
		elem = explore.ls_domains[Gtk.selected(_sel)]
		sel.domain_idx = elem[1]
	end

	_sel = GAccessor.selection(explore.tv_attentes)
	if Gtk.hasselection(_sel)
		elem = explore.ls_attentes[Gtk.selected(_sel)]
		sel.attente_idx = elem[1]
	end

#@show _sel
#	_sel = GAccessor.selection(explore.cb_subjects)
#	@show Gtk.selected(_sel)

	@show sel
	return sel
end

function _populate(explore::ExploreWnd)
	sel = explore.sel #Alias

#	grade_idx::Int
#	domain_idx::Int
#	attente_idx::Int
#	content_idx::Int

	subject_list = read_subjects(explore.db)
		empty!(explore.cb_subjects)
		for v in subject_list
		  push!(explore.cb_subjects, v)
		end
		idx = findfirst((x)->(sel.subject==x), subject_list)
		if isnothing(idx); idx = 0; end
		set_gtk_property!(explore.cb_subjects, :active, idx-1) #Set active element

	sel.grade_idx = max(1, min(sel.grade_idx, length(explore.rb_grade_list)))
	Gtk.gtk_toggle_button_set_active(explore.rb_grade_list[sel.grade_idx], true)

	sdinfo = read_sourcedoc(explore.db, sel)
		set_gtk_property!(explore.ent_sourcedoc, :text, sdinfo)

	dlist = read_domain_list(explore.db, sel)
		sel.domain_idx = min(sel.domain_idx, length(dlist))
		empty!(explore.ls_domains)
		for d in dlist
			push!(explore.ls_domains, d)
		end
		if sel.domain_idx > 0
			iter = Gtk.iter_from_index(explore.ls_domains, sel.domain_idx) #1-based wrapper!
			Gtk.select!(GAccessor.selection(explore.tv_domains), iter)
		end

	alist = read_attente_list(explore.db, sel)
		sel.attente_idx = min(sel.attente_idx, length(alist))
		descr = ""
		empty!(explore.ls_attentes)
		for a in alist
			push!(explore.ls_attentes, a)
		end
		if sel.attente_idx > 0
			iter = Gtk.iter_from_index(explore.ls_attentes, sel.attente_idx) #1-based wrapper!
			Gtk.select!(GAccessor.selection(explore.tv_attentes), iter)
			descr = alist[sel.attente_idx][4]
		end
		set_gtk_property!(explore.ent_attentesdesc, :text, descr)

	return
end


#==State-dependent functions
===============================================================================#
function state_set!(explore::ExploreWnd, state::WndState)
	explore.state = state
	return explore
end
function refresh!(::WSNormal, explore::ExploreWnd)
	state_set!(explore, WSUpdating())
	try
		_scan(explore)
		_populate(explore)
	catch e
		@warn(e)
		rethrow(e)
	finally
		state_set!(explore, WSNormal())
	end
	return
end
refresh!(::WSUpdating, explore::ExploreWnd) = nothing


#==Public interface
===============================================================================#
#Overwrite show (inhibit dumping Gtk info):
function Base.show(io::IO, ::MIME"text/plain", explore::ExploreWnd)
	print(io, ExploreWnd, "(\"", explore.db.filename, "\")")
end

refresh!(explore::ExploreWnd) = refresh!(explore.state, explore)

function Base.close(explore::ExploreWnd)
	window_close(explore.wnd)
	return nothing
end


#==Callback wrapper functions
===============================================================================#
@guarded function cb_wnddestroyed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	close(explore.db)
	@info("Fermeture de données")
	return #Known value
end
@guarded function cb_mnufileclose(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	close(explore)
	nothing #Known value
end
@guarded function cb_subjectchanged(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_gradechanged(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_domainchanged(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_attenteschanged(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end


#=="Constructors"
===============================================================================#

function ExploreWnd(dbpath=PATH_DB[])
	#Rendering types for tree views:
	rTxt = _Gtk.CellRendererText()
	#rTog = _Gtk.CellRendererToggle()

	vbox = _Gtk.Box(true, 0) #Main vbox for all widgets

	#Menu bar:
	mb = _Gtk.MenuBar()
		push!(vbox, mb) #Menu bar
	mnufile = Gtk_addmenu(mb, "_Fichier")
		Gtk_addsep(mnufile)
		mnuquit = Gtk_addmenuitem(mnufile, "_Quitter")

	cb_subjects = _Gtk.ComboBoxText()
		push!(vbox, cb_subjects)

	#Radio buttons for grade:
	grp_grades = _Gtk.RadioButtonGroup()
		set_gtk_property!(grp_grades.handle, :orientation, GtkOrientation.HORIZONTAL)
		push!(vbox, grp_grades)
		rb_grade_list = _Gtk.RadioButton[]

		for (i, id) in enumerate(LIST_GRADEID)
#			x = mod(i-1, MAXCOL_GRADEID); y = div(i-1, MAXCOL_GRADEID)
			rb = _Gtk.RadioButton(id)
			push!(rb_grade_list, rb)
			push!(grp_grades, rb)
		end
		#gtk_toggle_button_set_active(e, active::Bool)

	#Textbox for source documentation info:
	ent_sourcedoc = _Gtk.Entry()
		push!(vbox, ent_sourcedoc)
		set_gtk_property!(ent_sourcedoc, :text, "")
		set_gtk_property!(ent_sourcedoc, :editable, false)

	#List for domain:
	ls_domains = _Gtk.ListStore(Int, String, String) #index, id, domaine
	tv_domains = _Gtk.TreeView(_Gtk.TreeModel(ls_domains))
		push!(vbox, tv_domains)
		c1 = _Gtk.TreeViewColumn("ID", rTxt, Dict("text"=>1))
		c2 = _Gtk.TreeViewColumn("Domaine", rTxt, Dict("text"=>2))
		#c3 = _Gtk.TreeViewColumn("BVal", rTog, Dict("active"=>2))
		push!(tv_domains, c1, c2)

	#List for "attentes":
	ls_attentes = _Gtk.ListStore(Int, String, String, String) #index, id, nom, description
	tv_attentes = _Gtk.TreeView(_Gtk.TreeModel(ls_attentes))
		push!(vbox, tv_attentes)
		c1 = _Gtk.TreeViewColumn("ID", rTxt, Dict("text"=>1))
		c2 = _Gtk.TreeViewColumn("Attente", rTxt, Dict("text"=>2))
		push!(tv_attentes, c1, c2)
		sel = GAccessor.selection(tv_attentes)
#		sel = GAccessor.mode(sel, GtkSelectionMode.MULTIPLE)

	#Textbox for "attentes" description:
	ent_attentesdesc = _Gtk.Entry()
		push!(vbox, ent_attentesdesc)
		set_gtk_property!(ent_attentesdesc, :text, "")
		set_gtk_property!(ent_attentesdesc, :editable, false)


#	str = get_gtk_property(ent_attentesdesc, :text, String)
#	set_gtk_property!(tv_domains, :visible, false)
#	set_gtk_property!(tv_domains, :visible, true)

	#Create container object & callbacks:
	db = HDF5.h5open(dbpath, "r+")
	wnd = Gtk.Window(vbox, "", 640, 480, true)
	explore = ExploreWnd(WSNormal(), ExploreSelection(), db,
		wnd, cb_subjects, rb_grade_list, ent_sourcedoc,
		ls_domains, tv_domains, ls_attentes, tv_attentes, ent_attentesdesc
	)
	signal_connect(cb_wnddestroyed, wnd, "destroy", Nothing, (), false, explore)
	signal_connect(cb_mnufileclose, mnuquit, "activate", Nothing, (), false, explore)

	signal_connect(cb_subjectchanged, cb_subjects, "changed", Nothing, (), false, explore)
	for rb in rb_grade_list
		signal_connect(cb_gradechanged, rb, "toggled", Nothing, (), false, explore)
	end
	sel_domains = GAccessor.selection(explore.tv_domains)
	signal_connect(cb_domainchanged, sel_domains, "changed", Nothing, (), false, explore)
	sel_attentes = GAccessor.selection(explore.tv_attentes)
	signal_connect(cb_attenteschanged, sel_attentes, "changed", Nothing, (), false, explore)

	#Populate, show & return:
	refresh!(explore)
	Gtk.showall(explore.wnd)
	return explore
end
