#db_access.jl: Write/read data to/from HDF5 "database".
#-------------------------------------------------------------------------------


#==Constants
===============================================================================#
const MSG_NODATA = "Aucune donnée trouvée."
const MSG_NOSRCDOCINFO = "Source non-spécifiée."

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
	gstr = _getid_grade(sel.grade_idx)
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

#Open group, or return nothing !exist:
function gopen_nothing(o, path::String)
	if !HDF5.exists(o, path);
		return nothing
	else
		return HDF5.g_open(o, path)
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

#Open group, or return nothing if !exit:
getgrp_root(db::HDF5.HDF5File) = gopen_nothing(db, "/")
getgrp_subject(db::HDF5.HDF5File, sel::ExploreSelection) =
	gopen_nothing(db, getpath_subject(sel))
getgrp_grade(db::HDF5.HDF5File, sel::ExploreSelection) =
	gopen_nothing(db, getpath_grade(sel))
getgrp_domains(db::HDF5.HDF5File, sel::ExploreSelection) =
	gopen_nothing(db, getpath_domains(sel))
getgrp_attentes(db::HDF5.HDF5File, sel::ExploreSelection) =
	gopen_nothing(db, getpath_attentes(sel))
getgrp_content(db::HDF5.HDF5File, sel::ExploreSelection) =
	gopen_nothing(db, getpath_content(sel))

#Returns subgroup, or nothing
function getsubgrp_nothing(grp::HDF5.HDF5Group, name::String)
	try #Don't know how to tell if subgroup exists (only if SOMETHING exists)
		return HDF5.g_open(grp, name)
	catch
		return nothing
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
reada_nelem(grp) = read_attr(grp, AID_NELEM, Int64, 0)
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
#	if HDF5.exists(grp, name); ; end
	HDF5.d_write(grp, name, v)
	return
end


#==Read in high-level fields
===============================================================================#
read_subjects(db::HDF5.HDF5File) = names(getgrp_root(db))

function read_sourcedoc(db::HDF5.HDF5File, sel::ExploreSelection)
	ggrp = getgrp_grade(db, sel)
	if isnothing(ggrp); return MSG_NODATA; end
	return reada_srcdoc(ggrp)
end

function read_domain_list(db::HDF5.HDF5File, sel::ExploreSelection)
	result = []
	grp = getgrp_domains(db, sel)
#	if isnothing(grp); return result; end
	if isnothing(grp)
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
	grp = getgrp_attentes(db, sel)
#	if isnothing(grp); return result; end
	if isnothing(grp)
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
	grp = getgrp_content(db, sel)
	if isnothing(grp); return result; end

	#Read in data:
	nelem = reada_nelem(grp)
	for i in 1:nelem
		id = getid_content(sel.domain_idx, sel.attente_idx, i)
		descr = readds_safe(grp, "$i", String, "")
		push!(result, (i, id, descr))
	end
	return result
end


#==Write out high-level fields
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


#Write whole lists at once (update element count)
#-------------------------------------------------------------------------------
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
