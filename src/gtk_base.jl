#gtk_base.jl: Base structures functionnality for gtk GUI
#-------------------------------------------------------------------------------

import Gtk: get_gtk_property, set_gtk_property!, signal_connect, @guarded
import Gtk: GConstants.GtkOrientation, GConstants.GtkSelectionMode
import Gtk: GConstants, GAccessor
import Gtk: GConstants.GtkAlign
import Gtk: GConstants.GtkPackType #START, END
import Gtk: GConstants.GtkWrapMode #NONE, CHAR, WORD, WORD_CHAR
import Gtk: GConstants.GtkScrollablePolicy #MINIMUM, NATURAL
import Gtk: GConstants.GtkPolicyType #ALWAYS, AUTOMATIC, NEVER, EXTERNAL
import Gtk: GConstants.GdkModifierType #CONTROL, LOCK, SHIFT, MOD1, ...
import Gtk: GConstants.GtkAccelFlags #VISIBLE, LOCKED, MASK


#==Types
===============================================================================#
abstract type AbstractDialog; end
struct NoDialog <: AbstractDialog; end

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
	ls_content::_Gtk.ListStore
	tv_content::_Gtk.TreeView
	editdlg::AbstractDialog
end


#==Menu builders:
===============================================================================#
function Gtk_addmenu(parent::Union{_Gtk.Menu, _Gtk.MenuBar}, name::String)
	item = _Gtk.MenuItem(name)
	mnu = _Gtk.Menu(item)
	push!(parent, item)
	return mnu
end
function Gtk_addmenuitem(mnu::_Gtk.Menu, name::String)
	item = _Gtk.MenuItem(name)
	push!(mnu, item)
	return item
end
function Gtk_addsep(mnu::_Gtk.Menu)
	push!(mnu, _Gtk.SeparatorMenuItem())
	return
end


#==Copy functions for different field views
===============================================================================#
#=Actually, data will be copied from freshly read data.  This makes the code
cleaner/simpler - but it means what is copied could get out of sync with the GUI.
=#
function _build_domain_str(v::Tuple, opt::FieldViewOpts)
	abuf = String[]
	if opt.include_id; push!(abuf, v[2]); end
	if opt.include_shortdescr||opt.include_longdescr
		push!(abuf, v[3])
	end
	return join(abuf, " ")
end
function _build_attente_str(v::Tuple, opt::FieldViewOpts)
	abuf = String[]
	if opt.include_id; push!(abuf, v[2]); end
	if opt.include_shortdescr; push!(abuf, v[3]); end
	if opt.include_longdescr; push!(abuf, v[4]); end
	return join(abuf, " ")
end
function _build_content_str(v::Tuple, opt::FieldViewOpts)
	abuf = String[]
	if opt.include_id; push!(abuf, v[2]); end
	if opt.include_shortdescr||opt.include_longdescr
		push!(abuf, v[3])
	end
	return join(abuf, " ")
end
copyfv(::AbstractFieldView, explore::ExploreWnd, opt::FieldViewOpts) = nothing
copyfv(::FViewSrcDoc, explore::ExploreWnd, opt::FieldViewOpts) =
	read_sourcedoc(explore.db, explore.sel)
function copyfv(::FViewDomain, explore::ExploreWnd, opt::FieldViewOpts)
	sel = explore.sel
	dlist = read_domain_list(explore.db, sel)
	if isnothing(dlist); return nothing; end
	if sel.domain_idx in 1:length(dlist)
		return _build_domain_str(dlist[sel.domain_idx], opt)
	end
	return nothing
end
function copyfv(::FViewAttente, explore::ExploreWnd, opt::FieldViewOpts)
	sel = explore.sel
	dlist = read_attente_list(explore.db, sel)
	if isnothing(dlist); return nothing; end
	if sel.attente_idx in 1:length(dlist)
		return _build_attente_str(dlist[sel.attente_idx], opt)
	end
	return nothing
end
function copyfv(::FViewAttente_LongDescr, explore::ExploreWnd, opt::FieldViewOpts)
	sel = explore.sel
	opt = FieldViewOpts(opt.include_id, false, true) #Copy specifically long description
	dlist = read_attente_list(explore.db, sel)
	if isnothing(dlist); return nothing; end
	if sel.attente_idx in 1:length(dlist)
		return _build_attente_str(dlist[sel.attente_idx], opt)
	end
	return nothing
end
function copyfv(::FViewContent, explore::ExploreWnd, opt::FieldViewOpts)
	sel = explore.sel
	dlist = read_content_list(explore.db, sel)
	if isnothing(dlist); return nothing; end
	if sel.content_idx in 1:length(dlist)
		return _build_content_str(dlist[sel.content_idx], opt)
	end
	return nothing
end

copyallfv(fv::AbstractFieldView, explore::ExploreWnd, opt::FieldViewOpts) =
	copyfv(fv, explore, opt)
function copyallfv(::FViewDomain, explore::ExploreWnd, opt::FieldViewOpts)
	abuf = String[]
	dlist = read_domain_list(explore.db, explore.sel)
	if isnothing(dlist); return nothing; end
	for data in dlist
		push!(abuf, _build_domain_str(data, opt))
	end
	return join(abuf, "\n")
end
function copyallfv(::FViewAttente, explore::ExploreWnd, opt::FieldViewOpts)
	abuf = String[]
	dlist = read_attente_list(explore.db, explore.sel)
	if isnothing(dlist); return nothing; end
	for data in dlist
		push!(abuf, _build_attente_str(data, opt))
	end
	return join(abuf, "\n")
end
function copyallfv(::FViewContent, explore::ExploreWnd, opt::FieldViewOpts)
	abuf = String[]
	dlist = read_content_list(explore.db, explore.sel)
	if isnothing(dlist); return nothing; end
	for data in dlist
		push!(abuf, _build_content_str(data, opt))
	end
	return join(abuf, "\n")
end


#==Helper functions
===============================================================================#
function clipboard_set_text(explore::ExploreWnd, ::Nothing)
	#Do nothing; maybe clear clipboard??
end
function clipboard_set_text(explore::ExploreWnd, txtstr::String)
	clipboard = GAccessor.clipboard(explore.wnd, GTK_SELECTION_CLIPBOARD)
	clipboard_set_text(clipboard, txtstr, -1)
end

#Returns desired field view - depending on active widget
function _activefieldview(explore::ExploreWnd)
	widgetmap = [
		(explore.ent_sourcedoc, FViewSrcDoc()),
		(explore.tv_domains, FViewDomain()),
		(explore.tv_attentes, FViewAttente()),
		(explore.ent_attentesdesc, FViewAttente_LongDescr()),
		(explore.tv_content, FViewContent()),
	]
	for (w, fview) in widgetmap
		if Gtk.get_gtk_property(w, "is-focus", Bool)
			return fview
		end
	end
	return FViewNone()
end


#==Public interface
===============================================================================#

#Overwrite show (inhibit dumping Gtk info):
function Base.show(io::IO, ::MIME"text/plain", explore::ExploreWnd)
	print(io, ExploreWnd, "(\"", explore.db.filename, "\")")
end

refresh!(explore::ExploreWnd) = refresh!(explore.state, explore)

Base.close(dlg::NoDialog) = nothing
Base.close(dlg::AbstractDialog) = window_close(dlg.wnd)
Base.close(explore::ExploreWnd) = window_close(explore.wnd)

#Last line
