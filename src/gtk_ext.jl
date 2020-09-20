#gtk_ext.jl: GTK extensions (features missing from Gtk.jl library)
#-------------------------------------------------------------------------------

#GdkAtom "pointers":
const GTK_SELECTION_CLIPBOARD = Ptr{Nothing}(69)

#==Functions
===============================================================================#
function window_close(window::Gtk.GtkWindow)
	ccall((:gtk_window_close,Gtk.libgtk),Nothing,(Ptr{Gtk.GObject},),window)
	return
end

function clipboard_set_text(clipbrd::Ptr{Nothing}, v::String, _len::Int)
	ccall((:gtk_clipboard_set_text, Gtk.libgtk), Nothing, (Ptr{Gtk.GObject}, Ptr{UInt8}, Cint), clipbrd, v, _len)
	return clipbrd
end

#Last line
