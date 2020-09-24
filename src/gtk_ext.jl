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

#"ext": for customized implementations
function GtkMessageDialogLeaf_ext(msg::String, buttons::Integer=GtkButtonsType.OK,
		msgtype::Integer=GtkMessageType.INFO, parent = Gtk.GtkNullContainer())
	w = Gtk.GtkMessageDialogLeaf(ccall((:gtk_message_dialog_new, Gtk.libgtk), Ptr{Gtk.GObject},
		(Ptr{Gtk.GObject}, Cint, Cint, Cint, Ptr{UInt8}),
		parent, GtkDialogFlags.DESTROY_WITH_PARENT, msgtype, buttons, C_NULL)
	)
	set_gtk_property!(w, :text, msg)
	return w
end
function dialog_confirm(msg::String, parent = Gtk.GtkNullContainer())
	w = GtkMessageDialogLeaf_ext(msg, GtkButtonsType.YES_NO, GtkMessageType.WARNING, parent)
	answer = run(w)
	Gtk.destroy(w)
	return (GtkResponseType.YES == answer)
end
function dialog_inputbox(msg::String, entry_default::String, parent = Gtk.GtkNullContainer())
	w = GtkMessageDialogLeaf_ext(msg, GtkButtonsType.OK_CANCEL, GtkMessageType.INFO, parent)
	box = Gtk.content_area(w)
	entry = Gtk.GtkEntry(; text = entry_default)
	push!(box, entry)
	Gtk.showall(w)
	cancel = (run(w) != GtkResponseType.OK)
	_value = get_gtk_property(entry, :text, String)
	Gtk.destroy(w)
	if cancel; return nothing; end
	return _value
end

#Last line
