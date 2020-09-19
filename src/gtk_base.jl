#gtk_base.jl: Base structures functionnality for gtk GUI
#-------------------------------------------------------------------------------

import Gtk: get_gtk_property, set_gtk_property!, signal_connect, @guarded
import Gtk: GConstants.GtkOrientation, GConstants.GtkSelectionMode
import Gtk: GAccessor


#==Types
===============================================================================#


#==Extensions
===============================================================================#
function window_close(window::Gtk.GtkWindow)
	ccall((:gtk_window_close,Gtk.libgtk),Nothing,(Ptr{Gtk.GObject},),window)
	return
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


#Last line
