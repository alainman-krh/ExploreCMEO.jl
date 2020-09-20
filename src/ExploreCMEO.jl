module ExploreCMEO

import HDF5
import HDF5: HDF5Group, HDF5Dataset

import Gtk
const _Gtk = Gtk.ShortNames


const PATH_DB = Ref("")

include("base.jl")
include("db_access.jl")
include("gtk_ext.jl")
include("gtk_base.jl")
include("gtk_top.jl")


#==Initialization
===============================================================================#
function __init__()
	PATH_DB[] = abspath(joinpath(dirname(pathof(ExploreCMEO)), "..", "ExploreCMEO.h5"))
	@show PATH_DB[]
end

end # module
