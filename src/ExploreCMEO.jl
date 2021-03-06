module ExploreCMEO

import BinDeps #To download database from internet.
import HDF5
import HDF5: HDF5Group, HDF5Dataset

import Gtk
const _Gtk = Gtk.ShortNames

const URL_PUBLISHEDDATA = "https://raw.githubusercontent.com/alainman-krh/ExploreCMEODonnees.jl/master/ExploreCMEO.h5"
const PATH_DB = Ref(abspath("./ExploreCMEO.h5")) #In cwd

include("base.jl")
include("db_access.jl")
include("dbaccess_fieldview.jl")
include("gtk_ext.jl")
include("gtk_base.jl")
include("gtk_editdlg.jl")
include("gtk_top.jl")


#==Initialization
===============================================================================#
function __init__()
#	PATH_DB[] = abspath(joinpath(dirname(pathof(ExploreCMEODonnees)), "..", "ExploreCMEO.h5"))
	dbpath = PATH_DB[]
	if !isfile(dbpath)
		download_database(dbpath)
	end
end

end # module
