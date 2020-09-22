#gtk_top.jl: Top-level gtk functionnality
#-------------------------------------------------------------------------------


#==Types
===============================================================================#


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

	_sel = GAccessor.selection(explore.tv_content)
	if Gtk.hasselection(_sel)
		elem = explore.ls_content[Gtk.selected(_sel)]
		sel.content_idx = elem[1]
	end

#@show _sel
#	_sel = GAccessor.selection(explore.cb_subjects)
#	@show Gtk.selected(_sel)

#	@show sel
	return sel
end

function _populate(explore::ExploreWnd)
	sel = explore.sel #Alias

	subject_list = read_subjects(explore.db)
		empty!(explore.cb_subjects)
		for v in subject_list
		  push!(explore.cb_subjects, v)
		end
		idx = findfirst((x)->(sel.subject==x), subject_list)
		if isnothing(idx); idx = 0; end
		set_gtk_property!(explore.cb_subjects, "active", idx-1) #Set active element

	sel.grade_idx = max(1, min(sel.grade_idx, length(explore.rb_grade_list)))
	Gtk.gtk_toggle_button_set_active(explore.rb_grade_list[sel.grade_idx], true)

	sdinfo = read_sourcedoc(explore.db, sel)
		if isnothing(sdinfo); sdinfo = MSG_NODATA; end
		set_gtk_property!(explore.ent_sourcedoc, "text", sdinfo)

	dlist = read_domain_list(explore.db, sel)
		if isnothing(dlist); dlist = [DATA_NODOMAIN]; end
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
		if isnothing(alist); alist = [DATA_NOATTENTE]; end
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
		set_gtk_property!(explore.ent_attentesdesc, "text", descr)

	clist = read_content_list(explore.db, sel)
		if isnothing(clist); clist = [DATA_NOCONTENT]; end
		sel.content_idx = min(sel.content_idx, length(clist))
		descr = ""
		empty!(explore.ls_content)
		for c in clist
			push!(explore.ls_content, c)
		end
		if sel.content_idx > 0
			iter = Gtk.iter_from_index(explore.ls_content, sel.content_idx) #1-based wrapper!
			Gtk.select!(GAccessor.selection(explore.tv_content), iter)
		end

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


#==Callback wrapper functions
===============================================================================#
@guarded function cb_wnddestroyed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	close(explore.db)
	@info("Fermeture de données")
	close(explore.editdlg)
	return #Known value
end
@guarded function cb_mnufileclose(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	close(explore)
	nothing #Known value
end
@guarded function cb_mnucopy(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	opt = FieldViewOpts()
	afview = _activefieldview(explore)
	copystr = copyfv(afview, explore, opt)
	clipboard_set_text(explore, copystr)
	@info("Copié:\n$copystr")
	nothing #Known value
end
@guarded function cb_mnucopyall(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	opt = FieldViewOpts()
	afview = _activefieldview(explore)
	copystr = copyallfv(afview, explore, opt)
	clipboard_set_text(explore, copystr)
	@info("Copié tout:\n$copystr")
	nothing #Known value
end
@guarded function cb_mnuaddentry(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	try
		a
	catch
	end
#	show_editdlg(explore)
	nothing #Known value
end
@guarded function cb_mnueditfield(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	show_editdlg(explore)
	nothing #Known value
end
@guarded function cb_cb_subjects_changed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_rb_gradelist_changed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_sel_domains_changed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_sel_attentes_changed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end
@guarded function cb_sel_content_changed(w::Ptr{Gtk.GObject}, explore::ExploreWnd)
	refresh!(explore::ExploreWnd)
	return #Known value
end


#=="Constructors"
===============================================================================#

function ExploreWnd(dbpath=PATH_DB[])
	#Rendering types for tree views:
	#rTog = _Gtk.CellRendererToggle()
	rTxt = _Gtk.CellRendererText()
		#@show get_gtk_property(rTxt, "yalign")
		set_gtk_property!(rTxt, "yalign", 0)
	rTxt_mline = _Gtk.CellRendererText()
		set_gtk_property!(rTxt_mline, "wrap-width", 400) #Could update with wndsize
		set_gtk_property!(rTxt_mline, "yalign", 0)

	vbox = _Gtk.Box(true, 0) #Main vbox for all widgets

	#Menu bar:
	mb = _Gtk.MenuBar()
		push!(vbox, mb) #Menu bar
	mnufile = Gtk_addmenu(mb, "_Fichier")
		Gtk_addsep(mnufile)
		mnuquit = Gtk_addmenuitem(mnufile, "_Quitter")
	mnuedit = Gtk_addmenu(mb, "_Édition")
		mnucopy = Gtk_addmenuitem(mnuedit, "Copier")
		mnucopyall = Gtk_addmenuitem(mnuedit, "Copier Tout")
		Gtk_addsep(mnuedit)
		mnuaddentry = Gtk_addmenuitem(mnuedit, "Ajouter Entrée")
		mnuremoveentry = Gtk_addmenuitem(mnuedit, "Supprimer Dernière Entrée")
		mnueditfield = Gtk_addmenuitem(mnuedit, "Modifier Élément/Champ")

	#Add accelerator keys to menu items:
	accel_group = Gtk.GtkAccelGroupLeaf()
		push!(mnucopy, "activate", accel_group, GConstants.GDK_KEY_F,
			GdkModifierType.CONTROL, GtkAccelFlags.VISIBLE
		)
		push!(mnucopyall, "activate", accel_group, GConstants.GDK_KEY_F,
			GdkModifierType.GDK_CONTROL_MASK|GdkModifierType.SHIFT, GtkAccelFlags.VISIBLE
		)
		push!(mnuaddentry, "activate", accel_group, GConstants.GDK_KEY_A,
			GdkModifierType.GDK_CONTROL_MASK, GtkAccelFlags.VISIBLE
		)
#		push!(mnuremoveentry, "activate", accel_group, GConstants.GDK_KEY_D,
#			GdkModifierType.GDK_CONTROL_MASK, GtkAccelFlags.VISIBLE
#		)
		push!(mnueditfield, "activate", accel_group, GConstants.GDK_KEY_E,
			GdkModifierType.GDK_CONTROL_MASK, GtkAccelFlags.VISIBLE
		)

	cb_subjects = _Gtk.ComboBoxText()
		push!(vbox, cb_subjects)

	#Radio buttons for grade:
	grp_grades = _Gtk.RadioButtonGroup()
		set_gtk_property!(grp_grades.handle, "orientation", GtkOrientation.HORIZONTAL)
		push!(vbox, grp_grades)
		rb_grade_list = _Gtk.RadioButton[]

		for (i, id) in enumerate(LIST_GRADEID)
			rb = _Gtk.RadioButton(id)
			push!(rb_grade_list, rb)
			push!(grp_grades, rb)
		end
		#gtk_toggle_button_set_active(e, active::Bool)

	#Textbox for source documentation info:
	ent_sourcedoc = _Gtk.Entry()
		push!(vbox, ent_sourcedoc)
		set_gtk_property!(ent_sourcedoc, "text", "")
		set_gtk_property!(ent_sourcedoc, "editable", false)

	#List for domain:
	ls_domains = _Gtk.ListStore(Int, String, String) #index, id, domain
	tv_domains = _Gtk.TreeView(_Gtk.TreeModel(ls_domains))
		c1 = _Gtk.TreeViewColumn("ID", rTxt, Dict("text"=>1))
		c2 = _Gtk.TreeViewColumn("Domaine", rTxt, Dict("text"=>2))
		push!(tv_domains, c1, c2)

	#List for "attentes":
	ls_attentes = _Gtk.ListStore(Int, String, String, String) #index, id, shortdescr, descr
	tv_attentes = _Gtk.TreeView(_Gtk.TreeModel(ls_attentes))
		c1 = _Gtk.TreeViewColumn("ID", rTxt, Dict("text"=>1))
		c2 = _Gtk.TreeViewColumn("Attente", rTxt, Dict("text"=>2))
		push!(tv_attentes, c1, c2)
		sel = GAccessor.selection(tv_attentes)
#		sel = GAccessor.mode(sel, GtkSelectionMode.MULTIPLE)

	pane_da = _Gtk.Paned(false, 0) #_Gtk.Box(false, 0) #hbox for domains & "attentes"
		push!(vbox, pane_da)
		#Use scrolled windows to inhibit "natural" width (allow smaller)
		swleft = _Gtk.ScrolledWindow()
			push!(swleft, tv_domains)
			GAccessor.policy(swleft, GtkPolicyType.EXTERNAL, GtkPolicyType.NEVER)
		swright = _Gtk.ScrolledWindow()
			push!(swright, tv_attentes)
			GAccessor.policy(swright, GtkPolicyType.EXTERNAL, GtkPolicyType.NEVER)
		push!(pane_da, swleft, swright)
		set_gtk_property!(pane_da, "position", 250)
		set_gtk_property!(pane_da, "position-set", true)
		set_gtk_property!(pane_da, "wide-handle", true)

	#Textbox for "attentes" description:
	ent_attentesdesc = _Gtk.Entry()
		push!(vbox, ent_attentesdesc)
		set_gtk_property!(ent_attentesdesc, "text", "")
		set_gtk_property!(ent_attentesdesc, "editable", false)

	#List for content:
	swnd = _Gtk.ScrolledWindow() #Inhibit "natural" width
		push!(vbox, swnd)
	ls_content = _Gtk.ListStore(Int, String, String) #index, id, description
	tv_content = _Gtk.TreeView(_Gtk.TreeModel(ls_content))
		push!(swnd, tv_content)
			GAccessor.policy(swnd, GtkPolicyType.EXTERNAL, GtkPolicyType.ALWAYS)
		c1 = _Gtk.TreeViewColumn("ID", rTxt, Dict("text"=>1))
		c2 = _Gtk.TreeViewColumn("Contenu d'apprentissage", rTxt_mline, Dict("text"=>2))
		push!(tv_content, c1, c2)
		set_gtk_property!(tv_content, "vexpand", true)
		sel = GAccessor.selection(tv_content)

	#Create container object & callbacks:
	db = open_database(dbpath, "r+")
	wnd = Gtk.Window(vbox, "", 640, 480, true)
		push!(wnd, accel_group)
		set_gtk_property!(wnd, "title", "ExploreCMEO")

	explore = ExploreWnd(WSNormal(), ExploreSelection(), db,
		wnd, cb_subjects, rb_grade_list, ent_sourcedoc,
		ls_domains, tv_domains, ls_attentes, tv_attentes, ent_attentesdesc,
		ls_content, tv_content, NoDialog()
	)
	signal_connect(cb_wnddestroyed, wnd, "destroy", Nothing, (), false, explore)
	signal_connect(cb_mnufileclose, mnuquit, "activate", Nothing, (), false, explore)
	signal_connect(cb_mnucopy, mnucopy, "activate", Nothing, (), false, explore)
	signal_connect(cb_mnucopyall, mnucopyall, "activate", Nothing, (), false, explore)
	signal_connect(cb_mnuaddentry, mnuaddentry, "activate", Nothing, (), false, explore)
	signal_connect(cb_mnueditfield, mnueditfield, "activate", Nothing, (), false, explore)


	signal_connect(cb_cb_subjects_changed, cb_subjects, "changed", Nothing, (), false, explore)
	for rb in rb_grade_list
		signal_connect(cb_rb_gradelist_changed, rb, "toggled", Nothing, (), false, explore)
	end
	sel_domains = GAccessor.selection(explore.tv_domains)
	signal_connect(cb_sel_domains_changed, sel_domains, "changed", Nothing, (), false, explore)
	sel_attentes = GAccessor.selection(explore.tv_attentes)
	signal_connect(cb_sel_attentes_changed, sel_attentes, "changed", Nothing, (), false, explore)
	sel_content = GAccessor.selection(explore.tv_content)
	signal_connect(cb_sel_content_changed, sel_content, "changed", Nothing, (), false, explore)

	#Populate, show & return:
	refresh!(explore)
	Gtk.showall(explore.wnd)
	return explore
end
