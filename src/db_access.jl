#db_access.jl: Write/read data to/from HDF5 "database".
#-------------------------------------------------------------------------------

#==Types
===============================================================================#
"Exception: Invalid element of curricculum"
struct InvalidElement <: Exception
	msg
end

"Exception: Missing path in database"
struct MissingPath <: Exception
	msg
end


#==Constants
===============================================================================#
const DATA_UNKNOWNSRCDOC = "Source inconnue???"
const DATA_NEWDOMAIN = "Nouveau domaine"
const DATA_NEWATTENTE = "Nouvelle attente"
const DATA_NEWATTENTE_SHORT = "NA"
const DATA_NEWCONTENT = "Nouveau contenu"

const DATA_NODOMAIN = (0, "", "Aucun domaine")
const DATA_NOATTENTE = (0, "", "Aucune attente", "Aucune attente")
const DATA_NOCONTENT = (0, "", "Aucun contenu")

const MSG_NODATA = "Aucune donnée trouvée."
const MSG_NOSRCDOCINFO = "Source non-spécifiée."
const MSG_NOSUBJECT = "Aucun sujet sélectionné!"
const MSG_CANNOTADDENTRY = "Incapable d'ajouter un item!"

const ERROR_NOSUBJECT = InvalidElement(MSG_NOSUBJECT)
const ERROR_CANNOTADDENTRY = ErrorException(MSG_CANNOTADDENTRY)

#Attribute identifiers:
const AID_NELEM = "NELEM"
const AID_SRCDOC = "SRCDOC"
const AID_DESCR = "DESCR"
const AID_DESCR_SHORT = "DESCR_SHORT"


#==Path utils
===============================================================================#
getpath_subject(sel::ExploreSelection) = "/$(sel.subject)"
function getpath_grade(sel::ExploreSelection)
	pfx = getpath_subject(sel)
	gstr = getid_grade(sel.grade_idx)
	return "$pfx/$gstr"
end
function getpath_domains(sel::ExploreSelection)
	pfx = getpath_grade(sel)
	return "$pfx/domaines"
end
function getpath_seldomain(sel::ExploreSelection)
	pfx = getpath_domains(sel)
	return "$pfx/$(sel.domain_idx)"
end
function getpath_attentes(sel::ExploreSelection)
	pfx = getpath_seldomain(sel)
	return "$pfx/attentes"
end
function getpath_selattente(sel::ExploreSelection)
	pfx = getpath_attentes(sel)
	return "$pfx/$(sel.attente_idx)"
end
function getpath_content(sel::ExploreSelection)
	pfx = getpath_selattente(sel)
	return "$pfx/contenus"
end

#==Constructors
===============================================================================#
function InvalidElement(msg::String)
	return InvalidElement(msg)
end

function MissingPath(msg::String)
	return MissingPath(msg)
end


#==Base accessors for database
===============================================================================#
#Open group, or return nothing !exist:
function gopen_nothing(o, path::String)
	if !HDF5.exists(o, path);
		return nothing
	else
		return HDF5.g_open(o, path)
	end
end
#Returns subgroup, or nothing
function getsubgrp_nothing(grp::HDF5.HDF5Group, name::String)
	try #Don't know how to tell if subgroup exists (only if SOMETHING exists)
		return HDF5.g_open(grp, name)
	catch
		return nothing
	end
end

#Open group, or create if !exist:
function gopen_create(o, path::String)
	if !HDF5.exists(o, path);
		return HDF5.g_create(o, path)
	else
		return HDF5.g_open(o, path)
	end
end


#==Read in datasets & attributes (deal with missing data)
===============================================================================#
read_attr(::Nothing, name::String, expType::Type, default) = default
function read_attr(grp::HDF5.HDF5Group, name::String, expType::Type, default)
	if !HDF5.exists(HDF5.attrs(grp), name); return default; end
	attr = HDF5.a_read(grp, name)
	if !isa(attr, expType); return default; end
	return attr
end
function reada_nelem(grp)
	nelem = read_attr(grp, AID_NELEM, Int64, 0)
	return Int(max(0, nelem)) #Limit >= 0
end
reada_srcdoc(grp) = read_attr(grp, AID_SRCDOC, String, MSG_NOSRCDOCINFO)
reada_descr(grp) = read_attr(grp, AID_DESCR, String, "")
reada_shortdescr(grp) = read_attr(grp, AID_DESCR_SHORT, String, "")

function readds_safe(grp::HDF5.HDF5Group, name::String, expType::Type, default)
	if !HDF5.exists(grp, name); return default; end
	v = HDF5.d_read(grp, name)
	if !isa(v, expType); return default; end
	return v
end


#==Write datasets & attributes:
===============================================================================#
function write_attr(grp::HDF5.HDF5Group, name::String, v)
	if HDF5.exists(HDF5.attrs(grp), name)
		HDF5.a_delete(grp, name)
	end
	HDF5.a_write(grp, name, v)
end
writea_nelem(grp, v::Vector) = write_attr(grp, AID_NELEM, length(v))
writea_srcdoc(grp, v::String) = write_attr(grp, AID_SRCDOC, v)
writea_descr(grp, v::String) = write_attr(grp, AID_DESCR, v)
writea_shortdescr(grp, v::String) = write_attr(grp, AID_DESCR_SHORT, v)

function writeds_safe(grp::HDF5.HDF5Group, name::String, v)
	if HDF5.exists(grp, name); HDF5.o_delete(grp, name); end
	HDF5.d_write(grp, name, v)
	return
end



#==Validation
===============================================================================#
function validate_subject(sel::ExploreSelection)
	if isempty_subject(sel.subject); throw(ERROR_NOSUBJECT); end
	return
end
function validate_grade(sel::ExploreSelection)
	validate_subject(sel)
	if sel.grade_idx < 1; throw(InvalidElement(getpath_grade(sel))); end
	return
end
function validate_domain(sel::ExploreSelection)
	validate_grade(sel)
	if sel.domain_idx < 1; throw(InvalidElement(getpath_domains(sel))); end
	return
end
function validate_attente(sel::ExploreSelection)
	validate_domain(sel)
	if sel.attente_idx < 1; throw(InvalidElement(getpath_attentes(sel))); end
	return
end
function validate_content(sel::ExploreSelection)
	validate_attente(sel)
	if sel.content_idx < 1; throw(InvalidElement(getpath_content(sel))); end
	return
end

#Must actually exist in db:
#-------------------------------------------------------------------------------
function validateexists_simple(db::HDF5.HDF5File, path::String)
	grp = gopen_nothing(db, path)
	if isnothing(grp); throw(MissingPath(path)); end
	return
end
function validateexists_listitem(db::HDF5.HDF5File, path::String, itemidx::Int)
	grp = gopen_nothing(db, path)
	if isnothing(grp); throw(MissingPath(path)); end
	if itemidx > reada_nelem(grp); throw(MissingPath(path)); end
	return
end
function validateexists_subject(db::HDF5.HDF5File, sel::ExploreSelection)
	validate_subject(sel)
	validateexists_simple(db, getpath_subject(sel))
end
function validateexists_grade(db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_subject(db, sel)
	validateexists_simple(db, getpath_grade(sel))
end
function validateexists_domain(db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_grade(db, sel)
	validateexists_listitem(db, getpath_domains(sel), sel.domain_idx)
end
function validateexists_attente(db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_domain(db, sel)
	validateexists_listitem(db, getpath_attentes(sel), sel.attente_idx)
end
function validateexists_content(db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_attente(db, sel)
	validateexists_listitem(db, getpath_content(sel), sel.content_idx)
end


#==Read in high-level fields. Returns nothing on error.
===============================================================================#
read_subjects(db::HDF5.HDF5File) = names(gopen_nothing(db, "/"))

function read_sourcedoc(db::HDF5.HDF5File, sel::ExploreSelection)
	ggrp = gopen_nothing(db, getpath_grade(sel))
	if isnothing(ggrp); return nothing; end
	return reada_srcdoc(ggrp)
end

function read_domain_list(db::HDF5.HDF5File, sel::ExploreSelection)
	result = []
	grp = gopen_nothing(db, getpath_domains(sel))
	if isnothing(grp)
		return nothing
		#unreachable test data:
		for i in 1:3
			id = getid_domain(i)
			descr = "Domaine $id"
			push!(result, (i, id, descr))
		end
		return result
	end

	#Read in data:
	nelem = reada_nelem(grp)
	for i in 1:nelem
		id = getid_domain(i)
		dgrp = getsubgrp_nothing(grp, "$i")
		descr = reada_descr(dgrp)
		push!(result, (i, id, descr))
	end
	return result
end

function read_attente_list(db::HDF5.HDF5File, sel::ExploreSelection)
	result = []
	grp = gopen_nothing(db, getpath_attentes(sel))
	if isnothing(grp)
		return nothing
		#unreachable test data:
		for i in 1:3
			id = getid_attente(sel.domain_idx, i)
			shortdescr = "Attente $id"
			descr = "Description $id"
			push!(result, (i, id, shortdescr, descr))
		end
	end

	#Read in data:
	nelem = reada_nelem(grp)
	for i in 1:nelem
		id = getid_attente(sel.domain_idx, i)
		agrp = getsubgrp_nothing(grp, "$i")
		shortdescr = reada_shortdescr(agrp)
		descr = reada_descr(agrp)
		push!(result, (i, id, shortdescr, descr))
	end
	return result
end

function read_content_list(db::HDF5.HDF5File, sel::ExploreSelection)
	result = []
	grp = gopen_nothing(db, getpath_content(sel))
	if isnothing(grp); return nothing; end

	#Read in data:
	nelem = reada_nelem(grp)
	for i in 1:nelem
		id = getid_content(sel.domain_idx, sel.attente_idx, i)
		descr = readds_safe(grp, "$i", String, "")
		push!(result, (i, id, descr))
	end
	return result
end


#==Write out high-level fields. Use createslot_* or validateexists_* first!
===============================================================================#
function write_sourcedoc(db::HDF5.HDF5File, sel::ExploreSelection, v::String)
	grp = gopen_create(db, getpath_grade(sel))
	writea_srcdoc(grp, v)
end
function write_domain_descr(db::HDF5.HDF5File, sel::ExploreSelection, descr::String)
	grp = gopen_create(db, getpath_seldomain(sel))
	writea_descr(grp, descr)
end
function write_attente_descr(db::HDF5.HDF5File, sel::ExploreSelection, shortdescr::String, descr::String)
	grp = gopen_create(db, getpath_selattente(sel))
	writea_shortdescr(grp, shortdescr)
	writea_descr(grp, descr)
end
function write_content_descr(db::HDF5.HDF5File, sel::ExploreSelection, descr::String)
	grp = gopen_create(db, getpath_content(sel))
	writeds_safe(grp, "$(sel.content_idx)", descr)
end


#==Create slot: Add new item to db (throw exception if cannot; return true if success)
===============================================================================#
function createslot_subject(db::HDF5.HDF5File, sel::ExploreSelection)
	validate_subject(sel)
	grp = gopen_create(db, getpath_subject(sel))
	return true
end
#Don't really need to explicitly create subject. Create source doc info instead:
function createslot_srcdoc(db::HDF5.HDF5File, sel::ExploreSelection)
	validate_grade(sel) #Otherwise, will generate garbage
	srcstr = read_sourcedoc(db, sel)
	if !isnothing(srcstr); return false; end #Don't overwrite, but no exception
	grp = gopen_create(db, getpath_subject(sel))
	write_sourcedoc(db, sel, DATA_UNKNOWNSRCDOC)
	return true #Created new slot
end
function createslot_domain(db::HDF5.HDF5File, sel::ExploreSelection)
	createslot_srcdoc(db, sel) #Just in case doesn't exist / also validates
	#Don't really need to validate anything else before creating...
	dlist = read_domain_list(db, sel)
	if isnothing(dlist); dlist = []; end
	push!(dlist, DATA_NEWDOMAIN) #Add something to compute length
	sel.domain_idx = length(dlist)
	grp = gopen_create(db, getpath_domains(sel))
	write_domain_descr(db, sel, DATA_NEWDOMAIN)
	writea_nelem(grp, dlist)
	return
end
function createslot_attente(db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_domain(db, sel) #Don't create if parent nodes don't exist
	dlist = read_attente_list(db, sel)
	if isnothing(dlist); dlist = []; end
	push!(dlist, DATA_NEWATTENTE) #Add something to compute length
	sel.attente_idx = length(dlist)
	grp = gopen_create(db, getpath_attentes(sel))
	write_attente_descr(db, sel, DATA_NEWATTENTE_SHORT, DATA_NEWATTENTE)
	writea_nelem(grp, dlist)
	return
end
function createslot_content(db::HDF5.HDF5File, sel::ExploreSelection)
	validateexists_attente(db, sel) #Don't create if parent nodes don't exist
	dlist = read_content_list(db, sel)
	if isnothing(dlist); dlist = []; end
	push!(dlist, DATA_NEWCONTENT) #Add something to compute length
	sel.content_idx = length(dlist)
	grp = gopen_create(db, getpath_content(sel))
	write_content_descr(db, sel, DATA_NEWCONTENT)
	writea_nelem(grp, dlist)
	return
end


#==Write functions for list of elements
===============================================================================#
#=NOTE
 - Write whole lists at once & update element count.
 - Not very robust.
 - Meant to manually add data using scripts.
=#
function write_domain_list(db::HDF5.HDF5File, sel::ExploreSelection, list::Vector{String})
	sel = deepcopy(sel)
	for (i, descr) in enumerate(list)
		sel.domain_idx = i
		write_domain_descr(db, sel, descr)
	end

	grp = gopen_create(db, getpath_domains(sel))
	writea_nelem(grp, list)
end
function write_attente_list(db::HDF5.HDF5File, sel::ExploreSelection, list::Vector)
	sel = deepcopy(sel)
	for (i, elem) in enumerate(list)
		sel.attente_idx = i
		(shortdescr, descr) = elem
		write_attente_descr(db, sel, shortdescr, descr)
	end

	grp = gopen_create(db, getpath_attentes(sel))
	writea_nelem(grp, list)
end
function write_content_list(db::HDF5.HDF5File, sel::ExploreSelection, list::Vector)
	sel = deepcopy(sel)
	for (i, elem) in enumerate(list)
		sel.content_idx = i
		write_content_descr(db, sel, elem)
	end

	grp = gopen_create(db, getpath_content(sel))
	writea_nelem(grp, list)
end


#Last line
